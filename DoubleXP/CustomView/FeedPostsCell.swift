//
//  FeedPostsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class FeedPostsCell: UITableViewCell {
    @IBOutlet weak var postsCollection: UICollectionView!
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    var payload = [Any]()
    var dataSet = false
    var currentFeed: Feed?
    
    func setPosts(list: [Any], feed: Feed){
        self.payload = list
        self.currentFeed = feed
        
        if(!dataSet){
            self.dataSet = true
            if let layout = postsCollection.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal
            }
            
        }
        //self.cellHeightConstraint.constant = 200
    }
    
    @objc func test(){
        self.currentFeed!.launchVideoMessage()
    }
}
