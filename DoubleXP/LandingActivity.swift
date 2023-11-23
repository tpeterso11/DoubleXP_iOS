//
//  LandingActivity.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftHTTP
import SwiftNotificationCenter
import FBSDKCoreKit
import moa
import Firebase
import Lottie
import PopupDialog
//import GiphyUISDK
//import GiphyCoreSDK
import SPStorkController

typealias Runnable = () -> ()

protocol Profile {
    func goToProfile()
}

class LandingActivity: ParentVC, EMPageViewControllerDelegate, SearchCallbacks, LandingMenuCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, SPStorkControllerDelegate, TodayCallbacks {
    
    @IBOutlet weak var deleteAccount: UIButton!
    @IBOutlet weak var moreClickArea: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var scoob: LottieAnimationView!
    @IBOutlet weak var universalLoading: UIVisualEffectView!
    @IBOutlet weak var scoobSub: UIView!
    @IBOutlet weak var scoobCancel: UIButton!
    @IBOutlet weak var scoobText: UILabel!
    @IBOutlet weak var dismissHead: UILabel!
    @IBOutlet weak var dismissBody: UILabel!
    @IBOutlet weak var newMenuBlur: UIView!
    @IBOutlet weak var menuDrawer: UIVisualEffectView!
    @IBOutlet weak var searchClickArea: UIView!
    @IBOutlet weak var welcomeBlur: UIVisualEffectView!
    @IBOutlet weak var welcomeBlurDismiss: UIButton!
    var menuShowing = false
    var mainNavShowing = false
    var bannerShowing = false
    var met = false
    var resultsUserUid: String? = nil
    //@IBOutlet weak var newNav: UIView!
    
    @IBOutlet weak var bottomNav: UIVisualEffectView!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var myProfileClickArea: UIView!
    @IBOutlet weak var postsClickArea: UIView!
    @IBOutlet weak var alertSubjectStatus: UILabel!
    @IBOutlet weak var alertSubject: UILabel!
    @IBOutlet weak var alertBarFriendLayout: UIView!
    @IBOutlet weak var alertBarAnimation: LottieAnimationView!
    @IBOutlet weak var alertBar: UIView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var menuCollection: UICollectionView!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var menuVie: AnimatingView!
    @IBOutlet weak var mainNavCollection: UICollectionView!
    @IBOutlet weak var simpleLoading: UIVisualEffectView!
    @IBOutlet weak var simpleLoadingAnimation: LottieAnimationView!
    
    @IBOutlet weak var profileBlur: UIVisualEffectView!
    @IBOutlet weak var welcomeAnimation: LottieAnimationView!
    @IBOutlet weak var welcomeHeader: UILabel!
    @IBOutlet weak var headerDivider: UIView!
    @IBOutlet weak var feedHeader: UILabel!
    @IBOutlet weak var welcomeSub: UILabel!
    @IBOutlet weak var introMenuView: UIView!
    @IBOutlet weak var introFeedView: UIView!
    private var requestsAdded = false
    private var teamFragAdded = false
    private var profileAdded = false
    private var homeAdded = true
    private var mediaAdded = false
    private var isSecondaryNavShowing = false
    var stackDepth = 0
    var searchShowing = true
    var backButtonShowing = false
    var menuItems = [Any]()
    var constraint : NSLayoutConstraint?
    var messagingDeckHeight: CGFloat?
    var newConstraint: NSLayoutConstraint?
    var navHeightConstraint: NSLayoutConstraint?
    
    var newFriend: FriendObject?
    
    @IBOutlet weak var notificationDrawer: UIView!
    
    var bottomNavHeight = CGFloat()
    
    private var giphyKey = "KCFi8XVyX2VzniYepciJJnEPUc8H4Hpk"
    //let giphy = GiphyViewController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableButtons()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding = self
        appDelegate.registerUserOnlineStatus()
        
        if self.traitCollection.userInterfaceStyle == .dark {
            self.bottomNav.effect = UIBlurEffect(style: .dark)
        } else {
            self.bottomNav.effect = UIBlurEffect(style: .regular)
        }
        
        let preferences = UserDefaults.standard

        let currentLevelKey = "welcomeBlur"
        if preferences.object(forKey: currentLevelKey) == nil {
            self.showWelcomeBlur()
        } else {
            self.welcomeBlur.alpha = 0
        }
        
        menuDrawer.alpha = 1.0
        
        bottomNavHeight = self.bottomNav.bounds.height
        
        logOut.addTarget(self, action: #selector(logout), for: .touchUpInside)
        deleteAccount.addTarget(self, action: #selector(deleteAccountClicked), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        self.bottomNav.layer.shadowColor = UIColor.black.cgColor
        self.bottomNav.layer.shadowOffset = CGSize(width: self.bottomNav.bounds.width, height: 3)
        self.bottomNav.layer.shadowRadius = 15.0
        self.bottomNav.layer.shadowOpacity = 0.8
        self.bottomNav.layer.masksToBounds = false
        self.bottomNav.layer.shadowPath = UIBezierPath(roundedRect: self.bottomNav.bounds, cornerRadius: self.bottomNav.layer.cornerRadius).cgPath
    
        Broadcaster.register(LandingMenuCallbacks.self, observer: self)
        
        addFriendsRef()
        addPendingFriendsRef()
        addMessagingRef()
        addRivalsRef()
        addAcceptedRivalsRef()
        addRejectedRivalsRef()
        addFollowersRef()
        addBadgesRef()
        addGamesRef()
        addReceivedAnnouncementsRef()
    
        appDelegate.handleToken()
        
        setupScoob()
        
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        if(!appDelegate.currentUser!.dailyCheck.isEmpty){
            let currentCheck = self.stringToDate(appDelegate.currentUser!.dailyCheck)
            var dayComponent    = DateComponents()
            dayComponent.day    = 1
            let theCalendar     = Calendar.current
            let nextDate        = theCalendar.date(byAdding: dayComponent, to: currentCheck)
            if(nextDate != nil){
                if(nextDate!.isTomorrow){
                    appDelegate.recommendedUsersManager.getCachedUsers(uid: appDelegate.currentUser!.uId, callbacks: self)
                } else {
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    let result = formatter.string(from: date)
                    
                    ref.child("dailyCheck").setValue(result)
                    
                    appDelegate.recommendedUsersManager.getRecommendedUsers(cachedViewedUids: appDelegate.currentUser!.cachedRecommendedUids, callbacks: self)
                }
            }
        } else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            let result = formatter.string(from: date)
            
            ref.child("dailyCheck").setValue(result)
        
            appDelegate.recommendedUsersManager.getRecommendedUsers(cachedViewedUids: appDelegate.currentUser!.cachedRecommendedUids, callbacks: self)
        }
    }
    
