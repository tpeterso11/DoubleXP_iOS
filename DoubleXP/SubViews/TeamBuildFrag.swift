//
//  TeamBuildFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/27/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class TeamBuildFrag: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, TeamCallbacks {
    var team: TeamObject?
    var currentUser: User?
    
    @IBOutlet weak var friendList: UICollectionView!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var freeAgentButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        friendList.delegate = self
        friendList.dataSource = self
        
        freeAgentButton.addTarget(self, action: #selector(faButtonClicked), for: .touchUpInside)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentUser?.friends.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DashFriendInviteCell
        
        let current = self.currentUser!.friends[indexPath.item]
        cell.friendLabel.text = current.gamerTag
        
        var containedInInvites = false
        for invite in team!.teamInvites{
            if(invite.gamerTag == current.gamerTag){
                containedInInvites = true
                break
            }
        }
        
        if(containedInInvites){
            cell.invitedIcon.isHidden = false
        }
        else if((team?.teammateTags.contains(current.gamerTag))!){
            cell.memberIcon.isHidden = false
        }
        else{
            cell.inviteIcon.isHidden = false
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(inviteButtonClicked))
            cell.inviteIcon.isUserInteractionEnabled = true
            cell.inviteIcon.tag = indexPath.item
            cell.inviteIcon.addGestureRecognizer(singleTap)
        }
        
        return cell
    }
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentSearch(team: self.team!)
    }
    
    
    @objc func inviteButtonClicked(_ sender: AnyObject?) {
        let manager = TeamManager()
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        manager.inviteToTeam(team: self.team!, friend: currentUser!.friends[(sender?.tag)!], position: indexPath, callbacks: self)
    }
    
    func updateCell(indexPath: IndexPath) {
        currentUser!.teamInvites.append(team!)
        
        let cell = friendList.cellForItem(at: indexPath) as! DashFriendInviteCell
        cell.inviteIcon.isHidden = true
        cell.invitedIcon.isHidden = false
    }
}
