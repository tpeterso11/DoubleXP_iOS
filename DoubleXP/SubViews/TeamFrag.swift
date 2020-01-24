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
    @IBOutlet weak var createButton: UIView!
    @IBOutlet weak var faDashButton: UIView!
    @IBOutlet weak var teamSearchButton: UIView!
    @IBOutlet weak var headerView: UIView!
    
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateList()
        
        let createTap = UITapGestureRecognizer(target: self, action: #selector(createButtonClicked))
        createButton.isUserInteractionEnabled = true
        createButton.addGestureRecognizer(createTap)
        
        let faDashTap = UITapGestureRecognizer(target: self, action: #selector(faButtonClicked))
        faDashButton.isUserInteractionEnabled = true
        faDashButton.addGestureRecognizer(faDashTap)
        
        let teamSearchTap = UITapGestureRecognizer(target: self, action: #selector(searchButtonClicked))
        teamSearchButton.isUserInteractionEnabled = true
        teamSearchButton.addGestureRecognizer(teamSearchTap)
        
        createButton.applyGradient(colours:  [#colorLiteral(red: 0.3333052099, green: 0.3333491981, blue: 0.3332902789, alpha: 1), #colorLiteral(red: 0.4791436791, green: 0.4813652635, blue: 0.4867808223, alpha: 1)], orientation: .horizontal)
        faDashButton.applyGradient(colours:  [#colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1), #colorLiteral(red: 0.715370357, green: 0.04661592096, blue: 0.1113757268, alpha: 1)], orientation: .horizontal)
        teamSearchButton.applyGradient(colours:  [#colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.4791436791, green: 0.4813652635, blue: 0.4867808223, alpha: 1)], orientation: .horizontal)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil)
        
        headerView.roundCorners(corners: [.topLeft, .topRight], radius: 25)
        
        appDelegate.navStack.append(self)
        self.pageName = "Team"
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToCreateFrag()
    }
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToViewTeams()
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
        
        if(!(current?.games.isEmpty)!){
            cell.gameName.text = current?.games[0]
        }
        
        cell.contentView.applyGradient(colours:  [#colorLiteral(red: 0.9491214156, green: 0.9434790015, blue: 0.953458488, alpha: 1), #colorLiteral(red: 0.945284307, green: 0.9604713321, blue: 0.9703486562, alpha: 1)], orientation: .horizontal)
            /*cell.contentView.layer.cornerRadius = 20.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true*/
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: cell.bounds.width + 20, height: cell.bounds.height + 20)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.8
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let team = user?.teams[indexPath.item]
        
        LandingActivity().navigateToTeamDashboard(team: team!, newTeam: false)
    }
}