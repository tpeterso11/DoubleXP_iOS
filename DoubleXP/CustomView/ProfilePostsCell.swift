//
//  ProfilePostsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/11/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import collection_view_layouts

class ProfilePostsCell : UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var postsCollection: UICollectionView!
    var payload = [Any]()
    var dataSet = false
    var currentProfile: PlayerProfile?
    
    func setPosts(list: [PostObject], currentProfile: PlayerProfile?){
        payload = list
        self.currentProfile = currentProfile
        
        if(payload.count >= 3){
            self.cellHeight.constant = 500
            self.payload.append("empty")
        }  else if(payload.count >= 1){
            self.cellHeight.constant = 300
            self.payload.append("empty")
        }
        
        if(payload.isEmpty){
            self.postsCollection.isHidden = true
            self.emptyView.isHidden = false
        } else {
            self.postsCollection.isHidden = false
            self.emptyView.isHidden = true
            if(!dataSet){
                self.dataSet = true
                //self.postsCollection.collectionViewLayout = InstagramLayout()
                self.postsCollection.delegate = self
                self.postsCollection.dataSource = self
            } else {
                self.postsCollection.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        
        if(current as? String == "empty"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! PostEmptyCell
            cell.layer.cornerRadius = 10
            return cell
        } else {
            let currentPost = current as! PostObject
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! ProfilePostCell
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: currentPost.youtubeImg as NSString) != nil){
                cell.postImg.image = cache.object(forKey: currentPost.youtubeImg as NSString)
            } else {
                cell.postImg.moa.onSuccess = { image in
                    cell.postImg.image = image
                    appDelegate.imageCache.setObject(image, forKey: currentPost.youtubeImg as NSString)
                    return image
                }
                cell.postImg.moa.url = currentPost.youtubeImg
            }
            cell.postImg.contentMode = .scaleToFill
            cell.postImg.layer.cornerRadius = 10
            cell.postImg.clipsToBounds = true
            cell.layer.cornerRadius = 10
            
            if(currentPost.postConsole == "ps"){
                cell.consoleImg.image = UIImage.init(named: "ps_logo")
            } else if(currentPost.postConsole == "xbox"){
                cell.consoleImg.image = UIImage.init(named: "xbox_logo")
            } else if(currentPost.postConsole == "pc"){
                cell.consoleImg.image = UIImage.init(named: "pc_logo")
            } else if(currentPost.postConsole == "nintendo"){
                cell.consoleImg.image = UIImage.init(named: "nintendo_logo")
            } else {
                cell.consoleImg.image = UIImage.init(named: "mobile_logo")
            }
            
            if(!currentPost.date.isEmpty){
                cell.daysAgo.alpha = 1
                let milisecond = Int64(currentPost.date)
                if(milisecond != nil){
                    let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milisecond!)/1000)
                    cell.daysAgo.text = dateVar.timeAgoSinceDate()
                } else {
                    cell.daysAgo.alpha = 0
                }
            } else {
                cell.daysAgo.alpha = 0
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        if(current is PostObject){
            self.currentProfile!.launchPostView(currentPost: current as! PostObject)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
                let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
                let size:CGFloat = (collectionView.frame.size.width - space) / 2.0
                return CGSize(width: size, height: 220)
    }
}

extension Date {

    func timeAgoSinceDate() -> String {

        // From Time
        let fromDate = self

        // To Time
        let toDate = Date()

        // Estimation
        // Year
        if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
        }

        // Month
        if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
        }

        // Day
        if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
        }

        // Hours
        if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {

            return interval == 1 ? "\(interval)" + " " + "hour ago" : "\(interval)" + " " + "hours ago"
        }

        // Minute
        if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {

            return interval == 1 ? "\(interval)" + " " + "minute ago" : "\(interval)" + " " + "minutes ago"
        }

        return "a moment ago"
    }
}
