//
//  CommunityReviews.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import Lottie

class CommunityReviews : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var loadingAnimation: AnimationView!
    @IBOutlet weak var loadingView: UIVisualEffectView!
    @IBOutlet weak var reviewsList: UICollectionView!
    var game: GamerConnectGame!
    var payload = [NewsObject]()
    var reviewContained = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.loadingAnimation.loopMode = .loop
        self.loadingAnimation.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.getReviews(game: self.game)
        }
    }
    
    func getReviews(game: GamerConnectGame){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        let ref = Database.database().reference().child("Reviews").child(game.gameName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for review in snapshot.children{
                    self.payload = [NewsObject]()
                    let current = review as! DataSnapshot
                    if(current.hasChild("uid")){
                        let reviewAuthor = current.childSnapshot(forPath: "uid").value as? String ?? ""
                        if(delegate.currentUser!.uId == reviewAuthor){
                            self.reviewContained = true
                        }
                    }
                    if(current.hasChild("title") && current.hasChild("author") && current.hasChild("imageUrl") && current.hasChild("storyText")){
                        let newReview = NewsObject(title: current.childSnapshot(forPath: "title").value as? String ?? "", author: current.childSnapshot(forPath: "author").value as? String ?? "", storyText: current.childSnapshot(forPath: "storyText").value as? String ?? "", imageUrl: current.childSnapshot(forPath: "imageUrl").value as? String ?? "")
                        
                        newReview.uid = current.childSnapshot(forPath: "uid").value as? String ?? ""
                        //add uid to this object so we can track whether this user wrote a review easier.
                        self.payload.append(newReview)
                    }
                }
                
                self.reviewsList.dataSource = self
                self.reviewsList.delegate = self
                UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    self.loadingView.alpha = 0
                    self.loadingAnimation.pause()
                }, completion: nil)
            
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        
        if(current.storyText != "none"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "review", for: indexPath) as! ReviewCellLarge
            cell.author.text = current.author
            cell.ratingBar.rating = Double(current.imageUrl) ?? 0.0
            cell.review.text = current.storyText
            
            cell.ratingDesc.text = mapRatingToDesc(value: Double(current.imageUrl)  ?? 0.0 )
            
            cell.contentView.layer.cornerRadius = 10.0
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
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "rating", for: indexPath) as! ReviewCellLarge
            cell.author.text = current.author
            cell.ratingBar.rating = Double(current.imageUrl) ?? 0.0
            cell.ratingDesc.text = mapRatingToDesc(value: Double(current.imageUrl)  ?? 0.0 )
            
            cell.contentView.layer.cornerRadius = 10.0
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
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.payload[indexPath.item]
        if(current.storyText != "none"){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(200))
        } else {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        }
    }
    
    private func mapRatingToDesc(value: Double) -> String {
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
}
