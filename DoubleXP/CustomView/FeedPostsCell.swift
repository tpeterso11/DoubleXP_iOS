//
//  FeedPostsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class FeedPostsCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var postsCollection: UICollectionView!
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    var payload = [Any]()
    var dataSet = false
    
    func setPosts(list: [Any]){
        self.payload = list
        
        if(!dataSet){
            self.dataSet = true
            if let layout = postsCollection.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal
            }
            self.postsCollection.delegate = self
            self.postsCollection.dataSource = self
            self.postsCollection.reloadData()
        } else {
            self.postsCollection.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        if(current is String){
            if((current as! String) == "view"){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "view", for: indexPath) as! FeedMorePostsCell
                cell.moreAnimation.loopMode = .playOnce
                cell.moreAnimation.play()
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! FeedPostCell
                return cell
            }
        } else {
            let currentPost = (current as! PostObject)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! FeedPostCell
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: currentPost.youtubeImg as NSString) != nil){
                cell.postBackground.image = cache.object(forKey: currentPost.youtubeImg as NSString)
            } else {
                cell.postBackground.image = Utility.Image.placeholder
                cell.postBackground.moa.onSuccess = { image in
                    cell.postBackground.image = image
                    appDelegate.imageCache.setObject(image, forKey: currentPost.youtubeImg as NSString)
                    return image
                }
                cell.postBackground.moa.url = currentPost.youtubeImg
            }
            
            //cell.contentView.layer.cornerRadius = 20.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.8
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            cell.message.text = currentPost.title
            cell.fireAnimation.loopMode = .playOnce
            cell.fireAnimation.play()
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 230, height: 150)
    }
}
