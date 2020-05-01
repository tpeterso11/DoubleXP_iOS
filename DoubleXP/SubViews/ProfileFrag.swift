//
//  Profile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import UnderLineTextField

class ProfileFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CurrentProfileCallbacks, UITextFieldDelegate{
    
    @IBOutlet weak var bottomDrawerCover: UIView!
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
    @IBOutlet weak var bottomDrawer: UIView!
    @IBOutlet weak var gamerTagField: UnderLineTextField!
    @IBOutlet weak var drawerPSSwitch: UISwitch!
    @IBOutlet weak var drawerPSLabel: UILabel!
    @IBOutlet weak var drawerXboxSwitch: UISwitch!
    @IBOutlet weak var drawerXboxLabel: UILabel!
    @IBOutlet weak var drawerNintendoSwitch: UISwitch!
    @IBOutlet weak var drawerNintendoLabel: UILabel!
    @IBOutlet weak var drawerPcSwitch: UISwitch!
    @IBOutlet weak var drawerPcLabel: UILabel!
    @IBOutlet weak var drawerAddButton: UIButton!
    @IBOutlet weak var drawerCancelButton: UIButton!
    var gcGames = [GamerConnectGame]()
    var gamesPlayed = [GamerConnectGame]()
    var payload = [String]()
    var bioIndexPath: IndexPath?
    var consoleIndexPath: IndexPath?
    var gamesIndexPath: IndexPath?
    var testCell: ProfileConsolesCell?
    var currentProfilePayload = [[String: String]]()
    var drawerOpen = false
    var drawerHeight: CGFloat!
    var currentConsoleCell: ProfileConsolesCell?
    var currentGamesCell: ProfileGamesCell?
    
    var drawerSwitches = [UISwitch]()
    var addedName = ""
    var addedIndex: IndexPath!
    var removedName = ""
    var removedIndex: IndexPath!
    
    var bio: String?
    var ps: Bool!
    var xbox: Bool!
    var pc: Bool!
    var nintendo: Bool!
    
    var chosenConsole = ""
    var consoleChecked = false
    
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
        self.pageName = "Profile"
        
        appDelegate.addToNavStack(vc: self)
        
        self.saveButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
        self.saveButton.isUserInteractionEnabled = false
        
        self.cancelButton.addTarget(self, action: #selector(cancelButtonClicked), for: .touchUpInside)
        
        let currentUser = appDelegate.currentUser!
        
        for profile in currentUser.gamerTags{
            let current = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console]
            currentProfilePayload.append(current)
        }
        
        for game in gcGames{
            if(currentUser.games.contains(game.gameName)){
                gamesPlayed.append(game)
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDisappear),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        setup()
        
        gamerTagField.delegate = self
        gamerTagField.returnKeyType = UIReturnKeyType.done
        
        drawerSwitches.append(drawerPSSwitch)
        drawerSwitches.append(drawerXboxSwitch)
        drawerSwitches.append(drawerPcSwitch)
        drawerSwitches.append(drawerNintendoSwitch)
        
        drawerPSSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        drawerXboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        drawerPcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        drawerNintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile"))
    }
    
    func gameAdded(gameName: String, indexPath: IndexPath){
        self.addedName = gameName
        self.addedIndex = indexPath
        
        showBottomDrawer()
    }
    
    func gameRemoved(gameName: String, indexPath: IndexPath) {
        for array in self.currentProfilePayload{
            if(array["game"] == gameName){
                self.currentProfilePayload.remove(at: currentProfilePayload.index(of: array)!)
            }
        }
        
        checkGamerProfiles()
        
        currentGamesCell?.updateCell(indexPath: indexPath, gameName: gameName, show: false)
    }
    
