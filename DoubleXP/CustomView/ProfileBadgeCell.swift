//
//  ProfileBadgeCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/27/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileBadgeCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var badgeCollection: UICollectionView!
    var payload = [BadgeObj]()
    
    func setBadges(payload: [BadgeObj]){
        self.payload = payload
        
        self.badgeCollection.dataSource = self
        self.badgeCollection.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "badge", for: indexPath) as! ProfileBadgeCollectionCell
        let current = payload[indexPath.item]
        
        cell.badgeDesc.text = current.badgeName
        if(current.badgeName == "Reviewer"){
            cell.badgeImage.image = #imageLiteral(resourceName: "best.png")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(110), height: CGFloat(70))
    }
}
