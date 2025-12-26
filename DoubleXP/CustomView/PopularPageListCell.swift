//
//  PopularPageListCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/2/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class PopularPageListCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var videoCollection: UICollectionView!
    var payload = [YoutubeVideoObj]()
    var dataSet = false
    
    
    func setVideoPayload(incoming: [YoutubeVideoObj]){
        self.payload = incoming
        
        if(!dataSet){
            self.dataSet = true
            //self.videoCollection.collectionViewLayout = InstagramLayout()
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
        /*let url = URL(string: url)
        if (url != nil) {
            ImageLoader.shared.loadImage(from: current.youtubeImg) { [weak self] image in
                guard let self = self else { return }
                cell.youtubeImg.image = image
            }
        }*/
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 120)
    }
}
