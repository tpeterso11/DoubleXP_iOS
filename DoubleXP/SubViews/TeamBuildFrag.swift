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

class TeamBuildFrag: ParentVC, UITableViewDataSource, UITableViewDelegate, TeamCallbacks {
    var team: TeamObject?
    var currentUser: User?
    var cellHeights: [CGFloat] = []
    
    @IBOutlet weak var friendsList: UITableView!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var freeAgentButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    
    var invitableFriends = [FriendObject]()
    
    enum Const {
           static let closeCellHeight: CGFloat = 93
           static let openCellHeight: CGFloat = 185
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navDictionary = ["state": "backOnly"]
        let delegate = UIApplication.shared.delegate as! AppDelegate
    
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        if(!delegate.navStack.contains(self)){
            delegate.navStack.append(self)
        }
        self.pageName = "Team Build"
        
        currentUser = delegate.currentUser
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        if(!(self.currentUser?.friends.isEmpty)!){
            for friend in currentUser!.friends{
                if(!(team!.teammateIds.contains(friend.uid)) && !(team!.teamInviteTags.contains(friend.gamerTag))){
                    invitableFriends.append(friend)
                }
            }
            
            if(!invitableFriends.isEmpty){
                self.setup()
                animateView()
            }
            else{
                //show empty
            }
        }
        
        freeAgentButton.addTarget(self, action: #selector(faButtonClicked), for: .touchUpInside)
    }
    
    private func animateView(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.friendsList.delegate = self
            self.friendsList.dataSource = self
            
            let top2 = CGAffineTransform(translationX: 0, y: -10)
            
            UIView.animate(withDuration: 0.8, animations: {
                    self.friendsList.alpha = 1
                    self.friendsList.transform = top2
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.invitableFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TeamBuildFriendCell
        
        let current = self.invitableFriends[indexPath.item]
        cell.coverLabel.text = current.gamerTag
        cell.underLabel.text = current.gamerTag
        
        cell.inviteButton.addTarget(self, action: #selector(inviteButtonClicked), for: .touchUpInside)
        cell.profileButton.addTarget(self, action: #selector(profileButtonClicked), for: .touchUpInside)
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as FoldingCellCell = cell else {
            return
        }

        cell.backgroundColor = .clear

        if cellHeights[indexPath.row] == Const.closeCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }

        //cell.number = indexPath.row
    }
    
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! TeamBuildFriendCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.6
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.3
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > tableView.frame.maxY {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: nil)
    }
    
    @objc func faButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let teamManager = TeamManager()
        if(team!.teamNeeds.isEmpty || !teamManager.isTeamCaptain(user: delegate.currentUser!, team: self.team!)){
            delegate.currentLanding?.navigateToTeamFreeAgentSearch(team: self.team!)
        }
        else{
            delegate.currentLanding?.navigateToTeamFreeAgentResults(team: self.team!)
        }
    }
    
    
    @objc func inviteButtonClicked(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        let cell = friendsList.cellForRow(at: indexPath) as! TeamBuildFriendCell
        cellHeights[indexPath.row] = Const.closeCellHeight
        cell.unfold(false, animated: true, completion: nil)
        let duration = 0.3
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            self.friendsList.beginUpdates()
            self.friendsList.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > self.friendsList.frame.maxY {
                self.friendsList.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: { (finished: Bool) in
           let manager = TeamManager()
           let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
           manager.inviteToTeam(team: self.team!, friend: self.invitableFriends[(sender?.tag)!], position: indexPath, callbacks: self)
        })
    }
    
    @objc func profileButtonClicked(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        let cell = friendsList.cellForRow(at: indexPath) as! TeamBuildFriendCell
        cellHeights[indexPath.row] = Const.closeCellHeight
        cell.unfold(false, animated: true, completion: nil)
        let duration = 0.3
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            self.friendsList.beginUpdates()
            self.friendsList.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > self.friendsList.frame.maxY {
                self.friendsList.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let current = self.invitableFriends[(sender?.tag)!]
            
            delegate.currentLanding?.navigateToProfile(uid: current.uid)
        })
    }
    
    func updateCell(indexPath: IndexPath) {
        currentUser!.teamInvites.append(team!)
        team!.teamInviteTags.append(self.invitableFriends[indexPath.item].gamerTag)
        
        self.invitableFriends.remove(at: indexPath.item)
        self.friendsList.deleteRows(at: [indexPath], with: .automatic)
    }
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: (self.invitableFriends.count))
        friendsList.estimatedRowHeight = Const.closeCellHeight
        friendsList.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            friendsList.refreshControl = UIRefreshControl()
            friendsList.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
        
        //statEmpty.isHidden = true
        self.friendsList.dataSource = self
        self.friendsList.delegate = self
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.friendsList.refreshControl?.endRefreshing()
            }
            self?.friendsList.reloadData()
        })
    }
}
