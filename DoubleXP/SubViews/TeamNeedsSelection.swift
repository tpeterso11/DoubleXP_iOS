//
//  TeamNeedsSelection.swift
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

class TeamNeedsSelection: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var team: TeamObject? = nil
    
    var selectedNeeds = [String]()
    
    
    @IBOutlet weak var teamNeedsCollection: UICollectionView!
    @IBOutlet weak var teamNext: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(nextButtonClicked))
        teamNext.isUserInteractionEnabled = true
        teamNext.addGestureRecognizer(singleTap)
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        if(selectedNeeds.isEmpty){
            LandingActivity().navigateToTeamDashboard(team: team!, newTeam: true)
        }
        else{
            let ref = Database.database().reference().child("Teams").child(team!.teamName)
            ref.child("selectedTeamNeeds").setValue(selectedNeeds)
            
            LandingActivity().navigateToTeamDashboard(team: team!, newTeam: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return team?.teamNeeds.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamNeedsCell
        
        let current = team?.teamNeeds[indexPath.item]
        cell.needLabel.text = current
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(!selectedNeeds.contains((team?.teamNeeds[indexPath.item])!)){
            selectedNeeds.append(team?.teamNeeds[indexPath.item] ?? "")
            
            let cell = collectionView.cellForItem(at: indexPath) as! TeamNeedsCell
            cell.cover.isHidden = false
            cell.needLabel.textColor = UIColor.white
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if(selectedNeeds.contains((team?.teamNeeds[indexPath.item])!)){
            selectedNeeds = selectedNeeds.filter{$0 != team?.teamNeeds[indexPath.item]}
            
            let cell = collectionView.cellForItem(at: indexPath) as! TeamNeedsCell
            cell.cover.isHidden = false
            cell.needLabel.textColor = UIColor.white
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        return CGSize(width: (screenWidth/3)-6, height: (screenWidth/3)-6);
    }
    
    
}
