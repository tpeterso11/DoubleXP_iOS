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

class GamerConnectSearch: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout, SearchCallbacks, SPStorkControllerDelegate, SearchManagerCallbacks {
    
    var game: GamerConnectGame? = nil
    
    var returnedUsers = [Any]()
    var searchPS = false
    var searchXbox = false
    var searchNintendo = false
    var searchPC = false
    var searchMobile = false
    var set = false
    
    @IBOutlet weak var filterButton: UIImageView!
    @IBOutlet weak var gameHeaderImage: UIImageView!
    @IBOutlet weak var gamerConnectResults: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var searchEmpty: UIView!
    @IBOutlet weak var searchEmptyText: UILabel!
    @IBOutlet weak var searchEmptySub: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var searchAnimation: AnimationView!
    @IBOutlet weak var psLabel: UILabel!
    @IBOutlet weak var pcLabel: UILabel!
    @IBOutlet weak var xboxLabel: UILabel!
    @IBOutlet weak var nintendoLabel: UILabel!
    @IBOutlet weak var mobileLabel: UILabel!
    @IBOutlet weak var mobileSwitch: UISwitch!
    
    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //check rivals on entry.
        
        if(game != nil){
            //gameHeaderImage.alpha = 0
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: game!.imageUrl as NSString) != nil){
                gameHeaderImage.image = cache.object(forKey: game!.imageUrl as NSString)
            } else {
                gameHeaderImage.image = Utility.Image.placeholder
                gameHeaderImage.moa.onSuccess = { image in
                    self.gameHeaderImage.image = image
                    appDelegate.imageCache.setObject(image, forKey: self.game!.imageUrl as NSString)
                    return image
                }
                gameHeaderImage.moa.url = game!.imageUrl
            }
            gameHeaderImage.contentMode = .scaleAspectFill
            //gameImageHeader.clipsToBounds = true
            
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
            
            var availableCount = 0
            var userConsolesForGame = [String]()
            var psAvailable = false
            var xboxAvailable = false
            var nintendoAvailable = false
            var mobileAvailable = false
            var pcAvailable = false
            
            for profile in currentUser!.gamerTags {
                if(profile.game == game!.gameName){
                    userConsolesForGame.append(profile.console)
                }
            }
            
            if(game!.availablebConsoles.contains("ps")){
                psAvailable = true
                availableCount += 1
            }
            if(game!.availablebConsoles.contains("xbox")){
                xboxAvailable = true
                availableCount += 1
            }
            if(game!.availablebConsoles.contains("nintendo")){
                nintendoAvailable = true
                availableCount += 1
            }
            
            if(game!.availablebConsoles.contains("pc")){
                pcAvailable = true
                availableCount += 1
            }
            
            if(game!.availablebConsoles.contains("mobile")){
                mobileAvailable = true
                availableCount += 1
            }
            
            if(availableCount == 0 || availableCount == 1){
                self.pcSwitch.alpha = 0
                self.pcLabel.alpha = 0
                self.mobileSwitch.alpha = 0
                self.mobileLabel.alpha = 0
                self.psSwitch.alpha = 0
                self.psLabel.alpha = 0
                self.nintendoSwitch.alpha = 0
                self.nintendoLabel.alpha = 0
                self.xboxSwitch.alpha = 0
                self.xboxLabel.alpha = 0
                
                if(availableCount == 1){
                    if(psAvailable){
                        searchPS = true
                        manager.currentSelectedConsoles.append("ps")
                    }
                    if(xboxAvailable){
                        searchXbox = true
                        manager.currentSelectedConsoles.append("xbox")
                    }
                    if(nintendoAvailable){
                        searchNintendo = true
                        manager.currentSelectedConsoles.append("nintendo")
                    }
                    if(pcAvailable){
                        searchPC = true
                        manager.currentSelectedConsoles.append("pc")
                    }
                    if(mobileAvailable){
                        searchMobile = true
                        manager.currentSelectedConsoles.append("mobile")
                    }
                }
            } else  {
                if(psAvailable){
                    psSwitch.alpha = 1.0
                    psLabel.alpha = 1.0
                    psSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "ps"){
                            contained = true
                        }
                    }
                    if(contained){
                        psSwitch.isOn = true
                        searchPS = true
                        manager.currentSelectedConsoles.append("ps")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            psSwitch.isOn = true
                            searchPS = true
                            manager.currentSelectedConsoles.append("ps")
                        } else {
                            psSwitch.isOn = false
                            searchPS = false
                        }
                    }
                    psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    psSwitch.alpha = 0.3
                    psLabel.alpha = 0.3
                    psSwitch.isEnabled = false
                }
                if(xboxAvailable){
                    xboxSwitch.alpha = 1.0
                    xboxLabel.alpha = 1.0
                    xboxSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "xbox"){
                            contained = true
                        }
                    }
                    if(contained){
                        xboxSwitch.setOn(true, animated: false)
                        searchXbox = true
                        manager.currentSelectedConsoles.append("xbox")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            xboxSwitch.setOn(true, animated: false)
                            searchXbox = true
                            manager.currentSelectedConsoles.append("xbox")
                        } else {
                            xboxSwitch.setOn(false, animated: false)
                            searchXbox = false
                        }
                    }
                    xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    xboxSwitch.alpha = 0.3
                    xboxLabel.alpha = 0.3
                    xboxSwitch.isEnabled = false
                }
                if(nintendoAvailable){
                    nintendoSwitch.alpha = 1.0
                    nintendoLabel.alpha = 1.0
                    nintendoSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "nintendo"){
                            contained = true
                        }
                    }
                    if(contained){
                        nintendoSwitch.setOn(true, animated: false)
                        searchNintendo = true
                        manager.currentSelectedConsoles.append("nintendo")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            nintendoSwitch.setOn(true, animated: false)
                            searchNintendo = true
                            manager.currentSelectedConsoles.append("nintendo")
                        } else {
                            nintendoSwitch.setOn(false, animated: false)
                            searchNintendo = false
                        }
                    }
                    nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    nintendoSwitch.alpha = 0.3
                    nintendoLabel.alpha = 0.3
                    nintendoSwitch.isEnabled = false
                }
                if(pcAvailable){
                    pcSwitch.alpha = 1.0
                    pcLabel.alpha = 1.0
                    pcSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "pc"){
                            contained = true
                        }
                    }
                    if(contained){
                        pcSwitch.setOn(true, animated: false)
                        searchPC = true
                        manager.currentSelectedConsoles.append("pc")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            pcSwitch.setOn(true, animated: false)
                            searchPC = true
                            manager.currentSelectedConsoles.append("pc")
                        } else {
                            pcSwitch.setOn(false, animated: false)
                            searchPC = false
                        }
                    }
                    pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    pcSwitch.alpha = 0.3
                    pcLabel.alpha = 0.3
                    pcSwitch.isEnabled = false
                }
                if(mobileAvailable){
                    mobileSwitch.alpha = 1.0
                    mobileLabel.alpha = 1.0
                    mobileSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "mobile"){
                            contained = true
                        }
                    }
                    if(contained){
                        mobileSwitch.setOn(true, animated: false)
                        searchMobile = true
                        manager.currentSelectedConsoles.append("mobile")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            mobileSwitch.setOn(true, animated: false)
                            searchMobile = true
                            manager.currentSelectedConsoles.append("mobile")
                        } else {
                            mobileSwitch.setOn(false, animated: false)
                            searchMobile = false
                        }
                    }
                    mobileSwitch.addTarget(self, action: #selector(mobileSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    mobileSwitch.alpha = 0.3
                    mobileLabel.alpha = 0.3
                    mobileSwitch.isEnabled = false
                }
            }
            
            psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
            pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
            xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
            nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
            
            Broadcaster.register(SearchCallbacks.self, observer: self)
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showFilters))
            filterButton.isUserInteractionEnabled = true
            filterButton.addGestureRecognizer(singleTap)
            
            checkRivals()
        }
    }
    
    private func showLoading(){
        if(self.loadingView.alpha == 0){
            self.searchAnimation.play()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 1
            }, completion: nil)
        }
    }
    
    private func hideLoading(){
        if(self.loadingView.alpha == 1){
            self.searchAnimation.pause()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 0
            }, completion: nil)
        }
    }
    
    func dismissModal(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    
    @objc func didDismissStorkBySwipe(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.searchManager.searchWithFilters(callbacks: self)
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.profileManager
        currentUser = delegate.currentUser
        manager.updateTempRivalsDB()
        
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = delegate.searchManager
            manager.searchWithFilters(callbacks: self)
        }
        
    }
    
    @objc private func showFilters(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "filters") as! GCSearchFilters
        if(self.game != nil){
            currentViewController.gcGame = game
            appDelegate.currentFrag = "Filters"
            
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
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="yyyy.MM.dd hh:mm aaa"
        return formatter.date(from: str)!
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(stationSwitch.isOn){
            searchPS = true
            manager.currentSelectedConsoles.append("ps")
        }
        else{
            searchPS = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "ps")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(xSwitch.isOn){
            searchXbox = true
            manager.currentSelectedConsoles.append("xbox")
        }
        else{
            searchXbox = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "xbox")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(switchSwitch.isOn){
            searchNintendo = true
            manager.currentSelectedConsoles.append("nintendo")
        }
        else{
            searchNintendo = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "nintendo")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    
    @objc func mobileSwitchChanged(switchSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(switchSwitch.isOn){
            searchMobile = true
            manager.currentSelectedConsoles.append("mobile")
        }
        else{
            searchMobile = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "mobile")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(compSwitch.isOn){
            searchPC = true
            manager.currentSelectedConsoles.append("pc")
        }
        else{
            searchPC = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "pc")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return returnedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.returnedUsers[indexPath.item]
        if(current is User){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserCell
            
            let manager = GamerProfileManager()
            let current = returnedUsers[indexPath.item]
            cell.gamerTag.text = manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: (current as! User))
            
            if((current as! User).bio.isEmpty){
                cell.consoleTag.text = "No bio available."
            }
            else{
                cell.consoleTag.text = (current as! User).bio
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Profile Accessed"))
        
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
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
    
    private func searchUsers(userName: String?){
        if(self.searchPS){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PS, Game: " + self.game!.gameName))
        }
        if(self.searchXbox){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: XBox, Game: " + self.game!.gameName))
        }
        if(self.searchPC){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PC, Game: " + self.game!.gameName))
        }
        if(self.searchNintendo){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: Nintendo, Game: " + self.game!.gameName))
        }
        
        if(userName != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - User"))
        }
        
        if(self.loadingView.alpha == 0){
            self.searchAnimation.play()
            
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 1
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
                            if(!gamerTag.isEmpty && gamerTag == trimmedUser && (gamerProfileManager.getGamerTagForGame(gameName: self.game!.gameName) != userName)){
                                
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
            self.gamerConnectResults.delegate = self
            self.gamerConnectResults.dataSource = self
            
            self.set = true
            
            self.hideLoading()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    if(!self.returnedUsers.isEmpty){
                        self.searchEmpty.isHidden = true
                    }
                    else{
                        self.searchEmpty.isHidden = false
                        
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }, completion: nil)
            })
        }
        else{
            self.hideLoading()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                self.gamerConnectResults.reloadData()
                
                if(!self.returnedUsers.isEmpty){
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
                }
            })
        }
        
        }) { (error) in
            print(error.localizedDescription)
            AppEvents.logEvent(AppEvents.Name(rawValue: "GamerConnect Search "))
        }
    }
    
    func searchSubmitted(searchString: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.searchManager.searchForUser(searchTag: searchString, callbacks: self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.returnedUsers[indexPath.item]
        if(current is String){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(40))
        } else {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        }
    }
    
    private func addUserToList(returnedUser: User){
        var contained = false
        let manager = GamerProfileManager()
        
        for obj in returnedUsers{
            if(obj is User){
                if(manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: obj as! User) == manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: returnedUser)){
                    
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
            self.searchEmpty.alpha = 1
            self.searchEmpty.isHidden = false
            self.searchEmptySub.text = "please change a search filter or try again later."
            self.hideLoading()
            return
        }
        if(!set){
            self.searchEmpty.alpha = 0
            self.returnedUsers = returnedUsers
            self.returnedUsers.append("empty")
            self.gamerConnectResults.delegate = self
            self.gamerConnectResults.dataSource = self
            self.gamerConnectResults.reloadData()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.gamerConnectResults.alpha = 1
            }, completion: nil)
        } else {
            self.searchEmpty.alpha = 0
            self.returnedUsers = returnedUsers
            self.returnedUsers.append("empty")
            self.gamerConnectResults.reloadData()
        }
        self.hideLoading()
    }
    
    func onFailure() {
        self.searchEmpty.alpha = 1
        self.searchEmptySub.text = "please change a search filter or try again later."
    }
}

extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}

