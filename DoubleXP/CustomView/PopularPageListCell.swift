//
//  PopularPageListCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/2/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import collection_view_layouts

class PopularPageListCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var videoCollection: UICollectionView!
    var payload = [YoutubeVideoObj]()
    var dataSet = false
    
    
    func setVideoPayload(incoming: [YoutubeVideoObj]){
        self.payload = incoming
        
        if(!dataSet){
            self.dataSet = true
            self.videoCollection.collectionViewLayout = InstagramLayout()
            self.videoCollection.delegate = self
            self.videoCollection.dataSource = self
        } else {
            self.videoCollection.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = payload[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "basic", for: indexPath) as! PopularPageBasicCell
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        
        if(cache.object(forKey: current.youtubeImg as NSString) != nil){
            cell.youtubeImg.image = cache.object(forKey: current.youtubeImg as NSString)
        } else {
            cell.youtubeImg.image = Utility.Image.placeholder
            cell.youtubeImg.moa.onSuccess = { image in
                cell.youtubeImg.image = image
                appDelegate.imageCache.setObject(image, forKey: current.youtubeImg as NSString)
                return image
            }
            cell.youtubeImg.moa.url = current.youtubeImg
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 120)
    }
}
