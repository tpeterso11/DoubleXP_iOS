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

class ViewTeams: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TeamInteractionCallbacks {
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var gcGameList: UICollectionView!
    @IBOutlet weak var teamResults: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    private var teams = [TeamObject]()
    private var profiles = [FreeAgentObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCurrentUserProfiles()
        
        if(searchField.text != nil && !searchField.text!.isEmpty){
            searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        }
    }
    
    @objc func search(_ sender: AnyObject?) {
           doSearch(teamName: searchField.text!, gameName: nil)
    }
    
    private func loadCurrentUserProfiles(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    for agent in snapshot.children{
                        let currentObj = agent as! DataSnapshot
                        for profile in currentObj.children{
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
                }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func doSearch(teamName: String?, gameName: String?){
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
                        
                        let teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                        let captain = dict["teamCaptain"] as? String ?? ""
                        let imageUrl = dict["imageUrl"] as? String ?? ""
                        let teamChat = dict["teamChat"] as? String ?? String()
                        let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                        let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                        
                        let currentTeam = TeamObject(teamName: currentTeamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                        self.teams.append(currentTeam)
                        
                        if(teamName != nil){
                            break
                        }
                    }
                }
                if(!self.teams.isEmpty){
                    self.teamResults.delegate = self
                    self.teamResults.dataSource = self
                }
                
                for cell in self.gcGameList.visibleCells{
                    let currentCell = cell as! TeamSearchGameCell
                    currentCell.cover.isHidden = true
                    currentCell.isUserInteractionEnabled = true
                }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func addThisTeam(teamName: String?, gameName: String?, games: [String]?, currentTeamName: String?) -> Bool{
        var add = false
        
        if(teamName != nil){
            if(teamName == currentTeamName){
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
        if collectionView == self.gcGameList {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.gcGames.count
        }
        else{
            return self.teams.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == self.gcGameList){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamSearchGameCell
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let game = delegate.gcGames[indexPath.item]
            cell.gameback.moa.url = game.imageUrl
            cell.gameback.contentMode = .scaleAspectFill
            cell.gameback.clipsToBounds = true
            
            cell.gameName.text = game.gameName
            
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
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "teamCell", for: indexPath) as! TeamSearchTeamCell
            let current = self.teams[indexPath.item]
            
            let game = current.games[0]
            var url = ""
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let games = delegate.gcGames!
            for gcGame in games {
                if(gcGame.gameName == game){
                    url = gcGame.imageUrl
                }
            }
            
            cell.gameBack.moa.url = url
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameBack.clipsToBounds = true
            
            cell.gameName.text = game
            
            var contained = false
            var containedProfile: FreeAgentObject?
            
            for profile in self.profiles{
                if(profile.game == game){
                    contained = true
                    containedProfile = profile
                    break
                }
            }
            
            if(contained && !current.selectedTeamNeeds.isEmpty){
                if(current.selectedTeamNeeds.contains((containedProfile?.questions[0][0])!)){
                    cell.sendRequest.isHidden = false
                    cell.sendRequest.tag = indexPath.item
                    cell.sendRequest.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
                    
                    cell.createButton.isHidden = true
                }
                //else need to handle change to "You do not fit this teams needs"
            }
            else if(contained && (current.teamNeeds.isEmpty || current.selectedTeamNeeds.isEmpty)){
                cell.sendRequest.isHidden = false
                cell.sendRequest.tag = indexPath.item
                cell.sendRequest.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
                
                cell.createButton.isHidden = true
            }
            else{
                cell.sendRequest.isHidden = false
                cell.sendRequest.tag = indexPath.item
                cell.sendRequest.addTarget(self, action: #selector(createProfile), for: .touchUpInside)
            }
            
            if(!current.selectedTeamNeeds.isEmpty){
                cell.needs.isHidden = false
                
                var needString = ""
                for need in current.teamNeeds{
                    needString.append(need + " ")
                }
                
                cell.needs.text = needString
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.gcGameList){
            let cell = self.gcGameList.cellForItem(at: indexPath) as! TeamSearchGameCell
            cell.cover.isHidden = false
            
            for otherCell in self.gcGameList.visibleCells{
                if(otherCell != cell){
                    cell.cover.isHidden = false
                    cell.isUserInteractionEnabled = false
                }
            }
            
            self.doSearch(teamName: nil, gameName: cell.gameName.text)
        }
    }
    
    @objc func createProfile(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        let currentTeam = teams[indexPath.item]
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        
        //send to Free Agent Interview
    }
    
    @objc func sendRequest(_ sender: AnyObject?) {
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        let currentTeam = teams[indexPath.item]
        
        let manager = TeamManager()
        manager.sendRequestToJoin(freeAgent: profiles[indexPath.item], team: currentTeam, callbacks: self, indexPath: indexPath)
    }
    
    func successfulRequest(indexPath: IndexPath) {
        //show success
    }
    
}
