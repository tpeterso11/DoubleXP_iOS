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
import SwiftNotificationCenter
import FBSDKLoginKit
import SPStorkController

class GameSelection: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, SPStorkControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var continueButton: UIButton!
    var selectedGames = [String]()
    var originalList = [GamerConnectGame]()
    var gameList = [GamerConnectGame]()
    @IBOutlet weak var gameDrawerDev: UILabel!
    @IBOutlet weak var gameDrawerGame: UILabel!
    @IBOutlet weak var gameDrawerTagEntry: UnderLineTextField!
    @IBOutlet weak var gameDrawerAdd: UIButton!
    @IBOutlet weak var gameDrawerNo: UIButton!
    @IBOutlet weak var gameDrawer: UIView!
    @IBOutlet weak var gameDrawerBlur: UIVisualEffectView!
    var availableConsoles = [String]()
    @IBOutlet weak var search: UnderLineTextField!
    @IBOutlet weak var buildingBlur: UIVisualEffectView!
    @IBOutlet weak var buildingHeader: UILabel!
    @IBOutlet weak var buildingAnimation: LottieAnimationView!
    @IBOutlet weak var consoleTable: UITableView!
    @IBOutlet weak var gamerTagCover: UIView!
    @IBOutlet weak var consoleTag: UILabel!
    @IBOutlet weak var gamertagTag: UILabel!
    @IBOutlet weak var keyboardNext: UIButton!
    @IBOutlet weak var updateBlur: UIVisualEffectView!
    @IBOutlet weak var updateAnimation: LottieAnimationView!
    @IBOutlet weak var allGamesButton: UIView!
    @IBOutlet weak var allGamesCover: UIView!
    @IBOutlet weak var popularButton: UIView!
    @IBOutlet weak var consoleButton: UIView!
    @IBOutlet weak var consoleCover: UIView!
    @IBOutlet weak var popularCover: UIView!
    @IBOutlet weak var pcGamesButton: UIView!
    @IBOutlet weak var pcCover: UIView!
    @IBOutlet weak var mobileButton: UIView!
    @IBOutlet weak var mobileCover: UIView!
    @IBOutlet weak var tableButton: UIView!
    @IBOutlet weak var tableCover: UIView!
    @IBOutlet weak var gameCollection: UICollectionView!
    @IBOutlet weak var gameSelectionHeader: UILabel!
    @IBOutlet weak var gameSelectionSub: UILabel!
    var currentSelectedConsoles = [String]()
    var currentSelectedGamerTags = [String]()
    var currentSelectedGame = ""
    var currentSelectedConsole = ""
    var currentSelectedGT = ""
    var profiles = [GamerProfile]()
    var currentGameProfiles = [GamerProfile]()
    var consoles = [String]()
    var consolesSet = false
    var usersCache = [User]()
    var mappedConsoles = [String]()
    var gtDeckHeight: CGFloat?
    var constraint : NSLayoutConstraint?
    var keyboardOpen = false
    var returning = false
    var modalPopped = false
    var upgradeFrag: Upgrade?
    var currentGameGroup = "all"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentGameSelection = self
        let list = delegate.gcGames
        let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
        gameList = sorted
        
        if(returning){
            self.gameSelectionHeader.text = "what games do you play?"
            self.gameSelectionSub.text = "add your favortite games to your profile, increase your chances"
            continueButton.addTarget(self, action: #selector(self.closeModal), for: .touchUpInside)
            self.selectedGames.append(contentsOf: delegate.currentUser!.games)
            self.profiles.append(contentsOf: delegate.currentUser!.gamerTags)
        } else {
            self.gameSelectionHeader.text = "add your first game"
            self.gameSelectionSub.text = "add your favorite game to complete your profile."
            self.continueButton.setTitle("skip for now", for: .normal)
            continueButton.addTarget(self, action: #selector(self.advanceToResults), for: .touchUpInside)
        }
        
        let allTap = UITapGestureRecognizer(target: self, action: #selector(self.allClicked))
        self.allGamesButton.isUserInteractionEnabled = true
        self.allGamesButton.addGestureRecognizer(allTap)
        
        let popularTap = UITapGestureRecognizer(target: self, action: #selector(self.popularClicked))
        self.popularButton.isUserInteractionEnabled = true
        self.popularButton.addGestureRecognizer(popularTap)
        
        let consoleTap = UITapGestureRecognizer(target: self, action: #selector(self.consoleClicked))
        self.consoleButton.isUserInteractionEnabled = true
        self.consoleButton.addGestureRecognizer(consoleTap)
        
        let pcTap = UITapGestureRecognizer(target: self, action: #selector(self.pcClicked))
        self.pcGamesButton.isUserInteractionEnabled = true
        self.pcGamesButton.addGestureRecognizer(pcTap)
        
        let tableTap = UITapGestureRecognizer(target: self, action: #selector(self.tabletopClicked))
        self.tableButton.isUserInteractionEnabled = true
        self.tableButton.addGestureRecognizer(tableTap)
        
        let mobileTap = UITapGestureRecognizer(target: self, action: #selector(self.mobileClicked))
        self.mobileButton.isUserInteractionEnabled = true
        self.mobileButton.addGestureRecognizer(mobileTap)
        
        gameCollection.delegate = self
        gameCollection.dataSource = self
        
        search.delegate = self
        search.returnKeyType = UIReturnKeyType.done
        
        search.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func allClicked(){
        self.currentGameGroup = "all"
        handleButtons(selected: self.currentGameGroup)
    }
    @objc func pcClicked(){
        self.currentGameGroup = "pc"
        handleButtons(selected: "pc")
    }
    @objc func mobileClicked(){
        self.currentGameGroup = "mobile"
        handleButtons(selected: "mobile")
    }
    @objc func consoleClicked(){
        self.currentGameGroup = "console"
        handleButtons(selected: "console")
    }
    @objc func popularClicked(){
        self.currentGameGroup = "popular"
        handleButtons(selected: "popular")
    }
    @objc func tabletopClicked(){
        self.currentGameGroup = "tabletop"
        handleButtons(selected: "tabletop")
    }
    
    private func handleButtons(selected: String){
        if(selected == "all"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 1
            self.popularCover.alpha = 0
            self.pcCover.alpha = 0
            self.tableCover.alpha = 0
            self.mobileCover.alpha = 0
            self.consoleCover.alpha = 0
        } else if(selected == "pc"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            for game in gameList {
                if(!game.availablebConsoles.contains("pc")){
                    gameList.remove(at: gameList.index(of: game)!)
                }
            }
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 0
            self.popularCover.alpha = 0
            self.pcCover.alpha = 1
            self.tableCover.alpha = 0
            self.mobileCover.alpha = 0
            self.consoleCover.alpha = 0
        } else if(selected == "mobile"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            for game in gameList {
                if(game.mobileGame != "true"){
                    gameList.remove(at: gameList.index(of: game)!)
                }
            }
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 0
            self.popularCover.alpha = 0
            self.pcCover.alpha = 0
            self.tableCover.alpha = 0
            self.mobileCover.alpha = 1
            self.consoleCover.alpha = 0
        } else if(selected == "console"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            for game in gameList {
                if(!game.availablebConsoles.contains("ps") && !game.availablebConsoles.contains("xbox")
                && !game.availablebConsoles.contains("nintendo")){
                    gameList.remove(at: gameList.index(of: game)!)
                }
            }
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 0
            self.popularCover.alpha = 0
            self.pcCover.alpha = 0
            self.tableCover.alpha = 0
            self.mobileCover.alpha = 0
            self.consoleCover.alpha = 1
        } else if(selected == "tabletop"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            for game in gameList {
                if(!game.availablebConsoles.contains("tabletop")){
                    gameList.remove(at: gameList.index(of: game)!)
                }
            }
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 0
            self.popularCover.alpha = 0
            self.pcCover.alpha = 0
            self.tableCover.alpha = 1
            self.mobileCover.alpha = 0
            self.consoleCover.alpha = 0
        } else if(selected == "popular"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let list = delegate.gcGames
            let sorted = list!.sorted(by: { $0.gameName < $1.gameName })
            gameList = sorted
            
            for game in gameList {
                if(!game.categoryFilters.contains("popular")){
                    gameList.remove(at: gameList.index(of: game)!)
                }
            }
            self.gameCollection.reloadData()
            
            self.allGamesCover.alpha = 0
            self.popularCover.alpha = 1
            self.pcCover.alpha = 0
            self.tableCover.alpha = 0
            self.mobileCover.alpha = 0
            self.consoleCover.alpha = 0
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { // became first responder

        //move textfields up
        let myScreenRect: CGRect = UIScreen.main.bounds
        let keyboardHeight : CGFloat = 500

        UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
        var needToMove: CGFloat = 0

        var frame : CGRect = self.view.frame
        if (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height + */UIApplication.shared.statusBarFrame.size.height > (myScreenRect.size.height - keyboardHeight)) {
            needToMove = (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height +*/ UIApplication.shared.statusBarFrame.size.height) - (myScreenRect.size.height - keyboardHeight);
        }

        frame.origin.y = -needToMove
        self.view.frame = frame
        UIView.commitAnimations()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
            //move textfields back down
            UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
            var frame : CGRect = self.view.frame
            frame.origin.y = 0
            self.view.frame = frame
            UIView.commitAnimations()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        gameList = delegate.gcGames
        return true
    }
    
    @objc override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
                    if(game.gameName.localizedCaseInsensitiveContains(textField.text!)){
                        gameList.append(game)
                    }
                }
            }
            self.gameCollection.reloadData()
        }
    }
    
    /*func didDismissStorkBySwipe() {
        if(returning){
            DispatchQueue.main.async {
                self.gameCollection.reloadData()
                self.gameCollection.performBatchUpdates({ [weak self] in
                        let visibleItems = self?.gameCollection.indexPathsForVisibleItems ?? []
                        self?.gameCollection.reloadItems(at: visibleItems)
                    }, completion: { (_) in
                })
                self.gameCollection.collectionViewLayout.invalidateLayout()
                self.gameCollection.layoutSubviews()
            }
        } else {
            DispatchQueue.main.async {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(!appDelegate.currentUser!.games.isEmpty){
                    self.advanceToResults()
                }
            }
        }
    }*/

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableConsoles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "console", for: indexPath) as! ConsoleSelectionTableviewCell
        let current = self.availableConsoles[indexPath.item]
        
        cell.console.text = self.mapConsoleForDisplay(console: current)
        cell.coverConsole.text = self.mapConsoleForDisplay(console: current)
        
        if(self.currentSelectedConsoles.contains(current)){
            cell.selectedCover.alpha = 1
        } else {
            cell.selectedCover.alpha = 0
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = self.availableConsoles[indexPath.item]
        if(self.currentSelectedConsoles.contains(current)){
            self.currentSelectedConsoles.remove(at: self.currentSelectedConsoles.index(of: current)!)
        } else {
            self.currentSelectedConsoles.append(current)
        }
        self.consoleTable.reloadData()
        //self.checkNextButton()
    }
    
    private func showGameDrawer(gcGame: GamerConnectGame){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "quickAddGame") as! QuickAddGameDrawer
        currentViewController.gameName = gcGame.gameName
        currentViewController.currentGameSelectionModal = self
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 650
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
        //self.currentSelectedGame = gcGame.gameName
        //self.performSegue(withIdentifier: "addGame", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGame" {
            if let nextViewController = segue.destination as? QuickAddGameDrawer {
                nextViewController.gameName = self.currentSelectedGame
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showGameDrawer(gcGame: self.gameList[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GameSelectionV2Cell
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
        
        if(appDelegate.currentUser!.games.contains(current.gameName)){
            cell.testCheck.alpha = 1
        } else {
            cell.testCheck.alpha = 0
        }
        cell.selectedCover.alpha = 0
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: CGFloat(120))
    }
    
    func onModalReturn(){
        if(returning){
            DispatchQueue.main.async {
                self.gameCollection.reloadData()
                self.gameCollection.performBatchUpdates({ [weak self] in
                        let visibleItems = self?.gameCollection.indexPathsForVisibleItems ?? []
                        self?.gameCollection.reloadItems(at: visibleItems)
                    }, completion: { (_) in
                })
                self.gameCollection.collectionViewLayout.invalidateLayout()
                self.gameCollection.layoutSubviews()
            }
        } else {
            DispatchQueue.main.async {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if(!appDelegate.currentUser!.games.isEmpty){
                    self.advanceToResults()
                }
            }
        }
    }
    
    @objc private func advanceToResults(){
        UIView.animate(withDuration: 0.8, animations: {
            self.buildingBlur.alpha = 1
            self.buildingAnimation.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.buildingHeader.alpha = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.buildingAnimation.loopMode = .loop
                    self.buildingAnimation.play()
                    self.sendPayload()
                }
            }, completion: nil)
        })
    }
    
    @objc private func closeModal(){
        UIView.animate(withDuration: 0.8, animations: {
            self.updateBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.updateAnimation.alpha = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.updateAnimation.loopMode = .loop
                    self.updateAnimation.play()
                    self.updatePayload()
                }
            }, completion: nil)
        })
    }
    
    private func updatePayload(){
        if(self.modalPopped){
            self.upgradeFrag?.dismissModal()
            self.dismiss(animated: true) {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.currentFeedFrag?.checkOnlineAnnouncements()
                delegate.currentFeedSearchModal?.onModalDismissed()
            }
        } else {
            self.proceedToLanding()
        }
    }
    
    private func sendPayload(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.socialMediaManager
        manager.getTwitchAppToken(token: nil, uid: delegate.currentUser!.uId)
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Register - GC"))
        
        if(!self.returning && !delegate.currentUser!.gamerTag.isEmpty){
            self.proceedToResults()
        } else {
            if(self.modalPopped){
                upgradeFrag?.dismissModal()
                self.dismiss(animated: true) {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentFeedFrag?.checkOnlineAnnouncements()
                }
            } else {
                self.proceedToLanding()
            }
        }
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
        } else {
            self.loadBackupUsersCache()
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
            if(snapshot.hasChild("games") && snapshot.hasChild("gamerTag") && snapshot.hasChild("gamerTags")){
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                
                var gamerTags = [GamerProfile]()
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                for gamerTagObj in gamerTagsArray.children {
                    let currentObj = gamerTagObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let currentTag = dict?["gamerTag"] as? String ?? ""
                    let currentGame = dict?["game"] as? String ?? ""
                    let console = dict?["console"] as? String ?? ""
                    let quizTaken = dict?["quizTaken"] as? String ?? ""
                    
                    if(currentTag != "" && currentGame != "" && console != ""){
                        let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                        gamerTags.append(currentGamerTagObj)
                    }
                }
                
                var containedProfile = false
                var gamerTag = ""
                for tag in gamerTags {
                    if(!tag.gamerTag.isEmpty){
                        if(self.selectedGames.contains(tag.game)){
                            if(self.currentSelectedConsoles.contains(tag.console)){
                                containedProfile = true
                                gamerTag = tag.gamerTag
                                break
                            }
                        }
                    }
                }
                
                let theirGames = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                
                if(containedProfile){
                    let newUser = User(uId: uid)
                    newUser.games = theirGames
                    newUser.gamerTag = gamerTag
                    
                    self.usersCache.append(newUser)
                    currentArray.remove(at: currentArray.index(of: uid)!)
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(currentArray.count > 0){
                        self.loadUsers(list: currentArray)
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
                        self.loadUsers(list: currentArray)
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
                    self.loadUsers(list: currentArray)
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
            let maxCount = 100
            
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
                        let tag = (user as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? ""
                        if(gameMatch && languageMatch && !tag.isEmpty){
                            perfectMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        }
                        if(gameMatch && !tag.isEmpty){
                            gamesMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        }
                        if(languageMatch && !tag.isEmpty){
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
    
    private func proceedToLanding(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.performSegue(withIdentifier: "home", sender: nil)
        }
    }
    
    private func proceedToResults(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.performSegue(withIdentifier: "results", sender: nil)
        }
    }
    
    private func mapConsolesForDisplay(currentConsoles: [String]) -> [String]{
        var consoles = [String]()
        if(currentConsoles.contains("select a console")){
            consoles.append("select a console")
        }
        if(currentConsoles.contains("ps")){
            consoles.append("playstation")
        }
        if(currentConsoles.contains("xbox")){
            consoles.append("xbox")
        }
        if(currentConsoles.contains("nintendo")){
            consoles.append("nintendo")
        }
        if(currentConsoles.contains("pc")){
            consoles.append("pc")
        }
        if(currentConsoles.contains("mobile")){
            consoles.append("mobile")
        }
        if(currentConsoles.contains("tabletop")){
            consoles.append("tabletop")
        }
        return consoles
    }
    
    private func mapConsoleForDisplay(console: String) -> String {
        if(console == "ps"){
            return "playstation"
        } else if(console == "xbox"){
            return "xbox"
        } else if(console == "nintendo"){
            return "nintendo"
        } else if(console == "pc"){
            return "pc"
        } else if(console == "tabletop"){
            return "tabletop"
        } else {
            return "mobile"
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.mappedConsoles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.mappedConsoles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let current = self.availableConsoles[row]
        self.currentSelectedConsole = current
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: self.mappedConsoles[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}
