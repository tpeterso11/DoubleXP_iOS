//
//  ProfileGamesCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import moa

class ProfileGamesCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var gameList: UICollectionView!
    var gcGames = [GamerConnectGame]()
    var gamesPlayed = [GamerConnectGame]()
    var callbacks : CurrentProfileCallbacks!
    
    func setUi(list: [GamerConnectGame], callbacks: CurrentProfileCallbacks){
        self.callbacks = callbacks
        self.gamesPlayed = list
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.gcGames.append(contentsOf: appDelegate.gcGames)
        
        gameList.delegate = self
        gameList.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gcGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProfileGameSelectionCell
        let current = self.gcGames[indexPath.item]
        
        cell.gameImage.image = Utility.Image.placeholder
        cell.gameImage.moa.url = current.imageUrl
        cell.gameImage.contentMode = .scaleAspectFill
        cell.gameImage.clipsToBounds = true
        
        var contained = false
        for game in self.gamesPlayed{
            if(game.gameName == current.gameName){
                contained = true
                break
            }
        }
        
        if(contained){
            cell.blurCover.alpha = 1
        }
        
        cell.shortName.text = current.secondaryName
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = gcGames[indexPath.item]
        
        if(self.gamesPlayed.contains(current)){
            callbacks.gameRemoved(gameName: current.gameName, indexPath: indexPath)
        }
        else{
            callbacks.gameAdded(gameName: current.gameName, indexPath: indexPath)
        }
    }
    
   func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.width - 20, height: CGFloat(100))
   }
    
    func updateCell(indexPath: IndexPath, gameName: String, show: Bool){
        let cell = gameList.cellForItem(at: indexPath) as! ProfileGameSelectionCell
        if(show){
            self.gamesPlayed.append(self.gcGames[indexPath.item])
            
            UIView.animate(withDuration: 0.3, animations: {
                cell.blurCover.alpha = 1
                //track changes
            }, completion: nil)
        }
        else{
            self.gamesPlayed.remove(at: self.gamesPlayed.index(of: self.gcGames[indexPath.item])!)
            
            UIView.animate(withDuration: 0.3, animations: {
                cell.blurCover.alpha = 0
                //track changes
            }, completion: nil)
        }
        
        self.callbacks.checkChanges(updatedList: self.gamesPlayed)
    }
}
