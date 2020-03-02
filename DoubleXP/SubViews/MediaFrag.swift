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
import ImageLoader
import moa
import SwiftHTTP
import SwiftNotificationCenter
import Hero
import WebKit

class MediaFrag: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MediaCallbacks {
    
    @IBOutlet weak var testPlayer: WKWebView!
    @IBOutlet weak var articleOverlay: UIView!
    @IBOutlet weak var articleHeader: UIView!
    @IBOutlet weak var articleCollection: UICollectionView!
    @IBOutlet weak var optionsCollection: UICollectionView!
    @IBOutlet weak var news: UICollectionView!
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
    var currentWV: WKWebView?
    var currentCell: NewsArticleCell?
    
    struct Constants {
        static let secret = "uyvhqn68476njzzdvja9ulqsb8esn3"
        static let id = "aio1d4ucufi6bpzae0lxtndanh3nob"
    }
    
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var twitchLoginButton: UIView!
    @IBOutlet weak var twitchCover: UIView!
    @IBOutlet weak var articleOverlayClose: UIImageView!
    @IBOutlet weak var articleOverlaySourceImage: UIImageView!
    @IBOutlet weak var articleOverlayBadge: UIImageView!
    @IBOutlet weak var articleOverlaySource: UILabel!
    @IBOutlet weak var articleOverlayAuthor: UILabel!
    @IBOutlet weak var articleOverlaySub: UILabel!
    @IBOutlet weak var articleOverlayTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        options.append("popular")
        options.append("twitch")
        options.append("reviews")
        
        self.selectedCategory = options[0]
        
