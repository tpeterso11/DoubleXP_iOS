//
//  ViewTeams.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation
import SwiftNotificationCenter

class ViewTeams: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, SearchCallbacks {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var gcGameList: UICollectionView!
    @IBOutlet weak var teamResults: UITableView!
    private var chosenGame = ""
    private var gcGames = [GamerConnectGame]()
    private var teams = [TeamObject]()
    private var profiles = [FreeAgentObject]()
    @IBOutlet weak var instructionView: UIView!
    @IBOutlet weak var searchingText: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var cover: UIView!
    var setupComplete = false
    
    enum Const {
           static let closeCellHeight: CGFloat = 119
           static let openCellHeight: CGFloat = 205
           static let rowsCount = 1
    }
    var cellHeights: [CGFloat] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCurrentUserProfiles()
        
        gcGameList.delegate = self
        gcGameList.dataSource = self
        
        gcGameList.layer.shadowColor = UIColor.black.cgColor
        gcGameList.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        gcGameList.layer.shadowRadius = 2.0
        gcGameList.layer.shadowOpacity = 0.5
        gcGameList.layer.masksToBounds = false
        gcGameList.layer.shadowPath = UIBezierPath(roundedRect: gcGameList.bounds, cornerRadius: gcGameList.layer.cornerRadius).cgPath
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        navDictionary = ["state": "search", "searchHint": "Find A Team", "searchButton": "Search"]
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        
        self.pageName = "View Teams"
        delegate.addToNavStack(vc: self)
        
        gcGames.append(contentsOf: delegate.gcGames)
        
