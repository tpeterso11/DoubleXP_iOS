//
//  GamerConnectSearch.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftNotificationCenter
import MSPeekCollectionViewDelegateImplementation
import FBSDKCoreKit
import SPStorkController
import Lottie
import SwiftLocation
import PopupDialog
import CoreLocation
import GeoFire

class GamerConnectSearch: ParentVC, SearchCallbacks, SPStorkControllerDelegate, SearchManagerCallbacks, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    var game: GamerConnectGame? = nil
    
    var returnedUsers = [Any]()
    var searchPS = false
    var searchXbox = false
    var searchNintendo = false
    var searchPC = false
    var searchMobile = false
    var set = false
    var frontSearchPayload = [Any]()
    
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    @IBOutlet weak var filterButton: LottieAnimationView!
    @IBOutlet weak var loadingBlur: UIVisualEffectView!
    @IBOutlet weak var gameHeaderImage: UIImageView!
    @IBOutlet weak var searchTable: UITableView!
    @IBOutlet weak var searchCover: UIView!
    @IBOutlet weak var searchEmpty: UIView!
    @IBOutlet weak var searchEmptyTitle: UILabel!
    @IBOutlet weak var searchEmptyMessage: UILabel!
    var basicFilterList = [filterCell]()
    var locationCell: filterCell?
    var popup: PopupDialog?
    var currentManager: SearchManager!
    var currentLocationActivationCell: FilterActivateCell?
    
    var currentUser: User!
    var locationManager: CLLocationManager?
    var req: LocationRequest?
    var currentLocationIndexPath: IndexPath?
    var usersSelectedTags = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //check rivals on entry.
        
        if(game != nil){
            //gameHeaderImage.alpha = 0
            filterButton.loopMode = .playOnce
            filterButton.play()
            
            let filterTap = UITapGestureRecognizer(target: self, action: #selector(self.showFilters))
            filterButton.isUserInteractionEnabled = true
            filterButton.addGestureRecognizer(filterTap)
        
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: game!.imageUrl as NSString) != nil){
                gameHeaderImage.image = cache.object(forKey: game!.imageUrl as NSString)
            } else {
                gameHeaderImage.moa.onSuccess = { image in
                    self.gameHeaderImage.image = image
                    appDelegate.imageCache.setObject(image, forKey: self.game!.imageUrl as NSString)
                    return image
                }
                gameHeaderImage.moa.url = game!.imageUrl
            }
            gameHeaderImage.contentMode = .scaleAspectFill
            
            let testBounds = CGRect(x: self.gameHeaderImage.bounds.minX, y: self.gameHeaderImage.bounds.minY, width: self.view.bounds.width, height: self.gameHeaderImage.bounds.height)
            
            
            let maskLayer = CAGradientLayer(layer: self.gameHeaderImage.layer)
            maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 0, y: 1)
            maskLayer.frame = testBounds
            self.gameHeaderImage.layer.mask = maskLayer
            
            searchPS = false
            searchXbox = false
            searchNintendo = false
            searchPC = false
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentGCSearchFrag = self
            currentUser = delegate.currentUser
            let manager = delegate.searchManager
            manager.currentUser = currentUser
            manager.currentGameSearch = game?.gameName ?? ""
            manager.resetFilters()
            
            Broadcaster.register(SearchCallbacks.self, observer: self)
            
            showLoading()
            checkRivals()
            FriendsManager().checkOnlineAnnouncements()
            
            //self.searchTable.estimatedRowHeight = 250
            //self.searchTable.rowHeight = UITableView.automaticDimension
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.searchUsers(userName: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.searchManager.resetFilters()
        super.viewWillDisappear(animated)
    }
    
    private func showLoading(){
        self.loadingAnimation.loopMode = .loop
        self.loadingAnimation.play()
        
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.loadingBlur.alpha = 1
        }, completion: nil)
    }
    
    private func hideLoading(){
        if(self.loadingBlur.alpha == 1){
            UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                self.loadingBlur.alpha = 0
            }, completion: { (finished: Bool) in
                
            })
        }
    }
    
    func dismissModal(){
        self.searchTable.reloadData()
    }
    
    @objc func didDismissStorkBySwipe(){
        self.searchTable.reloadData()
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.profileManager
        currentUser = delegate.currentUser
        manager.updateTempRivalsDB()
    }
    
    @objc func showFilters(_ sender: AnyObject?){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "filters") as! GCSearchFilters
        currentViewController.gcGame = self.game!
        
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
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="yyyy.MM.dd hh:mm aaa"
        return formatter.date(from: str)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.returnedUsers[indexPath.item]
        if(current is User){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserCell
            
            let manager = GamerProfileManager()
            let current = returnedUsers[indexPath.item]
            cell.gamerTag.text = manager.getGamerTag(user: (current as! User))
            
            if((current as! User).bio.isEmpty){
                cell.consoleTag.text = "No bio available."
            }
            else{
                cell.consoleTag.text = (current as! User).bio
            }
            
            if((current as! User).onlineStatus.isEmpty){
                cell.onlineStatus.alpha = 0
            } else {
                if((current as! User).onlineStatus == "online"){
                    cell.onlineStatus.alpha = 1
                    cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                    cell.onlineStatus.text = "online now!"
                } else if((current as! User).onlineStatus == "gaming right NOW!"){
                    cell.onlineStatus.alpha = 1
                    cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                    cell.onlineStatus.text = "gaming right NOW!"
                    cell.onlineStatus.font = UIFont.boldSystemFont(ofSize: cell.onlineStatus.font.pointSize)
                } else {
                    cell.onlineStatus.alpha = 0
                }
            }
            
            cell.consoleOne.alpha = 1
            
            var oneShowing = false
            var twoShowing = false
            var threeShowing = false
            var fourShowing = false
            for profile in (current as! User).gamerTags {
                if(profile.game == self.game!.gameName){
                    if(profile.console == "ps"){
                        oneShowing = true
                        cell.oneTag.text = "PS"
                    }
                    if(profile.console == "xbox"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "XBox"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "XBox"
                            twoShowing = false
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "nintendo"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "Nintendo"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "Nintendo"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "Nintendo"
                            twoShowing = false
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "pc"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "PC"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "PC"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && threeShowing && !fourShowing){
                            fourShowing = true
                            cell.consoleFour.isHidden = false
                            cell.fourTag.text = "PC"
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "PC"
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "mobile"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "Mobile"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "Mobile"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && threeShowing && !fourShowing){
                            fourShowing = true
                            cell.consoleFour.isHidden = false
                            cell.fourTag.text = "Mobile"
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "Mobile"
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                }
            }
            
            if(cell.oneTag.text == "Label"){
                cell.consoleOne.isHidden = true
            }
            
            
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! EmptyCollectionViewCell
            return cell
        }
    }
    
    private func searchUsers(userName: String?){
        if(self.searchPS){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PS, Game: " + self.game!.gameName))
        }
        if(self.searchXbox){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Search - Console: XBox, Game: " + self.game!.gameName))
        }
        if(self.searchPC){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PC, Game: " + self.game!.gameName))
        }
        if(self.searchNintendo){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Search - Console: Nintendo, Game: " + self.game!.gameName))
        }
        
        if(userName != nil){
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Search - User"))
        }
        
        if(self.loadingBlur.alpha == 0){
            self.loadingAnimation.play()
            
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                self.loadingBlur.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.searchUsers(userName: userName)
                }
            })
            return
        }
        
        self.returnedUsers = [Any]()
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                let search = value?["search"] as? String ?? "true"
                let gamerTag = value?["gamerTag"] as? String ?? ""
                
                //make users that did not enter a gamertag are not searchable
                if(search == "true" && !(gamerTag.isEmpty && gamerTag == "undefined")){
                    let games = value?["games"] as? [String] ?? [String]()
                    
                    if(games.contains(self.game!.gameName) && userName == nil){
                        let uId = (user as! DataSnapshot).key
                        let bio = value?["bio"] as? String ?? ""
                        let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                        
                        var friends = [FriendObject]()
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
                        returnedUser.gamerTag = gamerTag
                        returnedUser.pc = pc
                        returnedUser.ps = ps
                        returnedUser.xbox = xbox
                        returnedUser.nintendo = nintendo
                        returnedUser.bio = bio
                        
                        //if the returned user plays the game being searched AND the returned users gamertag
                        //does not equal the current users gamertag, then add to list.
                        let manager = FriendsManager()
                        if(returnedUser.games.contains(self.game!.gameName) && self.currentUser.uId != returnedUser.uId &&
                            !manager.isInFriendList(user: returnedUser, currentUser: self.currentUser)){
                            if(self.searchPS && returnedUser.ps){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchPC && returnedUser.pc){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchXbox && returnedUser.xbox){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchNintendo && returnedUser.nintendo){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else{
                                for profile in returnedUser.gamerTags{
                                    if(profile.game == self.game?.gameName){
                                        self.addUserToList(returnedUser: returnedUser)
                                    }
                                }
                            }
                        }
                    }
                    else if(userName != nil){
                        let trimmedUser = userName!.trimmingCharacters(in: .whitespacesAndNewlines)
                        var gamerTag = (value?["gamerTag"] as? String) ?? ""
                        if(!gamerTag.isEmpty){
                            gamerTag = gamerTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
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
                        
                        var contained = false
                        //check legacy users first
                        if(gamerTag == trimmedUser){
                            contained = true
                        }
                        
                        //if not legacy, or not found, check gamertags one more time
                        if(!contained){
                            for gamerTagObj in gamerTags{
                                if(gamerTagObj.gamerTag == trimmedUser){
                                    contained = true
                                    break
                                }
                            }
                        }
                        
                        if(contained){
                        let gamerProfileManager = GamerProfileManager()
                        
                        if(userName != nil){
                            if(!gamerTag.isEmpty && gamerTag == trimmedUser && (gamerProfileManager.getGamerTag(user: self.currentUser!) == userName)){
                                
                                let uId = (user as! DataSnapshot).key
                                let bio = value?["bio"] as? String ?? ""
                                let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                                
                                var friends = [FriendObject]()
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
                                returnedUser.gamerTag = gamerTag
                                returnedUser.pc = pc
                                returnedUser.ps = ps
                                returnedUser.xbox = xbox
                                returnedUser.nintendo = nintendo
                                returnedUser.bio = bio
                                
                                self.returnedUsers.append(returnedUser)
                            }
                        }
                    }
                }
            }
        }
        
        if(!self.set){
            self.searchTable.delegate = self
            self.searchTable.dataSource = self
            
            self.set = true
            
            if(self.returnedUsers.isEmpty){
                self.searchEmpty.alpha = 1
            } else {
                self.searchEmpty.alpha = 0
            }
            
            UIView.animate(withDuration: 0.8, animations: {
                self.searchTable.alpha = 1
                self.searchTable.reloadData()
            }, completion: { (finished: Bool) in
                self.hideLoading()
                /*UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    if(!self.returnedUsers.isEmpty){
                        self.searchEmpty.isHidden = true
                    }
                    else{
                        self.searchEmpty.isHidden = false
                        
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }, completion: nil)*/
            })
        }
        else{
            UIView.animate(withDuration: 0.8, animations: {
                self.searchTable.alpha = 1
                self.searchTable.reloadData()
                
                if(self.returnedUsers.isEmpty){
                    self.searchEmpty.alpha = 1
                } else {
                    self.searchEmpty.alpha = 0
                }
            }, completion: { (finished: Bool) in
                self.hideLoading()
                
                /*if(!self.returnedUsers.isEmpty){
                    self.searchEmpty.isHidden = true
                }
                else{
                    self.searchEmpty.isHidden = false
                    
                    if(userName != nil){
                        self.searchEmptyText.text = "No users returned with that name."
                        self.searchEmptySub.text = "No worries.\nMake sure you typed their naame correctly, and try again."
                    }
                    else{
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }*/
            })
        }
        
        }) { (error) in
            print(error.localizedDescription)
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GamerConnect Search "))
        }
    }
    
    func searchSubmitted(searchString: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.searchManager.searchForUser(searchTag: searchString, callbacks: self)
    }
    
    private func addUserToList(returnedUser: User){
        var contained = false
        let manager = GamerProfileManager()
        
        for obj in returnedUsers{
            if(obj is User){
                if((obj as! User).gamerTag == returnedUser.gamerTag){
                    contained = true
                    break
                }
            }
        }
        
        if(!contained){
            self.returnedUsers.append(returnedUser)
        }
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func onSuccess(returnedUsers: [User]) {
        if(returnedUsers.isEmpty){
            //self.searchEmpty.alpha = 1
            //self.searchEmpty.isHidden = false
            //self.searchEmptySub.text = "please change a search filter or try again later."
            self.searchEmpty.alpha = 1
            self.hideLoading()
            return
        }
        if(!set){
            self.set = true
            self.returnedUsers = returnedUsers
            self.searchTable.delegate = self
            self.searchTable.dataSource = self
            self.searchTable.reloadData()
            self.searchEmpty.alpha = 0
        
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.searchTable.alpha = 1
            }, completion: nil)
        } else {
            self.returnedUsers = returnedUsers
            self.searchEmpty.alpha = 0
            self.searchTable.reloadData()
        }
        if(self.searchTable.alpha == 0){
            UIView.animate(withDuration: 0.8, animations: {
                self.searchTable.alpha = 1
            }, completion: { (finished: Bool) in
            
            })
        }
        self.hideLoading()
    }
    
    func onFailure() {
        //self.searchEmpty.alpha = 1
        //self.searchEmptySub.text = "please change a search filter or try again later."
    }
    
    //func numberOfSections(in tableView: UITableView) -> Int {
    //    return self.basicFilterList.count
   // }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.returnedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! GamerConnectUserCell
        let manager = GamerProfileManager()
        let current = self.returnedUsers[indexPath.item] as! User
        cell.gamerTag.text = manager.getGamerTag(user: current)
        if(current.bio.isEmpty){
            cell.bioField.text = "no bio available"
        } else {
            cell.bioField.text = current.bio
        }
        
        if(!current.ps){
            cell.psLogo.alpha = 0.1
        }
        else {
            cell.psLogo.alpha = 1.0
        }
        if(!current.xbox){
            cell.xboxLogo.alpha = 0.1
        }
        else {
            cell.xboxLogo.alpha = 1.0
        }
        if(!current.pc){
            cell.pcLogo.alpha = 0.1
        }
        else {
            cell.pcLogo.alpha = 1.0
        }
        if(!current.nintendo){
            cell.nintendoLogo.alpha = 0.1
        }
        else {
            cell.nintendoLogo.alpha = 1.0
        }
        
        if(!current.primaryLanguage.isEmpty){
            cell.primaryLanguageText.isHidden = false
            cell.primaryLanguageBubble.isHidden = false
            cell.primaryLanguageText.text = current.primaryLanguage.prefix(3).capitalized
        } else {
            cell.primaryLanguageBubble.isHidden = true
            cell.primaryLanguageText.isHidden = true
        }
        
        if(!current.secondaryLanguage.isEmpty){
            cell.secondaryLanguageText.isHidden = false
            cell.secondaryLanguageBubble.isHidden = false
            cell.secondaryLanguageText.text = current.secondaryLanguage.prefix(3).capitalized
        } else {
            cell.secondaryLanguageText.isHidden = true
            cell.secondaryLanguageBubble.isHidden = true
        }
        
        if(current.onlineStatus == "online"){
            cell.onlineDot.backgroundColor = .systemGreen
            cell.onlineText.textColor = .systemGreen
            cell.onlineText.text = "online now!"
        } else {
            cell.onlineDot.backgroundColor = .darkGray
            cell.onlineText.textColor = .darkGray
            cell.onlineText.text = "idle"
        }
        return cell
    }
    
    @objc private func locationButtonTriggered(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLat != 0.0){
            self.currentLocationActivationCell?.filterSwitch.setOn(false, animated: true)
            delegate.currentUser!.userLat = 0.0
            delegate.currentUser!.userLong = 0.0
            self.sendLocationInfo()
            self.searchTable.reloadData()
        } else {
            self.currentLocationActivationCell?.filterSwitch.setOn(true, animated: true)
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            if #available(iOS 14.0, *) {
                locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
            } else {
                locationManager?.desiredAccuracy = 5000
            }
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    @objc private func distanceChosen(sender: DistanceGesture){
        self.currentManager.locationFilter = sender.tag
        self.searchTable.reloadData()
    }
    
    @objc private func quickSearch(){
        UIView.animate(withDuration: 0.5, animations: {
            self.searchTable.alpha = 0
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.searchManager.searchWithFilters(callbacks: self)
        })
    }
    
    @objc func filterSearch(){
        UIView.animate(withDuration: 0.8, animations: {
            if(self.searchEmpty.alpha == 1){
                self.searchEmpty.alpha = 0
            }
            self.searchTable.alpha = 0
            self.showLoading()
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        })
    }
    
    @objc private func headerTriggered(sender: HeaderGesture) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "filterOptionDrawer") as! FilterOptionDrawer
        currentViewController.questionText = sender.question
        currentViewController.payload = sender.payload
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 500
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func locationSwitchTriggered(sender: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLat != 0.0){
            delegate.currentUser!.userLat = 0.0
            delegate.currentUser!.userLong = 0.0
            self.sendLocationInfo()
            self.searchTable.reloadData()
        } else {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            if #available(iOS 14.0, *) {
                locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
            } else {
                locationManager?.desiredAccuracy = 5000
            }
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func updateLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        if #available(iOS 14.0, *) {
            locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            locationManager?.desiredAccuracy = 5000
        }
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            //manager.startUpdatingLocation()
            self.req = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { result in
              switch result {
                case .failure(let error):
                  debugPrint("Received error: \(error)")
                    self.popup?.dismiss()
                    self.searchTable.reloadData()
                case .success(let location):
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser!.userLat = location.coordinate.latitude
                    delegate.currentUser!.userLong = location.coordinate.longitude
                    
                    var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
                    delegate.currentUser!.timezone = localTimeZoneAbbreviation
                    
                    self.sendLocationInfo()
                    self.popup?.dismiss()
                    
                    if(self.locationCell != nil){
                        self.locationCell?.opened = true
                        self.searchTable.reloadData()
                    } else {
                        self.buildFilterList()
                    }
                    //self.searchTable.reloadData()
              }
            }
            self.req?.start()
        } else if(status == .denied){
            showLocationDialog()
        } else if(status == .notDetermined){
            //if(self.currentSelectedSender != nil){
                //locationSwitchTriggered(sender: 0)
            //}
        }
    }
    
    private func sendLocationInfo(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("userLat").setValue(delegate.currentUser!.userLat)
        ref.child("userLong").setValue(delegate.currentUser!.userLong)
        ref.child("timezone").setValue(delegate.currentUser!.timezone)
        
        if(delegate.currentUser!.userLat != 0.0){
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            geoFire.setLocation(CLLocation(latitude: delegate.currentUser!.userLat, longitude: delegate.currentUser!.userLong), forKey: delegate.currentUser!.uId)
            self.req?.stop()
        }
    }
    
    private func showLocationDialog(){
        let title = "DoubleXP needs your permission."
        let message = "we only use your location to find users near you."

        popup = PopupDialog(title: title, message: message)
        let buttonOne = CancelButton(title: "cancel.") {
            print("dang it.")
            self.searchTable.reloadData()
        }

        // This button will not the dismiss the dialog
        let buttonTwo = DefaultButton(title: "go to settings.", dismissOnTap: false) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        popup!.addButtons([buttonOne, buttonTwo])//, buttonTwo, buttonThree])
        self.present(popup!, animated: true, completion: nil)
    }
    
    private func buildFilterList(){
        self.basicFilterList = [filterCell]()
        
        var mainHeader = filterCell()
        mainHeader.header = true
        mainHeader.mainHeader = true
        mainHeader.opened = false
        mainHeader.options = [["": ""]]
        self.basicFilterList.append(mainHeader)
        
        var advancedHeader = filterCell()
        advancedHeader.header = true
        advancedHeader.title = "apply filters"
        advancedHeader.opened = false
        advancedHeader.options = [["": ""]]
        self.basicFilterList.append(advancedHeader)
        
        locationCell = filterCell()
        locationCell?.header = true
        locationCell?.title = "location"
        locationCell?.type = "activate"
        locationCell?.opened = true
        locationCell?.options = [["": ""]]
        self.basicFilterList.append(locationCell!)
        
        /*var empty = filterCell()
        empty.header = true
        empty.title = ""
        empty.options = [["": ""]]
        self.basicFilterList.append(empty)*/
        /*let english = ["english": "english"]
        let spanish = ["spanish": "spanish"]
        let french = ["french": "french"]
        let chinese = ["chinese": "chinese"]
        let languageChoices = [english, spanish, french, chinese]
        opened = !self.currentManager.langaugeFilters.isEmpty
        let language = filterCell(opened: opened, title: "language", options: languageChoices, type: "language")
        self.basicFilterList.append(language)*/
        
        if(!self.game!.filterQuestions.isEmpty){
            let baby = ["12 - 16": "12_16"]
            let young = ["17 - 24": "17_24"]
            let mid = ["25 - 31": "25_31"]
            let grown = ["32 +": "32_over"]
            let ageChoices = [baby, young, mid, grown]
            var opened = !self.currentManager.ageFilters.isEmpty
            var age = filterCell(opened: opened, title: "age range", options: ageChoices, type: "age")
            age.choices = [String]()
            age.choices.append("12 - 16")
            age.choices.append("17 - 24")
            age.choices.append("25 - 31")
            age.choices.append("32 +")
            self.basicFilterList.append(age)
            
            var lookingHeader = filterCell()
            lookingHeader.header = true
            lookingHeader.type = "lookingFor"
            lookingHeader.opened = false
            lookingHeader.options = [["": ""]]
            self.basicFilterList.append(lookingHeader)
            /*/for question in self.game!.filterQuestions {
                let key = Array(question.keys)[0]
                var options = [[String: String]]()
                let answers = question[key] as? [[String: String]]
                for answer in answers! {
                    let answerKey = Array(answer.keys)[0]
                    let option = [key: answer[answerKey]!]
                    options.append(option)
                }
                let filter = filterCell(opened: false, title: key, options: options, type: "advanced")
                self.basicFilterList.append(filter)
            }*/
        }
        
        self.searchTable.dataSource = self
        self.searchTable.delegate = self
        self.searchTable.reloadData()
    }
    
    func addRemoveChoice(selected: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.searchManager.searchLookingFor.contains(selected)){
            delegate.searchManager.searchLookingFor.remove(at: delegate.searchManager.searchLookingFor.index(of: selected)!)
            self.searchTable.reloadData()
        } else {
            delegate.searchManager.searchLookingFor.append(selected)
            self.searchTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let current = returnedUsers[indexPath.item]
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
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
}

extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}

