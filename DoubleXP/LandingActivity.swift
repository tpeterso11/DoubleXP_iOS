//
//  LandingActivity.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftHTTP
import ImageLoader
import SwiftNotificationCenter
import FBSDKCoreKit
import GiphyUISDK
import GiphyCoreSDK
import moa
import Firebase
import Lottie

typealias Runnable = () -> ()

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

protocol Profile {
    func goToProfile()
}

class LandingActivity: ParentVC, EMPageViewControllerDelegate, NavigateToProfile, SearchCallbacks, LandingMenuCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    @IBOutlet weak var gifButton: UIImageView!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var teamButton: UIImageView!
    @IBOutlet weak var homeButton: UIImageView!
    @IBOutlet weak var requestButton: UIImageView!
    @IBOutlet weak var bottomNav: UIView!
    @IBOutlet weak var mainNavView: UIView!
    @IBOutlet weak var secondaryNv: UIView!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var requests: UIImageView!
    @IBOutlet weak var connect: UIImageView!
    @IBOutlet weak var team: UIImageView!
    @IBOutlet weak var bottomNavBack: UIImageView!
    @IBOutlet weak var bottomNavSearch: UITextField!
    @IBOutlet weak var primaryBack: UIImageView!
    @IBOutlet weak var searchButton: UIButton!
    var mainNavShowing = false
    var bannerShowing = false
    //@IBOutlet weak var newNav: UIView!
    
    @IBOutlet weak var alertSubjectStatus: UILabel!
    @IBOutlet weak var alertSubject: UILabel!
    @IBOutlet weak var alertBarFriendLayout: UIView!
    @IBOutlet weak var alertBarAnimation: AnimationView!
    @IBOutlet weak var alertBar: UIView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var mediaButton: UIImageView!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var menuCollection: UICollectionView!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var menuButton: UIImageView!
    @IBOutlet weak var menuVie: AnimatingView!
    @IBOutlet weak var mainNavCollection: UICollectionView!
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
    
    var newTeam: TeamObject?
    var newFriend: FriendObject?
    
    @IBOutlet weak var notificationDrawer: UIView!
    
    var bottomNavHeight = CGFloat()
    
    private var giphyKey = "KCFi8XVyX2VzniYepciJJnEPUc8H4Hpk"
    let giphy = GiphyViewController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableButtons()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding = self
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        bottomNavBack.isUserInteractionEnabled = true
        bottomNavBack.addGestureRecognizer(singleTap)
        
        let singleTap2 = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        primaryBack.isUserInteractionEnabled = true
        primaryBack.addGestureRecognizer(singleTap2)
        
        stackDepth = appDelegate.navStack.count
        
        Giphy.configure(apiKey: giphyKey)
        giphy.layout = .waterfall
        giphy.mediaTypeConfig = [.gifs, .emoji]
        giphy.rating = .ratedPG13
        giphy.renditionType = .fixedWidth
        giphy.shouldLocalizeSearch = false
        giphy.showConfirmationScreen = true
        GiphyViewController.trayHeightMultiplier = 0.7
        
        if (self.traitCollection.userInterfaceStyle == .dark) {
            giphy.theme = .dark
        }
        else{
            giphy.theme = .light
        }
        
        giphy.delegate = self
        
        self.constraint = NSLayoutConstraint(item: self.secondaryNv, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 0)
        self.constraint?.isActive = true
        
        menuVie.alpha = 1.0
        menuVie.layer.shadowColor = UIColor.black.cgColor
        menuVie.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        menuVie.layer.shadowRadius = 2.0
        menuVie.layer.shadowOpacity = 0.5
        menuVie.layer.masksToBounds = false
        menuVie.layer.shadowPath = UIBezierPath(roundedRect: menuVie.bounds, cornerRadius: menuVie.layer.cornerRadius).cgPath
        
        logOut.layer.shadowColor = UIColor.black.cgColor
        logOut.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        logOut.layer.shadowRadius = 2.0
        logOut.layer.shadowOpacity = 0.5
        logOut.layer.masksToBounds = false
        logOut.layer.shadowPath = UIBezierPath(roundedRect: logOut.bounds, cornerRadius: logOut.layer.cornerRadius).cgPath
        
        bottomNavSearch.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingChanged)
        //bottomNavSearch.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingChanged)
        bottomNavSearch.delegate = self
        bottomNavSearch.returnKeyType = .done
        
        bottomNavHeight = self.bottomNav.bounds.height
        
        logOut.addTarget(self, action: #selector(logout), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDisappear),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let gifTap = UITapGestureRecognizer(target: self, action: #selector(gifClicked))
        gifButton.isUserInteractionEnabled = true
        gifButton.addGestureRecognizer(gifTap)
        
        //self.view.bringSubviewToFront(self.giphy)
        Broadcaster.register(LandingMenuCallbacks.self, observer: self)
        
        addFriendsRef()
        addPendingFriendsRef()
        addMessagingRef()
        addTeamRequestRef()
        addTeamsRef()
    
        appDelegate.handleToken()
    
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) {
            let test = ["gamerTag": "SUCCESSFUL!!!!!!!", "uid": "Test", "date": "date"]
            let ref = Database.database().reference().child("Users").child("")
            ref.child("friends").setValue(test)
        }*/
        
        /*let allNewChildrenRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        allNewChildrenRef.observe(.childAdded, with: { (snapshot) in
            if(appDelegate.currentUser!.pendingRequests.isEmpty && snapshot.hasChild("pending_requests")){
                let child = snapshot.childSnapshot(forPath: "pending_requests")
                
                var pendingRequests = [FriendRequestObject]()
                
                for friend in child.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    pendingRequests.append(newFriend)
                }
                
                if(!pendingRequests.isEmpty && appDelegate.currentUser!.pendingRequests.count < pendingRequests.count){
                    appDelegate.currentUser?.pendingRequests = pendingRequests
                    
                    let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.navigateToRequests))
                    self.showAlert(alertText: "you have a new friend request!", tap: drawerTap)
                }
            }
        })*/
        
        
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let current = ["gamerTag": "test", "date": "today", "uid": "123"] as [String : String]
            
            newMessageRef.setValue([current])
        }*/
    }
    
    private func showAlert(alertText: String, tap: UITapGestureRecognizer){
        if(self.bannerShowing){
            //skip.
        }
        else{
            self.bannerShowing = true
            self.notificationLabel.text = alertText
            
            self.notificationDrawer.isUserInteractionEnabled = true
            self.notificationDrawer.addGestureRecognizer(tap)
            
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
            
            let top = CGAffineTransform(translationX: 0, y: -130)
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
    
    private func addTeamsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let newTeamsRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("teams")
            newTeamsRef.observe(.value, with: { (snapshot) in
                var teams = [TeamObject]()
                for teamObj in snapshot.children {
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
                        let uid = dict?["uid"] as? String ?? ""
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
                
                let currentUser = appDelegate.currentUser
                
                var alreadyTeams = [TeamObject]()
                alreadyTeams.append(contentsOf: currentUser!.teams)
                
                for alreadyTeam in alreadyTeams{
                    for newTeam in teams{
                        if(alreadyTeam.teamId == newTeam.teamId){
                            teams.remove(at: teams.index(of: newTeam)!)
                        }
                    }
                }
                
                
                if(!teams.isEmpty){
                    for team in teams{
                        if(team.teamCaptainId == currentUser!.uId){
                            teams.remove(at: teams.index(of: team)!)
                        }
                    }
                    
                    if(teams.count > 1){
                        let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.navigateToTeams))
                        self.showAlert(alertText: "you've just joined some new teams!", tap: drawerTap)
                    }
                    else if(teams.count == 1){
                        self.newTeam = teams[0]
                        self.launchAlertBar(view: "team", team: self.newTeam, friend: nil)
                    }
                }
            })
    }
    
    private func addFriendsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
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
                        
                        let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                        friends.append(newFriend)
                    }
                }
                
                if(friends.count > appDelegate.currentUser!.friends.count){
                    var currentFriends = [FriendObject]()
                    currentFriends.append(contentsOf: appDelegate.currentUser!.friends)
                    
                    appDelegate.currentUser!.friends = friends
                    
                    for newFriend in friends{
                        for oldFriend in currentFriends{
                            if(newFriend.uid == oldFriend.uid){
                                friends.remove(at: friends.index(of: newFriend)!)
                            }
                        }
                    }
                    
                    if(!friends.isEmpty){
                        if(friends.count > 1){
                            let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.navigateToTeams))
                            self.showAlert(alertText: "hey buddy, you got some new friends.", tap: drawerTap)
                        }
                        else if(friends.count == 1){
                            self.newFriend = friends[0]
                            self.launchAlertBar(view: "friend", team: nil, friend: self.newFriend)
                        }
                    }
                }
            })
    }
    
    private func launchAlertBar(view: String, team: TeamObject?, friend: FriendObject?){
        switch(view){
            case "team":
                self.newTeam = team
                self.alertSubject.text = self.newTeam?.teamName
                self.alertSubjectStatus.text = "just added you to the team!"
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
                
                if(team != nil){
                    self.newTeam = nil
                }
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
    
    private func addTeamRequestRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let newRequestRef = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId).child("inviteRequests")
            newRequestRef.observe(.value, with: { (snapshot) in
                var requests = [RequestObject]()
                 for invite in snapshot.children{
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
                     
                     requests.append(newRequest)
                }
                
                let currentUser = appDelegate.currentUser!
                
                if(currentUser.teamInviteRequests.count < requests.count){
                    currentUser.teamInviteRequests = requests
                    
                    if(!requests.isEmpty){
                        let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.navigateToRequests))
                        self.showAlert(alertText: "someone wants to join your team!", tap: drawerTap)
                    }
                }
            })
    }
    
    private func addPendingFriendsRef(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
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
                
                let drawerTap = UITapGestureRecognizer(target: self, action: #selector(self.navigateToRequests))
                self.showAlert(alertText: "you have a new friend request!", tap: drawerTap)
            }
        })
    }
    
    @objc func searchClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing Search Clicked"))
        if(!bottomNavSearch.text!.isEmpty){
            Broadcaster.notify(SearchCallbacks.self) {
                $0.searchSubmitted(searchString: bottomNavSearch.text!)
            }
            
            bottomNavSearch.text = ""
            self.view!.endEditing(true)
        }
    }
    
    @objc func gifClicked(_ sender: AnyObject?) {
        present(giphy, animated: true, completion: nil)
    }
    
    @objc func sendMessage(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Messaging - Send Message"))
        var count = 0
        if(!bottomNavSearch.text!.isEmpty && count < 1){
            count += 1
            Broadcaster.notify(SearchCallbacks.self) {
                $0.messageTextSubmitted(string: bottomNavSearch.text!, list: nil)
            }
            
            bottomNavSearch.text = ""
            self.view!.endEditing(true)
        }
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(menuVie.viewShowing){
            dismissMenu()
        }
        else if(appDelegate.currentMediaFrag != nil){
            if(appDelegate.currentMediaFrag!.articleOpen){
                appDelegate.currentMediaFrag!.closeOverlay()
                appDelegate.currentMediaFrag = nil
            }
            else if(appDelegate.currentMediaFrag!.channelOpen){
                appDelegate.currentMediaFrag!.closeChannel()
                appDelegate.currentMediaFrag = nil
            }
            else{
                var stack = appDelegate.navStack
                stackDepth -= 1
                
                if self.stackDepth >= 0 && self.stackDepth < stack.count {
                    let current = Array(stack)[self.stackDepth].value
                    let key = Array(stack)[self.stackDepth - 1].value
                    
                    if(stack.count > 0 && key != nil){
                        Broadcaster.notify(NavigateToProfile.self) {
                            $0.programmaticallyLoad(vc: key, fragName: key.pageName!)
                            updateNavigation(currentFrag: key)
                        }
                        
                        if(stack.count > 1){
                            stack.removeValue(forKey: current.pageName!)
                            appDelegate.navStack = stack
                        }
                        
                        if(stack.count == 1){
                            restoreBottomNav()
                        }
                    }
                }
            }
        }
        else{
            var stack = appDelegate.navStack
            stackDepth -= 1
            
            
            if self.stackDepth >= 0 && self.stackDepth < stack.count {
                let current = Array(stack)[self.stackDepth].value
                let key = Array(stack)[self.stackDepth - 1].value
                
                if(stack.count > 0 && key != nil){
                    Broadcaster.notify(NavigateToProfile.self) {
                        $0.programmaticallyLoad(vc: key, fragName: key.pageName!)
                    }
                    
                    if(stack.count > 1){
                        stack.removeValue(forKey: current.pageName!)
                        appDelegate.navStack = stack
                    }
                    
                    if(stack.count == 1){
                        restoreBottomNav()
                    }
                }
                else{
                    Broadcaster.notify(NavigateToProfile.self) {
                        $0.navigateToHome()
                    }
                }
            }
            else{
                navigateToHome()
            }
        }
    }
    
    @objc func navigateToProfile(uid: String){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Profile"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToProfile(uid: uid)
        }
    }
    
    @objc func navigateToRequests(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Requests"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToRequests()
        }
    }
    
    func navigateToHome(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To GamerConnect"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToHome()
        }
    }
    
    @objc func navigateToTeams() {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Teams"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeams()
        }
    }
    
    func navigateToInvite() {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Invite"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToInvite()
        }
    }
    
    func navigateToSearch(game: GamerConnectGame){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Search"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToSearch(game: game)
        }
    }
    
    func navigateToCompetition(competition: CompetitionObj) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Competition"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToCompetition(competition: competition)
        }
    }
    
    @objc func navigateToCurrentUserProfile() {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Current User Profile"))
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.restoreBottomNav()
                }, completion: { (finished: Bool) in
                    Broadcaster.notify(NavigateToProfile.self) {
                        $0.navigateToCurrentUserProfile()
                    }
                })
            })
        })
    }
    
    func navigateToCreateFrag() {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Create Team"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToCreateFrag()
        }
    }
    
    @objc func navigateToSettings() {
        dismissMenu()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Settings"))
            Broadcaster.notify(NavigateToProfile.self) {
                $0.navigateToSettings()
            }
        }
    }
    
    @objc func navigateToTeamDashboard(team: TeamObject?, newTeam: Bool) {
        var currentTeam = team
        
        if(currentTeam == nil){
            currentTeam = self.newTeam
        }
        
        if(currentTeam != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Dashboard"))
            Broadcaster.notify(NavigateToProfile.self) {
                $0.navigateToTeamDashboard(team: currentTeam!, newTeam: newTeam)
            }
        }
    }
    
    func navigateToTeamNeeds(team: TeamObject) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Needs"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamNeeds(team: team)
        }
    }
    
    func navigateToTeamBuild(team: TeamObject) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Team Build"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamBuild(team: team)
        }
    }
    
    func navigateToMedia() {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Media"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToMedia()
        }
    }
    
    func navigateToTeamFreeAgentSearch(team: TeamObject){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Search"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamFreeAgentSearch(team: team)
        }
    }
    
    func navigateToTeamFreeAgentResults(team: TeamObject){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Results"))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamFreeAgentResults(team: team)
        }
    }
    
    func navigateToTeamFreeAgentDash(){
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Dash"))
       Broadcaster.notify(NavigateToProfile.self) {
           $0.navigateToTeamFreeAgentDash()
       }
    }
    
    func navigateToTeamFreeAgentFront(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz Front"))
       Broadcaster.notify(NavigateToProfile.self) {
           $0.navigateToTeamFreeAgentFront()
       }
    }
    
    func navigateToFreeAgentQuiz(user: User!, team: TeamObject?, game: GamerConnectGame!) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz - " + game.gameName))
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: game, currentUser: user)
        }
    }
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Navigate To Free Agent Quiz - " + (team?.teamName ?? "")))
          Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: gcGame, currentUser: currentUser)
          }
    }
    
    @objc func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?){
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        
        var chatUrl = groupChannelUrl
        var chatOtherId = otherUserId
        
        if(groupChannelUrl == nil && otherUserId == nil){
            if(self.newTeam == nil && self.newFriend == nil){
                return
            }
    
            else{
                if(groupChannelUrl == nil && self.newTeam != nil){
                    chatUrl = self.newTeam?.teamChat
                }
                if(otherUserId == nil && self.newFriend != nil){
                    chatOtherId = self.newFriend?.uid
                }
            }
        }
        
        if(chatUrl != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Messaging Team"))
        }
        else if(chatOtherId != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - Messaging User"))
        }
    
        if(chatUrl != nil || chatOtherId != nil){
            Broadcaster.notify(NavigateToProfile.self) {
              $0.navigateToMessaging(groupChannelUrl: chatUrl, otherUserId: chatOtherId)
            }
        }
    }
    
    func menuNavigateToMessaging(uId: String) {
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing Menu - Messaging User"))
        menuVie.viewShowing = false
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                    Broadcaster.notify(NavigateToProfile.self) {
                      $0.navigateToMessaging(groupChannelUrl: nil, otherUserId: uId)
                }
            })
        })
    }
    
    func menuNavigateToProfile(uId: String){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing Menu - Friend Profile"))
        menuVie.viewShowing = false
        self.restoreBottomNav()
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.3, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        Broadcaster.notify(NavigateToProfile.self) {
                                $0.navigateToProfile(uid: uId)
                        }
                }, completion: nil)
            })
        })
    }
    
    func navigateToViewTeams(){
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing - View Teams"))
        Broadcaster.notify(NavigateToProfile.self) {
          $0.navigateToViewTeams()
        }
    }
    
    func searchSubmitted(searchString: String) {
    }
    
    func goBack(){
        Broadcaster.notify(NavigateToProfile.self) {
            $0.goBack()
        }
    }
    
    func programmaticallyLoad(vc: UIViewController, fragName: String) {
    }
    
    func updateNavigation(currentFrag: ParentVC){
        let navOptions = currentFrag.navDictionary
        
        switch(navOptions!["state"]){
            case "original":
                restoreBottomNav()
            break
            
            case "backOnly":
                removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            case "secondary":
                removeBottomNav(showNewNav: true, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            case "search":
                removeBottomNav(showNewNav: true, hideSearch: false, searchHint: navOptions!["searchHint"], searchButtonText: navOptions!["searchButton"], isMessaging: false)
            break
            
            case "messaging":
                removeBottomNav(showNewNav: true, hideSearch: false, searchHint: navOptions!["searchHint"], searchButtonText: navOptions!["searchButton"], isMessaging: true)
            break
            
            case "none":
                removeBottomNav(showNewNav: true, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            default:
                removeBottomNav(showNewNav: false, hideSearch: false, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
        }
    }
    
    
    func removeBottomNav(showNewNav: Bool, hideSearch: Bool, searchHint: String?, searchButtonText: String?, isMessaging: Bool){
        if(showNewNav){
            //show bottom nav WITH textfield. (Messaging Uses this first method)
            if(!bottomNavSearch.isHidden && !hideSearch){
                bottomNavSearch.isHidden = false
                
                if(searchButtonText != nil){
                    searchButton.setTitle(searchButtonText, for: .normal)
                }
                
                if(searchHint != nil){
                    bottomNavSearch.attributedPlaceholder = NSAttributedString(string: searchHint!,
                                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor(named:"dark") ?? UIColor.darkGray])
                }
                else{
                    bottomNavSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor(named:"dark")  ?? UIColor.darkGray])
                }
                
                if(isMessaging){
                    searchButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
                    self.gifButton.isHidden = false
                }
                else{
                    searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
                    self.gifButton.isHidden = true
                }
                
                if(!backButtonShowing && !hideSearch){
                    primaryBack.slideInBottomSmall()
                    backButtonShowing = true
                }
                
                UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                    self.constraint?.constant = self.bottomNav.bounds.height + 60
                    
                    UIView.animate(withDuration: 0.5) {
                        //self.articleOverlay.alpha = 1
                        //self.view.bringSubviewToFront(self.secondaryNv)
                        self.view.layoutIfNeeded()
                        
                        self.isSecondaryNavShowing = true
                    }
                
                }, completion: nil)
            }
            /*else{
                //search is not showing and we want to show it
                if(bottomNavSearch.isHidden && hideSearch == false){
                    bottomNavSearch.isHidden = false
                    bottomNavSearch.slideInBottomReset()
                    
                    //apply title to search button and bring it in.
                    if(searchButtonText != nil){
                        searchButton.setTitle(searchButtonText, for: .normal)
                    }
                    searchButton.slideInBottomReset()
                    
                    if(isMessaging){
                        searchButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
                    }
                    else{
                        searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
                    }
                }
                //if search is already showing
                else if(!bottomNavSearch.isHidden && hideSearch == false){
                    if(searchButtonText != nil){
                        searchButton.setTitle(searchButtonText, for: .normal)
                    }
                    searchButton.slideInBottomReset()
                    
                    if(isMessaging){
                        searchButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
                    }
                    else{
                        searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
                    }
                }
                else{
                    bottomNavSearch.isHidden = hideSearch
                    searchShowing = hideSearch
                }
            }
            
            if(searchHint != nil){
                bottomNavSearch.placeholder = searchHint
            }
            else{
                bottomNavSearch.placeholder = "Search"
            }
            
            //if(!backButtonShowing){
            //    secondaryNv.slideInBottom()
            //    secondaryNv.isHidden = false
            //}
            
            isSecondaryNavShowing = true*/
        }
        else if(isSecondaryNavShowing){
            if(isSecondaryNavShowing){
                UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                    self.constraint?.constant = 0
                    
                    UIView.animate(withDuration: 0.5) {
                        //self.articleOverlay.alpha = 1
                        //self.view.bringSubviewToFront(self.secondaryNv)
                        self.view.layoutIfNeeded()
                        
                        self.isSecondaryNavShowing = false
                    }
                
                }, completion: nil)
            }
        }
        else{
            if(isSecondaryNavShowing){
                secondaryNv.slideOutBottomSecond()
            }
            isSecondaryNavShowing = false
            
            //if(hideSearch && searchShowing){
            //    bottomNavSearch.slideOutBottom()
            //    searchButton.slideOutBottom()
            //}
            //else if(!hideSearch && !searchShowing){
            //    bottomNavSearch.isHidden = false
            //    searchButton.isHidden = false
                
            //    searchShowing = true
            //}
            
            if(!mainNavShowing){
                mainNavView.slideInBottomNav()
                mainNavShowing = true
            }
            
            if(!backButtonShowing){
                primaryBack.slideInBottomSmall()
                backButtonShowing = true
            }
        }
    }
    
    func restoreBottomNav(){
        if(isSecondaryNavShowing == true){
            UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                self.constraint?.constant = 0
                
                UIView.animate(withDuration: 0.5) {
                    //self.articleOverlay.alpha = 1
                    //self.view.bringSubviewToFront(self.secondaryNv)
                    self.view.layoutIfNeeded()
                    
                    self.isSecondaryNavShowing = false
                }
            
            }, completion: nil)
        }
        else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if(appDelegate.currentFrag == "Home"){
                primaryBack.slideOutBottomSmall()
                backButtonShowing = false
            }
        }
    }
    
    
    private func enableButtons(){
        let singleTapTeam = UITapGestureRecognizer(target: self, action: #selector(teamButtonClicked))
        team.isUserInteractionEnabled = true
        team.addGestureRecognizer(singleTapTeam)
        
        let singleTapHome = UITapGestureRecognizer(target: self, action: #selector(homeButtonClicked))
        connect.isUserInteractionEnabled = true
        connect.addGestureRecognizer(singleTapHome)
        
        let singleTapRequests = UITapGestureRecognizer(target: self, action: #selector(requestButtonClicked))
        requests.isUserInteractionEnabled = true
        requests.addGestureRecognizer(singleTapRequests)
        
        let singleTapMenu = UITapGestureRecognizer(target: self, action: #selector(menuButtonClicked))
        menuButton.isUserInteractionEnabled = true
        menuButton.addGestureRecognizer(singleTapMenu)
        
        let singleTapMedia = UITapGestureRecognizer(target: self, action: #selector(mediaButtonClicked))
        mediaButton.isUserInteractionEnabled = true
        mediaButton.addGestureRecognizer(singleTapMedia)
        
        bottomNav.isHidden = false
        bottomNav.isUserInteractionEnabled = true
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
        
        updateNavColor(color: .darkGray)
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
        
        updateNavColor(color: .darkGray)
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
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func requestButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentFrag != "Requests"){
            navigateToRequests()
            requestsAdded = true
            homeAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = false
        }
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func menuButtonClicked(_ sender: AnyObject?) {
        if(!menuVie.viewShowing){
            figureMenu()
            
            removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            
            self.menuCollection.dataSource = self
            self.menuCollection.delegate = self
            
            let top = CGAffineTransform(translationX: 249, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0.0, options:[], animations: {
                self.blur.alpha = 1.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                    self.menuVie.transform = top
                    
                    let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
                    self.clickArea.isUserInteractionEnabled = true
                    self.clickArea.addGestureRecognizer(backTap)
                }, completion: nil)
            })
            
            self.blur.isUserInteractionEnabled = true
            menuVie.viewShowing = true
        }
    }
    
    func figureMenu(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        
        self.menuItems.append(0)
        self.menuItems.append("Friends")
        self.menuItems.append(1)
        self.menuItems.append(2)
        
        if let flowLayout = menuCollection?.collectionViewLayout as? UICollectionViewFlowLayout {
           flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    @objc func dismissMenu(){
        menuVie.viewShowing = false
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.2, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
                self.blur.isUserInteractionEnabled = false
                self.restoreBottomNav()
            }, completion: nil)
        })
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func updateNavColor(color: UIColor) {
        UIView.transition(with: self.bottomNav, duration: 0.3, options: .curveEaseInOut, animations: {
            self.bottomNav.backgroundColor = color
            self.mainNavView.backgroundColor = color
        }, completion: nil)
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
    
    @objc func keyboardWillDisappear() {
        if(isSecondaryNavShowing){
            if(self.messagingDeckHeight != nil){
                restoreBottom(height: self.messagingDeckHeight!)
            }
        }
    }
    
    func extendBottom(height: CGFloat){
        let top = CGAffineTransform(translationX: 0, y: 50)
        UIView.animate(withDuration: 0.3, animations: {
            self.searchButton.alpha = 1
            self.bottomNavSearch.transform = top
            
            self.messagingDeckHeight = height + 120
            self.constraint?.constant = self.messagingDeckHeight!
            
            UIView.animate(withDuration: 0.5) {
                //self.articleOverlay.alpha = 1
                //self.view.bringSubviewToFront(self.secondaryNv)
                self.view.layoutIfNeeded()
            }
        
        }, completion: nil)
    }
    
    func restoreBottom(height: CGFloat){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.3, animations: {
            self.searchButton.alpha = 0
            self.bottomNavSearch.transform = top
            self.constraint?.constant = self.bottomNav.bounds.height + 60
            
            UIView.animate(withDuration: 0.5) {
                //self.articleOverlay.alpha = 1
                //self.view.sendSubviewToBack(self.secondaryNv)
                self.view.layoutIfNeeded()
            }
        
        }, completion: nil)
    }
    
    func navigateToMessagingFromMenu(uId: String){
        self.bottomNavHeight = self.bottomNav.bounds.height + 60
        navigateToMessaging(groupChannelUrl: nil, otherUserId: uId)
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
        let current = menuItems[indexPath.item]
        if(current is Int){
            if((current as! Int) ==  1){
                menuVie.viewShowing = false
                
                let top = CGAffineTransform(translationX: -249, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
                    self.menuVie.transform = top
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.blur.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Landing Menu - Messaging User"))
                    
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        self.navigateToProfile(uid: delegate.currentUser!.uId)
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
    
}

extension LandingActivity: GiphyDelegate {
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
}

extension Array {
    func getElement(at index: Int) -> Element? {
        let isValidIndex = index >= 0 && index < count
        return isValidIndex ? self[index] : nil
    }
}
