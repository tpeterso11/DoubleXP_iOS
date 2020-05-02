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
import Bartinter
import FBSDKCoreKit

class PlayerProfile: ParentVC, UITableViewDelegate, UITableViewDataSource, ProfileCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, RequestsUpdate, UICollectionViewDelegateFlowLayout {
    
    var uid: String = ""
    var userForProfile: User? = nil
    
    var keys = [String]()
    var objects = [GamerConnectGame]()
    var cellHeights: [CGFloat] = []
    
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var profileLine2: UILabel!
    @IBOutlet weak var profileLine3: UILabel!
    @IBOutlet weak var bio: VerticalAlignLabel!
    @IBOutlet weak var statsCollection: UICollectionView!
    @IBOutlet weak var consoleOne: UILabel!
    @IBOutlet weak var consoleTwo: UILabel!
    @IBOutlet weak var headerView: UIView!
    //@IBOutlet weak var connectButton: UIImageView!
    @IBOutlet weak var statEmpty: UIView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var userStatusText: UILabel!
    @IBOutlet weak var mainLayout: UIView!
    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var actionButtonIcon: UIImageView!
    @IBOutlet weak var actionButtonText: UILabel!
    @IBOutlet weak var actionOverlay: UIVisualEffectView!
    @IBOutlet weak var actionDrawer: UIView!
    @IBOutlet weak var bottomBlur: UIVisualEffectView!
    @IBOutlet weak var userStatsLabel: UILabel!
    @IBOutlet weak var tapInstructions: UILabel!
    @IBOutlet weak var sentOverlay: UIView!
    @IBOutlet weak var sentText: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var rivalButton: UIButton!
    
    @IBOutlet weak var rivalSendResultSub: UILabel!
    @IBOutlet weak var rivalSendResultText: UILabel!
    @IBOutlet weak var rivalOverlaySpinner: UIActivityIndicatorView!
    @IBOutlet weak var rivalCoOpSelection: UIView!
    @IBOutlet weak var rivalRivalSelection: UIView!
    @IBOutlet weak var rivalLoadingOverlay: UIView!
    @IBOutlet weak var rivalSendResultOverlay: UIView!
    @IBOutlet weak var rivalOverlay: UIView!
    @IBOutlet weak var rivalBlur: UIVisualEffectView!
    @IBOutlet weak var rivalClose: UIImageView!
    @IBOutlet weak var rivalTypeView: UIView!
    @IBOutlet weak var rivalOverlayHeader: UILabel!
    @IBOutlet weak var rivalGameView: UIView!
    @IBOutlet weak var rivalGameCollection: UICollectionView!
    
    var rivalOverlayPayload = [GamerConnectGame]()
    var sections = [Section]()
    var nav: NavigationPageController?
    
    var rivalSelectedGame = ""
    var rivalSelectedType = ""
    
    var gamesWithStats = [String]()
    
     enum Const {
           static let closeCellHeight: CGFloat = 72
           static let openCellHeight: CGFloat = 280
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard !uid.isEmpty else {
            return
        }
    
        loadUserInfo(uid: uid)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentUser!.uId == self.uid){
            bottomBlur.isHidden = true
            actionButton.isHidden = true
        }
        
        headerView.clipsToBounds = true
        
        self.actionOverlay.effect = nil
        actionOverlay.isHidden = false
        
