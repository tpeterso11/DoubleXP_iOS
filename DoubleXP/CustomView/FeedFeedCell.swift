//
//  FeedFeedCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FBSDKCoreKit

class FeedFeedCell : UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var feedCollection: UICollectionView!
    var secondaryPayload = [Any]()
    var feedFrag: Feed!
    var dataSet = false
    
    func setupView(feed: Feed){
        self.feedFrag = feed
        buildSecondaryPayload()
    }
    
    private func buildSecondaryPayload(){
        secondaryPayload = [Any]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.announcementManager
        let defaults = UserDefaults.standard
        var currentIndex = 0
        
        for announcement in manager.announcments{
            if(manager.shouldSeeAnnouncement(user: appDelegate.currentUser!, announcement: announcement)){
                secondaryPayload.append(announcement)
                currentIndex += 1
            }
        }
        
        if(!secondaryPayload.isEmpty){
            secondaryPayload.append(AdObject())
        }
        //upcoming games
        let ignoreArray = defaults.stringArray(forKey: "ignoredUpcomingGames") ?? [String]()
        for game in appDelegate.upcomingGames {
            if(!ignoreArray.contains(game.id)){
                secondaryPayload.append(game)
            }
        }
        
        if(!secondaryPayload.isEmpty){
            secondaryPayload.append(AdObject())
        }
        
        let ignoreNewsArray = defaults.stringArray(forKey: "ignoredNews") ?? [String]()
        for news in appDelegate.mediaCache.newsCache {
            if(!ignoreNewsArray.contains(news.title)){
                if(currentIndex.isMultiple(of: 5) && currentIndex != 0){
                    secondaryPayload.append(AdObject())
                } else {
                    secondaryPayload.append(news)
                }
                currentIndex += 1
            }
        }
        
        //episodes
        let ignoredEpisodes = defaults.stringArray(forKey: "ignoredEpisodes") ?? [String]()
        for episode in appDelegate.episodes {
            if(!ignoredEpisodes.contains(episode.mediaId)){
                if(currentIndex.isMultiple(of: 5) && currentIndex != 0){
                    secondaryPayload.append(AdObject())
                } else {
                    secondaryPayload.append(episode)
                }
                currentIndex += 1
            }
        }

        secondaryPayload.append(contentsOf: appDelegate.competitions)
    
        if(!dataSet){
            self.feedCollection.delegate = self
            self.feedCollection.dataSource = self
            
            self.dataSet = true
        } else {
            self.feedCollection.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return secondaryPayload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.secondaryPayload[indexPath.item]
        
        if(current is RecommendedUser){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendedCell", for: indexPath) as! RecommendedUsersCell
            
            cell.gamerTag.text = (current as! RecommendedUser).gamerTag
            
            if((current as! RecommendedUser).gamerTag == "allthesaints011"){
                cell.xBox.isHidden = true
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC-Connect Toussaint Click"))
            }
            if((current as! RecommendedUser).gamerTag == "fitboy_"){
                cell.xBox.isHidden = true
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC-Connect Hodges Click"))
            }
            if((current as! RecommendedUser).gamerTag == "Kwatakye Raven"){
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC-Connect Mike Click"))
            }
            
            
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
        else if(current is NewsObject){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "news", for: indexPath) as! NewsArticleCell
            cell.title.text = (current as! NewsObject).title
            
            if((current as! NewsObject).videoUrl.isEmpty){
                cell.contents.text = "READ"
            } else {
                cell.contents.text = "READ - WATCH"
            }
            
            if((current as! NewsObject).source == "gs"){
                cell.authorLabel.text = "gamespot"
            } else if((current as! NewsObject).source == "dxp"){
                cell.authorLabel.text = "doublexp"
            } else {
                cell.authorLabel.text = (current as! NewsObject).author
            }
            
            cell.articleBack.image = #imageLiteral(resourceName: "new_logo3.png")
            cell.closeX.alpha = 0
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: (current as! NewsObject).imageUrl as NSString) != nil){
                cell.articleBack.image = cache.object(forKey: (current as! NewsObject).imageUrl as NSString)
            } else {
                cell.articleBack.image = Utility.Image.placeholder
                cell.articleBack.moa.onSuccess = { image in
                    cell.articleBack.image = image
                    cell.articleBack.alpha = 0.6
                    cell.articleBack.contentMode = .scaleAspectFill
                    cell.articleBack.clipsToBounds = true
                    
                    appDelegate.imageCache.setObject(image, forKey: (current as! NewsObject).imageUrl as NSString)
                    return image
                }
                cell.articleBack.moa.url = (current as! NewsObject).imageUrl
            }
            
            cell.tag = indexPath.item
            
            return cell
        }
        else if(current is AdObject){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ad", for: indexPath) as! AdCell
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            cell.setAd(landingController: appDelegate.currentLanding!)
            
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
        else if(current is AnnouncementObj){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "announcementCell", for: indexPath) as! AnnouncementCell
            
            cell.announcementGame.text = (current as! AnnouncementObj).announcementGames[0]
            cell.announcementTitle.text = (current as! AnnouncementObj).announcementTitle
            
            cell.tag = indexPath.item
            
            let ignoreTap = UITapGestureRecognizer(target: self, action: #selector(ignoreGame))
            cell.announcementIgnore.isUserInteractionEnabled = true
            cell.announcementIgnore.addGestureRecognizer(ignoreTap)
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            return cell
        }
        else if(current is UpcomingGame){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upcoming", for: indexPath) as! UpcomingGameCell
            let currentObj = current as! UpcomingGame
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: currentObj.gameImageUrl as NSString) != nil){
                cell.gameBack.image = cache.object(forKey: currentObj.gameImageUrl as NSString)
            } else {
                cell.gameBack.image = Utility.Image.placeholder
                cell.gameBack.moa.onSuccess = { image in
                    cell.gameBack.image = image
                    appDelegate.imageCache.setObject(image, forKey: currentObj.gameImageUrl as NSString)
                    return image
                }
                cell.gameBack.moa.url = currentObj.gameImageUrl
            }
            
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameBack.clipsToBounds = true
            
            cell.closeClickArea.tag = indexPath.item
            
            let ignoreTap = UITapGestureRecognizer(target: self, action: #selector(ignoreGame))
            cell.closeClickArea.isUserInteractionEnabled = true
            cell.closeClickArea.addGestureRecognizer(ignoreTap)
            
            cell.gameName.text = currentObj.game
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            return cell
        } else if(current is EpisodeObj){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "episode", for: indexPath) as! EpisodeCell
            let currentObj = current as! EpisodeObj
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: currentObj.imageUrl as NSString) != nil){
                cell.background.image = cache.object(forKey: currentObj.imageUrl as NSString)
            } else {
                cell.background.image = Utility.Image.placeholder
                cell.background.moa.onSuccess = { image in
                    cell.background.image = image
                    appDelegate.imageCache.setObject(image, forKey: currentObj.imageUrl as NSString)
                    return image
                }
                cell.background.moa.url = currentObj.imageUrl
            }
            
            cell.background.contentMode = .scaleAspectFill
            cell.background.clipsToBounds = true
            
            cell.clickArea.tag = indexPath.item
            
            let ignoreTap = UITapGestureRecognizer(target: self, action: #selector(ignoreEpisode))
            cell.clickArea.isUserInteractionEnabled = true
            cell.clickArea.addGestureRecognizer(ignoreTap)
            
            cell.title.text = currentObj.name
            cell.sub.text = currentObj.sub
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            return cell
        } else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "competitionCell", for: indexPath) as! CompetitionCell
            
            cell.competitionName.text = (current as! CompetitionObj).competitionName
            cell.gameName.text = (current as! CompetitionObj).gameName
            cell.topPrize.text = "top prize: " + (current as! CompetitionObj).topPrize
            
            /*if(!(current as! CompetitionObj).videoPlayed){
                if((current as! CompetitionObj).gcName == "NBA 2K20"){
                    guard let videoPath = Bundle.main.path(forResource: "basketball", ofType: "mov"),
                    let imagePath = Bundle.main.path(forResource: "null", ofType: "png") else{
                        return cell
                    }
                    
                    let options = VideoOptions(pathToVideo: videoPath,
                                               pathToImage: imagePath,
                                               isMuted: true,
                                               shouldLoop: false)
                    let videoView = VideoBackground(frame: cell.bounds, options: options)
                    videoView.layer.masksToBounds = true
                    videoView.alpha = 0.3
                    
                    //videoView.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor).isActive = true
                    cell.contentView.insertSubview(videoView, at: 0)
                }
                (current as! CompetitionObj).videoPlayed = true
            }*/
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
                
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.secondaryPayload[indexPath.item]
        if(current is CompetitionObj){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(180))
        }
        else if(current is AnnouncementObj){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        }
        else if(current is AdObject){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(50))
        }
        else if(current is UpcomingGame){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(150))
        }
        else if(current is EpisodeObj){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(170))
        }
        else if(current is NewsObject){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(250))
        }
        else{
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
        if(cell is RecommendedUsersCell){
            //self.feedFrag.clearSearch()
            let current = self.secondaryPayload[indexPath.item]
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToProfile(uid: (current as! RecommendedUser).uid)
        }
        else if (cell is AnnouncementCell){
            //self.feedFrag.clearSearch()
            let current = self.secondaryPayload[indexPath.item]
            self.feedFrag.showAnnouncement(announcement: current as! AnnouncementObj)
        }
        else if (cell is UpcomingGameCell){
            //self.feedFrag.clearSearch()
            let current = self.secondaryPayload[indexPath.item] as! UpcomingGame
            self.feedFrag.showUpcomingGameInfo(upcomingGame: current)
        } else if (cell is EpisodeCell){
            //self.feedFrag.clearSearch()
            let current = self.secondaryPayload[indexPath.item] as! EpisodeObj
            self.feedFrag.playEpisode(url: current.url)
        } else if (cell is NewsArticleCell){
            //self.feedFrag.clearSearch()
            let current = self.secondaryPayload[indexPath.item] as! NewsObject
            
            if let cell = collectionView.cellForItem(at: indexPath) as? NewsArticleCell {
                let image = cell.articleBack.image
                self.feedFrag.showArticle(newsObj: current, image: image!)
            }
        }
        else if(cell is AdCell){
            //do nothing
        }
        else{
            //self.feedFrag.clearSearch()
            //self.feedFrag.resetSearchList()
            let current = self.secondaryPayload[indexPath.item]
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToCompetition(competition: (current as! CompetitionObj))
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            // `collectionView.contentSize` has a wrong width because in this nested example, the sizing pass occurs before the layout pass,
            // so we need to force a layout pass with the correct width.
            self.contentView.frame = self.bounds
            self.contentView.layoutIfNeeded()
            // Returns `collectionView.contentSize` in order to set the UITableVieweCell height a value greater than 0.
        return CGSize(width: self.feedCollection.contentSize.width, height: self.feedCollection.contentSize.height + 80)
    }
    
    @objc func ignoreGame(_ sender: UITapGestureRecognizer){
        let defaults = UserDefaults.standard
        var ignoreArray = defaults.stringArray(forKey: "ignoredUpcomingGames") ?? [String]()
        
        let view = sender.view
        if(view != nil){
            let current = self.secondaryPayload[view!.tag]
            if(current is UpcomingGame){
                if(!(current as! UpcomingGame).id.isEmpty){
                    ignoreArray.append((current as! UpcomingGame).id)
                    defaults.set(ignoreArray, forKey: "ignoredUpcomingGames")
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Upcoming Game ignored" + (current as! UpcomingGame).game))
                    
                    self.secondaryPayload.remove(at: view!.tag)
                    self.feedCollection.reloadData()
                }
            }
        }
    }
    
    @objc private func ignoreAnnouncement(_ sender: UITapGestureRecognizer){
        if(self.feedFrag.currentAnnouncement != nil){
            registerAnnouncementView(announcement: self.feedFrag.currentAnnouncement!)
        }
        
        for obj in self.secondaryPayload {
            if(obj is AnnouncementObj){
                if((obj as! AnnouncementObj).announcementId == self.feedFrag.currentAnnouncement?.announcementId){
                    
                    let view = sender.view
                    self.secondaryPayload.remove(at: (view as! AnnouncementCell).tag)
                }
            }
        }
        
        self.feedCollection.reloadData()
    }
    
    @objc private func ignoreEpisode(_ sender: UITapGestureRecognizer){
        let defaults = UserDefaults.standard
        var ignoreArray = defaults.stringArray(forKey: "ignoredEpisodes") ?? [String]()
        
        let view = sender.view
        if(view != nil){
            let current = self.secondaryPayload[view!.tag]
            if(current is EpisodeObj){
                if(!(current as! EpisodeObj).mediaId.isEmpty){
                    ignoreArray.append((current as! EpisodeObj).mediaId)
                    defaults.set(ignoreArray, forKey: "ignoredEpisodes")
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Episode ignored" + (current as! EpisodeObj).mediaId))
                    
                    self.secondaryPayload.remove(at: view!.tag)
                    self.feedCollection.reloadData()
                }
            }
        }
    }
    
    private func registerAnnouncementView(announcement: AnnouncementObj){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("viewedAnnouncements")){
                    var viewed = snapshot.childSnapshot(forPath: "viewedAnnouncements").value as! [String]
                    if(!viewed.contains(announcement.announcementId)){
                        viewed.append(announcement.announcementId)
                        ref.child("viewedAnnouncements").setValue(viewed)
                    }
                } else {
                    var viewed = [String]()
                    viewed.append(announcement.announcementId)
                    
                    ref.child("viewedAnnouncements").setValue(viewed)
                }
                
                if(!appDelegate.currentUser!.viewedAnnouncements.contains(announcement.announcementId)){
                    appDelegate.currentUser!.viewedAnnouncements.append(announcement.announcementId)
                }
                
                self.buildSecondaryPayload()
                self.feedCollection.reloadData()
            }
            
        }) { (error) in
            print(error.localizedDescription)
            
        }
    }
    
    func reloadFeed(){
        self.feedCollection.performBatchUpdates({
            let indexSet = IndexSet(integer: 0)
            self.feedCollection.reloadSections(indexSet)
        }, completion: nil)
    }
    
}
