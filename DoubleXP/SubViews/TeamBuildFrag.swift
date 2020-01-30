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

class TeamBuildFrag: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TeamCallbacks {
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
            
        cell.inviteButton.addTarget(self, action: #selector(inviteButtonClicked), for: .touchUpInside)
        
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
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding?.navigateToTeamFreeAgentSearch(team: self.team!)
    }
    
    
    @objc func inviteButtonClicked(_ sender: AnyObject?) {
        let manager = TeamManager()
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        manager.inviteToTeam(team: self.team!, friend: currentUser!.friends[(sender?.tag)!], position: indexPath, callbacks: self)
    }
    
    func updateCell(indexPath: IndexPath) {
        currentUser!.teamInvites.append(team!)
        
        let cell = friendList.cellForItem(at: indexPath) as! DashFriendInviteCell
        
        cell.inviteButton.addTarget(self, action: #selector(inviteButtonClicked), for: .touchUpInside)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(60))
    }
}
