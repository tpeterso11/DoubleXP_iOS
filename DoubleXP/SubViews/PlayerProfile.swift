//
//  PlayerProfile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/6/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import MSPeekCollectionViewDelegateImplementation
import FoldingCell
import FBSDKCoreKit
import OrderedDictionary
import UnderLineTextField
import NotificationCenter

class PlayerProfile: ParentVC, UITableViewDelegate, UITableViewDataSource, ProfileCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, RequestsUpdate, UICollectionViewDelegateFlowLayout, SocialMediaManagerCallback, UITextFieldDelegate {
    
    var uid: String = ""
    var userForProfile: User? = nil
    
    var keys = [String]()
    var objects = [GamerConnectGame]()
    var cellHeights: [CGFloat] = []
    var statsPayload = [String]()
    var currentStream = ""
    
    @IBOutlet weak var updateLabel: UILabel!
    @IBOutlet weak var twitchConnectLayoutWorkSpinner: UIActivityIndicatorView!
    @IBOutlet weak var twitchConnectLayoutWork: UIView!
    @IBOutlet weak var twitchWorkLabel: UILabel!
    @IBOutlet weak var twitchWorkSpinner: UIActivityIndicatorView!
    @IBOutlet weak var twitchConnectWork: UIView!
    @IBOutlet weak var twitchConnectNevermind: UIButton!
    @IBOutlet weak var twitchConnectButton: UIButton!
    @IBOutlet weak var twitchUserNameEntry: UnderLineTextField!
    @IBOutlet weak var twitchConnectDrawer: UIView!
    @IBOutlet weak var twitchConnectOverlay: UIVisualEffectView!
    @IBOutlet weak var profileTwitchPlayer: TestPlayer!
    @IBOutlet weak var twitchConnectNot: UIView!
    @IBOutlet weak var twitchConnectOffline: UIView!
    @IBOutlet weak var twitchConnect: UIView!
    @IBOutlet weak var twitchConnectOnline: UIView!
    @IBOutlet weak var twitchConnectLayout: UIView!
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var profileLine2: UILabel!
    @IBOutlet weak var profileLine3: UILabel!
    @IBOutlet weak var bio: VerticalAlignLabel!
    @IBOutlet weak var statsCollection: UICollectionView!
    @IBOutlet weak var consoleOne: UILabel!
    @IBOutlet weak var consoleTwo: UILabel!
    @IBOutlet weak var headerView: UIView!
    //@IBOutlet weak var connectButton: UIImageView!
    @IBOutlet weak var statEmpty: UIView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var userStatusText: UILabel!
    @IBOutlet weak var mainLayout: UIView!
    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var actionButtonText: UILabel!
    @IBOutlet weak var actionOverlay: UIVisualEffectView!
    @IBOutlet weak var actionDrawer: UIView!
    @IBOutlet weak var bottomBlur: UIVisualEffectView!
    @IBOutlet weak var userStatsLabel: UILabel!
    @IBOutlet weak var tapInstructions: UILabel!
    @IBOutlet weak var sentOverlay: UIView!
    @IBOutlet weak var sentText: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var rivalButton: UIButton!
    
    @IBOutlet weak var quizButtonSwitcher: UIButton!
    @IBOutlet weak var statsButtonSwitcher: UIButton!
    @IBOutlet weak var statsSwitcher: UIView!
    @IBOutlet weak var rivalSendResultSub: UILabel!
    @IBOutlet weak var rivalSendResultText: UILabel!
    @IBOutlet weak var rivalOverlaySpinner: UIActivityIndicatorView!
    @IBOutlet weak var rivalCoOpSelection: UIView!
    @IBOutlet weak var rivalRivalSelection: UIView!
    @IBOutlet weak var rivalLoadingOverlay: UIView!
    @IBOutlet weak var rivalSendResultOverlay: UIView!
    @IBOutlet weak var rivalOverlay: UIView!
    @IBOutlet weak var rivalBlur: UIVisualEffectView!
    @IBOutlet weak var rivalClose: UIImageView!
    @IBOutlet weak var rivalTypeView: UIView!
    @IBOutlet weak var rivalOverlayHeader: UILabel!
    @IBOutlet weak var rivalGameView: UIView!
    @IBOutlet weak var rivalGameCollection: UICollectionView!
    @IBOutlet weak var statOverlayCard: UIView!
    @IBOutlet weak var statsOverlay: UIVisualEffectView!
    @IBOutlet weak var statCardBack: UIImageView!
    @IBOutlet weak var statCardTitle: UILabel!
    @IBOutlet weak var statCardClose: UIImageView!
    @IBOutlet weak var statOverlayTable: UITableView!
    @IBOutlet weak var statsOverlayCollection: UICollectionView!
    @IBOutlet weak var profileTable: UITableView!
    @IBOutlet weak var gtRegisterBlur: UIVisualEffectView!
    @IBOutlet weak var gtRegisterBox: UIView!
    @IBOutlet weak var gtEntryField: UnderLineTextField!
    @IBOutlet weak var sendGt: UIButton!
    @IBOutlet weak var dismissGtRegisterButton: UIButton!
    
    var localImageCache = NSCache<NSString, UIImage>()
    
    var rivalOverlayPayload = [GamerConnectGame]()
    var sections = [Section]()
    var nav: NavigationPageController?
    var profilePayload = [FreeAgentObject]()
    
    var rivalSelectedGame = ""
    var rivalSelectedType = ""
    var newGT = ""
    var currentStatsGame: GamerConnectGame?
    var statsSet = false
    var quizSet = false
    var currentKey = ""
    var drawerOpen = false
    
    private var quizPayload = [FAQuestion]()
    private var currentProfile: FreeAgentObject? = nil
    
    var showStats = false
    var showQuiz = false
    
    var gamesWithStats = [String]()
    var gamesWithQuiz = [String]()
    
     enum Const {
           static let closeCellHeight: CGFloat = 100
           static let openCellHeight: CGFloat = 280
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard !uid.isEmpty else {
            return
        }
    
        loadUserInfo(uid: uid)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentProfileFrag = self
        if(appDelegate.currentUser!.uId == self.uid){
            bottomBlur.isHidden = true
            actionButton.isHidden = true
        }
        
