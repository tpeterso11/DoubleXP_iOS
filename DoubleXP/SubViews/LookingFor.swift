//
//  LookingFor.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/27/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class LookingFor: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var lookingTable: UITableView!
    @IBOutlet weak var currentCountLabel: UILabel!
    @IBOutlet weak var maxCountLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    var payload = [Any]() // String or [String]
    var usersSelected = [String]()
    var currentSelectedCount = 0
    var upgrade: Upgrade?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
        
        self.doneButton.addTarget(self, action: #selector(sendPayload), for: .touchUpInside)
        self.lookingTable.estimatedRowHeight = 350
        self.lookingTable.rowHeight = UITableView.automaticDimension
    }
    
    private func buildPayload(){
        payload = [Any]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(!appDelegate.generalLookingFor.isEmpty){
            payload.append("general")
            
            let selection = LookingForSelection()
            selection.gameName = "general"
            selection.choices = appDelegate.generalLookingFor
            payload.append(selection)
        }
        if(!appDelegate.currentUser!.games.isEmpty){
            for game in appDelegate.gcGames {
                if(appDelegate.currentUser!.games.contains(game.gameName) && !game.lookingFor.isEmpty){
                    payload.append(game.gameName)
                    
                    let selection = LookingForSelection()
                    selection.gameName = game.gameName
                    selection.choices = game.lookingFor
                    payload.append(selection)
                }
            }
        }
        if(!payload.isEmpty){
            if(appDelegate.currentUser!.userLookingFor != nil){
                self.usersSelected = appDelegate.currentUser!.userLookingFor
            }
            updateCount()
            self.lookingTable.delegate = self
            self.lookingTable.dataSource = self
        } else {
            //show oops
        }
    }
    
    func updateCount(){
        let count = self.usersSelected.count
        currentCountLabel.text = String(count)
        self.currentSelectedCount = count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        
        if(current is String){
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! LookingForHeader
            cell.title.text = current as? String ?? ""
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "options", for: indexPath) as! LookingForOptions
            cell.setLayout(list: (current as! LookingForSelection).choices, selection: (current as! LookingForSelection), lookingFor: self)
            return cell
        }
    }
    
    func reloadData(){
        lookingTable.reloadData()
    }
    
    func addRemoveChoice(selected: String, choice: LookingForSelection){
        if(self.usersSelected.contains(selected)){
            self.usersSelected.remove(at: self.usersSelected.index(of: selected)!)
            self.lookingTable.reloadData()
            self.updateCount()
        } else {
            if(self.usersSelected.count < 8){
                self.usersSelected.append(selected)
                self.lookingTable.reloadData()
                self.updateCount()
                
                if(self.usersSelected.count == 8){
                    self.currentCountLabel.textColor = #colorLiteral(red: 0.6423664689, green: 0, blue: 0.04794860631, alpha: 1)
                }
            }
        }
    }
    
    @objc func sendPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.child("lookingFor").setValue(self.usersSelected)
        appDelegate.currentUser!.userLookingFor = self.usersSelected
        upgrade?.updateButtons()
        self.dismiss(animated: true, completion: nil)
    }
}

class LookingForSelection: Equatable {
    var gameName: String!
    var choices = [String]()
    
    static func == (lhs: LookingForSelection, rhs: LookingForSelection) -> Bool {
        return lhs.gameName == rhs.gameName && lhs.choices == rhs.choices
    }
}
