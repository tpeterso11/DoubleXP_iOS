//
//  DiscoverGameQuickReviewsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/23/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class DiscoverGameQuickReviewsCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var usersButton: UIButton!
    @IBOutlet weak var reviewsCollection: UICollectionView!
    var payload = [NewsObject]()
    
    func setPayload(payload: [NewsObject]){
        self.payload = payload
        
        self.reviewsCollection.delegate = self
        self.reviewsCollection.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = payload[indexPath.item]
        if(current.storyText == "none"){
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
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "review", for: indexPath) as! DiscoverQuickReviewCell
            
            cell.reviewer.text = current.author
            cell.rating.text = current.imageUrl
            cell.review.text = current.storyText
            cell.source.text = current.title
            
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
            
            if let n = NumberFormatter().number(from: current.imageUrl) {
                let f = CGFloat(truncating: n)
                switch traitCollection.userInterfaceStyle {
                    case .light, .unspecified:
                        cell.ratingImage.image = mapRatingToImage(input: f, dark: false)
                    case .dark:
                        cell.ratingImage.image = mapRatingToImage(input: f, dark: true)
                }
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = payload[indexPath.item]
        if(current.storyText == "none"){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        } else {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(150))
        }
    }
    
    private func mapRatingToImage(input: CGFloat, dark: Bool) -> UIImage {
        if(dark){
            if(input < 5){
                return #imageLiteral(resourceName: "thumb-down.png")
            } else {
                return #imageLiteral(resourceName: "thumbs-up.png")
            }
        } else {
            if(input < 5){
                return #imageLiteral(resourceName: "thumb-down (1).png")
            } else {
                return #imageLiteral(resourceName: "thumbs_up")
            }
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
