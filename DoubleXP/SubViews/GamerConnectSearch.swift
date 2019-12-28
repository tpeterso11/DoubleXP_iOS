//
//  GamerConnectSearch.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class GamerConnectSearch: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource {
    var game: GamerConnectGame? = nil
    
    var returnedUsers = [User]()
    var searchPS = true
    var searchXbox = true
    var searchNintendo = true
    var searchPC = true
    
    @IBOutlet weak var gameHeaderImage: UIImageView!
    @IBOutlet weak var gamerConnectResults: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.removeBottomNav(showNewNav: true, hideSearch: false, searchHint: "Search for player")
        
        appDelegate.navStack.append(self)
        
        self.pageName = "GC Search"
        
        if(game != nil){
            gameHeaderImage.moa.url = game?.imageUrl
            gameHeaderImage.contentMode = .scaleAspectFill
            //gameImageHeader.clipsToBounds = true
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.currentUser
            
            if(user != nil){
                if(user!.ps){
                    psSwitch.isOn = true
                    searchPS = true
                }
                if(user!.xbox){
                    xboxSwitch.isOn = true
                    searchXbox = true
                }
                if(user!.nintendo){
                    nintendoSwitch.isOn = true
                    searchNintendo = true
                }
                if(user!.pc){
                    pcSwitch.isOn = true
                    searchPC = true
                }
            }
            
            psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
            pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
            xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
            nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
            
            searchUsers(userName: nil)
        }
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        if(stationSwitch.isOn){
            searchPS = true
        }
        else{
            searchPS = false
        }
    }
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        if(xSwitch.isOn){
            searchXbox = true
        }
        else{
            searchXbox = false
        }
    }
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        if(switchSwitch.isOn){
            searchNintendo = true
        }
        else{
            searchNintendo = false
        }
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        if(compSwitch.isOn){
            searchPC = true
        }
        else{
            searchPC = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return returnedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserCell
        
        let manager = GamerProfileManager()
        let current = returnedUsers[indexPath.item]
        cell.gamerTag.text = manager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: current)
        
        cell.consoleTag.text = current.getConsoleString()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = returnedUsers[indexPath.item]
        
        let uid = current.uId
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.navigateToProfile(uid: current.uId)
    }
    
    private func searchUsers(userName: String?){
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                let games = value?["games"] as? [String] ?? [String]()
                
                if(games.contains(self.game!.gameName)){
                    let uId = (user as! DataSnapshot).key
                    let gamerTag = value?["gamerTag"] as? String ?? ""
                    let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                    
                    var friends = [FriendObject]()
                    let friendsArray = snapshot.childSnapshot(forPath: "friends")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
                        let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                        friends.append(newFriend)
                    }
                    
                    let games = value?["games"] as? [String] ?? [String]()
                    var gamerTags = [GamerProfile]()
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as! [String: Any]
                        let currentTag = dict["gamerTag"] as? String ?? ""
                        let currentGame = dict["game"] as? String ?? ""
                        let console = dict["console"] as? String ?? ""
                        
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
                    
                    let gamerProfileManager = GamerProfileManager()
                    let delegate = UIApplication.shared.delegate as! AppDelegate!
                    let currentUser = delegate?.currentUser
                    
                    if(userName != nil){
                        if(!gamerTag.isEmpty && gamerTag == userName && gamerProfileManager.getGamerTagForGame(gameName: self.game!.gameName) != userName){
                            self.returnedUsers.append(returnedUser)
                            
                            self.gamerConnectResults.delegate = self
                            self.gamerConnectResults.dataSource = self
                            
                            return
                        }
                    }
                    else{
                        //if the returned user plays the game being searched AND the returned users gamertag
                        //does not equal the current users gamertag, then add to list.
                        
                        if(returnedUser.games.contains(self.game!.gameName) && gamerProfileManager.getGamerTagForOtherUserForGame(gameName: self.game!.gameName, returnedUser: returnedUser) != gamerProfileManager.getGamerTagForGame(gameName: self.game!.gameName)){
                            
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
                        }
                    }
                }
            }
            
            if(!self.returnedUsers.isEmpty){
                self.gamerConnectResults.delegate = self
                self.gamerConnectResults.dataSource = self
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
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
    
}
