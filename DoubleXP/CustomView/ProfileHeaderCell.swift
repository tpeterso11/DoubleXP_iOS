//
//  ProfileHeaderCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import youtube_ios_player_helper
import Lottie

class ProfileHeaderCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var youtubeLoadingAnimation: LottieAnimationView!
    @IBOutlet weak var youtubeLoadingBlur: UIVisualEffectView!
    @IBOutlet weak var more: UIImageView!
    @IBOutlet weak var gamertag: UILabel!
    @IBOutlet weak var consoleCollection: UICollectionView!
    @IBOutlet weak var onlineStatus: UILabel!
    @IBOutlet weak var onlineDot: UIImageView!
    @IBOutlet weak var editProfileTag: UILabel!
    @IBOutlet weak var headerYoutube: UIView!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var gtBaseView: UIView!
    @IBOutlet weak var videoCover: UIView!
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var playingTag: UILabel!
    @IBOutlet weak var socialList: UICollectionView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var defaultBackgroundImg: UIImageView!
    var payload = [String]()
    var socialPayload = [Any]()
    var collapsed = false
    
    
    func setConsoles(consoles: [String]){
        self.payload = consoles
        self.consoleCollection.delegate = self
        self.consoleCollection.dataSource = self
    }
    
    func setSocial(list: [Any], set: Bool){
        self.socialPayload = list
        
        if(!list.isEmpty){
            self.socialList.delegate = self
            self.socialList.dataSource = self
        }
        self.socialList.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == self.socialList){
            return self.socialPayload.count
        } else {
            return payload.count
        }
    }
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if(collectionView == self.socialList){
            let totalCellWidth = CGFloat(150) * CGFloat(self.socialPayload.count)
            let totalSpacingWidth = CGFloat(0) * (CGFloat(self.socialPayload.count) - 1)

            let leftInset = ((collectionView.bounds.width) - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset

            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        } else {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }*/
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == consoleCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "console", for: indexPath) as! ProfileConsoleCell
            let current = self.payload[indexPath.item]
            
            if(current == "ps"){
                cell.consoleImg.image = UIImage(imageLiteralResourceName: "playstation-logotype (1)")
            } else if(current == "xbox"){
                cell.consoleImg.image = UIImage(imageLiteralResourceName: "xbox-logo (1)")
            } else if(current == "pc"){
                cell.consoleImg.image = UIImage(imageLiteralResourceName: "pc-logo")
            } else if(current == "nintendo"){
                cell.consoleImg.image = UIImage(imageLiteralResourceName: "nintendo-switch")
            } else {
                cell.consoleImg.image = UIImage(imageLiteralResourceName: "phone-white")
            }
            
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "social", for: indexPath) as! ProfileSocialListItem
            let current = socialPayload[indexPath.item]
            if(current is TwitchAddedObject){
                cell.socialLabel.text = "@"+(current as! TwitchAddedObject).twitchId!
                cell.socialIcon.image = #imageLiteral(resourceName: "twitch_logo_light.png")
            } else if(current is DiscordAddedObject){
                cell.socialLabel.text = "@"+(current as! DiscordAddedObject).handle!
                cell.socialIcon.image = #imageLiteral(resourceName: "discord.png")
            } else if(current is InstaAddedObject){
                cell.socialLabel.text = "@"+(current as! InstaAddedObject).instaId!
                cell.socialIcon.image = #imageLiteral(resourceName: "instagram.png")
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == self.consoleCollection){
            return CGSize(width: CGFloat(30), height: CGFloat(30))
        } else {
            let current = self.socialPayload[indexPath.item]
            var width = 150
            return CGSize(width: CGFloat(collectionView.frame.size.width), height: CGFloat(20))
        }
    }
}
