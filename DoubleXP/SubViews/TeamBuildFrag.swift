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
    
    enum Const {
           static let closeCellHeight: CGFloat = 90
           static let openCellHeight: CGFloat = 235
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageName = "Team Build"
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.navStack.append(self)
        
        currentUser = appDelegate.currentUser
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        if(!(self.currentUser?.friends.isEmpty)!){
            self.setup()
            friendsList.delegate = self
            friendsList.dataSource = self
        }
        
        freeAgentButton.addTarget(self, action: #selector(faButtonClicked), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentUser?.friends.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TeamBuildFriendCell
        
        let current = self.currentUser!.friends[indexPath.item]
        
        
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
        
        //let cell = friendsList.cellForItem(at: indexPath) as! DashFriendInviteCell
        
        //cell.inviteButton.addTarget(self, action: #selector(inviteButtonClicked), for: .touchUpInside)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.width - 10, height: CGFloat(60))
    }
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: (self.currentUser?.friends.count)!)
        friendsList.estimatedRowHeight = Const.closeCellHeight
        friendsList.rowHeight = UITableView.automaticDimension
        friendsList.backgroundColor = UIColor.white
        
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
