//
//  GamerConnectSearch.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftNotificationCenter
import MSPeekCollectionViewDelegateImplementation
import FBSDKCoreKit

class GamerConnectSearch: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout, SearchCallbacks {
    
    var game: GamerConnectGame? = nil
    
    var returnedUsers = [User]()
    var searchPS = true
    var searchXbox = true
    var searchNintendo = true
    var searchPC = true
    var set = false
    
    @IBOutlet weak var searchingText: UILabel!
    @IBOutlet weak var gameHeaderImage: UIImageView!
    @IBOutlet weak var gamerConnectResults: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var searchEmpty: UIView!
    @IBOutlet weak var searchEmptyText: UILabel!
    @IBOutlet weak var searchEmptySub: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var searchProgress: UIActivityIndicatorView!
    
    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //check rivals on entry.
        
        if(game != nil){
            //gameHeaderImage.alpha = 0
            
            gameHeaderImage.image = Utility.Image.placeholder
            gameHeaderImage.moa.url = game?.imageUrl
            gameHeaderImage.contentMode = .scaleAspectFill
            //gameImageHeader.clipsToBounds = true
            
            searchPS = false
            searchXbox = false
            searchNintendo = false
            searchPC = false
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            currentUser = delegate.currentUser
            
            if(currentUser != nil){
                if(currentUser!.ps){
                    psSwitch.isOn = true
                    searchPS = true
                }
                if(currentUser!.xbox){
                    xboxSwitch.isOn = true
                    searchXbox = true
                }
                if(currentUser!.nintendo){
                    nintendoSwitch.isOn = true
                    searchNintendo = true
                }
                if(currentUser!.pc){
                    pcSwitch.isOn = true
                    searchPC = true
                }
            }
            
            psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
            pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
            xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
            nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
            
            Broadcaster.register(SearchCallbacks.self, observer: self)
            
            checkRivals()
        }
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
        
