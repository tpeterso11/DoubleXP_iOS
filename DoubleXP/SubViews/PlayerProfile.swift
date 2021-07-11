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
import UnderLineTextField
import PopupDialog
import Lottie
import NotificationCenter
import SPStorkController
import YoutubeKit
import youtube_ios_player_helper

class PlayerProfile: ParentVC, UITableViewDelegate, UITableViewDataSource, ProfileCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, RequestsUpdate, UICollectionViewDelegateFlowLayout, SocialMediaManagerCallback, UITextFieldDelegate, SPStorkControllerDelegate, UITextViewDelegate, YTSwiftyPlayerDelegate {
    
    var uid: String = ""
    var userForProfile: User? = nil
    var currentBio = ""
    
    var keys = [String]()
    var objects = [GamerConnectGame]()
    var cellHeights: [CGFloat] = []
    var statsPayload = [String]()
    var test = false
    var socialSet = false
    var announcementAvailable = false
    var currentStream = ""
    var currentVideoPlaying: YoutubeVideoObj? = nil
    var currentHeaderCell: ProfileHeaderCell? = nil
    private var player: YTSwiftyPlayer!
    @IBOutlet weak var twitchConnectDrawer: UIView!
    //@IBOutlet weak var connectButton: UIImageView!
    @IBOutlet weak var twitchWorkSpinner: AnimationView!
    @IBOutlet weak var twitchDrawerWork: UIView!
    @IBOutlet weak var actionOverlay: UIVisualEffectView!
    @IBOutlet weak var actionDrawer: UIView!
    @IBOutlet weak var sentOverlay: UIView!
    @IBOutlet weak var sentText: UILabel!
    @IBOutlet weak var clickArea: UIView!
    //@IBOutlet weak var rivalButton: UIButton!
    
    @IBOutlet weak var blockBlur: UIVisualEffectView!
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
    @IBOutlet weak var statsOverlayCollection: UICollectionView!
    @IBOutlet weak var profileTable: UITableView!
    @IBOutlet weak var gtRegisterBlur: UIVisualEffectView!
    @IBOutlet weak var gtRegisterBox: UIView!
    @IBOutlet weak var gtEntryField: UnderLineTextField!
    @IBOutlet weak var sendGt: UIButton!
    @IBOutlet weak var dismissGtRegisterButton: UIButton!
    @IBOutlet weak var fullProfileTable: UITableView!
    
    @IBOutlet weak var twitchConnectOverlay: UIVisualEffectView!
    @IBOutlet weak var successOverlay: UIView!
    @IBOutlet weak var workBlur: UIVisualEffectView!
    @IBOutlet weak var workSpinner: AnimationView!
    @IBOutlet weak var twitchUserNameEntry: UnderLineTextField!
    @IBOutlet weak var twitchConnectNevermind: UIButton!
    @IBOutlet weak var twitchConnectButton: UIButton!
    @IBOutlet weak var twitchWorkLabel: UILabel!
    @IBOutlet weak var quizTable: UITableView!
    var localImageCache = NSCache<NSString, UIImage>()
    var currentTV: UITextField?
    
    var rivalOverlayPayload = [GamerConnectGame]()
    var sections = [Section]()
    var nav: NavigationPageController?
    var profilePayload = [FreeAgentObject]()
    var currentAddBioTag: UILabel?
    
    var rivalSelectedGame = ""
    var rivalSelectedType = ""
    var newGT = ""
    var currentStatsGame: GamerConnectGame?
    var statsSet = false
    var quizSet = false
    var currentKey = ""
    var twitchOnlineStatus = ""
    var drawerOpen = false
    var dataSet = false
    var twitchLoading = false
    var userBlocked = false
    var rivalStatus = "unavailable"
    var currentTwitchWV: WKWebView?
    private var quizPayload = [FAQuestion]()
    private var currentProfile: FreeAgentObject? = nil
    private var fullProfilePayload = [Any]()
    
    var showStats = false
    var showQuiz = false
    
    var gamesWithStats = [String]()
    var gamesWithQuiz = [String]()
    var bioExpanded = false
    var editMode = true
    var videoPaused = false
    
     enum Const {
           static let closeCellHeight: CGFloat = 100
           static let openCellHeight: CGFloat = 280
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let test = appDelegate.cachedTest
        if(!uid.isEmpty){
            //do nothing
        } else if(!test.isEmpty){
            self.uid = test
        } else {
            return
        }
        
        getInfoForProfile()
        
        appDelegate.currentProfileFrag = self
        
        self.actionOverlay.effect = nil
        actionOverlay.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            self.fullProfileTable.reloadData()
        }
        
