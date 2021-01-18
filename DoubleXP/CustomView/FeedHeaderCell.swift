//
//  FeedHeaderCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import UnderLineTextField
import FBSDKCoreKit
import Lottie
import FirebaseDatabase

class FeedHeaderCell : UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var todayImg: UIImageView!
    @IBOutlet weak var dynamicSub: UILabel!
    @IBOutlet weak var hero: UIImageView!
    @IBOutlet weak var headerText: UILabel!
    //@IBOutlet weak var headerSearch: UnderLineTextField!
    @IBOutlet weak var gameCollection: UICollectionView!
    @IBOutlet weak var gamesEmpty: UIView!
    @IBOutlet weak var addGames: UIButton!
    @IBOutlet weak var hookupLayout: UIView!
    @IBOutlet weak var todayBlur: UIVisualEffectView!
    @IBOutlet weak var justHereForTheBlur: UIView!
    @IBOutlet weak var requestAmount: UILabel!
    @IBOutlet weak var alertsAmount: UILabel!
    @IBOutlet weak var requestsLayout: UIView!
    @IBOutlet weak var alertsLayout: UIView!
    @IBOutlet weak var todayNotificationDot: UIImageView!
    @IBOutlet weak var todayLoadingBlur: UIVisualEffectView!
    @IBOutlet weak var todayLoadingAnimation: AnimationView!
    @IBOutlet weak var todayOnlineStatus: UIImageView!
    var payload = [GamerConnectGame]()
    var feedFrag: Feed?
    var dataSet = false
    var recommendedLoaded = false
    
    func setLayout(feed: Feed, loaded: Bool){
        self.recommendedLoaded = loaded
        self.feedFrag = feed
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //header
        let defaults = UserDefaults.standard
        if(defaults.bool(forKey: "landing_returning") == true){
            if(appDelegate.currentUser!.gamerTag.isEmpty){
                self.headerText.text = "welcome back!"
            } else {
                self.headerText.text = "welcome back, " + appDelegate.currentUser!.gamerTag + "!"
            }
        } else {
            defaults.set(true, forKey: "landing_returning")
            self.headerText.text = "welcome!"
        }
        
        //hero
        if self.traitCollection.userInterfaceStyle == .dark {
        // User Interface is Dark
            let cache = appDelegate.imageCache
            if(cache.object(forKey: appDelegate.heroDarkUrl as NSString) != nil){
                hero.image = cache.object(forKey: appDelegate.heroDarkUrl as NSString)
            } else {
                hero.image = Utility.Image.placeholder
                hero.moa.onSuccess = { image in
                    self.hero.image = image
                    appDelegate.imageCache.setObject(image, forKey: appDelegate.heroDarkUrl as NSString)
                    return image
                }
                hero.moa.url = appDelegate.heroDarkUrl
            }
            hero.contentMode = .scaleAspectFill
        } else {
        // User Interface is Light
            let cache = appDelegate.imageCache
            if(cache.object(forKey: appDelegate.heroLightUrl as NSString) != nil){
                hero.image = cache.object(forKey: appDelegate.heroLightUrl as NSString)
            } else {
                hero.image = Utility.Image.placeholder
                hero.moa.onSuccess = { image in
                    self.hero.image = image
                    appDelegate.imageCache.setObject(image, forKey: appDelegate.heroLightUrl as NSString)
                    return image
                }
                hero.moa.url = appDelegate.heroLightUrl
            }
            hero.contentMode = .scaleAspectFill
        }
        
        /*hero.layer.shadowColor = UIColor.black.cgColor
        hero.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        hero.layer.shadowRadius = 2.0
        hero.layer.shadowOpacity = 0.5
        hero.layer.masksToBounds = false*/
        
        let testBounds = CGRect(x: hero.bounds.minX, y: hero.bounds.minY, width: self.bounds.width, height: hero.bounds.height)
        //hero.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: hero.layer.cornerRadius).cgPath
        
        let maskLayer = CAGradientLayer(layer: self.hero.layer)
        maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.frame = testBounds
        self.hero.layer.mask = maskLayer
        
        //sub
        dynamicSub.text = appDelegate.feedSub
        
        //games
        var userGamesList = [GamerConnectGame]()
        var list = [GamerConnectGame]()
        if(appDelegate.currentUser!.games.isEmpty){
            self.gamesEmpty.alpha = 1
            self.addGames.addTarget(self, action: #selector(addGamesClicked), for: .touchUpInside)
            list.append(contentsOf: userGamesList)
        } else {
            self.gamesEmpty.alpha = 0
            for game in appDelegate.gcGames {
                if(game.available == "true" && appDelegate.currentUser!.games.contains(game.gameName)){
                    userGamesList.append(game)
                }
            }
            list.append(contentsOf: userGamesList)
        }
        
        payload = list
        
        //today blur
        self.todayLoadingAnimation.loopMode = .loop
        self.todayLoadingAnimation.play()
        if(!self.recommendedLoaded && todayLoadingBlur.alpha == 0){
            self.showTodayLoading()
        } else if(!self.recommendedLoaded && todayLoadingBlur.alpha == 1){
            self.todayLoadingAnimation.play()
            self.todayLoadingBlur.alpha = 1
        } else if(self.recommendedLoaded && todayLoadingBlur.alpha == 1){
            self.dismissTodayLoading()
        } else {
            self.todayLoadingAnimation.pause()
            self.todayLoadingBlur.alpha = 0
        }
        
        if self.traitCollection.userInterfaceStyle == .dark {
            self.todayImg.image = #imageLiteral(resourceName: "test_twitch_header.jpg")
        } else {
            self.todayImg.image = #imageLiteral(resourceName: "discover_2.jpg")
        }
        
        self.todayBlur.layer.cornerRadius = 15.0
        self.todayBlur.layer.borderWidth = 1.0
        self.todayBlur.layer.borderColor = UIColor.clear.cgColor
        self.todayBlur.layer.masksToBounds = true
        
        self.justHereForTheBlur.layer.cornerRadius = 15.0
        self.justHereForTheBlur.layer.borderWidth = 1.0
        self.justHereForTheBlur.layer.borderColor = UIColor.clear.cgColor
        self.justHereForTheBlur.layer.masksToBounds = true
        
        self.justHereForTheBlur.layer.shadowColor = UIColor.black.cgColor
        self.justHereForTheBlur.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.justHereForTheBlur.layer.shadowRadius = 2.0
        self.justHereForTheBlur.layer.shadowOpacity = 0.5
        self.justHereForTheBlur.layer.masksToBounds = false
        self.justHereForTheBlur.layer.shadowPath = UIBezierPath(roundedRect: self.justHereForTheBlur.bounds, cornerRadius: self.justHereForTheBlur.layer.cornerRadius).cgPath
        self.fetchTodayInfo()
        
        //headerSearch.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        //headerSearch.delegate = self
        //headerSearch.returnKeyType = UIReturnKeyType.done
        
        let alertsTap = UITapGestureRecognizer(target: self, action: #selector(alertsClicked))
        self.alertsLayout.isUserInteractionEnabled = true
        self.alertsLayout.addGestureRecognizer(alertsTap)
        
        let requestTap = UITapGestureRecognizer(target: self, action: #selector(requestsClicked))
        self.requestsLayout.isUserInteractionEnabled = true
        self.requestsLayout.addGestureRecognizer(requestTap)
        
        if(!dataSet){
            self.gameCollection.delegate = self
            self.gameCollection.dataSource = self
            
            self.dataSet = true
        } else {
            self.gameCollection.reloadData()
        }
    }
    
    private func fetchTodayInfo(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var pendingShowing = false
        if(appDelegate.currentUser!.pendingRequests.isEmpty && appDelegate.currentUser!.tempRivals.isEmpty){
            self.requestAmount.text = "--"
        } else {
            pendingShowing = true
            self.requestAmount.text = String(format: "%02d", (appDelegate.currentUser!.pendingRequests.count +  appDelegate.currentUser!.tempRivals.count))
        }
        
        var alertsShowing = false
        if(appDelegate.currentUser!.acceptedTempRivals.isEmpty && appDelegate.currentUser!.rejectedTempRivals.isEmpty &&
            appDelegate.currentUser!.receivedAnnouncements.isEmpty){
            self.alertsAmount.text = "--"
            
            if(pendingShowing || alertsShowing){
                self.todayNotificationDot.alpha = 1
            } else {
                self.todayNotificationDot.alpha = 0
            }
            
            if(self.feedFrag!.announcementsAvailable){
                self.todayOnlineStatus.alpha = 1
            } else {
                self.todayOnlineStatus.alpha = 0
            }
            
            self.dismissTodayLoading()
        } else {
            if(!appDelegate.currentUser!.receivedAnnouncements.isEmpty){
                let ref = Database.database().reference().child("Users")
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    for uid in appDelegate.currentUser!.receivedAnnouncements {
                        if(snapshot.hasChild(uid)){
                            let currentUser = snapshot.childSnapshot(forPath: uid)
                            if(!currentUser.hasChild("onlineAnnouncements")){
                                appDelegate.currentUser!.receivedAnnouncements.remove(at: appDelegate.currentUser!.receivedAnnouncements.index(of: uid)!)
                            }
                        }
                    }
                    
                    if(snapshot.hasChild(appDelegate.currentUser!.uId)){
                        if(!appDelegate.currentUser!.receivedAnnouncements.isEmpty){
                            ref.child(appDelegate.currentUser!.uId).child("receivedAnnouncements").setValue(appDelegate.currentUser!.receivedAnnouncements)
                        } else {
                            ref.child(appDelegate.currentUser!.uId).child("receivedAnnouncements").removeValue()
                        }
                    }
                    
                    if(!appDelegate.currentUser!.receivedAnnouncements.isEmpty || !appDelegate.currentUser!.acceptedTempRivals.isEmpty ||
                        !appDelegate.currentUser!.rejectedTempRivals.isEmpty){
                        alertsShowing = true
                        
                        let count = (appDelegate.currentUser!.acceptedTempRivals.count + appDelegate.currentUser!.rejectedTempRivals.count
                                        + appDelegate.currentUser!.receivedAnnouncements.count)
                        self.alertsAmount.text = String(format: "%02d", count)
                    }
                    
                    if(pendingShowing || alertsShowing){
                        self.todayNotificationDot.alpha = 1
                    } else {
                        self.todayNotificationDot.alpha = 0
                    }
                    
                    self.dismissTodayLoading()
                    
                    return
                })
            } else {
                alertsShowing = true
                let count = (appDelegate.currentUser!.acceptedTempRivals.count + appDelegate.currentUser!.rejectedTempRivals.count
                                + appDelegate.currentUser!.receivedAnnouncements.count)
                self.alertsAmount.text = String(format: "%02d", count)
                
                if(pendingShowing || alertsShowing){
                    self.todayNotificationDot.alpha = 1
                } else {
                    self.todayNotificationDot.alpha = 0
                }
                
                self.dismissTodayLoading()
            }
        }
        
        if(appDelegate.recommendedUsersManager.recommendationsAvailable()){
            self.hookupLayout.alpha = 1
            
            let hookupTap = UITapGestureRecognizer(target: self, action: #selector(hookupClicked))
            self.hookupLayout.isUserInteractionEnabled = true
            self.hookupLayout.addGestureRecognizer(hookupTap)
        } else {
            self.hookupLayout.alpha = 0.3
            self.hookupLayout.isUserInteractionEnabled = false
        }
    }
    
    private func showTodayLoading(){
        self.todayLoadingAnimation.play()
        UIView.animate(withDuration: 0.5, animations: {
            self.todayLoadingBlur.alpha = 0
        }, completion: nil)
    }
    
    private func dismissTodayLoading(){
        UIView.animate(withDuration: 0.5, animations: {
            self.todayLoadingBlur.alpha = 0
        }, completion: { (finished: Bool) in
            self.todayLoadingAnimation.pause()
        })
    }
    
    @objc private func hookupClicked(){
        self.feedFrag?.hookupClicked()
    }
    
    @objc private func requestsClicked(){
        self.feedFrag?.requestsClicked()
    }
    
    @objc private func alertsClicked(){
        self.feedFrag?.alertsClicked()
    }
    
    @objc private func addGamesClicked(){
        self.feedFrag?.launchGameSelection()
    }
    
    func viewDidLayoutSubviews(){
        hero.layer.shadowColor = UIColor.black.cgColor
        hero.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        hero.layer.shadowRadius = 2.0
        hero.layer.shadowOpacity = 0.5
        hero.layer.masksToBounds = false
        
        let testBounds = CGRect(x: hero.bounds.minX, y: hero.bounds.minY, width: self.bounds.width, height: hero.bounds.height)
        hero.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: hero.layer.cornerRadius).cgPath
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
        
        let game = payload[indexPath.item]

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
        
        cell.gameName.text = game.gameName
        cell.developer.text = game.developer
        
        if(game.mobileGame == "true"){
            cell.mobile.isHidden = false
        } else {
            cell.mobile.isHidden = true
        }
        cell.hook.text = game.hook
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC-Connect " + game.gameName + " Click"))
        
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        self.feedFrag?.navigateToSearch(game: current)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 280, height: CGFloat(130))
    }
    
    /*@objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text?.count == 0){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            var list = [GamerConnectGame]()
            for game in delegate.gcGames {
                var contained = false
                for userGame in list {
                    if(game.gameName == userGame.gameName){
                        contained = true
                    }
                }
                if(!contained){
                    list.append(game)
                }
            }
            self.payload = list
        } else {
            self.payload = [GamerConnectGame]()
            let delegate = UIApplication.shared.delegate as! AppDelegate
            var list = [GamerConnectGame]()
            for game in delegate.gcGames {
                var contained = false
                for userGame in list {
                    if(game.gameName == userGame.gameName){
                        contained = true
                    }
                }
                if(!contained){
                    list.append(game)
                }
            }
            for game in list {
                if(game.gameName.localizedCaseInsensitiveContains(textField.text!)){
                    self.payload.append(game)
                }
            }
        }
        self.gameCollection.reloadData()
    }
    
    func resetSearchList(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var userGamesList = [GamerConnectGame]()
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true" && delegate.currentUser!.games.contains(game.gameName)){
                userGamesList.append(game)
            }
        }
        list.append(contentsOf: userGamesList)
        for game in delegate.gcGames {
            var contained = false
            for userGame in list {
                if(game.gameName == userGame.gameName){
                    contained = true
                }
            }
            if(!contained){
                list.append(game)
            }
        }
        self.payload = list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.gameCollection.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func resetSearch(){
        //self.headerSearch.text = ""
    }*/
}
