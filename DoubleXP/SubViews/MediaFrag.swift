//
//  MediaFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import moa
import SwiftHTTP
import SwiftNotificationCenter
import WebKit
import SwiftRichString
import FBSDKCoreKit
import Lottie
import UnderLineTextField
import SPStorkController

class MediaFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, MediaCallbacks, SocialMediaManagerCallback, LandingUICallbacks, SearchCallbacks, UITextFieldDelegate, UIScrollViewDelegate, SPStorkControllerDelegate {
    
    @IBOutlet weak var authorCell: UIView!
    @IBOutlet weak var articleVideoView: UIView!
    @IBOutlet weak var articleTable: UITableView!
    @IBOutlet weak var gcTag: UILabel!
    @IBOutlet weak var channelDXPLogo: UIImageView!
    @IBOutlet weak var twitchPlayerOverlay: UIView!
    @IBOutlet weak var channelLoading: UIView!
    @IBOutlet weak var channelCollection: UICollectionView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var videosButton: UIButton!
    @IBOutlet weak var streamsButton: UIButton!
    @IBOutlet weak var channelOverlayClose: UIImageView!
    @IBOutlet weak var channelOverlayDesc: UILabel!
    @IBOutlet weak var channelOverlayImage: UIImageView!
    @IBOutlet weak var twitchChannelOverlay: UIView!
    @IBOutlet weak var expandLabel: UILabel!
    @IBOutlet weak var collapseButton: UIImageView!
    @IBOutlet weak var expandButton: UIImageView!
    @IBOutlet weak var articleBlur: UIVisualEffectView!
    @IBOutlet weak var articleOverlay: UIView!
    @IBOutlet weak var articleHeader: UIView!
    @IBOutlet weak var optionsCollection: UICollectionView!
    @IBOutlet weak var news: UICollectionView!
    @IBOutlet weak var articleAuthorBadge: UIImageView!
    @IBOutlet weak var articleSourceImage: UIImageView!
    @IBOutlet weak var articleName: UILabel!
    @IBOutlet weak var scoob: AnimationView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var scoobDismiss: UIButton!
    @IBOutlet weak var articleImage: UIImageView!
    @IBOutlet weak var articleWV: WKWebView!
    @IBOutlet weak var videoAvailLabel: UILabel!
    @IBOutlet weak var playLogo: UIImageView!
    @IBOutlet weak var twitchWV: WKWebView!
    @IBOutlet weak var twitchOptionDrawer: UIView!
    @IBOutlet weak var twitchOptionTable: UITableView!
    @IBOutlet weak var clickableSpace: UIView!
    @IBOutlet weak var scoobLoading: UIVisualEffectView!
    @IBOutlet weak var dismissHead: UILabel!
    @IBOutlet weak var dismissBody: UILabel!
    @IBOutlet weak var scoobSub: UIView!
    @IBOutlet weak var searchField: UnderLineTextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var workAnimation: AnimationView!
    @IBOutlet weak var twitchOptionClose: UIButton!
    @IBOutlet weak var loadingView: UIVisualEffectView!
    @IBOutlet weak var fade: UIView!
    @IBOutlet weak var fadeHeight: NSLayoutConstraint!
    var options = [String]()
    var selectedCategory = ""
    var newsSet = false
    var articles = [Any]()
    var viewSet = false
    var articleSet = false
    var selectedArticle: NewsObject!
    var selectedArticleImage: UIImage?
    var articlePayload = [Any]()
    var twitchPayload = [Any]()
    var twitchCoverShowing = false
    var twitchShowing = false
    var currentCell: NewsArticleCell?
    var selectedChannel: TwitchChannelObj!
    var currentVideoCell: ArticleVideoCell?
    var constraint : NSLayoutConstraint?
    var channelConstraint : NSLayoutConstraint?
    var streams = [Any]()
    var currentCategory = "news"
    var isSearch = false
    var channelsSet = false
    var currentStream: TwitchStreamObject?
    
    let headerViewMaxHeight: CGFloat = 250
    let headerViewMinHeight: CGFloat = 44 + UIApplication.shared.statusBarFrame.height
    var discoverGameName: String?
    
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    
    var articlesLoaded = false
    private var streamsSet = false
    @IBOutlet weak var loadingViewSpinner: UIActivityIndicatorView!
    
    private let refreshControl = UIRefreshControl()
    private let channelRefreshControl = UIRefreshControl()
    
    @IBOutlet weak var standby: UIView!
    
    var mediaFragActive = false
    var channelOpen = false
    var articleOpen = false
    var fromDiscover = false
    
    var currentTwitchImage: Image?
    private var isExpanded = false
    
    @IBOutlet private var maxWidthConstraint: NSLayoutConstraint! {
        didSet {
            maxWidthConstraint.isActive = false
        }
    }
    
    struct Constants {
        static let spacing: CGFloat = 16
        static let secret = "uyvhqn68476njzzdvja9ulqsb8esn3"
        static let id = "aio1d4ucufi6bpzae0lxtndanh3nob"
    }
    
    var maxWidth: CGFloat? = nil {
        didSet {
            guard let maxWidth = maxWidth else {
                return
            }
            maxWidthConstraint.isActive = true
            maxWidthConstraint.constant = maxWidth
        }
    }
    
    let styleBase = Style({
        $0.color = UIColor.white
    })
    
    let styleBaseDark = Style({
        $0.color = UIColor.black
    })
    
    let testAttr = Style({
        $0.font = UIFont.boldSystemFont(ofSize: 20)
        $0.color = UIColor.blue
    })
    
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var twitchLoginButton: UIView!
    @IBOutlet weak var twitchCover: UIView!
    @IBOutlet weak var articleOverlayClose: UIImageView!
    private var standbyShowing = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageName = "Media"
        
        options.append("#popular")
        options.append("#reviews")
        options.append("#twitch")
        options.append("empty")
        
        self.workAnimation.loopMode = .loop
        self.workAnimation.play()
        
        self.selectedCategory = options[0]
        
