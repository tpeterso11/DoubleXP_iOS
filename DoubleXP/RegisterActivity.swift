//
//  RegisterActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/12/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import ValidationComponents
import FBSDKCoreKit
import FacebookLogin
import PopupDialog
import GoogleSignIn


class RegisterActivity: UIViewController, UITextFieldDelegate, GIDSignInDelegate {
    @IBOutlet weak var headerImage: UIImageView!
    
    @IBOutlet weak var emailLoginCover: UIImageView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var closeX: UIImageView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var facebook: UIImageView!
    @IBOutlet weak var googleSignIn: UIView!
    
    private var emailEntered = false
    private var passwordEntered = false
    private var consoleChosen = false
    private var isMFAEnabled = false
    private var switches = [UISwitch]()
    private var facebookLoginAccepted = false
    private var googleLoginAccepted = false
    private var googleToken = ""
    private var facebookLoginUid = ""
    private var facebookTokenString = ""
    private var googleTokenString = ""
    private var registrationType = ""
    
    var socialRegistered = ""
    var socialRegisteredUid = ""
    
    func supportsAlertController() -> Bool {
        return NSClassFromString("UIAlertController") != nil
    }
    
    class SimpleTextPromptDelegate: NSObject, UIAlertViewDelegate {
    }
    
    func loginManagerDidComplete(_ result: LoginResult) {
        let alertController: UIAlertController
        switch result {
        case .cancelled:
            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Canceled"))
            
            var buttons = [PopupDialogButton]()
            let title = "facebook login canceled."
            let message = "facebook login was canceled.."
            
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
        case .failed(let error):
            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Fail - " + error.localizedDescription))
            
            var buttons = [PopupDialogButton]()
            let title = "facebook login error."
            let message = "there was an error getting you logged into facebook. try again, or try registering using your email."
            
            let button = DefaultButton(title: "try again.") { [weak self] in
                self?.loginWithReadPermissions()
                
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
            

        case .success(_, _, let token):
            self.facebookTokenString = token.tokenString
            self.facebookLoginAccepted = true
            
            self.emailLoginCover.image = #imageLiteral(resourceName: "facebook_logo.png")
            
            let top = CGAffineTransform(translationX: 0, y: 70)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5, options: [], animations: {
                            self.emailLoginCover.transform = top
                            self.emailLoginCover.alpha = 1
                            self.emailField.alpha = 0.1
                            self.emailField.isUserInteractionEnabled = false
                            self.passwordField.alpha = 0.1
                            self.passwordField.isUserInteractionEnabled = false
            }, completion: nil)
        }
    }

