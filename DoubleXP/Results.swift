//
//  Results.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import SwiftNotificationCenter
import SPStorkController

class Results: UIViewController, UITableViewDataSource, UITableViewDelegate, SPStorkControllerDelegate {
    var payload = [Any]()
    var returning = false
    var userUid = ""
    var currentUpgradeChoice = ""
    var animatedTitles = [String]()
    @IBOutlet weak var resultTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentResultsFrag = self
        buildPayload()
    }
    
    func onModalReturn(){
        self.resultTable.reloadData()
    }
    
    private func buildPayload(){
        payload = [Any]()
        
        payload.append("header") //header "we did it!"
        //payload.append("gif")
        
        if(isKeyPresentInUserDefaults(key: "registered")){
            self.returning = true
        }
        
        payload.append("toolsHeader")
        
        let optionAbout = UpgradeOption()
        optionAbout.title = "tell us about you"
        optionAbout.sub = "pick the tags that describe you the best."
        payload.append(optionAbout)
        
        let optionLooking = UpgradeOption()
        optionLooking.title = "tell us what you're looking for"
        optionLooking.sub = "pick the tags that describe your dream teammate would be."
        payload.append(optionLooking)
        //stats
        /*for game in delegate.gcGames {
            if(game.statsAvailable && games.contains(game.gameName)){
                payload.append(1)
                break
            }
        }*/
        payload.append(false)
        
        self.resultTable.delegate = self
        self.resultTable.dataSource = self
    }
    
    private func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        if(current is String){
            if((current as! String) == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ResultsHeaderCell
                cell.header.text = "we did it!"
                cell.sub.text = "i knew we could..."
                
                cell.header.alpha = 1
                cell.header.isHidden = false
                
                cell.whiteGuyContainer.layer.cornerRadius = 15.0
                cell.whiteGuyContainer.layer.borderWidth = 1.0
                cell.whiteGuyContainer.layer.borderColor = UIColor.clear.cgColor
                cell.whiteGuyContainer.layer.masksToBounds = true
                
                cell.whiteGuyContainer.layer.shadowColor = UIColor.black.cgColor
                cell.whiteGuyContainer.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.whiteGuyContainer.layer.shadowRadius = 2.0
                cell.whiteGuyContainer.layer.shadowOpacity = 0.5
                cell.whiteGuyContainer.layer.masksToBounds = false
                cell.whiteGuyContainer.layer.shadowPath = UIBezierPath(roundedRect: cell.whiteGuyContainer.bounds, cornerRadius: cell.whiteGuyContainer.layer.cornerRadius).cgPath
                
                return cell
            }
            else if((current as! String) == "toolsHeader"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "toolsHeader", for: indexPath) as! EmptyCell
                return cell
            }
            else if((current as! String) == "gif"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "gif", for: indexPath) as! TestGifCell
                let img = UIImage.gifImageWithURL("https://firebasestorage.googleapis.com/v0/b/gameterminal-767f7.appspot.com/o/xxhdpi%2FAcclaimedLivelyChuckwalla-size_restricted.gif?alt=media&token=be781e7c-f5b2-4efc-a77d-1a78439ff2c0")
                cell.gifImg.image = img
                return cell
            }
        }
        if(current is [String: [User]]){
            let current = (current as! [String: [User]])
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let values = current.map { $0.value }
            let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! ResultsUserCell
            cell.setUserList(list: values[0], type: delegate.cachedUserType, resultsConroller: self)
            return cell
        }
        if(current is UpgradeOption){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! ResultsUpgradeCell
            cell.header.text = (current as! UpgradeOption).title
            cell.sub.text = (current as! UpgradeOption).sub
            
            if((current as! UpgradeOption).title == "tell us about you"){
                cell.upgradeImage.image = #imageLiteral(resourceName: "profile_cta.jpg")
                if(delegate.currentUser!.userAbout.isEmpty){
                    cell.completedOverlay.alpha = 0
                } else {
                    cell.completedOverlay.alpha = 1
                    if(self.animatedTitles.contains("tell us about you")){
                        cell.completeAnimation.currentFrame = cell.completeAnimation.animation?.endFrame ?? 0
                    } else {
                        self.animatedTitles.append("tell us about you")
                        cell.completeAnimation.play()
                    }
                }
            }
            if((current as! UpgradeOption).title == "take a free agent quiz"){
                cell.upgradeImage.image = #imageLiteral(resourceName: "test_img.jpg")
            }
            if((current as! UpgradeOption).title == "tell us what you're looking for"){
                cell.upgradeImage.image = #imageLiteral(resourceName: "test_mobile_img.jpg")
                if(delegate.currentUser!.userLookingFor.isEmpty){
                    cell.completedOverlay.alpha = 0
                } else {
                    cell.completedOverlay.alpha = 1
                    if(self.animatedTitles.contains("tell us what you're looking for")){
                        cell.completeAnimation.currentFrame = cell.completeAnimation.animation?.endFrame ?? 0
                    } else {
                        self.animatedTitles.append("tell us what you're looking for")
                        cell.completeAnimation.play()
                    }
                }
            }
            
            let cellTap = UpgradeTapGesture(target: self, action: #selector(proceedUpgrade))
            cellTap.tag = indexPath.item
            cell.isUserInteractionEnabled = true
            cell.contentView.addGestureRecognizer(cellTap)
            return cell
        }
        if(current is Bool){
            let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath) as! ResultsButtonCell
            cell.header.text = "we've kept you long enough"
            cell.sub.text = "let's get you back in the game."
            cell.button.titleLabel!.text = "done."
            cell.button.addTarget(self, action: #selector(self.proceedHome), for: .touchUpInside)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ResultsHeaderCell
        return cell
    }
    
    @objc private func proceedHome(){
        UserDefaults.standard.setValue("true", forKey: "registered")
        performSegue(withIdentifier: "home", sender: self)
    }
    
    @objc private func proceedUpgrade(sender: UpgradeTapGesture){
        let current = payload[sender.tag]
        
        if((current as? UpgradeOption)?.title == "tell us about you"){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "aboutYou") as! AboutYouDrawer
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            currentViewController.usersSelected = delegate.currentUser!.userAbout
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
        if((current as! UpgradeOption).title == "tell us what you're looking for"){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "looking") as! LookingFor
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            currentViewController.usersSelected = delegate.currentUser!.userLookingFor
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "upgrade"){
            let svc = segue.destination as! Upgrade
            svc.extra = self.currentUpgradeChoice
        }
    }
    
    func proceedToProfile(userUid: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.cachedTest = userUid
        
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
        //performSegue(withIdentifier: "profile", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = self.payload[indexPath.item]
        if(current is String){
            if((current as! String) == "toolsHeader"){
                return CGFloat(120)
            } else {
                return CGFloat(350)
            }
        }
        if(current is [String: [User]]){
            return CGFloat(570)
        }
        if(current is Int){
            return CGFloat(125)
        }
        if(current is Bool){
            return CGFloat(180)
        }
        return CGFloat(150)
    }
    
    private func createDefaultList() -> [User]{
        let userOne = User(uId: "EeahIsrgvlQzeSNMA5L8uxlBSkk1")
        userOne.gamerTag = "allthesaint011"
        
        let userTwo = User(uId: "N1k1BqmvEvdOXrbmi2p91kTNLOo1")
        userTwo.gamerTag = "Kwatakye Raven"
        
        var users = [User]()
        users.append(userOne)
        users.append(userTwo)
        return users
    }
}

class UpgradeTapGesture: UITapGestureRecognizer {
    var tag: Int!
}

class UpgradeOption {
    var title: String!
    var sub: String!
}
