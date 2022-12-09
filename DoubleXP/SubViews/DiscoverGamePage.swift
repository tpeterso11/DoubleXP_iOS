//
//  DiscoverGamePage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/23/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import LinearProgressBar
import FirebaseDatabase
import SPStorkController
import Lottie

class DiscoverGamePage: UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate {
    @IBOutlet weak var gameTable: UITableView!
    @IBOutlet weak var gameHeader: UIImageView!
    @IBOutlet weak var ratingsLayout: UIView!
    @IBOutlet weak var ratingsImage: UIImageView!
    @IBOutlet weak var raterThree: UILabel!
    @IBOutlet weak var ratingThree: UILabel!
    @IBOutlet weak var raterOne: UILabel!
    @IBOutlet weak var ratingOne: UILabel!
    @IBOutlet weak var raterTwo: UILabel!
    @IBOutlet weak var ratingTwo: UILabel!
    @IBOutlet weak var optionsTray: UIView!
    @IBOutlet weak var recommendButton: UIButton!
    @IBOutlet weak var twitchButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var loadingView: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: AnimationView!
    
    var game: GamerConnectGame!
    var payload = [[String : Any]]()
    var reviewsPayload = [NewsObject]()
    var reviewContained = false
    var dataSet = false
    var reviewModalActive = false
    var hideRatings = false
    var reviewsArray = [NewsObject]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingAnimation.loopMode = .loop
        self.loadingAnimation.play()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentDiscoverGamePage = self
        
        let cache = delegate.imageCache
        if(cache.object(forKey: game.imageUrl as NSString) != nil){
            self.gameHeader.image = cache.object(forKey: game.imageUrl as NSString)
        } else {
            self.gameHeader.image = Utility.Image.placeholder
            self.gameHeader.moa.onSuccess = { image in
                self.gameHeader.image = image
                delegate.imageCache.setObject(image, forKey: self.game.imageUrl as NSString)
                return image
            }
            self.gameHeader.moa.url = game.imageUrl
        }
        
        let maskLayer = CAGradientLayer(layer: self.gameHeader.layer)
        maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.frame = self.gameHeader.bounds
        self.gameHeader.layer.mask = maskLayer
        
        self.gameHeader.contentMode = .scaleAspectFill
        self.gameHeader.clipsToBounds = true
        
        self.ratingsLayout.layer.cornerRadius = 10.0
        self.ratingsLayout.layer.borderWidth = 1.0
        self.ratingsLayout.layer.borderColor = UIColor.clear.cgColor
        self.ratingsLayout.layer.masksToBounds = true
        
