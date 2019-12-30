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
import FoldingCell

class PlayerProfile: ParentVC, UITableViewDelegate, UITableViewDataSource {
    var uid: String = ""
    var userForProfile: User? = nil
    
    var keys = [String]()
    var objects = [StatObject]()
    var cellHeights: [CGFloat] = []
    
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var profileLine2: UILabel!
    @IBOutlet weak var profileLine3: UILabel!
    @IBOutlet weak var bio: VerticalAlignLabel!
    @IBOutlet weak var statsCollection: UICollectionView!
    @IBOutlet weak var consoleOne: UILabel!
    @IBOutlet weak var consoleTwo: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var connectButton: UIImageView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var statEmpty: UIView!
    @IBOutlet weak var userStatusText: UILabel!
    
    var sections = [Section]()
    var nav: NavigationPageController?
    
     enum Const {
           static let closeCellHeight: CGFloat = 150
           static let openCellHeight: CGFloat = 300
           static let rowsCount = 1
    }
    
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
                
                self.objects.append(currentStat)
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
            user.stats = self.objects
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
            self.setup()
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
                
                userStatusText.text = "This user is your friend. Tap here to chat."
            }
            
            for request in currentUser!.sentRequests{
                if(request.uid == user.uId){
                    connectButton.image = UIImage(named: "pending_button")
                    userStatusText.text = "Your request has been sent. Just waiting for a response..."
                    break
                }
            }
            
            for request in currentUser!.pendingRequests{
                if(request.uid == user.uId){
                    connectButton.image = UIImage(named: "pending_button")
                    userStatusText.text = "Your request has been sent. Just waiting for a response..."
                    break
                }
            }
        }
        else{
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(connectButtonClicked))
            connectButton.isUserInteractionEnabled = true
            connectButton.addGestureRecognizer(singleTap)
            
            userStatusText.text = "Tap to send a friend request to this user."
        }
        
        guard !user.bio.isEmpty else{
            //self.bio.text = "This user has not yet created a bio."
            self.bio.text = "I roll with the muh-fuckin rough ridin, ride or dyin, killing ERRRRRYBODY CLAN Xoxx:snfdgXXX"
            return
        }
        self.bio.text = user.bio
    }
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: self.objects.count)
        table.estimatedRowHeight = Const.closeCellHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = UIColor.white
        
        if #available(iOS 10.0, *) {
            table.refreshControl = UIRefreshControl()
            table.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
        
        statEmpty.isHidden = true
        self.table.dataSource = self
        self.table.delegate = self
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.table.refreshControl?.endRefreshing()
            }
            self?.table.reloadData()
        })
    }
    
    @objc func connectButtonClicked(_ sender: AnyObject?) {
        let friendsManager = FriendsManager()
        
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            friendsManager.sendRequestFromProfile(currentUser: currentUser!, otherUser: userForProfile!)
        }
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.objects.count
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as FoldingCellCell = cell else {
            return
        }

        cell.backgroundColor = .clear

        if cellHeights[indexPath.row] == Const.closeCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }

        //cell.number = indexPath.row
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FoldingCellCell
        let durations: [TimeInterval] = [0.26, 0.2, 0.2]
        cell.durationsForExpandedState = durations
        cell.durationsForCollapsedState = durations
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let games = appDelegate.gcGames!
        let current = self.objects[indexPath.item]
        
        for game in games{
            if(game.gameName == current.gameName){
                cell.gameBack.moa.url = game.imageUrl
                cell.gameBack.contentMode = .scaleAspectFill
                cell.gameBack.clipsToBounds = true
            }
        }
        
        cell.setCollectionView(stat: current)
        
        
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! FoldingCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.5
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > tableView.frame.maxY {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: nil)
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

fileprivate struct C {
  struct CellHeight {
    static let close: CGFloat = 91 // equal or greater foregroundView height
    static let open: CGFloat = 166 // equal or greater containerView height
  }
}
