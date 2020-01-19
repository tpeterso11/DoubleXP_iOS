//
//  GamerConnectFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/27/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class GamerConnectFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MSPeekImplementationDelegate {
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var recommendedUsers: UICollectionView!
    var selectedCell = false
    
    @IBOutlet weak var currentDate: UILabel!
    var gcGames = [GamerConnectGame]()
    var delegate: MSPeekCollectionViewDelegateImplementation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gcGameScroll.delegate = self
        recommendedUsers.delegate = self
        gcGameScroll.dataSource = self
        recommendedUsers.dataSource = self
        
        gcGameScroll.configureForPeekingDelegate()
        let todaysDate:NSDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd-yyyy"
        let todayString:String = dateFormatter.string(from: todaysDate as Date)
        
        currentDate.text = todayString
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        gcGames = appDelegate.gcGames
        
        if(!appDelegate.navStack.contains(self)){
            appDelegate.navStack.append(self)
        }
        
        self.pageName = "Home"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.gcGameScroll {
            return gcGames.count
        }
        else{
            return 3
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.recommendedUsers {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendedCell", for: indexPath) as! RecommendedUsersCell
            
            if(indexPath.item == 0){
                cell.gamerTag.text = "allthesaints011"
                cell.xBox.isHidden = true
            }
            if(indexPath.item == 1){
                cell.gamerTag.text = "_fitboy"
                cell.xBox.isHidden = true
            }
            if(indexPath.item == 2){
                cell.gamerTag.text = "Kwatakye Raven"
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
            
            let game = gcGames[indexPath.item]
            cell.backgroundImage.moa.url = game.imageUrl
            cell.backgroundImage.contentMode = .scaleAspectFill
            cell.backgroundImage.clipsToBounds = true
            
            cell.hook.text = game.hook
            
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
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToProfile(uid: getHomeUid(position: indexPath.item))
        }
        else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToSearch(game: gcGames[indexPath.item])
        }
    }
    
    private func getHomeUid(position: Int) -> String{
        if(position == 0){
            return "JOHLpZPWCaScVQ5JgiaoP9xPn9R2"
        }
        
        if(position == 1){
            return "oFdx8UequuOs77s8daWFifODVhJ3"
        }
        
        if(position == 2){
            return "N1k1BqmvEvdOXrbmi2p91kTNLOo1"
        }
        
        return ""
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 150
        if collectionView == self.recommendedUsers {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
        }
        else{
            return CGSize(width: 260, height: CGFloat(150))
        }
    }
}
