//
//  ViewTeamsFoldingCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FoldingCell

class ViewTeamsFoldingCell: FoldingCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TeamInteractionCallbacks{

    @IBOutlet weak var requestStatusOverlay: UIView!
    @IBOutlet weak var requestStatus: UILabel!
    @IBOutlet weak var teamName: UILabel!
    @IBOutlet weak var needsCollection: UICollectionView!
    @IBOutlet weak var drawer: UIView!
    @IBOutlet weak var gameBack: UIImageView!
    @IBOutlet weak var underImage: UIImageView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var statusText: UILabel!
    private var selectedNeeds = [String]()
    private var profiles = [FreeAgentObject]()
    private var gameName = ""
    private var currentTeam: TeamObject?
    private var currentCollection: UITableView?
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        drawer.layer.cornerRadius = 10
        drawer.layer.masksToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        needsCollection.setCollectionViewLayout(layout, animated: false)
        
        super.awakeFromNib()
    }

    func setUI(team: TeamObject, profiles: [FreeAgentObject], gameName: String, indexPath: IndexPath, collectionView: UITableView){
        self.profiles = [FreeAgentObject]()
        self.gameName = gameName
        self.currentTeam = team
        self.teamName.text = team.teamName
        self.currentCollection = collectionView
        self.selectedNeeds = [String]()
        
        self.profiles.append(contentsOf: profiles)
        
        if(!team.selectedTeamNeeds.isEmpty){
            self.selectedNeeds.append("needs_header_one")
            self.selectedNeeds.append(contentsOf: team.selectedTeamNeeds)
            needsCollection.delegate = self
            needsCollection.dataSource = self
        }
        
        var contained = false
        var containedProfile: FreeAgentObject?
        
        for profile in self.profiles{
            if(profile.game == self.gameName){
                contained = true
                containedProfile = profile
                break
            }
        }
        
        //if this user has a game profile for this game AND the current teams' team needs are not empty
        if(contained && !self.currentTeam!.selectedTeamNeeds.isEmpty){
            if(self.currentTeam!.selectedTeamNeeds.contains((containedProfile?.questions[0][0])!)){
                //match team needs
                self.sendButton.tag = indexPath.item
                self.sendButton.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
                
                self.statusText.text = " send a request to join this team."
                self.createButton.isHidden = true
            }
            else{
                //do not match team needs
                self.statusText.text = " you do not have a profile that matches this teams needs."
                self.createButton.isHidden = false
                self.sendButton.alpha = 0.4
                self.sendButton.isUserInteractionEnabled = false
                
                self.createButton.addTarget(self, action: #selector(createProfile), for: .touchUpInside)
            }
            //else need to handle change to "You do not fit this teams needs"
        }
        else if(contained && (self.currentTeam!.teamNeeds.isEmpty || self.currentTeam!.selectedTeamNeeds.isEmpty)){
            //if this user has a game profile for this game AND there are no team needs. Anyone can join.
            self.sendButton.tag = indexPath.item
            self.sendButton.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
            
            self.createButton.isHidden = true
            self.statusText.text = " send a request to join this team."
        }
        else{
            //if this gamer does not have a game profile for this game AND there are team needs.
            if(!contained && !self.currentTeam!.selectedTeamNeeds.isEmpty){
                self.statusText.text = " you do not have a profile that matches this teams needs."
                self.createButton.isHidden = false
                self.sendButton.alpha = 0.4
                self.sendButton.isUserInteractionEnabled = false
                
                self.createButton.addTarget(self, action: #selector(createProfile), for: .touchUpInside)
            }
            else{
                //if not contained and no team needs, they still need a profile to request
                self.statusText.text = " you do not have a profile that matches this teams needs."
                self.createButton.isHidden = false
                self.sendButton.alpha = 0.4
                self.sendButton.isUserInteractionEnabled = false
                
                self.createButton.addTarget(self, action: #selector(createProfile), for: .touchUpInside)
                self.statusText.text = " need a profile to request to join this team."
            }
        }
    }
    
    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedNeeds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.selectedNeeds[indexPath.item]
        if(current == "needs_header_one"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "header", for: indexPath) as! ViewTeamsNeedsHeader
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ViewTeamsNeedsCell
            cell.need.text = current
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)//here your custom value for spacing
        }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                let lay = collectionViewLayout as! UICollectionViewFlowLayout
                let widthPerItem = collectionView.frame.width / 3 - lay.minimumInteritemSpacing

        if indexPath.item == 0 {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(25))
        }
        else{
            return CGSize(width: widthPerItem, height: CGFloat(20))
        }
    }
    
    @objc func sendRequest(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        
        let manager = TeamManager()
        manager.sendRequestToJoin(freeAgent: profiles[indexPath.item], team: self.currentTeam!, callbacks: self, indexPath: indexPath)
    }
    
    @objc func createProfile(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: 0, section: (sender?.tag)!)
        self.currentCollection?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.currentCollection?.delegate?.tableView!(self.currentCollection!, didSelectRowAt: indexPath)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        var gcGame: GamerConnectGame?
        
        for game in delegate.gcGames{
            if(game.gameName == self.gameName){
                gcGame = game
                break
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            delegate.currentLanding?.navigateToFreeAgentQuiz(team: self.currentTeam, gcGame: gcGame!, currentUser: currentUser!)
        }
    }
    
    func successfulRequest(indexPath: IndexPath) {
        self.currentCollection?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.currentCollection?.delegate?.tableView!(self.currentCollection!, didSelectRowAt: indexPath)
        
        self.requestStatusOverlay.backgroundColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.8515089897)
        self.requestStatus.text = "requested."
        
        UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
            self.requestStatusOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                self.isUserInteractionEnabled = false
            }, completion: nil)
        })
    }
    
    func failedRequest(indexPath: IndexPath) {
        self.currentCollection?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.currentCollection?.delegate?.tableView!(self.currentCollection!, didSelectRowAt: indexPath)
        
        self.requestStatusOverlay.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
        self.requestStatus.text = "error."
        
        UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
            self.requestStatusOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 2.5, options: [], animations: {
                self.requestStatusOverlay.alpha = 0
            }, completion: nil)
        })
    }
}
