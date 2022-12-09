//
//  PlayHeaderCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/18/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class PlayHeaderCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var payload = [CompetitionObj]()
    var dataSet = false
    @IBOutlet weak var playCollection: UICollectionView!
    @IBOutlet weak var compBg: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    var playModal: PlayModal?
    
    
    func setList(list: [CompetitionObj], modal: PlayModal){
        self.payload = list
        self.playModal = modal
        
        if(!dataSet && !list.isEmpty){
            dataSet = true
            playCollection.delegate = self
            playCollection.dataSource = self
            self.emptyView.isHidden = true
            self.playCollection.isHidden = false
        } else if(!list.isEmpty) {
            playCollection.reloadData()
            self.emptyView.isHidden = true
            self.playCollection.isHidden = false
        } else {
            self.emptyView.isHidden = false
            self.playCollection.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "comp", for: indexPath) as! PlayCompCell
        
        let currentComp = payload[indexPath.item]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: currentComp.headerImgUrl as NSString) != nil){
            cell.compBg.image = cache.object(forKey: currentComp.headerImgUrl as NSString)
        } else {
            cell.compBg.image = Utility.Image.placeholder
            cell.compBg.moa.onSuccess = { image in
                cell.compBg.image = image
                appDelegate.imageCache.setObject(image, forKey: currentComp.headerImgUrl as NSString)
                return image
            }
            cell.compBg.moa.url = currentComp.headerImgUrl
        }
        cell.compBg.contentMode = .scaleToFill
        cell.compBg.clipsToBounds = true
        
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.init(named: "darkToWhite")?.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        cell.layer.shadowRadius = 5.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = payload[indexPath.item]
        playModal?.launchCompPage(currentComp: current)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 360, height: CGFloat(140))
    }
}
