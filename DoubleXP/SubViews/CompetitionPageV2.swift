//
//  CompetitionPageV2.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/5/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import Firebase
import Lottie

class CompetitionPageV2 : UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate {

    @IBOutlet weak var compTable: UITableView!
    var payload = [String]()
    var currentComp: CompetitionObj?
    var entryEligible = false
    var currentNotificationLottie: AnimationView?
    var notifications = false
    var currentNotificationsButtion: UIView?
    var playAnimation = false
    var entriesAvailable = false
    var moneyAnimatonPlayed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkEntryEligiblity()
        self.checkNotifications()
        self.checkEntries()
        self.setEntriesListener()
        payload.append("header")
        payload.append("buttons")
        payload.append("description")
        payload.append("prize")
        payload.append("instructions")
        payload.append("sponsor")
        compTable.delegate = self
        compTable.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        if(current == "header"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! CompetitionHeader
            cell.compTitle.text = currentComp?.competitionName
            cell.sponsorLabel.text = currentComp?.mainSponsor
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            
            if(cache.object(forKey: currentComp!.promoImgUrl as NSString) != nil){
                cell.promoImg.image = cache.object(forKey: currentComp!.promoImgUrl as NSString)
            } else {
                cell.promoImg.image = Utility.Image.placeholder
                cell.promoImg.moa.onSuccess = { image in
                    cell.promoImg.image = image
                    appDelegate.imageCache.setObject(image, forKey: self.currentComp!.promoImgUrl as NSString)
                    return image
                }
                cell.promoImg.moa.url = currentComp!.promoImgUrl
            }
            
            cell.liveAnim.loopMode = .loop
            cell.liveAnim.play()
            
            cell.sponsorContainer.layer.shadowColor = UIColor.black.cgColor
            cell.sponsorContainer.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.sponsorContainer.layer.shadowRadius = 2.0
            cell.sponsorContainer.layer.shadowOpacity = 0.5
            cell.sponsorContainer.layer.masksToBounds = false
            
            return cell
        } else if(current == "prize"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "prize", for: indexPath) as! CompPrizeCell
            cell.compTopPrize.text = currentComp?.topPrize
            cell.prizeUnits.text = currentComp?.topPrizeType
            if(!self.moneyAnimatonPlayed){
                self.moneyAnimatonPlayed = true
                cell.moneyAnimation.loopMode = .playOnce
                cell.moneyAnimation.play { (finished) in
                    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { () -> Void in
                        cell.moneyAnimation.alpha = 0
                    }, completion: nil)
                }
            }
            return cell
        } else if(current == "description"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "description", for: indexPath) as! CompDescriptionCell
            cell.compDescription.text = currentComp?.compDescription
            return cell
        } else if(current == "instructions"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "instructions", for: indexPath) as! CompInstructionsCell
            cell.setTable(payload: self.currentComp!.rundown)
            return cell
        } else if(current == "sponsor"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "sponsor", for: indexPath) as! CompSponsorButtonsCell
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(launchSponsor))
            cell.sponsorButton.isUserInteractionEnabled = true
            cell.sponsorButton.addGestureRecognizer(singleTap)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttons", for: indexPath) as! CompButtons
            
            cell.enterButton.layer.cornerRadius = 10.0
            cell.enterButton.layer.borderWidth = 1.5
            cell.enterButton.layer.masksToBounds = true
            if(entryEligible){
                cell.enterButton.layer.borderColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                if(cell.enterButton.alpha == 0.05){
                    UIView.animate(withDuration: 0.8, animations: {
                        cell.enterButton.alpha = 1
                    }, completion: nil)
                } else {
                    cell.enterButton.alpha = 1.0
                }
                
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(launchYoutube))
                cell.enterButton.isUserInteractionEnabled = true
                cell.enterButton.addGestureRecognizer(singleTap)
            } else {
                cell.enterButton.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.074041076, alpha: 1)
                if(cell.enterButton.alpha == 1.0){
                    UIView.animate(withDuration: 0.8, animations: {
                        cell.enterButton.alpha = 0.05
                    }, completion: nil)
                } else {
                    cell.enterButton.alpha = 0.05
                }
                cell.enterButton.alpha = 0.05
                cell.enterButton.isUserInteractionEnabled = false
            }
            
            let leaderboardTap = UITapGestureRecognizer(target: self, action: #selector(launchLeaderboard))
            cell.leaderboardButton.isUserInteractionEnabled = true
            cell.leaderboardButton.addGestureRecognizer(leaderboardTap)
            cell.leaderboardButton.layer.cornerRadius = 10.0
            cell.leaderboardButton.layer.borderWidth = 1.5
            cell.leaderboardButton.layer.borderColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
            cell.leaderboardButton.layer.masksToBounds = true
            
            print(self.entriesAvailable)
            if(self.entriesAvailable) {
                cell.voteButton.layer.borderColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                if(cell.voteButton.alpha == 0.05){
                    UIView.animate(withDuration: 0.8, animations: {
                        cell.voteButton.alpha = 1
                    }, completion: nil)
                } else {
                    cell.voteButton.alpha = 1.0
                }
                
                let voteTap = UITapGestureRecognizer(target: self, action: #selector(launchVote))
                cell.voteButton.isUserInteractionEnabled = true
                cell.voteButton.addGestureRecognizer(voteTap)
            } else {
                cell.voteButton.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.074041076, alpha: 1)
                if(cell.voteButton.alpha == 1.0){
                    UIView.animate(withDuration: 0.8, animations: {
                        cell.voteButton.alpha = 0.05
                    }, completion: nil)
                } else {
                    cell.voteButton.alpha = 0.05
                }
                cell.voteButton.isUserInteractionEnabled = false
            }
            cell.voteButton.layer.cornerRadius = 10.0
            cell.voteButton.layer.borderWidth = 1.0
            cell.voteButton.layer.masksToBounds = true
            
            let notificationTap = UITapGestureRecognizer(target: self, action: #selector(handleNotificationState))
            cell.notificationButton.isUserInteractionEnabled = true
            cell.notificationButton.addGestureRecognizer(notificationTap)
            cell.notificationAnimation.currentFrame = 0
            
            if(self.playAnimation){
                cell.notificationAnimation.play()
                self.playAnimation = false
            }
            if(self.notifications){
                cell.notificationText.text = "notifications for this competition have been enabled."
                cell.notificationButton.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
            } else {
                cell.notificationText.text = "get notifications for this competition."
                cell.notificationButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            }
            return cell
        }
    }
    
    @objc private func handleNotificationState(){
        self.playAnimation = true
        setNotifications()
    }
    
    private func checkNotifications(){
        let ref = Database.database().reference().child("Competitions").child(self.currentComp!.competitionId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if (snapshot.hasChild("subscribers")) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let subscribers = snapshot.childSnapshot(forPath: "subscribers").value as? [String] ?? [String]()
                    self.notifications = subscribers.contains(appDelegate.currentUser!.uId)
                    self.compTable.reloadData()
                }
            }
        })
    }
    
    private func setNotifications(){
        let ref = Database.database().reference().child("Competitions").child(self.currentComp!.competitionId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if (snapshot.hasChild("subscribers")) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    var subscribers = snapshot.childSnapshot(forPath: "subscribers").value as? [String] ?? [String]()
                    if(!self.notifications && !subscribers.contains(appDelegate.currentUser!.uId)){
                        subscribers.append(appDelegate.currentUser!.uId)
                        ref.child("subscribers").setValue(subscribers)
                        self.notifications = true
                        Messaging.messaging().subscribe(toTopic: self.currentComp!.competitionTopic)
                    } else if(!self.notifications && subscribers.contains(appDelegate.currentUser!.uId)){
                        subscribers.append(appDelegate.currentUser!.uId)
                        ref.child("subscribers").setValue(subscribers)
                        self.notifications = true
                        Messaging.messaging().subscribe(toTopic: self.currentComp!.competitionTopic)
                    } else if (self.notifications && subscribers.contains(appDelegate.currentUser!.uId)){
                        subscribers.remove(at: subscribers.index(of: appDelegate.currentUser!.uId)!)
                        ref.child("subscribers").setValue(subscribers)
                        self.notifications = false
                        Messaging.messaging().unsubscribe(fromTopic: self.currentComp!.competitionTopic)
                    } else if (self.notifications && !subscribers.contains(appDelegate.currentUser!.uId)){
                        self.notifications = false
                        Messaging.messaging().unsubscribe(fromTopic: self.currentComp!.competitionTopic)
                    }
                    self.compTable.reloadData()
                } else {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let subscribers = [appDelegate.currentUser!.uId]
                    ref.child("subscribers").setValue(subscribers)
                    self.notifications = true
                    Messaging.messaging().subscribe(toTopic: self.currentComp!.competitionTopic)
                }
                self.compTable.reloadData()
            }
        })
    }
    
    @objc private func launchYoutube(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "youtube") as! YoutubeConnect
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentCompetitionPage = self
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.profileUser = appDelegate.currentUser!
        currentViewController.competitionId = self.currentComp!.competitionId
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchLeaderboard(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "leaderboard") as! CompLeaderboard
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentCompetitionPage = self
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.compId = self.currentComp!.competitionId
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchVote(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "vote") as! VoteModal
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentCompetitionPage = self
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.compId = self.currentComp!.competitionId
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchSponsor(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "web") as! WebModal
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.url = self.currentComp!.sponsorUrl
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchRules(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "web") as! WebModal
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.url = self.currentComp!.rulesUrl
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func checkEntryEligiblity(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let entryRef = Database.database().reference().child("Entries").child(self.currentComp!.competitionId).child(appDelegate.currentUser!.uId)
        entryRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                self.entryEligible = false
            } else {
                self.entryEligible = true
            }
            self.compTable.reloadData()
        })
    }
    
    func checkEntries(){
        let entryRef = Database.database().reference().child("Entries").child(self.currentComp!.competitionId)
        entryRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                for child in snapshot.children {
                    let current = child as! DataSnapshot
                    if(current.hasChild("0")){
                        let uid = current.childSnapshot(forPath: "0").childSnapshot(forPath: "uid").value as? String ?? ""
                        print("uid = " + uid)
                        let voterUids = current.childSnapshot(forPath: "0").childSnapshot(forPath: "voterUids").value as? [String] ?? [String]()
                        let passUids = current.childSnapshot(forPath: "0").childSnapshot(forPath: "passUids").value as? [String] ?? [String]()
                        
                        if(uid != appDelegate.currentUser!.uId && !voterUids.contains(appDelegate.currentUser!.uId) && !passUids.contains(appDelegate.currentUser!.uId)){
                            self.entriesAvailable = true
                            self.compTable.reloadData()
                            break
                        } else {
                            self.entriesAvailable = false
                        }
                    }
                }
                print(self.entriesAvailable)
                self.compTable.reloadData()
            }
        })
    }
    
    private func setEntriesListener(){
        let entryRef = Database.database().reference().child("Entries").child(self.currentComp!.competitionId)
        entryRef.observe(.childAdded, with: { (snapshot) in
            if(snapshot.exists()){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                for child in snapshot.children {
                    let current = child as! DataSnapshot
                    if(current.hasChild("0")){
                        let uid = current.childSnapshot(forPath: "0").childSnapshot(forPath: "uid").value as? String ?? ""
                        print("uid = " + uid)
                        let voterUids = current.childSnapshot(forPath: "0").childSnapshot(forPath: "voterUids").value as? [String] ?? [String]()
                        let passUids = current.childSnapshot(forPath: "0").childSnapshot(forPath: "passUids").value as? [String] ?? [String]()
                        
                        if(uid != appDelegate.currentUser!.uId && !voterUids.contains(appDelegate.currentUser!.uId) && !passUids.contains(appDelegate.currentUser!.uId)){
                            self.entriesAvailable = true
                            self.compTable.reloadData()
                            break
                        } else {
                            self.entriesAvailable = false
                        }
                    }
                }
            }
        })
    }
}
