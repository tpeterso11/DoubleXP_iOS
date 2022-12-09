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

class FeedHeaderCell : UITableViewCell {
    
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    @IBOutlet weak var todayImg: UIImageView!
    @IBOutlet weak var dynamicSub: UILabel!
    @IBOutlet weak var hero: UIImageView!
    @IBOutlet weak var headerText: UILabel!
    //@IBOutlet weak var headerSearch: UnderLineTextField!
    @IBOutlet weak var gameCollection: UICollectionView!
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
    @IBOutlet weak var startLayout: UIView!
    @IBOutlet weak var green: UIView!
    @IBOutlet weak var messageLayout: UIView!
    @IBOutlet weak var red: UIView!
    var feedFrag: Feed?
    var dataSet = false
    var recommendedLoaded = false
    
    func setLayout(feed: Feed, loaded: Bool, todayAnimated: Bool, todayAnimating: Bool){
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
        
        if(self.headerText.alpha == 0){
            UIView.animate(withDuration: 0.8, animations: {
                self.headerText.alpha = 1
                self.dynamicSub.alpha = 1
            }, completion: { (finished: Bool) in
                
            })
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
        
        let testBounds = CGRect(x: hero.bounds.minX, y: hero.bounds.minY, width: feed.view.bounds.width, height: hero.bounds.height)
        //hero.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: hero.layer.cornerRadius).cgPath
        
        let maskLayer = CAGradientLayer(layer: self.hero.layer)
        maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.frame = testBounds
        self.hero.layer.mask = maskLayer
        
        //sub
        dynamicSub.text = appDelegate.feedSub
        
        //today blur
        if self.traitCollection.userInterfaceStyle == .dark {
            self.todayImg.image = #imageLiteral(resourceName: "test_twitch_header.jpg")
        } else {
            self.todayImg.image = #imageLiteral(resourceName: "discover_2.jpg")
        }
        
        self.todayBlur.layer.cornerRadius = 15.0
        self.todayBlur.layer.borderWidth = 1.0
        self.todayBlur.layer.borderColor = UIColor.clear.cgColor
        self.todayBlur.layer.masksToBounds = true
    
        if(self.todayBlur.alpha == 0 && !todayAnimated && !todayAnimating){
            self.feedFrag?.todayAnimating = true
            self.todayBlur.isHidden = false
            self.todayBlur.contentView.alpha = 0
            UIView.animate(withDuration: 0.8, delay: 1.5, options: [], animations: {
                self.todayBlur.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.todayImg.alpha = 1
                    //self.justHereForTheBlur.alpha = 1
                }, completion: { (finished: Bool) in
                    self.todayLoadingBlur.isHidden = false
                    UIView.animate(withDuration: 0.5, animations: {
                        self.todayLoadingBlur.alpha = 1
                        self.todayLoadingAnimation.loopMode = .loop
                        self.todayLoadingAnimation.play()
                    }, completion: { (finished: Bool) in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchTodayInfo()
                        }
                    })
                })
            })
        } else if(todayAnimated && !todayAnimating){
            self.todayBlur.alpha = 1
            self.todayImg.alpha = 1
            self.justHereForTheBlur.alpha = 1
            self.todayBlur.contentView.alpha = 1
            self.todayBlur.isHidden = false
        }
    
        self.messageLayout.layer.shadowColor = UIColor.black.cgColor
        self.messageLayout.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.messageLayout.layer.shadowRadius = 2.0
        self.messageLayout.layer.shadowOpacity = 0.5
        self.messageLayout.layer.masksToBounds = false
        self.messageLayout.layer.shadowPath = UIBezierPath(roundedRect: self.messageLayout.bounds, cornerRadius: self.messageLayout.layer.cornerRadius).cgPath
        
        self.startLayout.layer.shadowColor = UIColor.black.cgColor
        self.startLayout.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.startLayout.layer.shadowRadius = 2.0
        self.startLayout.layer.shadowOpacity = 0.5
        self.startLayout.layer.masksToBounds = false
        self.startLayout.layer.shadowPath = UIBezierPath(roundedRect: self.startLayout.bounds, cornerRadius: self.startLayout.layer.cornerRadius).cgPath
        
        UIView.animate(withDuration: 0.8, delay: 2.0, options: [], animations: {
            self.startLayout.alpha = 1
            self.messageLayout.alpha = 1
        }, completion: { (finished: Bool) in
            
        })
        
        let alertsTap = UITapGestureRecognizer(target: self, action: #selector(alertsClicked))
        self.alertsLayout.isUserInteractionEnabled = true
        self.alertsLayout.addGestureRecognizer(alertsTap)
        
        let requestTap = UITapGestureRecognizer(target: self, action: #selector(requestsClicked))
        self.requestsLayout.isUserInteractionEnabled = true
        self.requestsLayout.addGestureRecognizer(requestTap)
        
        let messageTap = UITapGestureRecognizer(target: self, action: #selector(messageClicked))
        self.messageLayout.isUserInteractionEnabled = true
        self.messageLayout.addGestureRecognizer(messageTap)
        
        self.green.layer.masksToBounds = true
        self.green.clipsToBounds = true
        self.green.layer.cornerRadius = 10
        self.green.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        self.red.layer.masksToBounds = true
        self.red.clipsToBounds = true
        self.red.layer.cornerRadius = 10
        self.red.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        self.headerHeight.constant = 350
    }
    
    //combine videos to show messaging functionality for intro animation. you already downloaded the gameplay animation, next should prolly be like achievements or winning.
    
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
            appDelegate.currentUser!.receivedAnnouncements.isEmpty && appDelegate.currentUser!.followerAnnouncements.isEmpty){
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
                        !appDelegate.currentUser!.rejectedTempRivals.isEmpty || !appDelegate.currentUser!.followerAnnouncements.isEmpty){
                        alertsShowing = true
                        
                        let count = (appDelegate.currentUser!.acceptedTempRivals.count + appDelegate.currentUser!.rejectedTempRivals.count
                                        + appDelegate.currentUser!.receivedAnnouncements.count + appDelegate.currentUser!.followerAnnouncements.count)
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
                                + appDelegate.currentUser!.receivedAnnouncements.count + appDelegate.currentUser!.followerAnnouncements.count)
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
            self.todayBlur.contentView.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                self.todayLoadingBlur.alpha = 0
            }, completion: { (finished: Bool) in
                self.todayLoadingAnimation.pause()
            })
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
    
    @objc private func messageClicked(){
        self.feedFrag?.launchVideoMessage()
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
    
    /*func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    }*/
    
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
