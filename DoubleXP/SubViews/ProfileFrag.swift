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
import SPStorkController

class ProfileFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CurrentProfileCallbacks, UITextFieldDelegate, SPStorkControllerDelegate{
    
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
    var selectedTag = ""
    
    var drawerSwitches = [UISwitch]()
    var addedName = ""
    var addedIndex: IndexPath!
    var removedName = ""
    var removedIndex: IndexPath!
    var statsAvailable = false
    var quizAvailable = false
    var cachedUidFromProfile = ""
    var uniqueTags = [String]()
    
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
        
        self.saveButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
        self.saveButton.alpha = 1
        self.saveButton.isUserInteractionEnabled = true
        
        self.cancelButton.addTarget(self, action: #selector(cancelButtonClicked), for: .touchUpInside)
        
        let currentUser = appDelegate.currentUser!
        
        self.selectedTag = currentUser.gamerTag
        
        for profile in currentUser.gamerTags{
            if(!self.uniqueTags.contains(profile.gamerTag)){
                self.uniqueTags.append(profile.gamerTag)
            }
            let current = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console]
            currentProfilePayload.append(current)
        }
        
        for game in gcGames{
            if(currentUser.games.contains(game.gameName)){
                gamesPlayed.append(game)
            }
        }
        
        let games = currentUser.games
        for game in appDelegate.gcGames {
            if(game.statsAvailable && games.contains(game.gameName)){
                self.statsAvailable = true
                break
            }
        }
        
        for game in appDelegate.gcGames {
            if(!game.quizUrl.isEmpty && games.contains(game.gameName)){
                self.quizAvailable = true
                break
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
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile"))
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
        self.payload = [String]()
        if(self.uniqueTags.count > 1){
            self.payload.append("preferred")
        }
        self.payload.append("tag")
        self.payload.append("games")
        if(quizAvailable){
            self.payload.append("quiz")
        }
        if(statsAvailable){
            self.payload.append("stats")
        }
    
        profileCollection.dataSource = self
        profileCollection.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
                cell.bioTextField.attributedPlaceholder = NSAttributedString(string: currentUser.bio,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            }
            
            cell.bioTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            cell.bioTextField.delegate = self
            cell.bioTextField.returnKeyType = .done
            
            self.bioIndexPath = indexPath
            return cell
        } else if(current == "games") {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "games", for: indexPath) as! EditProfileGamesCell
            return cell
        } else if(current == "quiz") {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "quiz", for: indexPath) as! EditProfileQuizCell
            if(!self.quizAvailable){
                cell.cover.alpha = 1
            } else {
                cell.cover.alpha = 0
            }
            return cell
        } else if(current == "preferred") {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "preferred", for: indexPath) as! EditProfileTagCell
            cell.setTable(list: uniqueTags, modal: self)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stats", for: indexPath) as! EditProfileStatsCell
            if(!self.statsAvailable){
                cell.cover.alpha = 1
            } else {
                cell.cover.alpha = 0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        
        if(current == "games"){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gameSelection") as! GameSelection
            currentViewController.returning = true
            
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        } else if(current == "stats"){
            if(self.statsAvailable){
                let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
                currentViewController.extra = "stats"
                
                let transitionDelegate = SPStorkTransitioningDelegate()
                currentViewController.transitioningDelegate = transitionDelegate
                currentViewController.modalPresentationStyle = .custom
                currentViewController.modalPresentationCapturesStatusBarAppearance = true
                transitionDelegate.showIndicator = true
                transitionDelegate.swipeToDismissEnabled = true
                transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                transitionDelegate.storkDelegate = self
                self.present(currentViewController, animated: true, completion: nil)
            }
        } else if(current == "quiz"){
            if(self.quizAvailable){
                let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
                currentViewController.extra = "quiz"
                
                let transitionDelegate = SPStorkTransitioningDelegate()
                currentViewController.transitioningDelegate = transitionDelegate
                currentViewController.modalPresentationStyle = .custom
                currentViewController.modalPresentationCapturesStatusBarAppearance = true
                transitionDelegate.showIndicator = true
                transitionDelegate.swipeToDismissEnabled = true
                transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
                transitionDelegate.storkDelegate = self
                self.present(currentViewController, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.payload[indexPath.item]
        
        if (current == "tag") {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
        }
        else if(current == "preferred"){
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(180))
        }
        else{
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        //checkChanges(updatedList: nil)
        
        self.bio = textField.text
    }
    
    func checkChanges(updatedList: [GamerConnectGame]?){
        var changed = false
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        
        if((self.bio != currentUser.bio) || (currentUser.gamerTag != self.selectedTag)){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if(selectedTag.isEmpty){
                manager.saveChanges(bio: ProfanityFilter.sharedInstance.cleanUp(self.bio ?? ""), gamertag: nil, callbacks: self)
            } else {
                manager.saveChanges(bio: ProfanityFilter.sharedInstance.cleanUp(self.bio ?? ""), gamertag: self.selectedTag, callbacks: self)
                appDelegate.currentUser!.gamerTag = self.selectedTag
            }
            appDelegate.currentUser!.bio = ProfanityFilter.sharedInstance.cleanUp(self.bio ?? "")
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentProfileFrag?.dismissModal()
            appDelegate.currentFeedFrag?.checkOnlineAnnouncements()
            self.dismiss(animated: true, completion: nil)
        }
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "User Profile - Profile Updated"))
    }
    
    @objc func cancelButtonClicked(_ sender: AnyObject?) {
        if(!self.cachedUidFromProfile.isEmpty){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentProfileFrag?.dismissModal()
            self.dismiss(animated: true, completion: nil)
            return
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToHome()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if (segue.identifier == "return") {
            if let destination = segue.destination as? PlayerProfile {
                destination.uid = self.cachedUidFromProfile
            }
        }
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
                if(!self.cachedUidFromProfile.isEmpty){
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.currentProfileFrag?.dismissModal()
                    self.dismiss(animated: true, completion: nil)
                    return
                } else {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.currentLanding!.navigateToHome()
                }
            }
        })
    }
}
