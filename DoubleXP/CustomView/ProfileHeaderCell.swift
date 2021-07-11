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

class ProfileHeaderCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var more: UIImageView!
    @IBOutlet weak var gamertag: UILabel!
    @IBOutlet weak var consoleCollection: UICollectionView!
    @IBOutlet weak var onlineStatus: UILabel!
    @IBOutlet weak var onlineDot: UIImageView!
    @IBOutlet weak var editProfileTag: UILabel!
    @IBOutlet weak var socialList: UITableView!
    @IBOutlet weak var headerYoutube: UIView!
    @IBOutlet weak var collapse: UIImageView!
    @IBOutlet weak var gtBaseView: UIView!
    @IBOutlet weak var gtBlurView: UIVisualEffectView!
    @IBOutlet weak var videoDrawerBlur: UIVisualEffectView!
    @IBOutlet weak var videoDrawerBase: UIView!
    @IBOutlet weak var channelLoadingBlur: UIVisualEffectView!
    @IBOutlet weak var expand: UIImageView!
    @IBOutlet weak var downVoteButton: UIImageView!
    @IBOutlet weak var upVoteButton: UIImageView!
    @IBOutlet weak var upVoteCount: UILabel!
    @IBOutlet weak var downVoteCount: UILabel!
    @IBOutlet weak var videoCover: UIView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var playingTag: UILabel!
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
        self.socialList.estimatedRowHeight = 30
        self.socialList.rowHeight = UITableView.automaticDimension
        
        if(!list.isEmpty){
            self.socialList.delegate = self
            self.socialList.dataSource = self
        }
        self.reload(tableView: self.socialList)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func centerItemsInCollectionView(cellWidth: Double, numberOfItems: Double, spaceBetweenCell: Double, collectionView: UICollectionView) -> UIEdgeInsets {
        let totalWidth = cellWidth * numberOfItems
        let totalSpacingWidth = spaceBetweenCell * (numberOfItems - 1)
        let leftInset = (collectionView.frame.width - CGFloat(totalWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "console", for: indexPath) as! ProfileConsoleCell
        let current = self.payload[indexPath.item]
        
        if(current == "ps"){
            cell.consoleImg.image = UIImage.init(named: "ps_logo")
        } else if(current == "xbox"){
            cell.consoleImg.image = UIImage.init(named: "xbox_logo")
        } else if(current == "pc"){
            cell.consoleImg.image = UIImage.init(named: "pc_logo")
        } else if(current == "nintendo"){
            cell.consoleImg.image = UIImage.init(named: "nintendo_logo")
        } else {
            cell.consoleImg.image = UIImage.init(named: "mobile_logo")
        }
        
        cell.contentView.layer.cornerRadius = 5.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(30), height: CGFloat(30))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.socialPayload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "social", for: indexPath) as! ProfileSocialListItem
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func reload(tableView: UITableView) {
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.setContentOffset(contentOffset, animated: false)
    }
}