    func onSuccess() {
    }
    
    func onSuccessShort() {
    }
    
    func onRecommendedUsersLoaded() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFeedFrag?.todayRecommendedUsersLoaded()
    }
    
    func playSimpleLandingAnimation(){
        self.simpleLoadingAnimation.play()
    }
    
    private func showWelcomeBlur(){
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.welcomeBlur.alpha = 1
        }, completion: { (finished: Bool) in
            self.welcomeAnimation.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.welcomeHeader.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 1.0, delay: 0.0, options: [], animations: {
                        self.headerDivider.alpha = 1
                        self.welcomeAnimation.alpha = 0
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
                            self.welcomeSub.alpha = 1
                        }, completion: { (finished: Bool) in
                            UIView.animate(withDuration: 0.3, delay: 0.8, options: [], animations: {
                                self.feedHeader.alpha = 1
                            }, completion: { (finished: Bool) in
                                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                                    self.introFeedView.alpha = 1
                                }, completion: { (finished: Bool) in
                                    UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                                        self.introMenuView.alpha = 1
                                        self.welcomeBlurDismiss.alpha = 1
                                    }, completion: { (finished: Bool) in
                                        
                                    })
                                })
                            })
                        })
                    })
                })
            }
        })
    
        let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissWelcomeBlur))
        self.welcomeBlur.isUserInteractionEnabled = true
        self.welcomeBlur.addGestureRecognizer(backTap)
        
        self.welcomeBlurDismiss.addTarget(self, action: #selector(self.dismissWelcomeBlur), for: .touchUpInside)
    }
    
    private func showAlert(alertText: String, tap: UITapGestureRecognizer?){
        if(self.bannerShowing){
            //skip.
        }
        else{
            self.bannerShowing = true
            self.notificationLabel.text = alertText
            
            if(tap != nil){
                self.notificationDrawer.isUserInteractionEnabled = true
                self.notificationDrawer.addGestureRecognizer(tap!)
            }
            
            let top = CGAffineTransform(translationX: 0, y: -160)
            UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
                self.notificationDrawer.transform = top
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    let down = CGAffineTransform(translationX: 0, y: 0)
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.notificationDrawer.transform = down
                    }, completion: { (finished: Bool) in
                        self.bannerShowing = false
                        self.notificationDrawer.isUserInteractionEnabled = false
                    })
                }
            })
        }
    }
    
    private func showMessageAlertQueue(array: [MeesageQueueObj]){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(!array.isEmpty && appDelegate.currentUser!.notifications == "true"){
            var mutable = [MeesageQueueObj]()
            mutable.append(contentsOf: array)
            
            let current = mutable[0]
            self.bannerShowing = true
            self.notificationLabel.text = "you have a new message."
            
            let top = CGAffineTransform(translationX: 0, y: -160)
            UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
                self.notificationDrawer.transform = top
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    let down = CGAffineTransform(translationX: 0, y: 0)
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.notificationDrawer.transform = down
                    }, completion: { (finished: Bool) in
                        self.notificationDrawer.isUserInteractionEnabled = false
                        
                        mutable.remove(at: 0)
                        
                        let messageQueue = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("messagingNotifications")
                        
                        var upList = [[String: String]]()
                        for message in mutable{
                            let newMessage = ["senderId": message.senderId]
                            upList.append(newMessage)
                        }
                        
                        messageQueue.setValue(upList)
                        
                        if(!array.isEmpty){
                            self.showMessageAlertQueue(array: mutable)
                        }
                    })
                }
            })
        }
        else{
            let messageQueue = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("messagingNotifications")
            
            var upList = [[String: String]]()
            messageQueue.setValue(upList)
        }
    }
    
    @objc private func dismissWelcomeBlur(){
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.welcomeBlur.alpha = 0
        }, completion: { (finished: Bool) in
            let preferences = UserDefaults.standard
            let currentLevelKey = "welcomeBlur"
            preferences.set(true, forKey: currentLevelKey)
        })
    }
    
    private func addGamesRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
        let newTeamsRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("games")
            newTeamsRef.observe(.value, with: { (snapshot) in
                if(snapshot.exists()){
                    var games = snapshot.value as? [String] ?? [String]()
                    let user = appDelegate.currentUser
                    if(games.count > appDelegate.currentUser!.games.count){
                        appDelegate.currentUser!.games = games
                        appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                    }
                }
            })
        }
    }
    
    private func addUpcomingGamesRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let upcomingGamesRef = Database.database().reference().child("Upcoming Games")
                upcomingGamesRef.observe(.value, with: { (snapshot) in
                    if(snapshot.exists()){
                    var upcoming = [UpcomingGame]()
                    for upGame in snapshot.children {
                        var game = ""
                        var trailerUrls = [String: String]()
                        var gameImageUrl = ""
                        var blurb = ""
                        var releaseDate = ""
                        var id = ""
                        var developer = ""
                        var releaseDateMillis = ""
                        var description = ""
                        var releaseDateProper = ""
                        
                        let current = upGame as! DataSnapshot
                        id = current.key
                        
                        if(current.hasChild("trailerUrls")){
                            trailerUrls = current.childSnapshot(forPath: "trailerUrls").value as? [String: String] ?? [String: String]()
                        }
                        
                        if(current.hasChild("game")){
                            game = current.childSnapshot(forPath: "game").value as! String
                        }
                        
                        if(current.hasChild("gameImageXXHDPI")){
                            gameImageUrl = current.childSnapshot(forPath: "gameImageXXHDPI").value as! String
                        }
                        
                        if(current.hasChild("blurb")){
                            blurb = current.childSnapshot(forPath: "blurb").value as! String
                        }
                        
                        if(current.hasChild("releaseDate")){
                            releaseDate = current.childSnapshot(forPath: "releaseDate").value as! String
                        }
                        
                        if(current.hasChild("releaseDateMillis")){
                            releaseDateMillis = current.childSnapshot(forPath: "releaseDateMillis").value as! String
                        }
                        
                        if(current.hasChild("developer")){
                            developer = current.childSnapshot(forPath: "developer").value as! String
                        }
                        
                        if(current.hasChild("description")){
                            description = current.childSnapshot(forPath: "description").value as! String
                        }
                        
                        if(current.hasChild("releaseDateProp")){
                            releaseDateProper = current.childSnapshot(forPath: "releaseDateProp").value as! String
                        }
                        
                        if(!game.isEmpty && !gameImageUrl.isEmpty && !developer.isEmpty){
                            let upcomingGame = UpcomingGame(id: id, game: game, blurb: blurb, releaseDateMillis: releaseDateMillis, releaseDate: releaseDate, trailerUrls: trailerUrls, gameImageUrl: gameImageUrl, gameDesc: description, releaseDateProper: releaseDateProper)
                            
                            upcoming.append(upcomingGame)
                        }
                    }
                    
                    if(!upcoming.isEmpty){
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.upcomingGames.append(contentsOf: upcoming)
                        
                        if(upcoming.count > delegate.upcomingGames.count){
                            delegate.currentFeedFrag?.checkOnlineAnnouncements()
                        }
                    }
                }
            })
        }
    }
    
    private func addRivalsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
        let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("tempRivals")
            newFriendRef.observe(.value, with: { (snapshot) in
                var tempArray = [RivalObj]()
                for rival in snapshot.children{
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
                                    tempArray.append(request)
                                }
                            }
                        }
                    }
                }
                
                var notContained = [String]()
                for tempRival in tempArray{
                    var contained = false
                    if(appDelegate.currentUser!.tempRivals.isEmpty){
                        notContained.append(tempRival.gamerTag)
                    }
                    else{
                        for currentRival in appDelegate.currentUser!.tempRivals{
                            if(tempRival.gamerTag == currentRival.gamerTag){
                                contained = true
                            }
                            
                            if(!contained){
                                notContained.append(tempRival.gamerTag)
                            }
                        }
                    }
                }
                
                
                if(!notContained.isEmpty){
                    appDelegate.currentUser!.tempRivals = tempArray
                    let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.requestButtonClicked))
                    self.showAlert(alertText: "someone wants to play with you.", tap: drawerTap)
                    appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            })
        }
    }
    
    private func addAcceptedRivalsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("acceptedTempRivals")
            newFriendRef.observe(.value, with: { (snapshot) in
                var tempArray = [RivalObj]()
                for rival in snapshot.children{
                    let currentObj = rival as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["gamerTag"] as? String ?? ""
                    let game = dict?["game"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    let dbType = dict?["type"] as? String ?? ""
                    let id = dict?["id"] as? String ?? ""
                    
                    let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                    tempArray.append(request)
                }
                
                if(tempArray.count > appDelegate.currentUser!.acceptedTempRivals.count){
                    appDelegate.currentUser!.acceptedTempRivals = tempArray
                    self.showAlert(alertText: "play request accepted! go play!", tap: nil)
                    appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            })
        }
    }
    
    private func addFollowersRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
        let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("followerAnnouncements")
            newFriendRef.observe(.value, with: { (snapshot) in
                var followers = [FriendObject]()
                for friend in snapshot.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    if(dict != nil){
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        /*for follower in appDelegate.currentUser!.followers {
                            if(follower.uid == uid){
                                appDelegate.currentUser!.followers.remove(at: appDelegate.currentUser!.followers.index(of: follower)!)
                            }
                        }*/
                        
                        let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                        followers.append(newFriend)
                    }
                }
                
                if(followers.count > appDelegate.currentUser!.followers.count){
                    appDelegate.currentUser!.followers = followers
                    appDelegate.currentUser!.followerAnnouncements = followers
                    appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            })
        }
    }
    
    private func addBadgesRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("badges")
            newFriendRef.observe(.value, with: { (snapshot) in
                var badges = [BadgeObj]()
                let badgesArray = snapshot.childSnapshot(forPath: "badges")
                for badge in badgesArray.children{
                    let currentObj = badge as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let name = dict?["badgeName"] as? String ?? ""
                    let desc = dict?["badgeDesc"] as? String ?? ""
                    
                    let badge = BadgeObj(badge: name, badgeDesc: desc)
                    badges.append(badge)
                }
                
                appDelegate.currentUser!.badges = badges
            })
        }
    }
    
    private func addTeamInvitesRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("teamInvites")
            newFriendRef.observe(.value, with: { (snapshot) in
                var tempArray = [TeamInviteObject]()
                for invite in snapshot.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["gamerTag"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: tag, date: date, uid: uid, teamName: teamName)
                    tempArray.append(newInvite)
                }
                
                if(tempArray.count > appDelegate.currentUser!.teamInvites.count){
                    appDelegate.currentUser!.teamInvites = tempArray
                    
                    self.showAlert(alertText: "you just got invited!", tap: nil)
                }
            })
        }
    }
    
    private func addInviteRequestsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("inviteRequests")
            newFriendRef.observe(.value, with: { (snapshot) in
                var dbRequests = [RequestObject]()
                 for invite in snapshot.children{
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
                
                if(dbRequests.count > appDelegate.currentUser!.teamInviteRequests.count){
                    appDelegate.currentUser!.teamInviteRequests = dbRequests
                    
                    self.showAlert(alertText: "someone wants to join your team!", tap: nil)
                }
            })
        }
    }
    
    private func addReceivedAnnouncementsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let receivedAnnouncementsRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("receivedAnnouncements")
            receivedAnnouncementsRef.observe(.value, with: { (snapshot) in
                if(snapshot.exists()){
                    var received = snapshot.value as? [String] ?? [String]()
                    if(!received.isEmpty){
                        if(received.count > appDelegate.currentUser!.receivedAnnouncements.count){
                            appDelegate.currentUser!.receivedAnnouncements = received
                            let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.showAlertsDrawer))
                            self.showAlert(alertText: "one of your friends is jumping online right NOW!", tap: drawerTap)
                            appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                        }
                        appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                    }
                }
            })
        }
    }
    
    @objc private func showAlertsDrawer(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFeedFrag?.alertsClicked()
    }
    
    private func addRejectedRivalsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("rejectedTempRivals")
            newFriendRef.observe(.value, with: { (snapshot) in
                var tempArray = [RivalObj]()
                for rival in snapshot.children{
                    let currentObj = rival as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["gamerTag"] as? String ?? ""
                    let game = dict?["game"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    let dbType = dict?["type"] as? String ?? ""
                    let id = dict?["id"] as? String ?? ""
                    
                    let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                    tempArray.append(request)
                }
                
                if(tempArray.count > appDelegate.currentUser!.rejectedTempRivals.count){
                    appDelegate.currentUser!.rejectedTempRivals = tempArray
                    let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.requestButtonClicked))
                    self.showAlert(alertText: "your friend is not available to play.", tap: drawerTap)
                    appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            })
        }
    }
    
    func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.profileManager
        let user = delegate.currentUser
        if(user != nil){
            manager.updateTempRivalsDB()
        }
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    private func addFriendsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
        let newFriendRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("friends")
            newFriendRef.observe(.value, with: { (snapshot) in
                var friends = [FriendObject]()
                for friend in snapshot.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    if(dict != nil){
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        for pendingRequest in appDelegate.currentUser!.pendingRequests {
                            if(pendingRequest.uid == uid){
                                appDelegate.currentUser!.pendingRequests.remove(at: appDelegate.currentUser!.pendingRequests.index(of: pendingRequest)!)
                            }
                        }
                        
                        let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                        friends.append(newFriend)
                    }
                }
                
                if(friends.count > appDelegate.currentUser!.friends.count){
                    appDelegate.currentUser!.friends = friends
                    
                    if(!friends.isEmpty){
                        self.newFriend = friends[0]
                        self.launchAlertBar(view: "friend", friend: self.newFriend)
                        appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                    }
                }
            })
        }
    }
    
    private func launchAlertBar(view: String, friend: FriendObject?){
        switch(view){
            case "team":
                self.alertSubject.text = "it happened"
                self.alertSubjectStatus.text = "you just got added to a team!"
            break
            case "friend":
                self.newFriend = friend
                self.alertSubject.text = self.newFriend?.gamerTag
                self.alertSubjectStatus.text = "just added you as a friend!"
            break
            default: return
        }
        
        let top = CGAffineTransform(translationX: 0, y: 270)
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.alertBar.transform = top
        }, completion: { (finished: Bool) in
            self.alertBarAnimation.loopMode = .repeat(3)
            self.alertBarAnimation.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self.dismissAlertBar()
                
                if(friend != nil){
                    self.newFriend = nil
                }
            }
        })
    }
    
    @objc private func dismissAlertBar(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.alertBar.transform = top
        }, completion: nil)
    }
    
    private func addMessagingRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
        let newMessageRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("messagingNotifications")
            newMessageRef.observe(.value, with: { (snapshot) in
                var messageArray = [MeesageQueueObj]()
                for message in snapshot.children{
                    let currentObj = message as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let senderId = dict?["senderId"] as? String ?? ""
                    
                    let messageObj = MeesageQueueObj(senderId: senderId, type: "user")
                    messageArray.append( messageObj)
                }
                
                if(!messageArray.isEmpty){
                    self.showMessageAlertQueue(array: messageArray)
                }
            })
        }
    }
    
    private func addTeamRequestRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let newRequestRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("inviteRequests")
            newRequestRef.observe(.value, with: { (snapshot) in
                var dbRequests = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for user in teamInviteRequests.children{
                    for invite in (user as! DataSnapshot).children {
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
                
                let currentUser = appDelegate.currentUser!
                
                if(currentUser.teamInviteRequests.count < dbRequests.count){
                    currentUser.teamInviteRequests = dbRequests
                    
                    if(!dbRequests.isEmpty){
                        let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.requestButtonClicked))
                        self.showAlert(alertText: "someone wants to join your team!", tap: drawerTap)
                    }
                }
            })
    }
    
    private func addPendingFriendsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        if(user != nil){
            let pendingFriendsRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("pending_friends")
            pendingFriendsRef.observe(.value, with: { (snapshot) in
                var pendingRequests = [FriendRequestObject]()
                
                for friend in snapshot.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    pendingRequests.append(newFriend)
                }
                
                if(!pendingRequests.isEmpty && appDelegate.currentUser!.pendingRequests.count < pendingRequests.count){
                    appDelegate.currentUser?.pendingRequests = pendingRequests
                    
                    let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.requestButtonClicked))
                    self.showAlert(alertText: "you have a new friend request!", tap: drawerTap)
                    appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            })
        }
    }
    
    @objc func navigateToProfile(uid: String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedTest = uid
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.editMode = appDelegate.currentUser!.uId == uid
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func navigateToSponsor() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Sponsor"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToSponsor()
        }
    }
    
    @objc func navigateToRequests(){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Requests"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToRequests()
        }
    }
    
    func navigateToHome(){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To GamerConnect"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToHome()
        }
    }
    
    @objc func navigateToTeams() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Teams"))
    }
    
    func navigateToInvite() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Invite"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToInvite()
        }
    }
    
    func navigateToSearch(game: GamerConnectGame){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Search"))
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        currentViewController.game = game
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
        //Broadcaster.notify(NavigateToProfile.self) {
        //    $0.navigateToSearch(game: game)
        //}
    }
    
    func navigateToSearchFromDiscover(game: GamerConnectGame){
        //delay for modal dismiss
        let delegate = UIApplication.shared.delegate as! AppDelegate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if(delegate.currentDiscoverCat != nil){
                delegate.currentDiscoverCat!.dismiss(animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    delegate.currentDiscoverFrag!.dismiss(animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Search"))
                        Broadcaster.notify(NavigateToProfile.self) {
                            $0.navigateToSearch(game: game)
                        }
                    }
                }
            }
        }
    }
    
    @objc func launchVideoMessage(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "videoMessage") as! VideoMessage
        //currentViewController.newsObj = newsObj
        //currentViewController.selectedImage = image
        
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
    
    func navigateToCompetition(competition: CompetitionObj) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Competition"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToCompetition(competition: competition)
        }
    }
    
    @objc func navigateToCurrentUserProfile() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Current User Profile"))
        self.menuShowing = false
        let top = CGAffineTransform(translationX: -320, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuDrawer.transform = top
            self.clickArea.isUserInteractionEnabled = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
            }, completion: { (finished: Bool) in
                let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
                let transitionDelegate = SPStorkTransitioningDelegate()
                currentViewController.transitioningDelegate = transitionDelegate
                currentViewController.modalPresentationStyle = .custom
                currentViewController.modalPresentationCapturesStatusBarAppearance = true
                transitionDelegate.showIndicator = true
                transitionDelegate.swipeToDismissEnabled = true
                transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                transitionDelegate.storkDelegate = self
                self.present(currentViewController, animated: true, completion: nil)
            })
        })
    }
    
    func navigateToCreateFrag() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Create Team"))
    }
    
    @objc func navigateToSettings() {
        self.menuShowing = false
        let top = CGAffineTransform(translationX: -320, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuDrawer.transform = top
            self.clickArea.isUserInteractionEnabled = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Settings"))
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "settings") as! SettingsFrag
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        
                        guard delegate.currentUser != nil else{
                            return
                        }
                        
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = false
                        transitionDelegate.customHeight = 520
                        transitionDelegate.showCloseButton = true
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                    }
                })
            })
        })
    }
    
    @objc func startDashNavigation(teamName: String?, teamInvite: TeamInviteObject?, newTeam: Bool) {
        if(teamInvite != nil){
            loadTeam(teamName: teamInvite!.teamName, newTeam: newTeam)
        }
        
        loadTeam(teamName: teamName, newTeam: newTeam)
    }
    
    @objc func navigateToTeamDashboard(team: TeamObject?, teamInvite: TeamInviteObject?, newTeam: Bool) {
        if(team != nil){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Dashboard"))
        }
    }
    
    func navigateToAlerts(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "alerts") as! AlertsDrawer
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = false
        transitionDelegate.customHeight = 500
        transitionDelegate.showCloseButton = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    private func loadTeam(teamName: String?, newTeam: Bool) {
        if(teamName != nil && !teamName!.isEmpty){
            let teamsRef = Database.database().reference().child("Teams").child(teamName!)
            teamsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = delegate.currentUser
                    
                    let dict = snapshot.value as? [String: Any]
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
                        let inviteTeamName = dict?["teamName"] as? String ?? ""
                        
                        let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: inviteTeamName)
                        invites.append(newInvite)
                    }
                    
                    let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let captain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? ""
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let captainId = dict?["teamCaptainId"] as? String ?? ""
                    
                    let currentTeam = TeamObject(teamName: teamName!, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId, isRequest: "true")
                    
                    var teammateArray = [TeammateObject]()
                    if(snapshot.hasChild("teammates")){
                        let teammates = snapshot.childSnapshot(forPath: "teammates")
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
                    }
                    
                    self.navigateToTeamDashboard(team: currentTeam, teamInvite: nil, newTeam: newTeam)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func navigateToTeamNeeds(team: TeamObject) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Needs"))
        
    }
    
    func navigateToTeamBuild(team: TeamObject) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Build"))
        
    }
    
    func navigateToMedia() {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Media"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToMedia()
        }
    }
    
    func navigateToTeamFreeAgentSearch(team: TeamObject){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Search"))
        
    }
    
    func navigateToTeamFreeAgentResults(team: TeamObject){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Results"))
        
    }
    
    func navigateToTeamFreeAgentDash(){
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Dash"))
       
    }
    
    func navigateToTeamFreeAgentFront(){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz Front"))
       
    }
    
    func navigateToFreeAgentQuiz(user: User!, team: TeamObject?, game: GamerConnectGame!) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz - " + game.gameName))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: game, currentUser: user)
        }
    }
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz - " + (team?.teamName ?? "")))
          Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: gcGame, currentUser: currentUser)
          }
    }
    
    @objc func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.cachedUidForMessaging = otherUserId ?? ""
        
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        
        let chatUrl = groupChannelUrl
        var chatOtherId = otherUserId
        
        if(groupChannelUrl == nil && otherUserId == nil){
            if(self.newFriend == nil){
                return
            }
    
            else{
                if(otherUserId == nil && self.newFriend != nil){
                    chatOtherId = self.newFriend?.uid
                }
            }
        }
        
        if(chatUrl != nil){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Messaging Team"))
        }
        else if(chatOtherId != nil){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Messaging User"))
        }
    
        if(chatUrl != nil || chatOtherId != nil){
            self.performSegue(withIdentifier: "messaging", sender: nil)
            //self.popMessagingModal(groupChannelUrl: chatUrl, otherUserId: chatOtherId)
        }
    }
    
    func menuNavigateToMessaging(uId: String) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.cachedUidForMessaging = uId
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Messaging User"))
        self.menuShowing = false
        
        let top = CGAffineTransform(translationX: -320, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuDrawer.transform = top
            self.clickArea.isUserInteractionEnabled = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
            }, completion: { (finished: Bool) in
                self.performSegue(withIdentifier: "messaging", sender: nil)
                //self.popMessagingModal(groupChannelUrl: nil, otherUserId: uId)
            })
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    func menuNavigateToProfile(uId: String){
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Friend Profile"))
        self.menuShowing = false
        
        let top = CGAffineTransform(translationX: -320, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.3, options:[], animations: {
            self.menuDrawer.transform = top
            self.clickArea.isUserInteractionEnabled = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.navigateToProfile(uid: uId)
                }, completion: nil)
            })
        })
    }
    
    func navigateToViewTeams(){
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - View Teams"))
       
    }
    
    func searchSubmitted(searchString: String) {
    }
    
    func goBack(){
        Broadcaster.notify(NavigateToProfile.self) {
            $0.goBack()
        }
    }
    
    func showScoob(cancelableWV: WKWebView?){
        resetDismissScoob()
        setupScoobCancel(cancelableWV: cancelableWV)
        
        let top = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.5, animations: {
            self.universalLoading.alpha = 1
            self.scoobSub.transform = top
            self.scoobSub.alpha = 1
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                self.showDismissScoob()
            }
        }, completion: nil)
        
        scoob.loopMode = .loop
        scoob.play()
    }
    
    func setupScoobCancel(cancelableWV: WKWebView?) {
        if(cancelableWV != nil){
            cancelableWV?.stopLoading()
            cancelableWV?.loadHTMLString("", baseURL: nil)
        } else {
            hideScoob()
        }
    }
    
    func showDismissScoob(){
        let top3 = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.5, animations: {
            self.scoobCancel.transform = top3
            self.dismissHead.transform = top3
            self.dismissBody.transform = top3
            self.scoobCancel.alpha = 1
            self.dismissHead.alpha = 1
            self.dismissBody.alpha = 1
        }, completion: nil)
    }
    
    func resetDismissScoob(){
        let top3 = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.01, animations: {
            self.scoobCancel.transform = top3
            self.dismissHead.transform = top3
            self.dismissBody.transform = top3
            self.scoobCancel.alpha = 0
            self.dismissHead.alpha = 0
            self.dismissBody.alpha = 0
        }, completion: nil)
    }
    
    func setupScoob(){
        scoobSub.layer.cornerRadius = 10.0
        scoobSub.layer.borderWidth = 1.0
        scoobSub.layer.borderColor = UIColor.clear.cgColor
        scoobSub.layer.masksToBounds = true
        
        scoobSub.layer.shadowColor = UIColor.black.cgColor
        scoobSub.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        scoobSub.layer.shadowRadius = 2.0
        scoobSub.layer.shadowOpacity = 0.5
        scoobSub.layer.masksToBounds = false
        scoobSub.layer.shadowPath = UIBezierPath(roundedRect: scoobSub.layer.bounds, cornerRadius: scoobSub.layer.cornerRadius).cgPath
        
        scoobCancel.layer.shadowColor = UIColor.black.cgColor
        scoobCancel.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        scoobCancel.layer.shadowRadius = 2.0
        scoobCancel.layer.shadowOpacity = 0.5
        scoobCancel.layer.masksToBounds = false
        scoobCancel.layer.shadowPath = UIBezierPath(roundedRect: scoobCancel.bounds, cornerRadius: scoobCancel.layer.cornerRadius).cgPath
        //add more scoob layouts
        // -- like one that is like  (ACTUAL CONTROLLER SYMBOLS ->) " triangle triangle back forward" and then below have "Sub Zero's ice move" somethin like that. We can create a small library of these to pop up throughout the app whenever the loading screen shows.
   
        scoobCancel.addTarget(self, action: #selector(hideScoob), for: .touchUpInside)
    }
    
    
    @objc func hideScoob(){
        if(self.universalLoading.alpha == 1){
            let top = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.5, animations: {
                self.universalLoading.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                    self.scoobSub.transform = top
                    self.scoobSub.alpha = 0
                    self.resetDismissScoob()
                    
                    self.scoob.stop()
                }, completion: nil)
            })
        }
    }
    
    
    
    func programmaticallyLoad(vc: UIViewController, fragName: String) {
    }
    
    
    private func enableButtons(){
        let singleTapRequests = UITapGestureRecognizer(target: self, action: #selector(launchVideoMessage))
        self.postsClickArea.isUserInteractionEnabled = true
        self.postsClickArea.addGestureRecognizer(singleTapRequests)
        
        let singleTapMenu = UITapGestureRecognizer(target: self, action: #selector(menuButtonClicked))
        self.moreClickArea.isUserInteractionEnabled = true
        self.moreClickArea.addGestureRecognizer(singleTapMenu)
        
        let singleTapProfile = UITapGestureRecognizer(target: self, action: #selector(profileButtonClicked))
        self.myProfileClickArea.isUserInteractionEnabled = true
        self.myProfileClickArea.addGestureRecognizer(singleTapProfile)
        
        let singleTapSearch = UITapGestureRecognizer(target: self, action: #selector(searchButtonClicked))
        self.searchClickArea.isUserInteractionEnabled = true
        self.searchClickArea.addGestureRecognizer(singleTapSearch)
        
        bottomNav.isHidden = false
        bottomNav.isUserInteractionEnabled = true
    }
    
    func hideLoading(){
        UIView.animate(withDuration: 0.8, animations: {
             self.simpleLoading.alpha = 0
        }, completion: { (finished: Bool) in
            self.simpleLoadingAnimation.pause()
        })
    }
    
    @objc private func twitchClicked(){
        /*let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        currentViewController.pageName = "Media"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFrag = currentViewController.pageName ?? "Media"
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)*/
        //self.presentAsStork(controller)
        //self.performSegue(withIdentifier: "twitch", sender: nil)
    }
    
    func navigateToTwitchFromDiscover(gameName: String){
        /*let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        currentViewController.pageName = "Media"
        currentViewController.navDictionary = ["state": "backOnly"]
        currentViewController.discoverGameName = gameName
        
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
    
    @objc func didDismissStorkBySwipe(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
    }
    
    @objc func popularButtonClicked(_ sender: AnyObject?) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "popular") as! PopularPage
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
    
    @objc func profileButtonClicked(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.cachedTest = delegate.currentUser!.uId
        self.performSegue(withIdentifier: "profile", sender: nil)
    }
    
    @objc func searchButtonClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "feedSearch") as! FeedSearchModal
        //currentViewController.currentFeed = self
        
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
    
    @objc func homeButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentFrag != "Home"){
            navigateToHome()
            homeAdded = true
            requestsAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = false
        }
    }
    
    @objc func mediaButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentFrag != "Media"){
            navigateToMedia()
            homeAdded = false
            requestsAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = true
        }
    }
    
    @objc func teamButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentFrag != "Teams"){
            navigateToTeams()
            teamFragAdded = true
            homeAdded = false
            requestsAdded = false
            profileAdded = false
            mediaAdded = false
        }
    }
    
    @objc func requestButtonClicked(_ sender: AnyObject?) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "requests") as! Requests
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.customHeight = 500
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
        //self.performSegue(withIdentifier: "requests", sender: nil)
    }
    
    @objc func playButtonClicked(_ sender: AnyObject?) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playModal") as! PlayModal
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
        //self.performSegue(withIdentifier: "requests", sender: nil)
    }
    
    @objc func menuButtonClicked(_ sender: AnyObject?) {
        if(!self.menuShowing){
            figureMenu()
            
            //removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            
            self.menuCollection.dataSource = self
            self.menuCollection.delegate = self
            
            let top = CGAffineTransform(translationX: 332, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0.0, options:[], animations: {
                self.newMenuBlur.alpha = 1.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                    self.menuDrawer.transform = top
                    
                    let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
                    self.clickArea.isUserInteractionEnabled = true
                    self.clickArea.addGestureRecognizer(backTap)
                }, completion: nil)
            })
            
            self.newMenuBlur.isUserInteractionEnabled = true
            self.menuShowing = true
        }
    }
    
    func figureMenu(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        
        self.menuItems.append(0)
        //self.menuItems.append(1)
        self.menuItems.append(4)
        self.menuItems.append(5)
        self.menuItems.append("friends")
        self.menuItems.append(2)
        
        if let flowLayout = menuCollection?.collectionViewLayout as? UICollectionViewFlowLayout {
           flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    @objc func dismissMenu(){
        self.menuShowing = false
        
        let top = CGAffineTransform(translationX: -332, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.2, options:[], animations: {
            self.menuDrawer.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
                self.newMenuBlur.isUserInteractionEnabled = false
                self.clickArea.isUserInteractionEnabled = false
                //self.restoreBottomNav()
            }, completion: nil)
        })
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { // became first responder

        //move textfields up
        let myScreenRect: CGRect = UIScreen.main.bounds
        let keyboardHeight : CGFloat = 500

        UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
        var needToMove: CGFloat = 0

        var frame : CGRect = self.view.frame
        if (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height + */UIApplication.shared.statusBarFrame.size.height > (myScreenRect.size.height - keyboardHeight)) {
            needToMove = (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height +*/ UIApplication.shared.statusBarFrame.size.height) - (myScreenRect.size.height - keyboardHeight);
        }

        frame.origin.y = -needToMove
        self.view.frame = frame
        UIView.commitAnimations()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
            //move textfields back down
            UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
            var frame : CGRect = self.view.frame
            frame.origin.y = 0
            self.view.frame = frame
            UIView.commitAnimations()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if(isSecondaryNavShowing){
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                
                extendBottom(height: keyboardHeight)
            }
        }
    }
    
    func extendBottom(height: CGFloat){
        //let top = CGAffineTransform(translationX: 0, y: 50)
        UIView.animate(withDuration: 0.3, animations: {
            //self.searchButton.alpha = 1
            //self.bottomNavSearch.transform = top
            
            self.messagingDeckHeight = height + 120
            self.constraint?.constant = self.messagingDeckHeight!
            
            UIView.animate(withDuration: 0.5) {
                //self.articleOverlay.alpha = 1
                //self.view.bringSubviewToFront(self.secondaryNv)
                self.view.layoutIfNeeded()
            }
        
        }, completion: nil)
    }
    
    func navigateToMessagingFromMenu(uId: String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedUidForMessaging = uId
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Current User Profile"))
        self.menuShowing = false
        let top = CGAffineTransform(translationX: -320, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuDrawer.transform = top
            self.clickArea.isUserInteractionEnabled = false
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.newMenuBlur.alpha = 0.0
            }, completion: { (finished: Bool) in
                self.navigateToMessaging(groupChannelUrl: nil, otherUserId: uId)
            })
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.menuItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = menuItems[indexPath.item]
        if(current is String){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "header", for: indexPath) as! MenuHeaderCell
            cell.headerText.text = current as? String
            return cell
        }
        else{
            if(current is Int){
                if(current as? Int == 0){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "settings", for: indexPath) as! MenuSettingsCell
                    cell.tag = indexPath.item
                    cell.profileButton.addTarget(self, action: #selector(navigateToCurrentUserProfile), for: .touchUpInside)
                    
                    let settingsTap = UITapGestureRecognizer(target: self, action: #selector(navigateToSettings))
                    cell.settingsButton.isUserInteractionEnabled = true
                    cell.settingsButton.addGestureRecognizer(settingsTap)
                    
                    return cell
                }
                else if(current as? Int == 1){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myProfile", for: indexPath) as! MenuMyProfileCell
                    return cell
                }
                else if(current as? Int == 2){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendsList", for: indexPath) as! MenuFriendsList
                    cell.loadContent()
                    return cell
                }
                else if(current as? Int == 3){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upgrade", for: indexPath) as! MenuUpgradeCell
                    return cell
                }
                else if(current as? Int == 4){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! NewMenuOptionCell
                    cell.optionLabel.text = "my followers"
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(!delegate.currentUser!.followers.isEmpty){
                        cell.sub.text = "view your list of followers"
                    } else {
                        cell.sub.text = "no followers yet."
                    }
                    return cell
                }
                else if(current as? Int == 5){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! NewMenuOptionCell
                    cell.optionLabel.text = "following"
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(!delegate.currentUser!.followers.isEmpty){
                        cell.sub.text = "view who you are following."
                    } else {
                        cell.sub.text = "you're not following anyone."
                    }
                    return cell
                }
                else{
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dxpFriends", for: indexPath) as! MenuFriendsCell
                    return cell
                }
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dxpFriends", for: indexPath) as! MenuFriendsCell
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.menuItems[indexPath.item]
        if(current is String){
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(50))
        }
        else{
            if(current is Int){
                if(current as? Int == 0){
                    //settings tab
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(50))
                }
                else if(current as? Int == 1){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(300))
                }
                else if(current as? Int == 2){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(400))
                }
                else if(current as? Int == 3){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
                }
                else if(current as? Int == 4){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(70))
                }
                else if(current as? Int == 5){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(70))
                }
                
                else{
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(100))
                }
            }
            else{
                return CGSize(width: collectionView.bounds.size.width, height: CGFloat(100))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let current = menuItems[indexPath.item]
        if(current is Int){
            if((current as! Int) ==  1){
                self.menuShowing = false
                
                let top = CGAffineTransform(translationX: 0, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
                    self.menuDrawer.transform = top
                    self.clickArea.isUserInteractionEnabled = false
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.newMenuBlur.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Messaging User"))
                    
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        self.navigateToProfile(uid: delegate.currentUser!.uId)
                    })
                })
            } else if((current as! Int) == 3){
                self.menuShowing = false
                
                let top = CGAffineTransform(translationX: 0, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
                    self.menuDrawer.transform = top
                    self.clickArea.isUserInteractionEnabled = false
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.newMenuBlur.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Upgrade"))
                    
                        self.performSegue(withIdentifier: "upgrade", sender: nil)
                    })
                })
            }
            else if((current as! Int) == 4 && !delegate.currentUser!.followers.isEmpty){
                self.menuShowing = false
                
                let top = CGAffineTransform(translationX: 0, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
                    self.menuDrawer.transform = top
                    self.clickArea.isUserInteractionEnabled = false
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.newMenuBlur.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Upgrade"))
                        
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "follower") as! MenuFollowerDrawer
                        currentViewController.payload = delegate.currentUser!.followers
                        currentViewController.type = "followers"
                        currentViewController.userUid = delegate.currentUser!.uId
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = true
                        transitionDelegate.customHeight = 600
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                    })
                })
            }
            else if((current as! Int) == 5 && !delegate.currentUser!.following.isEmpty){
                self.menuShowing = false
                
                let top = CGAffineTransform(translationX: 0, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
                    self.menuDrawer.transform = top
                    self.clickArea.isUserInteractionEnabled = false
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.newMenuBlur.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Landing Menu - Upgrade"))
                        
                        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "follower") as! MenuFollowerDrawer
                        currentViewController.payload = delegate.currentUser!.following
                        currentViewController.type = "following"
                        currentViewController.userUid = delegate.currentUser!.uId
                        let transitionDelegate = SPStorkTransitioningDelegate()
                        currentViewController.transitioningDelegate = transitionDelegate
                        currentViewController.modalPresentationStyle = .custom
                        currentViewController.modalPresentationCapturesStatusBarAppearance = true
                        transitionDelegate.showIndicator = true
                        transitionDelegate.customHeight = 600
                        transitionDelegate.swipeToDismissEnabled = true
                        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                        transitionDelegate.storkDelegate = self
                        self.present(currentViewController, animated: true, completion: nil)
                    })
                })
            }
        }
    }
    
    func programmaticallyLoad(vc: ParentVC, fragName: String) {
    }
    
    @objc func logout(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentUser = nil
        
        UserDefaults.standard.removeObject(forKey: "userId")
        
        self.performSegue(withIdentifier: "logout", sender: nil)
    }
    
    
    @objc func deleteAccountClicked(){
        var buttons = [PopupDialogButton]()
        let title = "delete your account."
        let message = "we really hate to see you go, are you sure you want to delete your account?"
        
        let button = DefaultButton(title: "delete my account.") { [weak self] in
            let delegate = UIApplication.shared.delegate as! AppDelegate
                    
            let ref = Database.database().reference().child("Users")
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.hasChild(delegate.currentUser!.uId)) {
                    ref.child(delegate.currentUser!.uId).removeValue()
                    delegate.currentUser = nil
                    UserDefaults.standard.removeObject(forKey: "userId")
                    
                    let user = Auth.auth().currentUser

                    user?.delete { error in
                      if let error = error {
                        // An error happened.
                      } else {
                        // Account deleted.
                      }
                    }
                }
                self!.performSegue(withIdentifier: "logout", sender: nil)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        buttons.append(button)
        
        let buttonOne = CancelButton(title: "nevermind") { [weak self] in
            
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
}

/*extension LandingActivity: GiphyDelegate {
   func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia)   {
   
        // your user tapped a GIF!
        giphyViewController.dismiss(animated: true, completion: nil)
        
        Broadcaster.notify(SearchCallbacks.self) {
            $0.messageTextSubmitted(string: "DXPGif" + media.url(rendition: .downsizedLarge, fileType: .gif)!, list: nil)
        }
   }
   
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}*/

extension Array {
    func getElement(at index: Int) -> Element? {
        let isValidIndex = index >= 0 && index < count
        return isValidIndex ? self[index] : nil
    }
}

extension Date {
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
