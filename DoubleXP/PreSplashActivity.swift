//
//  PreSplashActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftHTTP
import Firebase
import SwiftDate
import VideoBackground
import AdSupport

class PreSplashActivity: UIViewController, MediaCallbacks  {
    private var data: [NewsObject]!
    private var games: [GamerConnectGame]!
    
    @IBOutlet weak var videoBack: VideoBackground!
    struct Constants {
        static let secret = "uyvhqn68476njzzdvja9ulqsb8esn3"
        static let id = "aio1d4ucufi6bpzae0lxtndanh3nob"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoPath = Bundle.main.path(forResource: "splash", ofType: "mov"),
        let imagePath = Bundle.main.path(forResource: "null", ofType: "png") else{
            games = [GamerConnectGame]()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.getArticles()
                
                //let manager = InterviewManager()
                //manager.getOpions(url: "http://doublexpstorage.tech/app-json/champion.json")
            }
            return
        }
        
        let options = VideoOptions(pathToVideo: videoPath,
                                   pathToImage: imagePath,
                                   isMuted: true,
                                   shouldLoop: false)
        let videoView = VideoBackground(frame: view.bounds, options: options)
        videoView.layer.masksToBounds = true
        videoView.alpha = 0.8
        view.insertSubview(videoView, at: 0)
        
        games = [GamerConnectGame]()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            self.getArticles()
            self.getFeedExtras()
            self.loadLanguages()
            self.getGeneralLookingFor()
            
