//
//  TeamFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class TeamFrag: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var teamList: UICollectionView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var freeAgentButton: UIButton!
    @IBOutlet weak var teamSearchButton: UIButton!
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateList()
        
        createButton.addTarget(self, action: #selector(createButtonClicked), for: .touchUpInside)
        freeAgentButton.addTarget(self, action: #selector(faButtonClicked), for: .touchUpInside)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil)
        
        appDelegate.navStack.append(self)
        self.pageName = "Team"
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToCreateFrag()
    }
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    private func populateList(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        user = delegate.currentUser
        
        var captain = false
        for team in user?.teams ?? [TeamObject](){
            if(team.teamCaptain == user?.uId){
                captain = true
                break
            }
        }
        
        if(captain){
            status.text = "Captain"
        }
        else if(!user!.teams.isEmpty){
            status.text = "Teammate"
        }
        else{
            status.text = "Inactive"
        }
        
        teamList.delegate = self
        teamList.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return user?.teams.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "teamCell", for: indexPath) as! TeamCellTeamFrag
        
        let current = user?.teams[indexPath.item]
        cell.teamName.text = current?.teamName
        
        if(current?.teamCaptain == self.user?.uId ?? ""){
            cell.captainStar.isHidden = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let team = user?.teams[indexPath.item]
        
        LandingActivity().navigateToTeamDashboard(team: team!, newTeam: false)
    }
}
