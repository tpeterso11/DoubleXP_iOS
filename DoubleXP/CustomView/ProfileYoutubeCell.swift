//
//  ProfileYoutubeCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/25/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import moa

class ProfileYoutubeCell : UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var videoList: UICollectionView!
    @IBOutlet weak var expand: UIImageView!
    @IBOutlet weak var videoDrawer: UIView!
    var videoPayload = [YoutubeVideoObj]()
    var infoSet = false
    var currentProfile: PlayerProfile?
    
    func setVideos(payload: [YoutubeVideoObj], currentProfile: PlayerProfile?){
        self.videoPayload = payload
        self.currentProfile = currentProfile
        if(!infoSet){
            infoSet = true
            self.videoList.delegate = self
            self.videoList.dataSource = self
        } else {
            self.videoList.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoPayload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.videoPayload[indexPath.item]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "video", for: indexPath) as! ProfileYoutubeVideoCell
        if(cache.object(forKey: current.youtubeImg as NSString) != nil){
            cell.videoImg.image = cache.object(forKey: current.youtubeImg as NSString)
        } else {
            cell.videoImg.image = Utility.Image.placeholder
            cell.videoImg.moa.onSuccess = { image in
                cell.videoImg.image = image
                appDelegate.imageCache.setObject(image, forKey: current.youtubeImg as NSString)
                return image
            }
            cell.videoImg.moa.url = current.youtubeImg
        }
        
        if(self.currentProfile != nil && self.currentProfile!.currentVideoPlaying != nil){
            if(self.currentProfile!.currentVideoPlaying!.youtubeId == current.youtubeId){
                cell.playingAnimation.alpha = 1
                cell.playingAnimation.loopMode = .loop
                if(currentProfile!.videoPaused){
                    cell.playingAnimation.pause()
                } else {
                    cell.playingAnimation.play()
                }
            } else {
                cell.playingAnimation.alpha = 0
                cell.playingAnimation.pause()
            }
        } else {
            cell.playingAnimation.alpha = 0
            cell.playingAnimation.pause()
        }
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.videoPayload[indexPath.item]
        self.currentProfile!.changeChannel(selectedVideoId: current.youtubeId)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: CGFloat(80), height: CGFloat(80))
    }
}