    @IBAction private func loginWithReadPermissions() {
        let loginManager = LoginManager()
        loginManager.logIn(
            permissions: [.publicProfile, .email],
            viewController: self
        ) { result in
            self.loginManagerDidComplete(result)
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
    
    @IBOutlet weak var backX: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.addTarget(self, action: #selector(nextButtonClicked(_:)), for: .touchUpInside)
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        backX.isUserInteractionEnabled = true
        backX.addGestureRecognizer(backTap)
        
        emailField.returnKeyType = .done
        emailField.delegate = self
        passwordField.returnKeyType = .done
        passwordField.delegate = self
        emailField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)

        let facebookTap = UITapGestureRecognizer(target: self, action: #selector(loginWithReadPermissions))
        facebook.isUserInteractionEnabled = true
        facebook.addGestureRecognizer(facebookTap)
        
        let googleTap = UITapGestureRecognizer(target: self, action: #selector(googleClicked))
        googleSignIn.isUserInteractionEnabled = true
        googleSignIn.addGestureRecognizer(googleTap)
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        
        GIDSignIn.sharedInstance().delegate = self
        
        checkNextButton()
        
        if(!socialRegistered.isEmpty && !socialRegisteredUid.isEmpty){
            if(socialRegistered == "google"){
                self.emailLoginCover.image = #imageLiteral(resourceName: "google_logo.png")
            }
            else{
                self.emailLoginCover.image = #imageLiteral(resourceName: "facebook_logo.png")
            }
            
            
            let top = CGAffineTransform(translationX: 0, y: 70)
            UIView.animate(withDuration: 0.8, delay: 0.5, usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.5, options: [], animations: {
                            self.emailLoginCover.transform = top
                            self.emailLoginCover.alpha = 1
                            self.emailField.alpha = 0.1
                            self.emailField.isUserInteractionEnabled = false
                            self.passwordField.alpha = 0.1
                            self.passwordField.isUserInteractionEnabled = false
            }, completion: nil)
            
            if(self.socialRegistered == "google"){
                self.googleLoginAccepted = true
            }
            else{
                self.facebookLoginAccepted = true
            }
        }
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Register"))
    }
    
    @objc func googleClicked(){
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func xboxSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func pcSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func nintendoSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    func registerUser(email: String?, pass: String?, facebook: Bool, google: Bool){
        if(facebook && self.socialRegistered.isEmpty){
            let credential = FacebookAuthProvider.credential(withAccessToken: self.facebookTokenString)
            Auth.auth().signIn(with: credential) { (authResult, error) in
              if let error = error {
              let authError = error as NSError
                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Fail Firebase - " + error.localizedDescription))
                
                var message: String = ""
                let code = String(error._code)
                
                switch(code){
                    case "17007": message = "sorry, that email is already in use."
                    case "17008": message = "sorry, please enter a valid email to continue."
                    case "17009": message = "sorry, that password is incorrect. please try again."
                    case "17011": message = "sorry, we do not have that user in our database."
                    default: message = "there was an error logging you in. please try again."
                }
                
                let alertController = UIAlertController(title: "registration error", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
              }
              else{
                if(authResult != nil){
                    let checkRef = Database.database().reference().child("Users").child((authResult?.user.uid)!)
                    checkRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        if(snapshot.exists()){
                            self.downloadDBRef(uid: (authResult?.user.uid)!)
                        }
                    else{
                        let uId = authResult?.user.uid ?? ""
                            let user = User(uId: uId)
                                
                            if(self.psSwitch.isOn){
                                user.ps = true
                            }
                            
                            if(self.pcSwitch.isOn){
                                user.pc = true
                            }
                            
                            if(self.xboxSwitch.isOn){
                                user.xbox = true
                            }
                            
                            if(self.nintendoSwitch.isOn){
                                user.nintendo = true
                            }
                            checkRef.child("consoles").child("xbox").setValue(self.xboxSwitch.isOn)
                            checkRef.child("consoles").child("ps").setValue(self.psSwitch.isOn)
                            checkRef.child("consoles").child("nintendo").setValue(self.nintendoSwitch.isOn)
                            checkRef.child("consoles").child("pc").setValue(self.pcSwitch.isOn)
                            checkRef.child("platform").setValue("ios")
                            checkRef.child("search").setValue("true")
                            checkRef.child("registrationType").setValue("facebook")
                            checkRef.child("model").setValue(UIDevice.modelName)
                            checkRef.child("notifications").setValue("true")
                                
                            DispatchQueue.main.async {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                delegate.currentUser = user
                                    
                                if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                                    AppEvents.logEvent(AppEvents.Name(rawValue: "Register - No GC"))
                                    self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                                }
                                else{
                                    if(user.pc){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PC User"))
                                    }
                                    if(user.xbox){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - xBox User"))
                                    }
                                    if(user.ps){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PS User"))
                                    }
                                    if(user.nintendo){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Nintendo User"))
                                    }
                                    
                                    AppEvents.logEvent(AppEvents.Name(rawValue: "Register - GC"))
                                    self.performSegue(withIdentifier: "registerGC", sender: nil)
                                }
                                }
                            }
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        else if(google && self.socialRegistered.isEmpty){
                let credential = GoogleAuthProvider.credential(withIDToken: self.googleToken,
                                                               accessToken: self.googleTokenString)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                   if let error = error {
                               let authError = error as NSError
                                 AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Fail Firebase - " + error.localizedDescription))
                                 
                                 var message: String = ""
                                 let code = String(error._code)
                                 
                                 switch(code){
                                     case "17007": message = "sorry, that email is already in use."
                                     case "17008": message = "sorry, please enter a valid email to continue."
                                     case "17009": message = "sorry, that password is incorrect. please try again."
                                     case "17011": message = "sorry, we do not have that user in our database."
                                     default: message = "there was an error logging you in. please try again."
                                 }
                                 
                                 let alertController = UIAlertController(title: "registration error", message: message, preferredStyle: .alert)
                                 alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                 self.display(alertController: alertController)
                               }
                  else{
                    if(authResult != nil){
                        let checkRef = Database.database().reference().child("Users").child((authResult?.user.uid)!)
                        checkRef.observeSingleEvent(of: .value, with: { (snapshot) in
                            if(snapshot.exists()){
                                self.downloadDBRef(uid: (authResult?.user.uid)!)
                            }
                            else{
                                let uId = authResult?.user.uid ?? ""
                                    let user = User(uId: uId)
                                        
                                    if(self.psSwitch.isOn){
                                        user.ps = true
                                    }
                                    
                                    if(self.pcSwitch.isOn){
                                        user.pc = true
                                    }
                                    
                                    if(self.xboxSwitch.isOn){
                                        user.xbox = true
                                    }
                                    
                                    if(self.nintendoSwitch.isOn){
                                        user.nintendo = true
                                    }
                                    checkRef.child("consoles").child("xbox").setValue(self.xboxSwitch.isOn)
                                    checkRef.child("consoles").child("ps").setValue(self.psSwitch.isOn)
                                    checkRef.child("consoles").child("nintendo").setValue(self.nintendoSwitch.isOn)
                                    checkRef.child("consoles").child("pc").setValue(self.pcSwitch.isOn)
                                    checkRef.child("platform").setValue("ios")
                                    checkRef.child("search").setValue("true")
                                    checkRef.child("registrationType").setValue("google")
                                    checkRef.child("model").setValue(UIDevice.modelName)
                                    checkRef.child("notifications").setValue("true")
                                        
                                    DispatchQueue.main.async {
                                        let delegate = UIApplication.shared.delegate as! AppDelegate
                                        delegate.currentUser = user
                                            
                                        if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - No GC"))
                                            self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                                        }
                                        else{
                                            if(user.pc){
                                                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PC User"))
                                            }
                                            if(user.xbox){
                                                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - xBox User"))
                                            }
                                            if(user.ps){
                                                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PS User"))
                                            }
                                            if(user.nintendo){
                                                AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Nintendo User"))
                                            }
                                            
                                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - GC"))
                                            self.performSegue(withIdentifier: "registerGC", sender: nil)
                                        }
                                        }
                                    }
                                }) { (error) in
                                    print(error.localizedDescription)
                                }
                            }
                    }
                }
            }
        else if(!self.emailField.text!.isEmpty && !self.passwordField.text!.isEmpty && self.socialRegistered.isEmpty){
            if(email != nil && pass != nil){
                Auth.auth().createUser(withEmail: email!, password: pass!) { authResult, error in
                    if let error = error {
                                 let authError = error as NSError
                                   AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Facebook Login Fail Firebase - " + error.localizedDescription))
                                   
                                   var message: String = ""
                                   let code = String(error._code)
                                   
                                   switch(code){
                                       case "17007": message = "sorry, that email is already in use."
                                       case "17008": message = "sorry, please enter a valid email to continue."
                                       case "17009": message = "sorry, that password is incorrect. please try again."
                                       case "17011": message = "sorry, we do not have that user in our database."
                                       default: message = "there was an error logging you in. please try again."
                                   }
                                   
                                   let alertController = UIAlertController(title: "registration error", message: message, preferredStyle: .alert)
                                   alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                   self.display(alertController: alertController)
                                 }
                    else{
                        if(authResult != nil){
                            let uId = authResult?.user.uid ?? ""
                            let user = User(uId: uId)
                            
                            if(self.psSwitch.isOn){
                                user.ps = true
                            }
                            
                            if(self.pcSwitch.isOn){
                                user.pc = true
                            }
                            
                            if(self.xboxSwitch.isOn){
                                user.xbox = true
                            }
                            
                            if(self.nintendoSwitch.isOn){
                                user.nintendo = true
                            }
                            
                            let ref = Database.database().reference().child("Users").child((authResult?.user.uid)!)
                            ref.child("consoles").child("xbox").setValue(self.xboxSwitch.isOn)
                            ref.child("consoles").child("ps").setValue(self.psSwitch.isOn)
                            ref.child("consoles").child("nintendo").setValue(self.nintendoSwitch.isOn)
                            ref.child("consoles").child("pc").setValue(self.pcSwitch.isOn)
                            ref.child("platform").setValue("ios")
                            ref.child("search").setValue("true")
                            ref.child("registrationType").setValue("email")
                            ref.child("model").setValue(UIDevice.modelName)
                            ref.child("notifications").setValue("true")
                            
                            DispatchQueue.main.async {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                delegate.currentUser = user
                                
                                if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                                    AppEvents.logEvent(AppEvents.Name(rawValue: "Register - No GC"))
                                    self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                                }
                                else{
                                    if(user.pc){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PC User"))
                                    }
                                    if(user.xbox){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - xBox User"))
                                    }
                                    if(user.ps){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PS User"))
                                    }
                                    if(user.nintendo){
                                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Nintendo User"))
                                    }
                                    
                                    AppEvents.logEvent(AppEvents.Name(rawValue: "Register - GC"))
                                    self.performSegue(withIdentifier: "registerGC", sender: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
        else{
            if(!self.socialRegistered.isEmpty && !socialRegisteredUid.isEmpty){
                let user = User(uId: self.socialRegisteredUid)
                
                if(self.psSwitch.isOn){
                    user.ps = true
                }
                
                if(self.pcSwitch.isOn){
                    user.pc = true
                }
                
                if(self.xboxSwitch.isOn){
                    user.xbox = true
                }
                
                if(self.nintendoSwitch.isOn){
                    user.nintendo = true
                }
                
                let ref = Database.database().reference().child("Users").child(self.socialRegisteredUid)
                ref.child("consoles").child("xbox").setValue(self.xboxSwitch.isOn)
                ref.child("consoles").child("ps").setValue(self.psSwitch.isOn)
                ref.child("consoles").child("nintendo").setValue(self.nintendoSwitch.isOn)
                ref.child("consoles").child("pc").setValue(self.pcSwitch.isOn)
                ref.child("platform").setValue("ios")
                ref.child("search").setValue("true")
                ref.child("registrationType").setValue(self.socialRegistered)
                ref.child("model").setValue(UIDevice.modelName)
                ref.child("notifications").setValue("true")
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    
                    if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - No GC"))
                        self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                    }
                    else{
                        if(user.pc){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PC User"))
                        }
                        if(user.xbox){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - xBox User"))
                        }
                        if(user.ps){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PS User"))
                        }
                        if(user.nintendo){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Nintendo User"))
                        }
                        
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - GC"))
                        self.performSegue(withIdentifier: "registerGC", sender: nil)
                    }
                }
            }
            else{
                var buttons = [PopupDialogButton]()
                let title = "login error."
                let message = "there was an error getting you logged in. try again, or feel free to reach out if there is an issue."
                
                let button = DefaultButton(title: "try again.") { [weak self] in
                    self?.loginWithReadPermissions()
                }
                buttons.append(button)
                
                let buttonOne = CancelButton(title: "nevermind") { [weak self] in
                    self?.backButtonClicked(nil)
                }
                buttons.append(buttonOne)
                
                let popup = PopupDialog(title: title, message: message)
                popup.addButtons(buttons)

                // Present dialog
                self.present(popup, animated: true, completion: nil)
            }
        }
    }
    
    private func downloadDBRef(uid: String){
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
                
                let search = value?["search"] as? String ?? ""
                if(search.isEmpty){
                    ref.child("search").setValue("true")
                }
                
                let notifications = value?["notifications"] as? String ?? ""
                if(notifications.isEmpty){
                    ref.child("notifications").setValue("true")
                }
                
                var sentRequests = [FriendRequestObject]()
                let sentArray = snapshot.childSnapshot(forPath: "sent_requests")
                for friend in sentArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    sentRequests.append(newFriend)
                }
                
                var pendingRequests = [FriendRequestObject]()
                let requestsArray = snapshot.childSnapshot(forPath: "pending_friends")
                for friend in requestsArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    pendingRequests.append(newFriend)
                }
                
                var teamInviteReqs = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["teamCaptainId"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let gamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     let questions = profileDict?["questions"] as? [[String]] ?? [[String]]()
                     
                     let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                     let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                     newRequest.profile = result
                     
                     teamInviteReqs.append(newRequest)
                }
                
                var friends = [FriendObject]()
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
                
                
                let games = value?["games"] as? [String] ?? [String]()
                var gamerTags = [GamerProfile]()
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                for gamerTagObj in gamerTagsArray.children {
                    let currentObj = gamerTagObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let currentTag = dict?["gamerTag"] as? String ?? ""
                    let currentGame = dict?["game"] as? String ?? ""
                    let console = dict?["console"] as? String ?? ""
                    
                    let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                    gamerTags.append(currentGamerTagObj)
                }
                
                let messagingNotifications = value?["messagingNotifications"] as? Bool ?? false
                var teams = [TeamObject]()
                let teamsArray = snapshot.childSnapshot(forPath: "teams")
                for teamObj in teamsArray.children {
                    let currentObj = teamObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let teamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                    let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                    
                    var invites = [TeamInviteObject]()
                    let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                    for invite in teamInvites.children{
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let teamName = dict?["teamName"] as? String ?? ""
                        
                        let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                        invites.append(newInvite)
                    }
                    
                    var teammateArray = [TeammateObject]()
                    if(currentObj.hasChild("teammates")){
                        let teammates = currentObj.childSnapshot(forPath: "teammates")
                        for teammate in teammates.children{
                            let currentTeammate = teammate as! DataSnapshot
                            let dict = currentTeammate.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                            teammateArray.append(teammate)
                        }
                    }
                    
                    let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let captain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? String()
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let captainId = dict?["teamCaptainId"] as? String ?? String()
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                    currentTeam.teammates = teammateArray
                    teams.append(currentTeam)
                }
                
                var currentTeamInvites = [TeamObject]()
                let teamInvitesArray = snapshot.childSnapshot(forPath: "teamInvites")
                for teamObj in teamInvitesArray.children {
                    let currentObj = teamObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let teamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                    let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                    
                    var invites = [TeamInviteObject]()
                    let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                    for invite in teamInvites.children{
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let teamName = dict?["teamName"] as? String ?? ""
                        
                        let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                        invites.append(newInvite)
                    }
                    
                    var teammateArray = [TeammateObject]()
                    if(currentObj.hasChild("teammates")){
                        let teammates = currentObj.childSnapshot(forPath: "teammates")
                        for teammate in teammates.children{
                            let currentTeammate = teammate as! DataSnapshot
                            let dict = currentTeammate.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                            teammateArray.append(teammate)
                        }
                    }
                    
                    let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let captain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? String()
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let captainId = dict?["teamCaptainId"] as? String ?? String()
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                    currentTeam.teammates = teammateArray
                    currentTeamInvites.append(currentTeam)
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
                    
                    let currentStat = StatObject(gameName: gameName)
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
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Successful Login"))
                    
                    self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
                }
            }
            
            }) { (error) in
                AppEvents.logEvent(AppEvents.Name(rawValue: "Login Error"))
                print(error.localizedDescription)
        }
    }

    func checkNextButton(){
        if((self.emailEntered && passwordEntered && checkSwitches()) || (self.emailLoginCover.alpha == 1 && self.facebookLoginAccepted && checkSwitches()) || (self.googleLoginAccepted && checkSwitches())){
            self.nextButton.alpha = 1
        }
        else{
            self.nextButton.alpha = 0.3
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == self.emailField && textField.text?.count ?? 0 > 5){
            self.emailEntered = true
            checkNextButton()
        }
        else{
            if(textField.text?.count ?? 0 > 5){
                self.passwordEntered = true
                checkNextButton()
            }
        }
    }
    
    private func checkSwitches() -> Bool{
        var switchOn = false
        for uiSwitch in self.switches{
            if(uiSwitch.isOn){
                switchOn = true
                break
            }
        }
        
        return switchOn
    }
    
    private func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        let email = emailField.text ?? ""
        let pass = passwordField.text ?? ""
        
        let rule = EmailValidationPredicate()
        
        //registerUser(email: email, pass: pass)
        if(!email.isEmpty && !pass.isEmpty && rule.evaluate(with: email)){
            registerUser(email: email, pass: pass, facebook: false, google: false)
        }
        else if(self.facebookLoginAccepted && !self.facebookTokenString.isEmpty){
            registerUser(email: nil, pass: nil, facebook: true, google: false)
        }
        else if(self.googleLoginAccepted && !self.googleTokenString.isEmpty && !self.googleToken.isEmpty){
            registerUser(email: nil, pass: nil, facebook: false, google: true)
        }
        else if(!self.socialRegistered.isEmpty && !self.socialRegisteredUid.isEmpty){
            registerUser(email: nil, pass: nil, facebook: socialRegistered == "facebook", google: socialRegistered == "google")
        }
        else{
            if(!rule.evaluate(with: email)){
                let message = "Must enter a valid email to continue."
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
                
                return
            }
            
            if(pass.isEmpty){
                let message = "Must enter a password to continue."
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
                
                return
            }
            
            let message = "Must enter a valid email and/or password to continue."
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.display(alertController: alertController)
        }
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "registerBack", sender: nil)
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
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
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
        return
      }

      guard let authentication = user.authentication else { return }

        self.googleTokenString = authentication.accessToken
        self.googleToken = authentication.idToken
        self.googleLoginAccepted = true
        
        self.emailLoginCover.image = #imageLiteral(resourceName: "google_logo.png")
        
        let top = CGAffineTransform(translationX: 0, y: 70)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5, options: [], animations: {
                        self.emailLoginCover.transform = top
                        self.emailLoginCover.alpha = 1
                        self.emailField.alpha = 0.1
                        self.emailField.isUserInteractionEnabled = false
                        self.passwordField.alpha = 0.1
                        self.passwordField.isUserInteractionEnabled = false
        }, completion: nil)
        
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

    
    /*func showTextInputPrompt(withMessage message: String?,  completion: ((Bool, String) -> Void)? = nil) {
        if supportsAlertController() {
            let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            weak var weakPrompt = prompt
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                    completion!(false, "")
                })
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
                    let strongPrompt = weakPrompt
                    completion!(true, (strongPrompt?.textFields?[0].text) ?? "")
                })
            prompt.addTextField(configurationHandler: nil)
            prompt.addAction(cancelAction)
            prompt.addAction(okAction)
            present(prompt, animated: true)
        }
        else {
            let prompt = SimpleTextPromptDelegate()
            let alertView = UIAlertView(title: "", message: message ?? "error", delegate: prompt, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
            alertView.alertViewStyle = .plainTextInput
            alertView.show()
        }
    }*/
}

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
