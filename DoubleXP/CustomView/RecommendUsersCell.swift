//
//  RecommendUsersCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/29/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class RecommendUsersCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var usersCollection: UICollectionView!
    var payload: [Any]!
    var infoSet = false
    var recommeded: Recommeded?
    
    func setPayload(payload: [Any], recommeded: Recommeded){
        self.payload = payload
        self.recommeded = recommeded
        
        if(!infoSet){
            self.usersCollection.dataSource = self
            self.usersCollection.delegate = self
            self.infoSet = true
        } else {
            self.usersCollection.reloadData()
            /*let top = CGAffineTransform(translationX: 0, y: -40)
            let top2 = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.usersCollection.transform = top
                self.usersCollection.alpha = 0
            }, completion: { (finished: Bool) in
                self.usersCollection.reloadData()
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.usersCollection.transform = top2
                        self.usersCollection.alpha = 1
                }, completion: nil)
            })*/
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        if(current is User){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "user", for: indexPath) as! RecommendedUserCell
            let currentUser = (current as! User)
            cell.gamertag.text = currentUser.gamerTag
            
            if(self.recommeded!.currentSelection == "best"){
                cell.typeColor.backgroundColor = #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
                cell.reasonDesc.text = "based on many factors, this player is a great match!"
            }
            if(self.recommeded!.currentSelection == "location"){
                cell.typeColor.backgroundColor = #colorLiteral(red: 0.6423664689, green: 0, blue: 0.04794860631, alpha: 1)
                cell.reasonDesc.text = "you guys are close to each other, and can like similar games!"
            }
            if(self.recommeded!.currentSelection == "lucky"){
                cell.typeColor.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
                cell.reasonDesc.text = "based on our math...this person has potential."
            }
            cell.contentView.layer.cornerRadius = 15.0
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
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "game", for: indexPath) as! RecommendGameCell
            let currentGame = (current as! GamerConnectGame)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            
            var url = ""
            if(!currentGame.alternateImageUrl.isEmpty){
                url = currentGame.alternateImageUrl
            } else {
                url = currentGame.imageUrl
            }
            
            if(cache.object(forKey: url as NSString) != nil){
                cell.gameBack.image = cache.object(forKey: url as NSString)
            } else {
                cell.gameBack.image = Utility.Image.placeholder
                cell.gameBack.moa.onSuccess = { image in
                    cell.gameBack.image = image
                    appDelegate.imageCache.setObject(image, forKey: url as NSString)
                    return image
                }
                cell.gameBack.moa.url = url
            }
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameName.text = currentGame.gameName
            
            cell.contentView.layer.cornerRadius = 15.0
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        if(current is GamerConnectGame){
            self.recommeded?.launchGamePage(game: (current as! GamerConnectGame))
        } else {
            self.recommeded?.launchProfileForUser(uid: (current as! User).uId)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(250), height: CGFloat(350))
    }
}
