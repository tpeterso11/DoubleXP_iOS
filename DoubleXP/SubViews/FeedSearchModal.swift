//
//  FeedSearchModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/13/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import SPStorkController
import Lottie

class FeedSearchModal: UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate, RequestsUpdate, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var searchTable: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var gcGames: UICollectionView!
    @IBOutlet weak var emptyImg: UIImageView!
    @IBOutlet weak var emptyBlur: UIVisualEffectView!
    @IBOutlet weak var introGameSearch: UIView!
    @IBOutlet weak var favoriteGamesIntroLayout: UIView!
    @IBOutlet weak var mainSearchIntroLayout: UIView!
    @IBOutlet weak var finalSearchIntroLayout: UIView!
    @IBOutlet weak var blurDismissButton: UIButton!
    @IBOutlet weak var searchIntroOverlay: UIView!
    @IBOutlet weak var introSearchAnimation: LottieAnimationView!
    
    @IBOutlet weak var emptyActionButton: UIView!
    private var dataSet = false
    private var payload = [Any]()
    private var userGames = [GamerConnectGame]()
    var currentFeed: Feed?
    private var pastCharacterCount = 0
    private var clearActive = false
    private var gcGamesLoaded = false
    private var selectedGame: GamerConnectGame?
    
    override func viewWillAppear(_ animated: Bool) {
        self.introSearchAnimation.contentMode = .scaleAspectFill
        self.introSearchAnimation.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(currentFeed != nil){
            appDelegate.currentFeedSearchModal = self
        }
        
        let preferences = UserDefaults.standard

        let currentLevelKey = "searchIntroBlur"
        if preferences.object(forKey: currentLevelKey) == nil {
            self.showSearchIntroBlur()
        } else {
            self.searchIntroOverlay.alpha = 0
        }
        
        self.searchField.attributedPlaceholder = NSAttributedString(string: "search games or gamers",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        self.searchField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        self.searchField.attributedPlaceholder = NSAttributedString(string: "search",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(named: "darkToWhite")!])
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                view.addGestureRecognizer(tap)
        
        self.payload.append("presearch")
        setupTables()
        //self.searchTable.addTarget(self, action: #selector(dismissKeyboard), for: UIControl.Event.touchUpInside)
    }
    
    private func showSearchIntroBlur(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.mainSearchIntroLayout.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                    self.introSearchAnimation.alpha = 1
                    self.introSearchAnimation.play()
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 2.5, options: [], animations: {
                        self.mainSearchIntroLayout.alpha = 0
                        self.favoriteGamesIntroLayout.alpha = 1
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, delay: 2.5, options: [], animations: {
                            self.finalSearchIntroLayout.alpha = 1
                            self.favoriteGamesIntroLayout.alpha = 0
                        }, completion: { (finished: Bool) in
                            let backTap = UITapGestureRecognizer(target: self, action: #selector(self.hideIntroBlur))
                            self.searchIntroOverlay.isUserInteractionEnabled = true
                            self.searchIntroOverlay.addGestureRecognizer(backTap)
                            
                            self.blurDismissButton.addTarget(self, action: #selector(self.hideIntroBlur), for: .touchUpInside)
                        })
                    })
                })
            })
        }
    }
    
    private func setupTables(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for game in appDelegate.gcGames {
            if(appDelegate.currentUser!.games.contains(game.gameName)){
                self.userGames.append(game)
            }
        }
        
        if(self.userGames.isEmpty){
            if self.traitCollection.userInterfaceStyle == .dark {
                self.emptyImg.image = #imageLiteral(resourceName: "test_twitch_header.jpg")
            } else {
                self.emptyImg.image = #imageLiteral(resourceName: "discover_2.jpg")
            }
            self.emptyBlur.alpha = 1
            self.emptyImg.alpha = 1
            
            let actionTap = UITapGestureRecognizer(target: self, action: #selector(self.launchGames))
            self.emptyActionButton.isUserInteractionEnabled = true
            self.emptyActionButton.addGestureRecognizer(actionTap)
        } else {
            self.emptyImg.isUserInteractionEnabled = false
            self.emptyBlur.isUserInteractionEnabled = false
            self.emptyBlur.alpha = 0
            self.emptyImg.alpha = 0
            self.gcGames.delegate = self
            self.gcGames.dataSource = self
        }
        self.searchField.delegate = self
        self.searchTable.dataSource = self
        self.searchTable.delegate = self
        self.searchTable.reloadData()
    }
    
    @objc private func hideIntroBlur(){
        UIView.animate(withDuration: 0.5, animations: {
            self.finalSearchIntroLayout.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                self.searchIntroOverlay.alpha = 0
            }, completion: { (finished: Bool) in
                let preferences = UserDefaults.standard
                let currentLevelKey = "searchIntroBlur"
                preferences.set(true, forKey: currentLevelKey)
            })
        })
    }
    
    @objc func doClearField(){
        self.searchField.text = ""
        if(clearActive){
            self.animateToSearch()
        }
        self.payload = [Any]()
        self.payload.append("presearch")
        self.searchTable.reloadData()
        self.clearActive = false
    }
    
    @objc func textFieldDidChange(){
        if(self.searchField.text!.count >= 3){
            self.searchButton.isUserInteractionEnabled = true
            self.searchButton.alpha = 1
            self.searchButton.addTarget(self, action: #selector(doSearch), for: UIControl.Event.touchUpInside)
        } else {
            self.searchButton.alpha = 0.4
            self.searchButton.isUserInteractionEnabled = false
        }
        
        /*let currentCount = self.searchField.text?.count ?? 0
        if(currentCount < self.pastCharacterCount){
            //deleting
            if(!self.clearActive){
                animateToClear()
            }
        }
        if(currentCount > self.pastCharacterCount){
            //typing
            if(self.clearActive){
                animateToSearch()
            }
        }
        
        self.pastCharacterCount = currentCount*/
    }
    
    override func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        currentFeed?.modalDismissed()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        
        if(textField.text!.count > 3){
            self.doSearch()
        }
        return true
    }
    
    func didDismissStorkBySwipe() {
        self.searchTable.reloadData()
    }
    
    func onModalDismissed(){
        self.searchTable.reloadData()
        self.gcGames.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    @objc override func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let current = payload[exist: indexPath.item] {
            if(current is GamerConnectGame){
                let cell = tableView.dequeueReusableCell(withIdentifier: "game", for: indexPath) as! SearchGameCell
                cell.gameName.text = (current as! GamerConnectGame).gameName
                cell.developer.text = (current as! GamerConnectGame).developer
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let cache = appDelegate.imageCache
                if(cache.object(forKey: (current as! GamerConnectGame).imageUrl as NSString) != nil){
                    cell.gameImg.image = cache.object(forKey: (current as! GamerConnectGame).imageUrl as NSString)
                } else {
                    cell.gameImg.image = Utility.Image.placeholder
                    cell.gameImg.moa.onSuccess = { image in
                        cell.gameImg.image = image
                        appDelegate.imageCache.setObject(image, forKey: (current as! GamerConnectGame).imageUrl as NSString)
                        return image
                    }
                    cell.gameImg.moa.url = (current as! GamerConnectGame).imageUrl
                }
                
                cell.gameImg.contentMode = .scaleAspectFill
                cell.gameImg.clipsToBounds = true
                
                if(appDelegate.currentUser!.games.contains((current as! GamerConnectGame).gameName)){
                    cell.quickAdd.image = #imageLiteral(resourceName: "invited_check.png")
                    cell.quickAdd.isUserInteractionEnabled = false
                } else {
                    cell.quickAdd.image = #imageLiteral(resourceName: "add.png")
                    
                    let addTapGesture = SearchAddGameGesture(target: self, action: #selector(showQuickAddModal))
                    addTapGesture.position = indexPath.item
                    cell.quickAdd.addGestureRecognizer(addTapGesture)
                    cell.quickAdd.isUserInteractionEnabled = true
                }
                
                let tapGesture = SearchLaunchGameGesture(target: self, action: #selector(showGameModal))
                tapGesture.position = indexPath.item
                tapGesture.gameName = (current as? GamerConnectGame)?.gameName ?? ""
                cell.launchClickArea.addGestureRecognizer(tapGesture)
                cell.launchClickArea.isUserInteractionEnabled = true
                
                return cell
            } else if(current as? String ?? "" == "header") {
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! FeedSearchModalHeader
                return cell
            } else if(current as? String ?? "" == "presearch") {
                let cell = tableView.dequeueReusableCell(withIdentifier: "presearch", for: indexPath) as! PreSearchHeaderCell
                return cell
            } else if(current as? String ?? "" == "empty") {
                let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! FeedSearchEmptyCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! SearchCell
                cell.resultLabel.text = (current as! User).gamerTag
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let manager = FriendsManager()
                if(manager.isFollower(user: (current as! User), currentUser: appDelegate.currentUser!)){
                    cell.quickAdd.image = #imageLiteral(resourceName: "checkbox.png")
                    cell.quickAdd.isUserInteractionEnabled = false
                } else {
                    cell.quickAdd.image = UIImage(named: "quickAdd")
                    
                    if(!appDelegate.currentUser!.gamerTag.isEmpty){
                        cell.quickAdd.alpha = 1
                        
                        let tapGesture = SearchFollowGesture(target: self, action: #selector(quickFollowUser))
                        tapGesture.otherUserId = (current as! User).uId
                        tapGesture.otherUserTag = (current as! User).gamerTag
                        cell.quickAdd.addGestureRecognizer(tapGesture)
                        cell.quickAdd.isUserInteractionEnabled = true
                    } else {
                        cell.quickAdd.alpha = 0.3
                        cell.quickAdd.isUserInteractionEnabled = false
                    }
                }
                
                let tapGesture = SearchLaunchProfileGesture(target: self, action: #selector(showProfileModal))
                tapGesture.position = indexPath.item
                cell.launchClickArea.addGestureRecognizer(tapGesture)
                cell.launchClickArea.isUserInteractionEnabled = true
                return cell
            }
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
        }
    }
    
    @objc private func quickFollowUser(sender: SearchFollowGesture){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var contained = false
        for follower in appDelegate.currentUser!.followers {
            if(follower.uid == sender.otherUserId){
                contained = true
                break
            }
        }
        if(contained){
            FriendsManager().followBack(otherUserId: sender.otherUserId!, otherUserTag: sender.otherUserTag!, currentUser: appDelegate.currentUser!, callbacks: self)
        } else {
            FriendsManager().followUser(otherUserId: sender.otherUserId!, otherUserTag: sender.otherUserTag!, currentUser: appDelegate.currentUser!, callbacks: self)
        }
    }
    
    @objc private func showProfileModal(sender: SearchLaunchProfileGesture){
        let current = payload[sender.position!]
        if(current is User){
            let uid = (current as! User).uId
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.cachedTest = uid
            
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            currentViewController.editMode = false
            currentViewController.currentSearchModal = self
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
    
    @objc private func showQuickAddModal(sender: SearchAddGameGesture){
        let current = payload[sender.position!]
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "quickAddGame") as! QuickAddGameDrawer
        currentViewController.gameName = (current as! GamerConnectGame).gameName
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 650
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func showGameModal(sender: SearchLaunchGameGesture){
        let current = payload[sender.position!]
        if((current as! GamerConnectGame).availablebConsoles.count == 1){
            if((current as! GamerConnectGame).availablebConsoles[0] == "tabletop"){
                //quick create if on tabletop, all info really doesn't matter.
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
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
                        gamerTags.append(GamerProfile(gamerTag: delegate.currentUser!.gamerTag, game: (current as! GamerConnectGame).gameName, console: "tabletop", quizTaken: "false"))
                        delegate.currentUser!.gamerTags = gamerTags
                        
                        var sendUp = [[String: String]]()
                        for profile in gamerTags {
                            let newProfile = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console, "quizTaken": profile.quizTaken]
                            sendUp.append(newProfile)
                        }
                        ref.child("gamerTags").setValue(sendUp)
                    
                        if(snapshot.hasChild("games")){
                            var games = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                            if(!games.contains((current as! GamerConnectGame).gameName)){
                                games.append((current as! GamerConnectGame).gameName)
                                ref.child("games").setValue(games)
                            
                                delegate.currentUser!.games = games
                            }
                        }
                        self.searchTable.reloadData()
                    return
                })
            }
        }
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverGame") as! DiscoverGamePage
        currentViewController.game = (current as! GamerConnectGame)
        
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
    
    @objc func doSearch(){
        self.dismissKeyboard()
        //self.animateToClear()
        
        payload = [Any]()
        self.searchTable.reloadData()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let searchQuery = searchField.text
        
        for game in delegate.gcGames {
            if((game.gameName).lowercased().contains(searchQuery!.lowercased())){
                payload.append(game)
            }
        }
        
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            var containedProfile = false
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                var currentGt = ""
                let search = value?["search"] as? String ?? "true"
                var gamerTags = [GamerProfile]()
                if((user as! DataSnapshot).hasChild("gamerTags")){
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
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
            
                for tag in gamerTags {
                    if(tag.gamerTag.contains(searchQuery!)){
                        containedProfile = true
                        currentGt = tag.gamerTag
                        break
                    }
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(containedProfile && search == "true" && !currentGt.isEmpty && appDelegate.currentUser!.uId != String((user as! DataSnapshot).key)){
                    let uId = (user as! DataSnapshot).key
                    let bio = value?["bio"] as? String ?? ""
                    var onlineStatus = value?["onlineStatus"] as? String ?? ""
                    var announcementAvailable = false
                    if((user as! DataSnapshot).hasChild("onlineAnnouncements")){
                        let announcements = (user as! DataSnapshot).childSnapshot(forPath: "onlineAnnouncements")
                        for online in announcements.children
                        {
                            let current = (online as? DataSnapshot)
                            if(current != nil){
                                if(current!.hasChild("date")){
                                    let date = current!.childSnapshot(forPath: "date").value as? String ?? ""
                                    let dbDate = self.stringToDate(date)
                                    
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
                                                let ref = Database.database().reference().child("Users").child((user as! DataSnapshot).key)
                                                ref.child("onlineAnnouncements").child((online as! DataSnapshot).key).removeValue()
                                            } else {
                                                announcementAvailable = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(announcementAvailable){
                        onlineStatus = "gaming right NOW!"
                    }
                    
                    let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                    
                    var followers = [FriendObject]()
                    if((user as! DataSnapshot).hasChild("followers")){
                        let currentlyFollowing = (user as! DataSnapshot).childSnapshot(forPath: "followers")
                        for friend in currentlyFollowing.children{
                            let currentObj = friend as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                            followers.append(newFriend)
                        }
                    }
                    
                    var following = [FriendObject]()
                    if((user as! DataSnapshot).hasChild("following")){
                        let currentlyFollowing = (user as! DataSnapshot).childSnapshot(forPath: "following")
                        for friend in currentlyFollowing.children{
                            let currentObj = friend as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                            following.append(newFriend)
                        }
                    }
                    
                    var friends = [FriendObject]()
                    let friendsArray = (user as! DataSnapshot).childSnapshot(forPath: "friends")
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
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
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
                    
                    let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                    let dict = consoleArray.value as? [String: Bool]
                    let nintendo = dict?["nintendo"] ?? false
                    let ps = dict?["ps"] ?? false
                    let xbox = dict?["xbox"] ?? false
                    let pc = dict?["pc"] ?? false
                    
                    let returnedUser = User(uId: uId)
                    returnedUser.gamerTags = gamerTags
                    returnedUser.games = games
                    returnedUser.friends = friends
                    returnedUser.sentRequests = sentRequests
                    returnedUser.gamerTag = currentGt
                    returnedUser.pc = pc
                    returnedUser.ps = ps
                    returnedUser.xbox = xbox
                    returnedUser.nintendo = nintendo
                    returnedUser.bio = bio
                    returnedUser.onlineStatus = onlineStatus
                    returnedUser.following = following
                    returnedUser.followers = followers
                    
                    if(self.payload.isEmpty){
                        self.payload.append("header")
                    }
                    self.payload.append(returnedUser)
                }
            }
            
            if(self.payload.isEmpty){
                self.payload.append("empty")
            }
            self.searchTable.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = payload[indexPath.item]
        if(current as? String ?? "" == "empty" || current as? String ?? "" == "presearch") {
            return CGFloat(150)
        } else {
            return CGFloat(100)
        }
    }
    
    func updateCell() {
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalRequestSuccess() {
    }
    
    func rivalRequestFail() {
    }
    
    func rivalResponseAccepted() {
    }
    
    func rivalResponseRejected() {
    }
    
    func rivalResponseFailed() {
    }
    
    func friendRemoved() {
    }
    
    func friendRemoveFail() {
    }
    
    func onlineAnnounceSent() {
    }
    
    func onlineAnnounceFail() {
    }
    
    func onFollowSuccess() {
        self.searchTable.reloadData()
    }
    
    func onFollowBackSuccess() {
        self.searchTable.reloadData()
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.userGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
        
        let game = self.userGames[indexPath.item]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: game.imageUrl as NSString) != nil){
            cell.backgroundImage.image = cache.object(forKey: game.imageUrl as NSString)
        } else {
            cell.backgroundImage.image = Utility.Image.placeholder
            cell.backgroundImage.moa.onSuccess = { image in
                cell.backgroundImage.image = image
                appDelegate.imageCache.setObject(image, forKey: game.imageUrl as NSString)
                return image
            }
            cell.backgroundImage.moa.url = game.imageUrl
        }
        cell.backgroundImage.contentMode = .scaleAspectFill
        cell.backgroundImage.clipsToBounds = true
        
        cell.hook.text = game.hook
        
        if(game.mobileGame == "true"){
            cell.mobile.alpha = 1
        } else {
            cell.mobile.alpha = 0
        }
        
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
        
        let singleTap = FeedSearchGameGesture(target: self, action: #selector(test))
        singleTap.game = self.userGames[indexPath.item]
        cell.backgroundImage.isUserInteractionEnabled = true
        cell.backgroundImage.addGestureRecognizer(singleTap)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 230
        
        return CGSize(width: collectionView.bounds.size.width - 20, height: collectionView.bounds.size.height)
    }
    
    
    func navigateToSearch(game: GamerConnectGame){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToSearch(game: game)
    }
    
    @objc private func test(sender: FeedSearchGameGesture){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        currentViewController.game = sender.game!
        
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
    
    @objc private func launchGames(){
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
    }
    
    private func animateToClear(){
        self.clearActive = true
        self.searchButton.addTarget(self, action: #selector(doClearField), for: UIControl.Event.touchUpInside)
        UIView.animate(withDuration: 1.0, delay: 0.0, animations: {
            self.searchButton.backgroundColor = #colorLiteral(red: 0.3333052099, green: 0.3333491981, blue: 0.3332902789, alpha: 1)
            self.searchButton.setTitle("clear", for: .normal)
            }, completion:nil)
    }
    
    private func animateToSearch(){
        self.clearActive = false
        UIView.animate(withDuration: 1.0, delay: 0.0, animations: {
            self.searchButton.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
            self.searchButton.setTitle("search", for: .normal)
            }, completion:nil)
    }
}

class SearchLaunchProfileGesture: UITapGestureRecognizer {
    var position: Int?
}

class SearchLaunchGameGesture: UITapGestureRecognizer {
    var position: Int?
    var gameName: String?
}

class SearchAddGameGesture: UITapGestureRecognizer {
    var position: Int?
}

class SearchFollowGesture: UITapGestureRecognizer {
    var otherUserId: String?
    var otherUserTag: String?
}

class FeedSearchGameGesture: UITapGestureRecognizer {
    var game: GamerConnectGame?
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