        for rival in currentUser.currentTempRivals{
            let calendar = Calendar.current
            if(!rival.date.isEmpty){
                let dbDate = self.stringToDate(rival.date) as NSDate
                
                if(dbDate != nil){
                    let dbDateFuture = calendar.date(byAdding: .minute, value: 5, to: dbDate as Date)
                    
                    if(dbDateFuture != nil){
                        if((dbDateFuture! as NSDate).isLessThanDate(dateToCompare: NSDate())){
                            currentUser.currentTempRivals.remove(at: currentUser.currentTempRivals.index(of: rival)!)
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.searchUsers(userName: nil)
        }
        
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="yyyy.MM.dd hh:mm aaa"
        return formatter.date(from: str)!
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        if(stationSwitch.isOn){
            searchPS = true
        }
        else{
            searchPS = false
        }
        searchUsers(userName: nil)
    }
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        if(xSwitch.isOn){
            searchXbox = true
        }
        else{
            searchXbox = false
        }
        searchUsers(userName: nil)
    }
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        if(switchSwitch.isOn){
            searchNintendo = true
        }
        else{
            searchNintendo = false
        }
        searchUsers(userName: nil)
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        if(compSwitch.isOn){
            searchPC = true
        }
        else{
            searchPC = false
        }
        searchUsers(userName: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return returnedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserCell
        
        let manager = GamerProfileManager()
        let current = returnedUsers[indexPath.item]
        cell.gamerTag.text = manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: current)
        
        if(current.bio.isEmpty){
            cell.consoleTag.text = "No bio available."
        }
        else{
            cell.consoleTag.text = current.bio
        }
        
        var oneShowing = false
        var twoShowing = false
        var threeShowing = false
        var fourShowing = false
        
        if(current.ps){
            oneShowing = true
            cell.oneTag.text = "PS"
        }
        if(current.xbox){
            if(oneShowing && !twoShowing){
                cell.consoleTwo.isHidden = false
                cell.twoTag.text = "XBox"
                twoShowing = true
            }
            else{
                oneShowing = true
                cell.oneTag.text = "XBox"
            }
        }
        if(current.nintendo){
            if(oneShowing && !twoShowing){
                cell.consoleTwo.isHidden = false
                cell.twoTag.text = "Nintendo"
                twoShowing = true
            }
            else if(oneShowing && twoShowing && !threeShowing){
                threeShowing = true
                cell.consoleThree.isHidden = false
                cell.threeTag.text = "Nintendo"
            }
            else{
                oneShowing = true
                cell.oneTag.text = "Nintendo"
            }
        }
        if(current.pc){
            if(oneShowing && !twoShowing){
                cell.consoleTwo.isHidden = false
                cell.twoTag.text = "PC"
                twoShowing = true
            }
            else if(oneShowing && twoShowing && !threeShowing){
                threeShowing = true
                cell.consoleThree.isHidden = false
                cell.threeTag.text = "PC"
            }
            else if(oneShowing && twoShowing && threeShowing && !fourShowing){
                fourShowing = true
                cell.consoleFour.isHidden = false
                cell.fourTag.text = "PC"
            }
            else{
                oneShowing = true
                cell.oneTag.text = "PC"
            }
        }
        
        
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Profile Accessed"))
        
        let current = returnedUsers[indexPath.item]
        
        let uid = current.uId
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToProfile(uid: current.uId)
    }
    
    private func searchUsers(userName: String?){
        if(self.searchPS){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PS, Game: " + self.game!.gameName))
        }
        if(self.searchXbox){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: XBox, Game: " + self.game!.gameName))
        }
        if(self.searchPC){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PC, Game: " + self.game!.gameName))
        }
        if(self.searchNintendo){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: Nintendo, Game: " + self.game!.gameName))
        }
        
        if(userName != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - User"))
        }
        
        if(self.loadingView.alpha == 0){
            self.searchProgress.startAnimating()
            
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.searchUsers(userName: userName)
                }
            })
            return
        }
        
        self.returnedUsers = [User]()
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                
                
                let search = value?["search"] as? String ?? "true"
                let gamerTag = value?["gamerTag"] as? String ?? ""
                
                //make users that did not enter a gamertag are not searchable
                if(search == "true" && !(gamerTag.isEmpty && gamerTag == "undefined")){
                    let games = value?["games"] as? [String] ?? [String]()
                    
                    if(games.contains(self.game!.gameName) && userName == nil){
                        let uId = (user as! DataSnapshot).key
                        let bio = value?["bio"] as? String ?? ""
                        let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                        
                        var friends = [FriendObject]()
                        let friendsArray = snapshot.childSnapshot(forPath: "friends")
                        for friend in friendsArray.children{
                            let currentObj = friend as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                            friends.append(newFriend)
                        }
                        
                        let games = value?["games"] as? [String] ?? [String]()
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                        let dict = consoleArray.value as? [String: Bool]
                        let nintendo = dict?["nintendo"] ?? false
                        let ps = dict?["ps"] ?? false
                        let xbox = dict?["xbox"] ?? false
                        let pc = dict?["pc"] ?? false
                        
                        let returnedUser = User(uId: uId)
                        returnedUser.gamerTags = gamerTags
                        returnedUser.games = games
                        returnedUser.friends = friends
                        returnedUser.sentRequests = sentRequests
                        returnedUser.gamerTag = gamerTag
                        returnedUser.pc = pc
                        returnedUser.ps = ps
                        returnedUser.xbox = xbox
                        returnedUser.nintendo = nintendo
                        returnedUser.bio = bio
                        
                        //if the returned user plays the game being searched AND the returned users gamertag
                        //does not equal the current users gamertag, then add to list.
                        
                        if(returnedUser.games.contains(self.game!.gameName) && self.currentUser.uId != returnedUser.uId){
                            
                            if(self.searchPS && returnedUser.ps){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchPC && returnedUser.pc){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchXbox && returnedUser.xbox){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchNintendo && returnedUser.nintendo){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else{
                                for profile in returnedUser.gamerTags{
                                    if(profile.game == self.game?.gameName){
                                        self.addUserToList(returnedUser: returnedUser)
                                    }
                                }
                            }
                        }
                        
                    }
                    else if(userName != nil){
                        let trimmedUser = userName!.trimmingCharacters(in: .whitespacesAndNewlines)
                        var gamerTag = (value?["gamerTag"] as? String) ?? ""
                        if(!gamerTag.isEmpty){
                            gamerTag = gamerTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        var contained = false
                        //check legacy users first
                        if(gamerTag == trimmedUser){
                            contained = true
                        }
                        
                        //if not legacy, or not found, check gamertags one more time
                        if(!contained){
                            for gamerTagObj in gamerTags{
                                if(gamerTagObj.gamerTag == trimmedUser){
                                    contained = true
                                    break
                                }
                            }
                        }
                        
                        if(contained){
                        let gamerProfileManager = GamerProfileManager()
                        
                        if(userName != nil){
                            if(!gamerTag.isEmpty && gamerTag == trimmedUser && (gamerProfileManager.getGamerTagForGame(gameName: self.game!.gameName) != userName)){
                                
                                let uId = (user as! DataSnapshot).key
                                let bio = value?["bio"] as? String ?? ""
                                let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                                
                                var friends = [FriendObject]()
                                let friendsArray = snapshot.childSnapshot(forPath: "friends")
                                for friend in friendsArray.children{
                                    let currentObj = friend as! DataSnapshot
                                    let dict = currentObj.value as? [String: Any]
                                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                                    let date = dict?["date"] as? String ?? ""
                                    let uid = dict?["uid"] as? String ?? ""
                                    
                                    let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                                    friends.append(newFriend)
                                }
                                
                                let games = value?["games"] as? [String] ?? [String]()
                                var gamerTags = [GamerProfile]()
                                let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                                for gamerTagObj in gamerTagsArray.children {
                                    let currentObj = gamerTagObj as! DataSnapshot
                                    let dict = currentObj.value as? [String: Any]
                                    let currentTag = dict?["gamerTag"] as? String ?? ""
                                    let currentGame = dict?["game"] as? String ?? ""
                                    let console = dict?["console"] as? String ?? ""
                                    
                                    let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                                    gamerTags.append(currentGamerTagObj)
                                }
                                
                                let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                                let dict = consoleArray.value as? [String: Bool]
                                let nintendo = dict?["nintendo"] ?? false
                                let ps = dict?["ps"] ?? false
                                let xbox = dict?["xbox"] ?? false
                                let pc = dict?["pc"] ?? false
                                
                                let returnedUser = User(uId: uId)
                                returnedUser.gamerTags = gamerTags
                                returnedUser.games = games
                                returnedUser.friends = friends
                                returnedUser.sentRequests = sentRequests
                                returnedUser.gamerTag = gamerTag
                                returnedUser.pc = pc
                                returnedUser.ps = ps
                                returnedUser.xbox = xbox
                                returnedUser.nintendo = nintendo
                                returnedUser.bio = bio
                                
                                self.returnedUsers.append(returnedUser)
                            }
                        }
                    }
                }
            }
        }
        
        if(!self.set){
            self.gamerConnectResults.delegate = self
            self.gamerConnectResults.dataSource = self
            
            self.set = true
            
            self.searchProgress.stopAnimating()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    if(!self.returnedUsers.isEmpty){
                        self.searchEmpty.isHidden = true
                        let top = CGAffineTransform(translationX: 0, y: -30)
                        
                        self.gamerConnectResults.alpha = 1
                        self.gamerConnectResults.transform = top
                        
                        UIView.animate(withDuration: 0.8, animations: {
                            self.gamerConnectResults.delegate = self
                            self.gamerConnectResults.dataSource = self
                        }, completion: nil)
                    }
                    else{
                        self.searchEmpty.isHidden = false
                        
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }, completion: nil)
            })
        }
        else{
            if(!self.loadingView.isHidden){
                self.searchProgress.stopAnimating()
                UIView.animate(withDuration: 0.8, animations: {
                    self.loadingView.alpha = 0
                }, completion: { (finished: Bool) in
                    self.gamerConnectResults.reloadData()
                    
                    if(!self.returnedUsers.isEmpty){
                        self.searchEmpty.isHidden = true
                    }
                    else{
                        self.searchEmpty.isHidden = false
                        
                        if(userName != nil){
                            self.searchEmptyText.text = "No users returned with that name."
                            self.searchEmptySub.text = "No worries.\nMake sure you typed their naame correctly, and try again."
                        }
                        else{
                            self.searchEmptyText.text = "No users returned for your chosen game."
                            self.searchEmptySub.text = "No worries, try your search again later."
                        }
                    }
                })
            }
        }
        
        }) { (error) in
            print(error.localizedDescription)
            AppEvents.logEvent(AppEvents.Name(rawValue: "GamerConnect Search "))

            UIView.transition(with: self.loadingView, duration: 0.3, options: .curveEaseInOut, animations: {
                self.loadingView.backgroundColor = #colorLiteral(red: 0.6423664689, green: 0, blue: 0.04794860631, alpha: 0.6023116438)
                self.searchingText.text = "error loading results. please try again later."
            }, completion: nil)
        }
    }
    
    func searchSubmitted(searchString: String) {
        searchUsers(userName: searchString)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
    }
    
    private func addUserToList(returnedUser: User){
        var contained = false
        let manager = GamerProfileManager()
        
        for user in returnedUsers{
            if(manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: user) == manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: returnedUser)){
                
                contained = true
                break
            }
        }
        
        if(!contained){
            self.returnedUsers.append(returnedUser)
        }
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
}

extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}

