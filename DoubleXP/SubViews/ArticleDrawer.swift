//
//  ArticleDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/5/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import FBSDKCoreKit
import Lottie
import SwiftRichString
import SwiftNotificationCenter

class ArticleDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaCallbacks {
    var newsObj: NewsObject!
    var selectedImage: UIImage?
    var articlePayload = [Any]()
    var articleSet = false
    
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
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var articleAuthorBadge: UIImageView!
    @IBOutlet weak var articleSourceImage: UIImageView!
    @IBOutlet weak var articleName: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var articleImage: UIImageView!
    @IBOutlet weak var articleWV: WKWebView!
    @IBOutlet weak var videoAvailLabel: UILabel!
    @IBOutlet weak var playLogo: UIImageView!
    @IBOutlet weak var articleTable: UITableView!
    @IBOutlet weak var articleVideoView: UIView!
    @IBOutlet weak var scoobLoading: UIVisualEffectView!
    @IBOutlet weak var scoob: AnimationView!
    @IBOutlet weak var scoobSub: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: self.view.window,
            queue: nil
        ) { notification in
            self.hideScoob()
        }
        
        setupView()
    }
    
    private func setupView(){
        self.articlePayload = [Any]()
        
        self.articleName.text = self.newsObj.title
        
        let source = self.newsObj.source
        if(source == "gs"){
            self.articleSourceImage.image = #imageLiteral(resourceName: "gamespot_icon_ios.png")
        }
        else{
            self.articleSourceImage.image = #imageLiteral(resourceName: "new_logo.png")
        }
        
        let author = self.newsObj.author
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
        
        if(self.newsObj.videoUrl.isEmpty){
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
            
            if(self.articleImage != nil){
                self.articleImage.image = self.selectedImage
                self.articleImage.contentMode = .scaleAspectFill
                self.articleImage.clipsToBounds = true
                self.articleImage.alpha = 0.1
            }
            self.articleWV.alpha = 1
        }
        
        /*let authorTap = UITapGestureRecognizer(target: self, action: #selector(authorClicked))
        self.authorCell.isUserInteractionEnabled = true
        self.authorCell.addGestureRecognizer(authorTap)*/
        
        self.articlePayload.append(newsObj.storyText)
        
        if(!self.articleSet){
            self.articleTable.delegate = self
            self.articleTable.dataSource = self
            self.articleTable.reloadData()
        
            self.articleSet = true
        }
        else{
            self.articleTable.reloadData()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.mainView.alpha = 1
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articlePayload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.articlePayload[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as! ArticleTextCell
        
        let groupStyle = StyleXML.init(base: styleBase, ["strong" : testAttr])
        let attr = (current as! String).htmlToAttributedString
                      
        cell.label.attributedText = attr?.string.set(style: groupStyle)
        cell.label.font = UIFont(name: cell.label.font!.fontName, size: 18)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 1500.0;
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        print("closing")
    }
    
    @objc func videoClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.showScoob()
        
        if(newsObj.source == "gs"){
            AppEvents.logEvent(AppEvents.Name(rawValue: "Media - GS Video Selected"))
            delegate.mediaManager.downloadVideo(title: newsObj.title, url: newsObj.videoUrl, callbacks: self)
        }
        else{
            AppEvents.logEvent(AppEvents.Name(rawValue: "Media - DXP Video Selected"))
            self.onVideoLoaded(url: newsObj.videoUrl)
        }
    }
    
    func onVideoLoaded(url: String) {
        //loading videos for articles
        DispatchQueue.main.async() {

            if let videoURL:URL = URL(string: url) {
        
                let embedHTML = "<html><head><meta name='viewport' content='width=device-width, initial-scale=0.0, maximum-scale=1.0, minimum-scale=0.0'></head> <iframe width=\(self.view.bounds.width)\" height=\(self.view.bounds.width)\" src=\(videoURL)?&playsinline=1\" frameborder=\"0\" allowfullscreen></iframe></html>"
                
                self.articleWV.loadHTMLString(embedHTML, baseURL: nil)
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
    
    func windowDidBecomeVisible(notification: NSNotification) {
        print("open")
    }
    
    func showScoob(){
        let top = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.5, animations: {
            self.scoobLoading.alpha = 1
            self.scoobSub.transform = top
            self.scoobSub.alpha = 1
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
        
        //add more scoob layouts
        // -- like one that is like  (ACTUAL CONTROLLER SYMBOLS ->) " triangle triangle back forward" and then below have "Sub Zero's ice move" somethin like that. We can create a small library of these to pop up throughout the app whenever the loading screen shows.
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
                    
                    self.scoob.stop()
                }, completion: nil)
            })
        }
    }
    
    func onReviewsReceived(payload: [NewsObject]) {
    }
    
    func onMediaReceived(category: String) {
    }
}
