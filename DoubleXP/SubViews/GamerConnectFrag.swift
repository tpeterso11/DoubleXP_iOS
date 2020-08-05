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

class GamerConnectFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var recommendedUsers: UICollectionView!
    var selectedCell = false
    
    @IBOutlet weak var connectHeader: UILabel!
    @IBOutlet weak var currentDate: UILabel!
    var gcGames = [GamerConnectGame]()
    var secondaryPayload = [Any]()
    
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
        gcGames = appDelegate.gcGames
    }
    
    override func reloadView() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.restoreBottomNav()
        appDelegate.currentLanding!.updateNavColor(color: UIColor(named: "darker")!)
        appDelegate.currentLanding!.stackDepth = 1
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
                self.gcGameScroll.alpha = 1
                self.gcGameScroll.transform = top
                self.gcGameScroll.reloadData()
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.recommendedUsers.transform = top
                    self.recommendedUsers.alpha = 1
                }, completion: nil)
            })
        }
    }
    
    private func buildSecondaryPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        secondaryPayload.append(contentsOf: appDelegate.competitions)
        
        let userOne = RecommendedUser(gamerTag: "allthesaints011", uid: "HMv30El7nmWXPEnriV3irMsnS3V2")
        //let userTwo = RecommendedUser(gamerTag: "fitboy_", uid: "oFdx8UequuOs77s8daWFifODVhJ3")
        let userThree = RecommendedUser(gamerTag: "Kwatakye Raven", uid: "N1k1BqmvEvdOXrbmi2p91kTNLOo1")
        
        secondaryPayload.append(userOne)
        //secondaryPayload.append(userTwo)
        secondaryPayload.append(userThree)
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
            else{
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
            else{
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
            else{
                return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
            }
        }
        if collectionView == self.gcGameScroll {
            return CGSize(width: 280, height: CGFloat(160))
        }
        
        return CGSize(width: 260, height: CGFloat(100))
    }
}
