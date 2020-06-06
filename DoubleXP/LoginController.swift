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


class LoginController: UIViewController, GIDSignInDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
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
                        if(authResult != nil){
                            let uId = authResult?.user.uid ?? ""
                            self.downloadDBRef(uid: uId)
                        }
                        else{
                            self.performSegue(withIdentifier: "register", sender: nil)
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
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login"))
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
                    self.downloadDBRef(uid: userID)
                    
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
        showWork()
        
        self.selectedSocial = "facebook"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.loginWithReadPermissions()
        }
    }
    
    @objc func googleLoginClicked(_ sender: AnyObject?) {
        showWork()
        
        self.selectedSocial = "google"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            GIDSignIn.sharedInstance()?.presentingViewController = self
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    @available(iOS 13, *)
    @objc func appleLoginClicked(_ sender: AnyObject?) {
        //showWork()
        
        self.selectedSocial = "apple"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.startSignInWithAppleFlow()
        }
    }
    
    @objc func registerClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "register", sender: nil)
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
                    self.downloadDBRef(uid: uId)
                }
                else{
                    self.performSegue(withIdentifier: "register", sender: nil)
                }
            }
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
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType)
                        
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
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType)
                        
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
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType)
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
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType)
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
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Successful Login"))
                    
                    self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
                }
            }
            else{
                self.socialRegisteredUid = uid
                self.performSegue(withIdentifier: "registerSocial", sender: nil)
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
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
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
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
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
                       self.downloadDBRef(uid: uId)
                }
               else{
                   self.performSegue(withIdentifier: "register", sender: nil)
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
