//
//  TeamBuildFA.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//
import UIKit
import Firebase

class TeamBuildFA: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var team: TeamObject?
    var currentUser: User?
    
    @IBOutlet weak var teamNeeds: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
        
        teamNeeds.delegate = self
        teamNeeds.dataSource = self
        
        searchButton.addTarget(self, action: #selector(searchButtonClicked), for: .touchUpInside)
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        //send up any changes to DB.
        
        let ref = Database.database().reference().child("Teams").child(team!.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                ref.child("selectedTeamNeeds").setValue(self.team!.selectedTeamNeeds)
            }
            LandingActivity().navigateToTeamFreeAgentResults(team: self.team!)
            
        }) { (error) in
            LandingActivity().navigateToTeamFreeAgentResults(team: self.team!)
            print(error.localizedDescription)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.team?.teamNeeds.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FATeamNeedsCell
        
        let current = self.team?.teamNeeds[indexPath.item]
        cell.label.text = current
        
        if(self.team!.selectedTeamNeeds.contains(current!)){
            cell.cover.isHidden = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let manager = GamerProfileManager()
        if(manager.getGamerTagForGame(gameName: team!.games[0]) == team!.teamCaptain){
            if(team!.selectedTeamNeeds.contains(team!.teamNeeds[indexPath.item])){
                team!.selectedTeamNeeds = team!.selectedTeamNeeds.filter { $0 != team!.teamNeeds[indexPath.item] }
                
                let cell = teamNeeds.cellForItem(at: indexPath) as! FATeamNeedsCell
                cell.cover.isHidden = true
            }
            else{
                team!.selectedTeamNeeds.append(team!.teamNeeds[indexPath.item])
                
                let cell = teamNeeds.cellForItem(at: indexPath) as! FATeamNeedsCell
                cell.cover.isHidden = false
            }
        }
    }
}

