//
//  PlayerProfile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/6/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class PlayerProfile: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate {
    var uid: String = ""
    var userForProfile: User? = nil
    
    var keys = [String]()
    
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var profileLine2: UILabel!
    @IBOutlet weak var profileLine3: UILabel!
    @IBOutlet weak var bio: VerticalAlignLabel!
    @IBOutlet weak var statsCollection: UICollectionView!
    @IBOutlet weak var consoleOne: UILabel!
    @IBOutlet weak var consoleTwo: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var connectButton: UIImageView!
    
    var sections = [Section]()
    var nav: NavigationPageController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard !uid.isEmpty else {
            return
        }
    
        loadUserInfo(uid: uid)
        self.pageName = "Profile"
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        appDelegate.navStack.append(self)
        
        currentLanding?.removeBottomNav(showNewNav: false, hideSearch: false, searchHint: "Search for player")
        
        headerView.clipsToBounds = true
    }
    
    @objc func messagingButtonClicked(_ sender: AnyObject?) {
        
    }
    
    func loadUserInfo(uid: String){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let uId = snapshot.key
            let bio = value?["bio"] as? String ?? ""
            let gamerTag = value?["gamerTag"] as? String ?? ""
            let games = value?["games"] as? [String] ?? [String]()
            var gamerTags = [GamerProfile]()
            let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
            for gamerTagObj in gamerTagsArray.children {
                let currentObj = gamerTagObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let currentTag = dict["gamerTag"] as? String ?? ""
                let currentGame = dict["game"] as? String ?? ""
                let console = dict["console"] as? String ?? ""
                
                let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console)
                gamerTags.append(currentGamerTagObj)
            }
            var teams = [TeamObject]()
            let teamsArray = snapshot.childSnapshot(forPath: "teams")
            for teamObj in teamsArray.children {
                let currentObj = teamObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let teamName = dict["teamName"] as? String ?? ""
                let teamId = dict["teamId"] as? String ?? ""
                let games = dict["games"] as? [String] ?? [String]()
                let consoles = dict["consoles"] as? [String] ?? [String]()
                let teammateTags = dict["teammateTags"] as? [String] ?? [String]()
                let teammateIds = dict["teammateIds"] as? [String] ?? [String]()
                
                var invites = [TeamInviteObject]()
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid)
                    invites.append(newInvite)
                }
                
                let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                let captain = dict["teamCaptain"] as? String ?? ""
                let imageUrl = dict["imageUrl"] as? String ?? ""
                let teamChat = dict["teamChat"] as? String ?? String()
                let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                
                let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                teams.append(currentTeam)
            }
            
            var currentStats = [StatObject]()
            let statsArray = snapshot.childSnapshot(forPath: "stats")
            for statObj in statsArray.children {
                let currentObj = statObj as! DataSnapshot
                let dict = currentObj.value as! [String: Any]
                let gameName = dict["gameName"] as? String ?? ""
                let playerLevelGame = dict["playerLevelGame"] as? String ?? ""
                let playerLevelPVP = dict["playerLevelPVP"] as? String ?? ""
                let killsPVP = dict["killsPVP"] as? String ?? ""
                let killsPVE = dict["killsPVE"] as? String ?? ""
                let statURL = dict["statURL"] as? String ?? ""
                let setPublic = dict["setPublic"] as? String ?? ""
                let authorized = dict["authorized"] as? String ?? ""
                let currentRank = dict["currentRank"] as? String ?? ""
                let totalRankedWins = dict["otalRankedWins"] as? String ?? ""
                let totalRankedLosses = dict["totalRankedLosses"] as? String ?? ""
                let totalRankedKills = dict["totalRankedKills"] as? String ?? ""
                let totalRankedDeaths = dict["totalRankedDeaths"] as? String ?? ""
                let mostUsedAttacker = dict["mostUsedAttacker"] as? String ?? ""
                let mostUsedDefender = dict["mostUsedDefender"] as? String ?? ""
                let gearScore = dict["gearScore"] as? String ?? ""
                
                let currentStat = StatObject(gameName: gameName)
                currentStat.authorized = authorized
                currentStat.playerLevelGame = playerLevelGame
                currentStat.playerLevelPVP = playerLevelPVP
                currentStat.killsPVP = killsPVP
                currentStat.killsPVE = killsPVE
                currentStat.statUrl = statURL
                currentStat.setPublic = setPublic
                currentStat.authorized = authorized
                currentStat.currentRank = currentRank
                currentStat.totalRankedWins = totalRankedWins
                currentStat.totalRankedLosses = totalRankedLosses
                currentStat.totalRankedKills = totalRankedKills
                currentStat.totalRankedDeaths = totalRankedDeaths
                currentStat.mostUsedAttacker = mostUsedAttacker
                currentStat.mostUsedDefender = mostUsedDefender
                currentStat.gearScore = gearScore
                
                currentStats.append(currentStat)
            }
            
            let consoleArray = snapshot.childSnapshot(forPath: "consoles")
            let dict = consoleArray.value as? [String: Bool]
            let nintendo = dict?["nintendo"] ?? false
            let ps = dict?["ps"] ?? false
            let xbox = dict?["xbox"] ?? false
            let pc = dict?["pc"] ?? false
            
            let user = User(uId: uId)
            user.gamerTags = gamerTags
            user.teams = teams
            user.stats = currentStats
            user.games = games
            user.gamerTag = gamerTag
            user.pc = pc
            user.ps = ps
            user.xbox = xbox
            user.nintendo = nintendo
            user.bio = bio
            
            self.setUI(user: user)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func setUI(user: User){
        self.userForProfile = user
        let manager = GamerProfileManager()
        
        self.gamerTag.text = manager.getGamerTag(user: user)
        
        let consoles = user.getConsoleArray()
        if(!consoles.isEmpty){
            consoleOne.text = consoles[0]
            consoleOne.layer.masksToBounds = true
            consoleOne.layer.cornerRadius = 15
            
            if(consoles.indices.contains(1)){
                consoleTwo.text = consoles[1]
                consoleTwo.layer.masksToBounds = true
                consoleTwo.layer.cornerRadius = 15
            }
        }
        //let consoleString = user.getConsoleString()
        //self.profileLine2.text = String(consoleString)
        
        if(!user.stats.isEmpty){
            for stat in user.stats {
                let section = Section(name: stat.gameName, items: stat, collapsed: false)
                self.sections.append(section)
            }
            
            statsCollection.delegate = self
            statsCollection.dataSource = self
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let friendsManager = FriendsManager()
        
        if(friendsManager.checkListsForUser(user: userForProfile!, currentUser: currentUser!)){
            
            if(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)){
                //change image
                connectButton.image = UIImage(named: "messaging_button")
                
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(messagingButtonClicked))
                connectButton.isUserInteractionEnabled = true
                connectButton.addGestureRecognizer(singleTap)
            }
            
            for request in currentUser!.sentRequests{
                if(request.uid == user.uId){
                    connectButton.image = UIImage(named: "pending_button")
                    break
                }
            }
            
            for request in currentUser!.pendingRequests{
                if(request.uid == user.uId){
                    connectButton.image = UIImage(named: "pending_button")
                    break
                }
            }
        }
        else{
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(connectButtonClicked))
            connectButton.isUserInteractionEnabled = true
            connectButton.addGestureRecognizer(singleTap)
        }
        
        guard !user.bio.isEmpty else{
            //self.bio.text = "This user has not yet created a bio."
            self.bio.text = "I roll with the muh-fuckin rough ridin, ride or dyin, killing ERRRRRYBODY CLAN Xoxx:snfdgXXX"
            return
        }
        self.bio.text = user.bio
    }
    
    @objc func connectButtonClicked(_ sender: AnyObject?) {
        let friendsManager = FriendsManager()
        
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate!
            let currentUser = delegate?.currentUser
            friendsManager.sendRequestFromProfile(currentUser: currentUser!, otherUser: userForProfile!)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].getCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "statCell", for: indexPath) as! StatsCell
        
        let current = self.sections[indexPath.section]
        if(!keys.contains(current.items.gameName + "playerLevelGame") && !current.items.playerLevelGame.isEmpty){
            keys.append(current.items.gameName + "playerLevelGame")
            
            cell.statLabel.text = "Player Level Game"
            cell.statHeader.text = current.items.playerLevelGame
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "playerLevelPVP") && !current.items.playerLevelPVP.isEmpty){
            keys.append(current.items.gameName + "playerLevelPVP")
            
            cell.statLabel.text = "Player Level PVP"
            cell.statHeader.text = current.items.playerLevelPVP
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "killsPVE") && !current.items.killsPVE.isEmpty){
            keys.append(current.items.gameName + "killsPVE")
            
            cell.statLabel.text = "Kills PVE"
            cell.statHeader.text = current.items.killsPVE
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "killsPVP") && !current.items.killsPVP.isEmpty){
            keys.append(current.items.gameName + "killsPVP")
            
            cell.statLabel.text = "Kills PVP"
            cell.statHeader.text = current.items.killsPVP
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "currentRank") && !current.items.currentRank.isEmpty){
            keys.append(current.items.gameName + "currentRank")
            
            cell.statLabel.text = "Current Rank"
            cell.statHeader.text = current.items.currentRank
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "gearScore") && !current.items.gearScore.isEmpty){
            keys.append(current.items.gameName + "gearScore")
            
            cell.statLabel.text = "Gear Score"
            cell.statHeader.text = current.items.gearScore
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "totalRankedKills") && !current.items.totalRankedKills.isEmpty){
            keys.append(current.items.gameName + "totalRankedKills")
            
            cell.statLabel.text = "Total Ranked Kills"
            cell.statHeader.text = current.items.totalRankedKills
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "totalRankedDeaths") && !current.items.totalRankedDeaths.isEmpty){
            keys.append(current.items.gameName + "totalRankedDeaths")
            
            cell.statLabel.text = "Total Ranked Deaths"
            cell.statHeader.text = current.items.totalRankedDeaths
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "mostUsedAttacker") && !current.items.mostUsedAttacker.isEmpty){
            keys.append(current.items.gameName + "mostUsedAttacker")
            
            cell.statLabel.text = "Most Used Attacker"
            cell.statHeader.text = current.items.mostUsedAttacker
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "mostUsedDefender") && !current.items.mostUsedDefender.isEmpty){
            keys.append(current.items.gameName + "mostUsedDefender")
            
            cell.statLabel.text = "Most Used Defender"
            cell.statHeader.text = current.items.mostUsedDefender
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "totalRankedWins") && !current.items.totalRankedWins.isEmpty){
            keys.append(current.items.gameName + "totalRankedWins")
            
            cell.statLabel.text = "Total Ranked Wins"
            cell.statHeader.text = current.items.totalRankedWins
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "totalRankedLosses") && !current.items.totalRankedLosses.isEmpty){
            keys.append(current.items.gameName + "totalRankedLosses")
            
            cell.statLabel.text = "Total Ranked Losses"
            cell.statHeader.text = current.items.totalRankedLosses
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "authorized") && !current.items.authorized.isEmpty){
            keys.append(current.items.gameName + "authorized")
            
            cell.statLabel.text = "Authorized"
            cell.statHeader.text = current.items.authorized
            
            return cell
        }
        
        if(!keys.contains(current.items.gameName + "setPublic") && !current.items.setPublic.isEmpty){
            keys.append(current.items.gameName + "setPublic")
            
            cell.statLabel.text = "Public"
            cell.statHeader.text = current.items.setPublic
            
            return cell
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! StatsHeaderCell
        
        let current = sections[indexPath.section]
        header.headerText.text = current.name
        
        return header
    }
    
}

struct Section {
    var name: String
    var items: StatObject
    var collapsed: Bool
    
    init(name: String, items: StatObject, collapsed: Bool = false) {
        self.name = name
        self.items = items
        self.collapsed = collapsed
    }
    
    func getCount() -> Int{
        let stat = items
        var count = 0
        
        if(!stat.authorized.isEmpty){
            count += 1
        }
        
        if(!stat.currentRank.isEmpty){
            count += 1
        }
        
        if(!stat.gearScore.isEmpty){
            count += 1
        }
        
        if(!stat.killsPVE.isEmpty){
            count += 1
        }
        
        if(!stat.killsPVP.isEmpty){
            count += 1
        }
        
        if(!stat.mostUsedAttacker.isEmpty){
            count += 1
        }
        
        if(!stat.mostUsedDefender.isEmpty){
            count += 1
        }
        
        if(!stat.playerLevelGame.isEmpty){
            count += 1
        }
        
        if(!stat.playerLevelPVP.isEmpty){
            count += 1
        }
        
        if(!stat.setPublic.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedDeaths.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedKills.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedWins.isEmpty){
            count += 1
        }
        
        if(!stat.totalRankedLosses.isEmpty){
            count += 1
        }
        
        return count
    }
}
