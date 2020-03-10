//
//  Profile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CurrentProfileCallbacks, UITextFieldDelegate{
    
    @IBOutlet weak var savedOverlay: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var profileCollection: UICollectionView!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var bioEntry: UITextField!
    @IBOutlet weak var gamesCollection: UITableView!
    var gcGames = [GamerConnectGame]()
    var gamesPlayed = [GamerConnectGame]()
    var payload = [String]()
    var bioIndexPath: IndexPath?
    var consoleIndexPath: IndexPath?
    var gamesIndexPath: IndexPath?
    var testCell: ProfileConsolesCell?
    
    var bio: String?
    var ps: Bool!
    var xbox: Bool!
    var pc: Bool!
    var nintendo: Bool!
    
    
    var cellHeights: [CGFloat] = []
    enum Const {
           static let closeCellHeight: CGFloat = 83
           static let openCellHeight: CGFloat = 205
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        gcGames = appDelegate.gcGames
        
        if(!appDelegate.navStack.contains(self)){
            appDelegate.navStack.append(self)
        }
        
        self.pageName = "Profile"
        self.saveButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
        self.saveButton.isUserInteractionEnabled = false
        
        let currentUser = appDelegate.currentUser!
        
        for game in gcGames{
            if(currentUser.games.contains(game.gameName)){
                gamesPlayed.append(game)
            }
        }
        
        setup()
    }
    
    private func setup(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.ps = appDelegate.currentUser!.ps
        self.xbox = appDelegate.currentUser!.xbox
        self.pc = appDelegate.currentUser!.pc
        self.nintendo = appDelegate.currentUser!.nintendo
        
        
        self.payload.append("tag")
        self.payload.append("games")
        self.payload.append("console")
        
        profileCollection.dataSource = self
        profileCollection.delegate = self
        //self.payload.append("import")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        if(current == "tag"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tag", for: indexPath) as! ProfileGamerTagCell
            
            if(currentUser.bio.isEmpty){
                cell.bioTextField.attributedPlaceholder = NSAttributedString(string: "you don't have a bio yet. let the people know who you are.",
                                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            }
            else{
                cell.bioTextField.attributedPlaceholder = NSAttributedString(string: "you don't have a bio yet. let the people know who you are.",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            }
            
            cell.bioTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            cell.bioTextField.delegate = self
            cell.bioTextField.returnKeyType = .done
            
            self.bioIndexPath = indexPath
            return cell
        }
        else if(current == "games"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "games", for: indexPath) as! ProfileGamesCell
            cell.setUi(list: self.gamesPlayed, callbacks: self)
            
            self.gamesIndexPath = indexPath
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "consoles", for: indexPath) as! ProfileConsolesCell
            
            if(currentUser.ps){
                cell.psSwitch.isOn = true
            }
            cell.psSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
            if(currentUser.xbox){
                cell.xBoxSwitch.isOn = true
            }
            cell.xBoxSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
            if(currentUser.pc){
                cell.pcSwitch.isOn = true
            }
            cell.pcSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
            if(currentUser.nintendo){
                cell.nintendoSwitch.isOn = true
            }
            cell.nintendoSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
            self.testCell = cell
            self.consoleIndexPath = indexPath
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.payload[indexPath.item]
        
        if (current == "tag") {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
        }
        else if(current == "games"){
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(500))
        }
        else{
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        checkChanges(updatedList: nil)
        
        self.bio = textField.text
    }
    
    @objc func switchChanged(cSwitch: UISwitch) {
       checkChanges(updatedList: nil)
        
        let cell = self.profileCollection.cellForItem(at: self.consoleIndexPath!) as? ProfileConsolesCell
        
        if(cSwitch == cell?.psSwitch){
            self.ps = cell?.psSwitch.isOn
        }
        
        if(cSwitch == cell?.xBoxSwitch){
            self.xbox = cell?.xBoxSwitch.isOn
        }
        
        if(cSwitch == cell?.pcSwitch){
            self.pc = cell?.pcSwitch.isOn
        }
        
        if(cSwitch == cell?.nintendoSwitch){
            self.nintendo = cell?.nintendoSwitch.isOn
        }
    }
    
    func checkChanges(updatedList: [GamerConnectGame]?){
        if(updatedList != nil){
            self.gamesPlayed = updatedList!
        }
        
        var changed = false
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        //check games, check array is the users games at it's current state.
        var checkArray = [GamerConnectGame]()
        
        //get a new version of the games from the user obj.
        for game in gcGames{
            if(currentUser.games.contains(game.gameName)){
                checkArray.append(game)
            }
        }
        
        //user cleared options, if the user had options, and cleared them.
        if(checkArray.count > 0 && self.gamesPlayed.isEmpty){
            changed = true
        }
        
        //if the user had any or none options, and added or subtracted one.
        if(checkArray.count != self.gamesPlayed.count){
            changed = true
        }
        
        //if the user removed one, and added a different one.
        if(!changed){
            //compare check array to current working array.
            for game in gamesPlayed{
                if(!checkArray.contains(game)){
                    changed = true
                    break
                }
            }
        }
        
        if(!changed){
        //check bio
            let cell = self.profileCollection.cellForItem(at: self.bioIndexPath!) as? ProfileGamerTagCell
            if(cell != nil){
                if(cell!.bioTextField.hasText){
                    changed = true
                }
            }
        }
        
        if(!changed){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = appDelegate.currentUser!
            let cell = self.profileCollection.cellForItem(at: self.consoleIndexPath!) as? ProfileConsolesCell
            //let cell = self.testCell!
            
            if(cell != nil){
                if(currentUser.ps && !cell!.psSwitch.isOn){
                    changed = true
                }
                else if(!currentUser.ps && cell!.psSwitch.isOn){
                    changed = true
                }
                else if(currentUser.xbox && !cell!.xBoxSwitch.isOn){
                    changed = true
                }
                else if(!currentUser.xbox && cell!.xBoxSwitch.isOn){
                    changed = true
                }
                else if(currentUser.pc && !cell!.pcSwitch.isOn){
                    changed = true
                }
                else if(!currentUser.pc && cell!.pcSwitch.isOn){
                    changed = true
                }
                else if(currentUser.nintendo && !cell!.nintendoSwitch.isOn){
                    changed = true
                }
                else if(!currentUser.nintendo && cell!.nintendoSwitch.isOn){
                    changed = true
                }
            }
        }
        
        if(changed){
            self.saveButton.alpha = 1
            self.saveButton.isUserInteractionEnabled = true
        }
        else{
            self.saveButton.alpha = 0.5
            self.saveButton.isUserInteractionEnabled = false
        }
    }
    
    @objc func saveButtonClicked(_ sender: AnyObject?) {
        var games = [String]()
        for game in gamesPlayed{
            games.append(game.gameName)
        }
        
        let manager = ProfileManage()
        manager.saveChanges(bio: self.bio ?? "", games: games, ps: self.ps, pc: self.pc, xBox: self.xbox, nintendo: self.nintendo, callbacks: self)
    }
    
    func changesComplete() {
        UIView.animate(withDuration: 0.5, animations: {
            self.savedOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentLanding?.navigateToHome()
            }
        })
    }
}
