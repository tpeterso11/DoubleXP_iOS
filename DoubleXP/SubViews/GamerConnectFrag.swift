//
//  GamerConnectFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/27/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import MSPeekCollectionViewDelegateImplementation
import FBSDKCoreKit
import VideoBackground
import MSPeekCollectionViewDelegateImplementation
import SwiftNotificationCenter
import CollectionViewSlantedLayout

class GamerConnectFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
UITableViewDelegate, UITableViewDataSource, LandingUICallbacks {
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var recommendedUsers: UICollectionView!
    var selectedCell = false
    
    @IBOutlet weak var fadeLogo: UIImageView!
    @IBOutlet weak var yourFeedHeader: UIView!
    @IBOutlet weak var announcementShare: UIButton!
    @IBOutlet weak var announcementClose: UIImageView!
    @IBOutlet weak var announcementDetails: UILabel!
    @IBOutlet weak var announcementSender: UILabel!
    @IBOutlet weak var announcementTitle: UILabel!
    @IBOutlet weak var announcementBox: UIView!
    @IBOutlet weak var announcementLayout: UIVisualEffectView!
    @IBOutlet weak var connectHeader: UILabel!
    @IBOutlet weak var currentDate: UILabel!
    @IBOutlet weak var upcomingGameBox: UIView!
    @IBOutlet weak var upcomingBoxGame: UILabel!
    @IBOutlet weak var upcomingBoxDesc: UILabel!
    @IBOutlet weak var closeUpcomingGame: UIImageView!
    @IBOutlet weak var announcementCloseClickArea: UIView!
    @IBOutlet weak var upcomingReleaseDate: UILabel!
    @IBOutlet weak var trailerWV: WKWebView!
    @IBOutlet weak var upcomingReleaseBoxBack: UIImageView!
    var gcGames = [GamerConnectGame]()
    @IBOutlet weak var upcomingBoxTable: UITableView!
    var secondaryPayload = [Any]()
    private var currentAnnouncement: AnnouncementObj?
    private var currentEpisode: EpisodeObj?
    var timer: Timer!
    var currentUpcomingGamePos = -1
    var currentTrailers = [String: String]()
    var trailerPayload = [String]()
    var upcomingSet = false
    
    var behavior: MSCollectionViewPeekingBehavior!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animateView()
        
        //behavior = MSCollectionViewPeekingBehavior()
        //self.gcGameScroll.configureForPeekingBehavior(behavior: behavior)
        
        let todaysDate:NSDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let todayString:String = dateFormatter.string(from: todaysDate as Date)
        
        currentDate.text = todayString
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentConnectFrag = self
        
        var list = [GamerConnectGame]()
        for game in appDelegate.gcGames {
            if(game.available == "true"){
                list.append(game)
            }
        }
        
        gcGames = list
        
        //self.recommendedUsers.collectionViewLayout = CollectionViewSlantedLayout()
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentLanding?.hideScoob()
        }
    }
    
    override func reloadView() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.restoreBottomNav()
        appDelegate.currentLanding!.updateNavColor(color: UIColor(named: "darker")!)
        appDelegate.currentLanding!.stackDepth = 1
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("gone")
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("gone")
    }
    
    func reloadFeed(){
        buildSecondaryPayload()
        self.recommendedUsers.performBatchUpdates({
            let indexSet = IndexSet(integer: 0)
            self.recommendedUsers.reloadSections(indexSet)
        }, completion: nil)
    }
    
    private func animateView(){
        buildSecondaryPayload()
        
        let top = CGAffineTransform(translationX: 0, y: 50)
        UIView.animate(withDuration: 0.5, animations: {
            self.connectHeader.alpha = 1
            self.connectHeader.transform = top
            self.currentDate.transform = top
            self.currentDate.alpha = 1
        }, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.gcGameScroll.delegate = self
            self.recommendedUsers.delegate = self
            self.gcGameScroll.dataSource = self
            self.recommendedUsers.dataSource = self
            
            let top = CGAffineTransform(translationX: 0, y: 40)
            UIView.animate(withDuration: 0.8, animations: {
                self.fadeLogo.alpha = 0
                self.gcGameScroll.alpha = 1
                self.gcGameScroll.transform = top
                self.gcGameScroll.reloadData()
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.yourFeedHeader.transform = top
                    self.yourFeedHeader.alpha = 1
                    self.recommendedUsers.transform = top
                    self.recommendedUsers.alpha = 1
                }, completion: nil)
            })
        }
    }
    
    private func buildSecondaryPayload(){
        secondaryPayload = [Any]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.announcementManager
        let defaults = UserDefaults.standard
        
        for announcement in manager.announcments{
            if(manager.shouldSeeAnnouncement(user: appDelegate.currentUser!, announcement: announcement)){
                secondaryPayload.append(announcement)
            }
        }
        
        //episodes
        let ignoredEpisodes = defaults.stringArray(forKey: "ignoredEpisodes") ?? [String]()
        for episode in appDelegate.episodes {
            if(!ignoredEpisodes.contains(episode.mediaId)){
                secondaryPayload.append(episode)
            }
        }
        
        //upcoming games
        let ignoreArray = defaults.stringArray(forKey: "ignoredUpcomingGames") ?? [String]()
        for game in appDelegate.upcomingGames {
            if(!ignoreArray.contains(game.id)){
                secondaryPayload.append(game)
            }
        }

        secondaryPayload.append(contentsOf: appDelegate.competitions)
        
        //let userOne = RecommendedUser(gamerTag: "allthesaints011", uid: "HMv30El7nmWXPEnriV3irMsnS3V2")
        //let userTwo = RecommendedUser(gamerTag: "fitboy_", uid: "oFdx8UequuOs77s8daWFifODVhJ3")
        //let userThree = RecommendedUser(gamerTag: "Kwatakye Raven", uid: "N1k1BqmvEvdOXrbmi2p91kTNLOo1")
        
        //secondaryPayload.append(userOne)
        //secondaryPayload.append(userTwo)
        //secondaryPayload.append(userThree)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.gcGameScroll {
            return gcGames.count
        }
        else{
            return secondaryPayload.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.recommendedUsers {
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
            else if(current is AnnouncementObj){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "announcementCell", for: indexPath) as! AnnouncementCell
                
                cell.announcementGame.text = (current as! AnnouncementObj).announcementGames[0]
                cell.announcementTitle.text = (current as! AnnouncementObj).announcementTitle
                
                /*cell.contentView.layer.cornerRadius = 10.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true*/
                
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
                
                /*cell.contentView.layer.cornerRadius = 10.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true*/
                
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
                
                /*cell.contentView.layer.cornerRadius = 10.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true*/
                
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
                
                if(!(current as! CompetitionObj).videoPlayed){
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
                }
                
                /*cell.contentView.layer.cornerRadius = 10.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true*/
                
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.layer.shadowRadius = 2.0
                cell.layer.shadowOpacity = 0.5
                cell.layer.masksToBounds = false
                cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
                    
                return cell
            }
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
            
            let game = gcGames[indexPath.item]
    
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: game.imageUrl as NSString) != nil){
                cell.backgroundImage.image = cache.object(forKey: game.imageUrl as NSString)
            } else {
                cell.backgroundImage.image = Utility.Image.placeholder
                cell.backgroundImage.moa.onSuccess = { image in
                    cell.backgroundImage.image = image
                    appDelegate.imageCache.setObject(image, forKey: game.imageUrl as NSString)
                    return image
                }
                cell.backgroundImage.moa.url = game.imageUrl
            }
            
            cell.backgroundImage.contentMode = .scaleAspectFill
            cell.backgroundImage.clipsToBounds = true
            
            cell.gameName.text = game.gameName
            cell.developer.text = game.developer
            
            if(game.mobileGame == "true"){
                cell.mobile.isHidden = false
            } else {
                cell.mobile.isHidden = true
            }
            cell.hook.text = game.hook
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC-Connect " + game.gameName + " Click"))
            
            cell.contentView.layer.cornerRadius = 2.0
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
        if collectionView == self.recommendedUsers {
            let cell = collectionView.cellForItem(at: indexPath)
            
            if(cell is RecommendedUsersCell){
                let current = self.secondaryPayload[indexPath.item]
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentLanding!.navigateToProfile(uid: (current as! RecommendedUser).uid)
            }
            else if (cell is AnnouncementCell){
                let current = self.secondaryPayload[indexPath.item]
                self.showAnnouncement(announcement: current as! AnnouncementObj)
            }
            else if (cell is UpcomingGameCell){
                let current = self.secondaryPayload[indexPath.item] as! UpcomingGame
                self.showUpcomingGameInfo(upcomingGame: current)
            } else if (cell is EpisodeCell){
                let current = self.secondaryPayload[indexPath.item] as! EpisodeObj
                self.playEpisode(url: current.url)
            }   else{
                let current = self.secondaryPayload[indexPath.item]
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentLanding!.navigateToCompetition(competition: (current as! CompetitionObj))
            }
        }
        else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToSearch(game: gcGames[indexPath.item])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.recommendedUsers {
            let current = self.secondaryPayload[indexPath.item]
            if(current is CompetitionObj){
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(180))
            }
            else if(current is AnnouncementObj){
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(80))
            }
            else if(current is UpcomingGame){
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(150))
            }
            else if(current is EpisodeObj){
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(170))
            }
            else{
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
            }
        }
        if collectionView == self.gcGameScroll {
            return CGSize(width: 280, height: CGFloat(160))
        }
        
        return CGSize(width: 260, height: CGFloat(100))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.trailerPayload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trailer", for: indexPath) as! UpcomingTrailerCell
        let current = self.trailerPayload[indexPath.item]
        
        cell.type.text = current
        cell.url = self.currentTrailers[current]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath) as! UpcomingTrailerCell
        
        if(currentCell.url != nil){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding?.showScoob(callback: self, cancelableWV: self.trailerWV)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.trailerWV.load(NSURLRequest(url: NSURL(string: currentCell.url!)! as URL) as URLRequest)
            }
        }
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
                    self.recommendedUsers.reloadData()
                }
            }
        }
    }
    
    private func playEpisode(url: String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.showScoob(callback: self, cancelableWV: self.trailerWV)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.trailerWV.load(NSURLRequest(url: NSURL(string: url)! as URL) as URLRequest)
        }
    }
    
    @objc func UpdateTime(_ sender: Timer) {
        let userCalendar = Calendar.current
        // Set Current Date
        let date = Date()
        let components = userCalendar.dateComponents([.hour, .minute, .month, .year, .day, .second], from: date)
        let currentDate = userCalendar.date(from: components)!
        
        var eventDateComponents = DateComponents()
        eventDateComponents = userCalendar.dateComponents([.hour, .minute, .month, .year, .day, .second], from: ((sender.userInfo as! NSDictionary)["date"]! as! Date))
        
        // Convert eventDateComponents to the user's calendar
        let eventDate = userCalendar.date(from: eventDateComponents)!
        
        // Change the seconds to days, hours, minutes and seconds
        let timeLeft = userCalendar.dateComponents([.day, .hour, .minute, .second], from: currentDate, to: eventDate)
        
        // Display Countdown
        ((sender.userInfo as! NSDictionary)["view"] as! UILabel).text = "\(timeLeft.day!)d \(timeLeft.hour!)h \(timeLeft.minute!)m \(timeLeft.second!)s"
        
        // Show diffrent text when the event has passed
        endEvent(currentdate: currentDate, eventdate: eventDate)
    }
    
    func endEvent(currentdate: Date, eventdate: Date) {
        if currentdate >= eventdate {
            // Stop Timer
            timer.invalidate()
        }
    }
    
    private func showAnnouncement(announcement: AnnouncementObj){
        self.currentAnnouncement = announcement
        self.announcementSender.text = currentAnnouncement?.announcementSender
        self.announcementDetails.text = currentAnnouncement?.announcementDetails
        self.announcementTitle.text = currentAnnouncement?.announcementTitle
        
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(dismissAnnouncement))
        self.announcementClose.isUserInteractionEnabled = true
        self.announcementClose.addGestureRecognizer(closeTap)
        self.announcementShare.isHidden = true
        
        self.announcementBox.layer.shadowColor = UIColor.black.cgColor
        self.announcementBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.announcementBox.layer.shadowRadius = 2.0
        self.announcementBox.layer.shadowOpacity = 0.5
        self.announcementBox.layer.masksToBounds = false
        self.announcementBox.layer.shadowPath = UIBezierPath(roundedRect: self.announcementBox.bounds, cornerRadius: self.announcementBox.layer.cornerRadius).cgPath
        
        //let slideDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        //slideDown.direction = .down
        //self.announcementBox.addGestureRecognizer(slideDown)
        
        let top = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.8, animations: {
            self.announcementLayout.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.announcementBox.transform = top
                self.announcementBox.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc func dismissView(gesture: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.4) {
            if let theWindow = UIApplication.shared.keyWindow {
                gesture.view?.frame = CGRect(x:theWindow.frame.width - 15 , y: theWindow.frame.height - 15, width: 10 , height: 10)
            }
        }
    }
    
    @objc private func ignoreAnnouncement(_ sender: UITapGestureRecognizer){
        if(self.currentAnnouncement != nil){
            registerAnnouncementView(announcement: self.currentAnnouncement!)
        }
        
        for obj in self.secondaryPayload {
            if(obj is AnnouncementObj){
                if((obj as! AnnouncementObj).announcementId == self.currentAnnouncement?.announcementId){
                    
                    let view = sender.view
                    self.secondaryPayload.remove(at: (view as! AnnouncementCell).tag)
                }
            }
        }
        
        self.recommendedUsers.reloadData()
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
                    self.recommendedUsers.reloadData()
                }
            }
        }
    }
    
    @objc private func dismissAnnouncement(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.5, animations: {
            self.announcementBox.transform = top
            self.announcementBox.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.announcementLayout.alpha = 0
            }, completion: nil)
        })
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
                self.recommendedUsers.reloadData()
            }
            
        }) { (error) in
            print(error.localizedDescription)
            
        }
    }
    
    private func showUpcomingGameInfo(upcomingGame: UpcomingGame){
        self.upcomingBoxGame.text = upcomingGame.game
        self.upcomingBoxDesc.text = upcomingGame.gameDesc
        self.upcomingBoxDesc.layer.cornerRadius = 15
        
        self.upcomingBoxDesc.layer.shadowColor = UIColor.black.cgColor
        self.upcomingBoxDesc.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.upcomingBoxDesc.layer.shadowRadius = 2.0
        self.upcomingBoxDesc.layer.shadowOpacity = 0.5
        self.upcomingBoxDesc.layer.masksToBounds = true
        self.upcomingBoxDesc.layer.shadowPath = UIBezierPath(roundedRect: self.upcomingBoxDesc.bounds, cornerRadius: self.upcomingBoxDesc.layer.cornerRadius).cgPath
        
        self.currentTrailers = upcomingGame.trailerUrls
        self.upcomingReleaseDate.text = upcomingGame.releaseDateProper
        
        self.trailerPayload = [String]()
        self.trailerPayload.append(contentsOf: upcomingGame.trailerUrls.keys)
        
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(hideUpcoming))
        self.closeUpcomingGame.isUserInteractionEnabled = true
        self.closeUpcomingGame.addGestureRecognizer(closeTap)
        
        let clickAreaTap = UITapGestureRecognizer(target: self, action: #selector(hideUpcoming))
        self.announcementCloseClickArea.isUserInteractionEnabled = true
        self.announcementCloseClickArea.addGestureRecognizer(clickAreaTap)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: upcomingGame.gameImageUrl as NSString) != nil){
            self.upcomingReleaseBoxBack.image = cache.object(forKey: upcomingGame.gameImageUrl as NSString)
            self.upcomingReleaseBoxBack.contentMode = .scaleAspectFill
            self.upcomingReleaseBoxBack.clipsToBounds = true
        } else {
            self.upcomingReleaseBoxBack.image = Utility.Image.placeholder
            self.upcomingReleaseBoxBack.moa.onSuccess = { image in
                self.upcomingReleaseBoxBack.image = image
                self.upcomingReleaseBoxBack.contentMode = .scaleAspectFill
                self.upcomingReleaseBoxBack.clipsToBounds = true
                
                appDelegate.imageCache.setObject(image, forKey: upcomingGame.gameImageUrl as NSString)
                return image
            }
            self.upcomingReleaseBoxBack.moa.url = upcomingGame.gameImageUrl
        }
        
        self.upcomingGameBox.layer.cornerRadius = 15.0
        self.upcomingGameBox.layer.borderWidth = 1.0
        self.upcomingGameBox.layer.borderColor = UIColor.clear.cgColor
        self.upcomingGameBox.layer.masksToBounds = true
        
        self.upcomingGameBox.layer.shadowColor = UIColor.black.cgColor
        self.upcomingGameBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.upcomingGameBox.layer.shadowRadius = 2.0
        self.upcomingGameBox.layer.shadowOpacity = 0.5
        self.upcomingGameBox.layer.masksToBounds = false
        self.upcomingGameBox.layer.shadowPath = UIBezierPath(roundedRect: self.upcomingGameBox.bounds, cornerRadius: self.upcomingGameBox.layer.cornerRadius).cgPath
        
        if(!upcomingSet){
            self.upcomingBoxTable.delegate = self
            self.upcomingBoxTable.dataSource = self
            self.upcomingSet = true
            
            self.upcomingBoxTable.reloadData()
        } else {
            self.upcomingBoxTable.reloadData()
        }
        
        let top = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.8, animations: {
            self.announcementLayout.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.upcomingGameBox.alpha = 1
                self.upcomingGameBox.transform = top
                
                self.upcomingGameBox.layer.shadowColor = UIColor.black.cgColor
                self.upcomingGameBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                self.upcomingGameBox.layer.shadowRadius = 2.0
                self.upcomingGameBox.layer.shadowOpacity = 0.5
                self.upcomingGameBox.layer.masksToBounds = false
                self.upcomingGameBox.layer.shadowPath = UIBezierPath(roundedRect: self.upcomingGameBox.bounds, cornerRadius: self.upcomingGameBox.layer.cornerRadius).cgPath
            }, completion: nil)
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0;
    }
    
    func updateNavColor(color: UIColor) {
    }
    
    @objc private func hideUpcoming(){
        self.announcementCloseClickArea.isUserInteractionEnabled = false
        
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
             self.upcomingGameBox.alpha = 0
             self.upcomingGameBox.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.announcementLayout.alpha = 0
            }, completion: nil)
        })
    }
}

extension UIView {
    func rotate(degrees: CGFloat) {
        rotate(radians: CGFloat.pi * degrees / 180.0)
    }

    func rotate(radians: CGFloat) {
        self.transform = CGAffineTransform(rotationAngle: radians)
    }
}
