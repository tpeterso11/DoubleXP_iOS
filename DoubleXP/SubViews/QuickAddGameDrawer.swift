//
//  QuickAddGameDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/21/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import UnderLineTextField
import FirebaseDatabase
import Lottie
import SPStorkController

class QuickAddGameDrawer: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    var gameName = ""
    var game: GamerConnectGame? = nil
    var availableConsoles = [String]()
    var mappedConsoles = [String]()
    var currentSelectedConsole = ""
    var currentGamerTag = ""
    var selectedConsoles = [String]()
    var newProfiles = [GamerProfile]()
    var currentGameSelectionModal: GameSelection?
    
    @IBOutlet weak var successTag: UILabel!
    @IBOutlet weak var gameAddedTag: UILabel!
    @IBOutlet weak var gameBack: UIImageView!
    
    @IBOutlet weak var workAnimation: LottieAnimationView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var doneAnimation: LottieAnimationView!
    @IBOutlet weak var workBlur: UIVisualEffectView!
    @IBOutlet weak var success: UIView!
    @IBOutlet weak var gamerTagField: UnderLineTextField!
    @IBOutlet weak var gamertagTag: UILabel!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var consoleView: UIView!
    @IBOutlet weak var consoleCollection: UICollectionView!
    @IBOutlet weak var progressButton: UIButton!
    @IBOutlet weak var gameNameField: UILabel!
    var page = 0
    
    var consoleRequired = false
    override func viewDidLoad() {
        super.viewDidLoad()

        let delegate = UIApplication.shared.delegate as! AppDelegate
        for game in delegate.gcGames {
            if(game.gameName == gameName){
                self.game = game
                self.consoleRequired = game.availablebConsoles.count > 1
            }
        }
        if(game == nil){
            dismiss(animated: true, completion: nil)
        }
        
        setUI()
    }
    
    private func setUI(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.gameNameField.text = game!.gameName
        //self.gameNameField.text = ""
        
        setupGameBack()
        
        if(consoleRequired == true){
            self.availableConsoles = [String]()
            self.availableConsoles.append(contentsOf: getMappedConsoles())
            
            self.consoleCollection.delegate = self
            self.consoleCollection.dataSource = self
            
            let nextTap = UITapGestureRecognizer(target: self, action: #selector(self.transitionToTag))
            self.progressButton.isUserInteractionEnabled = true
            self.progressButton.addGestureRecognizer(nextTap)
            
            self.page = 1
            
            self.currentGamerTag = delegate.currentUser!.gamerTag
            self.gamerTagField.delegate = self
            self.gamerTagField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            
            self.checkButton()
        } else {
            self.consoleView.alpha = 0
            self.selectedConsoles.append(self.game!.availablebConsoles[0])
            self.progressButton.setTitle("add game", for: .normal)
            
            self.currentSelectedConsole = self.selectedConsoles[0]
            self.gamertagTag.text = "my gamertag on " + self.mapStringToConsole(selected: self.selectedConsoles[0]) + " is..."
        
            self.checkButton()
            
            self.page = 2
            self.gamerTagField.text = delegate.currentUser!.gamerTag
            self.currentGamerTag = delegate.currentUser!.gamerTag
            
            self.tagView.alpha = 1
        }
    }
    
    private func setupGameBack(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: self.game!.imageUrl as NSString) != nil){
            self.gameBack.image = cache.object(forKey: self.game!.imageUrl as NSString)
        } else {
            self.gameBack.image = Utility.Image.placeholder
            self.gameBack.moa.onSuccess = { image in
                self.gameBack.image = image
                appDelegate.imageCache.setObject(image, forKey: self.game!.imageUrl as NSString)
                return image
            }
            self.gameBack.moa.url = self.game!.imageUrl
        }
        
        self.gameBack.contentMode = .scaleAspectFill
        self.gameBack.clipsToBounds = true
        
        let testBounds = CGRect(x: self.gameBack.bounds.minX, y: self.gameBack.bounds.minY, width: self.view.bounds.width, height: self.gameBack.bounds.height)
        //hero.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: hero.layer.cornerRadius).cgPath
        
        let maskLayer = CAGradientLayer(layer: self.gameBack.layer)
        maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.frame = testBounds
        self.gameBack.layer.mask = maskLayer
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        checkButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        
        if(textField.text!.count > 3){
            self.addGamerTag()
        }
        return true
    }
    
    @objc private func transitionToTag(){
        let top = CGAffineTransform(translationX: 50, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.consoleView.alpha = 0
            self.consoleView.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.page = 2
                if(self.selectedConsoles.count > 1){
                    self.progressButton.setTitle("add gamertag", for: .normal)
                } else {
                    self.progressButton.setTitle("add game", for: .normal)
                }
                self.currentSelectedConsole = self.selectedConsoles[0]
                self.gamertagTag.text = "my gamertag on " + self.mapStringToConsole(selected: self.selectedConsoles[0]) + " is..."
                
                if(!self.currentGamerTag.isEmpty){
                    self.gamerTagField.text = self.currentGamerTag
                }
                
                self.checkButton()
                
                self.hideKeyboardWhenTappedAround()
                self.tagView.alpha = 1
            }, completion: nil)
        })
    }
    
    private func checkButton(){
        if(page == 2){
            if(self.gamerTagField.text?.count ?? 0 > 3){
                self.progressButton.alpha = 1
                
                let addTap = UITapGestureRecognizer(target: self, action: #selector(self.addGamerTag))
                self.progressButton.isUserInteractionEnabled = true
                self.progressButton.addGestureRecognizer(addTap)
            } else {
                self.progressButton.alpha = 0.3
                self.progressButton.isUserInteractionEnabled = false
            }
        } else {
            if(selectedConsoles.count > 0){
                self.progressButton.alpha = 1
                
                let addTap = UITapGestureRecognizer(target: self, action: #selector(self.transitionToTag))
                self.progressButton.isUserInteractionEnabled = true
                self.progressButton.addGestureRecognizer(addTap)
            } else {
                self.progressButton.alpha = 0.3
                self.progressButton.isUserInteractionEnabled = false
            }
        }
    }
    
    @objc private func addGamerTag(){
        self.currentGamerTag = self.gamerTagField.text!
        self.dismissKeyboard()
        let gamerProfile = GamerProfile(gamerTag: self.currentGamerTag, game: game!.gameName, console: self.currentSelectedConsole, quizTaken: "false")
        newProfiles.append(gamerProfile)
        
        if(self.selectedConsoles.contains(self.currentSelectedConsole)){
            self.selectedConsoles.remove(at: self.selectedConsoles.index(of: self.currentSelectedConsole)!)
        }
        if(self.selectedConsoles.isEmpty){
            addGameAndFinish()
        } else {
            transitionToNewTag()
        }
    }
    
    private func transitionToNewTag(){
        UIView.animate(withDuration: 0.8, animations: {
            self.tagView.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                if(self.selectedConsoles.count > 1){
                    self.progressButton.setTitle("add gamertag", for: .normal)
                } else {
                    self.progressButton.setTitle("add game", for: .normal)
                }
                self.currentSelectedConsole = self.selectedConsoles[0]
                self.gamertagTag.text = "my gamertag on " + self.mapStringToConsole(selected: self.selectedConsoles[0]) + " is..."
            
                self.checkButton()
                
                if(!self.currentGamerTag.isEmpty){
                    self.gamerTagField.text = self.currentGamerTag
                }
                
                self.tagView.alpha = 1
            }, completion: nil)
        })
    }
    
    private func addGameAndFinish(){
        self.dismissKeyboard()
        UIView.animate(withDuration: 0.8, animations: {
            self.workBlur.alpha = 1
            self.workAnimation.loopMode = .loop
            self.workAnimation.play()
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                var gamerTags = [GamerProfile]()
                var consoles = [String]()
                if(snapshot.hasChild("gamerTags")){
                    let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        
                        if(currentTag != "" && currentGame != "" && console != ""){
                            consoles.append(console)
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                    }
                }
                gamerTags.append(contentsOf: self.newProfiles)
                for profile in self.newProfiles {
                    if(delegate.currentUser!.gamerTag.isEmpty){
                        delegate.currentUser!.gamerTag = profile.gamerTag
                        ref.child("gamerTag").setValue(profile.gamerTag)
                    }
                    consoles.append(profile.console)
                }
                delegate.currentUser!.gamerTags = gamerTags
                
                if(snapshot.hasChild("consoles")){
                    let consoleArray = snapshot.childSnapshot(forPath: "consoles")
                    let dict = consoleArray.value as? [String: Bool]
                    var nintendo = dict?["nintendo"] ?? false
                    var ps = dict?["ps"] ?? false
                    var xbox = dict?["xbox"] ?? false
                    var pc = dict?["pc"] ?? false
                    var mobile = dict?["mobile"] ?? false
                    var tabletop = dict?["tabletop"] ?? false
                    
                    if(!nintendo && consoles.contains("nintendo")){
                        nintendo = true
                    }
                    if(!pc && consoles.contains("pc")){
                        pc = true
                    }
                    if(!tabletop && consoles.contains("tabletop")){
                        tabletop = true
                    }
                    if(!mobile && consoles.contains("mobile")){
                        mobile = true
                    }
                    if(!ps && consoles.contains("ps")){
                        ps = true
                    }
                    if(!xbox && consoles.contains("xbox")){
                        xbox = true
                    }
                    
                    ref.child("consoles").child("ps").setValue(ps)
                    ref.child("consoles").child("pc").setValue(pc)
                    ref.child("consoles").child("xbox").setValue(xbox)
                    ref.child("consoles").child("tabletop").setValue(tabletop)
                    ref.child("consoles").child("mobile").setValue(mobile)
                    ref.child("consoles").child("nintendo").setValue(nintendo)
                }
                
                var sendUp = [[String: String]]()
                for profile in gamerTags {
                    let newProfile = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console, "quizTaken": profile.quizTaken]
                    sendUp.append(newProfile)
                }
                ref.child("gamerTags").setValue(sendUp)
                
                if(snapshot.hasChild("games")){
                    var games = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                    if(!games.contains(self.game!.gameName)){
                        games.append(self.game!.gameName)
                        ref.child("games").setValue(games)
                        
                        delegate.currentUser!.games = games
                    }
                } else {
                    ref.child("games").setValue([self.game!.gameName])
                    delegate.currentUser!.games = [self.game!.gameName]
                }
                
                self.showSuccess()
            })
        })
    }
    
    func showSuccess(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentGameSelection != nil){
            self.searchButton.alpha = 0
            self.successTag.text = "tap dismiss and add some more games!"
        }
        UIView.animate(withDuration: 0.8, animations: {
            self.workAnimation.pause()
            self.workAnimation.alpha = 0
            self.success.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                self.doneAnimation.loopMode = .playOnce
                self.doneAnimation.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                        self.gameAddedTag.alpha = 1
                    }, completion: nil)
                }
                self.dismissButton.addTarget(self, action: #selector(self.dismissClicked), for: .touchUpInside)
                self.searchButton.addTarget(self, action: #selector(self.search), for: .touchUpInside)
            }, completion: nil)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat((collectionView.bounds.width / 2) - 10), height: CGFloat(65))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.availableConsoles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "console", for: indexPath) as! ConsoleSelectionCellV2
        let current = self.availableConsoles[indexPath.item]
        
        cell.consoleLabel.text = current
        cell.selectedLabel.text = current
        
        if(self.selectedConsoles.contains(self.mapConsoleString(selected: current))){
            cell.selectedCover.alpha = 1
        } else {
            cell.selectedCover.alpha = 0
        }
        
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.8
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    @objc private func search(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToSearch(game: self.game!)
    }
    
    @objc private func dismissClicked(){
        self.dismiss(animated: true, completion: {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentFeedSearchModal?.onModalDismissed()
            delegate.currentDiscoverGamePage?.modalDismissed()
            delegate.currentFeedFrag?.modalDismissed()
            self.currentGameSelectionModal?.onModalReturn()
        })
    }
    
    private func mapConsoleString(selected: String) -> String {
        if(selected == "PlayStation"){
            return "ps"
        }
        if(selected == "xBox"){
            return "xbox"
        }
        if(selected == "PC"){
            return "pc"
        }
        if(selected == "Mobile"){
            return "mobile"
        }
        if(selected == "Switch"){
            return "nintendo"
        }
        return "tabletop"
    }
    
    private func mapStringToConsole(selected: String) -> String {
        if(selected == "ps"){
            return "PlayStation"
        }
        if(selected == "xbox"){
            return "xBox"
        }
        if(selected == "pc"){
            return "PC"
        }
        if(selected == "mobile"){
            return "Mobile"
        }
        if(selected == "nintendo"){
            return "Switch"
        }
        return "Tabletop"
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.availableConsoles[indexPath.item]
        let selected = mapConsoleString(selected: current)
        if(self.selectedConsoles.contains(selected)){
            self.selectedConsoles.remove(at: self.selectedConsoles.index(of: selected)!)
            self.consoleCollection.reloadData()
        } else {
            self.selectedConsoles.append(selected)
            self.consoleCollection.reloadData()
        }
        
        checkButton()
    }
    
    private func getMappedConsoles() -> [String]{
        var mapped = [String]()
        for console in game!.availablebConsoles {
            if(console == "ps"){
                mapped.append("PlayStation")
            }
            if(console == "xbox"){
                mapped.append("xBox")
            }
            if(console == "pc"){
                mapped.append("PC")
            }
            if(console == "tabletop"){
                mapped.append("Tabletop")
            }
            if(console == "nintendo"){
                mapped.append("Switch")
            }
            if(console == "mobile"){
                mapped.append("Mobile")
            }
        }
        return mapped
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.availableConsoles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.availableConsoles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let current = self.availableConsoles[row]
        self.currentSelectedConsole = current
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(70)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: self.availableConsoles[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