        self.updatesStatusBarAppearanceAutomatically = true
    }
    
    @objc func messagingButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding!.navigateToMessaging(groupChannelUrl: nil, otherUserId: self.uid)
    }
    
    @objc func receivedButtonClicked(_ sender: AnyObject?) {
        showDrawerAndOverlay()
    }
    
    @objc func acceptClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Accepted"))
        let manager = FriendsManager()
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            for invite in currentUser!.pendingRequests{
                if(self.userForProfile!.uId == invite.uid){
                    manager.acceptFriendFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    break
                }
            }
        }
    }
    
    @objc func declineClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Declined"))
        let manager = FriendsManager()
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            
            for invite in currentUser!.pendingRequests{
                if(self.userForProfile!.uId == invite.uid){
                    manager.declineRequestFromProfile(otherUserRequest: invite, currentUserUid: currentUser!.uId, callbacks: self)
                    break
                }
            }
        }
    }
    
    func onFriendAdded() {
        updateToChatButton()
        dismissDrawerAndOverlay()
    }
    
    func onFriendDeclined() {
        updateToRequestButton()
        dismissDrawerAndOverlay()
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
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                    invites.append(newInvite)
                }
                
                var teammateArray = [TeammateObject]()
                if(currentObj.hasChild("teammates")){
                    let teammates = snapshot.childSnapshot(forPath: "teammates")
                    for invite in teammates.children{
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
                        let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                        teammateArray.append(teammate)
                    }
                }
                
                let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                let captain = dict["teamCaptain"] as? String ?? ""
                let imageUrl = dict["imageUrl"] as? String ?? ""
                let teamChat = dict["teamChat"] as? String ?? String()
                let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                let captainId = dict["teamCaptainId"] as? String ?? String()
                
                let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                currentTeam.teammates = teammateArray
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
                let codKills = dict["codKills"] as? String ?? ""
                let codKd = dict["codKd"] as? String ?? ""
                let codLevel = dict["codLevel"] as? String ?? ""
                let codBestKills = dict["codBestKills"] as? String ?? ""
                let codWins = dict["codWins"] as? String ?? ""
                let codWlRatio = dict["codWlRatio"] as? String ?? ""
                
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
                currentStat.codKills = codKills
                currentStat.codKd = codKd
                currentStat.codLevel = codLevel
                currentStat.codBestKills = codBestKills
                currentStat.codWins = codWins
                currentStat.codWlRatio = codWlRatio
                
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
        
        
        let friendsManager = FriendsManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        if(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)){
            checkRivals()
        }
        else{
            self.rivalButton.alpha = 0
            self.rivalButton.isUserInteractionEnabled = false
        }
        
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
        
        self.setup(gamesEmpty: user.games.isEmpty)
        
        if(friendsManager.checkListsForUser(user: userForProfile!, currentUser: currentUser!)){
            
            if(friendsManager.isInFriendList(user: userForProfile!, currentUser: currentUser!)){
                updateToChatButton()
                
            }
            
            for request in currentUser!.sentRequests{
                if(request.uid == user.uId){
                    updateToPending()
                    break
                }
            }
            
            for request in currentUser!.pendingRequests{
                if(request.uid == user.uId){
                    actionButton.applyGradient(colours:  [#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)], orientation: .horizontal)
                    actionButtonIcon.image = #imageLiteral(resourceName: "new.png")
                    actionButtonText.text = "Received Request!"
                    
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(receivedButtonClicked))
                    actionButton.isUserInteractionEnabled = true
                    actionButton.addGestureRecognizer(singleTap)
                    
                    acceptButton.addTarget(self, action: #selector(acceptClicked), for: .touchUpInside)
                    declineButton.addTarget(self, action: #selector(declineClicked), for: .touchUpInside)
                    break
                }
            }
        }
        else{
            updateToRequestButton()
        }
        
        guard !user.bio.isEmpty else{
            self.bio.text = "This user has not yet created a bio."
            //self.bio.text = "\"" + "I roll with the muh-fuckin rough ridin, ride or dyin, killing ERRRRRYBODY CLAN Xoxx:snfdgXXX" + "\""
            return
        }
        self.bio.text = "\"" + user.bio + "\""
    }
    
    private func setup(gamesEmpty: Bool) {
        if(gamesEmpty){
            self.bottomBlur.isHidden = true
            
            let top = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.statEmpty.alpha = 1
                self.statEmpty.transform = top
            }, completion: nil)
        }
        else{
            let delegate = UIApplication.shared.delegate as! AppDelegate
            for game in self.userForProfile!.games{
                for gcGame in delegate.gcGames{
                    if(game == gcGame.gameName){
                        self.objects.append(gcGame)
                    }
                }
            }
            
            cellHeights = Array(repeating: Const.closeCellHeight, count: self.objects.count)
            table.estimatedRowHeight = Const.closeCellHeight
            table.rowHeight = UITableView.automaticDimension
            
            if #available(iOS 10.0, *) {
                table.refreshControl = UIRefreshControl()
                table.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
            }
            
            self.table.dataSource = self
            self.table.delegate = self
            self.table.contentInset = UIEdgeInsets(top: 0,left: 0,bottom: 50,right: 0)
            
            let top = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.table.alpha = 1
                self.table.transform = top
                self.userStatsLabel.alpha = 1
                self.userStatsLabel.transform = top
                
                self.tapInstructions.alpha = 1
                self.tapInstructions.transform = top
            }, completion: nil)
        }
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
    
    private func updateToChatButton(){
        actionButton.applyGradient(colours:  [#colorLiteral(red: 0, green: 0.4987006783, blue: 0, alpha: 1), #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)], orientation: .horizontal)
        actionButtonIcon.image = #imageLiteral(resourceName: "comment-black-oval-bubble-shape.png")
        actionButtonText.text = "Chat with this user"
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(messagingButtonClicked))
        actionButton.isUserInteractionEnabled = true
        actionButton.addGestureRecognizer(singleTap)
    }
    
    private func updateToRequestButton(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(connectButtonClicked))
        actionButton.applyGradient(colours:  [UIColor(named: "darker")!, .lightGray], orientation: .horizontal)
        actionButtonIcon.image = #imageLiteral(resourceName: "follow.png")
        actionButtonText.text = "Send Friend Request"

        actionButton.isUserInteractionEnabled = true
        actionButton.addGestureRecognizer(singleTap)
    }
    
    private func updateToPending(){
        actionButton.applyGradient(colours:  [#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)], orientation: .horizontal)
        actionButtonIcon.image = #imageLiteral(resourceName: "sand-clock.png")
        actionButtonText.text = "Pending Request"
    }
    
    @objc func connectButtonClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Friend Request Sent"))
        let friendsManager = FriendsManager()
        
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            friendsManager.sendRequestFromProfile(currentUser: currentUser!, otherUser: userForProfile!, callbacks: self)
        }
    }
    
    private func showDrawerAndOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Action Drawer Opened"))
        UIView.animate(withDuration: 0.3, animations: {
            self.actionOverlay.alpha = 1
        } )
        
        let top = CGAffineTransform(translationX: 0, y: -180)
        UIView.animate(withDuration: 0.5, animations: {
            self.actionDrawer.alpha = 1
              self.actionDrawer.transform = top
        }, completion: nil)
        
        //let singleTap = UITapGestureRecognizer(target: self, action: #selector(dismissDrawerAndOverlay))
        //clickArea.isUserInteractionEnabled = true
        //clickArea.addGestureRecognizer(singleTap)
    }
    
    @objc private func dismissDrawerAndOverlay(){
        AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - Action Drawer Closed"))
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
              self.actionDrawer.transform = top
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, delay: 0.5,animations: {
            self.actionOverlay.effect = nil
        } )
        
        actionOverlay.isUserInteractionEnabled = false
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
        let current = self.objects[indexPath.item]
        
        cell.gameName.text = ""
        cell.developer.text = ""
        
        cell.gameBack.moa.url =  current.imageUrl
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        cell.gameName.text = current.gameName
        cell.developer.text = current.developer
        
        cell.statsAvailable.isHidden = true
        
        for stat in self.userForProfile!.stats{
            if(stat.gameName == current.gameName){
                self.objects[indexPath.item].stats = stat
                cell.setCollectionView(stat: stat)
                cell.statsAvailable.isHidden = false
                
                self.gamesWithStats.append(stat.gameName)
            }
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let current = self.objects[indexPath.item]
        if(self.gamesWithStats.contains(current.gameName)){
            let cell = tableView.cellForRow(at: indexPath) as! FoldingCell

            if cell.isAnimating() {
                return
            }

            var duration = 0.0
            let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
            if cellIsCollapsed {
                AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - View Stats (Open)"))
                cellHeights[indexPath.row] = Const.openCellHeight
                cell.unfold(true, animated: true, completion: nil)
                duration = 0.6
            } else {
                AppEvents.logEvent(AppEvents.Name(rawValue: "Friend Profile - View Stats (Close)"))
                cellHeights[indexPath.row] = Const.closeCellHeight
                cell.unfold(false, animated: true, completion: nil)
                duration = 0.3
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
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.rivalOverlayPayload.count
    }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
        
        let game = self.rivalOverlayPayload[indexPath.item]
           cell.backgroundImage.moa.url = game.imageUrl
           cell.backgroundImage.contentMode = .scaleAspectFill
           cell.backgroundImage.clipsToBounds = true
           
           cell.hook.text = game.gameName
           AppEvents.logEvent(AppEvents.Name(rawValue: "Player Profile Rival " + game.gameName + " Click"))
           
           cell.contentView.layer.cornerRadius = 2.0
           cell.contentView.layer.borderWidth = 1.0
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
        let current = self.rivalOverlayPayload[indexPath.item]
        
        self.rivalSelectedGame = current.gameName
        
        self.progressRival()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.rivalGameCollection.bounds.width - 10, height: CGFloat(80))
    }
    
    func onFriendRequested(){
        let top = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.5, animations: {
            self.sentOverlay.alpha = 1
            self.updateToPending()
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.sentText.transform = top
                self.sentText.alpha = 1
            }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                        self.sentOverlay.alpha = 0
                    }, completion: nil)
                }
            })
        })
    }
    
    private func roundCorners(cornerRadius: Double, view: UIView) {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }
    
    private func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private func convertTeammates(list: [String], userUid: String, teamName: String, game: String) -> [TeammateObject]{
        var newArray = [TeammateObject]()
        let manager = GamerProfileManager()
        let tempTeammates = list
        if(!tempTeammates.isEmpty){
            for teammate in tempTeammates{
                let ref = Database.database().reference().child("Users").child(teammate)
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let _ = snapshot.value as? NSDictionary
                        let uId = snapshot.key
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
            
                        let newTeammate = TeammateObject(gamerTag: manager.getGamerTagForGame(gameName: game), date: "", uid: uId)
                        newArray.append(newTeammate)
                })
                { (error) in
                    print(error.localizedDescription)
                }
            }
                        
            var teammates = [Dictionary<String, String>]()
            for user in newArray{
                let current = ["gamerTag": user.gamerTag, "date": user.date, "uid": user.uid]
                teammates.append(current)
            }
            
            if(!teammates.isEmpty){
                let ref = Database.database().reference().child("Users").child(userUid).child("teams")
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    for userTeam in snapshot.children{
                        let currentObj = userTeam as! DataSnapshot
                        let dict = currentObj.value as! [String: Any]
                        let teamName = dict["teamName"] as? String ?? ""
                        
                        if(teamName == teamName){
                            ref.child(userUid).child("teams").child(currentObj.key).child("teammates").setValue(teammates)
                            break
                        }
                    }
                })
                
                let teamRef = Database.database().reference().child("Teams")
                teamRef.child(teamName).child("teammates").setValue(teammates)
            }
        }
        return newArray
    }
    
    @objc private func rivalClicked(){
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(self.closeOverlay))
        self.rivalClose.isUserInteractionEnabled = true
        self.rivalClose.addGestureRecognizer(closeTap)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalBlur.alpha = 1
            
            self.rivalGameCollection.dataSource = self
            self.rivalGameCollection.delegate = self
        }, completion: { (finished: Bool) in
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.rivalOverlay.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc private func closeOverlay(){
        UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
            self.rivalOverlay.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                self.rivalBlur.alpha = 0
            }, completion: nil)
        })
    }
    
    private func progressRival(){
        let top = CGAffineTransform(translationX: -(self.rivalGameView.bounds.width), y: 0)
        
        UIView.transition(with: self.rivalOverlayHeader,
             duration: 0.3,
              options: .transitionCrossDissolve,
           animations: { [weak self] in
               self?.rivalOverlayHeader.text = "how are you wanting to play?"
         }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, animations: {
                self.rivalGameView.transform = top
                self.rivalGameView.alpha = 0
            }, completion: { (finished: Bool) in
                let coOpTap = UITapGestureRecognizer(target: self, action: #selector(self.coOpClicked))
                self.rivalCoOpSelection.isUserInteractionEnabled = true
                self.rivalCoOpSelection.addGestureRecognizer(coOpTap)
                
                let rivalTap = UITapGestureRecognizer(target: self, action: #selector(self.rivalOptionlicked))
                self.rivalRivalSelection.isUserInteractionEnabled = true
                self.rivalRivalSelection.addGestureRecognizer(rivalTap)
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.rivalTypeView.alpha = 1
                }, completion: nil)
            })
        })
    }
    
    @objc private func coOpClicked(){
        self.rivalLoadingOverlay.backgroundColor = UIColor(named: "greenAlpha")
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            self.rivalOverlaySpinner.startAnimating()
            self.rivalSelectedType = "co-op"
            
            self.sendPayload()
        }, completion: nil)
    }
    
    @objc private func rivalOptionlicked(){
        self.rivalLoadingOverlay.backgroundColor = UIColor(named: "redAlpha")
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            self.rivalOverlaySpinner.startAnimating()
            self.rivalSelectedType = "rival"
            
            self.sendPayload()
        }, completion: nil)
    }
    
    private func sendPayload(){
        let manager = FriendsManager()
        manager.createRivalRequest(otherUser: self.userForProfile!, game: self.rivalSelectedGame, type: self.rivalSelectedType, callbacks: self, gamerTags: self.userForProfile!.gamerTags)
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalResponseAccepted(indexPath: IndexPath) {
    }
    
    func rivalResponseRejected(indexPath: IndexPath) {
    }
    
    func rivalResponseFailed() {
    }
    
    func rivalRequestSuccess() {
        self.rivalSendResultText.text = "sent!"
        self.rivalSendResultSub.text = "one step closer."
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 0
            }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                self.rivalSendResultOverlay.alpha = 1
            }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                        self.rivalOverlay.alpha = 0
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                            self.rivalBlur.alpha = 0
                        
                            self.self.rivalButton.alpha = 0.3
                            self.rivalButton.isUserInteractionEnabled = false
                        
                            if(self.rivalSelectedType == "co-op"){
                                UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                                    self.rivalButton.backgroundColor = UIColor(named: "greenToDarker")
                                    self.headerView.backgroundColor = UIColor(named: "greenToDarker")
                                }, completion: nil)
                            }
                        else{
                            UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                                 self.rivalButton.backgroundColor = UIColor(named: "redToDark")
                                 self.headerView.backgroundColor = UIColor(named: "redToDark")
                            }, completion: nil)
                        }
                    }, completion: nil)
                })
            })
        })
    }
    
    func rivalRequestFail() {
        self.rivalSendResultText.text = "error!"
        self.rivalSendResultSub.text = "our bad. please try again."
        
        UIView.animate(withDuration: 0.8, animations: {
            self.rivalLoadingOverlay.alpha = 1
            }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                self.rivalSendResultOverlay.alpha = 1
            }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                        self.rivalOverlay.alpha = 0
                    }, completion: { (finished: Bool) in
                      UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.rivalBlur.alpha = 1
                    }, completion: nil)
                })
            })
        })
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        var currentRival: RivalObj?
        
        var alreadyARival = false
        for rival in currentUser.currentTempRivals{
            let dbDate = self.stringToDate(rival.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let nowString = formatter.string(from: now as Date)
                let nowDate = self.stringToDate(nowString)
                let dbFuture = dbDate.adding(minutes: 10)
                
                let validRival = nowDate.compare(.isEarlier(than: dbFuture))
                
                if(dbFuture != nil){
                    if(!validRival){
                        currentUser.currentTempRivals.remove(at: currentUser.currentTempRivals.index(of: rival)!)
                    }
                    else{
                        if(rival.uid == userForProfile!.uId){
                            alreadyARival = true
                            currentRival = rival
                        }
                    }
                }
            }
        }
        
        for rival in currentUser.tempRivals{
            let dbDate = self.stringToDate(rival.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let future = formatter.string(from: now as Date)
                let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                
                let validRival = dbDate.compareCloseTo(dbFuture, precision: 10.minutes.timeInterval)
                
                if(dbFuture != nil){
                    if(!validRival){
                        currentUser.tempRivals.remove(at: currentUser.tempRivals.index(of: rival)!)
                    }
                    else{
                        if(rival.uid == userForProfile!.uId){
                            alreadyARival = true
                            currentRival = rival
                        }
                    }
                }
            }
        }
        
        var contained = false
        var gcPayload = [String]()
        for game in userForProfile!.gamerTags{
            for currentUserGame in delegate.currentUser!.gamerTags{
                if (game.game == currentUserGame.game && !game.gamerTag.isEmpty){
                    contained = true
                    gcPayload.append(game.game)
                }
            }
        }
        
        if(contained && !alreadyARival){
            rivalButton.alpha = 1
            rivalButton.addTarget(self, action: #selector(rivalClicked), for: .touchUpInside)
            rivalButton.isUserInteractionEnabled = true
            
            checkGames(payload: gcPayload)
        }
        else if(contained && alreadyARival){
            rivalButton.alpha = 0.3
            rivalButton.isUserInteractionEnabled = false
            
            if(currentRival != nil){
                if(currentRival!.type == "co-op"){
                    UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                        self.rivalButton.titleLabel?.text = "co-op"
                        self.rivalButton.backgroundColor = UIColor(named: "greenToDarker")
                        self.headerView.backgroundColor = UIColor(named: "greenToDarker")
                    }, completion: nil)
                }
                else{
                    UIView.transition(with: self.headerView, duration: 0.3, options: .curveEaseInOut, animations: {
                        self.rivalButton.titleLabel?.text = "rival"
                        self.rivalButton.backgroundColor = UIColor(named: "redToDark")
                        self.headerView.backgroundColor = UIColor(named: "redToDark")
                    }, completion: nil)
                }
            }
        }
        else{
            rivalButton.alpha = 0
            rivalButton.isUserInteractionEnabled = false
        }
    }
    
    
    private func checkGames(payload: [String]){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        for game in delegate.gcGames{
            if(payload.contains(game.gameName)){
                self.rivalOverlayPayload.append(game)
            }
        }
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
        
        if(!stat.codKd.isEmpty){
            count += 1
        }
        if(!stat.codWins.isEmpty){
            count += 1
        }
        if(!stat.codWlRatio.isEmpty){
            count += 1
        }
        if(!stat.codKills.isEmpty){
            count += 1
        }
        if(!stat.codBestKills.isEmpty){
            count += 1
        }
        if(!stat.codLevel.isEmpty){
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

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIView {
    @discardableResult
    func applyGradient(colours: [UIColor]) -> CAGradientLayer {
        return self.applyGradient(colours: colours, locations: nil)
    }

    @discardableResult
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        gradient.cornerRadius = 20
        self.layer.insertSublayer(gradient, at: 0)
        return gradient
    }
    
    func applyGradient(colours: [UIColor], orientation: GradientOrientation) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        gradient.cornerRadius = 20
        self.layer.insertSublayer(gradient, at: 0)
    }
}

extension UIVisualEffectView {

    func fadeInEffect(_ style:UIBlurEffect.Style = .light, withDuration duration: TimeInterval = 1.0) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: duration, curve: .easeIn) {
                self.effect = UIBlurEffect(style: style)
            }

            animator.startAnimation()
        }else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.effect = UIBlurEffect(style: style)
            }
        }
    }

    func fadeOutEffect(withDuration duration: TimeInterval = 1.0) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                self.effect = nil
            }

            animator.startAnimation()
            animator.fractionComplete = 1
        }else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.effect = nil
            }
        }
    }

}

extension Date {
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}
