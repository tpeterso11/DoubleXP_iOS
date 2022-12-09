//
//  MenuFollowDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/3/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController

class MenuFollowerDrawer : UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var followTable: UITableView!
    var type: String!
    var userUid: String!
    var payload: [FriendObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentUser!.uId == userUid){
            if(type == "followers"){
                header.text = "my followers"
            } else {
                header.text = "i'm following..."
            }
        } else {
            if(type == "followers"){
                header.text = "followers"
            } else {
                header.text = "following..."
            }
        }
        
        self.followTable.delegate = self
        self.followTable.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "following", for: indexPath) as! DrawerFollowingCell
        cell.gamertag.text = current.gamerTag
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = payload[indexPath.item]
        let uid = current.uid
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedTest = uid
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.editMode = false
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
}
