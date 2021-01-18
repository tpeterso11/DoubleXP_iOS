//
//  LoginController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import UnderLineTextField
import FBSDKLoginKit
import GoogleSignIn
import PopupDialog
import SwiftDate
import CryptoKit
import AuthenticationServices
import FlagPhoneNumber
import SPStorkController


class LoginController: UIViewController, GIDSignInDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UITextFieldDelegate, FPNTextFieldDelegate, SPStorkControllerDelegate {
    private var data: [NewsObject]!
    private var games: [GamerConnectGame]!
    var handle: AuthStateDidChangeListenerHandle?
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordFieild: UITextField!
    @IBOutlet weak var registerText: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var facebookLogin: UIImageView!
    @IBOutlet weak var googleSignIn: UIView!
    @IBOutlet weak var workOverlay: UIView!
    @IBOutlet weak var workSpinner: UIActivityIndicatorView!
    @IBOutlet weak var appleLogin: UIImageView!
    @IBOutlet weak var phoneLayout: UIView!
    @IBOutlet weak var emailLayout: UIView!
    @IBOutlet weak var phoneNumberSwitch: UILabel!
    @IBOutlet weak var emailSwitch: UILabel!
    @IBOutlet weak var phoneEntry: FPNTextField!
    @IBOutlet weak var phoneLogin: UIButton!
    private var validPhone = false
    
    var socialRegisteredUid = ""
    var selectedSocial = ""
    
