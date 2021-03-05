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
    var usersSelected = [LookingForSelection]()
    var currentSelectedCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
        
        self.doneButton.addTarget(self, action: #selector(sendPayload), for: .touchUpInside)
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
            usersSelected = appDelegate.currentUser!.userLookingFor
            updateCount()
            self.lookingTable.delegate = self
            self.lookingTable.dataSource = self
        } else {
            //show oops
        }
    }
    
    func updateCount(){
        var count = 0
        for selection in usersSelected {
            count += selection.choices.count
        }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = self.payload[indexPath.item]
        if(current is String){
            return 40
        }
        else {
            return 200
        }
    }
    
    func reloadData(){
        lookingTable.reloadData()
    }
    
    func addRemoveChoice(selected: String, choice: LookingForSelection){
        if(usersSelected.isEmpty){
            let newChoice = LookingForSelection()
            newChoice.gameName = choice.gameName
            newChoice.choices.append(selected)
            usersSelected.append(newChoice)
            self.lookingTable.reloadData()
            self.updateCount()
        } else {
            for selection in usersSelected {
                if(selection.gameName == choice.gameName){
                    var selections = selection.choices
                    if(selections.contains(selected)){
                        if(selections.count == 1){
                            usersSelected.remove(at: usersSelected.index(of: selection)!)
                        } else {
                            selections.remove(at: selections.index(of: selected)!)
                            selection.choices = selections
                        }
                        self.lookingTable.reloadData()
                        self.updateCount()
                    } else {
                        if(self.currentSelectedCount < 8){
                            selections.append(selected)
                            selection.choices = selections
                            self.lookingTable.reloadData()
                            self.updateCount()
                        }
                    }
                } else {
                    if(self.currentSelectedCount < 8){
                        let newChoice = LookingForSelection()
                        newChoice.gameName = choice.gameName
                        newChoice.choices.append(selected)
                        usersSelected.append(newChoice)
                        self.lookingTable.reloadData()
                        self.updateCount()
                    }
                }
            }
        }
    }
    
    func selectionHasBeenSelected(option: String, current: LookingForSelection) -> Bool {
        var contained = false
        for selection in self.usersSelected {
            if(selection.gameName == current.gameName && selection.choices.contains(option)){
                contained = true
                break
            }
        }
        return contained
    }
    
    @objc func sendPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        for selection in self.usersSelected {
            ref.child("lookingFor").child(selection.gameName!).setValue(selection.choices)
        }
        appDelegate.currentUser!.userLookingFor = usersSelected
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
