//
//  Feed.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import WebKit
import Lottie
import FirebaseDatabase
import FBSDKCoreKit

class Feed : ParentVC, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate, LandingUICallbacks {
    @IBOutlet weak var feedTable: UITableView!
    @IBOutlet weak var announcementShare: UIButton!
    @IBOutlet weak var announcementClose: UIImageView!
    @IBOutlet weak var announcementDetails: UILabel!
    @IBOutlet weak var announcementSender: UILabel!
    @IBOutlet weak var announcementTitle: UILabel!
    @IBOutlet weak var announcementBox: UIView!
    @IBOutlet weak var announcementLayout: UIVisualEffectView!
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
    var payload = [String]()
    var trailerPayload = [String]()
    var currentTrailers = [String: String]()
    var currentAnnouncement: AnnouncementObj?
    var currentEpisode: EpisodeObj?
    var upcomingSet = false
    var currentHeaderCell: FeedHeaderCell?
    var recommededLoaded = false
    var onlineAnnouncements = [OnlineObj]()
    var announcementsAvailable = false
    var dataSet = false
    var todayAnimated = false
    var currentFeaturedGame: GamerConnectGame?
    var todayAnimating = false
    
    override func viewDidLoad() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFeedFrag = self
        FriendsManager().checkOnlineAnnouncements()
        
        appDelegate.currentLanding?.playSimpleLandingAnimation()
    
