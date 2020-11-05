//
//  MenuFriendsList.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/4/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import ExpyTableView
import SwiftNotificationCenter

class MenuFriendsList: UICollectionViewCell, ExpyTableViewDelegate, ExpyTableViewDataSource, LandingMenuCallbacks{
    @IBOutlet weak var friendsList: ExpyTableView!
    
    var expandedCells = [Int]()
    
    func loadContent(){
        friendsList.delegate = self
        friendsList.dataSource = self
        
        friendsList.rowHeight = UITableView.automaticDimension
        friendsList.estimatedRowHeight = 200
        
        Broadcaster.register(LandingMenuCallbacks.self, observer: self)
        //friendsList.expandingAnimation = .fade
        //friendsList.collapsingAnimation = .fade
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! MenuFriendsListCell
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let current = appDelegate.currentUser!.friends[section]
        cell.friendName.text = current.gamerTag
        
        //if(expandedCells.contains(section)){
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 4.0)
            cell.layer.shadowRadius = 5.0
            cell.layer.shadowOpacity = 0.8
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        //}
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
      return true //Return false if you want your section not to be expandable
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.currentUser!.friends.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cell = tableView.dequeueReusableCell(withIdentifier: "expanded", for: indexPath) as! ExpandedTVCell
        
        if(indexPath.row == 1){
            cell.action.text = "message"
            cell.actionIcon.image = #imageLiteral(resourceName: "message.png")
        }
        else{
            cell.action.text = "profile"
            cell.actionIcon.image = #imageLiteral(resourceName: "information.png")
        }
        //cell.friendName.text = current.gamerTag
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
    
        switch state {
        case .willExpand:
            self.expandedCells.append(section)
            print("WILL EXPAND")
            
        case .willCollapse:
            self.expandedCells.remove(at: self.expandedCells.index(of: section)!)
            print("WILL COLLAPSE")
            
        case .didExpand:
            print("DID EXPAND")
            
        case .didCollapse:
            print("DID COLLAPSE")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //If you don't deselect the row here, seperator of the above cell of the selected cell disappears.
        //Check here for detail: https://stackoverflow.com/questions/18924589/uitableviewcell-separator-disappearing-in-ios7
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if(indexPath.row == 1){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let current = appDelegate.currentUser!.friends[indexPath.section]
            
            Broadcaster.notify(LandingMenuCallbacks.self) {
                $0.menuNavigateToMessaging(uId: current.uid)
            }
            
            friendsList.collapse(indexPath.section)
        }
        else if(indexPath.row == 2){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let current = appDelegate.currentUser!.friends[indexPath.section]
            
            Broadcaster.notify(LandingMenuCallbacks.self) {
                $0.menuNavigateToProfile(uId: current.uid)
            }
            
            friendsList.collapse(indexPath.section)
        }
        
        //This solution obviously has side effects, you can implement your own solution from the given link.
        //This is not a bug of ExpyTableView hence, I think, you should solve it with the proper way for your implementation.
        //If you have a generic solution for this, please submit a pull request or open an issue.
        
        print("DID SELECT row: \(indexPath.row), section: \(indexPath.section)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50)
    }
    
    func menuNavigateToMessaging(uId: String) {
    }
    
    func menuNavigateToProfile(uId: String) {
    }
}
