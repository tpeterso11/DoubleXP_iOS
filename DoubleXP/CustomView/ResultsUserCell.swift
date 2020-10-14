//
//  ResultsUserCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ResultsUserCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource, ProfileCallbacks {
    var payload = [User]()
    var type = ""
    var resultsController: Results?
    @IBOutlet weak var basedOn: UILabel!
    @IBOutlet weak var userList: UITableView!
    
    
    func setUserList(list: [User], type: String, resultsConroller: Results){
        self.payload = list
        self.type = type
        self.resultsController = resultsConroller
        userList.delegate = self
        userList.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ResultsUserInteractionCell
        let current = payload[indexPath.item]
        cell.gamertag.text = current.gamerTag
        if(type == "location"){
            cell.resultType.text = "playing some of the same games near you!"
        } else if(type == "language"){
            cell.resultType.text = "ready to connect!"
        } else if(type == "default"){
            cell.resultType.text = "ready to connect!"
        } else if(type == "perfect"){
            cell.resultType.text = "these guys are tailor-made for you!"
        } else if(type == "games"){
            cell.resultType.text = "you guys play the same games!"
        }
        
        cell.profile.tag = indexPath.item
        cell.profile.addTarget(self, action: #selector(self.navigateToProfile), for: .touchUpInside)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var contained = false
        if(!delegate.currentUser!.sentRequests.isEmpty){
            for request in delegate.currentUser!.sentRequests {
                if(request.uid == current.uId){
                    contained = true
                    break
                }
            }
        }
        if(contained){
            cell.request.backgroundColor = #colorLiteral(red: 0.2880555391, green: 0.2778990865, blue: 0.2911514342, alpha: 1)
            cell.request.titleLabel?.text = "requested"
            cell.request.isUserInteractionEnabled = false
        } else {
            cell.request.isUserInteractionEnabled = true
            cell.request.tag = indexPath.item
            cell.request.addTarget(self, action: #selector(self.sendRequest), for: .touchUpInside)
        }
        
        return cell
    }
    
    @objc private func sendRequest(sender: UIButton){
        let manager = FriendsManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let otherUser = payload[sender.tag]
        manager.sendRequestFromProfile(currentUser: delegate.currentUser!, otherUser: otherUser, callbacks: self)
    }
    
    @objc private func navigateToProfile(sender: UIButton){
        let current = payload[sender.tag]
        self.resultsController?.proceedToProfile(userUid: current.uId)
    }
    
    func onFriendAdded() {
    }
    
    func onFriendDeclined() {
    }
    
    func onFriendRequested() {
        userList.reloadData()
    }
}