            //let manager = StatsManager()
            //manager.getPubgStats(gamerTag: "superNayr")
            //let manager = InterviewManager()
            //manager.getOpions(url: "http://doublexpstorage.tech/app-json/champion.json")
        }
    }
    
    func getArticles(){
        let manager = MediaManager()
        manager.getGameSpotNews(callbacks: self)
    }
    
    func getFeedExtras(){
        let ref = Database.database().reference().child("Feed")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(snapshot.hasChild("sub")){
                    appDelegate.feedSub = snapshot.childSnapshot(forPath: "sub").value as? String ?? "let's do this."
                }
                if(snapshot.hasChild("heroLightXXHDPI")){
                    appDelegate.heroLightUrl = snapshot.childSnapshot(forPath: "heroLightXXHDPI").value as? String ?? ""
                }
                if(snapshot.hasChild("heroLightXXHDPI")){
                    appDelegate.heroDarkUrl = snapshot.childSnapshot(forPath: "heroDarkXXHDPI").value as? String ?? ""
                }
            }
        })
    }
    
    func getGeneralLookingFor(){
        let ref = Database.database().reference().child("Looking")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let answers = snapshot.value as? [String] ?? [String]()
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.generalLookingFor = answers
            }
        })
    }
    
    func onReviewsReceived(payload: [NewsObject]) {
    }
    
    func onMediaReceived(category: String) {
        self.getAppConfig()
    }
    
    func onVideoLoaded(url: String) {
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
                   
                    //self.getTwitchAppToken()
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
                            var available = "true"
                            var hasQuiz = false
                            var mobileGame = ""
                            var gameType = ""
                            var releaseDate = ""
                            var gameDescription = ""
                            var ideal = ""
                            var timeCommitment = ""
                            var complexity = ""
                            var alternateImageUrl = ""
                            var ratings = [[String: String]]()
                            var quickReviews = [[String: String]]()
                            var gameModes = [String]()
                            var statsAvailable = false
                            var teamNeeds = [String]()
                            var categoryFilters = [String]()
                            var availableConsoles = [String]()
                            var lookingFor = [String]()
                            var filterQuestions = [[String: Any]]()
                            if let gameDict = game as? NSDictionary {
                                hook = (gameDict.value(forKey: "hook") as? String ?? "")
                                gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                                imageUrl = (gameDict.value(forKey: "headerImageUrlXXHDPI") as? String ?? "")
                                developer = (gameDict.value(forKey: "developer") as? String ?? "")
                                statsAvailable = (gameDict.value(forKey: "statsAvailable") as? Bool ?? false)
                                teamNeeds = (gameDict.value(forKey: "teamNeeds") as? [String]) ?? [String]()
                                secondaryName = (gameDict.value(forKey: "secondaryName") as? String ?? "")
                                gameType = (gameDict.value(forKey: "gameType") as? String ?? "")
                                releaseDate = (gameDict.value(forKey: "releaseDate") as? String ?? "")
                                gameModes = (gameDict).value(forKey: "gameModes") as? [String] ?? [String]()
                                categoryFilters = (gameDict).value(forKey: "categoryFilters") as? [String] ?? [String]()
                                twitterHandle = (gameDict).value(forKey: "twitterHandle") as? String ?? ""
                                twitchHandle = (gameDict).value(forKey: "twitchHandle") as? String ?? ""
                                mobileGame = (gameDict).value(forKey: "mobileGame") as? String ?? "false"
                                available = (gameDict).value(forKey: "available") as? String ?? "true"
                                availableConsoles = (gameDict.value(forKey: "availableConsoles") as? [String]) ?? [String]()
                                lookingFor = (gameDict.value(forKey: "lookingFor") as? [String]) ?? [String]()
                                gameDescription = (gameDict).value(forKey: "gameDescription") as? String ?? ""
                                ideal = (gameDict).value(forKey: "ideal") as? String ?? ""
                                timeCommitment = (gameDict).value(forKey: "timeCommitment") as? String ?? ""
                                alternateImageUrl = (gameDict).value(forKey: "alternateImageUrlXXHDPI") as? String ?? ""
                                complexity = (gameDict).value(forKey: "complexity") as? String ?? ""
                                ratings = (gameDict).value(forKey: "ratings") as? [[String: String]] ?? [[String: String]]()
                                quickReviews = (gameDict).value(forKey: "quickReviews") as? [[String: String]] ?? [[String: String]]()
                                
                                let quiz = (gameDict).value(forKey: "quiz") as? String ?? ""
                                if(quiz == "true"){
                                    hasQuiz = true
                                } else {
                                    hasQuiz = false
                                }
                                
                                let newGame  = GamerConnectGame(imageUrl: imageUrl, gameName: gameName, developer: developer, hook: hook, statsAvailable: statsAvailable, teamNeeds: teamNeeds,
                                                                twitterHandle: twitterHandle, twitchHandle: twitchHandle, available: available)
                                newGame.secondaryName = secondaryName
                                newGame.gameModes = gameModes
                                newGame.hasQuiz = hasQuiz
                                newGame.mobileGame = mobileGame
                                newGame.availablebConsoles = availableConsoles
                                newGame.categoryFilters = categoryFilters
                                newGame.gameType = gameType
                                newGame.releaseDate = releaseDate
                                newGame.ratings = ratings
                                newGame.gameDescription = gameDescription
                                newGame.ideal = ideal
                                newGame.timeCommitment = timeCommitment
                                newGame.complexity = complexity
                                newGame.quickReviews = quickReviews
                                newGame.alternateImageUrl = alternateImageUrl
                                newGame.lookingFor = lookingFor
                                
                                if(gameDict.value(forKey: "filterQuestions") != nil){
                                    //let test = gameDict["filterQuestions"] as? [[String: Any]] ?? [[String: Any]]()
                                    filterQuestions = (gameDict.value(forKey: "filterQuestions") as? [[String: Any]]) ?? [[String: Any]]()
                                    newGame.filterQuestions = filterQuestions
                                }
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
                    LoginHelper().getFeedInfo(uid: uId, activity: self)
                }
            }
        }
    
    func loadLanguages(){
        HTTP.GET("http://doublexpstorage.tech/app-json/languages.json") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    var langaugeList = [String: String]()
                    for game in jsonObj! {
                        var name = ""
                        var nativeName = ""
                        
                        if let langauageDict = game.value as? NSDictionary {
                            name = (langauageDict.value(forKey: "name") as? String ?? "")
                            nativeName = (langauageDict.value(forKey: "nativeName") as? String ?? "")
                            
                            if(!nativeName.isEmpty){
                                langaugeList[name] = nativeName
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.languageList = langaugeList
                    }
                }
            }
        }
    }
    
    func onFeedCompleted(uid: String?){
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
    
    private func downloadDBRef(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
            let value = snapshot.value as? NSDictionary
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let uId = snapshot.key
            let gamerTag = value?["gamerTag"] as? String ?? ""
            let userLat = value?["userLat"] as? Double ?? 0.0
            let userLong = value?["userLong"] as? Double ?? 0.0
            let subscriptions = value?["subscriptions"] as? [String] ?? [String]()
            let competitions = value?["competitions"] as? [String] ?? [String]()
            let bio = value?["bio"] as? String ?? ""
            let blockList = value?["blockList"] as? [String: String] ?? [String: String]()
            let restrictList = value?["restrictList"] as? [String: String] ?? [String: String]()
            let cachedRecommendedUids = value?["cachedRecommendedUids"] as? [String] ?? [String]()
            let dailyCheck = value?["dailyCheck"] as? String ?? ""
            var receivedAnnouncements = value?["receivedAnnouncements"] as? [String] ?? [String]()
            let search = value?["search"] as? String ?? ""
            if(search.isEmpty){
                ref.child("search").setValue("true")
            }
            
            let twitchToken = value?["twitchAppToken"] as? String ?? ""
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
            let reviews = value?["reviews"] as? [String] ?? [String]()
            
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
                if(snapshot.hasChild("pending_friends")){
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
            }
            
            var dbRequests = [RequestObject]()
            if(snapshot.hasChild("pending_friends")){
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
                     
                     dbRequests.append(newRequest)
                }
            }
            
            var friends = [FriendObject]()
            if(snapshot.hasChild("friends")){
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
            }
            
            var lookingForArray = [LookingForSelection]()
            if(snapshot.hasChild("lookingFor")){
                let lookingFor = snapshot.childSnapshot(forPath: "lookingFor")
                for lookingForChild in lookingFor.children {
                    let newSelection = LookingForSelection()
                    newSelection.gameName = (lookingForChild as? DataSnapshot)?.key ?? ""
                    newSelection.choices = (lookingForChild as? DataSnapshot)?.value as? [String] ?? [String]()
                    lookingForArray.append(newSelection)
                }
            }
            
            var currentTeamInvites = [TeamInviteObject]()
            if(snapshot.hasChild("teamInvites")){
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
            }
            
            let games = value?["games"] as? [String] ?? [String]()
            var gamerTags = [GamerProfile]()
            if(snapshot.hasChild("gamerTags")){
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                for gamerTagObj in gamerTagsArray.children {
                    let currentObj = gamerTagObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let currentTag = dict?["gamerTag"] as? String ?? ""
                    let currentGame = dict?["game"] as? String ?? ""
                    let console = dict?["console"] as? String ?? ""
                    let quizTaken = dict?["quizTaken"] as? String ?? ""
                    
                    if(currentTag != "" && currentGame != "" && console != ""){
                        let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                        gamerTags.append(currentGamerTagObj)
                    }
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
            
            let messagingNotifications = value?["messagingNotifications"] as? Bool ?? false
            
            var teams = [EasyTeamObj]()
            if(snapshot.hasChild("teams")){
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
            }
            
            var currentStats = [StatObject]()
            if(snapshot.hasChild("stats")){
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
                    let fortniteDuoStats = dict?["fortniteDuoStats"] as? [String:String] ?? [String: String]()
                    let fortniteSoloStats = dict?["fortniteSoloStats"] as? [String:String] ?? [String: String]()
                    let fortniteSquadStats = dict?["fortniteSquadStats"] as? [String:String] ?? [String: String]()
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
                    currentStat.fortniteDuoStats = fortniteDuoStats
                    currentStat.fortniteSoloStats = fortniteSoloStats
                    currentStat.fortniteSquadStats = fortniteSquadStats
                    
                    currentStats.append(currentStat)
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
            user.viewedAnnouncements = viewedAnnouncements
            user.userLat = userLat
            user.userLong = userLong
            user.blockList = Array(blockList.keys)
            user.restrictList = Array(restrictList.keys)
            user.reviews = reviews
            user.badges = badges
            user.dailyCheck = dailyCheck
            user.cachedRecommendedUids = cachedRecommendedUids
            user.receivedAnnouncements = receivedAnnouncements
            user.userLookingFor = lookingForArray
            
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
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        for tag in gamerTags{
                            if(list.contains(tag.gamerTag)){
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
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
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        for tag in gamerTags{
                            if(list.contains(tag.gamerTag)){
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
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
    
    func identifierForAdvertising() -> String? {
        // Check whether advertising tracking is enabled
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return nil
        }

        // Get and return IDFA
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