        headerView.clipsToBounds = true
        
        self.twitchConnectLayoutWork.alpha = 1
        self.twitchConnectLayoutWorkSpinner.startAnimating()
        
        self.actionOverlay.effect = nil
        actionOverlay.isHidden = false
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            self.hideTwitchConnectWork()
        }
    }
    
    @objc func messagingButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding!.navigateToMessaging(groupChannelUrl: nil, otherUserId: self.uid)
    }
    
    @objc func receivedButtonClicked(_ sender: AnyObject?) {
        showDrawerAndOverlay()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func acceptClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Accepted"))
        let manager = FriendsManager()
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            for invite in currentUser!.pendingRequests{
                if(self.userForProfile!.uId == invite.uid){
                    manager.acceptFriendFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    break
                }
            }
        }
    }
    
    @objc func declineClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Declined"))
        let manager = FriendsManager()
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            for invite in currentUser!.pendingRequests{
                if(self.userForProfile!.uId == invite.uid){
                    manager.declineRequestFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    break
                }
            }
        }
    }
    
    func onFriendAdded() {
        updateToChatButton()
        dismissDrawerAndOverlay()
    }
    
    func onFriendDeclined() {
        updateToRequestButton()
        dismissDrawerAndOverlay()
    }
    
    func loadUserInfo(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let uId = snapshot.key
            let bio = value?["bio"] as? String ?? ""
            let gamerTag = value?["gamerTag"] as? String ?? ""
            let games = value?["games"] as? [String] ?? [String]()
            let twitchConnect = value?["twitchConnect"] as? String ?? ""
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
                let codKills = dict["codKills"] as? String ?? ""
                let codKd = dict["codKd"] as? String ?? ""
                let codLevel = dict["codLevel"] as? String ?? ""
                let codBestKills = dict["codBestKills"] as? String ?? ""
                let codWins = dict["codWins"] as? String ?? ""
                let codWlRatio = dict["codWlRatio"] as? String ?? ""
                let fortniteDuoStats = dict["fortniteDuoStats"] as? [String:String] ?? [String: String]()
                let fortniteSoloStats = dict["fortniteSoloStats"] as? [String:String] ?? [String: String]()
                let fortniteSquadStats = dict["fortniteSquadStats"] as? [String:String] ?? [String: String]()
                let overwatchCasualStats = dict["overwatchCasualStats"] as? [String:String] ?? [String: String]()
                let overwatchCompetitiveStats = dict["overwatchCompetitiveStats"] as? [String:String] ?? [String: String]()
                let killsPerMatch = dict["killsPerMatch"] as? String ?? ""
                let matchesPlayed = dict["matchesPlayed"] as? String ?? ""
                let seasonWins = dict["seasonWins"] as? String ?? ""
                let seasonKills = dict["seasonKills"] as? String ?? ""
                let supImage = dict["supImage"] as? String ?? ""
                
                let currentStat = StatObject(gameName: gameName)
                currentStat.fortniteDuoStats = fortniteDuoStats
                currentStat.fortniteSoloStats = fortniteSoloStats
                currentStat.fortniteSquadStats = fortniteSquadStats
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
            user.games = games
            user.gamerTag = gamerTag
            user.pc = pc
            user.ps = ps
            user.xbox = xbox
            user.nintendo = nintendo
            user.bio = bio
            user.twitchConnect = twitchConnect
            
            self.loadProfiles(user: user)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func loadProfiles(user: User){
        let ref = Database.database().reference().child("Free Agents V2").child(user.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.profilePayload = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for profile in snapshot.children{
                    let currentProfile = profile as! DataSnapshot
                    let dict = currentProfile.value as! [String: Any]
                    let game = dict["game"] as? String ?? ""
                    let consoles = dict["consoles"] as? [String] ?? [String]()
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let competitionId = dict["competitionId"] as? String ?? ""
                    let userId = dict["userId"] as? String ?? ""
                    
                    var questions = [FAQuestion]()
                    let questionList = dict["questions"] as? [[String: Any]] ?? [[String: Any]]()
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
                    
                    let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                    self.profilePayload.append(result)
                }
                self.setUI(user: user)
            } else {
                self.setUI(user: user)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func setUI(user: User){
        self.userForProfile = user
        let manager = GamerProfileManager()
        
        let friendsManager = FriendsManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        if(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)){
            checkRivals()
        }
        else{
            self.rivalButton.alpha = 0
            self.rivalButton.isUserInteractionEnabled = false
        }
        
        self.gamerTag.text = manager.getGamerTag(user: user)
        
        let consoles = user.getConsoleArray()
        if(!consoles.isEmpty){
            consoleOne.text = consoles[0]
            consoleOne.layer.masksToBounds = true
            consoleOne.layer.cornerRadius = 15
            
            if(consoles.indices.contains(1)){
                consoleTwo.text = consoles[1]
                consoleTwo.layer.masksToBounds = true
                consoleTwo.layer.cornerRadius = 15
                consoleTwo.isHidden = false
            }
        }
        
        if(userForProfile!.uId == currentUser!.uId){
            if(!userForProfile!.twitchConnect.isEmpty){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let manager = appDelegate.socialMediaManager
                manager.checkTwitchStream(twitchId: userForProfile!.twitchConnect, callbacks: self)
            } else {
                UIView.transition(with: self.twitchConnectLayout, duration: 0.3, options: .curveEaseInOut, animations: {
                    self.twitchConnectLayoutWork.alpha = 0
                    self.twitchConnectLayoutWorkSpinner.stopAnimating()
                    self.twitchConnectLayout.backgroundColor = UIColor(named: "twitch_purple")
                }, completion: nil)
                
                let connectTwitch = UITapGestureRecognizer(target: self, action: #selector(showTwitchConnectOverlay))
                self.twitchConnectLayout.isUserInteractionEnabled = true
                self.twitchConnectLayout.addGestureRecognizer(connectTwitch)
                
                twitchConnectOffline.alpha = 0
                twitchConnectNot.alpha = 0
                twitchConnectOnline.alpha = 0
                twitchConnect.alpha = 1
            }
        } else {
            if(!userForProfile!.twitchConnect.isEmpty){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let manager = appDelegate.socialMediaManager
                manager.checkTwitchStream(twitchId: userForProfile!.twitchConnect, callbacks: self)
            } else {
                UIView.transition(with: self.twitchConnectLayout, duration: 0.3, options: .curveEaseInOut, animations: {
                    self.twitchConnectLayout.backgroundColor = UIColor(named: "whiteBackToDarkGrey")
                    self.twitchConnectLayoutWork.alpha = 0
                    self.twitchConnectLayoutWorkSpinner.stopAnimating()
                }, completion: nil)
                
                twitchConnectOffline.alpha = 0
                twitchConnectNot.alpha = 1
                twitchConnectOnline.alpha = 0
                twitchConnect.alpha = 0
            }
        }
        
        var profileGames = [String]()
        for profile in self.profilePayload{
            profileGames.append(profile.game)
        }
        
        for game in delegate.gcGames{
            if(profileGames.contains(game.gameName) && !user.games.contains(game.gameName)){
                user.games.append(game.gameName)
            }
        }
        
        self.setup(gamesEmpty: user.games.isEmpty)
        
        if(friendsManager.checkListsForUser(user: userForProfile!, currentUser: currentUser!)){
            
            if(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)){
                updateToChatButton()
                
            }
            
            for request in currentUser!.sentRequests{
                if(request.uid == user.uId){
                    updateToPending()
                    break
                }
            }
            
            for request in currentUser!.pendingRequests{
                if(request.uid == user.uId){
                    actionButton.applyGradient(colours:  [#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)], orientation: .horizontal)
                    actionButtonText.text = "Received Request!"
                    
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(receivedButtonClicked))
                    actionButton.isUserInteractionEnabled = true
                    actionButton.addGestureRecognizer(singleTap)
                    
                    acceptButton.addTarget(self, action: #selector(acceptClicked), for: .touchUpInside)
                    declineButton.addTarget(self, action: #selector(declineClicked), for: .touchUpInside)
                    break
                }
            }
        }
        else{
            updateToRequestButton()
        }
        
        guard !user.bio.isEmpty else{
            self.bio.text = "This user has not yet created a bio."
            //self.bio.text = "\"" + "I roll with the muh-fuckin rough ridin, ride or dyin, killing ERRRRRYBODY CLAN Xoxx:snfdgXXX" + "\""
            return
        }
        self.bio.text = "\"" + user.bio + "\""
    }
    
    @objc private func showTwitchConnectOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Show Twitch Connect Overlay"))
        UIView.animate(withDuration: 0.5, animations: {
            self.twitchConnectOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            let top = CGAffineTransform(translationX: 0, y: -365)
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.checkTwitchButton()
                self.twitchUserNameEntry.text = ""
                self.twitchUserNameEntry.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                self.twitchConnectDrawer.transform = top
                self.twitchUserNameEntry.returnKeyType = .done
                self.twitchUserNameEntry.delegate = self
                self.twitchConnectNevermind.addTarget(self, action: #selector(self.dismissTwitchConnectOverlay(register:)), for: .touchUpInside)
            }, completion: nil)
        })
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == self.twitchUserNameEntry){
            if(textField.text != nil){
                self.checkTwitchButton()
            }
        } else {
            if(self.gtEntryField.text!.count > 4){
                self.sendGt.alpha = 1
                self.sendGt.isUserInteractionEnabled = true
                self.newGT = self.gtEntryField.text!
                self.sendGt.addTarget(self, action: #selector(dismissEntry), for: .touchUpInside)
            } else {
                self.sendGt.alpha = 0.3
                self.sendGt.isUserInteractionEnabled = false
            }
        }
    }
    
    private func checkTwitchButton(){
        if(twitchUserNameEntry.text!.isEmpty){
            twitchConnectButton.alpha = 0.3
        } else if(twitchUserNameEntry.text!.count >= 3){
            twitchConnectButton.alpha = 1.0
            twitchConnectButton.addTarget(self, action: #selector(registerTwitchConnect), for: .touchUpInside)
        }
    }
    
    @objc private func registerTwitchConnect(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Registered with Twitch Connect"))
        
        UIView.animate(withDuration: 0.5, animations: {
            self.twitchConnectWork.alpha = 1
            self.twitchWorkSpinner.startAnimating()
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.child("twitchConnect").setValue(self.twitchUserNameEntry.text!)
            
            self.dismissTwitchConnectOverlay(register: true)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let manager = appDelegate.socialMediaManager
            manager.checkTwitchStream(twitchId: self.twitchUserNameEntry.text!, callbacks: self)
        })
    }
    
    private func hideTwitchConnectWork(){
        UIView.animate(withDuration: 0.5, animations: {
            self.twitchConnectLayoutWork.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.twitchConnectOnline.alpha = 1
                self.twitchConnectLayoutWorkSpinner.stopAnimating()
            }, completion: nil)
        })
    }
    
    @objc private func dismissTwitchConnectOverlay(register: Bool){
        if(register){
            AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Hide Twitch Connect - Registered"))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIView.animate(withDuration: 0.5, animations: {
                    self.twitchWorkLabel.text = "done."
                    self.twitchWorkSpinner.alpha = 0
                }, completion: { (finished: Bool) in
                    let top = CGAffineTransform(translationX: 0, y: 0)
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.twitchConnectDrawer.transform = top
                    }, completion: { (finished: Bool) in
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                self.checkTwitchButton()
                                self.twitchConnectOverlay.alpha = 0
                        }, completion: nil)
                    })
                })
            }
        } else {
            AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Hide Twitch Connect - Not Registered"))
            let top = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.twitchConnectDrawer.transform = top
            }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.checkTwitchButton()
                        self.twitchConnectOverlay.alpha = 0
                }, completion: nil)
            })
        }
    }
    
    private func setup(gamesEmpty: Bool) {
        if(gamesEmpty){
            self.bottomBlur.isHidden = true
            
            let top = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.statEmpty.alpha = 1
                self.statEmpty.transform = top
            }, completion: nil)
        }
        else{
            let delegate = UIApplication.shared.delegate as! AppDelegate
            for game in self.userForProfile!.games{
                for gcGame in delegate.gcGames{
                    if(game == gcGame.gameName){
                        self.objects.append(gcGame)
                    }
                }
            }
            
            cellHeights = Array(repeating: Const.closeCellHeight, count: self.objects.count)
            table.estimatedRowHeight = Const.closeCellHeight
            table.rowHeight = UITableView.automaticDimension
            
            if #available(iOS 10.0, *) {
                table.refreshControl = UIRefreshControl()
                table.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
            }
            
            if(!self.profilePayload.isEmpty){
                for profile in self.profilePayload {
                    for game in self.objects {
                        if(game.gameName == profile.game){
                            self.gamesWithQuiz.append(game.gameName)
                        }
                    }
                }
            }
            
            self.table.dataSource = self
            self.table.delegate = self
            self.table.contentInset = UIEdgeInsets(top: 0,left: 0,bottom: 50,right: 0)
            
            let top = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.table.alpha = 1
                self.table.transform = top
                self.userStatsLabel.alpha = 1
                self.userStatsLabel.transform = top
                
                self.tapInstructions.alpha = 1
                self.tapInstructions.transform = top
            }, completion: nil)
        }
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
        if(streams.isEmpty){
            UIView.transition(with: self.twitchConnectLayout, duration: 0.3, options: .curveEaseInOut, animations: {
                self.twitchConnectLayout.backgroundColor = UIColor(named: "whiteBackToDarkGrey")
                self.twitchConnectLayoutWork.alpha = 0
                self.twitchConnectLayoutWorkSpinner.stopAnimating()
            }, completion: nil)
            
            twitchConnectOffline.alpha = 1
            twitchConnectNot.alpha = 0
            twitchConnectOnline.alpha = 0
            twitchConnect.alpha = 0
            
            let changeTwitch = UITapGestureRecognizer(target: self, action: #selector(self.showTwitchConnectOverlay))
            self.twitchConnectLayout.isUserInteractionEnabled = true
            self.twitchConnectLayout.addGestureRecognizer(changeTwitch)
            
            updateLabel.isHidden = false
        } else {
            DispatchQueue.main.async() {
                UIView.transition(with: self.twitchConnectLayout, duration: 0.3, options: .curveEaseInOut, animations: {
                    self.twitchConnectLayout.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                    self.twitchConnectLayoutWork.alpha = 0
                    self.twitchConnectLayoutWorkSpinner.stopAnimating()
                }, completion: nil)
                
                self.twitchConnectOffline.alpha = 0
                self.twitchConnectNot.alpha = 0
                self.twitchConnectOnline.alpha = 1
                self.twitchConnect.alpha = 0
                
                let currentStream = streams[0]
                self.currentStream = currentStream.handle
                
                let playTwitch = UITapGestureRecognizer(target: self, action: #selector(self.startTwitch))
                self.twitchConnectLayout.isUserInteractionEnabled = true
                self.twitchConnectLayout.addGestureRecognizer(playTwitch)
            }
        }
    }
    
    func onChannelsLoaded(channels: [TwitchChannelObj]) {
    }
    
    @objc func startTwitch(){
        UIView.animate(withDuration: 0.5, animations: {
            self.twitchConnectOnline.alpha = 0
            self.twitchConnectLayoutWorkSpinner.startAnimating()
            
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.twitchConnectLayoutWork.alpha = 1
                
                self.profileTwitchPlayer.setChannel(to: self.currentStream)
                self.profileTwitchPlayer.play()
            }, completion: nil)
        })
    }
    
    @objc func connectTwitch(){
        
        self.profileTwitchPlayer.play()
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.table.refreshControl?.endRefreshing()
            }
            self?.table.reloadData()
        })
    }
    
    private func updateToChatButton(){
        actionButton.applyGradient(colours:  [#colorLiteral(red: 0, green: 0.4987006783, blue: 0, alpha: 1), #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)], orientation: .horizontal)
        actionButtonText.text = "Chat with this user"
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(messagingButtonClicked))
        actionButton.isUserInteractionEnabled = true
        actionButton.addGestureRecognizer(singleTap)
    }
    
    private func updateToRequestButton(){
        let manager = GamerProfileManager()
        if(!manager.gamertagBelongsToUser(gamerTag: manager.getGamerTag(user: self.userForProfile!))){
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(connectButtonClicked))
           actionButton.applyGradient(colours:  [#colorLiteral(red: 0, green: 0.4987006783, blue: 0, alpha: 1), #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)], orientation: .horizontal)
           actionButtonText.text = "send friend request"

           actionButton.isUserInteractionEnabled = true
           actionButton.isHidden = false
            actionButton.addGestureRecognizer(singleTap)
        } else {
            self.bottomBlur.isHidden = true
            self.actionButton.isHidden = true
        }
    }
    
    private func setupGTView(){
        self.gtRegisterBox.layer.borderColor = UIColor.clear.cgColor
        self.gtRegisterBox.layer.masksToBounds = true
        
        self.gtRegisterBox.layer.shadowColor = UIColor.black.cgColor
        self.gtRegisterBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.gtRegisterBox.layer.shadowRadius = 2.0
        self.gtRegisterBox.layer.shadowOpacity = 0.5
        self.gtRegisterBox.layer.shadowPath = UIBezierPath(roundedRect: self.gtRegisterBox.bounds, cornerRadius: self.gtRegisterBox.layer.cornerRadius).cgPath
    }
    
    private func showGamerTagRequest(){
        self.gtEntryField.delegate = self
        self.gtEntryField.text = ""
        self.gtEntryField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        self.sendGt.alpha = 0.3
        self.dismissGtRegisterButton.addTarget(self, action: #selector(dismissEntry), for: .touchUpInside)
        self.sendGt.addTarget(self, action: #selector(dismissEntry), for: .touchUpInside)
        let top = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.6, animations: {
            self.gtRegisterBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.gtRegisterBox.transform = top
                self.gtRegisterBox.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc func dismissEntry(_ sender: AnyObject?) {
        if(!self.newGT.isEmpty){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentUser!.gamerTag = self.newGT
            
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.child("gamerTag").setValue(self.newGT)
            
            let friendsManager = FriendsManager()
            friendsManager.sendRequestFromProfile(currentUser: delegate.currentUser!, otherUser: userForProfile!, callbacks: self)
        }
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.4, animations: {
            self.gtRegisterBox.transform = top
            self.gtRegisterBox.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.gtRegisterBlur.alpha = 0
            }, completion: nil)
        })
    }
    
    private func updateToPending(){
        actionButton.applyGradient(colours:  [#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)], orientation: .horizontal)
        actionButtonText.text = "pending request"
    }
    
    @objc func connectButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userCanSendInvites()){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Sent"))
            let friendsManager = FriendsManager()
            
            if(self.userForProfile != nil){
                let currentUser = delegate.currentUser
                friendsManager.sendRequestFromProfile(currentUser: currentUser!, otherUser: userForProfile!, callbacks: self)
            }
        } else {
            showGamerTagRequest()
        }
    }
    
    private func showDrawerAndOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Action Drawer Opened"))
        UIView.animate(withDuration: 0.3, animations: {
            self.actionOverlay.alpha = 1
        } )
        
        let top = CGAffineTransform(translationX: 0, y: -180)
        UIView.animate(withDuration: 0.5, animations: {
            self.actionDrawer.alpha = 1
              self.actionDrawer.transform = top
        }, completion: nil)
        
        //let singleTap = UITapGestureRecognizer(target: self, action: #selector(dismissDrawerAndOverlay))
        //clickArea.isUserInteractionEnabled = true
        //clickArea.addGestureRecognizer(singleTap)
    }
    
    @objc private func dismissDrawerAndOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Action Drawer Closed"))
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
              self.actionDrawer.transform = top
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, delay: 0.5,animations: {
            self.actionOverlay.effect = nil
        } )
        
        actionOverlay.isUserInteractionEnabled = false
    }
    
    func tableView(_ tableview: UITableView, numberOfRowsInSection _: Int) -> Int {
        if(tableview == self.table){
            return self.objects.count
        } else {
            return self.quizPayload.count
        }
    }

    func tableView(_ tableview: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(tableview == self.table){
            guard case let cell as FoldingCellCell = cell else {
                return
            }

            cell.backgroundColor = .clear

            if cellHeights[indexPath.row] == Const.closeCellHeight {
                cell.unfold(false, animated: false, completion: nil)
            } else {
                cell.unfold(true, animated: false, completion: nil)
            }
        }
    }

    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableview == self.table){
            let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FoldingCellCell
            let current = self.objects[indexPath.item]
            
            cell.gameName.text = ""
            cell.developer.text = ""
            
            if(self.gamesWithQuiz.contains(current.gameName)){
                cell.quizAvailableContainer.isHidden = false
            } else {
                cell.quizAvailableContainer.isHidden = true
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: current.imageUrl as NSString) != nil){
                cell.gameBack.image = cache.object(forKey: current.imageUrl as NSString)
            } else {
                cell.gameBack.image = Utility.Image.placeholder
                cell.gameBack.moa.onSuccess = { image in
                    cell.gameBack.image = image
                    appDelegate.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                    return image
                }
                cell.gameBack.moa.url = current.imageUrl
            }
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameBack.clipsToBounds = true
            
            cell.coverGameName.text = current.gameName.lowercased()
            cell.gameName.text = current.gameName
            cell.developer.text = current.developer
            
            cell.statsAvailable.isHidden = true
            cell.statsAvailableContainer.isHidden = true
            
            var contained = ""
            for stat in self.userForProfile!.stats{
                if(stat.gameName == current.gameName){
                    contained = stat.gameName
                    break
                }
            }
            
            if(!contained.isEmpty){
                cell.statsAvailable.isHidden = false
                cell.statsAvailableContainer.isHidden = false
                
                self.gamesWithStats.append(contained)
            } else {
                cell.statsAvailable.isHidden = true
                cell.statsAvailableContainer.isHidden = true
            }
            
            cell.layoutMargins = UIEdgeInsets.zero
            cell.separatorInset = UIEdgeInsets.zero
            
            return cell
        }
        else {
            let current = quizPayload[indexPath.item]
            
            if(!current.answer.isEmpty){
                if(current.answer.contains("/DXP/")){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath) as! OptionAnswerCell
                    let adjustedPayload = [current.answer]
                    cell.question.text = current.question
                    
                    cell.setOptions(options: adjustedPayload, cache: self.localImageCache)
                    
                    return cell
                } else {
                    let cell = tableview.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
                    
                    cell.question.text = current.question
                    cell.answer.text = current.answer
                    
                    return cell
                }
            } else {
                let currentArray = current.answerArray
                
                if(currentArray[0].contains("/DXP/")){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath) as! OptionAnswerCell
                    
                    cell.question.text = current.question
                    cell.setOptions(options: current.answerArray, cache: self.localImageCache)
                    
                    return cell
                } else if(currentArray.count > 1){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "multiOptionCell", for: indexPath) as! MultiOptionCell
                    
                    cell.question.text = current.question
                    
                    cell.setPayload(payload: currentArray)
                    
                    return cell
                } else {
                    let cell = tableview.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
                    
                    cell.question.text = current.question
                    cell.answer.text = currentArray[0]
                    
                    return cell
                }
            }
            
        }
    }

    func tableView(_ tableview: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableview == self.table){
            return cellHeights[indexPath.row]
        } else {
            let cell = tableview.cellForRow(at: indexPath)
            if(cell is AnswerTableCell){
                return CGFloat(50)
            } else if (cell is MultiOptionCell){
                 return CGFloat(140)
            } else {
                return CGFloat(180)
            }
        }
    }

    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableview == self.table){
            let current = self.objects[indexPath.item]
            if(self.gamesWithStats.contains(current.gameName) || self.gamesWithQuiz.contains(current.gameName)){
                self.showStatsOverlay(gameName: current.gameName, game: current)
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == rivalGameCollection){
            return self.rivalOverlayPayload.count
        } else {
            if(showStats){
                return self.statsPayload.count
            } else {
                return self.quizPayload.count
            }
        }
    }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == rivalGameCollection){
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
        
        let game = self.rivalOverlayPayload[indexPath.item]
           cell.backgroundImage.moa.url = game.imageUrl
           cell.backgroundImage.contentMode = .scaleAspectFill
           cell.backgroundImage.clipsToBounds = true
           
           cell.hook.text = game.gameName
           AppEvents.logEvent(AppEvents.Name(rawValue: "Player Profile Rival " + game.gameName + " Click"))
           
           cell.contentView.layer.cornerRadius = 2.0
           cell.contentView.layer.borderWidth = 1.0
           cell.contentView.layer.borderColor = UIColor.clear.cgColor
           cell.contentView.layer.masksToBounds = true
           
           cell.layer.shadowColor = UIColor.black.cgColor
           cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
           cell.layer.shadowRadius = 2.0
           cell.layer.shadowOpacity = 0.5
           cell.layer.masksToBounds = false
           cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
           return cell
        } else {
           let current = self.statsPayload[indexPath.item]
           let currentArr = current.characters.split{$0 == "/"}.map(String.init)
            let key = currentArr[0]
            let value = currentArr[1]
           
            if(key.contains("HEADER")){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "statsHeaderCell", for: indexPath) as! ProfileStatHeader
                cell.headerText.text = value
                
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "statsCell", for: indexPath) as! StatsCollectionCell
                cell.statLabel.text = key
                cell.stat.text = value
                
                cell.isUserInteractionEnabled = false
                return cell
          }
       }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == rivalGameCollection){
            let current = self.rivalOverlayPayload[indexPath.item]
            
            self.rivalSelectedGame = current.gameName
            
            self.progressRival()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == rivalGameCollection){
            return CGSize(width: self.rivalGameCollection.bounds.width, height: CGFloat(80))
        } else {
            let current = self.statsPayload[indexPath.item]
            if(current.contains("HEADER")){
                return CGSize(width: self.statsOverlayCollection.bounds.width - 10, height: CGFloat(50))
            } else {
                return CGSize(width: 150, height: CGFloat(130))
            }
        }
    }
    
    func onFriendRequested(){
        let top = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.5, animations: {
            self.sentOverlay.alpha = 1
            self.updateToPending()
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.sentText.transform = top
                self.sentText.alpha = 1
            }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                        self.sentOverlay.alpha = 0
                    }, completion: nil)
                }
            })
        })
    }
    
    private func showStatsOverlay(gameName: String, game: GamerConnectGame){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        if(self.gamesWithStats.contains(game.gameName)){
            self.showStats = true
            self.statsOverlayCollection.alpha = 1
            var currentStat: StatObject? = nil
            
            for stat in userForProfile!.stats{
                if(stat.gameName == gameName){
                    currentStat = stat
                }
            }
            
            for game in delegate.gcGames{
                if(gameName == game.gameName){
                    self.currentStatsGame = game
                }
            }
            
            if(self.currentStatsGame != nil){
                if(currentStat != nil && !currentStat!.suppImage.isEmpty){
                    self.statCardBack.moa.url = currentStat!.suppImage
                } else {
                    self.statCardBack.moa.url = self.currentStatsGame!.imageUrl
                }
                
                if(gameName == "Fortnite"){
                    var build = [String]()
                    build.append("HEADER_0/solo stats")
                    
                    for (key, value) in currentStat!.fortniteSoloStats{
                        if((value as! String).contains(".00")){
                            let newVal = (value as! String).prefix(upTo: (value as! String).index(of: ".")!)
                            build.append(key+"/"+newVal)
                        } else {
                            build.append(key+"/"+(value as? String ?? ""))
                        }
                    }
                    
                    build.append("HEADER_1/duo stats")
                    for (key, value) in currentStat!.fortniteDuoStats{
                      if((value as! String).contains(".00")){
                          let newVal = (value as! String).prefix(upTo: (value as! String).index(of: ".")!)
                          build.append(key+"/"+newVal)
                      } else {
                          build.append(key+"/"+(value as? String ?? ""))
                      }
                    }
                    
                    build.append("HEADER_1/squad Stats")
                    for (key, value) in currentStat!.fortniteSquadStats{
                      if((value as! String).contains(".00")){
                          let newVal = (value as! String).prefix(upTo: (value as! String).index(of: ".")!)
                          build.append(key+"/"+newVal)
                      } else {
                          build.append(key+"/"+(value as? String ?? ""))
                      }
                    }
                    
                    self.statsPayload = build
                } else if(gameName == "Overwatch"){
                    var build = [String]()
                    build.append("HEADER_0/casual stats")
                    
                    for (key, value) in currentStat!.overwatchCasualStats{
                        build.append(key+"/"+(value as? String ?? ""))
                    }
                    
                    build.append("HEADER_1/competitive stats")
                    for (key, value) in currentStat!.overwatchCompetitiveStats{
                      build.append(key+"/"+(value as? String ?? ""))
                    }
                    
                    self.statsPayload = build
                } else {
                    self.statsPayload = currentStat!.createBasicPayload()
                }
                
                if(!self.statsSet){
                    self.statsOverlayCollection.dataSource = self
                    self.statsOverlayCollection.delegate = self
                    self.statsSet = true
                } else {
                    self.statsOverlayCollection.reloadData()
                }
            }
        } else {
            self.showStats = false
            self.statsOverlayCollection.alpha = 0
            
            for game in delegate.gcGames{
                if(gameName == game.gameName){
                    self.statCardBack.moa.url = game.imageUrl
                }
            }
            
            let top = CGAffineTransform(translationX: -338, y: 0)
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.profileTable.transform = top
            }, completion: nil)
            
        }
           
        //releasing with bug that, under unknown circumstances, the quiz table will not appear when drawer is opened.
        self.quizPayload = [FAQuestion]()
        if(self.gamesWithQuiz.contains(gameName)){
            for profile in self.profilePayload{
                if(profile.game == game.gameName){
                    self.currentProfile = profile
                    
                    self.quizPayload.append(contentsOf: currentProfile!.questions)
                    break
                }
            }
            
            if(!self.quizSet){
                self.profileTable.dataSource = self
                self.profileTable.delegate = self
                self.reload(tableView: profileTable)
                self.quizSet = true
            } else {
                self.profileTable.reloadData()
            }
        }

        self.statCardBack.contentMode = .scaleAspectFill
        self.statCardBack.clipsToBounds = true
        self.statCardTitle.text = gameName.lowercased()
        
        let overlayCloseTap = UITapGestureRecognizer(target: self, action: #selector(hideStatsOverlay))
        self.statCardClose.isUserInteractionEnabled = true
        self.statCardClose.addGestureRecognizer(overlayCloseTap)
        
        self.quizButtonSwitcher.addTarget(self, action: #selector(switchToProfiles), for: .touchUpInside)
        self.quizButtonSwitcher.isUserInteractionEnabled = true
        self.statsButtonSwitcher.addTarget(self, action: #selector(switchToStats), for: .touchUpInside)
        self.statsButtonSwitcher.isUserInteractionEnabled = true
        
        if(self.gamesWithQuiz.contains(gameName) && self.gamesWithStats.contains(game.gameName)){
            self.statsSwitcher.alpha = 1
        } else {
            self.statsSwitcher.alpha = 0
        }
        
        let top = CGAffineTransform(translationX: -338, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.statsOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.statOverlayCard.transform = top
                self.statOverlayCard.alpha = 1
                self.drawerOpen = true
            }, completion: nil)
        })
    }
    
    func reload(tableView: UITableView) {
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.setContentOffset(contentOffset, animated: false)
    }
    
    @objc private func switchToProfiles(){
        self.quizButtonSwitcher.isUserInteractionEnabled = false
        self.statsButtonSwitcher.isUserInteractionEnabled = false
        
        let top = CGAffineTransform(translationX: -338, y: 0)
        UIView.animate(withDuration: 0.3, animations: {
            self.statsOverlayCollection.transform = top
            self.statsOverlayCollection.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.profileTable.transform = top
                self.profileTable.alpha = 1
                
                self.quizButtonSwitcher.isUserInteractionEnabled = true
                self.statsButtonSwitcher.isUserInteractionEnabled = true
            }, completion: nil)
        })
    }
    
    @objc private func switchToStats(){
        self.quizButtonSwitcher.isUserInteractionEnabled = false
        self.statsButtonSwitcher.isUserInteractionEnabled = false
        
        let topReturn = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.3, animations: {
            self.profileTable.transform = topReturn
            self.profileTable.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.statsOverlayCollection.transform = topReturn
                self.statsOverlayCollection.alpha = 1
                
                self.quizButtonSwitcher.isUserInteractionEnabled = true
                self.statsButtonSwitcher.isUserInteractionEnabled = true
            }, completion: nil)
        })
    }
    
    @objc func hideStatsOverlay(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.statOverlayCard.transform = top
            self.statOverlayCard.alpha = 0
            self.drawerOpen = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.statsOverlay.alpha = 0
                self.statsOverlayCollection.transform = top
                self.profileTable.transform = top
            }, completion: nil)
        })
    }
    
    private func roundCorners(cornerRadius: Double, view: UIView) {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }
    
    private func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    @objc private func rivalClicked(){
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(self.closeOverlay))
        self.rivalClose.isUserInteractionEnabled = true
        self.rivalClose.addGestureRecognizer(closeTap)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalBlur.alpha = 1
            
            self.rivalGameCollection.dataSource = self
            self.rivalGameCollection.delegate = self
        }, completion: { (finished: Bool) in
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.rivalOverlay.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc private func closeOverlay(){
        UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
            self.rivalOverlay.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                self.rivalBlur.alpha = 0
            }, completion: nil)
        })
    }
    
    private func progressRival(){
        let top = CGAffineTransform(translationX: -(self.rivalGameView.bounds.width), y: 0)
        
        UIView.transition(with: self.rivalOverlayHeader,
             duration: 0.3,
              options: .transitionCrossDissolve,
           animations: { [weak self] in
               self?.rivalOverlayHeader.text = "how are you wanting to play?"
         }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.rivalGameView.transform = top
                self.rivalGameView.alpha = 0
            }, completion: { (finished: Bool) in
                let coOpTap = UITapGestureRecognizer(target: self, action: #selector(self.coOpClicked))
                self.rivalCoOpSelection.isUserInteractionEnabled = true
                self.rivalCoOpSelection.addGestureRecognizer(coOpTap)
                
                let rivalTap = UITapGestureRecognizer(target: self, action: #selector(self.rivalOptionlicked))
                self.rivalRivalSelection.isUserInteractionEnabled = true
                self.rivalRivalSelection.addGestureRecognizer(rivalTap)
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.rivalTypeView.alpha = 1
                }, completion: nil)
            })
        })
    }
    
    @objc private func coOpClicked(){
        self.rivalLoadingOverlay.backgroundColor = UIColor(named: "greenAlpha")
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            self.rivalOverlaySpinner.startAnimating()
            self.rivalSelectedType = "co-op"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.sendPayload()
            }
        }, completion: nil)
    }
    
    @objc private func rivalOptionlicked(){
        self.rivalLoadingOverlay.backgroundColor = UIColor(named: "redAlpha")
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            self.rivalOverlaySpinner.startAnimating()
            self.rivalSelectedType = "rival"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.sendPayload()
            }
        }, completion: nil)
    }
    
    private func sendPayload(){
        let manager = FriendsManager()
        manager.createRivalRequest(otherUser: self.userForProfile!, game: self.rivalSelectedGame, type: self.rivalSelectedType, callbacks: self, gamerTags: self.userForProfile!.gamerTags)
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalResponseAccepted(indexPath: IndexPath) {
    }
    
    func rivalResponseRejected(indexPath: IndexPath) {
    }
    
    func rivalResponseFailed() {
    }
    
    func rivalRequestSuccess() {
        self.rivalSendResultText.text = "sent!"
        self.rivalSendResultSub.text = "one step closer."
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 0
            }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                self.rivalSendResultOverlay.alpha = 1
            }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                        self.rivalOverlay.alpha = 0
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                            self.rivalBlur.alpha = 0
                        
                            self.self.rivalButton.alpha = 0.3
                            self.rivalButton.isUserInteractionEnabled = false
                        
                            if(self.rivalSelectedType == "co-op"){
                                UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                                    self.rivalButton.backgroundColor = UIColor(named: "greenToDarker")
                                    self.headerView.backgroundColor = UIColor(named: "greenToDarker")
                                }, completion: nil)
                            }
                        else{
                            UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                                 self.rivalButton.backgroundColor = UIColor(named: "redToDark")
                                 self.headerView.backgroundColor = UIColor(named: "redToDark")
                            }, completion: nil)
                        }
                    }, completion: nil)
                })
            })
        })
    }
    
    func rivalRequestFail() {
        self.rivalSendResultText.text = "error!"
        self.rivalSendResultSub.text = "our bad. please try again."
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                self.rivalSendResultOverlay.alpha = 1
            }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                        self.rivalOverlay.alpha = 0
                    }, completion: { (finished: Bool) in
                      UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.rivalBlur.alpha = 1
                    }, completion: nil)
                })
            })
        })
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        var currentRival: RivalObj?
        
        var alreadyARival = false
        for rival in currentUser.currentTempRivals{
            let dbDate = self.stringToDate(rival.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let future = formatter.string(from: dbDate as Date)
                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                
                let validRival = (now as Date).compare(.isEarlier(than: dbTimeOut))
                
                if(dbTimeOut != nil){
                    if(!validRival){
                        currentUser.currentTempRivals.remove(at: currentUser.currentTempRivals.index(of: rival)!)
                    }
                    else{
                        if(rival.uid == userForProfile!.uId){
                            alreadyARival = true
                            currentRival = rival
                        }
                    }
                }
            }
        }
        
        for rival in currentUser.tempRivals{
            let dbDate = self.stringToDate(rival.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let future = formatter.string(from: dbDate as Date)
                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                
                let validRival = (now as Date).compare(.isEarlier(than: dbTimeOut))
                
                if(dbTimeOut != nil){
                    if(!validRival){
                        currentUser.tempRivals.remove(at: currentUser.tempRivals.index(of: rival)!)
                    }
                    else{
                        if(rival.uid == userForProfile!.uId){
                            alreadyARival = true
                            currentRival = rival
                        }
                    }
                }
            }
        }
        
        var contained = false
        var gcPayload = [String]()
        for game in userForProfile!.gamerTags{
            for currentUserGame in delegate.currentUser!.gamerTags{
                if (game.game == currentUserGame.game && !game.gamerTag.isEmpty){
                    contained = true
                    gcPayload.append(game.game)
                }
            }
        }
        
        if(contained && !alreadyARival){
            rivalButton.alpha = 1
            rivalButton.addTarget(self, action: #selector(rivalClicked), for: .touchUpInside)
            rivalButton.isUserInteractionEnabled = true
            
            checkGames(payload: gcPayload)
        }
        else if(contained && alreadyARival){
            rivalButton.alpha = 0.3
            rivalButton.isUserInteractionEnabled = false
            
            if(currentRival != nil){
                if(currentRival!.type == "co-op"){
                    UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                        self.rivalButton.titleLabel?.text = "co-op"
                        self.rivalButton.backgroundColor = UIColor(named: "greenToDarker")
                        self.headerView.backgroundColor = UIColor(named: "greenToDarker")
                    }, completion: nil)
                }
                else{
                    UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                        self.rivalButton.titleLabel?.text = "rival"
                        self.rivalButton.backgroundColor = UIColor(named: "redToDark")
                        self.headerView.backgroundColor = UIColor(named: "redToDark")
                    }, completion: nil)
                }
            }
        }
        else{
            rivalButton.alpha = 0
            rivalButton.isUserInteractionEnabled = false
        }
    }
    
    
    private func checkGames(payload: [String]){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        for game in delegate.gcGames{
            if(payload.contains(game.gameName)){
                self.rivalOverlayPayload.append(game)
            }
        }
    }
}

