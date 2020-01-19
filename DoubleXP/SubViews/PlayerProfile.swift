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

class PlayerProfile: ParentVC, UITableViewDelegate, UITableViewDataSource, ProfileCallbacks {
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
    @IBOutlet weak var acceptButton: UIView!
    @IBOutlet weak var declineButton: UIView!
    
    
    var sections = [Section]()
    var nav: NavigationPageController?
    
     enum Const {
           static let closeCellHeight: CGFloat = 72
           static let openCellHeight: CGFloat = 235
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
        
        currentLanding?.removeBottomNav(showNewNav: true, hideSearch: true, searchHint: "Search for player")
        
        headerView.clipsToBounds = true
        mainLayout.roundCorners(corners: [.topLeft, .topRight], radius: 20)
        actionDrawer.roundCorners(corners: [.topLeft, .topRight], radius: 40)
        
        self.actionOverlay.effect = nil
        actionOverlay.isHidden = false
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
            self.statEmpty.isHidden = true
            self.setup()
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let friendsManager = FriendsManager()
        
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
                    
                    acceptButton.applyGradient(colours:  [#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)], orientation: .horizontal)
                    declineButton.applyGradient(colours:  [#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1), #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)], orientation: .horizontal)
                    
                    let acceptTap = UITapGestureRecognizer(target: self, action: #selector(acceptClicked))
                    acceptButton.isUserInteractionEnabled = true
                    acceptButton.addGestureRecognizer(acceptTap)
                    
                    let declineTap = UITapGestureRecognizer(target: self, action: #selector(declineClicked))
                    declineButton.isUserInteractionEnabled = true
                    declineButton.addGestureRecognizer(declineTap)
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
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: self.objects.count)
        table.estimatedRowHeight = Const.closeCellHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = UIColor.white
        
        if #available(iOS 10.0, *) {
            table.refreshControl = UIRefreshControl()
            table.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
        
        //statEmpty.isHidden = true
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
        actionButton.applyGradient(colours:  [.darkGray, .lightGray], orientation: .horizontal)
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
        let friendsManager = FriendsManager()
        
        if(self.userForProfile != nil){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let currentUser = delegate.currentUser
            friendsManager.sendRequestFromProfile(currentUser: currentUser!, otherUser: userForProfile!)
        }
    }
    
    private func showDrawerAndOverlay(){
        UIView.animate(withDuration: 0.7, animations: {
            self.actionOverlay.effect = UIBlurEffect(style: .regular)
        } )
        
        let top = CGAffineTransform(translationX: 0, y: -135)
        UIView.animate(withDuration: 0.4, delay: 1.3, options: [], animations: {
              self.actionDrawer.transform = top
        }, completion: nil)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(dismissDrawerAndOverlay))
        actionOverlay.isUserInteractionEnabled = true
        actionOverlay.addGestureRecognizer(singleTap)
    }
    
    @objc private func dismissDrawerAndOverlay(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
              self.actionDrawer.transform = top
        }, completion: nil)
        
        UIView.animate(withDuration: 0.7, delay: 0.5,animations: {
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let games = appDelegate.gcGames!
        let current = self.objects[indexPath.item]
        
        cell.gameName.text = ""
        cell.developer.text = ""
        
        for game in games{
            if(game.gameName == current.gameName){
                cell.gameBack.moa.url = game.imageUrl
                cell.gameBack.contentMode = .scaleAspectFill
                cell.gameBack.clipsToBounds = true
                
                cell.gameName.text = game.gameName
                cell.developer.text = game.developer
            }
        }
        
        cell.setCollectionView(stat: current)
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
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
            duration = 0.6
        } else {
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