    @objc func psSwitchChanged(psSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:psSwitch)
    }
    
    @objc func xboxSwitchChanged(psSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:psSwitch)
    }
    
    @objc func pcSwitchChanged(psSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:psSwitch)
    }
    
    @objc func nintendoSwitchChanged(psSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:psSwitch)
    }
    
    private func cycleSwitches(selectedSwitch: UISwitch){
        var console = ""
        for uiSwitch in self.drawerSwitches{
            if(uiSwitch == selectedSwitch){
                if(!uiSwitch.isOn){
                    uiSwitch.isOn = false
                }
                else{
                    uiSwitch.isOn = true
                    
                    if(uiSwitch == self.drawerNintendoSwitch){
                        console = "nintendo"
                    }
                    if(uiSwitch == self.drawerXboxSwitch){
                        console = "xbox"
                    }
                    if(uiSwitch == self.drawerPSSwitch){
                        console = "ps"
                    }
                    if(uiSwitch == self.drawerPcSwitch){
                        console = "pc"
                    }
                    
                    consoleChecked = true
                }
            }
            else{
                uiSwitch.isOn = false
            }
        }
        
        if(console == ""){
            consoleChecked = false
        }
        self.chosenConsole = console
        
        checkNextActivation()
    }
    
    private func checkNextActivation(){
        if(consoleChecked && gamerTagField.text != nil){
            self.drawerAddButton.alpha = 1
            
            self.drawerAddButton.isUserInteractionEnabled = true
            self.drawerAddButton.addTarget(self, action: #selector(addButtonClicked), for: .touchUpInside)
        }
        else{
            self.drawerAddButton.alpha = 0.33
           
            self.drawerAddButton.isUserInteractionEnabled = false
        }
    }
    
    @objc func addButtonClicked() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        
        if(drawerPSSwitch.isOn){
            currentUser!.ps = true
            if(self.currentConsoleCell?.psSwitch != nil){
                if(!(self.currentConsoleCell?.psSwitch.isOn)!){
                    self.currentConsoleCell?.psSwitch.isOn = true
                }
            }
        }
        if(drawerXboxSwitch.isOn){
            currentUser!.xbox = true
            if(self.currentConsoleCell?.xBoxSwitch != nil){
                if(!(self.currentConsoleCell?.xBoxSwitch.isOn)!){
                    self.currentConsoleCell?.xBoxSwitch.isOn = true
                }
            }
        }
        if(drawerPcSwitch.isOn){
            currentUser!.pc = true
            if(self.currentConsoleCell?.pcSwitch != nil){
                if(!(self.currentConsoleCell?.pcSwitch.isOn)!){
                    self.currentConsoleCell?.pcSwitch.isOn = true
                }
            }
        }
        if(drawerNintendoSwitch.isOn){
            currentUser!.nintendo = true
            if(self.currentConsoleCell?.pcSwitch != nil){
                if(!(self.currentConsoleCell?.nintendoSwitch.isOn)!){
                    self.currentConsoleCell?.nintendoSwitch.isOn = true
                }
            }
        }
        
        dismissDrawer()
        
        let current = ["gamerTag": gamerTagField.text!, "game": self.addedName, "console": self.chosenConsole]
        self.currentProfilePayload.append(current)
        
        currentGamesCell?.updateCell(indexPath: self.addedIndex, gameName: self.addedName, show: true)
        // send broadcast to update cell
    }
    
    private func dismissDrawer(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.bottomDrawer.transform = top
        }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5) {
                self.bottomDrawerCover.alpha = 0
                    
                self.drawerOpen = false
            }
        })
    }
    
    func showBottomDrawer(){
        let top = CGAffineTransform(translationX: 0, y: -290)
        UIView.animate(withDuration: 0.8, animations: {
            self.bottomDrawerCover.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.bottomDrawer.transform = top
                
                self.drawerOpen = true
            }, completion: nil)
        })
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if(drawerOpen){
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                
                self.drawerHeight = keyboardHeight
                
                extendBottom(height: self.drawerHeight)
            }
        }
    }
    
    @objc func keyboardWillDisappear() {
        if(drawerOpen){
            let top = CGAffineTransform(translationX: 0, y: -290)
            UIView.animate(withDuration: 0.5, animations: {
                self.bottomDrawer.transform = top
            }, completion: nil)
        }
    }
    
    private func extendBottom(height: CGFloat){
        let top = CGAffineTransform(translationX: 0, y: -390)
        UIView.animate(withDuration: 0.8, animations: {
            self.bottomDrawer.transform = top
        }, completion: nil)
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
        
        self.bio = appDelegate.currentUser?.bio
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
            self.currentGamesCell = cell
            
            cell.setUi(list: self.gamesPlayed, callbacks: self)
            
            self.gamesIndexPath = indexPath
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "consoles", for: indexPath) as! ProfileConsolesCell
            
            self.currentConsoleCell = cell
            
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
        manager.saveChanges(bio: self.bio ?? "", games: games, ps: self.ps, pc: self.pc, xBox: self.xbox, nintendo: self.nintendo, profiles: self.currentProfilePayload, callbacks: self)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        currentUser!.ps = self.ps
        currentUser!.xbox = self.xbox
        currentUser!.pc = self.pc
        currentUser!.nintendo = self.nintendo
        
        var profiles = [GamerProfile]()
        for profile in self.currentProfilePayload{
            let newProfile = GamerProfile(gamerTag: profile["gamerTag"]!, game: profile["game"]!, console: profile["console"]!)
            profiles.append(newProfile)
        }
        currentUser!.gamerTags = profiles
        currentUser!.games = games
        currentUser!.bio = self.bio ?? ""
        
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Profile Updated"))
    }
    
    @objc func cancelButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToHome()
    }
    
    func checkGamerProfiles(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        
        var psIsOn = false
        var xIsOn = false
        var pcIsOn = false
        var ninIsOn = false
        
        for profile in currentUser!.gamerTags{
            if(profile.console == "ps" && !psIsOn){
                self.currentConsoleCell?.psSwitch.isOn = true
                psIsOn = true
            }
            if(profile.console == "xbox" && !xIsOn){
                self.currentConsoleCell?.xBoxSwitch.isOn = true
                xIsOn = true
            }
            if(profile.console == "pc" && !pcIsOn){
                self.currentConsoleCell?.pcSwitch.isOn = true
                pcIsOn = true
            }
            if(profile.console == "xbox" && !ninIsOn){
                self.currentConsoleCell?.nintendoSwitch.isOn = true
                ninIsOn = true
            }
        }
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