        Broadcaster.register(SearchCallbacks.self, observer: self)
        //if(searchField.text != nil && !searchField.text!.isEmpty){
        //    searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        //}
    }
    
    func search(searchString: String?) {
        let color = UIColor(named: "darkOpacity")
        UIView.transition(with: self.cover, duration: 0.3, options: .curveEaseInOut, animations: {
            self.cover.backgroundColor = color
            self.cover.backgroundColor = color
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.searchingText.text = "one sec..."
            self.cover.alpha = 1
            self.instructionView.alpha = 0
            self.teamResults.alpha = 0
            //self.teamResults.transform = returnV
        }, completion: { (finished: Bool) in
             UIView.animate(withDuration: 0.8, animations: {
                self.searchingText.alpha = 1
                self.spinner.alpha = 1
                self.spinner.startAnimating()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.doSearch(teamName: searchString, gameName: self.chosenGame)
                }
            })
        })
    }
    
    private func loadCurrentUserProfiles(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.profiles = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for profile in snapshot.children{
                    let currentProfile = profile as! DataSnapshot
                    let dict = currentProfile.value as! [String: Any]
                    let game = dict["game"] as? String ?? ""
                    let consoles = dict["consoles"] as? [String] ?? [String]()
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let competitionId = dict["competitionId"] as? String ?? ""
                    let userId = dict["userId"] as? String ?? ""
                    let questions = dict["questions"] as? [[String]] ?? [[String]]()
                    
                    let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                    self.profiles.append(result)
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func doSearch(teamName: String?, gameName: String?){
        self.teams.removeAll()
        self.teamResults.reloadData()
        
        let ref = Database.database().reference().child("Teams")
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                for team in snapshot.children{
                    let currentObj = team as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let currentTeamName = dict["teamName"] as? String ?? ""
                    let teamId = dict["teamId"] as? String ?? ""
                    let games = dict["games"] as? [String] ?? [String]()
                    
                    if(self.addThisTeam(teamName: teamName, gameName: gameName, games: games, currentTeamName: currentTeamName)){
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
                        
                        var dbRequests = [RequestObject]()
                         let teamRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                         for invite in teamRequests.children{
                            let currentObj = invite as! DataSnapshot
                            let dict = currentObj.value as! [String: Any]
                            let status = dict["status"] as? String ?? ""
                            let teamId = dict["teamId"] as? String ?? ""
                            let teamName = dict["teamName"] as? String ?? ""
                            let captainId = dict["captainId"] as? String ?? ""
                            let requestId = dict["requestId"] as? String ?? ""
                             
                             let requestsArray = snapshot.childSnapshot(forPath: "inviteRequests")
                             var requestProfiles = [FreeAgentObject]()
                             for requestObj in requestsArray.children {
                                 let currentObj = requestObj as! DataSnapshot
                                 let dict = currentObj.value as! [String: Any]
                                 let game = dict["game"] as? String ?? ""
                                 let consoles = dict["consoles"] as? [String] ?? [String]()
                                 let gamerTag = dict["gamerTag"] as? String ?? ""
                                 let competitionId = dict["competitionId"] as? String ?? ""
                                 let userId = dict["userId"] as? String ?? ""
                                 let questions = dict["questions"] as? [[String]] ?? [[String]]()
                                 
                                 let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                                 
                                 requestProfiles.append(result)
                             }
                             
                             let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                             newRequest.profile = requestProfiles[0]
                             
                             dbRequests.append(newRequest)
                        }
                        
                        let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                        let captain = dict["teamCaptain"] as? String ?? ""
                        let imageUrl = dict["imageUrl"] as? String ?? ""
                        let teamChat = dict["teamChat"] as? String ?? String()
                        let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                        let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                        
                        let currentTeam = TeamObject(teamName: currentTeamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                        currentTeam.teammates = teammateArray
                        currentTeam.requests = dbRequests
                        
                        self.teams.append(currentTeam)
                        
                        if(teamName != nil){
                            break
                        }
                    }
                }
                if(!self.teams.isEmpty && !self.setupComplete){
                    self.setup()
                    
                    self.setupComplete = true
                }
                else if(!self.teams.isEmpty){
                    UIView.animate(withDuration: 0.5, animations: {
                        self.searchingText.alpha = 1
                        self.spinner.alpha = 1
                        //self.teamResults.transform = returnV
                    }, completion: { (finished: Bool) in
                         UIView.animate(withDuration: 0.8, animations: {
                            self.teamResults.alpha = 1
                            self.cover.alpha = 0
                        }, completion: { (finished: Bool) in
                            self.cellHeights = Array(repeating: Const.closeCellHeight, count: (self.teams.count))
                            self.teamResults.performBatchUpdates({
                                let indexSet = IndexSet(integersIn: 0...0)
                                self.teamResults.reloadSections(indexSet, with: .fade)
                             }, completion: nil)
                        })
                    })
                }
                else{
                    self.showEmpty()
                    //self.showEmpty()
                }
        }) { (error) in
            print(error.localizedDescription)
            self.showError()
        }
    }
    
    private func addThisTeam(teamName: String?, gameName: String?, games: [String]?, currentTeamName: String?) -> Bool{
        var add = false
        
        if(teamName != nil && currentTeamName != nil){
            if(teamName!.caseInsensitiveCompare(currentTeamName!.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame){
                add = true
            }
        }
        
        if(games != nil){
            if((games?.contains(gameName!))!){
                add = true
            }
        }
        
        return add
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.gcGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! homeGCCell
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let game = delegate.gcGames[indexPath.item]
        cell.searchName = game.gameName
        
        if(game.cachedImage.imageData != nil){
            cell.backgroundImage.image = game.cachedImage
            cell.backgroundImage.contentMode = .scaleAspectFill
            cell.backgroundImage.clipsToBounds = true
        }
        else{
            cell.backgroundImage.moa.onSuccess = { image in
                game.cachedImage = image
                
              return image
            }

            cell.backgroundImage.moa.url = game.imageUrl
            cell.backgroundImage.contentMode = .scaleAspectFill
            cell.backgroundImage.clipsToBounds = true
        }
        
        cell.hook.text = game.secondaryName
        
        if(self.chosenGame == game.gameName){
            cell.cover.isHidden = false
            cell.isUserInteractionEnabled = false
        }
        else{
            cell.cover.isHidden = true
            cell.isUserInteractionEnabled = true
        }
        
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
        let cell = self.gcGameList.cellForItem(at: indexPath) as! homeGCCell
        cell.cover.isHidden = false
        
        let current = self.gcGames[indexPath.item]
        current.cachedImage = cell.backgroundImage.image ?? UIImage()
        
        //self.gcGameList.reloadItems(at: [indexPath])
        self.gcGameList.reloadData()
        for cell in self.gcGameList.visibleCells{
            if((cell as! homeGCCell).searchName != self.chosenGame){
                (cell as! homeGCCell).cover.isHidden = true
            }
        }
        
        self.chosenGame = self.gcGames[indexPath.item].gameName
        
        self.search(searchString: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
            
        return CGSize(width: collectionView.bounds.size.width - 10, height: CGFloat(80))
    }
    
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.teams.count
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as ViewTeamsFoldingCell = cell else {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ViewTeamsFoldingCell
        
        let current = self.teams[indexPath.item]
        
        cell.gameBack.backgroundColor = UIColor(named: "whiteBackToDarkGrey")
        //cell.gameBack.moa.url = current.imageUrl
        //cell.gameBack.contentMode = .scaleAspectFill
        //cell.gameBack.clipsToBounds = true
        
        cell.underImage.moa.url = current.imageUrl
        cell.underImage.contentMode = .scaleAspectFill
        cell.underImage.clipsToBounds = true
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var contained = false
        for request in current.requests{
            if(request.profile.userId == delegate.currentUser!.uId){
                cell.requestStatusOverlay.alpha = 1
                cell.isUserInteractionEnabled = false
                contained = true
                break
            }
        }
        
        if(!contained){
            cell.setUI(team: current, profiles: self.profiles, gameName: current.games[0], indexPath: indexPath, collectionView: teamResults)
        }
        
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! ViewTeamsFoldingCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            duration = 0.6
            cell.unfold(true, animated: true, completion: nil)
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            duration = 0.3
            cell.unfold(false, animated: true, completion: nil)
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
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.teamResults.refreshControl?.endRefreshing()
            }
            self?.teamResults.reloadData()
        })
    }
    
    func reload(tableView: UITableView) {
        if(tableView == teamResults){
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.layoutIfNeeded()
            tableView.setContentOffset(contentOffset, animated: false)
        }
    }
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: (self.teams.count))
        teamResults.estimatedRowHeight = Const.closeCellHeight
        teamResults.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            teamResults.refreshControl = UIRefreshControl()
            teamResults.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
        
        self.teamResults.dataSource = self
        self.teamResults.delegate = self
        
        UIView.animate(withDuration: 0.5, animations: {
            self.searchingText.alpha = 1
            self.spinner.alpha = 1
            //self.teamResults.transform = returnV
        }, completion: { (finished: Bool) in
             UIView.animate(withDuration: 0.8, animations: {
                self.teamResults.alpha = 1
                self.cover.alpha = 0
            }, completion: { (finished: Bool) in
                self.reload(tableView: self.teamResults)
            })
        })
    }
    
    private func showEmpty(){
        self.spinner.alpha = 0
        
        let color = UIColor(named: "darkOpacity")
        UIView.transition(with: self.cover, duration: 0.3, options: .curveEaseInOut, animations: {
            self.cover.backgroundColor = color
            self.cover.backgroundColor = color
        }, completion: nil)
        
        self.searchingText.text = "no teams available right now..."
        UIView.animate(withDuration: 0.5, animations: {
            self.cover.alpha = 1
            self.searchingText.alpha = 1
            //self.teamResults.transform = returnV
        }, completion: { (finished: Bool) in
             UIView.animate(withDuration: 0.8, animations: {
                self.teamResults.alpha = 0
                self.searchingText.alpha = 1
            }, completion: nil)
        })
    }
    
    private func showError(){
        self.searchingText.text = "we had an issue getting teams for you..."
        
        let color = UIColor(named: "redAlpha")
        UIView.transition(with: self.cover, duration: 0.3, options: .curveEaseInOut, animations: {
            self.cover.backgroundColor = color
            self.cover.backgroundColor = color
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.spinner.alpha = 0
            self.cover.alpha = 1
            self.searchingText.alpha = 1
            //self.teamResults.transform = returnV
        }, completion: { (finished: Bool) in
             UIView.animate(withDuration: 0.8, animations: {
                self.teamResults.alpha = 0
                self.searchingText.alpha = 1
            }, completion: nil)
        })
    }
    
    func searchSubmitted(searchString: String) {
        self.search(searchString: searchString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
}