        self.buildTablePayload()
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentLanding?.hideScoob()
        }
        
        self.feedTable.estimatedRowHeight = 250
        self.feedTable.rowHeight = UITableView.automaticDimension
        
        if self.traitCollection.userInterfaceStyle == .dark {
            AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - User in Dark Mode"))
        } else {
            AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - User in Light Mode"))
        }
    }
    
    @objc override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    private func buildTablePayload(){
        payload = [String]()
        
        
        payload.append("header")
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for game in delegate.gcGames {
            if(game.gameName == delegate.feedFeaturedGame){
                self.currentFeaturedGame = game
                break
            }
        }
        if((delegate.currentUser!.userAbout.isEmpty || delegate.currentUser!.userLookingFor.isEmpty) && delegate.currentCta != nil) {
            payload.append("cta")
        }
        if(!delegate.currentUser!.receivedPosts.isEmpty){
            var newPostsAvailable = false
            for postObj in delegate.currentUser!.receivedPosts {
                if(!delegate.currentUser!.viewedPosts.contains(postObj.postId)){
                    newPostsAvailable = true
                    break
                }
            }
            if(newPostsAvailable){
                payload.append("posts")
            }
        }
        if(self.currentFeaturedGame != nil){
            payload.append("discoverExpanded")
        }
        payload.append("discover")
        payload.append("feed")
        
        checkOnlineAnnouncements()
        //UIView.animate(withDuration: 0.8, delay: 1.5, options: [], animations: {
        //    self.feedTable.alpha = 1
        //}, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.8, animations: {
            self.feedTable.alpha = 1
        }, completion: nil)
    }
    
    func didDismissStorkBySwipe() {
        self.checkOnlineAnnouncements()
    }
    
    func didDismissStorkByTap() {
        self.checkOnlineAnnouncements()
    }
    func modalDismissed(){
        self.checkOnlineAnnouncements()
    }
    
    func checkOnlineAnnouncements(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                self.onlineAnnouncements = [OnlineObj]()
                if(snapshot.hasChild("onlineAnnouncements")){
                    let announceArray = snapshot.childSnapshot(forPath: "onlineAnnouncements")
                    for onlineAnnounce in announceArray.children {
                        let currentObj = onlineAnnounce as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["tag"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = OnlineObj(tag: tag, friends: [String](), date: date, id: id)
                        
                        let calendar = Calendar.current
                        if(!date.isEmpty){
                            let dbDate = self.stringToDate(date)
                            
                            if(dbDate != nil){
                                let now = NSDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                                let future = formatter.string(from: dbDate as Date)
                                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                                
                                let validAnnouncement = (now as Date).compare(.isEarlier(than: dbTimeOut))
                                
                                if(dbTimeOut != nil){
                                    if(validAnnouncement){
                                        self.onlineAnnouncements.append(request)
                                    }
                                }
                            }
                        }
                    }
                    self.announcementsAvailable = !self.onlineAnnouncements.isEmpty
                    
                    if(self.dataSet){
                        self.reloadFeed()
                    } else {
                        self.dataSet = true
                        self.feedTable.delegate = self
                        self.feedTable.dataSource = self
                        //self.feedTable.reloadData()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            delegate.currentLanding?.hideLoading()
                        }
                    }
                } else {
                    self.announcementsAvailable = false
                    if(self.dataSet){
                        self.reloadFeed()
                    } else {
                        self.dataSet = true
                        self.feedTable.delegate = self
                        self.feedTable.dataSource = self
                        //self.feedTable.reloadData()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            delegate.currentLanding?.hideLoading()
                        }
                    }
                }
            } else {
                self.announcementsAvailable = false
                if(self.dataSet){
                    self.reloadFeed()
                } else {
                    self.dataSet = true
                    self.feedTable.delegate = self
                    self.feedTable.dataSource = self
                    self.feedTable.reloadData()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.currentLanding?.hideLoading()
                    }
                }
            }
        })
    }
    
    private func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    
    func requestsClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Requests Launched"))
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding?.requestButtonClicked(self)
    }
    
    func alertsClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Alerts launched"))
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding?.navigateToAlerts()
    }
    
    /*func clearSearch(){
        dismissKeyboard()
        currentHeaderCell?.resetSearch()
    }*/
    
    private func reloadFeed(){
        self.feedTable.reloadData()
    }
    
    func launchGameSelection(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gameSelection") as! GameSelection
        currentViewController.returning = true
        currentViewController.modalPopped = true
        
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
    
    @objc func launchFeedSearch(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "feedSearch") as! FeedSearchModal
        currentViewController.currentFeed = self
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        print("gone")
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("gone")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == self.feedTable){
            return self.payload.count
        } else {
            return self.trailerPayload.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == feedTable){
            let current = self.payload[indexPath.item]
            
            if(current == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! FeedHeaderCell
                cell.setLayout(feed: self, loaded: self.recommededLoaded, todayAnimated: self.todayAnimated, todayAnimating: self.todayAnimating)
                
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.launchFeedSearch))
                cell.startLayout.isUserInteractionEnabled = true
                cell.startLayout.addGestureRecognizer(backTap)
                
                //cell.contentView
                return cell
            } else if(current == "cta"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "cta", for: indexPath) as! CTACell
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let cache = appDelegate.imageCache
                
                if self.traitCollection.userInterfaceStyle == .dark {
                    if(cache.object(forKey: appDelegate.currentCta!.imgUrlDark as NSString) != nil){
                        cell.backgroundImg.image = cache.object(forKey: appDelegate.currentCta!.imgUrlDark as NSString)
                    } else {
                        cell.backgroundImg.image = Utility.Image.placeholder
                        cell.backgroundImg.moa.onSuccess = { image in
                            cell.backgroundImg.image = image
                            appDelegate.imageCache.setObject(image, forKey: appDelegate.currentCta!.imgUrlDark as NSString)
                            return image
                        }
                        cell.backgroundImg.moa.url = appDelegate.currentCta!.imgUrlDark
                    }
                } else {
                    if(cache.object(forKey: appDelegate.currentCta!.imgUrlLight as NSString) != nil){
                        cell.backgroundImg.image = cache.object(forKey: appDelegate.currentCta!.imgUrlLight as NSString)
                    } else {
                        cell.backgroundImg.image = Utility.Image.placeholder
                        cell.backgroundImg.moa.onSuccess = { image in
                            cell.backgroundImg.image = image
                            appDelegate.imageCache.setObject(image, forKey: appDelegate.currentCta!.imgUrlLight as NSString)
                            return image
                        }
                        cell.backgroundImg.moa.url = appDelegate.currentCta!.imgUrlLight
                    }
                }
                cell.backgroundImg.contentMode = .scaleAspectFill
                cell.backgroundImg.clipsToBounds = true
                
                cell.ctaButton.setTitle(appDelegate.currentCta!.buttonText, for: .normal)
                
                cell.shell.layer.shadowColor = UIColor.black.cgColor
                cell.shell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.shell.layer.shadowRadius = 2.0
                cell.shell.layer.shadowOpacity = 0.5
                cell.shell.layer.masksToBounds = false
                cell.shell.layer.shadowPath = UIBezierPath(roundedRect: cell.shell.bounds, cornerRadius: cell.shell.layer.cornerRadius).cgPath
                
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.ctaClicked))
                cell.shell.isUserInteractionEnabled = true
                cell.shell.addGestureRecognizer(backTap)
                
                /*UIView.animate(withDuration: 0.8, delay: 4.0, options: [], animations: {
                    cell.shell.alpha = 1
                }, completion: { (finished: Bool) in

                })*/
                
                return cell
            } else if(current == "discoverExpanded"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "discoverExpanded", for: indexPath) as! DiscoverExpandedCell
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let cache = appDelegate.imageCache
                
                if(!self.currentFeaturedGame!.alternateImageUrl.isEmpty){
                    if(cache.object(forKey: self.currentFeaturedGame!.alternateImageUrl as NSString) != nil){
                        cell.gameBack.image = cache.object(forKey: self.currentFeaturedGame!.alternateImageUrl as NSString)
                    } else {
                        cell.gameBack.image = Utility.Image.placeholder
                        cell.gameBack.moa.onSuccess = { image in
                            cell.gameBack.image = image
                            appDelegate.imageCache.setObject(image, forKey: self.currentFeaturedGame!.alternateImageUrl as NSString)
                            return image
                        }
                        cell.gameBack.moa.url = self.currentFeaturedGame!.alternateImageUrl
                    }
                } else {
                    if(cache.object(forKey: self.currentFeaturedGame!.imageUrl as NSString) != nil){
                        cell.gameBack.image = cache.object(forKey: self.currentFeaturedGame!.imageUrl as NSString)
                    } else {
                        cell.gameBack.image = Utility.Image.placeholder
                        cell.gameBack.moa.onSuccess = { image in
                            cell.gameBack.image = image
                            appDelegate.imageCache.setObject(image, forKey: self.currentFeaturedGame!.imageUrl as NSString)
                            return image
                        }
                        cell.gameBack.moa.url = self.currentFeaturedGame!.imageUrl
                    }
                }
                
                cell.gameBack.contentMode = .scaleAspectFill
                cell.gameBack.clipsToBounds = true
                
                cell.shell.layer.shadowColor = UIColor.black.cgColor
                cell.shell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.shell.layer.shadowRadius = 2.0
                cell.shell.layer.shadowOpacity = 0.5
                cell.shell.layer.masksToBounds = false
                cell.shell.layer.shadowPath = UIBezierPath(roundedRect: cell.shell.bounds, cornerRadius: cell.shell.layer.cornerRadius).cgPath
                
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.featuredGameClicked))
                cell.shell.isUserInteractionEnabled = true
                cell.shell.addGestureRecognizer(backTap)
                
                cell.gameName.text = self.currentFeaturedGame!.gameName
                
                return cell
            } else if(current == "discover"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "discover", for: indexPath) as! FeedDiscoverCell
                
                cell.discoverLayout.layer.shadowColor = UIColor.black.cgColor
                cell.discoverLayout.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.discoverLayout.layer.shadowRadius = 2.0
                cell.discoverLayout.layer.shadowOpacity = 0.5
                cell.discoverLayout.layer.masksToBounds = false
                cell.discoverLayout.layer.shadowPath = UIBezierPath(roundedRect: cell.discoverLayout.bounds, cornerRadius: cell.discoverLayout.layer.cornerRadius).cgPath
                
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.discoverClicked))
                cell.discoverLayout.isUserInteractionEnabled = true
                cell.discoverLayout.addGestureRecognizer(backTap)
                
                return cell
            } else if(current == "posts"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "posts", for: indexPath) as! FeedPostsCell
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                //let cache = appDelegate.imageCache
                let receivedPosts = appDelegate.currentUser!.receivedPosts
                
                var list = [Any]()
                list.append(contentsOf: receivedPosts)
                list.append("view")
                cell.setPosts(list: list)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "feed", for: indexPath) as! FeedFeedCell
                cell.setupView(feed: self)
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "trailer", for: indexPath) as! UpcomingTrailerCell
            let current = self.trailerPayload[indexPath.item]
            
            cell.type.text = current
            cell.url = self.currentTrailers[current]
            return cell
        }
    }
    
    @objc func ctaClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - CTA clicked"))
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
        currentViewController.extra = "quiz"
        
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
    
    @objc func featuredGameClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Featured Game clicked"))
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverGame") as! DiscoverGamePage
        currentViewController.game = self.currentFeaturedGame!
        
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
    
    @objc func discoverClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Discover clicked"))
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discover") as! DiscoverFrag
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
    
    @objc func hookupClicked(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Recommendations clicked"))
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "recommend") as! Recommeded
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
    
    /*func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == self.feedTable){
            let current = payload[indexPath.item]
            if(current == "header"){
                return 720
            } else if(current == "discover"){
                return 140
            } else {
                return 500
            }
        } else {
            return 80.0;
        }
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == feedTable){
            let current = payload[indexPath.item]
            if(current == "discover"){
                self.discoverClicked()
            }
        } else {
            let currentCell = tableView.cellForRow(at: indexPath) as! UpcomingTrailerCell
            
            if(currentCell.url != nil){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentLanding?.showScoob(callback: self, cancelableWV: self.trailerWV)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.trailerWV.load(NSURLRequest(url: NSURL(string: currentCell.url!)! as URL) as URLRequest)
                }
            }
        }
    }
    
    func playEpisode(url: String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.showScoob(callback: self, cancelableWV: self.trailerWV)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.trailerWV.load(NSURLRequest(url: NSURL(string: url)! as URL) as URLRequest)
        }
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
                self.announcementLayout.isHidden = true
            }, completion: nil)
        })
    }
    
    func todayRecommendedUsersLoaded(){
        self.recommededLoaded = true
        self.feedTable.reloadData()
    }
    
    @objc private func dismissAnnouncement(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.5, animations: {
            self.announcementBox.transform = top
            self.announcementBox.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.announcementLayout.alpha = 0
                self.announcementLayout.isHidden = true
            }, completion: nil)
        })
    }
    
    func showAnnouncement(announcement: AnnouncementObj){
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
        
        self.announcementLayout.isHidden = false
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
    
    func showArticle(newsObj: NewsObject, image: UIImage){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "articleDrawer") as! ArticleDrawer
        currentViewController.newsObj = newsObj
        currentViewController.selectedImage = image
        
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
    
    func showUpcomingGameInfo(upcomingGame: UpcomingGame){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Feed - Upcoming Game clicked - " + upcomingGame.game))
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upcomingDrawer") as! UpcomingGameDrawer
        currentViewController.upcomingGame = upcomingGame
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.customHeight = 650
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
        
        /*self.upcomingBoxGame.text = upcomingGame.game
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
        })*/
    }
    
    func launchVideoMessage(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "videoMessage") as! VideoMessage
        //currentViewController.newsObj = newsObj
        //currentViewController.selectedImage = image
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        transitionDelegate.customHeight = 500
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func navigateToSearch(game: GamerConnectGame){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToSearch(game: game)
    }
    
    func updateNavColor(color: UIColor) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
