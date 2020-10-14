//
//  GameSelection.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import UnderLineTextField
import Lottie
import FirebaseDatabase
import CoreLocation
import GeoFire

class GameSelection: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var gameTable: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    var selectedGames = [String]()
    var originalList = [GamerConnectGame]()
    var gameList = [GamerConnectGame]()
    @IBOutlet weak var gameDrawerDev: UILabel!
    @IBOutlet weak var gameDrawerGame: UILabel!
    @IBOutlet weak var gameDrawerTagEntry: UnderLineTextField!
    @IBOutlet weak var gameDrawerConsoleSpinner: UIPickerView!
    @IBOutlet weak var gameDrawerAdd: UIButton!
    @IBOutlet weak var gameDrawerNo: UIButton!
    @IBOutlet weak var gameDrawer: UIView!
    @IBOutlet weak var gameDrawerBlur: UIVisualEffectView!
    var availableConsoles = [String]()
    @IBOutlet weak var search: UnderLineTextField!
    @IBOutlet weak var buildingBlur: UIVisualEffectView!
    @IBOutlet weak var buildingHeader: UILabel!
    @IBOutlet weak var buildingAnimation: AnimationView!
    var currentSelectedConsole = ""
    var currentSelectedGamerTag = ""
    var currentSelectedGame = ""
    var profiles = [GamerProfile]()
    var consoles = [String]()
    var gameSpinnerSet = false
    var usersCache = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        gameList = delegate.gcGames
        
        gameTable.delegate = self
        gameTable.dataSource = self
        
        search.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == search){
            if(textField.text?.count == 0){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                gameList = delegate.gcGames
            } else {
                gameList = [GamerConnectGame]()
                let delegate = UIApplication.shared.delegate as! AppDelegate
                for game in delegate.gcGames {
                    if(game.gameName.contains(textField.text!)){
                        gameList.append(game)
                    }
                }
            }
            self.gameTable.reloadData()
        } else {
            checkAddButton()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GameSelectionV2Cell
        let current = gameList[indexPath.item]
        cell.developer.text = current.developer
        cell.gamename.text = current.gameName
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: current.imageUrl as NSString) != nil){
            cell.gameback.image = cache.object(forKey: current.imageUrl as NSString)
        } else {
            cell.gameback.image = Utility.Image.placeholder
            cell.gameback.moa.onSuccess = { image in
                cell.gameback.image = image
                appDelegate.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                return image
            }
            cell.gameback.moa.url = current.imageUrl
        }
        
        cell.gameback.contentMode = .scaleAspectFill
        cell.gameback.clipsToBounds = true
        
        if(self.selectedGames.contains(current.gameName)){
            cell.coverblur.alpha = 1
        } else {
            cell.coverblur.alpha = 0
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = gameList[indexPath.item]
        showGameDrawer(gcGame: current)
    }
    
    private func showGameDrawer(gcGame: GamerConnectGame){
        currentSelectedGame = gcGame.gameName
        currentSelectedConsole = ""
        currentSelectedGamerTag = ""
        
        self.gameDrawerDev.text = gcGame.developer
        self.gameDrawerGame.text = gcGame.gameName
        self.availableConsoles = gcGame.availablebConsoles
        
        if(!gameSpinnerSet){
            self.gameSpinnerSet = true
            self.gameDrawerConsoleSpinner.delegate = self
            self.gameDrawerConsoleSpinner.dataSource = self
        } else {
            self.gameDrawerConsoleSpinner.reloadAllComponents()
        }
        
        self.gameDrawerTagEntry.text = ""
        self.gameDrawerTagEntry.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func checkAddButton(){
        if(self.gameDrawerTagEntry.text!.count >= 4 && self.gameDrawerAdd.alpha != 1.0){
            UIView.animate(withDuration: 0.4, animations: {
                self.gameDrawerAdd.alpha = 1
                self.gameDrawerAdd.addTarget(self, action: #selector(self.addGame), for: .touchUpInside)
                self.gameDrawerAdd.isUserInteractionEnabled = true
            }, completion: nil)
        } else if(self.gameDrawerTagEntry.text!.count >= 4){
            self.gameDrawerAdd.alpha = 1
            self.gameDrawerAdd.isUserInteractionEnabled = true
        } else if(self.gameDrawerTagEntry.text!.count < 4 && self.gameDrawerAdd.alpha == 1.0){
            UIView.animate(withDuration: 0.4, animations: {
                self.gameDrawerAdd.alpha = 0.3
                self.gameDrawerAdd.isUserInteractionEnabled = false
            }, completion: nil)
        } else {
            self.gameDrawerAdd.alpha = 0.3
            self.gameDrawerAdd.isUserInteractionEnabled = false
        }
    }
    
    @objc private func addGame(){
        let currentGameProfile = GamerProfile(gamerTag: self.currentSelectedGamerTag, game: self.currentSelectedGame, console: self.currentSelectedConsole)
        var contained = false
        for profile in self.profiles {
            if(profile.game == currentGameProfile.game){
                contained = true
            }
        }
        if(!contained){
            self.profiles.append(currentGameProfile)
        }
        
        self.selectedGames.append(currentGameProfile.game)
        self.gameTable.reloadData()
    }
    
    @objc private func advanceToResults(){
        UIView.animate(withDuration: 0.8, animations: {
            self.buildingBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.buildingHeader.alpha = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.buildingAnimation.play()
                    self.sendPayload()
                }
            }, completion: nil)
        })
    }
    
    private func sendPayload(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("games").setValue(selectedGames)
        
        var sendUp = [[String: String]]()
        for profile in self.profiles {
            self.consoles.append(self.mapConsole(console: profile.console))
            let currentProfile = ["gamerTag": profile.gamerTag, "game": profile.game, "console": self.mapConsole(console: profile.console)]
            sendUp.append(currentProfile)
        }
        ref.child("gamerTags").setValue(sendUp)
        ref.child("ps").setValue(self.consoles.contains("ps"))
        ref.child("xbox").setValue(self.consoles.contains("xbox"))
        ref.child("nintendo").setValue(self.consoles.contains("nintendo"))
        ref.child("pc").setValue(self.consoles.contains("pc"))
        ref.child("mobile").setValue(self.consoles.contains("mobile"))
        
        buildUserCache()
    }
    
    private func buildUserCache(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        if(currentUser.userLat != 0.0){
            let center = CLLocation(latitude: currentUser.userLat, longitude: currentUser.userLong)
            
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
            var ids = [String]()
            let query = geoFire.query(at: center, withRadius: 160.934)//100 miles
            query.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
                ids.append(key)
            })
            query.observeReady {
                query.removeAllObservers()
                self.loadUsers(list: ids)
            }
        }
    }
    
    private func loadUsers(list: [String]?){
        if(list != nil){
            var newList = [String]()
            newList.append(contentsOf: list!)
            newList.shuffle()
            self.loadListUser(uid: list![0], currentList: newList)
        } else {
            self.loadBackupUsersCache()
        }
    }
    
    private func loadListUser(uid: String, currentList: [String]?){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("games") && snapshot.hasChild("gamerTag")){
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                
                let theirGames = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                var contained = false
                for game in theirGames {
                    if(self.selectedGames.contains(game)){
                        contained = true
                        break
                    }
                }
                if(contained){
                    let newUser = User(uId: uid)
                    newUser.games = theirGames
                    let gtag = snapshot.childSnapshot(forPath: "gamerTag").value as? String ?? ""
                    newUser.gamerTag = gtag
                    
                    self.usersCache.append(newUser)
                    currentArray.remove(at: currentList!.index(of: uid)!)
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(currentList!.count > 0){
                        self.loadUsers(list: currentList)
                    } else if(delegate.registerUserCache.count == 3){
                        delegate.registerUserCache = self.usersCache
                        delegate.cachedUserType = "location"
                        self.proceedToResults()
                    } else {
                        self.loadBackupUsersCache()
                    }
                } else {
                    currentArray.remove(at: currentArray.index(of: uid)!)
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(currentArray.count > 0){
                        self.loadUsers(list: currentList)
                    } else if(delegate.registerUserCache.count == 3){
                        delegate.registerUserCache = self.usersCache
                        delegate.cachedUserType = "location"
                        self.proceedToResults()
                    } else {
                        self.loadBackupUsersCache()
                    }
                }
            } else {
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                currentArray.remove(at: currentArray.index(of: uid)!)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                if(currentArray.count > 0){
                    self.loadUsers(list: currentList)
                } else if(delegate.registerUserCache.count == 3){
                    delegate.registerUserCache = self.usersCache
                    delegate.cachedUserType = "location"
                    self.proceedToResults()
                } else {
                    self.loadBackupUsersCache()
                }
            }
        })
    }
    
    private func loadBackupUsersCache(){
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var perfectMatches = [User]()
            var languageMatches = [User]()
            var gamesMatches = [User]()
            var currentCount = 0
            let maxCount = 20
            
            for user in snapshot.children {
                var gameMatch = false
                var languageMatch = false
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser!
                //filter through users for first perfect match, language match or games match
                if((user as! DataSnapshot).hasChild("gamerTag")){
                    if((user as! DataSnapshot).hasChild("games")){
                        let theirGames = (user as! DataSnapshot).childSnapshot(forPath: "games").value as? [String] ?? [String]()
                        for game in self.selectedGames {
                            if(theirGames.contains(game)){
                                gameMatch = true
                                break
                            }
                        }
                        if((user as! DataSnapshot).hasChild("primaryLanguage")){
                            let primary = (user as! DataSnapshot).childSnapshot(forPath: "primaryLanguage").value as? String ?? ""
                            if(currentUser.primaryLanguage == primary){
                                languageMatch = true
                            }
                            if(!languageMatch){
                                if((user as! DataSnapshot).hasChild("secondaryLanguage")){
                                    let secondary = (user as! DataSnapshot).childSnapshot(forPath: "secondaryLanguage").value as? String ?? ""
                                    if(currentUser.secondaryLanguage == secondary){
                                        languageMatch = true
                                    }
                                }
                            }
                        }
                        
                        if(gameMatch && languageMatch){
                            perfectMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        }
                        if(gameMatch){
                            gamesMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        }
                        if(languageMatch){
                            languageMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        }
                        
                        if(perfectMatches.count == 3){
                            delegate.registerUserCache.append(contentsOf: perfectMatches)
                            delegate.cachedUserType = "perfect"
                            self.proceedToResults()
                            return
                        }
                        if(gamesMatches.count == 3){
                            delegate.registerUserCache.append(contentsOf: gamesMatches)
                            delegate.cachedUserType = "games"
                            self.proceedToResults()
                            return
                        }
                        if(languageMatches.count == 3){
                            delegate.registerUserCache.append(contentsOf: languageMatches)
                            delegate.cachedUserType = "language"
                            self.proceedToResults()
                            return
                        }
                        
                        currentCount += 1
                        if(currentCount == maxCount){
                            delegate.cachedUserType = "default"
                            self.proceedToResults()
                            return
                        }
                    } else {
                        currentCount += 1
                        if(currentCount == maxCount){
                            delegate.cachedUserType = "default"
                            self.proceedToResults()
                            return
                        }
                    }
                }
                else {
                    currentCount += 1
                    if(currentCount == maxCount){
                        delegate.cachedUserType = "default"
                        self.proceedToResults()
                        return
                    }
                }
            }
        })
    }
    
    private func quickCreateUser(snapshot: DataSnapshot) -> User{
        let user = User(uId: snapshot.key)
        if(snapshot.hasChild("gamerTag")){
            let gamerTag = snapshot.childSnapshot(forPath: "gamerTag").value as? String ?? ""
            user.gamerTag = gamerTag
        }
        return user
    }
    
    private func proceedToResults(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.performSegue(withIdentifier: "results", sender: nil)
        }
    }
    
    private func mapConsole(console: String) -> String {
        if(console == "PlayStation"){
            return "ps"
        } else if(console == "xBox"){
            return "xbox"
        } else if(console == "Nintendo"){
            return "nintendo"
        } else if(console == "PC"){
            return "pc"
        } else {
            return "mobile"
        }
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
        let current = availableConsoles[row]
        self.currentSelectedConsole = current
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: self.availableConsoles[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}