        self.ratingsLayout.layer.shadowColor = UIColor.black.cgColor
        self.ratingsLayout.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.ratingsLayout.layer.shadowRadius = 2.0
        self.ratingsLayout.layer.shadowOpacity = 0.5
        self.ratingsLayout.layer.masksToBounds = false
        self.ratingsLayout.layer.shadowPath = UIBezierPath(roundedRect: self.ratingsLayout.bounds, cornerRadius: self.ratingsLayout.layer.cornerRadius).cgPath
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.getReviews()
        }
    }
    
    private func getReviews(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Reviews").child(game.gameName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for review in snapshot.children{
                    self.reviewsPayload = [NewsObject]()
                    let current = review as! DataSnapshot
                    if(current.hasChild("uid")){
                        let reviewAuthor = current.childSnapshot(forPath: "uid").value as? String ?? ""
                        if(delegate.currentUser!.uId == reviewAuthor){
                            self.reviewContained = true
                        }
                    }
                    if(current.hasChild("title") && current.hasChild("author") && current.hasChild("imageUrl") && current.hasChild("storyText")){
                        let newReview = NewsObject(title: current.childSnapshot(forPath: "title").value as? String ?? "", author: current.childSnapshot(forPath: "author").value as? String ?? "", storyText: current.childSnapshot(forPath: "storyText").value as? String ?? "", imageUrl: current.childSnapshot(forPath: "imageUrl").value as? String ?? "")
                        
                        newReview.uid = current.childSnapshot(forPath: "uid").value as? String ?? ""
                        //add uid to this object so we can track whether this user wrote a review easier.
                        self.reviewsPayload.append(newReview)
                    }
                }
                self.setupButtons()
                self.buildGamePayload()
            } else {
                self.setupButtons()
                self.buildGamePayload()
            }
        })
    }
    
    private func setupButtons(){
        self.recommendButton.layer.shadowColor = UIColor.black.cgColor
        self.recommendButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.recommendButton.layer.shadowRadius = 2.0
        self.recommendButton.layer.shadowOpacity = 0.5
        self.recommendButton.layer.masksToBounds = false
        self.recommendButton.layer.shadowPath = UIBezierPath(roundedRect: self.recommendButton.bounds, cornerRadius: self.recommendButton.layer.cornerRadius).cgPath
        
        self.twitchButton.layer.shadowColor = UIColor.black.cgColor
        self.twitchButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.twitchButton.layer.shadowRadius = 2.0
        self.twitchButton.layer.shadowOpacity = 0.5
        self.twitchButton.layer.masksToBounds = false
        self.twitchButton.layer.shadowPath = UIBezierPath(roundedRect: self.twitchButton.bounds, cornerRadius: self.twitchButton.layer.cornerRadius).cgPath
        
        self.connectButton.layer.shadowColor = UIColor.black.cgColor
        self.connectButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.connectButton.layer.shadowRadius = 2.0
        self.connectButton.layer.shadowOpacity = 0.5
        self.connectButton.layer.masksToBounds = false
        self.connectButton.layer.shadowPath = UIBezierPath(roundedRect: self.connectButton.bounds, cornerRadius: self.connectButton.layer.cornerRadius).cgPath
        
        self.connectButton.addTarget(self, action: #selector(showSearchAsModal), for: .touchUpInside)
        
        
        if(game.twitchHandle.isEmpty){
            self.twitchButton.alpha = 0.5
            self.twitchButton.isUserInteractionEnabled = false
        } else {
            self.twitchButton.alpha = 1.0
            self.twitchButton.isUserInteractionEnabled = true
            self.twitchButton.addTarget(self, action: #selector(twitchClicked), for: .touchUpInside)
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.gamerTag.isEmpty){
            self.recommendButton.alpha = 0.5
            self.recommendButton.isUserInteractionEnabled = false
        } else {
            if(self.reviewContained){
                self.recommendButton.alpha = 0.5
                self.recommendButton.isUserInteractionEnabled = false
                self.recommendButton.setTitle("reviewed", for: .normal)
                self.recommendButton.setTitleColor(UIColor(named: "stayWhite"), for: .normal)
                self.recommendButton.backgroundColor = UIColor(named: "darker")
            } else {
                self.recommendButton.alpha = 1.0
                self.recommendButton.isUserInteractionEnabled = true
                self.recommendButton.setTitle("review", for: .normal)
                self.recommendButton.setTitleColor(UIColor(named: "greenToDarker"), for: .normal)
                self.recommendButton.backgroundColor = UIColor(named: "stayWhite")
                self.recommendButton.addTarget(self, action: #selector(rateClicked), for: .touchUpInside)
            }
        }
    }
    
    func modalDismissed(){
        if(self.reviewModalActive){
            //for some reason, this does not fire after setting rating sometimes.
            self.reviewModalActive = false
            self.reloadData()
        } else {
            self.reloadData()
        }
    }
    
    private func reloadData(){
        UIView.animate(withDuration: 0.8, animations: {
            self.loadingView.alpha = 1
            self.loadingAnimation.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.getReviews()
            }
        }, completion: nil)
    }
    
    func showRatingsFromModal(){
        self.reviewModalActive = true
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "communityReviews") as! CommunityReviews
        currentViewController.game = self.game
        
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
    
    @objc private func showSearchAsModal(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        currentViewController.game = self.game
        
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
    
    @objc private func reviewsClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "communityReviews") as! CommunityReviews
        currentViewController.game = self.game
        
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
    
    @objc private func connectClicked(){
        dismiss(animated: true, completion: nil)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding?.navigateToSearchFromDiscover(game: self.game)
    }
    
    @objc private func rateClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "rating") as! RatingDrawer
        currentViewController.game = game
        
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
    
    @objc private func twitchClicked(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        currentViewController.pageName = "Media"
        currentViewController.navDictionary = ["state": "backOnly"]
        currentViewController.discoverGameName = game.gameName
        
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
    
    private func buildGamePayload(){
        if(self.reviewsPayload.isEmpty){
            //use quick reviews
            for review in game.quickReviews {
                let test = NewsObject(title: review["source"]!, author: review["author"]!, storyText: review["review"]!, imageUrl: review["rating"]!)
                self.reviewsArray.append(test)
            }
        } else {
            if(self.reviewsPayload.count > 1){
                let shuffled = self.reviewsPayload.shuffled()
                self.reviewsArray.append(shuffled[0])
                self.reviewsArray.append(shuffled[1])
            } else {
                //only show user reviews if there are at least 2.
                for review in game.quickReviews {
                    let test = NewsObject(title: review["source"]!, author: review["author"]!, storyText: review["review"]!, imageUrl: review["rating"]!)
                    self.reviewsArray.append(test)
                }
            }
        }
        
        var pos = 0
        for rating in game.ratings {
            if(pos < 4){
                if(pos == 0){
                    self.raterOne.text = rating["source"]
                    self.ratingOne.text = rating["rating"]
                }
                if(pos == 1){
                    self.raterTwo.text = rating["source"]
                    self.ratingTwo.text = rating["rating"]
                }
                if(pos == 2){
                    self.raterThree.text = rating["source"]
                    self.ratingThree.text = rating["rating"]
                }
                if(pos == 3){
                    if(rating["show"] == "true"){
                        self.hideRatings = false
                    } else {
                        self.hideRatings = true
                    }
                }
                pos+=1
            }  else {
                break
            }
        }
        
        if(game.categoryFilters.contains("dope")){
            payload = [["info": ["gamename": game.gameName, "developer": game.developer, "releaseDate": game.releaseDate, "genre": game.gameType]], ["dope": ["": ""]],["ideal": [game.ideal: "emoji-type to show"]], ["reviews": ["payload": self.reviewsArray]]]
        } else {
            payload = [["info": ["gamename": game.gameName, "developer": game.developer, "releaseDate": game.releaseDate, "genre": game.gameType]], ["ideal": [game.ideal: "emoji-type to show"]], ["reviews": ["payload": self.reviewsArray]]]
        }
        
        if(!self.dataSet){
            self.gameTable.delegate = self
            self.gameTable.dataSource = self
            self.gameTable.reloadData()
        } else {
            self.gameTable.reloadData()
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
            if(!self.hideRatings) {
                self.ratingsLayout.alpha = 1
                self.ratingsImage.alpha = 1
            }
            self.optionsTray.alpha = 1
            self.gameTable.alpha = 1
            UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
                self.loadingView.alpha = 0
                self.loadingAnimation.stop()
            }, completion: nil)
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        let key = Array(current.keys)[0]
        
        if(key == "info"){ //basic
            let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath) as! DiscoverGameBasicInfoCell
            let value = current[key] as? [String: String] ?? [String: String]()
            if(!value.isEmpty){
                for (key, value) in value {
                if(key == "gamename"){
                    cell.gameName.text = value
                    continue
                }
                if(key == "developer"){
                    cell.developer.text = value
                    continue
                }
                if(key == "releaseDate"){
                    cell.releaseDate.text = value
                    continue
                }
                if(key == "genre"){
                    cell.genre.text = value
                    continue
                }
                }
            }
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if(delegate.currentUser!.games.contains(self.game.gameName)){
                cell.addGameButton.backgroundColor = #colorLiteral(red: 0.2880555391, green: 0.2778990865, blue: 0.2911514342, alpha: 1)
                cell.addGameButton.setTitle("you play this game.", for: .normal)
                cell.addGameButton.alpha = 0.5
                cell.addGameButton.isUserInteractionEnabled = false
            } else {
                cell.addGameButton.backgroundColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                cell.addGameButton.setTitle("add this game.", for: .normal)
                cell.addGameButton.alpha = 1
                cell.addGameButton.isUserInteractionEnabled = true
                cell.addGameButton.addTarget(self, action: #selector(showQuickAddModal), for: UIControl.Event.touchUpInside)
            }
            
            if(game.categoryFilters.contains("dope")){
                cell.bottomDivider.alpha = 1
            } else {
                cell.bottomDivider.alpha = 0
            }
            
            return cell
        }
        
        if(key == "dope"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "dope", for: indexPath) as! DiscoverGameDopeCell
            return cell
        }
        
        if(key == "ideal"){ //ideal
            let cell = tableView.dequeueReusableCell(withIdentifier: "ideal", for: indexPath) as! DiscoverGameIdealCell
            let value = current[key] as? [String: String] ?? [String: String]()
            for (key, _) in value {
                cell.condition.text = key
                cell.emoji.image = #imageLiteral(resourceName: "game_star")
            }
            
            cell.gameDescription.text = game.gameDescription
            
            if let n = NumberFormatter().number(from: game.timeCommitment) {
                let f = CGFloat(truncating: n)
                cell.testBar.progressValue = f
                cell.timeCommitment.text = mapTimeString(input: f)
            }
        
            if let n = NumberFormatter().number(from: game.complexity) {
                let f = CGFloat(truncating: n)
                cell.complexityBar.progressValue = f
                cell.complexityDesc.text = mapComplexityString(input: f)
            }
            cell.testBar.barColorForValue = { value in
                switch value {
                case 0..<20:
                    return UIColor.green
                case 20..<60:
                    return UIColor.yellow
                case 60..<80:
                    return UIColor.orange
                default:
                    return UIColor.red
                }
            }
            
            cell.complexityBar.barColorForValue = { value in
                switch value {
                case 0..<20:
                    return UIColor.green
                case 20..<60:
                    return UIColor.yellow
                case 60..<80:
                    return UIColor.orange
                default:
                    return UIColor.red
                }
            }
            return cell
        }
        
        else { //quick
            let cell = tableView.dequeueReusableCell(withIdentifier: "quick", for: indexPath) as! DiscoverGameQuickReviewsCell
            let value = current[key] as? [String: [NewsObject]] ?? [String: [NewsObject]]()
            
            if(self.reviewsPayload.isEmpty){
                cell.usersButton.alpha = 0.3
                cell.usersButton.setTitle("no user reviews, yet.", for: .normal)
                cell.usersButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                cell.usersButton.isUserInteractionEnabled = false
                
                if(!self.reviewsArray.isEmpty){
                    cell.reviewsCollection.alpha = 1
                    for (_, value) in value {
                        cell.setPayload(payload: value)
                    }
                } else {
                    cell.reviewsCollection.alpha = 0
                }
            } else {
                cell.usersButton.setTitle("view user reviews", for: .normal)
                cell.usersButton.isUserInteractionEnabled = true
                cell.usersButton.backgroundColor = UIColor(named: "greenToDarker")
                cell.usersButton.addTarget(self, action: #selector(reviewsClicked), for: .touchUpInside)
                cell.usersButton.alpha = 1
                
                if(!self.reviewsPayload.isEmpty){
                    cell.reviewsCollection.alpha = 1
                    for (_, value) in value {
                        cell.setPayload(payload: value)
                    }
                } else {
                    cell.reviewsCollection.alpha = 0
                }
            }
            return cell
        }
    }
    
    @objc func didDismissStorkBySwipe(){
        if(reviewModalActive){
            self.reviewModalActive = false
            self.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = self.payload[indexPath.item]
        let key = Array(current.keys)[0]
        if(key == "info"){
            return CGFloat(200)
        }
        else if(key == "ideal"){
            return CGFloat(450)
        }
        else if(key == "reviews"){
            if(!self.reviewsArray.isEmpty){
                return CGFloat(450)
            } else {
                return CGFloat(150)
            }
        }
        else if(key == "dope"){
            return CGFloat(120)
        }
        else {
            return CGFloat(0)
        }
    }
    
    @objc private func showQuickAddModal(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "quickAddGame") as! QuickAddGameDrawer
        currentViewController.gameName = game.gameName
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 650
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    private func mapTimeString(input: CGFloat) -> String {
        switch input {
        case 0..<20:
            return "casual up to about an hour."
        case 20..<60:
            return "a few hours to a night."
        case 60..<80:
            return "yeah...better block off a weekend."
        default:
            return "head down and grind."
        }
    }
    
    private func mapComplexityString(input: CGFloat) -> String {
        switch input {
        case 0..<20:
            return "easy to pick up and play."
        case 20..<60:
            return "pretty basic controls. but nothing too gnarly."
        case 60..<80:
            return "advanced controls, more possibilities"
        default:
            return "this game is complex. period."
        }
    }
}
