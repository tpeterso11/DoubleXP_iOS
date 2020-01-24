//
//  PreSplashActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftHTTP
import ImageLoader
import Firebase

class PreSplashActivity: UIViewController {
    private var data: [NewsObject]!
    private var games: [GamerConnectGame]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        games = [GamerConnectGame]()
        // Do any additional setup after loading the view, typically from a nib.
        getAppConfig()
    }
    
    func getAppConfig(){
        HTTP.GET("http://doublexpstorage.tech/app-json/appconfig.json") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [[String: Any]] {
                    
                    let appProps = NSMutableDictionary()
                    for item in jsonObj {
                        var name = ""
                        var newValue = ""
                        if let configDict = item as? [String: Any]{
                            for (key, value) in configDict {
                                if(key == "name"){
                                    name = (value as? String)!
                                }
                                else{
                                    appProps.setValue(value, forKeyPath: name)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.appProperties = appProps
                    }
                    
                    self.loadGCGames()
                }
            }
        }
    }
    
    func loadGCGames(){
        HTTP.GET("https://firebasestorage.googleapis.com/v0/b/gameterminal-767f7.appspot.com/o/config%2Fregister_config3.json?alt=media&token=944235d2-2f3b-48fa-9a67-15abfd4a340e") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "Games") as? NSArray {
                        for game in resultArray{
                            var hook = ""
                            var gameName = ""
                            var imageUrl = ""
                            var developer = ""
                            var statsAvailable = false
                            var teamNeeds = [String]()
                            if let gameDict = game as? NSDictionary {
                                hook = (gameDict.value(forKey: "hook") as? String)!
                                gameName = (gameDict.value(forKey: "gameName") as? String)!
                                imageUrl = (gameDict.value(forKey: "headerImageUrlXXHDPI") as? String)!
                                developer = (gameDict.value(forKey: "developer") as? String)!
                                statsAvailable = (gameDict.value(forKey: "statsAvailable") as? Bool)!
                                teamNeeds = (gameDict.value(forKey: "teamNeeds") as? [String]) ?? [String]()
                                
                                let newGame  = GamerConnectGame(imageUrl: imageUrl, gameName: gameName, developer: developer, hook: hook, statsAvailable: statsAvailable, teamNeeds: teamNeeds)
                                self.games.append(newGame)
                                }
                            }
                        }
                    }
                }
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.gcGames = self.games
                    
                    let uId = UserDefaults.standard.string(forKey: "userId")
                    if(uId != nil){
                        if(!uId!.isEmpty){
                            self.downloadDBRef(uid: uId!)
                            //self.performSegue(withIdentifier: "newLogin", sender: nil)
                        }
                        else{
                            self.performSegue(withIdentifier: "newLogin", sender: nil)
                        }
                    }
                    else{
                        self.performSegue(withIdentifier: "newLogin", sender: nil)
                    }
                }
            }
        }
    
    private func downloadDBRef(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
            let value = snapshot.value as? NSDictionary
            let uId = snapshot.key
            let gamerTag = value?["gamerTag"] as? String ?? ""
            let bio = value?["bio"] as? String ?? ""
            var sentRequests = [FriendRequestObject]()
            
            //if sent requests have not been converted, we convert NOW.
            if(value?["sent_requests"] is [String]){
                self.convertRequests(list: value?["sent_requests"] as! [String], pathString: "sent_requests", userUid: uId)
            }
            else{
                let friendsArray = snapshot.childSnapshot(forPath: "sent_requests")
                for friend in friendsArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
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
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    pendingRequests.append(newFriend)
                }
            }
            
            var friends = [FriendObject]()
            if(value?["friends"] is [String]){
                self.convertFriends(list: value?["friends"] as! [String], pathString: "friends", userUid: uId)
            }
            else{
                let friendsArray = snapshot.childSnapshot(forPath: "friends")
                for friend in friendsArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                    friends.append(newFriend)
                }
            }
            
            let games = value?["games"] as? [String] ?? [String]()
            var gamerTags = [GamerProfile]()
            let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
            for gamerTagObj in gamerTagsArray.children {
                let currentObj = gamerTagObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let currentTag = dict["gamerTag"] as? String ?? ""
                let currentGame = dict["game"] as? String ?? ""
                let console = dict["console"] as? String ?? ""
                
                let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                gamerTags.append(currentGamerTagObj)
            }
            let messagingNotifications = value?["messagingNotifications"] as? Bool ?? false
            var teams = [TeamObject]()
            let teamsArray = snapshot.childSnapshot(forPath: "teams")
            for teamObj in teamsArray.children {
                let currentObj = teamObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let teamName = dict["teamName"] as? String ?? ""
                let teamId = dict["teamId"] as? String ?? ""
                let games = dict["games"] as? [String] ?? [String]()
                let consoles = dict["consoles"] as? [String] ?? [String]()
                let teammateTags = dict["teammateTags"] as? [String] ?? [String]()
                let teammateIds = dict["teammateIds"] as? [String] ?? [String]()
                
                var invites = [TeamInviteObject]()
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid)
                    invites.append(newInvite)
                }
                
                let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                let captain = dict["teamCaptain"] as? String ?? ""
                let imageUrl = dict["imageUrl"] as? String ?? ""
                let teamChat = dict["teamChat"] as? String ?? String()
                let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                
                let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                
                var teammateArray = [TeammateObject]()
                if(currentObj.hasChild("teammates")){
                    let teammates = currentObj.childSnapshot(forPath: "teammates")
                    for teammate in teammates.children{
                        let currentTeammate = teammate as! DataSnapshot
                        let dict = currentTeammate.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
                        let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                        teammateArray.append(teammate)
                    }
                    currentTeam.teammates = teammateArray
                    teams.append(currentTeam)
                }
            }
            
            var currentTeamInvites = [TeamObject]()
            let teamInvitesArray = snapshot.childSnapshot(forPath: "teamInvites")
            for teamObj in teamInvitesArray.children {
                let currentObj = teamObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let teamName = dict["teamName"] as? String ?? ""
                let teamId = dict["teamId"] as? String ?? ""
                let games = dict["games"] as? [String] ?? [String]()
                let consoles = dict["consoles"] as? [String] ?? [String]()
                let teammateTags = dict["teammateTags"] as? [String] ?? [String]()
                let teammateIds = dict["teammateIds"] as? [String] ?? [String]()
                
                var invites = [TeamInviteObject]()
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid)
                    invites.append(newInvite)
                }
                
                let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                let captain = dict["teamCaptain"] as? String ?? ""
                let imageUrl = dict["imageUrl"] as? String ?? ""
                let teamChat = dict["teamChat"] as? String ?? String()
                let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                
                let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                
                var teammateArray = [TeammateObject]()
                if(currentObj.hasChild("teammates")){
                    let teammates = currentObj.childSnapshot(forPath: "teammates")
                    for teammate in teammates.children{
                        let currentTeammate = teammate as! DataSnapshot
                        let dict = currentTeammate.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
                        let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                        teammateArray.append(teammate)
                    }
                    
                    currentTeam.teammates = teammateArray
                }
                
                teams.append(currentTeam)
                
                currentTeamInvites.append(currentTeam)
            }
            
            var currentStats = [StatObject]()
            let statsArray = snapshot.childSnapshot(forPath: "stats")
            for statObj in statsArray.children {
                let currentObj = statObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let gameName = dict["gameName"] as? String ?? ""
                let playerLevelGame = dict["playerLevelGame"] as? String ?? ""
                let playerLevelPVP = dict["playerLevelPVP"] as? String ?? ""
                let killsPVP = dict["killsPVP"] as? String ?? ""
                let killsPVE = dict["killsPVE"] as? String ?? ""
                let statURL = dict["statURL"] as? String ?? ""
                let setPublic = dict["setPublic"] as? String ?? ""
                let authorized = dict["authorized"] as? String ?? ""
                let currentRank = dict["currentRank"] as? String ?? ""
                let totalRankedWins = dict["otalRankedWins"] as? String ?? ""
                let totalRankedLosses = dict["totalRankedLosses"] as? String ?? ""
                let totalRankedKills = dict["totalRankedKills"] as? String ?? ""
                let totalRankedDeaths = dict["totalRankedDeaths"] as? String ?? ""
                let mostUsedAttacker = dict["mostUsedAttacker"] as? String ?? ""
                let mostUsedDefender = dict["mostUsedDefender"] as? String ?? ""
                let gearScore = dict["gearScore"] as? String ?? ""
                
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
                
                currentStats.append(currentStat)
            }
            
            let consoleArray = snapshot.childSnapshot(forPath: "consoles")
            let dict = consoleArray.value as! [String: Bool]
            let nintendo = dict["nintendo"] ?? false
            let ps = dict["ps"] ?? false
            let xbox = dict["xbox"] ?? false
            let pc = dict["pc"] ?? false
            
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
            
            DispatchQueue.main.async {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.currentUser = user
                
                self.performSegue(withIdentifier: "homeTransition", sender: nil)
            }
            
            }) { (error) in
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
                            let dict = currentObj.value as! [String: Any]
                            let currentTag = dict["gamerTag"] as? String ?? ""
                            let currentGame = dict["game"] as? String ?? ""
                            let console = dict["console"] as? String ?? ""
                            
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
                            let dict = currentObj.value as! [String: Any]
                            let currentTag = dict["gamerTag"] as? String ?? ""
                            let currentGame = dict["game"] as? String ?? ""
                            let console = dict["console"] as? String ?? ""
                            
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
    
    private func convertTeamInvites(list: [String], pathString: String, teamName: String){
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
                            let dict = currentObj.value as! [String: Any]
                            let currentTag = dict["gamerTag"] as? String ?? ""
                            let currentGame = dict["game"] as? String ?? ""
                            let console = dict["console"] as? String ?? ""
                            
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "homeTransition") {
            let controller = segue.destination as! LandingActivity
            let _ = controller.view
        }
    }
}
