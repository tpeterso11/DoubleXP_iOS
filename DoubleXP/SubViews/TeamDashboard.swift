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

class TeamDashboard: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var team: TeamObject? = nil
    var tweets = [TWTRTweet]()
    var teammates = [TeammateObject]()
    
    
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    @IBOutlet weak var tweetCollection: UICollectionView!
    @IBOutlet weak var rosterTable: UITableView!
    @IBOutlet weak var buildButton: UIView!
    @IBOutlet weak var teamChat: UIView!
    @IBOutlet weak var teamRoster: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
    
        teamLabel.text = team?.teamName
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        //buildButton.applyGradient(colours:  [#colorLiteral(red: 0.3333052099, green: 0.3333491981, blue: 0.3332902789, alpha: 1), #colorLiteral(red: 0.4791436791, green: 0.4813652635, blue: 0.4867808223, alpha: 1)], orientation: .horizontal)
        //teamChat.applyGradient(colours:  [#colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1), #colorLiteral(red: 0.715370357, green: 0.04661592096, blue: 0.1113757268, alpha: 1)], orientation: .horizontal)
        //buildButton.addTarget(self, action: #selector(buildButtonClicked), for: .touchUpInside)
        
        tweetCollection.delegate = self
        tweetCollection.dataSource = self
        
        buildRoster()
        //loadTweets()
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
        LandingActivity().navigateToTeamBuild(team: self.team!)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.teamRoster {
            return self.teammates.count
        }
        else{
            return 5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.tweetCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamTweetCell
            
            return cell
        }
        else{
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
    }
    
    private func loadTweets() {
        let client = TWTRAPIClient()
        let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/user_timeline.json"
        let params = ["screen_name": "Activision" ,"count": "3"]
        var clientError : NSError?
        
        let request = client.urlRequest(withMethod: "GET", urlString: statusesShowEndpoint, parameters: params, error: &clientError)
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(String(describing: connectionError))")
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                //print(json)
                let statuses = json!["statuses"] as? [Any]
                let status = statuses![0]
                print(status)
            } catch let jsonError as NSError {
                print("json error: \(jsonError.localizedDescription)")
            }
        }
        
        //let ds = TWTRTimelineDataSource()
        //let dataSource = TWTRCollectionTimelineDataSource(collectionID: "539487832448843776", apiClient: client)
        let dataSource = TWTRUserTimelineDataSource(screenName: "Activision", apiClient: TWTRAPIClient())
        print("Error:")
        
        /*TWTRTwitter.sharedInstance().sessionStore.APIClient.loadTweetsWithIDs("") { tweets, error in
            if let ts = tweets as? [TWTRTweet] {
                self.tweets = ts
            } else {
                println("Failed to load tweets: \(error.localizedDescription)")
            }
        }*/
        //let data = TWTRTimelineDataSource(screenName: "TomCruise", APIClient: TWTRAPIClient())
        //let request = client.urlRequest(withMethod: "GET", urlString: statusesShowEndpoint, parameters: params, error: &clientError)

        /*client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                print("json: \(json)")
            } catch let jsonError as NSError {
                print("json error: \(jsonError.localizedDescription)")
            }*/
        //}
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //if collectionView == self.tweetCollection {
        //    return CGSize(width: self.tweetCollection.bounds.width, height: CGFloat(80))
       // }
       // else{
            return CGSize(width: collectionView.bounds.width, height: CGFloat(60))
       // }
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