        twitchLoginButton.applyGradient(colours:  [#colorLiteral(red: 0.3081886768, green: 0.1980658174, blue: 0.5117434263, alpha: 1), #colorLiteral(red: 0.395016551, green: 0.2572917342, blue: 0.6494273543, alpha: 1)], orientation: .horizontal)
        
        optionsCollection.dataSource = self
        optionsCollection.delegate = self
        
        self.news?.collectionViewLayout = TestCollection()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        articles.append(contentsOf: delegate.mediaCache.newsCache)

        news.delegate = self
        news.dataSource = self
    
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == optionsCollection){
            return options.count
        }
        else if (collectionView == articleCollection){
            return articlePayload.count
        }
        else{
            return articles.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == optionsCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MediaCategoryCell
            let current = self.options[indexPath.item]
            
            if(selectedCategory == current){
                cell.mediaCategory.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
                cell.mediaCategory.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }
            else{
                cell.mediaCategory.font = UIFont.systemFont(ofSize: 24, weight: .regular)
                cell.mediaCategory.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
            cell.mediaCategory.text = current
            
            return cell
        }
        /*else if(collectionView == articleCollection){
            let current = self.articlePayload[indexPath.item]
            if(current is Int){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "video", for: indexPath) as! ArticleVideoCell
                cell.videoImage.image = self.selectedArticleImage
                cell.videoImage.contentMode = .scaleAspectFill
                cell.videoImage.clipsToBounds = true
                return cell
            }
            else if(current is Bool){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! EmptyCell
                return cell
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! ArticleTextCell
                
                let groupStyle = StyleXML.init(base: styleBase, ["strong" : testAttr])
                let attr = (current as! String).htmlToAttributedString
                
                cell.label.attributedText = attr?.string.set(style: groupStyle)
                cell.label.lineBreakMode = .byWordWrapping
                return cell
            }
        }*/
        else{
            let current = self.articles[indexPath.item]
            if(current is NewsObject){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
                cell.title.text = (current as! NewsObject).title
                cell.subTitle.text = (current as! NewsObject).subTitle
                
                if(!(current as! NewsObject).imageAdded){
                    cell.articleBack.moa.onSuccess = { image in
                        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                            cell.articleBack.alpha = 0.1
                            cell.articleBack.contentMode = .scaleAspectFill
                            cell.articleBack.clipsToBounds = true
                        }, completion: nil)
                        
                        (current as! NewsObject).image = image
                        (current as! NewsObject).imageAdded = true
                        
                      return image
                    }
                }
                else{
                    cell.articleBack.image = (current as! NewsObject).image
                }
                
                switch ((current as! NewsObject).author) {
                case "Kwatakye Raven":
                    //cell..text = "DoubleXP"
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.authorImage.image = #imageLiteral(resourceName: "mike_badge.png")
                    cell.sourceImage.image = #imageLiteral(resourceName: "team_thumbs_up.png")
                    break
                case "Aaron Hodges":
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.sourceImage.image = #imageLiteral(resourceName: "team_thumbs_up.png")
                    cell.authorImage.image = #imageLiteral(resourceName: "hodges_badge.png")
                    break
                default:
                    cell.authorLabel.text = (current as! NewsObject).author
                    cell.sourceImage.image = #imageLiteral(resourceName: "gamespot_icon_ios.png")
                    cell.authorImage.image = #imageLiteral(resourceName: "unknown_badge.png")
                }
                
                cell.articleBack.image = #imageLiteral(resourceName: "team_thumbs_up.png")
                cell.articleBack.moa.url = (current as! NewsObject).imageUrl
                
                cell.tag = indexPath.item
                
                return cell
            }
            else if(current is Bool){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "twitchLoginCell", for: indexPath) as! TwitchLoginCell
                cell.loginButton.applyGradient(colours:  [#colorLiteral(red: 0.3081886768, green: 0.1980658174, blue: 0.5117434263, alpha: 1), #colorLiteral(red: 0.395016551, green: 0.2572917342, blue: 0.6494273543, alpha: 1)], orientation: .horizontal)
                return cell
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributorCell", for: indexPath) as! ContributorCell
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == optionsCollection){
            let current = self.options[indexPath.item]
            
            self.selectedCategory = current
            let cell = collectionView.cellForItem(at: indexPath) as! MediaCategoryCell
            cell.mediaCategory.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
            cell.mediaCategory.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            for cell in self.optionsCollection.visibleCells{
                let currentCell = cell as! MediaCategoryCell
                if(currentCell.mediaCategory.text != current){
                    currentCell.mediaCategory.font = UIFont.systemFont(ofSize: 24, weight: .regular)
                    currentCell.mediaCategory.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            }
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            switch(self.selectedCategory){
                case "popular":
                    self.articles = [Any]()
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    if(self.twitchCoverShowing){
                        UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                            self.header.backgroundColor = UIColor(named: "dark")
                            self.optionsCollection.backgroundColor = UIColor(named: "darkOpacity")
                        })
                        
                        delegate.currentLanding?.updateNavColor(color: .darkGray)
                        
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
                case "twitch":
                    self.articles = [Any]()
                    
                    showTwitchLogin()
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                    //self.articles.append(false)
                    
                    /*self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)*/
                break;
                case "reviews":
                    self.articles = [Any]()
                    articles.append(0)
                    articles.append(contentsOf: delegate.mediaCache.reviewsCache)
                    
                    if(self.twitchCoverShowing){
                        UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                            self.header.backgroundColor = UIColor(named: "dark")
                            self.optionsCollection.backgroundColor = UIColor(named: "darkOpacity")
                        })
                        
                        delegate.currentLanding?.updateNavColor(color: .darkGray)
                        
                        UIView.animate(withDuration: 0.3, animations: {
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
                default:
                    self.articles = [Any]()
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    if(self.twitchCoverShowing){
                        UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                            self.header.backgroundColor = UIColor(named: "dark")
                            self.optionsCollection.backgroundColor = UIColor(named: "darkOpacity")
                        })
                        
                        delegate.currentLanding?.updateNavColor(color: .darkGray)
                            
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
        else if(collectionView == news){
            let current = self.articles[indexPath.item]
            if(current is NewsObject){
                let cell = collectionView.cellForItem(at: indexPath) as! NewsArticleCell
                self.selectedArticle = (current as! NewsObject)
                self.currentWV = cell.cellWV
                self.currentCell = cell
            
                //onVideoLoaded(url: "https://static-gamespotvideo.cbsistatic.com/vr/2019/04/23/kingsfieldiv1_700_1000.mp4")
                
                if(self.selectedArticle.source == "gs"){
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.mediaManager.downloadVideo(title: self.selectedArticle.title, url: selectedArticle.videoUrl, callbacks: self)
                }
                else{
                    onVideoLoaded(url: self.selectedArticle.videoUrl)
                }
            }
        }
        
        /*else{
            let current = self.articlePayload[indexPath.item]
            if(current is Int){
                let videoURL = (self.selectedArticle as NewsObject).videoUrl
                let player = AVPlayer(url: URL(fileURLWithPath: videoURL))
                player.playImmediately(atRate: 1.0)
                
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player

                present(playerViewController, animated: true) {
                  player.play()
                }
            }
        }*/
    }
    
    func onReviewsReceived(payload: [NewsObject]) {
    }
    
    func onMediaReceived() {
    }
    
    func onVideoLoaded(url: String) {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = false
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        DispatchQueue.main.async() {
            let webView = WKWebView(frame: .zero, configuration: webConfiguration)

            if let videoURL:URL = URL(string: url) {
                let embedHTML = "<html><head><meta name='viewport' content='width=device-width, initial-scale=0.0, maximum-scale=1.0, minimum-scale=0.0'></head> <iframe width=\(self.currentCell!.bounds.width)\" height=\(self.currentCell!.bounds.width)\" src=\(url)?&playsinline=1\" frameborder=\"0\" allowfullscreen></iframe></html>"

                //let html = "<video playsinline controls width=\"100%\" height=\"100%\" src=\"\(url)\"> </video>"
                //self.testPlayer.loadHTMLString(embedHTML, baseURL: nil)
                self.currentWV!.isHidden = false
                self.currentWV!.loadHTMLString(embedHTML, baseURL: nil)
                //let request:URLRequest = URLRequest(url: videoURL)
                //self.testPlayer.load(request)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in

        if complete != nil {
          let height = webView.scrollView.contentSize
          print("height of webView is: \(height)")
        }
      })
    }
    
    func showTwitchLogin(){
        if(!self.twitchCoverShowing){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentLanding?.updateNavColor(color: UIColor(named: "twitchPurpleDark")!)
            UIView.transition(with: self.header, duration: 0.3, options: .curveEaseInOut, animations: {
                self.header.backgroundColor = UIColor(named: "twitchPurpleDark")
                self.optionsCollection.backgroundColor = UIColor(named: "twitchPurple")
                self.twitchCover.alpha = 1
            }, completion: nil)
            
            self.twitchCoverShowing = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 150
        
        if(collectionView == optionsCollection){
            return CGSize(width: 150, height: CGFloat(150))
        }
        else if(collectionView == news){
            let current = self.articles[indexPath.item]
            if(current is Int){
                return CGSize(width: (collectionView.bounds.width - 20), height: CGFloat(200))
            }
            else if(current is Bool){
                //if((current as! Bool) == false){
                    return CGSize(width: (collectionView.bounds.width), height: (collectionView.bounds.height))
                //}
            }
            else{
                if(indexPath.item % 3 == 0){
                    return CGSize(width: (collectionView.bounds.width / 2) - 20, height: CGFloat(50))
                }
                else{
                    return CGSize(width: (collectionView.bounds.width), height: CGFloat(300))
                }
            }
        }
        else{
            let current = self.articlePayload[indexPath.item]
            if(current is Int){
                return CGSize(width: (collectionView.bounds.width / 3 + 20), height: CGFloat(180))
            }
            else if(current is Bool){
                return CGSize(width: (collectionView.bounds.width), height: CGFloat(300))
            }
            else{
                return CGSize(width: (collectionView.bounds.width), height: CGFloat(300))
            }
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
