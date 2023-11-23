//
//  RatingDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Cosmos
import FirebaseDatabase
import Lottie
import SwiftNotificationCenter

class RatingDrawer: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var reviewHolder: UIView!
    @IBOutlet weak var badge: UIImageView!
    @IBOutlet weak var oldView: UIButton!
    @IBOutlet weak var oldClose: UIButton!
    @IBOutlet weak var newView: UIButton!
    @IBOutlet weak var newClose: UIButton!
    @IBOutlet weak var oldReviewerLayout: UIView!
    @IBOutlet weak var newReviewerLayout: UIView!
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    @IBOutlet weak var loadingView: UIVisualEffectView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var ratingFeedback: UILabel!
    @IBOutlet weak var review: UITextView!
    @IBOutlet weak var rating: CosmosView!
    var currentRating = 0.0
    var game: GamerConnectGame!
    var isReview = false
    var drawerOpen = false
    var drawerHeight: CGFloat!
    var badgeEligible = false
    var baseText = "leave a quick review (optional)"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        review.text = baseText
        review.textColor = UIColor.lightGray
        
        self.submit.alpha = 0.3
        self.submit.isUserInteractionEnabled = false
        
        self.reviewHolder.layer.shadowColor = UIColor.black.cgColor
        self.reviewHolder.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.reviewHolder.layer.shadowRadius = 2.0
        self.reviewHolder.layer.shadowOpacity = 0.5
        self.reviewHolder.layer.masksToBounds = false
        self.reviewHolder.layer.shadowPath = UIBezierPath(roundedRect: self.reviewHolder.bounds, cornerRadius: self.reviewHolder.layer.cornerRadius).cgPath
        
        self.review.delegate = self
        
        rating.didFinishTouchingCosmos = { rating in
            self.currentRating = rating
            self.ratingFeedback.text = self.mapRatingToFeedback(value: rating)
            self.updateSubmit(value: rating)
        }
        
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
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            self.drawerHeight = keyboardHeight
            
            extendBottom(height: self.drawerHeight)
        }
    }
    
    @objc func keyboardWillDisappear() {
        let top = CGAffineTransform(translationX: 0, y: 50)
        UIView.animate(withDuration: 0.5, animations: {
            self.submit.transform = top
        }, completion: nil)
    }
    
    private func extendBottom(height: CGFloat){
        let top = CGAffineTransform(translationX: 0, y: -height + 20)
        UIView.animate(withDuration: 0.8, animations: {
            self.submit.transform = top
        }, completion: nil)
    }
    
    private func submitReview(){
        self.view.endEditing(true)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var review = "none"
        if(self.review.text != "leave a quick review (optional)" && !self.review.text.isEmpty){
            self.isReview = true
            review = ProfanityFilter.sharedInstance.cleanUp(self.review.text)
        }
        
        let ref = Database.database().reference().child("Reviews").child(game.gameName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var reviewList = [NewsObject]()
                var contained = false
                for review in snapshot.children {
                    let current = review as! DataSnapshot
                    if(current.hasChild("author")){
                        let reviewAuthor = current.childSnapshot(forPath: "author").value as? String ?? ""
                        if(appDelegate.currentUser!.gamerTag == reviewAuthor){
                            contained = true
                        }
                    }
                    if(current.hasChild("title") && current.hasChild("author") && current.hasChild("imageUrl") && current.hasChild("storyText")){
                        let newReview = NewsObject(title: current.childSnapshot(forPath: "title").value as? String ?? "", author: current.childSnapshot(forPath: "author").value as? String ?? "", storyText: current.childSnapshot(forPath: "storyText").value as? String ?? "", imageUrl: current.childSnapshot(forPath: "imageUrl").value as? String ?? "")
                        newReview.uid = current.childSnapshot(forPath: "uid").value as? String ?? ""
                        reviewList.append(newReview)
                    }
                }
                
                if(!contained){
                    var array = [[String: String]]()
                    for review in reviewList {
                        let sendUp = ["title": review.title, "author": review.author, "storyText": review.storyText, "imageUrl": review.imageUrl, "uid": review.uid]
                        array.append(sendUp)
                    }
                    let sendUp = ["title": "community", "author": appDelegate.currentUser!.gamerTag, "storyText": review, "imageUrl": String(self.currentRating), "uid": appDelegate.currentUser!.uId]
                    array.append(sendUp)
                    
                    ref.setValue(array)
                    self.getBadgeInfo()
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                var array = [[String: String]]()
                let sendUp = ["title": "community", "author": appDelegate.currentUser!.gamerTag, "storyText": review, "imageUrl": String(self.currentRating), "uid": appDelegate.currentUser!.uId]
                array.append(sendUp)
                
                ref.setValue(array)
                
                self.getBadgeInfo()
            }
        })
    }
    
    private func updateSubmit(value: Double){
        if(value > 0.0 && self.submit.alpha != 1){
            UIView.animate(withDuration: 0.3, animations: {
                self.submit.alpha = 1.0
                self.submit.isUserInteractionEnabled = true
                self.submit.addTarget(self, action: #selector(self.showWork), for: .touchUpInside)
            })
        } else if(value > 0.0){
            self.submit.alpha = 1.0
        } else if(value == 0.0 && self.submit.alpha == 1){
            UIView.animate(withDuration: 0.3, animations: {
                self.submit.alpha = 0.3
                self.submit.isUserInteractionEnabled = false
            })
        } else {
            self.submit.alpha = 0.3
        }
    }
    
    @objc private func showWork(){
        self.view.endEditing(true)
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.loadingView.alpha = 1
            self.loadingAnimation.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                self.submitReview()
            }
        }, completion: nil)
    }
    
    private func showSent(){
        if(self.isReview){
            getBadgeInfo()
        } else {
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingAnimation.alpha = 0
                self.loadingAnimation.stop()
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.oldReviewerLayout.alpha = 1
                    self.oldClose.addTarget(self, action: #selector(self.closeClicked), for: .touchUpInside)
                    self.oldView.addTarget(self, action: #selector(self.viewClicked), for: .touchUpInside)
                })
            })
        }
    }
    
    private func getBadgeInfo(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if(snapshot.hasChild("reviews")){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(!appDelegate.currentUser!.reviews.contains(self.game.gameName)){
                    appDelegate.currentUser!.reviews.append(self.game.gameName)
                }
                ref.child("reviews").setValue(appDelegate.currentUser!.reviews)
                
                UIView.animate(withDuration: 0.8, animations: {
                    self.loadingAnimation.alpha = 0
                    self.loadingAnimation.stop()
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.oldReviewerLayout.alpha = 1
                        self.oldClose.addTarget(self, action: #selector(self.closeClicked), for: .touchUpInside)
                        self.oldView.addTarget(self, action: #selector(self.viewClicked), for: .touchUpInside)
                    })
                })
            } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(!appDelegate.currentUser!.reviews.contains(self.game.gameName)){
                    appDelegate.currentUser!.reviews.append(self.game.gameName)
                }
                ref.child("reviews").setValue(appDelegate.currentUser!.reviews)
                
                self.giveReviewBadge()
                
                self.newClose.addTarget(self, action: #selector(self.closeClicked), for: .touchUpInside)
                self.newView.addTarget(self, action: #selector(self.viewClicked), for: .touchUpInside)
            
                UIView.animate(withDuration: 0.5, animations: {
                    self.loadingAnimation.alpha = 0
                }, completion: { (finished: Bool) in
                    self.loadingAnimation.stop()
                    
                    UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                        self.newReviewerLayout.alpha = 1
                        
                        let top2 = CGAffineTransform(translationX: 0, y: 60)
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                            self.badge.transform = top2
                            self.badge.alpha = 1
                        }, completion: nil)
                    })
                })
            }
        })
    }
    
    @objc private func viewClicked(){
        self.dismiss(animated: true, completion: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentDiscoverGamePage?.showRatingsFromModal()
        })
    }
    
    @objc private func closeClicked(){
        self.dismiss(animated: true, completion: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentDiscoverGamePage?.modalDismissed()
        })
    }
    
    private func giveReviewBadge(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("badges")){
                var contained = false
                var badges = [BadgeObj]()
                for badge in snapshot.childSnapshot(forPath: "badges").children {
                    let current = badge as! DataSnapshot
                    if(current.hasChild("name")){
                        let name = current.childSnapshot(forPath: "badgeName").value as? String ?? ""
                        let desc = current.childSnapshot(forPath: "badgeDesc").value as? String ?? ""
                        let badge = BadgeObj(badge: name, badgeDesc: desc)
                        if(name == "Reviewer"){
                            contained = true
                        }
                        badges.append(badge)
                    }
                }
                if(!contained){
                    let newBadge = BadgeObj(badge: "Reviewer", badgeDesc: "wrote review on doublexp game")
                    badges.append(newBadge)
                    var sendUp = [[String: String]]()
                    for badge in badges {
                        let paylaod = ["badgeName": badge.badgeName, "badgeDesc": badge.badgeDesc]
                        sendUp.append(paylaod)
                    }
                    ref.child("badges").setValue(sendUp)
                }
            } else {
                var badges = [BadgeObj]()
                let newBadge = BadgeObj(badge: "Reviewer", badgeDesc: "wrote review on doublexp game")
                badges.append(newBadge)
                
                var sendUp = [[String: String]]()
                for badge in badges {
                    let paylaod = ["badgeName": badge.badgeName, "badgeDesc": badge.badgeDesc]
                    sendUp.append(paylaod)
                }
                ref.child("badges").setValue(sendUp)
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let newBadge = BadgeObj(badge: "Reviewer", badgeDesc: "wrote review on doublexp game")
            appDelegate.currentUser!.badges.append(newBadge)
        })
    }
    
    private func mapRatingToFeedback(value: Double) -> String {
        switch value {
        case 0..<3:
            return "we will not speak of this game again."
        case 3:
            return "it was good...not great."
        case 4:
            return "great game. seriously."
        default:
            return "masterpiece."
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor(named: "darkToWhite")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "leave a quick review (optional)"
            textView.textColor = UIColor.lightGray
        }
    }
}
