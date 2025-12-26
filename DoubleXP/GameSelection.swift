//
//  GameSelection.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import Firebase
import CoreLocation
import GeoFire
import Kingfisher
import SwiftEntryKit
import AlertKit


class GameSelection: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var continueButton: UIButton!
    var selectedGames = [String]()
    var originalList = [GamerConnectGame]()
    var gameList = [GamerConnectGame]()
    @IBOutlet weak var gameDrawerDev: UILabel!
    @IBOutlet weak var gameDrawerGame: UILabel!
    @IBOutlet weak var gameDrawerAdd: UIButton!
    @IBOutlet weak var gameDrawerNo: UIButton!
    @IBOutlet weak var gameDrawer: UIView!
    @IBOutlet weak var gameDrawerBlur: UIVisualEffectView!
    var availableConsoles = [String]()
    @IBOutlet weak var buildingBlur: UIVisualEffectView!
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
    @IBOutlet weak var casualButton: UIView!
    @IBOutlet weak var casualCover: UIView!
    @IBOutlet weak var shooterButton: UIView!
    @IBOutlet weak var shooterCover: UIView!
    @IBOutlet weak var sportsButton: UIView!
    @IBOutlet weak var sportsCover: UIView!
    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var actionCover: UIView!
    @IBOutlet weak var multiButton: UIView!
    @IBOutlet weak var multiCover: UIView!
    
    @IBOutlet weak var gameCollection: UICollectionView!
    @IBOutlet weak var gameSelectionHeader: UILabel!
    @IBOutlet weak var gameSelectionSub: UILabel!
    @IBOutlet weak var categoryBlur: UIVisualEffectView!
    @IBOutlet weak var pokoCollection: UICollectionView!
    @IBOutlet weak var pokoLayout: UIView!
    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var pokoTitle: UILabel!
    @IBOutlet weak var pokoSub: UILabel!
    @IBOutlet weak var searchButton: UIView!
    @IBOutlet weak var searchImage: UIImageView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var pokoTooltip: UIImageView!
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
    var selectedGameProfile: GamerProfile?
    private var pokoOverride = false
    private var pokoList = [Poko]()
    private var activeBorderLayer: CAShapeLayer?
    private var selectedPokoId: String?
    var newProfiles = [GamerProfile]()
    var searchActive = false
    private var gameApiService = GameAPIService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categoryBlur.alpha = 0
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentGameSelection = self
        let list = gameApiService.allRegistrationGames
        let sorted = list.sorted(by: { $0.gameName < $1.gameName })
        gameList = sorted
        Task {
            pokoList = await PokoProvider.shared.getPokos()
        }
        
        if(returning){
            self.gameSelectionHeader.text = "what games do you play?"
            self.gameSelectionSub.text = "add your favortite games to your profile, increase your chances"
            continueButton.addTarget(self, action: #selector(self.closeModal), for: .touchUpInside)
            self.selectedGames.append(contentsOf: delegate.currentUser!.games)
            self.profiles.append(contentsOf: delegate.currentUser!.gamerTags)
        } else {
            self.gameSelectionHeader.text = "add your first game"
            self.gameSelectionSub.text = "add your favorite game to complete your profile."
            continueButton.addTarget(self, action: #selector(self.showPokoLayout), for: .touchUpInside)
        }
        
        let allTap = UITapGestureRecognizer(target: self, action: #selector(self.allClicked))
        self.allGamesButton.isUserInteractionEnabled = true
        self.allGamesButton.addGestureRecognizer(allTap)
        
        let actionTap = UITapGestureRecognizer(target: self, action: #selector(self.actionClicked))
        self.actionButton.isUserInteractionEnabled = true
        self.actionButton.addGestureRecognizer(actionTap)
        
        let sportsTap = UITapGestureRecognizer(target: self, action: #selector(self.sportsClicked))
        self.sportsButton.isUserInteractionEnabled = true
        self.sportsButton.addGestureRecognizer(sportsTap)
        
        let shooterTap = UITapGestureRecognizer(target: self, action: #selector(self.shooterClicked))
        self.shooterButton.isUserInteractionEnabled = true
        self.shooterButton.addGestureRecognizer(shooterTap)
        
        let casualTap = UITapGestureRecognizer(target: self, action: #selector(self.casualClicked))
        self.casualButton.isUserInteractionEnabled = true
        self.casualButton.addGestureRecognizer(casualTap)
        
        let multiTap = UITapGestureRecognizer(target: self, action: #selector(self.multiClicked))
        self.multiButton.isUserInteractionEnabled = true
        self.multiButton.addGestureRecognizer(multiTap)
        
        let toolTipTap = UITapGestureRecognizer(target: self, action: #selector(self.showPokoTooltip))
        self.pokoTooltip.isUserInteractionEnabled = true
        self.pokoTooltip.addGestureRecognizer(toolTipTap)
        
        /*let layout = AnimatedCollectionViewLayout()
         layout.animator = LinearCardAttributesAnimator()
         layout.scrollDirection = .horizontal*/
        //gameCollection.collectionViewLayout = layout
        
        gameCollection.delegate = self
        gameCollection.dataSource = self
        
        //search.delegate = self
        search.returnKeyType = UIReturnKeyType.done
        search.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.searchButton.alpha = 0.5
        self.searchButton.isUserInteractionEnabled = false
    }
    
    @objc func allClicked(){
        self.currentGameGroup = "all"
        handleButtons(selected: self.currentGameGroup)
    }
    @objc func sportsClicked(){
        self.currentGameGroup = "Sports"
        handleButtons(selected: "Sports")
    }
    @objc func shooterClicked(){
        self.currentGameGroup = "Shooter"
        handleButtons(selected: "Shooter")
    }
    @objc func multiClicked(){
        self.currentGameGroup = "Massively Multiplayer"
        handleButtons(selected: "Massively Multiplayer")
    }
    @objc func actionClicked(){
        self.currentGameGroup = "Action"
        handleButtons(selected: "Action")
    }
    @objc func casualClicked(){
        self.currentGameGroup = "Casual"
        handleButtons(selected: "Casual")
    }
    
    private func handleButtons(selected: String){
        UIView.animate(withDuration: 0.8, animations: {
            self.categoryBlur.alpha = 1
            if(self.searchActive){
                self.searchActive = false
                self.searchButton.backgroundColor = .systemGreen
                self.searchImage.image = #imageLiteral(resourceName: "search.png")
                self.search.text = ""
            }
        }, completion: { (finished: Bool) in
            let searchTap = UITapGestureRecognizer(target: self, action: #selector(self.searchClicked))
            self.searchButton.addGestureRecognizer(searchTap)
            self.searchButton.isUserInteractionEnabled = false
            
            if(selected == "all"){
                /*let list = RawgGameProvider.shared.getGamerConnectGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }*/
            } else if(selected == "Action"){
                let list = RawgGameProvider.shared.getAllGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                for game in self.gameList {
                    if(!game.categoryFilters.contains("Action")){
                        self.gameList.remove(at: self.gameList.index(of: game)!)
                    }
                }
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
            } else if(selected == "Casual"){
                let list = RawgGameProvider.shared.getAllGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                for game in self.gameList {
                    if(!game.categoryFilters.contains("Casual")){
                        self.gameList.remove(at: self.gameList.index(of: game)!)
                    }
                }
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
            } else if(selected == "Shooter"){
                let list = RawgGameProvider.shared.getAllGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                for game in self.gameList {
                    if(!game.categoryFilters.contains("Shooter")){
                        self.gameList.remove(at: self.gameList.index(of: game)!)
                    }
                }
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
            } else if(selected == "Sports"){
                let list = RawgGameProvider.shared.getAllGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                for game in self.gameList {
                    if(!game.categoryFilters.contains("Sports")){
                        self.gameList.remove(at: self.gameList.index(of: game)!)
                    }
                }
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
            } else if(selected == "Massively Multiplayer"){
                let list = RawgGameProvider.shared.getAllGames()
                let sorted = list.sorted(by: { $0.gameName < $1.gameName })
                self.gameList = sorted
                
                for game in self.gameList {
                    if(!game.categoryFilters.contains("Massively Multiplayer")){
                        self.gameList.remove(at: self.gameList.index(of: game)!)
                    }
                }
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
            }
            UIView.animate(withDuration: 0.8, delay: 0.8, options: [],animations: {
                self.categoryBlur.alpha = 0
            }, completion: nil)
        })
        
        if(selected == "all"){
            self.allGamesCover.alpha = 1
            self.actionCover.alpha = 0
            self.sportsCover.alpha = 0
            self.casualCover.alpha = 0
            self.shooterCover.alpha = 0
            self.multiCover.alpha = 0
        } else if(selected == "Action"){
            self.allGamesCover.alpha = 0
            self.sportsCover.alpha = 0
            self.actionCover.alpha = 1
            self.casualCover.alpha = 0
            self.shooterCover.alpha = 0
            self.multiCover.alpha = 0
        } else if(selected == "Sports"){
            self.allGamesCover.alpha = 0
            self.actionCover.alpha = 0
            self.shooterCover.alpha = 0
            self.multiCover.alpha = 0
            self.sportsCover.alpha = 1
            self.casualCover.alpha = 0
        } else if(selected == "Casual"){
            self.allGamesCover.alpha = 0
            self.actionCover.alpha = 0
            self.sportsCover.alpha = 0
            self.shooterCover.alpha = 0
            self.multiCover.alpha = 0
            self.casualCover.alpha = 1
        } else if(selected == "Massively Multiplayer"){
            self.allGamesCover.alpha = 0
            self.actionCover.alpha = 0
            self.sportsCover.alpha = 0
            self.multiCover.alpha = 1
            self.shooterCover.alpha = 0
            self.casualCover.alpha = 0
        } else if(selected == "Shooter"){
            self.allGamesCover.alpha = 0
            self.shooterCover.alpha = 1
            self.sportsCover.alpha = 0
            self.casualCover.alpha = 0
            self.multiCover.alpha = 0
            self.actionCover.alpha = 0
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == search){
            if(textField.text?.count == 0){
                self.searchActive = false
                gameList = RawgGameProvider.shared.getAllGames()
                self.gameCollection.reloadData()
                DispatchQueue.main.async {
                    self.gameCollection.setContentOffset(.zero, animated: true)
                }
                self.searchButton.isUserInteractionEnabled = false
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.searchButton.backgroundColor = .systemGreen
                    self.searchButton.alpha = 0.5
                    self.searchImage.image = #imageLiteral(resourceName: "search.png")
                }, completion: nil)
            } else {
                self.searchActive = true
                self.searchButton.alpha = 1.0
                let searchTap = UITapGestureRecognizer(target: self, action: #selector(self.searchClicked))
                self.searchButton.addGestureRecognizer(searchTap)
                self.searchButton.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc private func searchClicked(){
        UIView.animate(withDuration: 0.8, animations: {
            self.categoryBlur.alpha = 1
            self.searchButton.backgroundColor = .systemRed
            self.searchImage.image = #imageLiteral(resourceName: "close_white.png")
        }, completion: { (finished: Bool) in
            let searchClearTap = UITapGestureRecognizer(target: self, action: #selector(self.clearSearch))
            self.searchButton.isUserInteractionEnabled = true
            self.searchButton.addGestureRecognizer(searchClearTap)
            Task {
                do {
                    let games = try await RawgGameProvider.shared.searchGames(query: self.search.text!)
                    DispatchQueue.main.async {
                        self.gameList = games
                        self.gameCollection.reloadData()
                        DispatchQueue.main.async {
                            self.gameCollection.setContentOffset(.zero, animated: true)
                        }
                        UIView.animate(withDuration: 0.8, delay: 0.8, options: [],animations: {
                            self.categoryBlur.alpha = 0
                        }, completion: nil)
                    }
                    print("✅ Found games: \(games.map { $0.gameName })")
                } catch {
                    print("❌ Error searching games:", error)
                }
            }
        })
    }
    
    @objc private func clearSearch(){
        self.search.text = ""
        UIView.animate(withDuration: 0.8,animations: {
            self.categoryBlur.alpha = 1
            self.searchButton.backgroundColor = .systemGreen
            self.searchImage.image = #imageLiteral(resourceName: "search.png")
        }, completion: { (finished: Bool) in
            let searchTap = UITapGestureRecognizer(target: self, action: #selector(self.searchClicked))
            self.searchButton.addGestureRecognizer(searchTap)
            self.searchButton.isUserInteractionEnabled = true
            
            self.allClicked()
            self.searchButton.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.8, delay: 0.8, options: [],animations: {
                self.categoryBlur.alpha = 0
            }, completion: nil)
        })
    }
    
    func createTwoByTwoGridLayout(in collectionView: UICollectionView) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        
        let numberOfColumns: CGFloat = 2
        let numberOfRows: CGFloat = 2
        let spacing: CGFloat = 8
        
        let totalHorizontalSpacing = (numberOfColumns - 1) * spacing
        let totalVerticalSpacing = (numberOfRows - 1) * spacing
        
        let itemWidth = (collectionView.bounds.width - totalHorizontalSpacing) / numberOfColumns
        let itemHeight = (collectionView.bounds.height - totalVerticalSpacing) / numberOfRows
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        return layout
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGame" {
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == self.gameCollection){
            return self.gameList.count
        } else {
            return self.pokoList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.gameCollection){
            self.gameSelected(game: self.gameList[indexPath.item])
            AlertKitAPI.present(
                title: "I love that game too.",
                icon: .done,
                style: .iOS17AppleMusic,
                haptic: .success
            )
        } else {
            let cell = self.pokoCollection.cellForItem(at: indexPath) as! PokoCell
            // Remove previous border
            activeBorderLayer?.removeFromSuperlayer()
            
            // Create and animate new border
            animateBorderTrace(around: cell.contentView) { [weak self] newLayer in
                self?.activeBorderLayer = newLayer
                cell.selectionLottie.shouldLoop = false
                cell.selectionLottie.play()
                let selectedPoko = self?.pokoList[indexPath.item].id
                self?.selectedPokoId = selectedPoko
                self?.continueButton.addTarget(self, action: #selector(self?.sendPayload), for: .touchUpInside)
                UIView.animate(withDuration: 0.5, animations: {
                    self?.continueButton.alpha = 1
                }, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == self.gameCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GameCell
            let current = gameList[indexPath.item]
            cell.configure(with: current)
            if(self.selectedGameProfile != nil){
                if(self.selectedGameProfile!.gameId == current.id){
                    cell.selectedCover.alpha = 1
                } else {
                    cell.selectedCover.alpha = 0
                }
            } else {
                cell.selectedCover.alpha = 0
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "poko", for: indexPath) as! PokoCell
            let current = pokoList[indexPath.item]
            cell.pokoName.text = current.name
            cell.pokoType.text = current.type
            if(current.specialEdition == "true"){
                cell.specialEditionImg.isHidden = false
            } else {
                cell.specialEditionImg.isHidden = true
            }
            let url = URL(string: current.imageUrl)
            if (url != nil) {
                /*ImageLoader.shared.loadImage(from: url!) { [weak self] image in
                    cell.pokoImg.image = image
                }*/
                //cell.pokoImg.kf.setImage(with: url)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == self.gameCollection){
            let spacing: CGFloat = 10
            let totalSpacing = spacing * 3
            let width = (collectionView.bounds.width - totalSpacing) / 2
            return CGSize(width: width, height: 200)
        } else {
            let numberOfColumns: CGFloat = 2
            let numberOfRows: CGFloat = 2
            let spacing: CGFloat = 8
            
            let totalHorizontalSpacing = (numberOfColumns - 1) * spacing
            let totalVerticalSpacing = (numberOfRows - 1) * spacing
            
            let itemWidth = (collectionView.bounds.width - totalHorizontalSpacing) / numberOfColumns
            let itemHeight = (collectionView.bounds.height - totalVerticalSpacing) / numberOfRows
            
            return CGSize(width: itemWidth, height: itemHeight)
        }
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
    
    private func gameSelected(game: GamerConnectGame){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.selectedGameProfile = GamerProfile(gamerTag: appDelegate.currentUser!.screenName, game: game.gameName, console: "", quizTaken: "false", gameId: game.id)
        self.gameCollection.reloadData()
        
        self.continueButton.addTarget(self, action: #selector(self.showPokoLayout), for: .touchUpInside)
        self.continueButton.alpha = 1
        self.continueButton.isUserInteractionEnabled = true
    }
    
    @objc private func advanceToResults(){
        self.buildingAnimation.play()
        self.buildingAnimation.loopMode = .loop
        UIView.animate(withDuration: 0.8, animations: {
            self.buildingBlur.alpha = 1
            self.buildingAnimation.alpha = 1
        }, completion: { (finished: Bool) in
            self.sendPayload()
        })
    }
    
    @objc private func closeModal(){
        UIView.animate(withDuration: 0.8, animations: {
            self.updateBlur.alpha = 1
        }, completion: { (finished: Bool) in
            /*UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
             self.updateAnimation.alpha = 1
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
             self.updateAnimation.loopMode = .loop
             self.updateAnimation.play()
             self.updatePayload()
             }
             }, completion: nil)*/
        })
    }
    
    private func updatePayload(){
        if(self.modalPopped){
            //self.upgradeFrag?.dismissModal()
            self.dismiss(animated: true) {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
            }
        } else {
            self.proceedToLanding()
        }
    }
    
    @objc private func sendPayload(){
        UIView.animate(withDuration: 0.8, animations: {
            self.buildingBlur.alpha = 1
            self.buildingAnimation.alpha = 1
        }, completion: { (finished: Bool) in
            self.buildingAnimation.loopMode = .loop
            self.buildingAnimation.play()
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = delegate.socialMediaManager
            manager.getTwitchAppToken(token: nil, uid: delegate.currentUser!.uId)
            if(self.selectedPokoId != nil){
                self.savePokos()
            }
            if(!delegate.currentUser!.screenName.isEmpty){
                self.proceedToLanding()
            }
        })
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
            //self.loadBackupUsersCache()
        }
    }
    
    private func loadUsers(list: [String]?){
        if(list != nil){
            var newList = [String]()
            newList.append(contentsOf: list!)
            newList.shuffle()
            //self.loadListUser(uid: list![0], currentList: newList)
        } else {
            //self.loadBackupUsersCache()
        }
    }
    
    /*private func loadListUser(uid: String, currentList: [String]?){
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
                    let gameId = dict?["gameId"] as? String ?? ""
                    
                    if(currentTag != "" && currentGame != "" && console != ""){
                        let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken, gameId: gameId)
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
    }*/
    
    /*private func loadBackupUsersCache(){
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
                        //if(gameMatch && languageMatch && !tag.isEmpty){
                        //    perfectMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        //}
                        //if(gameMatch && !tag.isEmpty){
                        //    gamesMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        //}
                        //if(languageMatch && !tag.isEmpty){
                        //    languageMatches.append(self.quickCreateUser(snapshot: user as! DataSnapshot))
                        //}
                        
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
    }*/
    
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
    
    private func saveGames(){
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
                    let gameId = dict?["gameId"] as? String ?? ""
                    
                    if(currentTag != "" && currentGame != "" && console != ""){
                        consoles.append(console)
                        let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken, gameId: gameId)
                        gamerTags.append(currentGamerTagObj)
                    }
                }
            }
            gamerTags.append(contentsOf: self.newProfiles)
            delegate.currentUser!.gamerTags = gamerTags
            
            var sendUp = [[String: String]]()
            for profile in gamerTags {
                let newProfile = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console, "quizTaken": profile.quizTaken]
                sendUp.append(newProfile)
            }
            ref.child("gamerTags").setValue(sendUp)
            
            if(snapshot.hasChild("games")){
                var games = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                for gameProfile in self.newProfiles {
                    if(!games.contains(gameProfile.game)){
                        games.append(gameProfile.game)
                    }
                }
                ref.child("games").setValue(games)
                delegate.currentUser!.games = games
            } else {
                var games = [String]()
                for gameProfile in self.newProfiles {
                    if(!games.contains(gameProfile.game)){
                        games.append(gameProfile.game)
                    }
                }
                delegate.currentUser!.games = games
            }
        })
    }
    
    private func savePokos(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let dbRef = Database.database().reference()
        dbRef.child("Pokos")
            .queryOrdered(byChild: "id")
            .queryEqual(toValue: self.selectedPokoId!)
            .observeSingleEvent(of: .value) { snapshot in
                guard snapshot.exists(), let pokoDict = snapshot.value as? [String: Any],
                      let matchingKey = pokoDict.keys.first else {
                    print("❌ No poko found matching id \(self.selectedPokoId!)")
                    return
                }
                
                // Step 2: Read current ownedPokos
                let userRef = dbRef.child("Users/\(delegate.currentUser!.uId)")
                userRef.child("ownedPokos").observeSingleEvent(of: .value) { ownedSnapshot in
                    var currentOwned = ownedSnapshot.value as? [String] ?? []
                    
                    // Step 3: Append only if not already owned
                    if !currentOwned.contains(self.selectedPokoId!) {
                        currentOwned.append(self.selectedPokoId!)
                    }
                    
                    // Step 4: Batch update: selectedPoko, ownedPokos, and downloadCount
                    let updates: [String: Any] = [
                        "/Users/\(delegate.currentUser!.uId)/selectedPoko": self.selectedPokoId!,
                        "/Users/\(delegate.currentUser!.uId)/ownedPokos": currentOwned,
                        "/Pokos/\(matchingKey)/downloadCount": ServerValue.increment(1)
                    ]
                    
                    dbRef.updateChildValues(updates) { error, _ in
                        if let err = error {
                            print("⚠️ Update error:", err.localizedDescription)
                        } else {
                            print("🎉 Updated selected poko, owned list, and download count")
                        }
                    }
                }
            }
    }
    
    @objc private func showPokoLayout(override: Bool){
        self.saveGames()
        if(self.selectedGameProfile == nil && !self.pokoOverride){
            PopupManager.show(
                title: "Pick a Game?",
                message: "You don’t have to, but choosing one helps others connect with you!",
                okButtonText: "Skip for now",
                cancelButtonText: "Let me pick a game",
                popupType: .normal,
                okAction: {
                    SwiftEntryKit.dismiss()
                    self.pokoOverride = true
                    self.showPokoLayout(override: true)
                },
                cancelAction: { SwiftEntryKit.dismiss() }
            )
            return
        }
        self.pokoCollection.collectionViewLayout = createTwoByTwoGridLayout(in: self.pokoCollection)
        self.pokoCollection.contentInsetAdjustmentBehavior = .never
        self.pokoCollection.delegate = self
        self.pokoCollection.dataSource = self
        
        UIView.animate(withDuration: 0.8, animations: {
            self.casualButton.alpha = 0
            self.actionButton.alpha = 0
            self.shooterButton.alpha = 0
            self.multiButton.alpha = 0
            self.sportsButton.alpha = 0
            self.allGamesButton.alpha = 0
            self.gameSelectionHeader.alpha = 0
            self.gameSelectionSub.alpha = 0
            self.gameCollection.alpha = 0
            self.searchView.alpha = 0
            self.continueButton.alpha = 0.5
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, animations: {
                self.pokoLayout.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                    self.pokoTitle.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        self.pokoSub.alpha = 1
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, animations: {
                            self.pokoCollection.alpha = 1
                        }, completion: nil)
                    })
                })
            })
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(scrollView == self.gameCollection) {
            let visibleIndexPaths = self.gameCollection.indexPathsForVisibleItems.sorted(by: { $0.item < $1.item })
            // Example: Get next 10 index paths to prefetch
            let upcomingIndexPaths = visibleIndexPaths.compactMap { IndexPath(item: $0.item + 1, section: $0.section) }
            preloadUpcomingImages(from: upcomingIndexPaths)
        }
    }
    
    func preloadUpcomingImages(from indexPaths: [IndexPath]) {
        let upcomingGames = indexPaths.compactMap { indexPath in
            return gameList[safe: indexPath.item] // use a safe subscript if needed
        }

        let urls = upcomingGames.compactMap { URL(string: $0.imageUrl ?? "") }

        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }
    
    func animateBorderTrace(
        around view: UIView,
        borderColor: UIColor = .systemGreen,
        lineWidth: CGFloat = 4.0,
        duration: CFTimeInterval = 0.5,
        completion: ((CAShapeLayer) -> Void)? = nil
    ) {
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeEnd = 0

        view.layer.addSublayer(shapeLayer)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion?(shapeLayer)
        }

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shapeLayer.add(animation, forKey: "traceBorder")

        CATransaction.commit()

        shapeLayer.strokeEnd = 1
    }
    
    @objc private func showPokoTooltip() {
        TooltipHelper.showTooltip(
            title: "What is a Poko?",
            message: "The Poko you choose is your in-app companion as well as your digital representation of 'you'.",
            image: UIImage(named: "pinky")!,
            imageOnRight: false,
            duration: 5
        )
    }
}
