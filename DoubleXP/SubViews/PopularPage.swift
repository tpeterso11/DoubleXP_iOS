//
//  PopularPage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/30/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import FirebaseDatabase
import collection_view_layouts

class PopularPage: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var loadingScreen: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: AnimationView!
    @IBOutlet weak var popularTable: UICollectionView!
    @IBOutlet weak var empty: UIView!
    var payload = [YoutubeVideoObj]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.5, animations: {
                self.loadingAnimation.alpha = 1
                self.loadingAnimation.play()
            }, completion: { (finished: Bool) in
                self.getVideos()
            })
        }
    }
    
    private func buildPayload(){
        self.popularTable.collectionViewLayout = InstagramLayout()
        self.popularTable.delegate = self
        self.popularTable.dataSource = self
        self.popularTable.reloadData()
        
        if(self.payload.isEmpty){
            self.empty.alpha = 1
        } else {
            self.empty.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingAnimation.alpha = 0
                self.loadingAnimation.pause()
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.loadingScreen.alpha = 0
                }, completion: nil)
            })
        }
    }
    
    private func getVideos(){
        let ref = Database.database().reference().child("YoutubeSubmissions")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for user in snapshot.children {
                let videoArray = snapshot.childSnapshot(forPath: (user as! DataSnapshot).key)
                var currentVideos = [YoutubeVideoObj]()
                for video in videoArray.children {
                    let currentVid = video as! DataSnapshot
                    let dict = currentVid.value as! [String: Any]
                    let videoOwnerGt = dict["videoOwnerGamerTag"] as? String ?? ""
                    let videoOwnerUid = dict["videoOwnerUid"] as? String ?? ""
                    let youtubeFavorite = dict["youtubeFavorite"] as? String ?? ""
                    let youtubeId = dict["youtubeId"] as? String ?? ""
                    let youtubeImg = dict["youtubeImg"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let downVotes = dict["downVotes"] as? [String] ?? [String]()
                    let upVotes = dict["upVotes"] as? [String] ?? [String]()
                    let title = dict["title"] as? String ?? ""
                    
                    let newVid = YoutubeVideoObj(title: title, videoOwnerGamerTag: videoOwnerGt, videoOwnerUid: videoOwnerUid, youtubeFavorite: youtubeFavorite, date: date, youtubeId: youtubeId, imgUrl: youtubeImg)
                    newVid.downVotes = downVotes
                    newVid.upVotes = upVotes
                    currentVideos.append(newVid)
                }
                self.payload.append(contentsOf: currentVideos)
            }
            
            /*sorting logic*/
            
            
            self.buildPayload()
        })
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