        self.fullProfileTable.estimatedRowHeight = 250
        self.fullProfileTable.rowHeight = UITableView.automaticDimension
    }
    
    func getInfoForProfile(){
        UIView.animate(withDuration: 0.8, animations: {
            self.workBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.workSpinner.alpha = 1
                self.workSpinner.loopMode = .loop
                self.workSpinner.play()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.loadUserInfo(uid: self.uid)
                }
            })
        })
    }
    
    func changeChannel(selectedVideoId: String){
        UIView.animate(withDuration: 0.5, animations: {
            self.currentHeaderCell?.channelLoadingBlur?.alpha = 1
            self.currentHeaderCell?.headerYoutube.alpha = 0.3
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.loadUserVideo(uid: self.uid, selectedChannelId: selectedVideoId)
            }
        })
    }
    
    private func loadUserVideo(uid: String, selectedChannelId: String){
        let ref = Database.database().reference().child("YoutubeSubmissions").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for video in snapshot.children {
                    let currentVideo = (video as! DataSnapshot)
                    if(currentVideo.hasChild("youtubeId")){
                        let id = currentVideo.childSnapshot(forPath: "youtubeId").value as? String ?? ""
                        if(selectedChannelId == id){
                            let dict = currentVideo.value as! [String: Any]
                            let videoOwnerGt = dict["videoOwnerGamerTag"] as? String ?? ""
                            let videoOwnerUid = dict["videoOwnerUid"] as? String ?? ""
                            let youtubeFavorite = dict["youtubeFavorite"] as? String ?? ""
                            let youtubeId = dict["youtubeId"] as? String ?? ""
                            let youtubeImg = dict["youtubeImg"] as? String ?? ""
                            let date = dict["date"] as? String ?? ""
                            let downVotes = dict["downVotes"] as? [String] ?? [String]()
                            let upVotes = dict["upVotes"] as? [String] ?? [String]()
                            let title = dict["title"] as? String ?? ""
                            
                            let newVid = YoutubeVideoObj(title: title, videoOwnerGamerTag: videoOwnerGt, videoOwnerUid: videoOwnerUid, youtubeFavorite: youtubeFavorite, date: date, youtubeId: youtubeId, imgUrl: youtubeImg)
                            newVid.downVotes = downVotes
                            newVid.upVotes = upVotes
                            
                            self.currentVideoPlaying = newVid
                            self.fullProfileTable.reloadData()
                        }
                    }
                }
            }
        })
    }
    
    func friendRemoved() {
    }
    
    func friendRemoveFail() {
    }
    
    private func showWork(){
        UIView.animate(withDuration: 0.5, animations: {
            self.workBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.workSpinner.loopMode = .loop
                self.workSpinner.play()
            }, completion: nil)
        })
    }
    
    private func hideWork(){
        UIView.animate(withDuration: 0.5, animations: {
            self.workSpinner.pause()
            self.workSpinner.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.workBlur.alpha = 0
            }, completion: nil)
        })
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
                    self.showWork()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        manager.acceptFriendFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    }
                    break
                }
            }
        }
    }
    
    @objc func declineClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Accepted"))
        let manager = FriendsManager()
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            for invite in currentUser!.pendingRequests{
                if(self.userForProfile!.uId == invite.uid){
                    self.showWork()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        manager.declineRequestFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    }
                    break
                }
            }
        }
    }
    
    func onFriendAdded() {
        self.fullProfileTable.reloadData()
    }
    
    func onFriendDeclined() {
        //updateToRequestButton()
        self.fullProfileTable.reloadData()
    }
    
    func loadUserInfo(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            let value = snapshot.value as? NSDictionary
            let uId = snapshot.key
            let bio = value?["bio"] as? String ?? ""
            let gamerTag = value?["gamerTag"] as? String ?? ""
            let games = value?["games"] as? [String] ?? [String]()
            let twitchConnect = value?["twitchConnect"] as? String ?? ""
            let instaConnect = value?["instagramConnect"] as? String ?? ""
            let discordConnect = value?["discordConnect"] as? String ?? ""
            
            var googleApiAccessToken = ""
            var googleApiRefreshToken = ""
            if(currentUser!.uId == uId){
                googleApiAccessToken = value?["googleApiAccessToken"] as? String ?? ""
                googleApiRefreshToken = value?["googleApiRefreshToken"] as? String ?? ""
            }
            let userAge = value?["selectedAge"] as? String ?? ""
            let primary = value?["primaryLanguage"] as? String ?? ""
            let secondary = value?["secondaryLanguage"] as? String ?? ""
            let blockList = value?["blockList"] as? [String: String] ?? [String: String]()
            let restrictList = value?["restrictList"] as? [String: String] ?? [String: String]()
            let onlineStatus = value?["onlineStatus"] as? String ?? ""
            
            var youtubeVideos = [YoutubeVideoObj]()
            let videoArray = snapshot.childSnapshot(forPath: "youtubeVideos")
            for video in videoArray.children {
                let currentVid = video as! DataSnapshot
                let dict = currentVid.value as! [String: Any]
                let videoOwnerGt = dict["videoOwnerGamerTag"] as? String ?? ""
                let videoOwnerUid = dict["videoOwnerUid"] as? String ?? ""
                let youtubeFavorite = dict["youtubeFavorite"] as? String ?? ""
                let youtubeId = dict["youtubeId"] as? String ?? ""
                let youtubeImg = dict["youtubeImg"] as? String ?? ""
                let date = dict["date"] as? String ?? ""
                let downVotes = dict["downVotes"] as? [String] ?? [String]()
                let upVotes = dict["upVotes"] as? [String] ?? [String]()
                let title = dict["title"] as? String ?? ""
                
                let newVid = YoutubeVideoObj(title: title, videoOwnerGamerTag: videoOwnerGt, videoOwnerUid: videoOwnerUid, youtubeFavorite: youtubeFavorite, date: date, youtubeId: youtubeId, imgUrl: youtubeImg)
                newVid.downVotes = downVotes
                newVid.upVotes = upVotes
                youtubeVideos.append(newVid)
            }
            
            var gamerTags = [GamerProfile]()
            let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
            for gamerTagObj in gamerTagsArray.children {
                let currentObj = gamerTagObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let currentTag = dict["gamerTag"] as? String ?? ""
                let currentGame = dict["game"] as? String ?? ""
                let console = dict["console"] as? String ?? ""
                let quizTaken = dict["quizTaken"] as? String ?? ""
                
                let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
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
            
            var lookingForArray = [String]()
            if(snapshot.hasChild("lookingFor")){
                lookingForArray = snapshot.childSnapshot(forPath: "lookingFor").value as? [String] ?? [String]()
            }
            
            var online = [OnlineObj]()
            if(snapshot.hasChild("onlineAnnouncements")){
                let announceArray = snapshot.childSnapshot(forPath: "onlineAnnouncements")
                for onlineAnnounce in announceArray.children{
                    let currentObj = onlineAnnounce as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["tag"] as? String ?? ""
                    let id = dict?["id"] as? String ?? ""
                    
                    let request = OnlineObj(tag: tag, friends: [String](), date: date, id: id)
                    
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
                            
                            let validAnnouncement = (now as Date).compare(.isEarlier(than: dbTimeOut))
                            
                            if(dbTimeOut != nil){
                                if(validAnnouncement){
                                    online.append(request)
                                }
                            }
                        }
                    }
                }
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
            user.instagramConnect = instaConnect
            user.discordConnect = discordConnect
            user.selectedAge = userAge
            user.primaryLanguage = primary
            user.secondaryLanguage = secondary
            user.blockList = Array(blockList.keys)
            user.restrictList = Array(restrictList.keys)
            user.onlineStatus = onlineStatus
            user.userLookingFor = lookingForArray
            user.youtubeVideos = youtubeVideos
            user.googleApiAccessToken = googleApiAccessToken
            user.googleApiRefreshToken = googleApiRefreshToken
            if(!online.isEmpty){
                user.currentOnlineAnnounement = online[0]
            } else {
                user.currentOnlineAnnounement = nil
            }
            user.badges = badges
            
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
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.blockList.contains(self.userForProfile!.uId) || self.userForProfile!.blockList.contains(delegate.currentUser!.uId)){
            self.blockBlur.alpha = 1
        }
        
        let friendsManager = FriendsManager()
        let currentUser = delegate.currentUser
        self.fullProfilePayload = [Any]()
        var consoleArray = [String]()
        for profile in user.gamerTags {
            if(!consoleArray.contains(profile.console)){
                consoleArray.append(profile.console)
            }
        }
        if(editMode){
            self.fullProfilePayload.append([manager.getGamerTag(user: user): consoleArray]) //header
            self.fullProfilePayload.append(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!))
            self.fullProfilePayload.append(user.bio)
            
        
            let two = EditObject()
            two.title = "build your gamer profile"
            self.fullProfilePayload.append(two)
            
            /*let profiles = userForProfile!.gamerTags
            var statsAvailable = false
            for profile in profiles {
                for game in delegate.gcGames {
                    if(game.statsAvailable && profile.game == game.gameName){
                        statsAvailable = true
                    }
                }
            }*/
            //if(statsAvailable){
            //    let three = EditObject()
            //    three.title = "add gameplay stats"
             //   self.fullProfilePayload.append(three)
            //}
            let four = EditObject()
            four.title = "add twitch"
            self.fullProfilePayload.append(four)
            
            let thee = EditObject()
            thee.title = "add discord"
            self.fullProfilePayload.append(thee)
            
            let six = EditObject()
            six.title = "add instagram"
            self.fullProfilePayload.append(six)
            
            let seven = EditObject()
            seven.title = "add youtube"
            self.fullProfilePayload.append(seven)
            
            let five = EditObject()
            five.title = "edit games"
            self.fullProfilePayload.append(five)
            self.fullProfilePayload.append("empty")
            
            checkOnlineAnnouncements()
        } else {
            if(!self.userForProfile!.twitchConnect.isEmpty){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let manager = appDelegate.socialMediaManager
                manager.checkTwitchStream(twitchId: self.userForProfile!.twitchConnect, callbacks: self)
            } else {
                self.reloadUserPayload()
                if(userForProfile!.uId != currentUser!.uId){
                    checkRivals()
                } else {
                    if(!dataSet){
                        self.fullProfileTable.delegate = self
                        self.fullProfileTable.dataSource = self
                        self.fullProfileTable.reloadData()
                        self.dataSet = true
                        
                        if(self.fullProfileTable.alpha == 0){
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                self.fullProfileTable.alpha = 1
                            }, completion: { (finished: Bool) in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.hideWork()
                                }
                            })
                        }
                    } else {
                        self.fullProfileTable.reloadData()
                        
                        if(self.workBlur.alpha == 1){
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.hideWork()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func mapAgeFromDB(value: String) -> String {
        if(value == "12_16"){
            return "12 - 16"
        } else if(value == "17_24"){
            return "17 - 24"
        } else if(value == "25_31"){
            return "25 - 31"
        } else {
            return "32 +"
        }
    }
    
    private func buildSocialList(user: User) -> [Any] {
        var payload = [Any]()
        if(!user.twitchConnect.isEmpty){
            let connected = TwitchAddedObject()
            connected.twitchId = user.twitchConnect
            payload.append(connected)
        }
        if(!user.discordConnect.isEmpty){
            let connected = DiscordAddedObject()
            connected.handle = user.discordConnect
            payload.append(connected)
        }
        if(!user.instagramConnect.isEmpty){
            let connected = InstaAddedObject()
            connected.instaId = user.instagramConnect
            payload.append(connected)
        }
        return payload
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
    
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        if(state == .paused || state == .ended){
            self.videoPaused = true
        } else {
            self.videoPaused = false
        }
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
            self.twitchDrawerWork.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.twitchWorkSpinner.alpha = 1
                self.twitchWorkSpinner.loopMode = .loop
                self.twitchWorkSpinner.play()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                    ref.child("twitchConnect").setValue(self.twitchUserNameEntry.text!)
                    
                    self.dismissTwitchConnectOverlay(register: true)
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let manager = appDelegate.socialMediaManager
                    manager.checkTwitchStream(twitchId: self.twitchUserNameEntry.text!, callbacks: self)
                }
            })
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
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for game in self.userForProfile!.games{
            for gcGame in delegate.gcGames{
                if(game == gcGame.gameName){
                    self.objects.append(gcGame)
                }
            }
        }
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
        self.twitchLoading = false
        
        DispatchQueue.main.async() {
            if(streams.isEmpty){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                self.twitchOnlineStatus = "offline"
                self.reloadUserPayload()
                if(self.userForProfile!.uId == delegate.currentUser!.uId){
                    self.checkOnlineAnnouncements()
                } else {
                    self.checkRivals()
                }
            } else {
                self.twitchOnlineStatus = "online"
                let currentStream = streams[0]
                self.currentStream = currentStream.handle
                NotificationCenter.default.addObserver(self, selector: #selector(self.enteredBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.reloadFromResume), name: UIApplication.didBecomeActiveNotification, object: nil)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                self.reloadUserPayload()
                if(self.userForProfile!.uId == delegate.currentUser!.uId){
                    self.checkOnlineAnnouncements()
                } else {
                    self.checkRivals()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.currentTwitchWV?.load(URLRequest(url: URL(string:"about:blank")!))
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func reloadFromResume(){
        self.fullProfileTable.reloadData()
    }
    
    func onChannelsLoaded(channels: [Any]) {
    }
    
    @objc func startTwitch(){
        self.twitchLoading = true
        self.fullProfileTable.reloadData()
    }
    
    private func rebuildPayload(){
        UIView.animate(withDuration: 0.8, animations: {
            self.workBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.workSpinner.alpha = 1
                self.workSpinner.loopMode = .loop
                self.workSpinner.play()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.loadUserInfo(uid: self.uid)
                }
            })
        })
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
        //self.gtEntryField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
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
        if(tableview == self.fullProfileTable){
            return self.fullProfilePayload.count
        } else {
            return self.quizPayload.count
        }
    }
    
    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableview == self.fullProfileTable){
            let current = self.fullProfilePayload[indexPath.item]
            if(current is [String: [String]]){
                let cell = tableview.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ProfileHeaderCell
                cell.selectionStyle = .none
                let currentLib = (current as! [String: [String]])
                let key = Array(currentLib.keys)[0]
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                self.currentHeaderCell = cell
                cell.gamertag.text = key
                
                if(!userForProfile!.onlineStatus.isEmpty){
                    cell.onlineStatus.alpha = 1
                    if(userForProfile!.uId == currentUser.uId){
                        cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                        cell.onlineStatus.text = "your status: online."
                        cell.onlineDot.alpha = 1
                    } else {
                        if(userForProfile!.onlineStatus == "online"){
                            cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                            cell.onlineStatus.text = "online."
                            cell.onlineDot.alpha = 1
                        } else if(userForProfile!.onlineStatus == "idle"){
                            cell.onlineStatus.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
                            cell.onlineStatus.text = "idle."
                            cell.onlineDot.alpha = 0
                        } else if(self.announcementAvailable){
                            cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                            cell.onlineStatus.text = "gaming right now!"
                            cell.onlineDot.alpha = 1
                        }
                        else {
                            cell.onlineStatus.alpha = 0
                            cell.onlineDot.alpha = 0
                        }
                    }
                } else {
                    cell.onlineStatus.alpha = 0
                    cell.onlineDot.alpha = 0
                }
                
                if(!editMode){
                    let payload = self.buildSocialList(user: userForProfile!)
                    cell.setSocial(list: payload, set: self.socialSet)
                    self.socialSet = true
                    
                    cell.setConsoles(consoles: currentLib[key]!)
                    cell.logo.alpha = 0.1
                    
                    if(!userForProfile!.youtubeVideos.isEmpty && twitchOnlineStatus != "online"){
                        cell.height.constant = 320
                        cell.layoutIfNeeded()
                        var currentVid: YoutubeVideoObj? = nil
                        if(self.currentVideoPlaying != nil){
                            currentVid = self.currentVideoPlaying
                            
                            if(cell.channelLoadingBlur.alpha == 1){
                                UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
                                    cell.channelLoadingBlur.alpha = 0
                                    cell.headerYoutube.alpha = 1
                                }, completion: nil)
                            }
                        }
                        if(currentVid == nil){
                            for video in userForProfile!.youtubeVideos {
                                if(video.youtubeFavorite == "true"){
                                    currentVid = video
                                    break
                                }
                            }
                        }
                        if(currentVid == nil){
                            currentVid = userForProfile!.youtubeVideos[0]
                        }
                        
                        self.createUpDownVoteListener()
                        self.player = YTSwiftyPlayer(frame: CGRect(x: -75, y: -50, width: cell.headerYoutube.bounds.width + 150, height: cell.headerYoutube.bounds.height + 150), playerVars: [
                                                        .mute(true),
                                                     .playsInline(true),
                                                     .videoID(currentVid!.youtubeId),
                                                     .loopVideo(true),
                                                        .disableKeyboardControl(true),
                                                        .autoplay(true),
                                                        .showLoadPolicy(false),
                                                        .showRelatedVideo(false),
                                                        .showInfo(false),
                                                        .showControls(VideoControlAppearance.hidden),
                                                        .showModestbranding(false)])
                        player.delegate = self
                        player.setPlaybackQuality(YTSwiftyVideoQuality.small)
                        player.mute()
                        player.loadPlayer()
                        player.autoplay = true
                        cell.headerYoutube.addSubview(player)
                        player.pauseVideo()
                        player.playVideo()
                        
                        if(cell.videoDrawerBlur.alpha == 1){
                            let top = CGAffineTransform(translationX: 0, y: 80)
                            UIView.animate(withDuration: 0.3, animations: {
                                cell.videoDrawerBlur.transform = top
                                cell.videoDrawerBase.transform = top
                                cell.videoDrawerBlur.alpha = 0
                                cell.videoDrawerBase.alpha = 0
                            }, completion: { (finished: Bool) in
                                UIView.animate(withDuration: 0.3, delay: 0.3, options: [], animations: {
                                    self.updateYoutubeVotes(cell: cell, vid: currentVid!)
                                    let back = CGAffineTransform(translationX: 0, y: 0)
                                    cell.videoDrawerBlur.transform = back
                                    cell.videoDrawerBase.transform = back
                                    cell.videoDrawerBlur.alpha = 1
                                    cell.videoDrawerBase.alpha = 1
                                }, completion: nil)
                            })
                        } else {
                            updateYoutubeVotes(cell: cell, vid: currentVid!)
                        }
                        self.currentVideoPlaying = currentVid!
                        
                        let gesture = CollapseGesture(target: self, action: #selector(collapseClicked))
                        gesture.currentVideoId = currentVid!.youtubeId
                        gesture.currentHeaderCell = cell
                        cell.collapse.isUserInteractionEnabled = true
                        cell.collapse.addGestureRecognizer(gesture)
                        
                        let expandGesture = CollapseGesture(target: self, action: #selector(expandGTClicked))
                        expandGesture.currentVideoId = currentVid!.youtubeId
                        expandGesture.currentHeaderCell = cell
                        cell.expand.isUserInteractionEnabled = true
                        cell.expand.addGestureRecognizer(expandGesture)
                    } else {
                        cell.height.constant = 50
                        cell.layoutIfNeeded()
                        
                        cell.headerYoutube.alpha = 0
                        cell.collapse.alpha = 0
                    }
                } else {
                    cell.height.constant = 50
                    cell.layoutIfNeeded()
                    
                    cell.playingTag.alpha = 0
                    cell.consoleCollection.isHidden = true
                    cell.headerYoutube.alpha = 0
                    cell.collapse.alpha = 0
                    cell.logo.alpha = 0.0
                }
            
                if(currentUser.uId != self.userForProfile!.uId){
                    cell.editProfileTag.alpha = 0
                    cell.more.alpha = 1
                    cell.more.isUserInteractionEnabled = true
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(moreClicked))
                    cell.more.isUserInteractionEnabled = true
                    cell.more.addGestureRecognizer(singleTap)
                } else {
                    cell.more.alpha = 0
                    cell.more.isUserInteractionEnabled = false
                    if(editMode){
                        cell.editProfileTag.alpha = 1
                    }
                }
                return cell
            } else if(current is [String]){
                let cell = tableview.dequeueReusableCell(withIdentifier: "info", for: indexPath) as! ProfileUserInfoCell
                let currentList = (current as! [String])
                cell.selectionStyle = .none
                cell.ageText.text = self.mapAgeFromDB(value: currentList[0])
                cell.primaryText.text = currentList[1]
                cell.secondaryText.text = currentList[2]
                return cell
            } else if(current is [YoutubeVideoObj]){
                let cell = tableview.dequeueReusableCell(withIdentifier: "youtube", for: indexPath) as! ProfileYoutubeCell
                let currentList = (current as! [YoutubeVideoObj])
                cell.setVideos(payload: currentList, currentProfile: self)
                
                let gesture = ExpandVideosGesture(target: self, action: #selector(expandVideosClicked))
                gesture.currentHeaderCell = cell
                gesture.expand = !cell.videoDrawer.isHidden
                cell.expand.isUserInteractionEnabled = true
                cell.expand.addGestureRecognizer(gesture)
                
                return cell
            } else if(current is Bool){
                if(current as! Bool){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "interaction", for: indexPath) as! ProfileFriendInteractionCell
                    cell.selectionStyle = .none
                    
                    if self.traitCollection.userInterfaceStyle == .dark {
                        cell.message.backgroundColor = .white
                    } else {
                        cell.message.backgroundColor = UIColor(named: "frostwhite")
                    }
                    cell.message.addTarget(self, action: #selector(openMessaging), for: .touchUpInside)
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser!
                    if(self.userForProfile!.restrictList.contains(currentUser.uId)){
                        cell.restrictedCover.alpha = 1
                    } else {
                        cell.restrictedCover.alpha = 0
                        if(self.rivalStatus == "unavailable"){
                            cell.wannaPlay.backgroundColor = #colorLiteral(red: 0.3333052099, green: 0.3333491981, blue: 0.3332902789, alpha: 1)
                            cell.wannaPlay.setTitle("request sent.", for: .normal)
                            cell.wannaPlay.alpha = 0.4
                            cell.wannaPlay.isUserInteractionEnabled = false
                        } else {
                            cell.wannaPlay.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                            cell.wannaPlay.setTitle("wanna play?", for: .normal)
                            cell.wannaPlay.alpha = 1.0
                            cell.isUserInteractionEnabled = true
                            cell.wannaPlay.addTarget(self, action: #selector(playClicked), for: .touchUpInside)
                        }
                        
                        cell.wannaPlay.layer.shadowColor = UIColor.black.cgColor
                        cell.wannaPlay.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                        cell.wannaPlay.layer.shadowRadius = 1.0
                        cell.wannaPlay.layer.shadowOpacity = 0.5
                        cell.wannaPlay.layer.masksToBounds = false
                        cell.wannaPlay.layer.shadowPath = UIBezierPath(roundedRect:  cell.wannaPlay.bounds, cornerRadius:  cell.wannaPlay.layer.cornerRadius).cgPath
                    }
                    return cell
                } else {
                    let cell = tableview.dequeueReusableCell(withIdentifier: "unknown", for: indexPath) as! ProfileUnknownInteractionCell
                    cell.selectionStyle = .none
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser!
                    if(currentUser.uId == self.userForProfile!.uId && editMode){
                        cell.pendingUserCover.alpha = 0
                        cell.currentUserCover.alpha = 1
                        
                        cell.noFriendsCover.alpha = 0
                        cell.editButton.addTarget(self, action: #selector(editClicked), for: .touchUpInside)
                        
                        cell.editButton.layer.shadowColor = UIColor.black.cgColor
                        cell.editButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                        cell.editButton.layer.shadowRadius = 1.0
                        cell.editButton.layer.shadowOpacity = 0.5
                        cell.editButton.layer.masksToBounds = false
                        cell.editButton.layer.shadowPath = UIBezierPath(roundedRect:  cell.editButton.bounds, cornerRadius:  cell.editButton.layer.cornerRadius).cgPath
                        
                        if(self.announcementAvailable){
                            cell.imGamingButton.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
                            cell.imGamingButton.isUserInteractionEnabled = false
                            cell.imGamingButton.setTitle("alert sent", for: .normal)
                        } else {
                            cell.imGamingButton.setTitle("jumping online", for: .normal)
                            cell.imGamingButton.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                            cell.alpha = 1
                            cell.imGamingButton.isUserInteractionEnabled = true
                            cell.imGamingButton.addTarget(self, action: #selector(onlineClicked), for: .touchUpInside)
                        }
                        
                        cell.imGamingButton.layer.shadowColor = UIColor.black.cgColor
                        cell.imGamingButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                        cell.imGamingButton.layer.shadowRadius = 1.0
                        cell.imGamingButton.layer.shadowOpacity = 0.5
                        cell.imGamingButton.layer.masksToBounds = false
                        cell.imGamingButton.layer.shadowPath = UIBezierPath(roundedRect:  cell.imGamingButton.bounds, cornerRadius:  cell.imGamingButton.layer.cornerRadius).cgPath
                        
                    } else if(currentUser.uId == self.userForProfile!.uId && !editMode) {
                        cell.currentUserCover.alpha = 1
                        cell.currentUserBlur.alpha = 1
                        cell.currentUserBlur.isUserInteractionEnabled = true
                    } else {
                        let manager = FriendsManager()
                        cell.currentUserCover.alpha = 0
                        if(manager.isPendingRequest(user: self.userForProfile!, currentUser: appDelegate.currentUser!)){
                            cell.pendingUserCover.alpha = 1
                            cell.acceptButton.addTarget(self, action: #selector(acceptClicked), for: .touchUpInside)
                            cell.declineButton.addTarget(self, action: #selector(declineClicked), for: .touchUpInside)
                        } else if(manager.isSentRequest(user: self.userForProfile!, currentUser: appDelegate.currentUser!)){
                            cell.requestButton.backgroundColor = #colorLiteral(red: 0.2880555391, green: 0.2778990865, blue: 0.2911514342, alpha: 0.8045537243)
                            cell.requestButton.alpha = 0.5
                            cell.requestButton.setTitle( "request sent.", for: .normal)
                            cell.requestButton.isUserInteractionEnabled = false
                        } else {
                            if(!currentUser.gamerTag.isEmpty){
                                cell.requestButton.addTarget(self, action: #selector(requestClicked), for: .touchUpInside)
                            } else {
                                cell.requestButton.setTitle("unavailable", for: .normal)
                                cell.requestButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                                cell.alpha = 0.3
                                cell.isUserInteractionEnabled = false
                            }
                        }
                    }
                    return cell
                }
            } else if(current is String){
                if((current as! String) == "twitch"){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "twitch", for: indexPath) as! ProfileTwitchCell
                    cell.selectionStyle = .none
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    UIView.transition(with: cell.twitchLogo, duration: 0.8, options: .curveEaseInOut, animations: {
                        cell.twitchLogo.tintColor = UIColor(named: "twitchPurple")
                    }, completion: nil)
                    
                    if(self.twitchLoading){
                        if(cell.workBlur.alpha == 0){
                            UIView.animate(withDuration: 0.8, animations: {
                                cell.workBlur.alpha = 1
                            }, completion: { (finished: Bool) in
                                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                    cell.workSpinner.loopMode = .loop
                                    cell.workSpinner.play()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        let test = "https://doublexpstorage.tech/stream.php?channel=" + self.currentStream
                                        cell.popOutPlayer.load(NSURLRequest(url: NSURL(string: test)! as URL) as URLRequest)
                                        self.twitchLoading = false
                                    }
                                }, completion: nil)
                            })
                        }
                        return cell
                    }
                    
                    if(!self.twitchLoading && cell.workBlur.alpha == 1){
                        UIView.animate(withDuration: 0.8, animations: {
                            cell.workSpinner.pause()
                            cell.workSpinner.alpha = 0
                        }, completion: { (finished: Bool) in
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                cell.workBlur.alpha = 0
                            }, completion: nil)
                        })
                    }
                    if(!userForProfile!.twitchConnect.isEmpty){
                        if(self.twitchOnlineStatus == "online"){
                            let playTwitch = UITapGestureRecognizer(target: self, action: #selector(self.startTwitch))
                            cell.onlineView.isUserInteractionEnabled = true
                            cell.onlineView.addGestureRecognizer(playTwitch)
                            cell.offlineView.alpha = 0
                            cell.notConnectedView.alpha = 0
                            cell.onlineView.alpha = 1
                            cell.connectView.alpha = 0
                            cell.currentUserView.alpha = 0
                            
                            let configuration = WKWebViewConfiguration()
                            configuration.allowsInlineMediaPlayback = true
                            configuration.mediaTypesRequiringUserActionForPlayback = .audio
                            let webView = WKWebView(frame: cell.fullWVShell.bounds, configuration: configuration)
                            cell.fullWVShell.addSubview(webView)
                            self.currentTwitchWV = webView
                            
                            let test = "https://doublexpstorage.tech/stream.php?channel=" + self.userForProfile!.twitchConnect
                            webView.load(NSURLRequest(url: NSURL(string: test)! as URL) as URLRequest)
                        } else {
                            cell.offlineView.alpha = 0
                            cell.notConnectedView.alpha = 0
                            cell.onlineView.alpha = 0
                            cell.connectView.alpha = 0
                            cell.currentUserView.alpha = 0
                            cell.twitchLogo.alpha = 0
                        }
                    }
                    return cell
                } else if((current as! String) == "looking"){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "lookingFor", for: indexPath) as! ProfileLookingForCell
                    cell.selectionStyle = .none
                    cell.setCollection(list: userForProfile!.userLookingFor, completion: {
                        if tableview.indexPath(for: cell) == indexPath {
                            tableview.reloadRows(at: [indexPath], with: .none)
                        }
                    })
                    self.test = true
                    return cell
                } else if((current as! String) == "empty"){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
                    cell.selectionStyle = .none
                    return cell
                }  else {
                    let cell = tableview.dequeueReusableCell(withIdentifier: "bio", for: indexPath) as! ProfileBioCell
                    cell.selectionStyle = .none
        
                    cell.expandCollapse.alpha = 0
                    cell.expandCollapse.isUserInteractionEnabled = false
                    
                    cell.bio.delegate = self
                    self.currentAddBioTag = cell.addBioTag
                    if(editMode){
                        if(userForProfile!.bio.isEmpty){
                            cell.addBioTag.alpha = 1
                            cell.myBio.text = "edit your bio"
                        } else {
                            cell.addBioTag.alpha = 0
                            cell.bio.textAlignment = .center
                            cell.bio.text = userForProfile!.bio
                        }
                        cell.tapEditLabel.alpha = 1
                        cell.bio.isUserInteractionEnabled = true
                        cell.bio.isEditable = true
                        cell.bio.textContainer.maximumNumberOfLines = 3
                        cell.bio.textContainer.lineBreakMode = .byWordWrapping
                        cell.bio.font = UIFont.systemFont(ofSize: cell.bio.font!.pointSize)
                        cell.myBio.alpha = 1
                        //known bug: Bio cell cuts off bio when scrolled and then scrolled back once or twice.
                        self.adjustUITextViewHeight(arg: cell.bio, cell: cell)
                    } else {
                        cell.tapEditLabel.alpha = 0
                        cell.myBio.alpha = 1
                        cell.myBio.text = "my bio."
                        cell.addBioTag.alpha = 0
                        cell.bio.text = (current as? String) ?? "bio unavailable"
                        cell.bio.isUserInteractionEnabled = false
                        cell.bio.textContainer.maximumNumberOfLines = 3
                        cell.bio.textContainer.lineBreakMode = .byWordWrapping
                        cell.bio.font = UIFont.italicSystemFont(ofSize: cell.bio.font!.pointSize)
                        self.adjustUITextViewHeight(arg: cell.bio, cell: cell)
                    }
                    
                    return cell
                }
            }  else if(current is [BadgeObj]){
                let cell = tableview.dequeueReusableCell(withIdentifier: "badges", for: indexPath) as! ProfileBadgeCell
                cell.setBadges(payload: (current as! [BadgeObj]))
                cell.selectionStyle = .none
                return cell
            }  else if(current is EditObject){
               let cell = tableview.dequeueReusableCell(withIdentifier: "connectCell", for: indexPath) as! ConnectCell
                cell.selectionStyle = .none
                if((current as! EditObject).title == "add twitch" && !self.userForProfile!.twitchConnect.isEmpty){
                    cell.connectLabel.text = "manage twitch"
                    cell.disconnectButton.alpha = 0
                    cell.connectLogo.image = #imageLiteral(resourceName: "580b57fcd9996e24bc43c540.png")
                    cell.connectLogo.alpha = 1
                    return cell
                } else if ((current as! EditObject).title == "add instagram" && !self.userForProfile!.instagramConnect.isEmpty){
                    cell.connectLabel.text = "manage instagram"
                    cell.disconnectButton.alpha = 0
                    cell.connectLogo.image = #imageLiteral(resourceName: "instagram.png")
                    cell.connectLogo.alpha = 1
                    return cell
                } else if((current as! EditObject).title == "add discord" && !self.userForProfile!.discordConnect.isEmpty){
                    cell.connectLabel.text = "manage discord"
                    cell.disconnectButton.alpha = 0
                    cell.connectLogo.image = #imageLiteral(resourceName: "discord.png")
                    cell.connectLogo.alpha = 1
                    return cell
                } else if((current as! EditObject).title == "add youtube" && !self.userForProfile!.googleApiAccessToken.isEmpty){
                    cell.connectLabel.text = "manage youtube"
                    cell.disconnectButton.alpha = 0
                    cell.connectLogo.image = #imageLiteral(resourceName: "discord.png")
                    cell.connectLogo.alpha = 1
                    return cell
                } else if(((current as! EditObject).title == "build your gamer profile")){
                    cell.connectLogo.image = #imageLiteral(resourceName: "star (9).png")
                    cell.connectLogo.alpha = 1
                    cell.connectLabel.text = (current as! EditObject).title
                    cell.disconnectButton.alpha = 0
                    return cell
                }
                cell.connectLabel.text = (current as! EditObject).title
                cell.disconnectButton.alpha = 0
                cell.connectLogo.alpha = 0
                return cell
           } else {
                let cell = tableview.dequeueReusableCell(withIdentifier: "games", for: indexPath) as! ProfileMyGamesCell
                cell.selectionStyle = .none
                if(userForProfile!.games.isEmpty){
                    cell.noTagCover.alpha = 1
                } else {
                    cell.noTagCover.alpha = 0
                    cell.setupGames()
                }
                return cell
            }
        }
        else {
            let current = quizPayload[indexPath.item]
            
            if(!current.answer.isEmpty){
                if(current.answer.contains("/DXP/")){
                    let cell = tableview.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath) as! OptionAnswerCell
                    let adjustedPayload = [current.answer]
                    cell.question.text = current.question
                    
                    cell.setOptions(options: adjustedPayload, cache: self.localImageCache, game: self.currentStatsGame)
                    
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
                    cell.setOptions(options: current.answerArray, cache: self.localImageCache, game: self.currentStatsGame)
                    
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
        if(tableview == self.fullProfileTable){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cell = tableview.cellForRow(at: indexPath)
            if(cell is ProfileBioCell){
                return 200
            } else {
                return self.fullProfileTable.rowHeight
            }
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
    
    @objc private func manageYoutube(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "youtube") as! YoutubeConnect
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.profileUser = userForProfile!
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func adjustUITextViewHeight(arg : UITextView, cell: ProfileBioCell)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
        cell.bio.frame.size.width = self.view.frame.size.width - 20
    }
    
    @objc private func disconnectTwitch(){
        let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
        ref.child("twitchConnect").removeValue()
        self.userForProfile!.twitchConnect = ""
        self.fullProfileTable.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fullProfileTable.reloadData()
    }
    
    @objc func enteredBackground(notification: Notification) {
        self.currentTwitchWV?.load(URLRequest(url: URL(string:"about:blank")!))
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        if(self.currentBio != self.userForProfile!.bio && !self.currentBio.isEmpty){
            let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
            if(self.currentBio.isEmpty){
                ref.child("bio").removeValue()
                return
            }
            ref.child("bio").setValue(self.currentBio)
            
            self.userForProfile!.bio = currentBio
            DispatchQueue.main.async{
                self.fullProfileTable.reloadData()
            }
        }
    }
    
    private func updateYoutubeVotes(cell: ProfileHeaderCell, vid: YoutubeVideoObj){
        let upVoteCount = vid.upVotes.count
        if(upVoteCount < 9){
            cell.upVoteCount.text = "0" + String(upVoteCount)
        } else {
            cell.upVoteCount.text = String(upVoteCount)
        }
        
        let downVoteCount = vid.downVotes.count
        if(downVoteCount < 9){
            cell.downVoteCount.text = "0" + String(downVoteCount)
        } else {
            cell.downVoteCount.text = String(downVoteCount)
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        if(vid.upVotes.contains(currentUser?.uId ?? "nil")){
            cell.upVoteButton.alpha = 0.3
            cell.upVoteButton.isUserInteractionEnabled = false
        } else {
            cell.upVoteButton.alpha = 1.0
            let gesture = VoteGesture(target: self, action: #selector(upDownVoteClicked))
            gesture.currentVideoId = vid.youtubeId
            gesture.currentHeaderCell = cell
            gesture.upVote = true
            cell.upVoteButton.isUserInteractionEnabled = true
            cell.upVoteButton.addGestureRecognizer(gesture)
        }
    
        if(vid.downVotes.contains(currentUser?.uId ?? "nil")){
            cell.downVoteButton.alpha = 0.5
            cell.downVoteButton.isUserInteractionEnabled = false
        } else {
            cell.downVoteButton.alpha = 1.0
            let downGesture = VoteGesture(target: self, action: #selector(upDownVoteClicked))
            downGesture.currentVideoId = vid.youtubeId
            downGesture.currentHeaderCell = cell
            downGesture.upVote = false
            cell.downVoteButton.isUserInteractionEnabled = true
            cell.downVoteButton.addGestureRecognizer(downGesture)
        }
    }
    
    @objc private func expandVideosClicked(sender: ExpandVideosGesture){
        UIView.animate(withDuration: 0.3, animations: {
            self.fullProfileTable.performBatchUpdates(nil)
        }, completion: nil)
    }
    
    @objc private func upDownVoteClicked(sender: VoteGesture){
        var vid: YoutubeVideoObj? = nil
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        for video in userForProfile!.youtubeVideos {
            if(sender.currentVideoId == video.youtubeId){
                vid = video
            }
        }
        if(vid == nil){
            return
        }
        if(sender.upVote){
            //master
            var dbDownVotes = [String]()
            var dbUpVotes = [String]()
            var updatedDb = false
            let masterYoutubeRef = Database.database().reference().child("YoutubeSubmissions").child(userForProfile!.uId)
            masterYoutubeRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    for video in snapshot.children {
                        if((video as! DataSnapshot).hasChild("youtubeId")){
                            let id = (video as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                            if(id == sender.currentVideoId){
                                if(vid!.downVotes.contains(currentUser!.uId)){
                                    dbDownVotes = (video as! DataSnapshot).childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                    if(dbDownVotes.contains(currentUser!.uId)){
                                        dbDownVotes.remove(at: dbDownVotes.index(of: currentUser!.uId)!)
                                        vid!.downVotes = dbDownVotes
                                        masterYoutubeRef.child((video as! DataSnapshot).key).child("downVotes").setValue(dbDownVotes)
                                    }
                                }
                                if(!vid!.upVotes.contains(currentUser!.uId)){
                                    dbUpVotes = (video as! DataSnapshot).childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                    if(!dbUpVotes.contains(currentUser!.uId)){
                                        dbUpVotes.append(currentUser!.uId)
                                        vid!.upVotes = dbUpVotes
                                        masterYoutubeRef.child((video as! DataSnapshot).key).child("upVotes").setValue(dbUpVotes)
                                    }
                                }
                                self.updateYoutubeVotes(cell: sender.currentHeaderCell!, vid: vid!)
                                updatedDb = true
                                break
                            }
                        }
                    }
                }
                
                //handle user downvotes
                if(updatedDb){
                    let youtubeRef = Database.database().reference().child("Users").child(self.userForProfile!.uId)
                    youtubeRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        if(snapshot.hasChild("youtubeVideos")){
                            let vidArray = snapshot.childSnapshot(forPath: "youtubeVideos")
                            for video in vidArray.children {
                                if((video as! DataSnapshot).hasChild("youtubeId")){
                                    let id = (video as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                                    if(id == sender.currentVideoId){
                                        youtubeRef.child("youtubeVideos").child((video as! DataSnapshot).key).child("downVotes").setValue(dbDownVotes)
                                        youtubeRef.child("youtubeVideos").child((video as! DataSnapshot).key).child("upVotes").setValue(dbUpVotes)
                                        break
                                    }
                                }
                            }
                        }
                    })
                }
            })
        } else {
            //master
            var updatedDb = false
            var dbUpVotes = vid!.upVotes
            var dbDownVotes = vid!.downVotes
            let masterYoutubeRef = Database.database().reference().child("YoutubeSubmissions").child(userForProfile!.uId)
            masterYoutubeRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    for video in snapshot.children {
                        if((video as! DataSnapshot).hasChild("youtubeId")){
                            let id = (video as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                            if(id == sender.currentVideoId){
                                if(vid!.upVotes.contains(currentUser!.uId)){
                                    dbUpVotes = (video as! DataSnapshot).childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                    if(dbUpVotes.contains(currentUser!.uId)){
                                        dbUpVotes.remove(at: dbUpVotes.index(of: currentUser!.uId)!)
                                        vid!.upVotes = dbUpVotes
                                        masterYoutubeRef.child((video as! DataSnapshot).key).child("upVotes").setValue(dbUpVotes)
                                    }
                                }
                                if(!vid!.downVotes.contains(currentUser!.uId)){
                                    dbDownVotes = (video as! DataSnapshot).childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                    if(!dbDownVotes.contains(currentUser!.uId)){
                                        dbDownVotes.append(currentUser!.uId)
                                        vid!.downVotes = dbDownVotes
                                        masterYoutubeRef.child((video as! DataSnapshot).key).child("downVotes").setValue(dbDownVotes)
                                    }
                                }
                                self.updateYoutubeVotes(cell: sender.currentHeaderCell!, vid: vid!)
                                updatedDb = true
                                break
                            }
                        }
                    }
                }
                
                if(updatedDb){
                    let youtubeRef = Database.database().reference().child("Users").child(self.userForProfile!.uId)
                    youtubeRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        if(snapshot.hasChild("youtubeVideos")){
                            let vidArray = snapshot.childSnapshot(forPath: "youtubeVideos")
                            for video in vidArray.children {
                                if((video as! DataSnapshot).hasChild("youtubeId")){
                                    let id = (video as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                                    if(id == sender.currentVideoId){
                                        youtubeRef.child("youtubeVideos").child((video as! DataSnapshot).key).child("upVotes").setValue(dbUpVotes)
                                        youtubeRef.child("youtubeVideos").child((video as! DataSnapshot).key).child("downVotes").setValue(dbDownVotes)
                                        break
                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    private func createUpDownVoteListener(){
        let newFriendRef = Database.database().reference().child("YoutubeSubmissions").child(self.userForProfile!.uId)
        newFriendRef.observe(.value, with: { (snapshot) in
            if(snapshot.exists()){
                for video in snapshot.children {
                    for userVideo in self.userForProfile!.youtubeVideos {
                        let currentDownVotes = (video as! DataSnapshot).childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                        let currentUpVotes = (video as! DataSnapshot).childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                        
                        userVideo.upVotes = currentUpVotes
                        userVideo.downVotes = currentDownVotes
                    }
                }
            }
        })
    }
    
    private func addDoneButtonOnKeyboard(tv: UITextField) {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissKeyboard))

        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)

        doneToolbar.items = items
        doneToolbar.sizeToFit()

        tv.inputAccessoryView = doneToolbar
        tv.delegate = self
    }
    
    @objc private func disconnectDiscord(){
        let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
        ref.child("discordConnect").removeValue()
        self.userForProfile!.discordConnect = ""
        self.fullProfileTable.reloadData()
    }
    
    @objc private func disconnectInstagram(){
        let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
        ref.child("instagramConnect").removeValue()
        self.userForProfile!.instagramConnect = ""
        self.fullProfileTable.reloadData()
    }
    
    @objc private func setOnAir(){
        
    }
    
    @objc private func setOffAir(){
        
    }

    @objc private func requestClicked(){
        self.showWork()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = FriendsManager()
            manager.sendRequestFromProfile(currentUser: delegate.currentUser!, otherUser: self.userForProfile!, callbacks: self)
        }
    }
    
    @objc private func editClicked(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedTest = uid
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.editMode = false
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func playClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "play") as! PlayDrawer
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let profileManager = delegate.profileManager
        profileManager.wannaPlayCachedUser = self.userForProfile!
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.variation = "play"
        transitionDelegate.showCloseButton = true
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = false
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 450
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func onlineClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "play") as! PlayDrawer
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let profileManager = delegate.profileManager
        profileManager.wannaPlayCachedUser = self.userForProfile!
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.variation = "online"
        transitionDelegate.showCloseButton = true
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = false
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 450
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func dismissModal(){
        self.getInfoForProfile()
    }
    
    func dismissModalPlaySuccess(){
        self.rivalStatus = "unavailable"
        self.fullProfileTable.reloadData()
        self.updateMoreComplete()
    }
    
    @objc func didDismissStorkBySwipe(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.uId != self.userForProfile!.uId){
            self.checkRivals()
            self.updateMoreComplete()
        } else {
            self.checkOnlineAnnouncements()
        }
    }
    
    @objc func didDismissStorkByTap() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.uId != self.userForProfile!.uId){
            self.checkRivals()
            self.updateMoreComplete()
        } else {
            self.checkOnlineAnnouncements()
        }
    }
    
    @objc private func expandClicked(){
        if(self.bioExpanded){
            self.bioExpanded = false
        } else {
            self.bioExpanded = true
        }
        
        self.fullProfileTable.reloadData()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if(editMode){
            self.currentAddBioTag?.alpha = 0
            textView.textAlignment = .left
            textView.textColor = UIColor.init(named: "whiteBackToDarkGrey")
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.currentBio = textView.text
     }
    
    @objc private func moreClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "options") as! OptionsList
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let profileManager = delegate.profileManager
        profileManager.moreOptionsCachedUser = self.userForProfile!
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.customHeight = 520
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }

    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableview == self.fullProfileTable){
            tableview.deselectRow(at: indexPath, animated: true)
            let current = self.fullProfilePayload[indexPath.item]
            if(current is EditObject){
                let currentObjTitle = (current as! EditObject).title
                if(currentObjTitle == "build your gamer profile"){
                    let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
                    currentViewController.extra = "quiz"
                    
                    let transitionDelegate = SPStorkTransitioningDelegate()
                    currentViewController.transitioningDelegate = transitionDelegate
                    currentViewController.modalPresentationStyle = .custom
                    currentViewController.modalPresentationCapturesStatusBarAppearance = true
                    transitionDelegate.showIndicator = true
                    transitionDelegate.swipeToDismissEnabled = true
                    transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                    transitionDelegate.storkDelegate = self
                    self.present(currentViewController, animated: true, completion: nil)
                } else if (currentObjTitle == "edit games"){
                    let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gameSelection") as! GameSelection
                    currentViewController.returning = true
                    currentViewController.modalPopped = true
                    
                    let transitionDelegate = SPStorkTransitioningDelegate()
                    currentViewController.transitioningDelegate = transitionDelegate
                    currentViewController.modalPresentationStyle = .custom
                    currentViewController.modalPresentationCapturesStatusBarAppearance = true
                    transitionDelegate.showIndicator = true
                    transitionDelegate.swipeToDismissEnabled = true
                    transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                    transitionDelegate.storkDelegate = self
                    self.present(currentViewController, animated: true, completion: nil)
                }   else if (currentObjTitle == "add instagram" || currentObjTitle == "manage instagram"){
                        if(self.userForProfile!.instagramConnect.isEmpty){
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "socialConnect") as! SocialConnectModal
                        currentViewController.thingType = "instagram"
                        
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = true
                        transitionDelegate.customHeight = 550
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                        } else {
                            var buttons = [PopupDialogButton]()
                            let title = "manage instagram"
                            let message = "do you want to remove your instagram from your account?"
                            
                            let buttonOne = DestructiveButton(title: "clear my info") { [weak self] in
                                if(self != nil){
                                    Database.database().reference().child("Users").child(self!.userForProfile!.uId).child("instagramConnect").removeValue()
                                    self!.getInfoForProfile()
                                }
                            }
                            buttons.append(buttonOne)
                            
                            let button = DefaultButton(title: "nah, nevermind.") { [weak self] in
                                //do nothing
                            }
                            buttons.append(button)
                            
                            let popup = PopupDialog(title: title, message: message)
                            popup.addButtons(buttons)

                            // Present dialog
                            self.present(popup, animated: true, completion: nil)
                        }
                } else if (currentObjTitle == "add discord" || currentObjTitle == "manage discord"){
                    if(self.userForProfile!.discordConnect.isEmpty){
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "socialConnect") as! SocialConnectModal
                        currentViewController.thingType = "discord"
                        
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = true
                        transitionDelegate.customHeight = 550
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                    } else {
                        var buttons = [PopupDialogButton]()
                        let title = "manage discord"
                        let message = "do you want to remove your discord from your account?"
                        
                        let buttonOne = DestructiveButton(title: "clear my info") { [weak self] in
                            if(self != nil){
                                Database.database().reference().child("Users").child(self!.userForProfile!.uId).child("discordConnect").removeValue()
                                self!.getInfoForProfile()
                            }
                        }
                        buttons.append(buttonOne)
                        
                        let button = DefaultButton(title: "nah, nevermind.") { [weak self] in
                            //do nothing
                        }
                        buttons.append(button)
                        
                        let popup = PopupDialog(title: title, message: message)
                        popup.addButtons(buttons)

                        // Present dialog
                        self.present(popup, animated: true, completion: nil)
                    }
                } else if (currentObjTitle == "add twitch" || currentObjTitle == "manage twitch"){
                    if(self.userForProfile!.twitchConnect.isEmpty){
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "socialConnect") as! SocialConnectModal
                        currentViewController.thingType = "twitch"
                        
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = true
                        transitionDelegate.customHeight = 550
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                    }
                } else if (currentObjTitle == "add youtube" || currentObjTitle == "manage youtube"){
                    let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "youtube") as! YoutubeConnect
                    
                    let transitionDelegate = SPStorkTransitioningDelegate()
                    currentViewController.transitioningDelegate = transitionDelegate
                    currentViewController.modalPresentationStyle = .custom
                    currentViewController.modalPresentationCapturesStatusBarAppearance = true
                    currentViewController.profileUser = userForProfile!
                    transitionDelegate.showIndicator = true
                    transitionDelegate.swipeToDismissEnabled = true
                    transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                    transitionDelegate.storkDelegate = self
                    self.present(currentViewController, animated: true, completion: nil)
                }  else if(currentObjTitle == "add gameplay stats"){
                    let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
                    currentViewController.extra = "stats"
                    
                    let transitionDelegate = SPStorkTransitioningDelegate()
                    currentViewController.transitioningDelegate = transitionDelegate
                    currentViewController.modalPresentationStyle = .custom
                    currentViewController.modalPresentationCapturesStatusBarAppearance = true
                    transitionDelegate.showIndicator = true
                    transitionDelegate.swipeToDismissEnabled = true
                    transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                    transitionDelegate.storkDelegate = self
                    self.present(currentViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func updateMoreComplete(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.blockList.contains(self.userForProfile!.uId)){
            delegate.currentLanding!.navigateToHome()
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
        self.fullProfileTable.reloadData()
        UIView.animate(withDuration: 0.5, animations: {
            self.successOverlay.alpha = 1
        }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                    self.workBlur.alpha = 0
                }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.successOverlay.alpha = 0
                    }, completion: nil)
                }
                })
            }
        })
    }
    
    func showStatsOverlay(gameName: String, game: GamerConnectGame){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        /*if(self.gamesWithStats.contains(game.gameName)){
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
                
                if(gameName == "Fortnite" || gameName == "PlayerUnknown's Battlegrounds"){
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
        } else {*/
            self.showStats = false
            self.statsOverlayCollection.alpha = 0
            
            for game in delegate.gcGames{
                if(gameName == game.gameName){
                    self.statCardBack.moa.url = game.imageUrl
                }
            }
            
            //moves the statcard out of the way
            let top = CGAffineTransform(translationX: -338, y: 0)
            UIView.animate(withDuration: 0.8, animations: {
                self.statsOverlayCollection.transform = top
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.quizTable.transform = top
                }, completion: nil)
            })
        //}
           
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
                self.quizTable.dataSource = self
                self.quizTable.delegate = self
                self.quizTable.reloadData()
                self.quizSet = true
            } else {
                self.quizTable.reloadData()
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
        
        /*if(self.gamesWithQuiz.contains(gameName) && self.gamesWithStats.contains(game.gameName)){
            self.statsSwitcher.alpha = 1
        } else {
            self.statsSwitcher.alpha = 0
        }*/
        
        let top2 = CGAffineTransform(translationX: -338, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.statsOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.statOverlayCard.transform = top2
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
                self.quizTable.transform = top
                self.quizTable.alpha = 1
                
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
            self.quizTable.transform = topReturn
            self.quizTable.alpha = 0
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
    
    @objc private func openMessaging(){
        //let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "messaging") as! MessagingFrag
        //let delegate = UIApplication.shared.delegate as! AppDelegate
        self.performSegue(withIdentifier: "messaging", sender: nil)
        //delegate.currentLanding!.navigateToMessaging(groupChannelUrl: nil, otherUserId: self.userForProfile!.uId)
        /*guard delegate.currentUser != nil else{
            return
        }
        currentViewController.currentUser = delegate.currentUser!
        currentViewController.otherUserId = self.userForProfile!.uId
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)*/
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "messaging") {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if let currentViewController = segue.destination as? MessagingFrag {
                currentViewController.currentUser = delegate.currentUser!
                currentViewController.otherUserId = self.userForProfile!.uId
            }
        }
    }
    
    private func sendPayload(){
        let manager = FriendsManager()
        manager.createRivalRequest(otherUser: self.userForProfile!, game: self.rivalSelectedGame, type: self.rivalSelectedType, callbacks: self, gamerTags: self.userForProfile!.gamerTags)
    }
    
    func updateCell() {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalResponseAccepted() {
    }
    
    func rivalResponseRejected() {
    }
    
    func rivalResponseFailed() {
    }
    
    func onlineAnnounceFail() {
    }
    
    func onlineAnnounceSent() {
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
        let manager = delegate.profileManager
        //var currentRival = RivalObj(gamerTag: "", date: "", game: "", uid: "", type: "", id: "")
        
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
                            //currentRival = rival
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
                            //currentRival = rival
                        }
                    }
                }
            }
        }
        
        manager.updateTempRivalsDB()
        
        if(!alreadyARival){
            self.rivalStatus = "available"
        }
        else if(alreadyARival){
            self.rivalStatus = "unavailable"
        }
        
        if(!dataSet){
            self.fullProfileTable.delegate = self
            self.fullProfileTable.dataSource = self
            self.dataSet = true
            self.fullProfileTable.reloadData()
            
            if(self.fullProfileTable.alpha == 0){
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.fullProfileTable.alpha = 1
                }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.hideWork()
                    }
                })
            }
        } else {
            self.fullProfileTable.reloadData()
            
            if(self.workBlur.alpha == 1){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideWork()
                }
            }
        }
    }
    
    private func checkOnlineAnnouncements(){
        if(userForProfile!.currentOnlineAnnounement != nil){
            let dbDate = self.stringToDate(userForProfile!.currentOnlineAnnounement!.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let future = formatter.string(from: dbDate as Date)
                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                
                let validAnnounments = (now as Date).compare(.isEarlier(than: dbTimeOut))
                
                if(dbTimeOut != nil){
                    if(!validAnnounments){
                        userForProfile!.currentOnlineAnnounement = nil
                        
                        let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
                        ref.child("onlineAnnouncements").removeValue()
                    }
                }
            }
        }
        
        self.announcementAvailable = (userForProfile!.currentOnlineAnnounement != nil)
        if(!dataSet){
            self.fullProfileTable.delegate = self
            self.fullProfileTable.dataSource = self
            self.dataSet = true
            self.fullProfileTable.reloadData()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.fullProfileTable.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideWork()
                }
            })
        } else {
            self.fullProfileTable.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hideWork()
            }
        }
    }
    
    private func quickCheckAndUpdate(updated: String){
        let ref = Database.database().reference().child("Users").child(userForProfile!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("twitchConnect")){
                    if(updated != "twitch"){
                        self.userForProfile?.twitchConnect = snapshot.childSnapshot(forPath: "twitchConnect").value as? String ?? ""
                    }
                }
                if(snapshot.hasChild("discordConnect")){
                    if(updated != "discord"){
                        self.userForProfile?.discordConnect = snapshot.childSnapshot(forPath: "discordConnect").value as? String ?? ""
                    }
                }
                if(snapshot.hasChild("instagramConnect")){
                    if(updated != "instagram"){
                        self.userForProfile?.instagramConnect = snapshot.childSnapshot(forPath: "instagramConnect").value as? String ?? ""
                    }
                }
            }
            DispatchQueue.main.async{
                //self.reloadEditPayload()
            }
        })
        
    }
    
    func onYoutubeFail() {
    }
    
    func onYoutubeSuccessful(videos: [YoutubeVideoObj]) {
    }
    
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection]) {
    }
    
    private func reloadUserPayload(){
        //build payload again
        let manager = GamerProfileManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        let friendsManager = FriendsManager()
        let currentUser = delegate.currentUser
        self.fullProfilePayload = [Any]()
        var consoleArray = [String]()
        for profile in self.userForProfile!.gamerTags {
            if(!consoleArray.contains(profile.console)){
                consoleArray.append(profile.console)
            }
        }
        self.fullProfilePayload.append([manager.getGamerTag(user: self.userForProfile!): consoleArray]) //header
        if(!userForProfile!.youtubeVideos.isEmpty && twitchOnlineStatus != "online"){
            self.fullProfilePayload.append(userForProfile!.youtubeVideos)
        }
        if(twitchOnlineStatus == "online"){
            self.fullProfilePayload.append("twitch")
        }
        if(!userForProfile!.userLookingFor.isEmpty){
            self.fullProfilePayload.append("looking")
        }
        self.fullProfilePayload.append(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)) // interaction buttons
        var currentBio = "this user has not created a bio, yet."
        if(!self.userForProfile!.bio.isEmpty){
            currentBio = self.userForProfile!.bio
        }
        self.fullProfilePayload.append(currentBio) //bio
        
        if(!self.userForProfile!.selectedAge.isEmpty && !self.userForProfile!.primaryLanguage.isEmpty && !self.userForProfile!.secondaryLanguage.isEmpty){
            var userInfo = [String]()
            userInfo.append(self.userForProfile!.selectedAge)
            userInfo.append(self.userForProfile!.primaryLanguage)
            userInfo.append(self.userForProfile!.secondaryLanguage)
            self.fullProfilePayload.append(userInfo)
        } //extras if needed
        if(!self.userForProfile!.badges.isEmpty){
            self.fullProfilePayload.append(self.userForProfile!.badges) //badges
        }
        self.fullProfilePayload.append(0) //game list
        if(userForProfile!.games.isEmpty){
            self.fullProfilePayload.append("empty")
            self.fullProfilePayload.append("empty")
            self.fullProfilePayload.append("empty")
        }
    }
    
    @objc private func collapseClicked(sender: CollapseGesture){
        sender.currentHeaderCell?.collapsed = true
        UIView.animate(withDuration: 0.5, animations: {
            //sender.currentHeaderCell?.gtBaseView.alpha = 0
            sender.currentHeaderCell?.gtBlurView.alpha = 0
            sender.currentHeaderCell?.consoleCollection.alpha = 0
            sender.currentHeaderCell?.videoCover.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                sender.currentHeaderCell?.videoDrawerBase.alpha = 1
                sender.currentHeaderCell?.videoDrawerBlur.alpha = 1
            }, completion: { (finished: Bool) in
               // DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               //     self.loadUserInfo(uid: self.uid)
               // }
            })
        })
    }
    
    @objc private func expandGTClicked(sender: CollapseGesture){
        sender.currentHeaderCell?.collapsed = true
        UIView.animate(withDuration: 0.5, animations: {
            sender.currentHeaderCell?.videoDrawerBase.alpha = 0
            sender.currentHeaderCell?.videoDrawerBlur.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                //sender.currentHeaderCell?.gtBaseView.alpha = 1
                sender.currentHeaderCell?.gtBlurView.alpha = 1
                sender.currentHeaderCell?.consoleCollection.alpha = 1
                sender.currentHeaderCell?.videoCover.alpha = 1
            }, completion: { (finished: Bool) in
               // DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               //     self.loadUserInfo(uid: self.uid)
               // }
            })
        })
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

extension UILabel {
    func calculateMaxLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        let linesRoundedUp = Int(ceil(textSize.height/charSize))
        return linesRoundedUp
    }
}

class TwitchAddedObject {
    var twitchId: String?
}

class InstaAddedObject {
    var instaId: String?
}

class DiscordAddedObject {
    var handle: String?
}

class EditObject {
    var title: String?
}

class PauseGesture: UITapGestureRecognizer {
    var currentHeaderCell: ProfileHeaderCell?
}

class CollapseGesture: UITapGestureRecognizer {
    var currentVideoId: String!
    var currentHeaderCell: ProfileHeaderCell?
}

class VoteGesture: UITapGestureRecognizer {
    var currentVideoId: String!
    var currentHeaderCell: ProfileHeaderCell?
    var upVote: Bool!
}

class ExpandVideosGesture: UITapGestureRecognizer {
    var currentHeaderCell: ProfileYoutubeCell?
    var expand: Bool?
}
