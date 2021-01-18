//
//  DiscoverFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController

class DiscoverFrag : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DiscoverCallbacks, SPStorkControllerDelegate {
    @IBOutlet weak var discoverHeader: UILabel!
    @IBOutlet weak var discoverSub: UILabel!
    @IBOutlet weak var discoverCollection: UICollectionView!
    var payload = Array<(key: Int, value: Any)>()
    var currentPos = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentDiscoverFrag = self
        DiscoverManager().getDiscoverHomeInfo(callbacks: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = Array(payload)[indexPath.item].value
        if(current is GamerConnectGame){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featured", for: indexPath) as! DiscoveredFeaturedCell
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: (current as! GamerConnectGame).imageUrl as NSString) != nil){
                cell.gameBack.image = cache.object(forKey: (current as! GamerConnectGame).imageUrl as NSString)
            } else {
                cell.gameBack.image = Utility.Image.placeholder
                cell.gameBack.moa.onSuccess = { image in
                    cell.gameBack.image = image
                    appDelegate.imageCache.setObject(image, forKey: (current as! GamerConnectGame).imageUrl as NSString)
                    return image
                }
                cell.gameBack.moa.url = (current as! GamerConnectGame).imageUrl
            }
            
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameBack.clipsToBounds = true
            
            cell.featuredGameName.text = (current as! GamerConnectGame).gameName
            
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
        } else if (current is DiscoverCategory){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as! DiscoverCategoryCell
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: (current as! DiscoverCategory).imgUrl as NSString) != nil){
                cell.categoryBack.image = cache.object(forKey: (current as! DiscoverCategory).imgUrl as NSString)
            } else {
                cell.categoryBack.image = Utility.Image.placeholder
                cell.categoryBack.moa.onSuccess = { image in
                    cell.categoryBack.image = image
                    appDelegate.imageCache.setObject(image, forKey: (current as! DiscoverCategory).imgUrl as NSString)
                    return image
                }
                cell.categoryBack.moa.url = (current as! DiscoverCategory).imgUrl
            }
            
            cell.categoryBack.contentMode = .scaleAspectFill
            cell.categoryBack.clipsToBounds = true
            
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
            
            cell.category.text = (current as! DiscoverCategory).categoryName
            return cell
        } else {
            let currentEmpty = (current as? Int ?? 0)
            if(currentEmpty == 0){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty_large", for: indexPath) as! EmptyCellLarge
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty_small", for: indexPath) as! EmptyCollectionViewCell
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = Array(payload)[indexPath.item].value
        if(current is DiscoverCategory){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverCategory") as! DiscoveryCategoryFrag
            currentViewController.category = (current as! DiscoverCategory)
            
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        } else if (current is GamerConnectGame){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverGame") as! DiscoverGamePage
            currentViewController.game = (current as! GamerConnectGame)
            
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = Array(payload)[indexPath.item].value
        if(current is GamerConnectGame){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(180))
        } else if(current is DiscoverCategory){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(120))
        } else {
            let currentInt = (current as! Int)
            if(currentInt == 0){
                return CGSize(width: collectionView.bounds.size.width, height: CGFloat(24))
            } else {
                return CGSize(width: collectionView.bounds.size.width, height: CGFloat(8))
            }
        }
    }
    
    func onSuccess(discoverPayload: [Int: Any]) {
        let booga = discoverPayload.sorted(by: { $0.key < $1.key })
        self.payload = booga
        DispatchQueue.main.async {
            self.discoverCollection.delegate = self
            self.discoverCollection.dataSource = self
        }
    }
    
    func onFailure() {
        //show error
    }
    
}