struct Section {
    var name: String
    var items: StatObject
    var collapsed: Bool
    
    init(name: String, items: StatObject, collapsed: Bool = false) {
        self.name = name
        self.items = items
        self.collapsed = collapsed
    }
    
    func getCount() -> Int{
        let stat = items
        var count = 0
        
        if(!stat.authorized.isEmpty){
            count += 1
        }
        
        if(!stat.currentRank.isEmpty){
            count += 1
        }
        
        if(!stat.gearScore.isEmpty){
            count += 1
        }
        
        if(!stat.killsPVE.isEmpty){
            count += 1
        }
        
        if(!stat.killsPVP.isEmpty){
            count += 1
        }
        
        if(!stat.mostUsedAttacker.isEmpty){
            count += 1
        }
        
        if(!stat.mostUsedDefender.isEmpty){
            count += 1
        }
        
        if(!stat.playerLevelGame.isEmpty){
            count += 1
        }
        
        if(!stat.playerLevelPVP.isEmpty){
            count += 1
        }
        
        if(!stat.setPublic.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedDeaths.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedKills.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedWins.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedLosses.isEmpty){
            count += 1
        }
        
        if(!stat.codKd.isEmpty){
            count += 1
        }
        if(!stat.codWins.isEmpty){
            count += 1
        }
        if(!stat.codWlRatio.isEmpty){
            count += 1
        }
        if(!stat.codKills.isEmpty){
            count += 1
        }
        if(!stat.codBestKills.isEmpty){
            count += 1
        }
        if(!stat.codLevel.isEmpty){
            count += 1
        }
        
        
        return count
    }
}

fileprivate struct C {
  struct CellHeight {
    static let close: CGFloat = 91 // equal or greater foregroundView height
    static let open: CGFloat = 166 // equal or greater containerView height
  }
}

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIView {
    @discardableResult
    func applyGradient(colours: [UIColor]) -> CAGradientLayer {
        return self.applyGradient(colours: colours, locations: nil)
    }

    @discardableResult
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
        return gradient
    }
    
    func applyGradient(colours: [UIColor], orientation: GradientOrientation) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        self.layer.insertSublayer(gradient, at: 0)
    }
}

extension UIVisualEffectView {

    func fadeInEffect(_ style:UIBlurEffect.Style = .light, withDuration duration: TimeInterval = 1.0) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: duration, curve: .easeIn) {
                self.effect = UIBlurEffect(style: style)
            }

            animator.startAnimation()
        }else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.effect = UIBlurEffect(style: style)
            }
        }
    }

    func fadeOutEffect(withDuration duration: TimeInterval = 1.0) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                self.effect = nil
            }

            animator.startAnimation()
            animator.fractionComplete = 1
        }else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.effect = nil
            }
        }
    }

}

extension Date {
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
