//
//  Requests.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import PopupDialog
import MSPeekCollectionViewDelegateImplementation
import SPStorkController

class Requests: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RequestsUpdate, SPStorkControllerDelegate {
    var userRequests = [Any]()
    
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var quizTable: UITableView!
    @IBOutlet weak var closeView: UIView!
    @IBOutlet weak var quizView: UIView!
    @IBOutlet weak var blurBack: UIVisualEffectView!
    @IBOutlet weak var quizCollection: UICollectionView!
    @IBOutlet weak var emptyLayout: UIView!
    @IBOutlet weak var veetooRequests: UICollectionView!
    
    var quizSet = false
    var dataSet = false
    
    @IBOutlet weak var requestsSub: UILabel!
    @IBOutlet weak var requestsHeader: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentRequests = self
        checkRivals()
    }
    
    private func animateView(){
        self.dataSet = true
        veetooRequests.delegate = self
        veetooRequests.dataSource = self
        
        let top = CGAffineTransform(translationX: 0, y: -30)
        UIView.animate(withDuration: 0.8, animations: {
            self.veetooRequests.alpha = 1
            self.veetooRequests.transform = top
        }, completion: nil)
    }
    
    private func dismissModal(){
        
    }
    
    func didDismissStorkBySwipe() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.buildRequests(user: delegate.currentUser!)
    }
    
    private func buildRequests(user: User){
        if(!user.tempRivals.isEmpty){
            for rival in user.tempRivals{
                self.userRequests.append(rival)
            }
        }
        
        if(!user.pendingRequests.isEmpty){
            for request in user.pendingRequests{
                self.userRequests.append(request)
            }
        }
        
        /*if(!user.teamInviteRequests.isEmpty){
            for request in user.teamInviteRequests{
                self.userRequests.append(request)
            }
        }
        
        if(!user.teamInvites.isEmpty){
            for request in user.teamInvites{
                self.userRequests.append(request)
            }
        }*/
        
        if(!dataSet){
            if(!userRequests.isEmpty){
                animateView()
            } else{
                let top = CGAffineTransform(translationX: 0, y: -10)
                UIView.animate(withDuration: 0.8, animations: {
                    self.emptyLayout.alpha = 1
                    self.emptyLayout.transform = top
                }, completion: nil)
            }
        } else {
            if(!userRequests.isEmpty){
                let top = CGAffineTransform(translationX: 0, y: -10)
                UIView.animate(withDuration: 0.8, animations: {
                    self.emptyLayout.alpha = 1
                    self.emptyLayout.transform = top
                }, completion: nil)
            } else {
                self.veetooRequests.reloadData()
            }
        }
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.profileManager
        
        manager.updateTempRivalsDB()
        self.showView()
    }
    
    func showView(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let top = CGAffineTransform(translationX: 0, y: -30)
        UIView.animate(withDuration: 0.8, delay: 0.3, options:[], animations: {
            self.requestsHeader.alpha = 1
            self.requestsHeader.transform = top
            self.requestsSub.alpha = 1
            
            if(currentUser != nil){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.buildRequests(user: currentUser!)
                }
            }
            else{
                return
            }
            
        }, completion: nil)
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    func launchProfile(uid: String){
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
    
    
    
    //later, add "accepted" and "invited" array to user. This way. when they are invited or accepted, we can observe this in the DB and open a nice little overlay that says "you've been accepted, chat or check out the team". We cannot do this just by observing teams because if they create a team themselves, we do not want this overlay showing.
    
    func updateCell() {
        /*let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentFeedFrag?.checkOnlineAnnouncements()
        
        if indexPath.item >= 0 && indexPath.item < self.userRequests.count {
            self.userRequests.remove(at: indexPath.item)
            //self.veetooRequests.deleteRows(at: [indexPath], with: .automatic)
            
            if(self.userRequests.isEmpty){
                UIView.animate(withDuration: 0.8, animations: {
                    self.emptyLayout.alpha = 1
                }, completion: nil)
            }
        }*/
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalRequestSuccess() {
    }
    
    func rivalRequestFail() {
    }
    
    func rivalResponseAccepted() {
        updateCell()
        showConfirmation()
    }
    
    func rivalResponseRejected() {
        updateCell()
    }
    
    func rivalResponseFailed() {
        showFail()
    }
    
    func friendRemoved() {
    }
    
    func friendRemoveFail() {
    }
    
    func onlineAnnounceFail() {
    }
    
    func onlineAnnounceSent() {
    }
    
    func showConfirmation(){
        var buttons = [PopupDialogButton]()
        let title = "you accepted, we sent it."
        let message = "looks like you both are ready to play. go get online!"
        
        let buttonOne = CancelButton(title: "game time!") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func showFail(){
        var buttons = [PopupDialogButton]()
        let title = "there was an error with your request."
        let message = "try again, or jump in the chat and let them know."
        
        let buttonOne = CancelButton(title: "gotcha") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.userRequests[indexPath.item]
        if(current is FriendRequestObject){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as! RequestsCellV2
            if((current as! FriendRequestObject).youtubeConnect.isEmpty){
                cell.youtubeLogo.alpha = 0.3
            } else {
                cell.youtubeLogo.alpha = 1.0
            }
            if((current as! FriendRequestObject).instagramConnect.isEmpty){
                cell.instagramLogo.alpha = 0.3
            } else {
                cell.instagramLogo.alpha = 1.0
            }
            if((current as! FriendRequestObject).discordConnect.isEmpty){
                cell.discordLogo.alpha = 0.3
            } else {
                cell.discordLogo.alpha = 1.0
            }
            if((current as! FriendRequestObject).youtubeConnect.isEmpty){
                cell.youtubeLogo.alpha = 0.3
            } else {
                cell.youtubeLogo.alpha = 1.0
            }
            
            cell.gamerTag.text = (current as! FriendRequestObject).gamerTag
            
            cell.contentView.layer.cornerRadius = 10.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.8
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "play", for: indexPath) as! RequestsPlayCellV2
            cell.gamertag.text = (current as! RivalObj).gamerTag
            
            cell.contentView.layer.cornerRadius = 10.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.8
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.userRequests[indexPath.item]
        if(current is FriendRequestObject){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(150))
        } else {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(130))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.userRequests[indexPath.item]
        if(current is FriendRequestObject){
            //let current = (self.userRequests[indexPath.item] as! FriendRequestObject)
            var buttons = [PopupDialogButton]()
            let title = "you got a request from " + (current as! FriendRequestObject).gamerTag
            let message = "what do you wanna do?"
            let manager = FriendsManager()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let buttonOne = DefaultButton(title: "view profile") { [weak self] in
                self?.launchProfile(uid: (current as! FriendRequestObject).uid)
            }
            buttons.append(buttonOne)
            
            let buttonTwo = CancelButton(title: "accept request") { [weak self] in
                manager.acceptFriendFromRequests(otherUserRequest: (current as! FriendRequestObject), currentUserUid: appDelegate.currentUser!.uId, callbacks: self as! RequestsUpdate)
            }
            buttons.append(buttonTwo)
            
            let buttonThree = DestructiveButton(title: "reject request") { [weak self] in
                manager.declineRequest(otherUserRequest: (current as! FriendRequestObject), currentUserUid: appDelegate.currentUser!.uId, callbacks: self as! RequestsUpdate)
            }
            buttons.append(buttonThree)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        } else if(current is RivalObj){
            var buttons = [PopupDialogButton]()
            let title = (current as! RivalObj).gamerTag + " wants to play " + (current as! RivalObj).game + "!"
            let message = "what do you wanna do?"
            let manager = FriendsManager()
            
            let buttonOne = DefaultButton(title: "view profile") { [weak self] in
                self?.launchProfile(uid: (current as! RivalObj).uid)
            }
            buttons.append(buttonOne)
            
            let buttonTwo = CancelButton(title: "i'm ready to play") { [weak self] in
                manager.acceptPlayRequest(rival: (current as! RivalObj), callbacks: self as! RequestsUpdate)
            }
            buttons.append(buttonTwo)
            
            let buttonThree = DestructiveButton(title: "not right now") { [weak self] in
                manager.rejectPlayRequest(rival: (current as! RivalObj), callbacks: self as! RequestsUpdate)
            }
            buttons.append(buttonThree)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
    }
    
    struct Section {
        var name: String
        var items: [Any]
        
        init(name: String, items: [Any]?) {
            self.name = name
            self.items = [Any]()
        }
        
        func getCount() -> Int{
            return items.count
        }
    }
        
}
