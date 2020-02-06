//
//  TeamDashboard.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation
import TwitterKit
import SwiftTwitch
import WebKit
import TwitchPlayer

class TeamDashboard: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SocialMediaManagerCallback {
    var team: TeamObject? = nil
    var tweets = [Any]()
    var streams = [Any]()
    var teammates = [TeammateObject]()
    let manager = SocialMediaManager()
    
    var viewLoadedBool = false
    
    
    @IBOutlet weak var twitchView: UIView!
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    @IBOutlet weak var buildButton: UIView!
    @IBOutlet weak var teamChat: UIView!
    @IBOutlet weak var teamRoster: UICollectionView!
    @IBOutlet weak var tweetCollection: UICollectionView!
    @IBOutlet weak var tweetStreamSegment: UISegmentedControl!
    @IBOutlet weak var twitchStreamList: UICollectionView!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var twitchPlayer: TestPlayer!
    
    @IBAction func onChange(_ sender: Any) {
        switch (tweetStreamSegment.selectedSegmentIndex){
        case 0:
            //Show Twitter
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.twitchStreamList.transform = CGAffineTransform(translationX: 0, y: 0)
                }) { (finished) in
                    self.tweetCollection.delegate = self
                    self.tweetCollection.dataSource = self
                    self.twitchStreamList.reloadData()
                    
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                        self.tweetCollection.transform = CGAffineTransform(translationX: 0, y: 0)
                    }) { (finished) in
                        
                        self.manager.loadTwitchStreams(team: self.team!, callbacks: self)
                    }
            }
        case 1:
            //Show Twitch
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                self.tweetCollection.transform = CGAffineTransform(translationX: -375, y: 0)
            }) { (finished) in
                self.twitchStreamList.dataSource = self
                self.twitchStreamList.delegate = self
                self.twitchStreamList.reloadData()
                
                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.twitchStreamList.transform = CGAffineTransform(translationX: -375, y: 0)
                }) { (finished) in
                    
                    self.manager.loadTweets(team: self.team!, callbacks: self)
                }
            }

        default:
            break;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        self.pageName = "Profile"
        delegate.navStack.append(self)
    
        teamLabel.text = team?.teamName
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        tweetStreamSegment.selectedSegmentIndex = 0
        
        let buildTap = UITapGestureRecognizer(target: self, action: #selector(buildButtonClicked))
        buildButton.isUserInteractionEnabled = true
        buildButton.addGestureRecognizer(buildTap)
        
        buildRoster()
        loadTweets()
    }
    
    private func getTwitch(){
        let manager = SocialMediaManager()
        manager.loadTwitchStreams(team: team!, callbacks: self)
    }
    
    private func buildRoster(){
        for user in team!.teammates{
            if(user.gamerTag == team?.teamCaptain){
                teammates.append(user)
                break
            }
        }
        
        for user in team!.teammates{
            if(!teammates.contains(user)){
                teammates.append(user)
            }
        }
        
        teamRoster.dataSource = self
        teamRoster.delegate = self
    }
    
    @objc func buildButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding!.navigateToTeamBuild(team: self.team!)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.teamRoster {
            return self.teammates.count
        }
        else if(collectionView == self.tweetCollection){
            return self.tweets.count
        }
        else{
            return self.streams.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.tweetCollection {
            let current = tweets[indexPath.item]
            
            if current is String {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "label", for: indexPath) as! TwitterDescCell
                return cell
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamTweetCell
                
                let current = self.tweets[indexPath.item] as! TweetObject
                cell.twitterTag.text = current.handle
                cell.tweet.text = current.tweet
                cell.bottomBorder.backgroundColor = #colorLiteral(red: 0.182135582, green: 0.6824935079, blue: 0.9568628669, alpha: 1)
                return cell
            }
        }
        else if(collectionView == self.teamRoster){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamRosterCell
            let current = team!.teammates[indexPath.item]
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = GamerProfileManager()
            let currentUser = delegate.currentUser
            
            cell.gamerTag.text = current.gamerTag
            
            if((team!.teamCaptain == manager.getGamerTagForGame(gameName: self.team!.games[0]))){
                cell.captainStar.isHidden = false
                cell.backgroundColor = #colorLiteral(red: 0.833609879, green: 0.6559728384, blue: 0.2461257577, alpha: 1)
            }
            else{
                cell.captainStar.isHidden = true
            }
            
            if(current.uid == currentUser!.uId){
                cell.messageButton.isHidden = true
            }
            else{
                cell.messageButton.tag = indexPath.item
                
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(goToChat))
                cell.messageButton.isUserInteractionEnabled = true
                cell.messageButton.addGestureRecognizer(singleTap)
            }
            
            cell.backgroundColor = .white
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            return cell
        }
        else{
            let current = streams[indexPath.item]
            
            if current is String {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "label", for: indexPath) as! TwitchDescCell
                
                cell.backgroundColor = .white
                
                cell.contentView.layer.cornerRadius = 2.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true
                
                return cell
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TwitchStreamCell
                let currentStream = streams[indexPath.item] as! TwitchStreamObject
                
                cell.streamName.text = currentStream.handle
                
                if(currentStream.type != "live"){
                    cell.liveIcon.isHidden = true
                }
                
                let str = currentStream.thumbnail
                let replaced = str.replacingOccurrences(of: "{width}x{height}", with: "800x500")
                
                cell.previewImage.moa.url = replaced
                cell.previewImage.contentMode = .scaleAspectFill
                cell.previewImage.clipsToBounds = true
                
                cell.contentView.layer.cornerRadius = 2.0
                cell.contentView.layer.borderWidth = 1.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true
                
                return cell
            }
        }
    }
    
    private func loadTweets() {
        let manager = SocialMediaManager()
        manager.loadTweets(team: team!, callbacks: self)
        manager.loadTwitchStreams(team: self.team!, callbacks: self)
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
        self.tweets = tweets
        self.tweets.insert("label", at: 0)
        
        if(!self.viewLoadedBool){
            self.tweetCollection.delegate = self
            self.tweetCollection.dataSource = self
            
            self.viewLoadedBool = true
        }
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
        self.streams = streams
        self.streams.insert("label", at: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.tweetCollection {
            let current = tweets[indexPath.item]
            
            if current is String {
                 return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(50))
            }
            else{
                return CGSize(width: self.tweetCollection.bounds.width, height: CGFloat(80))
            }
        }
        else if(collectionView == twitchStreamList){
            let current = streams[indexPath.item]
            
            if current is String {
                 return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(50))
            }
            else{
                return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(120))
            }
        }
        else{
            return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(50))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == twitchStreamList){
            let cell = self.twitchStreamList.cellForItem(at: indexPath) as! TwitchStreamCell
            let current = streams[indexPath.item]
        
            NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeKeyNotification,
                object: self.view.window,
                queue: nil
            ) { notification in
                print("Video stopped")
                self.twitchPlayer.isHidden = true
                self.twitchPlayer.setChannel(to: "")
                
                UIView.animate(withDuration: 0.8) {
                    self.twitchView.alpha = 0
                }
            }
            
            twitchPlayer.configuration.allowsInlineMediaPlayback = true
            twitchPlayer.configuration.mediaTypesRequiringUserActionForPlayback = []
            twitchPlayer.setChannel(to: (current as! TwitchStreamObject).handle)
            //twitchPlayer.togglePlaybackState()
            
            UIView.animate(withDuration: 0.8) {
                self.twitchView.alpha = 1.0
            }
        }
        else if(collectionView == teamRoster){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            let current = self.teammates[indexPath.item]
            
            if(current.uid != currentUser?.uId){
                delegate.currentLanding?.navigateToProfile(uid: currentUser!.uId)
            }
        }
    }
    
    @objc func goToChat(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        let currentTeammate = teammates[indexPath.item]
        
        delegate.currentLanding?.navigateToMessaging(groupChannelUrl: nil, otherUserId: currentTeammate.uid)
    }
    //1128714793555091456-C4OD4V0gLqpHFinaHl4hpUshhNBXcN (token)
    //ByV39JcNUoCaaNs3qewI57uEelpikR9JlMYFi5PdZs1GS  (secret)
    
    //sEWJZFZjZAIaxwZUrzdd2JPeI (consumer API key)
    //K2yk5yy8AHmyC4mMFHecB1WBoowFnf4uMs4ET7zEjFe06hWmCm (consumer API secret)
}
