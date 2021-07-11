//
//  AboutYouDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/29/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class AboutYouDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var aboutTable: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    var payload = [Any]()
    var upgrade: Upgrade?
    var usersSelected = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
        self.saveButton.addTarget(self, action: #selector(sendPayload), for: .touchUpInside)
    }
    
    private func buildPayload(){
        payload = [Any]()
        
        payload.append("header")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
            if(appDelegate.currentUser!.userAbout != nil){
                self.usersSelected = appDelegate.currentUser!.userAbout
            }
            self.aboutTable.delegate = self
            self.aboutTable.dataSource = self
        } else {
            //show oops
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        
        if(current is String){
            if((current as! String) == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! EmptyCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "gameHeader", for: indexPath) as! LookingForHeader
                cell.title.text = current as? String ?? ""
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "options", for: indexPath) as! AboutMeOptions
            cell.setLayout(list: (current as! LookingForSelection).choices, selection: (current as! LookingForSelection), aboutDrawer: self)
            return cell
        }
    }
    
    func reloadData(){
        self.aboutTable.reloadData()
    }
    
    func addRemoveChoice(selected: String, choice: LookingForSelection){
        if(self.usersSelected.contains(selected)){
            self.usersSelected.remove(at: self.usersSelected.index(of: selected)!)
            self.aboutTable.reloadData()
        } else {
            if(self.usersSelected.count < 8){
                self.usersSelected.append(selected)
                self.aboutTable.reloadData()
            }
        }
    }
    
    @objc func sendPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.child("aboutMe").setValue(self.usersSelected)
        appDelegate.currentUser!.userAbout = self.usersSelected
        upgrade?.updateButtons()
        self.dismiss(animated: true, completion: nil)
    }
}
