//
//  OptionsList.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/2/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import PopupDialog

class OptionsList: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RequestsUpdate {
    
    var payload = [String]()
    
    @IBOutlet weak var blockView: UIView!
    @IBOutlet weak var blockReason: UITextField!
    @IBOutlet weak var blockFinishButton: UIButton!
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var optionList: UITableView!
    @IBOutlet weak var restrictView: UIView!
    @IBOutlet weak var restrictButton: UIButton!
    @IBOutlet weak var restrictReason: UITextField!
    @IBOutlet weak var doneOverlay: UIView!
    @IBOutlet weak var doneStatus: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.profileManager
        let friendsManager = FriendsManager()
        if(friendsManager.isInFriendList(user: manager.moreOptionsCachedUser!, currentUser: appDelegate.currentUser!)){
            payload = ["block", "report", "remove friend"]
        } else {
            payload = ["block", "report"]
        }
        
        self.optionList.delegate = self
        self.optionList.dataSource = self
        self.optionList.reloadData()
        
        self.blockReason.returnKeyType = .done
        self.blockReason.delegate = self
        self.closeButton.addTarget(self, action: #selector(closeClicked), for: .touchUpInside)
    }
    
    @objc private func closeClicked(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "extra", for: indexPath) as! ProfileExtraCell
        let current = payload[indexPath.item]
        cell.label.text = current
        
        if(current == "block"){
            cell.label.textColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        } else {
            cell.label.textColor = UIColor.init(named: "stayWhite")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = payload[indexPath.item]
        if(current == "block"){
            advanceToBlock()
        }
        if(current == "report"){
            advanceToRestrict()
        }
        if(current == "remove friend"){
            var buttons = [PopupDialogButton]()
            let title = "are you sure?"
            let message = ""
            
            let button = DefaultButton(title: "remove friend") { [weak self] in
                self?.removeFriend()
                
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "nevermind") { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
    }
    
    private func removeFriend(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.profileManager
        let friendsManager = FriendsManager()
        friendsManager.removeFriend(otherUser: manager.moreOptionsCachedUser!, callbacks: self)
    }
    
    private func advanceToBlock(){
        self.blockFinishButton.addTarget(self, action: #selector(blockUser), for: .touchUpInside)
        UIView.animate(withDuration: 0.8, animations: {
            self.optionsView.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.blockView.alpha = 1
            }, completion: nil)
        })
    }
    
    private func advanceToRestrict(){
        self.restrictButton.addTarget(self, action: #selector(restrictUser), for: .touchUpInside)
        UIView.animate(withDuration: 0.8, animations: {
            self.optionsView.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.restrictView.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc private func blockUser(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.profileManager
        let currentUser = appDelegate.currentUser!
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var list = [String: String]()
            if(snapshot.hasChild("blockList")){
                list = snapshot.childSnapshot(forPath: "blockList").value as? [String: String] ?? [String: String]()
                list[manager.moreOptionsCachedUser!.uId] = self.blockReason.text
                ref.child("blockList").setValue(list)
            } else {
                list = [manager.moreOptionsCachedUser!.uId : self.blockReason.text ?? ""]
                ref.child("blockList").setValue(list)
            }
            currentUser.blockList = Array(list.keys)
            
            self.showSuccess(status: "blocked.")
        })
    }
    
    @objc private func restrictUser(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.profileManager
        let currentUser = appDelegate.currentUser!
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var list = [String: String]()
            if(snapshot.hasChild("restrictList")){
                list = snapshot.childSnapshot(forPath: "restrictList").value as? [String: String] ?? [String: String]()
                list[manager.moreOptionsCachedUser!.uId] = self.restrictReason.text
                ref.child("restrictList").setValue(list)
            } else {
                list = [manager.moreOptionsCachedUser!.uId : self.restrictReason.text ?? ""]
                ref.child("restrictList").setValue(list)
            }
            currentUser.blockList = Array(list.keys)
            
            self.showSuccess(status: "reported.")
        })
    }
    
    func updateCell() {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalRequestSuccess() {
    }
    
    func rivalRequestFail() {
    }
    
    func rivalResponseAccepted() {
    }
    
    func rivalResponseRejected() {
    }
    
    func rivalResponseFailed() {
    }
    
    func onlineAnnounceFail() {
    }
    
    func onlineAnnounceSent() {
    }
    
    private func showSuccess(status: String){
        self.doneStatus.text = status
        UIView.animate(withDuration: 0.8, animations: {
            self.doneOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func friendRemoved() {
        showSuccess(status: "removed.")
    }
    
    func friendRemoveFail() {
        self.dismiss(animated: true, completion: nil)
    }
}
