//
//  TeamFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
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
    private var emptyTeamList = [EasyTeamObj]()
    
    @IBOutlet weak var buttonLayout: UIView!
    private var user: User?
    private var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentTeamFrag = self
        
        let createTap = UITapGestureRecognizer(target: self, action: #selector(createButtonClicked))
        createButton.isUserInteractionEnabled = true
        createButton.addGestureRecognizer(createTap)
        
        let faDashTap = UITapGestureRecognizer(target: self, action: #selector(faButtonClicked))
        faDashButton.isUserInteractionEnabled = true
        faDashButton.addGestureRecognizer(faDashTap)
        
        let teamSearchTap = UITapGestureRecognizer(target: self, action: #selector(searchButtonClicked))
        teamSearchButton.isUserInteractionEnabled = true
        teamSearchButton.addGestureRecognizer(teamSearchTap)
        
        createButton.applyGradient(colours:  [#colorLiteral(red: 0.177384913, green: 0.172250092, blue: 0.1810538173, alpha: 1), #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0.1774329543, green: 0.1721752286, blue: 0.185343653, alpha: 1)], orientation: .horizontal)
        faDashButton.applyGradient(colours:  [#colorLiteral(red: 0.177384913, green: 0.172250092, blue: 0.1810538173, alpha: 1), #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0.177384913, green: 0.172250092, blue: 0.1810538173, alpha: 1)], orientation: .horizontal)
        teamSearchButton.applyGradient(colours:  [#colorLiteral(red: 0.177384913, green: 0.172250092, blue: 0.1810538173, alpha: 1), #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0.177384913, green: 0.172250092, blue: 0.1810538173, alpha: 1)], orientation: .horizontal)
        
        //headerView.roundCorners(corners: [.topLeft, .topRight], radius: 25)
        
        populateList()
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.navigateToCreateFrag()
    }
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.navigateToTeamFreeAgentDash()
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.navigateToViewTeams()
    }
    
    private func populateList(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        user = delegate.currentUser!
        
        var captain = false
        for team in user!.teams {
            if(team.teamCaptainId == user?.uId){
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
        
        if((user?.teams.isEmpty)!){
            let easyTeam = EasyTeamObj(teamName: "No Teams", teamId: "", gameName:  "Tap to build your first.", teamCaptainId: "", newTeam: "false")
            
            self.emptyTeamList.append(easyTeam)
        }
        
        if(!loaded){
            self.loaded = true
            self.animateView()
        } else {
            self.teamList.reloadData()
        }
    }
    
    func reloadTeams(){
        populateList()
    }
    
    override func reloadView(){
        if(self.teamList != nil){
            self.teamList.reloadData()
        }
    }
    
    private func animateView(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.teamList.delegate = self
            self.teamList.dataSource = self
            
            let top = CGAffineTransform(translationX: 0, y: 30)
            let top2 = CGAffineTransform(translationX: 0, y: -30)
            
            UIView.animate(withDuration: 0.5, animations: {
                    self.teamList.alpha = 1
                    self.teamList.transform = top
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.buttonLayout.transform = top2
                        self.buttonLayout.alpha = 1
                }, completion: nil)
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if((user?.teams.isEmpty)!){
            return self.emptyTeamList.count
        }
        else{
            return user?.teams.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "teamCell", for: indexPath) as! TeamCellTeamFrag
        
        var current: EasyTeamObj
        
        if((user?.teams.isEmpty)!){
            current = self.emptyTeamList[indexPath.item]
        }
        else{
            current = (user?.teams[indexPath.item]) ?? EasyTeamObj(teamName: "", teamId: "", gameName: "", teamCaptainId: "", newTeam: "false")
        }
        cell.teamName.text = current.teamName
        
        
        if(current.teamCaptainId == self.user?.uId ?? ""){
            cell.captainStar.isHidden = false
        }
        
        if(!current.gameName.isEmpty){
            cell.gameName.text = current.gameName
        }
        
        cell.contentView.applyGradient(colours:  [#colorLiteral(red: 0.9491214156, green: 0.9434790015, blue: 0.953458488, alpha: 1), #colorLiteral(red: 0.945284307, green: 0.9604713321, blue: 0.9703486562, alpha: 1)], orientation: .horizontal)
        cell.contentView.layer.cornerRadius = 20.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: cell.bounds.width + 20, height: cell.bounds.height + 20)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.8
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(!user!.teams.isEmpty){
            let team = user?.teams[indexPath.item]
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let currentLanding = appDelegate.currentLanding
            currentLanding!.startDashNavigation(teamName: team!.teamName, teamInvite: nil, newTeam: false)
        }
        else{
            self.createButtonClicked(self)
        }
    }
}
