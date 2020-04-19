//
//  LoginController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import UnderLineTextField
import FBSDKCoreKit

class LoginController: UIViewController {
    private var data: [NewsObject]!
    private var games: [GamerConnectGame]!
    var handle: AuthStateDidChangeListenerHandle?
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordFieild: UITextField!
    @IBOutlet weak var registerText: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        games = [GamerConnectGame]()
        // Do any additional setup after loading the view, typically from a nib.
        
        loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(registerClicked))
        registerText.isUserInteractionEnabled = true
        registerText.addGestureRecognizer(singleTap)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Login"))
    }
    
    @objc func loginButtonClicked(_ sender: AnyObject?) {
        guard let email = emailField.text, let password = passwordFieild.text else { return }
        let manager = FirebaseAuthManager()
        manager.signIn(email: email, pass: password) {[weak self] (success) in
            guard let `self` = self else { return }
            var message: String = ""
            if (success) {
                let userID = Auth.auth().currentUser!.uid
                self.downloadDBRef(uid: userID)
                
                UserDefaults.standard.set(userID, forKey: "userId")
                //self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
            }
            else {
                message = "There was an error."
                
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
            }
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
    
    private func downloadDBRef(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
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
            
            }) { (error) in
                AppEvents.logEvent(AppEvents.Name(rawValue: "Login Error"))
                print(error.localizedDescription)
        }
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
    
    /*private func convertTeamInvites(list: [String], pathString: String, teamName: String){
        var newArray = [TeamInviteObject]()
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
                                
                                let newRequest = TeamInviteObject(gamerTag: tag.gamerTag, date: result, uid: uId)
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
                    let teamRef = Database.database().reference().child("Teams")
                    teamRef.child(teamName).child(pathString).setValue(requests)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }*/
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
