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
    
    var payload = [Any]() // String or [String]
    var usersSelected = [String]()
    var currentSelectedCount = 0
    var upgrade: Upgrade?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
        
        self.lookingTable.estimatedRowHeight = 350
        self.lookingTable.rowHeight = UITableView.automaticDimension
    }
    
    private func buildPayload(){
        payload = [Any]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(!appDelegate.generalLookingFor.isEmpty){
            let obj = LookingForObj()
            obj.name = "general"
            payload.append(obj)
            
            let selection = LookingForSelection()
            selection.gameName = "general"
            selection.choices = appDelegate.generalLookingFor
            payload.append(selection)
        }
        if(!appDelegate.currentUser!.games.isEmpty){
            for game in appDelegate.gcGames {
                if(appDelegate.currentUser!.games.contains(game.gameName) && !game.lookingFor.isEmpty){
                    let obj = LookingForObj()
                    obj.name = game.gameName
                    obj.image = game.imageUrl
                    payload.append(obj)
                    
                    let selection = LookingForSelection()
                    selection.gameName = game.gameName
                    selection.choices = game.lookingFor
                    payload.append(selection)
                }
            }
        }
        payload.append("end")
        if(!payload.isEmpty){
            self.usersSelected = appDelegate.currentUser!.userLookingFor
            self.lookingTable.delegate = self
            self.lookingTable.dataSource = self
        } else {
            //show oops
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        
        if(current is LookingForObj){
            let currentObj = (current as! LookingForObj)
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! LookingForHeader
            cell.title.text = currentObj.name
            if((current as! LookingForObj).image != nil){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let cache = appDelegate.imageCache
                if(cache.object(forKey: currentObj.image! as NSString) != nil){
                    cell.headerImg.image = cache.object(forKey: currentObj.image! as NSString)
                } else {
                    cell.headerImg.moa.onSuccess = { image in
                        cell.headerImg.image = image
                        appDelegate.imageCache.setObject(image, forKey: currentObj.image! as NSString)
                        return image
                    }
                    cell.headerImg.moa.url = currentObj.image!
                }
            } else {
                cell.headerImg.image = UIImage(named: "profile_cta.jpg")
            }
            return cell
        } else if(current is String){
            let cell = tableView.dequeueReusableCell(withIdentifier: "end", for: indexPath) as! LookingForEndCell
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
            self.updateChoices(usersSelected: self.usersSelected)
            self.lookingTable.reloadData()
        } else {
            if(self.usersSelected.count < 8){
                self.usersSelected.append(selected)
                self.updateChoices(usersSelected: self.usersSelected)
                self.lookingTable.reloadData()
            }
        }
    }
    
    private func updateChoices(usersSelected: [String]){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.child("lookingFor").setValue(usersSelected)
        appDelegate.currentUser!.userLookingFor = usersSelected
    }
}

class LookingForSelection: Equatable {
    var gameName: String!
    var choices = [String]()
    
    static func == (lhs: LookingForSelection, rhs: LookingForSelection) -> Bool {
        return lhs.gameName == rhs.gameName && lhs.choices == rhs.choices
    }
}

class LookingForObj {
    var name: String? = nil
    var image: String? = nil
}
