//
//  TeamDashboard.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import MSPeekCollectionViewDelegateImplementation
import TwitterKit
import SwiftTwitch
import WebKit

class TeamDashboard: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SocialMediaManagerCallback {
    
    var team: TeamObject? = nil
    var tweets = [Any]()
    var streams = [Any]()
    var teammates = [TeammateObject]()
    let manager = SocialMediaManager()
    
    var viewLoadedBool = false
    
    
    @IBOutlet weak var loadingElement: UILabel!
    @IBOutlet weak var loadingStatus: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var twitchView: UIView!
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    @IBOutlet weak var buildButton: UIView!
    @IBOutlet weak var teamChat: UIView!
    @IBOutlet weak var teamRoster: UICollectionView!
    @IBOutlet weak var tweetCollection: UICollectionView!
    @IBOutlet weak var tweetStreamSegment: UISegmentedControl!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var twitchPlayer: TestPlayer!
    var gcGame: GamerConnectGame!
    var dataSet = "twitter"
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func onChange(_ sender: Any) {
        switch (tweetStreamSegment.selectedSegmentIndex){
        case 0:
            //Show Twitter
            self.dataSet = "twitter"
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.tweetCollection.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.tweetCollection.alpha = 0
                }) { (finished) in
                    //self.tweetCollection.delegate = self
                    //self.tweetCollection.dataSource = self
                    self.tweetCollection.reloadData()
                    
                    let top = CGAffineTransform(translationX: 0, y: -10)
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                        self.tweetCollection.transform = top
                        self.tweetCollection.alpha = 1
                    }) { (finished) in
                        
                        self.manager.loadTwitchStreams(team: self.team!, gcGame: self.gcGame, callbacks: self)
                    }
            }
        case 1:
            //Show Twitch
            self.dataSet = "twitch"
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                self.tweetCollection.transform = CGAffineTransform(translationX: 0, y: 0)
                self.tweetCollection.alpha = 0
            }) { (finished) in
                //self.tweetCollection.delegate = self
                //self.tweetCollection.dataSource = self
                self.tweetCollection.reloadData()
                
                let top = CGAffineTransform(translationX: 0, y: -10)
                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.tweetCollection.transform = top
                    self.tweetCollection.alpha = 1
                }) { (finished) in
                    
                    self.manager.loadTweets(team: self.team!, gcGame: self.gcGame, callbacks: self)
                }
            }

        default:
            break;
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3) {
            self.loadSocial()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup nav
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
    
        teamLabel.text = team?.teamName
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        tweetStreamSegment.selectedSegmentIndex = 0
        
        let chatTap = UITapGestureRecognizer(target: self, action: #selector(chatButtonClicked))
        teamChat.isUserInteractionEnabled = true
        teamChat.addGestureRecognizer(chatTap)
        
        let buildTap = UITapGestureRecognizer(target: self, action: #selector(buildButtonClicked))
        buildButton.isUserInteractionEnabled = true
        buildButton.addGestureRecognizer(buildTap)
        
        buildRoster()
        
        loadingStatus.text = "loading..."
        
        
        UIView.animate(withDuration: 0.8, animations: {
            self.spinner.alpha = 1
            self.loadingStatus.alpha = 1
            self.spinner.startAnimating()
        }, completion: nil)
        
        for game in delegate.gcGames{
            if(game.gameName == team!.games[0]){
                self.gcGame = game
            }
        }
    }
    
    private func getTwitch(){
        let manager = SocialMediaManager()
        manager.loadTwitchStreams(team: team!, gcGame: self.gcGame, callbacks: self)
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
        
        let top = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.teamRoster.alpha = 1
            self.teamRoster.transform = top
        }, completion: nil)
    }
    
    @objc func buildButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding!.navigateToTeamBuild(team: self.team!)
    }
    
    @objc func chatButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding!.navigateToMessaging(groupChannelUrl: team!.teamChat, otherUserId: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.teamRoster {
            return self.teammates.count
        }
        else{
            if(self.dataSet == "twitter"){
                return self.tweets.count
            }
            else{
                return self.streams.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.tweetCollection {
            if(dataSet == "twitter"){
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
            else{
                let current = streams[indexPath.item]
    
                if current is String {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "twitchLabel", for: indexPath) as! TwitchDescCell
                    
                    cell.contentView.layer.cornerRadius = 2.0
                    cell.contentView.layer.borderWidth = 1.0
                    cell.contentView.layer.borderColor = UIColor.clear.cgColor
                    cell.contentView.layer.masksToBounds = true
                    
                    return cell
                }
                else{
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "twitchCell", for: indexPath) as! TwitchStreamCell
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
            //roster
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamRosterCell
            let current = team!.teammates[indexPath.item]
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            cell.gamerTag.text = current.gamerTag
            
            if((team!.teamCaptain == current.gamerTag)){
                cell.captainStar.isHidden = false
                cell.backgroundColor = #colorLiteral(red: 0.833609879, green: 0.6559728384, blue: 0.2461257577, alpha: 1)
            }
            else{
                cell.captainStar.isHidden = true
            }
            
            cell.messageButton.isHidden = true
            /*if(current.uid == currentUser!.uId){
                cell.messageButton.isHidden = true
            }
            else{
                cell.messageButton.tag = indexPath.item
                
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(goToChat))
                cell.messageButton.isUserInteractionEnabled = true
                cell.messageButton.addGestureRecognizer(singleTap)
            }*/
            
            cell.backgroundColor = .white
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            return cell
        }
    }
    
    private func loadSocial() {
        let manager = SocialMediaManager()
        manager.loadTwitchStreams(team: self.team!, gcGame: self.gcGame, callbacks: self)
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
        self.tweets = tweets
        self.tweets.insert("label", at: 0)
        
        if(!self.viewLoadedBool){
            self.tweetCollection.delegate = self
            self.tweetCollection.dataSource = self
            
            let top = CGAffineTransform(translationX: 0, y: 8)
            UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                self.tweetCollection.alpha = 1
                self.tweetCollection.transform = top
                self.loadingView.alpha = 0
            }, completion: nil)
            
            self.spinner.stopAnimating()
            self.viewLoadedBool = true
        }
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
        self.streams = streams
        self.streams.insert("label", at: 0)
        
        self.manager.loadTweets(team: self.team!, gcGame: self.gcGame, callbacks: self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.tweetCollection {
            if(self.dataSet == "twitter"){
                let current = tweets[indexPath.item]
                
                if current is String {
                     return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(50))
                }
                else{
                    return CGSize(width: self.tweetCollection.bounds.width, height: CGFloat(80))
                }
            }
            else{
                let current = self.streams[indexPath.item]
                if current is String {
                     return CGSize(width: self.tweetCollection.bounds.width, height: CGFloat(50))
                }
                else{
                    return CGSize(width: self.tweetCollection.bounds.width, height: CGFloat(120))
                }
            }
        }
        else{
            return CGSize(width: collectionView.bounds.width, height: CGFloat(50))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == tweetCollection && dataSet == "twitch"){
            let cell = self.tweetCollection.cellForItem(at: indexPath) as! TwitchStreamCell
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
                delegate.currentLanding?.navigateToProfile(uid: current.uid)
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
    
    func onChannelsLoaded(channels: [TwitchChannelObj]) {
    }
}