    func loginManagerDidComplete(_ result: LoginManagerLoginResult?, _ error: Error?) {
        if let result = result, result.isCancelled {
            hideWork()
            
            AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login Canceled"))
            
            var buttons = [PopupDialogButton]()
            let title = "your login attempt was canceled."
            let message = "login attempt was canceled.."
            
            let button = DefaultButton(title: "try again.") { [weak self] in
                self?.loginWithReadPermissions()
                
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "i know") { [weak self] in
                //do nothing
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        } else {
            if let tokenString = result?.token?.tokenString {
                let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        let authError = error as NSError
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Fail Firebase - " + authError.localizedDescription))
                    }
                    else{
                        let uId = authResult?.user.uid ?? ""
                        if(!uId.isEmpty){
                            if(authResult != nil){
                                self.downloadDBRef(uid: uId, registrationType: "facebook")
                            }
                            else{
                                let checkRef = Database.database().reference().child("Users").child(uId)
                                let user = User(uId: uId)
                                checkRef.child("platform").setValue("ios")
                                checkRef.child("search").setValue("true")
                                checkRef.child("registrationType").setValue("facebook")
                                checkRef.child("model").setValue(UIDevice.modelName)
                                checkRef.child("notifications").setValue("true")
                                    
                                DispatchQueue.main.async {
                                    let delegate = UIApplication.shared.delegate as! AppDelegate
                                    delegate.currentUser = user
                                    self.performSegue(withIdentifier: "newReg", sender: nil)
                                }
                            }
                        }
                    }
                }
            } else {
                hideWork()
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login Fail - " + "\(error?.localizedDescription ?? "")"))
                
                var buttons = [PopupDialogButton]()
                let title = "facebook login error."
                let message = "there was an error getting you logged into facebook. try again, or try registering using your email."
                
                let button = DefaultButton(title: "try again.") { [weak self] in
                    self?.loginWithReadPermissions()
                    
                }
                buttons.append(button)
                
                let buttonOne = CancelButton(title: "nevermind") { [weak self] in
                    self?.hideWork()
                }
                buttons.append(buttonOne)
                
                let popup = PopupDialog(title: title, message: message)
                popup.addButtons(buttons)

                // Present dialog
                self.present(popup, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func emailSwitchAction(){
        if(phoneLayout.alpha == 1){ //if phone layout is showing, make email bold, show email layout
            self.emailSwitch.font = UIFont.boldSystemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
            self.phoneNumberSwitch.font = UIFont.systemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
            UIView.animate(withDuration: 0.8, animations: {
                self.phoneLayout.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                    self.emailLayout.alpha = 1
                }, completion: nil)
            })
        } else {
            self.phoneNumberSwitch.font = UIFont.boldSystemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
            self.emailSwitch.font = UIFont.systemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
        }
    }
    
    @objc private func phoneSwitchAction(){
        if(phoneLayout.alpha == 0){
            self.phoneNumberSwitch.font = UIFont.boldSystemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
            self.emailSwitch.font = UIFont.systemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
            UIView.animate(withDuration: 0.8, animations: {
                self.emailLayout.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                    self.phoneLayout.alpha = 1
                }, completion: nil)
            })
            
        } else {
            self.phoneNumberSwitch.font = UIFont.systemFont(ofSize: self.phoneNumberSwitch.font.pointSize)
        }
    }

    @IBAction private func loginWithReadPermissions() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] (result, error) in
            self?.loginManagerDidComplete(result, error)
        }
    }

    @IBAction private func logOut() {
        let loginManager = LoginManager()
        loginManager.logOut()

        let alertController = UIAlertController(
            title: "Logout",
            message: "Logged out.", preferredStyle: .alert
        )
        present(alertController, animated: true, completion: nil)
    }
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        games = [GamerConnectGame]()
        // Do any additional setup after loading the view, typically from a nib.
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLoginActivity = self
        
        loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(registerClicked))
        registerText.isUserInteractionEnabled = true
        registerText.addGestureRecognizer(singleTap)
        
        let facebookTap = UITapGestureRecognizer(target: self, action: #selector(facebookLoginClicked))
        facebookLogin.isUserInteractionEnabled = true
        facebookLogin.addGestureRecognizer(facebookTap)
        
        let googleTap = UITapGestureRecognizer(target: self, action: #selector(googleLoginClicked))
        googleSignIn.isUserInteractionEnabled = true
        googleSignIn.addGestureRecognizer(googleTap)
        
        if #available(iOS 13, *) {
            appleLogin.alpha = 1
            
            let appleTap = UITapGestureRecognizer(target: self, action: #selector(appleLoginClicked))
            appleLogin.isUserInteractionEnabled = true
            appleLogin.addGestureRecognizer(appleTap)
        } else {
            appleLogin.alpha = 0.3
            appleLogin.isUserInteractionEnabled = false
        }
        //todo IMPLEMET APPLE LOGIN~!!!!
        
        GIDSignIn.sharedInstance().delegate = self
        
        addDoneButtonOnKeyboard()
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login"))
        
        emailField.returnKeyType = .done
        emailField.delegate = self
        passwordFieild.returnKeyType = .done
        passwordFieild.delegate = self
        
        self.phoneEntry.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        self.phoneEntry.delegate = self
        self.phoneEntry.returnKeyType = .done
        self.phoneLogin.addTarget(self, action: #selector(continueClickedPhone), for: .touchUpInside)
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(phoneSwitchAction))
        self.phoneNumberSwitch.isUserInteractionEnabled = true
        self.phoneNumberSwitch.addGestureRecognizer(phoneTap)
        
        let emailTap = UITapGestureRecognizer(target: self, action: #selector(emailSwitchAction))
        self.emailSwitch.isUserInteractionEnabled = true
        self.emailSwitch.addGestureRecognizer(emailTap)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == self.phoneEntry && self.phoneEntry.text!.count > 4){
            self.checkNextButton()
        }
    }
    
    private func checkNextButton(){
        if(validPhone){
            self.phoneLogin.alpha = 1
        } else {
            self.phoneLogin.alpha = 0.3
        }
    }
    
    @objc func loginButtonClicked(_ sender: AnyObject?) {
        self.showWork()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let email = self.emailField.text, let password = self.passwordFieild.text else { return }
            let manager = FirebaseAuthManager()
            manager.signIn(email: email, pass: password) {[weak self] (error, success) in
                guard let `self` = self else { return }
                var message: String = ""
                var code = ""
                if (success) {
                    let userID = Auth.auth().currentUser!.uid
                    self.downloadDBRef(uid: userID, registrationType: "email")
                    
                    UserDefaults.standard.set(userID, forKey: "userId")
                    //self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
                }
                else {
                    code = error
                    
                    switch(code){
                        case "17007": message = "sorry, that email is already in use."
                        case "17008": message = "sorry, please enter a valid email to continue."
                        case "17009": message = "sorry, that password is incorrect. please try again."
                        case "17011": message = "sorry, we do not have that user in our database."
                        default: message = "there was an error logging you in. please try again."
                    }
                    
                    let alertController = UIAlertController(title: "login error", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: self.dismissedAlert(alert:)))
                    self.display(alertController: alertController)
                }
            }
        }
    }
    
    func dismissedAlert(alert: UIAlertAction!) {
        hideWork()
    }
    
    @objc func facebookLoginClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login"))
        showWork()
        
        self.selectedSocial = "facebook"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.loginWithReadPermissions()
        }
    }
    
    @objc func googleLoginClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Google Login"))
        showWork()
        
        self.selectedSocial = "google"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            GIDSignIn.sharedInstance()?.presentingViewController = self
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    @available(iOS 13, *)
    @objc func appleLoginClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Apple Login"))
        
        self.selectedSocial = "apple"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.startSignInWithAppleFlow()
        }
    }
    
    @objc func registerClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "register", sender: nil) // noraml
        //self.performSegue(withIdentifier: "test", sender: nil) // game selection
        //self.performSegue(withIdentifier: "newReg", sender: nil) //registration
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    private func showWork(){
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.workOverlay.alpha = 1
            self.workSpinner.startAnimating()
        }, completion: nil)
    }
    
    private func hideWork(){
           UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.workSpinner.stopAnimating()
               self.workOverlay.alpha = 0
           }, completion: nil)
       }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
          guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
          }
          guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
          }
          guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
          }
          // Initialize a Firebase credential.
          let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
          // Sign in with Firebase.
          Auth.auth().signIn(with: credential) { (authResult, error) in
            if (error != nil) {
              // Error. If error.code == .MissingOrInvalidNonce, make sure
              // you're sending the SHA256-hashed nonce as a hex string with
              // your request to Apple.
                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Apple Login Fail Firebase"))
            }
            else{
                if(authResult != nil){
                    let uId = authResult?.user.uid ?? ""
                    UserDefaults.standard.set(uId, forKey: "userId")
                    self.downloadDBRef(uid: uId, registrationType: "apple")
                }
                else{
                    //need to redo this. AuthResult is null, so then uId will be empty.
                    let uId = authResult?.user.uid ?? ""
                    if(!uId.isEmpty){
                        UserDefaults.standard.set(uId, forKey: "userId")
                        if(authResult != nil){
                            self.downloadDBRef(uid: uId, registrationType: "apple")
                        }
                        else{
                            let checkRef = Database.database().reference().child("Users").child(uId)
                            let user = User(uId: uId)
                            checkRef.child("platform").setValue("ios")
                            checkRef.child("search").setValue("true")
                            checkRef.child("registrationType").setValue("apple")
                            checkRef.child("model").setValue(UIDevice.modelName)
                            checkRef.child("notifications").setValue("true")
                                
                            DispatchQueue.main.async {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                delegate.currentUser = user
                                self.performSegue(withIdentifier: "newReg", sender: nil)
                            }
                        }
                    }
                }
            }
        }
      }
    }
    
    private func downloadDBRef(uid: String, registrationType: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                let uId = snapshot.key
                let gamerTag = value?["gamerTag"] as? String ?? ""
                let subscriptions = value?["subscriptions"] as? [String] ?? [String]()
                let competitions = value?["competitions"] as? [String] ?? [String]()
                let bio = value?["bio"] as? String ?? ""
                let userLat = value?["userLat"] as? Double ?? 0.0
                let userLong = value?["userLong"] as? Double ?? 0.0
                let blockList = value?["blockList"] as? [String: String] ?? [String: String]()
                let restrictList = value?["restrictList"] as? [String: String] ?? [String: String]()
                
                let search = value?["search"] as? String ?? ""
                if(search.isEmpty){
                    ref.child("search").setValue("true")
                }
                
                let twitchToken = value?["twitchAppToken"] as? String ?? ""
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let manager = delegate.socialMediaManager
                if(twitchToken.isEmpty){
                    manager.getTwitchAppToken(token: nil, uid: uid)
                } else {
                    manager.getTwitchAppToken(token: twitchToken, uid: uid)
                }
                
                let notifications = value?["notifications"] as? String ?? ""
                if(notifications.isEmpty){
                    ref.child("notifications").setValue("true")
                }
                
                let viewedAnnouncements = value?["viewedAnnouncements"] as? [String] ?? [String]()
                
                var sentRequests = [FriendRequestObject]()
                
                //if sent requests have not been converted, we convert NOW.
                if(value?["sent_requests"] is [String]){
                    self.convertRequests(list: value?["sent_requests"] as! [String], pathString: "sent_requests", userUid: uId)
                }
                else{
                    let friendsArray = snapshot.childSnapshot(forPath: "sent_requests")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        sentRequests.append(newFriend)
                    }
                }
                
                //if pending requests have not been converted, we convert NOW.
                var pendingRequests = [FriendRequestObject]()
                if(value?["pending_friends"] is [String]){
                    self.convertRequests(list: value?["pending_friends"] as! [String], pathString: "pending_friends", userUid: uId)
                }
                else{
                    let friendsArray = snapshot.childSnapshot(forPath: "pending_friends")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        pendingRequests.append(newFriend)
                    }
                }
                
                var badges = [BadgeObj]()
                if(snapshot.hasChild("badges")){
                    let badgesArray = snapshot.childSnapshot(forPath: "badges")
                    for badge in badgesArray.children{
                        let currentObj = badge as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let name = dict?["badgeName"] as? String ?? ""
                        let desc = dict?["badgeDesc"] as? String ?? ""
                        
                        let badge = BadgeObj(badge: name, badgeDesc: desc)
                        badges.append(badge)
                    }
                }
                
                var teamInviteReqs = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["captainId"] as? String ?? ""
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                        let userUid = dict?["userUid"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let profileGamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     
                    var questions = [FAQuestion]()
                    let questionList = dict?["questions"] as? [[String: Any]] ?? [[String: Any]]()
                            for question in questionList {
                                var questionNumber = ""
                                var questionString = ""
                                var option1 = ""
                                var option1Description = ""
                                var option2 = ""
                                var option2Description = ""
                                var option3 = ""
                                var option3Description = ""
                                var option4 = ""
                                var option4Description = ""
                                var option5 = ""
                                var option5Description = ""
                                var option6 = ""
                                var option6Description = ""
                                var option7 = ""
                                var option7Description = ""
                                var option8 = ""
                                var option8Description = ""
                                var option9 = ""
                                var option9Description = ""
                                var option10 = ""
                                var option10Description = ""
                                var required = ""
                                var questionDescription = ""
                                var teamNeedQuestion = "false"
                                var acceptMultiple = ""
                                var question1SetURL = ""
                                var question2SetURL = ""
                                var question3SetURL = ""
                                var question4SetURL = ""
                                var question5SetURL = ""
                                var optionsURL = ""
                                var maxOptions = ""
                                var answer = ""
                                var answerArray = [String]()
                                
                                for (key, value) in question {
                                    if(key == "questionNumber"){
                                        questionNumber = (value as? String) ?? ""
                                    }
                                    if(key == "question"){
                                        questionString = (value as? String) ?? ""
                                    }
                                    if(key == "option1"){
                                        option1 = (value as? String) ?? ""
                                    }
                                    if(key == "option1Description"){
                                        option1Description = (value as? String) ?? ""
                                    }
                                    if(key == "option2"){
                                        option2 = (value as? String) ?? ""
                                    }
                                    if(key == "option2Description"){
                                        option2Description = (value as? String) ?? ""
                                    }
                                    if(key == "option3"){
                                        option3 = (value as? String) ?? ""
                                    }
                                    if(key == "option3Description"){
                                        option3Description = (value as? String) ?? ""
                                    }
                                    if(key == "option4"){
                                        option4 = (value as? String) ?? ""
                                    }
                                    if(key == "option4Description"){
                                        option4Description = (value as? String) ?? ""
                                    }
                                    if(key == "option5"){
                                        option5 = (value as? String) ?? ""
                                    }
                                    if(key == "option5Description"){
                                        option5Description = (value as? String) ?? ""
                                    }
                                    if(key == "option6"){
                                        option6 = (value as? String) ?? ""
                                    }
                                    if(key == "option6Description"){
                                        option6Description = (value as? String) ?? ""
                                    }
                                    if(key == "option7"){
                                        option7 = (value as? String) ?? ""
                                    }
                                    if(key == "option7Description"){
                                        option7Description = (value as? String) ?? ""
                                    }
                                    if(key == "option8"){
                                        option8 = (value as? String) ?? ""
                                    }
                                    if(key == "option8Description"){
                                        option8Description = (value as? String) ?? ""
                                    }
                                    if(key == "option9"){
                                        option9 = (value as? String) ?? ""
                                    }
                                    if(key == "option9Description"){
                                        option9Description = (value as? String) ?? ""
                                    }
                                    if(key == "option10"){
                                        option10 = (value as? String) ?? ""
                                    }
                                    if(key == "option10Description"){
                                        option10Description = (value as? String) ?? ""
                                    }
                                    if(key == "required"){
                                        required = (value as? String) ?? ""
                                    }
                                    if(key == "questionDescription"){
                                        questionDescription = (value as? String) ?? ""
                                    }
                                    if(key == "acceptMultiple"){
                                        acceptMultiple = (value as? String) ?? ""
                                    }
                                    if(key == "question1SetURL"){
                                        question1SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question2SetURL"){
                                        question2SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question3SetURL"){
                                        question3SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question4SetURL"){
                                        question4SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question5SetURL"){
                                        question5SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "teamNeedQuestion"){
                                        teamNeedQuestion = (value as? String) ?? "false"
                                    }
                                    if(key == "optionsUrl"){
                                        optionsURL = (value as? String) ?? ""
                                    }
                                    if(key == "maxOptions"){
                                        maxOptions = (value as? String) ?? ""
                                    }
                                    if(key == "answer"){
                                        answer = (value as? String) ?? ""
                                    }
                                    if(key == "answerArray"){
                                        answerArray = (value as? [String]) ?? [String]()
                                    }
                            }
                                
                                let faQuestion = FAQuestion(question: questionString)
                                    faQuestion.questionNumber = questionNumber
                                    faQuestion.question = questionString
                                    faQuestion.option1 = option1
                                    faQuestion.option1Description = option1Description
                                    faQuestion.question1SetURL = question1SetURL
                                    faQuestion.option2 = option2
                                    faQuestion.option2Description = option2Description
                                    faQuestion.question2SetURL = question2SetURL
                                    faQuestion.option3 = option3
                                    faQuestion.option3Description = option3Description
                                    faQuestion.question3SetURL = question3SetURL
                                    faQuestion.option4 = option4
                                    faQuestion.option4Description = option4Description
                                    faQuestion.question4SetURL = question4SetURL
                                    faQuestion.option5 = option5
                                    faQuestion.option5Description = option5Description
                                    faQuestion.question5SetURL = question5SetURL
                                    faQuestion.option6 = option6
                                    faQuestion.option6Description = option6Description
                                    faQuestion.option7 = option7
                                    faQuestion.option7Description = option7Description
                                    faQuestion.option8 = option8
                                    faQuestion.option8Description = option8Description
                                    faQuestion.option9 = option9
                                    faQuestion.option9Description = option9Description
                                    faQuestion.option10 = option10
                                    faQuestion.option10Description = option10Description
                                    faQuestion.required = required
                                    faQuestion.acceptMultiple = acceptMultiple
                                    faQuestion.questionDescription = questionDescription
                                    faQuestion.teamNeedQuestion = teamNeedQuestion
                                    faQuestion.optionsUrl = optionsURL
                                    faQuestion.maxOptions = maxOptions
                                    faQuestion.answer = answer
                                    faQuestion.answerArray = answerArray
                    
                        questions.append(faQuestion)
                    }
                     
                     let result = FreeAgentObject(gamerTag: profileGamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                    let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId, userUid: userUid, gamerTag: gamerTag)
                     newRequest.profile = result
                     
                     teamInviteReqs.append(newRequest)
                }
                
                var friends = [FriendObject]()
                if(value?["friends"] is [String]){
                    self.convertFriends(list: value?["friends"] as! [String], pathString: "friends", userUid: uId)
                }
                else{
                    let friendsArray = snapshot.childSnapshot(forPath: "friends")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                        friends.append(newFriend)
                    }
                }
                
                let games = value?["games"] as? [String] ?? [String]()
                var gamerTags = [GamerProfile]()
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                for gamerTagObj in gamerTagsArray.children {
                    let currentObj = gamerTagObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let currentTag = dict?["gamerTag"] as? String ?? ""
                    let currentGame = dict?["game"] as? String ?? ""
                    let console = dict?["console"] as? String ?? ""
                    let quizTaken = dict?["quizTaken"] as? String ?? ""
                    
                    let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                    gamerTags.append(currentGamerTagObj)
                }
                let messagingNotifications = value?["messagingNotifications"] as? Bool ?? false
                
               var teams = [EasyTeamObj]()
               let teamsArray = snapshot.childSnapshot(forPath: "teams")
               for teamObj in teamsArray.children {
                   let currentObj = teamObj as! DataSnapshot
                   let dict = currentObj.value as? [String: Any]
                   let teamName = dict?["teamName"] as? String ?? ""
                   let teamId = dict?["teamId"] as? String ?? ""
                   let game = dict?["gameName"] as? String ?? ""
                   let teamCaptainId = dict?["teamCaptainId"] as? String ?? ""
                   let newTeam = dict?["newTeam"] as? String ?? ""
                   
                   teams.append(EasyTeamObj(teamName: teamName, teamId: teamId, gameName: game, teamCaptainId: teamCaptainId, newTeam: newTeam))
               }
                
                var currentTeamInvites = [TeamInviteObject]()
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                    currentTeamInvites.append(newInvite)
                }
                
                var currentStats = [StatObject]()
                let statsArray = snapshot.childSnapshot(forPath: "stats")
                for statObj in statsArray.children {
                    let currentObj = statObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gameName = dict?["gameName"] as? String ?? ""
                    let playerLevelGame = dict?["playerLevelGame"] as? String ?? ""
                    let playerLevelPVP = dict?["playerLevelPVP"] as? String ?? ""
                    let killsPVP = dict?["killsPVP"] as? String ?? ""
                    let killsPVE = dict?["killsPVE"] as? String ?? ""
                    let statURL = dict?["statURL"] as? String ?? ""
                    let setPublic = dict?["setPublic"] as? String ?? ""
                    let authorized = dict?["authorized"] as? String ?? ""
                    let currentRank = dict?["currentRank"] as? String ?? ""
                    let totalRankedWins = dict?["otalRankedWins"] as? String ?? ""
                    let totalRankedLosses = dict?["totalRankedLosses"] as? String ?? ""
                    let totalRankedKills = dict?["totalRankedKills"] as? String ?? ""
                    let totalRankedDeaths = dict?["totalRankedDeaths"] as? String ?? ""
                    let mostUsedAttacker = dict?["mostUsedAttacker"] as? String ?? ""
                    let mostUsedDefender = dict?["mostUsedDefender"] as? String ?? ""
                    let gearScore = dict?["gearScore"] as? String ?? ""
                    let codKills = dict?["codKills"] as? String ?? ""
                    let codKd = dict?["codKd"] as? String ?? ""
                    let codLevel = dict?["codLevel"] as? String ?? ""
                    let codBestKills = dict?["codBestKills"] as? String ?? ""
                    let codWins = dict?["codWins"] as? String ?? ""
                    let codWlRatio = dict?["codWlRatio"] as? String ?? ""
                    let overwatchCasualStats = dict?["overwatchCasualStats"] as? [String:String] ?? [String: String]()
                    let overwatchCompetitiveStats = dict?["overwatchCompetitiveStats"] as? [String:String] ?? [String: String]()
                    let killsPerMatch = dict?["killsPerMatch"] as? String ?? ""
                    let matchesPlayed = dict?["matchesPlayed"] as? String ?? ""
                    let seasonWins = dict?["seasonWins"] as? String ?? ""
                    let seasonKills = dict?["seasonKills"] as? String ?? ""
                    let supImage = dict?["supImage"] as? String ?? ""
                    
                    let currentStat = StatObject(gameName: gameName)
                    currentStat.overwatchCasualStats = overwatchCasualStats
                    currentStat.overwatchCompetitiveStats = overwatchCompetitiveStats
                    currentStat.killsPerMatch = killsPerMatch
                    currentStat.matchesPlayed = matchesPlayed
                    currentStat.seasonWins = seasonWins
                    currentStat.seasonKills = seasonKills
                    currentStat.suppImage = supImage
                    currentStat.authorized = authorized
                    currentStat.playerLevelGame = playerLevelGame
                    currentStat.playerLevelPVP = playerLevelPVP
                    currentStat.killsPVP = killsPVP
                    currentStat.killsPVE = killsPVE
                    currentStat.statUrl = statURL
                    currentStat.setPublic = setPublic
                    currentStat.authorized = authorized
                    currentStat.currentRank = currentRank
                    currentStat.totalRankedWins = totalRankedWins
                    currentStat.totalRankedLosses = totalRankedLosses
                    currentStat.totalRankedKills = totalRankedKills
                    currentStat.totalRankedDeaths = totalRankedDeaths
                    currentStat.mostUsedAttacker = mostUsedAttacker
                    currentStat.mostUsedDefender = mostUsedDefender
                    currentStat.gearScore = gearScore
                    currentStat.codKills = codKills
                    currentStat.codKd = codKd
                    currentStat.codLevel = codLevel
                    currentStat.codBestKills = codBestKills
                    currentStat.codWins = codWins
                    currentStat.codWlRatio = codWlRatio
                    
                    currentStats.append(currentStat)
                }
                
                var rivals = [RivalObj]()
                if(snapshot.hasChild("currentTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "currentTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        
                        let calendar = Calendar.current
                        if(!date.isEmpty){
                            let dbDate = self.stringToDate(date)
                            
                            if(dbDate != nil){
                                let now = NSDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                                let future = formatter.string(from: dbDate as Date)
                                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                                
                                let validRival = (now as Date).compare(.isEarlier(than: dbTimeOut))
                                
                                if(dbTimeOut != nil){
                                    if(validRival){
                                        rivals.append(request)
                                    }
                                    else{
                                        ref.child("tempRivals").child(currentObj.key).removeValue()
                                    }
                                }
                            }
                        }
                    }
                }
                
                let reviews = value?["reviews"] as? [String] ?? [String]()
                
                var tempRivals = [RivalObj]()
                if(snapshot.hasChild("tempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "tempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        
                        if(!date.isEmpty){
                            let dbDate = self.stringToDate(date)
                            
                            if(dbDate != nil){
                                let now = NSDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                                let future = formatter.string(from: dbDate as Date)
                                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                                
                                let validRival = (now as Date).compare(.isEarlier(than: dbTimeOut))
                                
                                if(dbTimeOut != nil){
                                    if(validRival){
                                        tempRivals.append(request)
                                    }
                                    else{
                                        ref.child("tempRivals").child(currentObj.key).removeValue()
                                    }
                                }
                            }
                        }
                    }
                }
                
                var acceptedRivals = [RivalObj]()
                if(snapshot.hasChild("acceptedTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "acceptedTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        acceptedRivals.append(request)
                    }
                }
                
                var rejectedRivals = [RivalObj]()
                if(snapshot.hasChild("rejectedTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "rejectedTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        rejectedRivals.append(request)
                    }
                }
                
                let consoleArray = snapshot.childSnapshot(forPath: "consoles")
                let dict = consoleArray.value as? [String: Bool]
                let nintendo = dict?["nintendo"] ?? false
                let ps = dict?["ps"] ?? false
                let xbox = dict?["xbox"] ?? false
                let pc = dict?["pc"] ?? false
                
                let user = User(uId: uId)
                user.gamerTags = gamerTags
                user.teams = teams
                user.stats = currentStats
                user.teamInvites = currentTeamInvites
                user.games = games
                user.friends = friends
                user.pendingRequests = pendingRequests
                user.sentRequests = sentRequests
                user.gamerTag = gamerTag
                user.messagingNotifications = messagingNotifications
                user.pc = pc
                user.ps = ps
                user.xbox = xbox
                user.nintendo = nintendo
                user.bio = bio
                user.search = search
                user.notifications = notifications
                user.teamInviteRequests = teamInviteReqs
                user.subscriptions = subscriptions
                user.competitions = competitions
                user.currentTempRivals = rivals
                user.acceptedTempRivals = acceptedRivals
                user.rejectedTempRivals = rejectedRivals
                user.tempRivals = tempRivals
                user.viewedAnnouncements = viewedAnnouncements
                user.userLat = userLat
                user.userLong = userLong
                user.blockList = Array(blockList.keys)
                user.restrictList = Array(restrictList.keys)
                user.badges = badges
                user.reviews = reviews
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Successful Login"))
                    
                    self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
                }
            }
            else{
                let checkRef = Database.database().reference().child("Users").child(uid)
                let user = User(uId: uid)
                checkRef.child("platform").setValue("ios")
                checkRef.child("search").setValue("true")
                checkRef.child("registrationType").setValue(registrationType)
                checkRef.child("model").setValue(UIDevice.modelName)
                checkRef.child("notifications").setValue("true")
                    
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    self.performSegue(withIdentifier: "newReg", sender: nil)
                }
            }
            
            }) { (error) in
                AppEvents.logEvent(AppEvents.Name(rawValue: "Login Error"))
                print(error.localizedDescription)
        }
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    private func convertFriends(list: [String], pathString: String, userUid: String){
        let currentFriends = list
        var friends = [[String: String]]()
        
        if(!currentFriends.isEmpty){
            let ref = Database.database().reference().child("Users")
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                for _ in currentFriends{
                    for user in snapshot.children{
                        var contained = false
                        
                        let current = (user as! DataSnapshot)
                        let uId = current.key
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = current.childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        for tag in gamerTags{
                            if(list.contains(tag.gamerTag)){
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMMM.dd.yyyy"
                                let result = formatter.string(from: date)
                                
                                let newFriend = ["gamerTag": tag.gamerTag, "date": result, "uid": uId]
                                friends.append(newFriend)
                                
                                contained = true
                                
                                break
                            }
                        }
                        
                        if(contained){
                          break
                        }
                    }
                }
                
                if(!friends.isEmpty){
                    ref.child(userUid).child(pathString).setValue(friends)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    fileprivate var currentNonce: String?
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
    private func convertRequests(list: [String], pathString: String, userUid: String){
        var newArray = [FriendRequestObject]()
        let tempRequests = list
        if(!tempRequests.isEmpty){
            let ref = Database.database().reference().child("Users")
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                for _ in tempRequests{
                    for user in snapshot.children{
                        var contained = false
                        
                        let current = (user as! DataSnapshot)
                        let uId = current.key
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = current.childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        for tag in gamerTags{
                            if(list.contains(tag.gamerTag)){
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMMM.dd.yyyy"
                                let result = formatter.string(from: date)
                                
                                let newRequest = FriendRequestObject(gamerTag: tag.gamerTag, date: result, uid: uId)
                                newArray.append(newRequest)
                                
                                contained = true
                                break
                            }
                        }
                        if(contained){
                            break
                        }
                    }
                }
                
                var requests = [Dictionary<String, String>]()
                for request in newArray{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid]
                    requests.append(current)
                }
                
                if(!requests.isEmpty){
                    ref.child(userUid).child(pathString).setValue(requests)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func continueClickedPhone(){
        self.view.endEditing(true)
        let phoneNumber = self.phoneEntry.getFormattedPhoneNumber(format: .E164)
        if(phoneNumber != nil){
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber!, uiDelegate: nil) { (verificationID, error) in
              if let error = error {
                var buttons = [PopupDialogButton]()
                let title = "phone number signup error"
                let message = "there was an error signing you up. make sure your phone number is correct and try again."
                
                let button = DefaultButton(title: "try again.") { [weak self] in
                    self?.continueClickedPhone()
                    
                }
                buttons.append(button)
                
                let buttonOne = CancelButton(title: "nevermind") { [weak self] in
                    //do nothing
                }
                buttons.append(buttonOne)
                
                let popup = PopupDialog(title: title, message: message)
                popup.addButtons(buttons)

                // Present dialog
                self.present(popup, animated: true, completion: nil)
                return
              }
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                self.showCode()
            }
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))

        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)

        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.phoneEntry.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.phoneEntry.resignFirstResponder()
    }
    
    private func showCode(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "code") as! RegisterCodeDrawer
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = false
        transitionDelegate.customHeight = 550
        transitionDelegate.showCloseButton = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func transitionAfterPhoneRegistration(uid: String){
        let checkRef = Database.database().reference().child("Users").child((uid))
        checkRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                self.downloadDBRef(uid: uid, registrationType: "phone")
            }
            else{
                    let user = User(uId: uid)
                    checkRef.child("platform").setValue("ios")
                    checkRef.child("search").setValue("true")
                    checkRef.child("registrationType").setValue("google")
                    checkRef.child("model").setValue(UIDevice.modelName)
                    checkRef.child("notifications").setValue("true")
                    DispatchQueue.main.async {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.currentUser = user
                        self.performSegue(withIdentifier: "newReg", sender: nil)
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
      // ...
      if let error = error {
        // ...AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login Fail - " + error.localizedDescription))
        
        var buttons = [PopupDialogButton]()
        let title = "google login error."
        let message = "there was an error getting you logged into google. try again, or try registering using your email."
        
        let button = DefaultButton(title: "try again.") { [weak self] in
            self?.loginWithReadPermissions()
            
        }
        buttons.append(button)
        
        let buttonOne = CancelButton(title: "nevermind") { [weak self] in
            self?.hideWork()
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
        return
      }

      guard let authentication = user.authentication else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
               if let error = error {
                   let authError = error as NSError
                   AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Google Login Fail Firebase - " + authError.localizedDescription))
               }
               else{
                   if(authResult != nil){
                       let uId = authResult?.user.uid ?? ""
                    UserDefaults.standard.set(uId, forKey: "userId")
                    self.downloadDBRef(uid: uId, registrationType: "google")
                }
               else{
                let uId = authResult?.user.uid ?? ""
                if(!uId.isEmpty){
                    if(authResult != nil){
                        UserDefaults.standard.set(uId, forKey: "userId")
                        self.downloadDBRef(uid: uId, registrationType: "google")
                    }
                    else{
                        let checkRef = Database.database().reference().child("Users").child(uId)
                        let user = User(uId: uId)
                        checkRef.child("platform").setValue("ios")
                        checkRef.child("search").setValue("true")
                        checkRef.child("registrationType").setValue("google")
                        checkRef.child("model").setValue(UIDevice.modelName)
                        checkRef.child("notifications").setValue("true")
                            
                        DispatchQueue.main.async {
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            delegate.currentUser = user
                            self.performSegue(withIdentifier: "newReg", sender: nil)
                        }
                    }
                }
               }
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if (segue.identifier == "registerSocial") {
            if let destination = segue.destination as? RegisterActivity {
                destination.socialRegistered = self.selectedSocial
                destination.socialRegisteredUid = self.socialRegisteredUid
            }
        }
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
          if isValid {
            self.validPhone = true
          } else {
            self.validPhone = false
          }
       }
    
    func fpnDisplayCountryList() {
    
    }
    
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
