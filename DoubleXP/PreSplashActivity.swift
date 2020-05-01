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
import TwitterKit
import SwiftTwitch
import Marshal
import SwiftDate

class PreSplashActivity: UIViewController {
    private var data: [NewsObject]!
    private var games: [GamerConnectGame]!
    
    struct Constants {
        static let secret = "uyvhqn68476njzzdvja9ulqsb8esn3"
        static let id = "aio1d4ucufi6bpzae0lxtndanh3nob"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        games = [GamerConnectGame]()
        // Do any additional setup after loading the view, typically from a nib.
        
        //let social = SocialMediaManager()
        //social.getGame()
        //getTwitchToken()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.getAppConfig()
        }
        
        //let test = ["gamerTag": "SUCCESSFUL!!!!!!!", "game": "Test", "observableTime": "0", "timeInMs": "50000"]
                   
                   //array.append(test)
                   //let appDelegate = UIApplication.shared.delegate as! AppDelegate
                   //let allNewChildrenRef = Database.database().reference().child("Users").child("UNrTyfFOeHZB3T2HQvUVevIxHkE2")
                   //allNewChildrenRef.child("tempRivals").setValue(test)
               //allNewChildrenRef.child("thisShitIsSoAnnoying").setValue("YOU!")
        
        //testLoadTwitter()
    }
    
    func getAppConfig(){
        HTTP.GET("http://doublexpstorage.tech/app-json/tes.json") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [[String: Any]] {
                    
                    let appProps = NSMutableDictionary()
                    var games = [TwitchChannelObj]()
                    for item in jsonObj {
                        var name = ""
                        var newValue = ""
                        if let configDict = item as? [String: Any]{
                            for (key, value) in configDict {
                                //check the payload. in every object, there is a key, and a value.
                                //open every object. the key is the actual name, the value is in the value object as an ns string.
                                //ex. in the object you get back, object 2, key is enabled. value(any), open it, see that the payload is "false". Find a way to parse that.
                                if(key == "name"){
                                    name = (value as? String)!
                                }
                                else if(key == "games"){
                                    if let gamesDict = value as? [[String: String]]{
                                        for game in gamesDict{
                                            let gameName = game["name"]
                                            let developer = game["developer"]
                                            let developerLight = game["developerLogoLight"]
                                            let developerDark = game["developerLogoDark"]
                                            let description = game["gameDescription"]
                                            let imageUrlIOS = game["imageUrlIOS"]
                                            let twitchId = game["twitch_id"]
                                            let isGCGame = game["isGCGame"]
                                            let gcGameName = game["gcGameName"]
                                            
                                            let channel = TwitchChannelObj(gameName: gameName ?? "", imageUrIOS: imageUrlIOS ?? "", twitchID: twitchId ?? "")
                                            channel.developer = developer ?? ""
                                            channel.developerLogoDarkUrl = developerDark ?? ""
                                            channel.developerLogoLightUrl = developerLight ?? ""
                                            channel.gameDescription = description ?? ""
                                            channel.gcGameName = gcGameName ?? ""
                                            channel.isGCGame = isGCGame ?? ""
                                            
                                            games.append(channel)
                                        }
                                        DispatchQueue.main.async {
                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            appDelegate.twitchChannels = games
                                        }
                                    }
                                }
                                else{
                                    if(name.isEmpty){
                                        name = key
                                    }
                                    var name2 = name
                                    var value2 = value as? String
                                    appProps.setValue(value, forKeyPath: name)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.appProperties = appProps
                    }
                    self.destroyCache()
                    self.loadGCGames()
                }
            }
        }
    }
    
    private func destroyCache() {
        let fileManager = FileManager.default
        let documentsUrl =  fileManager.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path
        let bundleIdentifier = Bundle.main.bundleIdentifier! as String
        do {
            if let documentPath = documentsPath
            {
                let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)/\(bundleIdentifier)")
                for fileName in fileNames {
                    let filePathName = "\(documentPath)/\(bundleIdentifier)/\(fileName)"
                    try fileManager.removeItem(atPath: filePathName)
                }
            }

        } catch {
            print("Could not clear: \(error)")
        }
    }
    
    func loadGCGames(){
        HTTP.GET("http://doublexpstorage.tech/app-json/gcGames.json") { response in
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
                            var secondaryName = ""
                            var twitterHandle = ""
                            var twitchHandle = ""
                            var gameModes = [String]()
                            var statsAvailable = false
                            var teamNeeds = [String]()
                            if let gameDict = game as? NSDictionary {
                                hook = (gameDict.value(forKey: "hook") as? String ?? "")
                                gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                                imageUrl = (gameDict.value(forKey: "headerImageUrlXXHDPI") as? String ?? "")
                                developer = (gameDict.value(forKey: "developer") as? String ?? "")
                                statsAvailable = (gameDict.value(forKey: "statsAvailable") as? Bool ?? false)
                                teamNeeds = (gameDict.value(forKey: "teamNeeds") as? [String]) ?? [String]()
                                secondaryName = (gameDict.value(forKey: "secondaryName") as? String ?? "")
                                gameModes = (gameDict).value(forKey: "gameModes") as? [String] ?? [String]()
                                twitterHandle = (gameDict).value(forKey: "twitterHandle") as? String ?? ""
                                twitchHandle = (gameDict).value(forKey: "twitchHandle") as? String ?? ""
                                
                                let newGame  = GamerConnectGame(imageUrl: imageUrl, gameName: gameName, developer: developer, hook: hook, statsAvailable: statsAvailable, teamNeeds: teamNeeds,
                                                                twitterHandle: twitterHandle, twitchHandle: twitchHandle)
                                newGame.secondaryName = secondaryName
                                newGame.gameModes = gameModes
                                self.games.append(newGame)
                                }
                            }
                        }
                    }
                }
            
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.gcGames = self.games
                    
                    let uId = UserDefaults.standard.string(forKey: "userId")
                    self.getCompetitions(uid: uId)
                }
            }
        }
    
    func getCompetitions(uid: String?){
        let ref = Database.database().reference().child("Competitions")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var displayCompetitions = [CompetitionObj]()
                
                for competition in snapshot.children{
                    let currentObj = competition as? DataSnapshot
                    let dict = currentObj?.value as? [String: Any]
                    
                    let competitonName = dict?["competitionName"] as? String ?? ""
                    let competitionId = dict?["competitionId"] as? String ?? ""
                    let gameName = dict?["gameName"] as? String ?? ""
                    let mainSponsor = dict?["mainSponsor"] as? String ?? ""
                    let topPrize = dict?["topPrize"] as? String ?? ""
                    let secondPrize = dict?["secondPrize"] as? String ?? ""
                    let thirdPrize = dict?["thirdPrize"] as? String ?? ""
                    let competitionDate = dict?["competitionDate"] as? String ?? ""
                    let competitionAirDate = dict?["competitionAirDate"] as? String ?? ""
                    let competitionAirDateString = dict?["competitionAirDateString"] as? String ?? ""
                    let competitionDateString = dict?["competitionDateString"] as? String ?? ""
                    let registrationDeadlineMillis = dict?["registrationDeadlineMillis"] as? CLong ?? 0
                    let twitchChannelId = dict?["twitchChannelId"] as? String ?? ""
                    let gcName = dict?["gcName"] as? String ?? ""
                    let subscriptionId = dict?["subscriptionId"] as? String ?? ""
                    
                    /*var competitors = [CompetitorObj]()
                    let competitorArray = competition.childSnapshot(forPath: "competitors")
                    for competitor in competitorArray.children{
                        let currentObj = competitor as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newCompetitor = CompetitorObj(gamerTag: gamerTag, uid: uid)
                        competitors.append(newCompetitor)
                    }*/
                    
                    let newCompetition = CompetitionObj(competitionName: competitonName, competitionId: competitionId, gameName: gameName, mainSponsor: mainSponsor)
                    newCompetition.topPrize = topPrize
                    newCompetition.secondPrize = secondPrize
                    newCompetition.thirdPrize = thirdPrize
                    newCompetition.registrationDeadlineMillis = String(registrationDeadlineMillis)
                    newCompetition.twitchChannelId = twitchChannelId
                    newCompetition.competitionDate = competitionDate
                    newCompetition.competitionDateString = competitionDateString
                    newCompetition.competitionAirDate = competitionAirDate
                    newCompetition.competitionAirDateString = competitionAirDateString
                    newCompetition.gcName = gcName
                    newCompetition.subscriptionId = subscriptionId
                    
                    displayCompetitions.append(newCompetition)
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.competitions = displayCompetitions
                
                if(uid != nil){
                    if(!uid!.isEmpty){
                        self.downloadDBRef(uid: uid!)
                    }
                    else{
                        self.performSegue(withIdentifier: "newLogin", sender: nil)
                    }
                }
                else{
                    self.performSegue(withIdentifier: "newLogin", sender: nil)
                }
            }
            else{
                if(uid != nil){
                    if(!uid!.isEmpty){
                        self.downloadDBRef(uid: uid!)
                    }
                    else{
                        self.performSegue(withIdentifier: "newLogin", sender: nil)
                    }
                }
                else{
                    self.performSegue(withIdentifier: "newLogin", sender: nil)
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            
            if(uid != nil){
                if(!uid!.isEmpty){
                    self.downloadDBRef(uid: uid!)
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
            
            var dbRequests = [RequestObject]()
            let teamRequests = snapshot.childSnapshot(forPath: "inviteRequests")
            for invite in teamRequests.children{
               let currentObj = invite as! DataSnapshot
               let dict = currentObj.value as? [String: Any]
               let status = dict?["status"] as? String ?? ""
               let teamId = dict?["teamId"] as? String ?? ""
               let teamName = dict?["teamName"] as? String ?? ""
               let captainId = dict?["teamCaptainId"] as? String ?? ""
               let requestId = dict?["requestId"] as? String ?? ""
                
               var requestProfiles = [FreeAgentObject]()
               let test = dict?["profile"] as? [String: Any] ?? [String: Any]()
               let game = test["game"] as? String ?? ""
               let consoles = test["consoles"] as? [String] ?? [String]()
               let gamerTag = test["gamerTag"] as? String ?? ""
               let competitionId = test["competitionId"] as? String ?? ""
               let userId = test["userId"] as? String ?? ""
               let questions = test["questions"] as? [[String]] ?? [[String]]()
               
               let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
               
               requestProfiles.append(result)
               
               
               let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
               newRequest.profile = requestProfiles[0]
               
               dbRequests.append(newRequest)
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
            
            let games = value?["games"] as? [String] ?? [String]()
            var gamerTags = [GamerProfile]()
            let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
            for gamerTagObj in gamerTagsArray.children {
                let currentObj = gamerTagObj as! DataSnapshot
                let dict = currentObj.value as? [String: Any]
                let currentTag = dict?["gamerTag"] as? String ?? ""
                let currentGame = dict?["game"] as? String ?? ""
                let console = dict?["console"] as? String ?? ""
                
                if(currentTag != "" && currentGame != "" && console != ""){
                    let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                    gamerTags.append(currentGamerTagObj)
                }
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
                            let dbDateFuture = calendar.date(byAdding: .minute, value: 5, to: dbDate as Date)
                            
                            if(dbDateFuture != nil){
                                let now = NSDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                                let future = formatter.string(from: now as Date)
                                let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                                
                                let validRival = dbDate.compare(.isEarlier(than: dbFuture))
                                
                                if(dbFuture != nil){
                                    if(validRival){
                                        rivals.append(request)
                                    }
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
                            let future = formatter.string(from: now as Date)
                            let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validRival = dbDate.compare(.isEarlier(than: dbFuture))
                            
                            if(dbFuture != nil){
                                if(validRival){
                                    tempRivals.append(request)
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
                
                var teamInviteRequests = [RequestObject]()
                let teamRequests = currentObj.childSnapshot(forPath: "inviteRequests")
                for invite in teamRequests.children{
                   let currentObj = invite as! DataSnapshot
                   let dict = currentObj.value as? [String: Any]
                   let status = dict?["status"] as? String ?? ""
                   let teamId = dict?["teamId"] as? String ?? ""
                   let teamName = dict?["teamName"] as? String ?? ""
                   let captainId = dict?["teamCaptainId"] as? String ?? ""
                   let requestId = dict?["requestId"] as? String ?? ""
                    
                   var requestProfiles = [FreeAgentObject]()
                   let test = dict?["profile"] as? [String: Any] ?? [String: Any]()
                   let game = test["game"] as? String ?? ""
                   let consoles = test["consoles"] as? [String] ?? [String]()
                   let gamerTag = test["gamerTag"] as? String ?? ""
                   let competitionId = test["competitionId"] as? String ?? ""
                   let userId = test["userId"] as? String ?? ""
                   let questions = test["questions"] as? [[String]] ?? [[String]]()
                   
                   let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                   
                   requestProfiles.append(result)
                   
                   
                   let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                   newRequest.profile = requestProfiles[0]
                   
                   teamInviteRequests.append(newRequest)
                }
                
                var invites = [TeamInviteObject]()
                let teamInvites = currentObj.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                    invites.append(newInvite)
                }
                
                let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                let captain = dict?["teamCaptain"] as? String ?? ""
                let imageUrl = dict?["imageUrl"] as? String ?? ""
                let teamChat = dict?["teamChat"] as? String ?? String()
                let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                let captainId = dict?["teamCaptainId"] as? String ?? String()
                
                let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                
                var teammateArray = [TeammateObject]()
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
                currentTeam.teammates = teammateArray
                currentTeam.requests = teamInviteRequests
                
                teams.append(currentTeam)
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
            user.gamerTags = gamerTags
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
            user.teamInviteRequests = dbRequests
            user.subscriptions = subscriptions
            user.competitions = competitions
            user.currentTempRivals = rivals
            user.acceptedTempRivals = acceptedRivals
            user.rejectedTempRivals = rejectedRivals
            user.tempRivals = tempRivals
            
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
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "homeTransition") {
            let controller = segue.destination as! LandingActivity
            let _ = controller.view
        }
    }
}
