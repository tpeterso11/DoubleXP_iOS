//
//  FoldingCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/28/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FoldingCell

class FoldingCellCell: FoldingCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var gameBack: UIImageView!
    @IBOutlet weak var statCollection: UICollectionView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var developer: UILabel!
    @IBOutlet weak var statLayout: UIView!
    
    var currentStat: StatObject?
    var keys = [String]()
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        statLayout.layer.cornerRadius = 10
        statLayout.layer.masksToBounds = true
        super.awakeFromNib()
    }

    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
    
    func setCollectionView(stat: StatObject){
        
        currentStat = stat
        
        statCollection.delegate = self
        statCollection.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentStat!.getStatCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProfileStatCell
        
        let current = currentStat!
        if(!keys.contains(current.gameName + "playerLevelGame") && !current.playerLevelGame.isEmpty){
            keys.append(current.gameName + "playerLevelGame")
            
            cell.statLabel.text = "Player Level Game"
            cell.stat.text = current.playerLevelGame
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "playerLevelPVP") && !current.playerLevelPVP.isEmpty){
            keys.append(current.gameName + "playerLevelPVP")
            
            cell.statLabel.text = "Player Level PVP"
            cell.stat.text = current.playerLevelPVP
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "killsPVE") && !current.killsPVE.isEmpty){
            keys.append(current.gameName + "killsPVE")
            
            cell.statLabel.text = "Kills PVE"
            cell.stat.text = current.killsPVE
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "killsPVP") && !current.killsPVP.isEmpty){
            keys.append(current.gameName + "killsPVP")
            
            cell.statLabel.text = "Kills PVP"
            cell.stat.text = current.killsPVP
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "currentRank") && !current.currentRank.isEmpty){
            keys.append(current.gameName + "currentRank")
            
            cell.statLabel.text = "Current Rank"
            cell.stat.text = current.currentRank
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "gearScore") && !current.gearScore.isEmpty){
            keys.append(current.gameName + "gearScore")
            
            cell.statLabel.text = "Gear Score"
            cell.stat.text = current.gearScore
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "totalRankedKills") && !current.totalRankedKills.isEmpty){
            keys.append(current.gameName + "totalRankedKills")
            
            cell.statLabel.text = "Total Ranked Kills"
            cell.stat.text = current.totalRankedKills
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "totalRankedDeaths") && !current.totalRankedDeaths.isEmpty){
            keys.append(current.gameName + "totalRankedDeaths")
            
            cell.statLabel.text = "Total Ranked Deaths"
            cell.stat.text = current.totalRankedDeaths
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "mostUsedAttacker") && !current.mostUsedAttacker.isEmpty){
            keys.append(current.gameName + "mostUsedAttacker")
            
            cell.statLabel.text = "Most Used Attacker"
            cell.stat.text = current.mostUsedAttacker
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "mostUsedDefender") && !current.mostUsedDefender.isEmpty){
            keys.append(current.gameName + "mostUsedDefender")
            
            cell.statLabel.text = "Most Used Defender"
            cell.stat.text = current.mostUsedDefender
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "totalRankedWins") && !current.totalRankedWins.isEmpty){
            keys.append(current.gameName + "totalRankedWins")
            
            cell.statLabel.text = "Total Ranked Wins"
            cell.stat.text = current.totalRankedWins
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "totalRankedLosses") && !current.totalRankedLosses.isEmpty){
            keys.append(current.gameName + "totalRankedLosses")
            
            cell.statLabel.text = "Total Ranked Losses"
            cell.stat.text = current.totalRankedLosses
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "authorized") && !current.authorized.isEmpty){
            keys.append(current.gameName + "authorized")
            
            cell.statLabel.text = "Authorized"
            cell.stat.text = current.authorized
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "setPublic") && !current.setPublic.isEmpty){
            keys.append(current.gameName + "setPublic")
            
            cell.statLabel.text = "Public"
            cell.stat.text = current.setPublic
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "codKd") && !current.codKd.isEmpty){
            keys.append(current.gameName + "codKd")
            
            cell.statLabel.text = "K/D"
            cell.stat.text = current.codKd
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "codKills") && !current.codKills.isEmpty){
            keys.append(current.gameName + "codKills")
            
            cell.statLabel.text = "Kills"
            cell.stat.text = current.codKills
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "codWins") && !current.codWins.isEmpty){
            keys.append(current.gameName + "codWins")
            
            cell.statLabel.text = "Wins"
            cell.stat.text = current.codWins
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "codLevel") && !current.codLevel.isEmpty){
            keys.append(current.gameName + "codLevel")
            
            cell.statLabel.text = "Level"
            cell.stat.text = current.codLevel
            
            return cell
        }
        
        if(!keys.contains(current.gameName + "codWlRatio") && !current.codWlRatio.isEmpty){
            keys.append(current.gameName + "codWlRatio")
            
            cell.statLabel.text = "W/L Ratio"
            cell.stat.text = current.codWlRatio
            
            return cell
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(30))
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
