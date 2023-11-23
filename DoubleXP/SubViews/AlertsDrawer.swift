//
//  AlertsDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/30/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import Lottie
import SPStorkController

class AlertsDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource, TodayCallbacks, SPStorkControllerDelegate {
    @IBOutlet weak var empty: UIView!
    @IBOutlet weak var alertsTable: UITableView!
    @IBOutlet weak var alertsImg: UIImageView!
    @IBOutlet weak var alertWorkOverlay: UIVisualEffectView!
    @IBOutlet weak var workAnimation: LottieAnimationView!
    @IBOutlet weak var kobeHeader: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    var dataSet = false
    var payLoad = [Any]()
    var acceptedRivals = [String]()
    var rejectedRivals = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
    }
    
    private func buildPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        payLoad = [Any]()
        if(!currentUser.receivedAnnouncements.isEmpty){
            checkAnnouncements(ids: currentUser.receivedAnnouncements)
        } else {
            payLoad.append(contentsOf: currentUser.acceptedTempRivals)
            payLoad.append(contentsOf: currentUser.rejectedTempRivals)
            payLoad.append(contentsOf: currentUser.followerAnnouncements)
            if(self.payLoad.isEmpty){
                self.alertsTable.alpha = 0
                self.empty.alpha = 1
                self.clearButton.alpha = 0.3
                self.clearButton.isUserInteractionEnabled = false
            } else {
                self.alertsTable.alpha = 1
                self.empty.alpha = 0
                self.clearButton.alpha = 1
                self.clearButton.addTarget(self, action: #selector(self.clearAllClicked), for: .touchUpInside)
                self.clearButton.isUserInteractionEnabled = true
                
                if(!self.dataSet){
                    self.dataSet = true
                    self.alertsTable.delegate = self
                    self.alertsTable.dataSource = self
                    self.alertsTable.reloadData()
                } else {
                    self.alertsTable.reloadData()
                }
            }
        }
    }
    
    private func removeAlert(optionType: String, position: Int, onlineUid: String){
        UIView.animate(withDuration: 0.8, animations: {
            self.alertWorkOverlay.alpha = 1
            if(optionType == "rival"){
                if(!onlineUid.isEmpty){
                    self.payLoad.remove(at: position)
                    FriendsManager().cleanRivals(rivalId: onlineUid, callbacks: self)
                }
            } else if(optionType == "follower"){
                self.payLoad.remove(at: position)
                FriendsManager().cleanFollowers(uid: onlineUid, callbacks: self)
            } else {
                if(!onlineUid.isEmpty){
                    self.payLoad.remove(at: position)
                    FriendsManager().cleanReceivedOnlineAnnouncements(announcementUid: onlineUid, callbacks: self)
                }
            }
        }, completion: { (finished: Bool) in
            
        })
    }
    
    private func resetViews(){
        self.workAnimation.alpha = 0
        self.kobeHeader.alpha = 0
    }
    
    private func hideWork(){
        
    }
    
    private func checkAnnouncements(ids: [String]){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        var users = [User]()
        
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for uid in ids {
                if(snapshot.hasChild(uid)){
                    let user = snapshot.childSnapshot(forPath: uid)
                    if(user.hasChild("onlineAnnouncements")){
                        users.append(self.quickCreateUser(snapshot: user))
                    }
                }
            }
            
            self.payLoad.append(contentsOf: users)
            self.payLoad.append(contentsOf: currentUser.acceptedTempRivals)
            self.payLoad.append(contentsOf: currentUser.rejectedTempRivals)
            self.payLoad.append(contentsOf: currentUser.followerAnnouncements)
            
            if(self.payLoad.isEmpty){
                self.alertsTable.alpha = 0
                self.empty.alpha = 1
                
                self.clearButton.alpha = 0.3
                self.clearButton.isUserInteractionEnabled = false
            } else {
                self.alertsTable.alpha = 1
                self.empty.alpha = 0
                self.clearButton.alpha = 1
                self.clearButton.addTarget(self, action: #selector(self.clearAllClicked), for: .touchUpInside)
                self.clearButton.isUserInteractionEnabled = true
                
                
                if(!self.dataSet){
                    self.dataSet = true
                    self.alertsTable.delegate = self
                    self.alertsTable.dataSource = self
                    self.alertsTable.reloadData()
                } else {
                    self.alertsTable.reloadData()
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payLoad.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payLoad[indexPath.item]
        if(current is RivalObj){
            let cell = tableView.dequeueReusableCell(withIdentifier: "alert", for: indexPath) as! AlertCell
            cell.backgroundColor = UIColor.clear
            let currentRivalObj = (current as! RivalObj)
            cell.senderTag.text = currentRivalObj.gamerTag
            
            var accepted = false
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            for rival in appDelegate.currentUser!.acceptedTempRivals {
                if(rival.id == currentRivalObj.id){
                    accepted = true
                    break
                }
            }
            
            if(accepted){
                cell.details.text = "accepted your request to play."
                cell.onlineIcon.alpha = 0
                cell.rejectedIcon.alpha = 0
                cell.acceptedIcon.alpha = 1
            } else {
                cell.details.text = "is not available to play."
                cell.onlineIcon.alpha = 0
                cell.rejectedIcon.alpha = 1
                cell.acceptedIcon.alpha = 0
            }
            
            let clearTap = ClearGesture(target: self, action: #selector(clearClicked))
            clearTap.onlineUid = currentRivalObj.id
            clearTap.optionType = "rival"
            clearTap.position = indexPath.item
            cell.clearAlert.isUserInteractionEnabled = true
            cell.clearAlert.addGestureRecognizer(clearTap)
            
            let launchTap = LaunchGesture(target: self, action: #selector(launchProfile))
            launchTap.uid = currentRivalObj.id
            cell.clickArea.isUserInteractionEnabled = true
            cell.clickArea.addGestureRecognizer(launchTap)
        
            return cell
        } else if(current is FriendObject){
            let cell = tableView.dequeueReusableCell(withIdentifier: "alert", for: indexPath) as! AlertCell
            cell.backgroundColor = UIColor.clear
            let currentFollower = (current as! FriendObject)
            cell.senderTag.text = currentFollower.gamerTag
            
            cell.details.text = "is following you now!"
            cell.onlineIcon.alpha = 0
            cell.rejectedIcon.alpha = 0
            cell.acceptedIcon.alpha = 1
            
            let clearTap = ClearGesture(target: self, action: #selector(clearClicked))
            clearTap.onlineUid = currentFollower.uid
            clearTap.optionType = "follower"
            clearTap.position = indexPath.item
            cell.clearAlert.isUserInteractionEnabled = true
            cell.clearAlert.addGestureRecognizer(clearTap)
            
            let launchTap = LaunchGesture(target: self, action: #selector(launchProfile))
            launchTap.uid = currentFollower.uid
            cell.clickArea.isUserInteractionEnabled = true
            cell.clickArea.addGestureRecognizer(launchTap)
        
            return cell
        } else {
            let currentUser = (current as! User)
            let cell = tableView.dequeueReusableCell(withIdentifier: "alert", for: indexPath) as! AlertCell
            cell.backgroundColor = UIColor.clear
            cell.senderTag.text = currentUser.gamerTag
            cell.details.text = "jumping online -- you should too."
            
            let clearTap = ClearGesture(target: self, action: #selector(clearClicked))
            clearTap.onlineUid = currentUser.uId
            clearTap.position = indexPath.item
            clearTap.optionType = "online"
            cell.clearAlert.isUserInteractionEnabled = true
            cell.clearAlert.addGestureRecognizer(clearTap)
            
            let launchTap = LaunchGesture(target: self, action: #selector(launchProfile))
            launchTap.uid = currentUser.uId
            cell.clickArea.isUserInteractionEnabled = true
            cell.clickArea.addGestureRecognizer(launchTap)
            
            cell.onlineIcon.alpha = 1
            cell.rejectedIcon.alpha = 0
            cell.acceptedIcon.alpha = 0
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = self.payLoad[indexPath.item]
        if(current is RivalObj){
            let uid = (current as! RivalObj).uid
            
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
        } else if(current is FriendObject){ //new follower
            let uid = (current as! FriendObject).uid
            
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
        } else {
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
    
    @objc private func launchProfile(sender: LaunchGesture){
        let uid = sender.uid
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedTest = uid!
        
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
    
    @objc private func clearClicked(sender: ClearGesture){
        self.removeAlert(optionType: sender.optionType, position: sender.position, onlineUid: sender.onlineUid)
    }
    
    @objc private func clearAllClicked(sender: ClearGesture){
        UIView.animate(withDuration: 0.8, animations: {
            self.alertWorkOverlay.alpha = 1
            FriendsManager().clearAllAnnouncements(callbacks: self)
        })
    }
    
    func onRecommendedUsersLoaded() {
    }
    
    func onSuccess() {
        self.buildPayload()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.workAnimation.alpha = 1
            self.workAnimation.play(completion: { _ in
                UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                    self.kobeHeader.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                        self.alertWorkOverlay.alpha = 0
                        self.resetViews()
                    })
                })
            })
        }, completion: nil)
    }
    
    func onSuccessShort(){
        self.buildPayload()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
        UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
            self.alertWorkOverlay.alpha = 0
            self.resetViews()
        }, completion: nil)
    }
    
    private func quickCreateUser(snapshot: DataSnapshot) -> User{
        let user = User(uId: snapshot.key)
        if(snapshot.hasChild("gamerTag")){
            let gamerTag = snapshot.childSnapshot(forPath: "gamerTag").value as? String ?? ""
            user.gamerTag = gamerTag
        }
        return user
    }
}

class ClearGesture: UITapGestureRecognizer {
    var onlineUid: String!
    var position: Int!
    var optionType: String!
}

class LaunchGesture: UITapGestureRecognizer {
    var uid: String!
}