        if #available(iOS 10.0, *) {
            self.news.refreshControl = refreshControl
            self.channelCollection.refreshControl = channelRefreshControl
        } else {
            self.news.addSubview(refreshControl)
            self.channelCollection.addSubview(channelRefreshControl)
        }
        self.news.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        self.channelCollection.refreshControl?.addTarget(self, action: #selector(downloadStreams), for: .valueChanged)
        self.searchField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.searchField.returnKeyType = .done
        self.searchField.delegate = self
        checkSearchButton()
        //optionsCollection.dataSource = self
        //optionsCollection.delegate = self
        setupScoob()
        
        self.constraint = NSLayoutConstraint(item: self.articleOverlay, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 0)
        
        self.channelConstraint = NSLayoutConstraint(item: self.twitchChannelOverlay, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 0)
        
        self.constraint?.isActive = true
        self.channelConstraint?.isActive = true
        
        let expand = UITapGestureRecognizer(target: self, action: #selector(expandOverlay))
        expandButton.isUserInteractionEnabled = true
        expandButton.addGestureRecognizer(expand)
        
        Broadcaster.register(SearchCallbacks.self, observer: self)
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media"))
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            self.hideScoob()
        }
        
        self.header.layer.shadowColor = UIColor.black.cgColor
        self.header.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.header.layer.shadowRadius = 2.0
        self.header.layer.shadowOpacity = 0.5
        self.header.layer.masksToBounds = false
        
        let testBounds = CGRect(x: self.header.bounds.minX, y: self.header.bounds.minY, width: self.view.bounds.width, height: self.header.bounds.height)
        self.header.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: self.header.layer.cornerRadius).cgPath

        if(self.discoverGameName != nil){
            animateViewForChannel()
        } else {
            animateView()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        if(self.searchField.text!.count > 0){
            self.searchForStreamer()
            self.view.endEditing(true)
        }
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        checkSearchButton()
    }
    
    private func checkSearchButton(){
        if(self.searchField.text!.count > 0 && self.searchButton.alpha != 1.0){
            UIView.animate(withDuration: 0.3, animations: {
                self.searchButton.alpha = 1
                self.searchButton.isUserInteractionEnabled = true
                self.searchButton.addTarget(self, action: #selector(self.searchForStreamer), for: .touchUpInside)
            }, completion: nil)
        } else if(self.searchField.text!.count > 0 && self.searchButton.alpha == 1.0) {
            self.searchButton.alpha = 1
            self.searchButton.isUserInteractionEnabled = true
            self.searchButton.addTarget(self, action: #selector(self.searchForStreamer), for: .touchUpInside)
        } else if(self.searchField.text!.count == 0 && self.searchButton.alpha == 1.0){
            UIView.animate(withDuration: 0.3, animations: {
                self.searchButton.alpha = 0.3
                self.searchButton.isUserInteractionEnabled = false
            }, completion: nil)
        } else {
            self.searchButton.alpha = 0.3
            self.searchButton.isUserInteractionEnabled = false
        }
    }
    
    @objc private func searchForStreamer(){
        self.isSearch = true
        self.view.endEditing(true)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 1
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.workAnimation.loopMode = .loop
                self.workAnimation.play()
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let manager = delegate.socialMediaManager
                manager.searchStreams(searchQuery: self.searchField.text!, callbacks: self)
            }
        })
    }
    
    private func showStandby(){
        if(!self.standbyShowing){
            UIView.animate(withDuration: 0.5, animations: {
                self.standby.alpha = 1
                self.standby.isUserInteractionEnabled = true
            }, completion: nil)
        }
    }
    
    private func hideStandby(){
        if(!self.standbyShowing){
            UIView.animate(withDuration: 0.5, animations: {
                self.standby.alpha = 0
                self.standby.isUserInteractionEnabled = false
            }, completion: nil)
        }
    }
    
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y: CGFloat = scrollView.contentOffset.y
        let newHeaderViewHeight: CGFloat = self.headerHeight.constant - y

        if newHeaderViewHeight > headerViewMaxHeight {
            self.headerHeight.constant = headerViewMaxHeight
        } else if newHeaderViewHeight < headerViewMinHeight {
            self.headerHeight.constant = headerViewMinHeight
        } else {
            self.headerHeight.constant = newHeaderViewHeight
            scrollView.contentOffset.y = 0 // block scroll view
        }
    }*/
    
    @objc func pullToRefresh(){
        if(self.currentCategory == "news"){
            getMedia()
        }
        else if(self.currentCategory == "reviews"){
            getReviews()
        }
        else{
            if(self.refreshControl.isRefreshing){
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func getMedia(){
        if(self.loadingView.alpha == 0){
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 1
                self.loadingViewSpinner.startAnimating()
            }, completion: { (finished: Bool) in
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let manager = delegate.mediaManager
                manager.getGameSpotNews(callbacks: self)
            })
        }
        else{
            self.loadingViewSpinner.startAnimating()
             
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = delegate.mediaManager
            manager.getGameSpotNews(callbacks: self)
        }
    }
    
    @objc func getReviews(){
        if(self.loadingView.alpha == 0){
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 1
                self.loadingViewSpinner.startAnimating()
            }, completion: { (finished: Bool) in
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let manager = delegate.mediaManager
                manager.getReviews(callbacks: self)
            })
        }
        else{
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = delegate.mediaManager
            manager.getReviews(callbacks: self)
        }
    }
    
    private func animateView(){
        self.twitchShowing = true
        self.currentCategory = "twitch"
        self.articlesLoaded = false
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Twitch Selected"))
        //let delegate = UIApplication.shared.delegate as! AppDelegate
        //delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
        //delegate.currentLanding?.removeBottomNav(showNewNav: true, hideSearch: false, searchHint:"search for stream", searchButtonText: "search", isMessaging: false)
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.articles = [Any]()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let manager = appDelegate.socialMediaManager
            manager.getTwitchGames(callbacks: self)
        }
    }
    
    private func animateViewForChannel(){
        self.twitchShowing = true
        self.currentCategory = "twitch"
        self.articlesLoaded = false
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Twitch Selected"))
        //let delegate = UIApplication.shared.delegate as! AppDelegate
        //delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
        //delegate.currentLanding?.removeBottomNav(showNewNav: true, hideSearch: false, searchHint:"search for stream", searchButtonText: "search", isMessaging: false)
       
        self.articles = [Any]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var game: GamerConnectGame?
        for gc in appDelegate.gcGames {
            if(gc.gameName == self.discoverGameName){
                game = gc
            }
        }
        
        if(game != nil){
            self.fromDiscover = true
            self.selectedChannel = TwitchChannelObj(gameName: game!.gameName, imageUrIOS: game!.imageUrl, twitchID: game!.twitchHandle)
            self.showChannel(channel: self.selectedChannel)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == optionsCollection){
            return options.count
        }
        else if(collectionView == self.channelCollection){
            return self.streams.count
        }
        else{
            return articles.count
        }
    }
    
    private func scrollToTop(collectionView: UICollectionView){
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 0),
              at: .top,
        animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == optionsCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MediaCategoryCell
            let current = self.options[indexPath.item]
            
            if(current == "empty"){
                cell.mediaCategory.isHidden = true
                cell.categoryContents.isHidden = true
                cell.contentView.backgroundColor = .clear
                cell.isUserInteractionEnabled = false
                cell.categoryImg.isHidden = true
            }
            else{
                if(current == "#twitch"){
                    cell.contentView.backgroundColor = #colorLiteral(red: 0.395016551, green: 0.2572917342, blue: 0.6494273543, alpha: 1)
                    cell.mediaCategory.textColor = UIColor(named: "stayWhite")
                    cell.categoryContents.textColor = UIColor(named: "stayWhite")
                    cell.categoryImg.image = #imageLiteral(resourceName: "twitch_white.png")
                    cell.categoryImg.contentMode = .scaleAspectFill
                    cell.categoryImg.clipsToBounds = true
                    
                    cell.categoryContents.text = "streams/videos"
                }
                if(current == "#popular"){
                    cell.categoryContents.text = "what's goin' on"
                }
                if(current == "#reviews"){
                    cell.categoryContents.text = "game reviews"
                }
                
                cell.contentView.layer.cornerRadius = 20.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true
                
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: cell.bounds.width + 20, height: cell.bounds.height + 20)
                cell.layer.shadowRadius = 2.0
                cell.layer.shadowOpacity = 0.8
                cell.layer.masksToBounds = false
                cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
                
                
                cell.mediaCategory.text = current
            }
            
            return cell
        }
        else if(collectionView == self.channelCollection){
            let current = self.streams[indexPath.item]
            
            if(current is AdObject){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ad", for: indexPath) as! AdCell
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                cell.setAd(landingController: appDelegate.currentLanding!)
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contentCell", for: indexPath) as! TwitchContentCell
                if(current is TwitchStreamObject){
                    let current = (self.streams[indexPath.item] as! TwitchStreamObject)
                    cell.channelName.text = current.title
                    cell.channelUser.text = current.handle
                    
                    let str = current.thumbnail
                    let replaced = str.replacingOccurrences(of: "{width}x{height}", with: "800x500")
                    cell.contentImage.image = Utility.Image.placeholder
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let cache = appDelegate.imageCache
                    if(cache.object(forKey: replaced as NSString) != nil){
                        cell.contentImage.image = cache.object(forKey: replaced as NSString)
                    } else {
                        cell.contentImage.image = Utility.Image.placeholder
                        cell.contentImage.moa.onSuccess = { image in
                            cell.contentImage.image = image
                            appDelegate.imageCache.setObject(image, forKey: replaced as NSString)
                            return image
                        }
                        cell.contentImage.moa.url = replaced
                    }
                    cell.contentImage.contentMode = .scaleAspectFill
                    cell.contentImage.clipsToBounds = true
                }
                return cell
            }
        }
        else{
            let current = self.articles[indexPath.item]
            if(current is NewsObject){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
                cell.title.text = (current as! NewsObject).title
                
                if((current as! NewsObject).videoUrl.isEmpty){
                    cell.contents.text = "READ"
                } else {
                    cell.contents.text = "READ - WATCH"
                }
                
                switch ((current as! NewsObject).author) {
                case "Kwatakye Raven":
                    //cell..text = "DoubleXP"
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.sourceImage.image = #imageLiteral(resourceName: "dxp_disc_dark_boom.png")
                    break
                case "Aaron Hodges":
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.sourceImage.image = #imageLiteral(resourceName: "dxp_disc_dark_boom.png")
                    break
                default:
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.sourceImage.image = #imageLiteral(resourceName: "gamespot_icon_ios.png")
                }
                
                cell.articleBack.image = #imageLiteral(resourceName: "new_logo3.png")
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let cache = appDelegate.imageCache
                if(cache.object(forKey: (current as! NewsObject).imageUrl as NSString) != nil){
                    cell.articleBack.image = cache.object(forKey: (current as! NewsObject).imageUrl as NSString)
                } else {
                    cell.articleBack.image = Utility.Image.placeholder
                    cell.articleBack.moa.onSuccess = { image in
                        cell.articleBack.image = image
                        cell.articleBack.alpha = 0.3
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
            else {
                let current = self.articles[indexPath.item]
                if(current is TwitchChannelObj){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! TwitchChannelCell
                    cell.gameName.text = (current as! TwitchChannelObj).gameName
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let str = (current as! TwitchChannelObj).imageUrlIOS
                    let replaced = str.replacingOccurrences(of: "{width}x{height}", with: "800x500")
                    
                    let cache = delegate.imageCache
                    if(cache.object(forKey: replaced as NSString) != nil){
                        cell.image.image = cache.object(forKey: replaced as NSString)
                    } else {
                        cell.image.image = Utility.Image.placeholder
                        cell.image.moa.onSuccess = { image in
                            cell.image.image = image
                            delegate.imageCache.setObject(image, forKey: replaced as NSString)
                            return image
                        }
                        cell.image.moa.url = replaced
                    }
                    cell.image.contentMode = .scaleAspectFill
                    cell.image.clipsToBounds = true
                    
                    cell.contentView.layer.cornerRadius = 10.0
                    cell.contentView.layer.borderWidth = 1.0
                    cell.contentView.layer.borderColor = UIColor.clear.cgColor
                    cell.contentView.layer.masksToBounds = true
                    
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                    cell.layer.shadowRadius = 2.0
                    cell.layer.shadowOpacity = 0.5
                    cell.layer.masksToBounds = false
                    cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius:
                        cell.contentView.layer.cornerRadius).cgPath
                    //cell.devLogo.contentMode = .scaleAspectFill
                    //cell.devLogo.clipsToBounds = true
                    
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! EmptyCollectionViewCell
                    return cell
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == optionsCollection){
            if(self.articlesLoaded){
                let current = self.options[indexPath.item]
                
                self.selectedCategory = current
                let cell = collectionView.cellForItem(at: indexPath) as! MediaCategoryCell
                cell.mediaCategory.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                if(cell.mediaCategory.text == "#twitch"){
                    cell.mediaCategory.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                }
                
                for cell in self.optionsCollection.visibleCells{
                    let currentCell = cell as! MediaCategoryCell
                    if(currentCell.mediaCategory.text != current){
                        currentCell.mediaCategory.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
                    }
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                switch(self.selectedCategory){
                    case "#popular":
                        self.loadingViewSpinner.startAnimating()
                        self.currentCategory = "news"
                        self.articlesLoaded = false
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Popular Selected"))
                        delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                        
                        if(twitchShowing){
                            self.twitchShowing = false
                            
                            delegate.currentLanding?.removeBottomNav(showNewNav: false, hideSearch: false, searchHint: nil, searchButtonText: nil, isMessaging: false)
                        }
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            self.loadingView.alpha = 1
                        }, completion: { (finished: Bool) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                                
                                if(!delegate.mediaCache.reviewsCache.isEmpty){
                                    self.onMediaReceived(category: "news")
                                }
                                else{
                                    self.getMedia()
                                }
                            }
                        })
                    
                    break;
                    case "#twitch":
                        self.twitchShowing = true
                        self.loadingViewSpinner.startAnimating()
                        self.currentCategory = "twitch"
                        self.articlesLoaded = false
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Twitch Selected"))
                        //delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
                        delegate.currentLanding?.removeBottomNav(showNewNav: true, hideSearch: false, searchHint:"search for stream", searchButtonText: "search", isMessaging: false)
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            self.loadingView.alpha = 1
                        }, completion: { (finished: Bool) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.articles = [Any]()
                                
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                let manager = appDelegate.socialMediaManager
                                manager.getTwitchGames(callbacks: self)
                            }
                        })
                    break;
                    case "#reviews":
                        self.loadingViewSpinner.startAnimating()
                        self.currentCategory = "reviews"
                        self.articlesLoaded = false
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Reviews Selected"))
                        delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                        if(twitchShowing){
                            self.twitchShowing = false
                            
                            delegate.currentLanding?.removeBottomNav(showNewNav: false, hideSearch: false, searchHint: nil, searchButtonText: nil, isMessaging: false)
                        }
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            self.loadingView.alpha = 1
                        }, completion: { (finished: Bool) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                                
                                if(!delegate.mediaCache.reviewsCache.isEmpty){
                                    self.onMediaReceived(category: "reviews")
                                }
                                else{
                                    self.getReviews()
                                }
                            }
                        })
                    break;
                    default:
                        self.twitchShowing = false
                        self.articles = [Any]()
                        self.articlesLoaded = false
                        articles.append(contentsOf: delegate.mediaCache.newsCache)
                        delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                        
                        if(self.twitchCoverShowing){
                            UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                                self.header.backgroundColor = UIColor(named: "dark")
                                self.optionsCollection.backgroundColor = UIColor(named: "darkOpacity")
                            })
                            
                            delegate.currentLanding?.updateNavColor(color: UIColor(named: "darker")!)
                                
                            UIView.animate(withDuration: 0.8, animations: {
                                    self.twitchCover.alpha = 0
                            }, completion: { (finished: Bool) in
                                self.news.performBatchUpdates({
                                    let indexSet = IndexSet(integersIn: 0...0)
                                    self.news.reloadSections(indexSet)
                                }, completion: nil)
                            })
                            
                            self.twitchCoverShowing = false
                        }
                        else{
                            self.news.performBatchUpdates({
                                let indexSet = IndexSet(integersIn: 0...0)
                                self.news.reloadSections(indexSet)
                            }, completion: nil)
                        }
                    break;
                }
            }
        }
        else if(collectionView == channelCollection){
            let current = streams[indexPath.item]
        
            if(current is TwitchStreamObject){
                NotificationCenter.default.addObserver(
                    forName: UIWindow.didBecomeKeyNotification,
                    object: self.view.window,
                    queue: nil
                ) { notification in
                    print("Video stopped")
                    //self.twitchPlayer.isHidden = true
                    //self.twitchPlayer.setChannel(to: "")
                    
                    UIView.animate(withDuration: 0.8) {
                        self.twitchPlayerOverlay.alpha = 0
                    }
                }
                
                self.showScoob(callback: self, cancelableWV: self.twitchWV)
                //loading twitch streams
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let test = "https://doublexpstorage.tech/stream.php?channel=" + (current as! TwitchStreamObject).handle
                    
                    if let encoded = test.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                        let url = URL(string: encoded)
                    {
                        self.twitchWV.load(NSURLRequest(url: url) as URLRequest)
                    } else {
                        let root = "https://doublexpstorage.tech/stream.php?channel="
                        let path = (current as! TwitchStreamObject).handle
                        var urlcomps = URLComponents(string: root)!
                        urlcomps.path = path
                        if let newUrl = urlcomps.url {
                            self.twitchWV.load(NSURLRequest(url: newUrl) as URLRequest)
                            return
                        }
                        
                        self.hideScoob()
                    }
                    
                    
                    /*if(test != nil && !test.isEmpty){
                        self.twitchWV.load(NSURLRequest(url: NSURL(string: test)! as URL) as URLRequest)
                    } else {
                        self.hideScoob()
                    }*/
                }
            }
        }
        else {
            let current = self.articles[indexPath.item]
            if(current is NewsObject){
                let cell = collectionView.cellForItem(at: indexPath) as! NewsArticleCell
                self.selectedArticle = (current as! NewsObject)
                self.selectedArticleImage = cell.articleBack.image
                self.currentCell = cell
            
                let top = CGAffineTransform(translationX: 0, y: 800)
                UIView.animate(withDuration: 0.8, animations: {
                    cell.transform = top
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.showArticle(article: self.selectedArticle)
                    }, completion: nil)
                })
                
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "Article Selected: Source - " + selectedArticle.source))
                //onVideoLoaded(url: "https://static-gamespotvideo.cbsistatic.com/vr/2019/04/23/kingsfieldiv1_700_1000.mp4")
                
                
                /*if(self.selectedArticle.source == "gs"){
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.mediaManager.downloadVideo(title: self.selectedArticle.title, url: selectedArticle.videoUrl, callbacks: self)
                }
                else{
                    onVideoLoaded(url: self.selectedArticle.videoUrl)
                }*/
            }
            
            if(current is TwitchChannelObj){
                let cell = collectionView.cellForItem(at: indexPath) as! TwitchChannelCell
                self.currentTwitchImage = cell.image.image
                self.selectedChannel = (current as! TwitchChannelObj)
                
                self.showChannel(channel: self.selectedChannel)
            }
        }
    }
    
    func showArticle(article: NewsObject){
        self.articleOverlay.alpha = 1
        self.twitchChannelOverlay.alpha = 0
        self.articlePayload = [Any]()
        
        self.articleName.text = self.selectedArticle.title
        
        let source = self.selectedArticle.source
        if(source == "gs"){
            self.articleSourceImage.image = #imageLiteral(resourceName: "gamespot_icon_ios.png")
        }
        else{
            self.articleSourceImage.image = #imageLiteral(resourceName: "new_logo.png")
        }
        
        let author = self.selectedArticle.author
        switch (author) {
        case "Kwatakye Raven":
            //cell..text = "DoubleXP"
            self.authorLabel.text = author
            self.articleAuthorBadge.image = #imageLiteral(resourceName: "mike_badge.png")
            break
        case "Aaron Hodges":
            self.authorLabel.text = author
            self.articleAuthorBadge.image = #imageLiteral(resourceName: "hodges_badge.png")
            break
        default:
            self.authorLabel.text = author
            self.articleAuthorBadge.image = #imageLiteral(resourceName: "unknown_badge.png")
        }
        
        if(self.selectedArticle.videoUrl.isEmpty){
            self.playLogo.alpha = 0.1
            self.videoAvailLabel.text = "No Video Available"
            self.articleVideoView.isUserInteractionEnabled = false
            
            self.articleImage.alpha = 0
            self.articleWV.alpha = 0
        }
        else{
            let videoTap = UITapGestureRecognizer(target: self, action: #selector(videoClicked))
            self.articleVideoView.isUserInteractionEnabled = true
            self.articleVideoView.addGestureRecognizer(videoTap)
            
            if(self.selectedArticleImage != nil){
                self.articleImage.image = self.selectedArticleImage
                self.articleImage.contentMode = .scaleAspectFill
                self.articleImage.clipsToBounds = true
                self.articleImage.alpha = 0.1
            }
            self.articleWV.alpha = 1
        }
        
        let authorTap = UITapGestureRecognizer(target: self, action: #selector(authorClicked))
        self.authorCell.isUserInteractionEnabled = true
        self.authorCell.addGestureRecognizer(authorTap)
        
        
        self.articlePayload.append(article.storyText)
        
        if(!self.articleSet){
            self.articleTable.delegate = self
            self.articleTable.dataSource = self
        
            self.articleSet = true
        }
        else{
            self.articleTable.reloadData()
        }
        
        self.expandButton.isHidden = false
        self.expandLabel.isHidden = false
        
        let close = UITapGestureRecognizer(target: self, action: #selector(closeOverlay))
        articleOverlayClose.isUserInteractionEnabled = true
        articleOverlayClose.addGestureRecognizer(close)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.articleBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                self.constraint?.constant = self.view.frame.size.height
                
                UIView.animate(withDuration: 0.5) {
                    self.articleOverlay.alpha = 1
                    self.view.bringSubviewToFront(self.articleOverlay)
                    
                    self.expandOverlay()
                    self.view.layoutIfNeeded()
                }
                
            
            }, completion: nil)
        })
        
        self.articleOpen = true
    }
    
    @objc func videoClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.showScoob(callback: self, cancelableWV: self.articleWV)
        
        if(self.selectedArticle.source == "gs"){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Media - GS Video Selected"))
            delegate.mediaManager.downloadVideo(title: self.selectedArticle.title, url: selectedArticle.videoUrl, callbacks: self)
        }
        else{
            AppEvents.logEvent(AppEvents.Name(rawValue: "Media - DXP Video Selected"))
            self.onVideoLoaded(url: selectedArticle.videoUrl)
        }
    }
    
    @objc func authorClicked(_ sender: AnyObject?) {
        let author = self.selectedArticle.author
        switch (author) {
        case "Kwatakye Raven":
            //cell..text = "DoubleXP"
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToProfile(uid: getHomeUid(position: 2))
            break
        case "Aaron Hodges":
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToProfile(uid: getHomeUid(position: 1))
            break
        default:
            print("do nothing")
        }
    }
    
    private func getHomeUid(position: Int) -> String{
        if(position == 1){
            return "oFdx8UequuOs77s8daWFifODVhJ3"
        }
        
        if(position == 2){
            return "N1k1BqmvEvdOXrbmi2p91kTNLOo1"
        }
        
        return ""
    }
    
    func showChannel(channel: TwitchChannelObj){
        self.articleOverlay.alpha = 0
        self.twitchChannelOverlay.alpha = 1
        self.channelOverlayDesc.text = channel.gameName
        if(channel.isGCGame == "true"){
            self.channelDXPLogo.isHidden = false
            self.connectButton.isHidden = false
            self.connectButton.isUserInteractionEnabled = true
            self.gcTag.isHidden = false
        }
        else{
            self.channelDXPLogo.isHidden = true
            self.connectButton.isHidden = true
            self.connectButton.isUserInteractionEnabled = false
            self.gcTag.isHidden = true
        }
        
        if(self.fromDiscover){
            self.channelOverlayClose.alpha = 0
        } else {
            self.channelOverlayClose.alpha = 1.0
            let close = UITapGestureRecognizer(target: self, action: #selector(closeChannel))
            self.channelOverlayClose.isUserInteractionEnabled = true
            self.channelOverlayClose.addGestureRecognizer(close)
        }
        
        self.downloadStreams()
        //streamsButton.addTarget(self, action: #selector(downloadStreams), for: .touchUpInside)
        videosButton.addTarget(self, action: #selector(downloadVideos), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(navigateToConnect), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.articleBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                self.channelConstraint?.constant = self.view.frame.size.height
                
                UIView.animate(withDuration: 0.5) {
                    self.twitchChannelOverlay.alpha = 1
                    self.view.bringSubviewToFront(self.twitchChannelOverlay)
                    self.view.layoutIfNeeded()
                }
            }, completion: nil)
        })
        
        self.channelOpen = true
    }
    
    func onReviewsReceived(payload: [NewsObject]) {
    }
    
    func onMediaReceived(category: String) {
        DispatchQueue.main.async() {
            if(self.refreshControl.isRefreshing){
                self.refreshControl.endRefreshing()
            }
            
            self.articles = [Any]()
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentMediaFrag = self
            
            if(category == "news"){
                self.articles.append(contentsOf: delegate.mediaCache.newsCache)
            }
            else if(category == "reviews"){
                self.articles.append(contentsOf: delegate.mediaCache.reviewsCache)
            }
            else{
                //"show error"
                return
            }
            
            if(!self.newsSet){
                
               //let layout = AnimatedCollectionViewLayout()
               //layout.animator = LinearCardAttributesAnimator()
               // layout.scrollDirection = .horizontal

               // self.news?.collectionViewLayout = layout
                
                self.news.delegate = self
                self.news.dataSource = self
                self.newsSet = true
                
                let top = CGAffineTransform(translationX: 0, y: 40)
                UIView.animate(withDuration: 0.5, animations: {
                    self.news.transform = top
                    self.news.alpha = 1
                    self.articlesLoaded = true
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.loadingView.alpha = 0
                        self.workAnimation.pause()
                    }, completion: nil)
                })
            }
            else{
                //let layout = AnimatedCollectionViewLayout()
                //layout.animator = LinearCardAttributesAnimator()
                //layout.scrollDirection = .horizontal

                //self.news?.collectionViewLayout = layout
                self.news?.reloadData()
                self.news.setContentOffset(CGPoint(x:0,y:0), animated: true)
                
                //self.news?.collectionViewLayout = TestCollection()
                //self.news.reloadData()
                self.scrollToTop(collectionView: self.news)
                UIView.animate(withDuration: 0.3, animations: {
                    self.news.alpha = 1
                    self.articlesLoaded = true
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.loadingView.alpha = 0
                        self.workAnimation.pause()
                    }, completion: nil)
                })
            }
        }
    }
    
    func onVideoLoaded(url: String) {
        //loading videos for articles
        DispatchQueue.main.async() {

            if let videoURL:URL = URL(string: url) {
                
                let embedHTML = "<html><head><meta name='viewport' content='width=device-width, initial-scale=0.0, maximum-scale=1.0, minimum-scale=0.0'></head> <iframe width=\(self.currentCell!.bounds.width)\" height=\(self.currentCell!.bounds.width)\" src=\(videoURL)?&playsinline=1\" frameborder=\"0\" allowfullscreen></iframe></html>"
                
                self.articleWV.loadHTMLString(embedHTML, baseURL: nil)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("gone")
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("gone")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.articleWV.removeObserver(self, forKeyPath: #keyPath(UIViewController.view.frame))
        //self.navigationController?.popViewController(animated: false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in

        if complete != nil {
          let height = webView.scrollView.contentSize
          print("height of webView is: \(height)")
        }
      })
    }
    
    func windowDidBecomeVisible(notification: NSNotification) {
        print("open")
    }
    
    @objc func downloadStreams(){
        self.streams.removeAll()
        self.channelCollection.performBatchUpdates({
            let indexSet = IndexSet(integersIn: 0...0)
            self.channelCollection.reloadSections(indexSet)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.channelLoading.alpha = 1
        }, completion: { (finished: Bool) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let manager = appDelegate.socialMediaManager
            manager.loadTwitchStreams2DotOhChannel(currentChannel: self.selectedChannel, callbacks: self)
        })
    }
    
    @objc func downloadVideos(){
        self.streams.removeAll()
        self.channelCollection.performBatchUpdates({
            let indexSet = IndexSet(integersIn: 0...0)
            self.channelCollection.reloadSections(indexSet)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.channelLoading.alpha = 1
        }, completion: { (finished: Bool) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let manager = appDelegate.socialMediaManager
            //manager.getChannelTopVideos(currentChannel: self.selectedChannel, callbacks: self)
        })
    }
    
    @objc func expandOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Article Expand"))
        self.isExpanded = true
        self.expandButton.isHidden = true
        self.expandLabel.isHidden = true
        
        self.constraint?.constant = self.view.frame.size.height
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            
            self.articleTable.reloadData()
        }
    }
    
    @objc func navigateToConnect(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var currentGame: GamerConnectGame? = nil
        for game in delegate.gcGames{
            if(game.gameName == self.selectedChannel.gcGameName){
                currentGame = game
                break
            }
        }
        
        if(currentGame != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Navigate To Search"))
            
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
            currentViewController.game = currentGame!
            
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
        
    @objc func closeOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Close Article"))
        self.isExpanded = false
        self.constraint?.constant = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.articleOverlay.alpha = 1
            self.articleBlur.alpha = 0
        })
        
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.currentCell?.transform = top
            self.news.reloadData()
        }, completion: nil)
        
        reloadColView()
        
        self.articleOpen = false
    }
    
    @objc func closeChannel(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Media - Close Channel"))
        self.channelConstraint?.constant = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.twitchChannelOverlay.alpha = 1
            self.articleBlur.alpha = 0
        })
        
        reloadColView()
        
        self.streams = [TwitchStreamObject]()
        self.channelCollection.reloadData()
        
        self.channelOpen = false
    }
    
    private func reloadColView(){
        self.articleOverlay.setNeedsLayout()
        self.articleOverlay.layoutIfNeeded()
    }
    
    func showTwitchLogin(){
        if(!self.twitchCoverShowing){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            //delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
            /*UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                self.header.backgroundColor = UIColor(named: "twitchPurpleDark")
                self.optionsCollection.backgroundColor = UIColor(named: "twitchPurple")
                self.twitchCover.alpha = 1
            }, completion: nil)*/
            
            self.twitchCoverShowing = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if(collectionView == optionsCollection){
            //media options
            return CGSize(width: 123, height: CGFloat(126))
        }
        else if(collectionView == channelCollection){
            //twitch channel
            return CGSize(width: (channelCollection.bounds.width), height: 150)
        }
        else {
            let current = self.articles[indexPath.item]
            if(current is Int){
                if((current as? Int) == 0){
                    //empty cell
                    return CGSize(width: (collectionView.bounds.width), height: CGFloat(80))
                }
                else{
                    return CGSize(width: (collectionView.bounds.width - 20), height: CGFloat(200))
                }
            }
            else if(current is Bool){
                //if((current as! Bool) == false){
                    return CGSize(width: (collectionView.bounds.width), height: (collectionView.bounds.height))
                //}
            }
            else{
                if(self.twitchShowing){
                    return CGSize(width: (collectionView.bounds.width - 20), height: (100))
                } else {
                    return CGSize(width: (collectionView.bounds.width - 20), height: (collectionView.bounds.height - 20))
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == articleTable){
            return self.articlePayload.count
        } else {
            return self.streams.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == articleTable){
            let current = self.articlePayload[indexPath.item]
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as! ArticleTextCell
            
            let groupStyle = StyleXML.init(base: styleBase, ["strong" : testAttr])
            let attr = (current as! String).htmlToAttributedString
                          
            cell.label.attributedText = attr?.string.set(style: groupStyle)
            cell.label.font = UIFont(name: cell.label.font!.fontName, size: 18)
            
            return cell
        } else {
            let current = self.streams[indexPath.item] as! TwitchStreamObject
            let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! TwitchOptionCell
            cell.handle.text = current.handle
            
            if(current.isLive == "true"){
                cell.live.image = #imageLiteral(resourceName: "live_active.png")
            } else {
                cell.live.image = #imageLiteral(resourceName: "live_inactive.png")
            }
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == self.twitchOptionTable){
            let stream = self.streams[indexPath.item] as? TwitchStreamObject
            if(stream != nil){
                if(stream!.isLive == "true"){
                    currentStream = self.streams[indexPath.item] as? TwitchStreamObject
                    dismissTwitchDrawer()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == articleTable){
            return 1500.0;
        } else {
            return 100.0;
        }
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        print("closing")
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
    }
    
    func onChannelsLoaded(channels: [Any]) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var sortedPayload = [Any]()
        //my games first
        for channel in channels {
            if(channel is TwitchChannelObj){
                if(delegate.currentUser!.games.contains((channel as! TwitchChannelObj).gameName)){
                    sortedPayload.append(channel)
                }
            }
        }
        
        //all the rest
        for channel in channels {
            if(channel is TwitchChannelObj){
                if(!delegate.currentUser!.games.contains((channel as! TwitchChannelObj).gameName)){
                    sortedPayload.append(channel)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.articles = sortedPayload
            self.articles.append(0)
            if(!self.channelsSet){
                if(self.refreshControl.isRefreshing){
                    self.refreshControl.endRefreshing()
            }
            
            delegate.currentMediaFrag = self
            
            let top = CGAffineTransform(translationX: 0, y: 10)
            UIView.animate(withDuration: 0.8, animations: {
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                self.news?.collectionViewLayout = layout
                self.news.transform = top
                self.news.delegate = self
                self.news.dataSource = self
                self.news.alpha = 1
                self.channelsSet = true
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.loadingView.alpha = 0
                    self.workAnimation.pause()
                }, completion: nil)
            })
        } else {
                self.articles.append(contentsOf: channels)
                self.articles.append(0)
                
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                self.news?.collectionViewLayout = layout
                self.news.reloadData()
                self.news.setContentOffset(CGPoint(x:0,y:0), animated: true)
                
                UIView.animate(withDuration: 0.8, delay: 1, options: [], animations: {
                    self.loadingView.alpha = 0
                    self.articlesLoaded = true
                }, completion: nil)
            }
        }
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
        if(isSearch){
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.loadingView.alpha = 0
                }, completion: nil)
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "Twitch Search"))
                if(streams.count == 1){
                    self.showScoob(callback: self, cancelableWV: self.twitchWV)
                    //loading twitch streams
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Twitch Search Exact Match"))
                        if(streams[0] is TwitchStreamObject){
                            let test = "https://doublexpstorage.tech/stream.php?channel=" + (streams[0] as! TwitchStreamObject).handle
                            self.twitchWV.load(NSURLRequest(url: NSURL(string: test)! as URL) as URLRequest)
                        }
                    }
                    self.isSearch = false
                } else {
                    self.streams = [Any]()
                    self.streams.append(contentsOf: streams)
                    self.showTwitchOptions(streams: self.streams)
                }
            }
        } else {
            DispatchQueue.main.async {
                if(self.channelRefreshControl.isRefreshing){
                    self.channelRefreshControl.endRefreshing()
                }
                
                self.streams = [TwitchStreamObject]()
                self.streams.append(contentsOf: streams)
            
                if(!self.streamsSet){
                    self.channelCollection.collectionViewLayout = UICollectionViewFlowLayout()
                    self.channelCollection.dataSource = self
                    self.channelCollection.delegate = self
                    
                    self.streamsSet = true
                    
                    if(self.channelLoading.alpha == 1){
                        UIView.animate(withDuration: 0.8, animations: {
                            self.channelLoading.alpha = 0
                        }, completion: { (finished: Bool) in
                            UIView.animate(withDuration: 0.8, delay: 0.5, animations: {
                                self.loadingView.alpha = 0
                                self.workAnimation.stop()
                            }, completion: nil)
                        })
                    } else {
                        UIView.animate(withDuration: 0.8, animations: {
                            self.loadingView.alpha = 0
                            self.workAnimation.stop()
                        }, completion: nil)
                    }
                } else{
                    UIView.animate(withDuration: 0.8, animations: {
                        self.channelCollection.reloadData()
                        self.scrollToTop(collectionView: self.channelCollection)
                    }, completion: { (finished: Bool) in
                        if(self.channelLoading.alpha == 1){
                            self.channelLoading.alpha = 0
                        } else {
                            UIView.animate(withDuration: 0.8, delay: 0.5, animations: {
                                self.loadingView.alpha = 0
                                self.workAnimation.stop()
                            }, completion: { (finished: Bool) in
                            
                            })
                        }
                    })
                }
            }
        }
    }
    
    private func showTwitchOptions(streams: [Any]){
        self.searchButton.isUserInteractionEnabled = false
        self.searchField.isUserInteractionEnabled = false
        self.articleTable.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            AppEvents.logEvent(AppEvents.Name(rawValue: "Twitch Option Drawer Shown"))
            self.twitchOptionTable.delegate = self
            self.twitchOptionTable.dataSource = self
            self.twitchOptionTable.reloadData()
            
            let close = UITapGestureRecognizer(target: self, action: #selector(self.dismissTwitchDrawer))
            self.twitchOptionClose.addTarget(self, action: #selector(self.dismissTwitchDrawer), for: .touchUpInside)
            self.clickableSpace.isUserInteractionEnabled = true
            self.clickableSpace.addGestureRecognizer(close)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.articleBlur.alpha = 1
            }, completion: { (finished: Bool) in
                let top = CGAffineTransform(translationX: -300, y: 0)
                UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                    self.twitchOptionDrawer.transform = top
                }, completion: nil)
            })
        }
    }
    
    @objc private func dismissTwitchDrawer(){
        self.searchButton.isUserInteractionEnabled = true
        self.searchField.isUserInteractionEnabled = true
        self.articleTable.isUserInteractionEnabled = true
        if(self.currentStream != nil){
            self.showScoob(callback: self, cancelableWV: self.twitchWV)
            //loading twitch streams
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let test = "https://doublexpstorage.tech/stream.php?channel=" + self.currentStream!.handle
                self.twitchWV.load(NSURLRequest(url: NSURL(string: test)! as URL) as URLRequest)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let top = CGAffineTransform(translationX: 0, y: 0)
                    UIView.animate(withDuration: 0.3, animations: {
                        self.twitchOptionDrawer.transform = top
                    }, completion: { (finished: Bool) in
                        self.clickableSpace.isUserInteractionEnabled = false
                        self.articleBlur.alpha = 0
                    })
                }
            }
        } else {
            let top = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.3, animations: {
                self.twitchOptionDrawer.transform = top
            }, completion: { (finished: Bool) in
                self.articleBlur.isUserInteractionEnabled = false
                self.articleBlur.alpha = 0
                
                /*let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
                delegate.currentLanding?.removeBottomNav(showNewNav: true, hideSearch: false, searchHint:"search for stream", searchButtonText: "search", isMessaging: false)*/
            })
        }
        
        self.isSearch = false
    }
    
    func updateNavColor(color: UIColor) {
    }
    
    func onYoutubeFail() {
    }
    func onYoutubeSuccessful(videos: [YoutubeVideoObj]) {
    }
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection]) {
    }
    
    func searchSubmitted(searchString: String) {
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.loadingView.alpha = 1
        }, completion: nil)
        
        isSearch = true
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.socialMediaManager
        manager.searchStreams(searchQuery: searchString, callbacks: self)
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func showScoob(callback: LandingUICallbacks, cancelableWV: WKWebView?){
        resetDismissScoob()
        setupScoobCancel(cancelableWV: cancelableWV)
        
        let top = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.5, animations: {
            self.scoobLoading.alpha = 1
            self.scoobSub.transform = top
            self.scoobSub.alpha = 1
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                self.showDismissScoob()
            }
        }, completion: nil)
        
        scoob.loopMode = .loop
        scoob.play()
    }
    
    func setupScoobCancel(cancelableWV: WKWebView?) {
        if(cancelableWV != nil){
            cancelableWV?.stopLoading()
            cancelableWV?.loadHTMLString("", baseURL: nil)
        } else {
            hideScoob()
        }
    }
    
    func showDismissScoob(){
        let top3 = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.5, animations: {
            self.scoobDismiss.transform = top3
            self.dismissHead.transform = top3
            self.dismissBody.transform = top3
            self.scoobDismiss.alpha = 1
            self.dismissHead.alpha = 1
            self.dismissBody.alpha = 1
        }, completion: nil)
    }
    
    func resetDismissScoob(){
        let top3 = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.01, animations: {
            self.scoobDismiss.transform = top3
            self.dismissHead.transform = top3
            self.dismissBody.transform = top3
            self.scoobDismiss.alpha = 0
            self.dismissHead.alpha = 0
            self.dismissBody.alpha = 0
        }, completion: nil)
    }
    
    func setupScoob(){
        scoobSub.layer.cornerRadius = 10.0
        scoobSub.layer.borderWidth = 1.0
        scoobSub.layer.borderColor = UIColor.clear.cgColor
        scoobSub.layer.masksToBounds = true
        
        scoobSub.layer.shadowColor = UIColor.black.cgColor
        scoobSub.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        scoobSub.layer.shadowRadius = 2.0
        scoobSub.layer.shadowOpacity = 0.5
        scoobSub.layer.masksToBounds = false
        scoobSub.layer.shadowPath = UIBezierPath(roundedRect: scoobSub.layer.bounds, cornerRadius: scoobSub.layer.cornerRadius).cgPath
        
        scoobDismiss.layer.shadowColor = UIColor.black.cgColor
        scoobDismiss.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        scoobDismiss.layer.shadowRadius = 2.0
        scoobDismiss.layer.shadowOpacity = 0.5
        scoobDismiss.layer.masksToBounds = false
        scoobDismiss.layer.shadowPath = UIBezierPath(roundedRect: scoobDismiss.bounds, cornerRadius: scoobDismiss.layer.cornerRadius).cgPath
        //add more scoob layouts
        // -- like one that is like  (ACTUAL CONTROLLER SYMBOLS ->) " triangle triangle back forward" and then below have "Sub Zero's ice move" somethin like that. We can create a small library of these to pop up throughout the app whenever the loading screen shows.
   
        scoobDismiss.addTarget(self, action: #selector(hideScoob), for: .touchUpInside)
    }
    
    
    @objc func hideScoob(){
        if(self.scoobLoading.alpha == 1){
            let top = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.5, animations: {
                self.scoobLoading.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                    self.scoobSub.transform = top
                    self.scoobSub.alpha = 0
                    self.resetDismissScoob()
                    
                    self.scoob.stop()
                }, completion: nil)
            })
        }
    }

    
}
extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
