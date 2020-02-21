//
//  TeamManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class TeamManager{
    
    func isTeamCaptain(user: User, team: TeamObject) -> Bool{
        var isCaptain = false
        let manager = GamerProfileManager()
        
        for gamerTag in manager.getAllTags(user: user){
            if(gamerTag == team.teamCaptain){
                isCaptain = true
                break
            }
        }
        
        return isCaptain
    }
    
    func inviteToTeam(team: TeamObject, friend: FriendObject, position: IndexPath, callbacks: TeamCallbacks){
        //First, add the invite to the team.
        
        let ref = Database.database().reference().child("Teams").child(team.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
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
                
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM.dd.yyyy"
                let result = formatter.string(from: date)
                
                let currentInvite = TeamInviteObject(gamerTag: friend.gamerTag, date: result, uid: friend.uid)
                invites.append(currentInvite)
                
                var sendList = [[String: Any]]()
                for invite in invites{
                    let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid] as [String : String]
                    sendList.append(current)
                }
                
                let dict = snapshot.value as! [String: Any]
                var teamInvitetags = dict["teamInviteTags"] as? [String] ?? [String]()
                teamInvitetags.append(friend.gamerTag)
                
                ref.child("teamInvites").setValue(sendList)
                ref.child("teamInviteTags").setValue(teamInvitetags)
                
                
                self.updateUserTeamInvite(team: team, friend: friend, position: position, callbacks: callbacks)
                
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateUserTeamInvite(team: TeamObject, friend: FriendObject, position: IndexPath, callbacks: TeamCallbacks){
        //finally, we update the user object to show invite
        
        
        let ref = Database.database().reference().child("Users").child(friend.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var currentInvites = [TeamObject]()
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    
                    /*
                    self.teamInvites = teamInvites*/
                    
                    let teamName = dict["teamName"] as? String ?? ""
                    let teamId = dict["teamId"] as? String ?? ""
                    let games = dict["games"] as? [String] ?? [String]()
                    let consoles = dict["consoles"] as? [String] ?? [String]()
                    let teamNeeds = dict["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict["selectedTeamNeeds"] as? [String] ?? [String]()
                    let teamInviteTags = dict["teamInviteTags"] as? [String] ?? [String]()
                    let teammateIds = dict["teammateIds"] as? [String] ?? [String]()
                    let teammateTags = dict["teammateTags"] as? [String] ?? [String]()
                    let teamCaptain = dict["teamCaptain"] as? String ?? ""
                    let imageUrl = dict["imageUrl"] as? String ?? ""
                    let teamChat = dict["teamChat"] as? String ?? ""
                    
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
                    let teammates = snapshot.childSnapshot(forPath: "teammates")
                    for teammate in teammates.children{
                        let currentTeammate = teammate as! DataSnapshot
                        let dict = currentTeammate.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
                        let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                        teammateArray.append(teammate)
                    }
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: teamCaptain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInviteTags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl)
                    currentTeam.teammates = teammateArray
                    
                    currentInvites.append(currentTeam)
                }
                //Got all the teams from the DB, now lets add our team.
                currentInvites.append(team)
                
                //convert them and send them back.
                var sendInvites = [[String: Any]]()
                for team in currentInvites{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamInvites": self.convertInvitesToSendableValue(invites: team.teamInvites), "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl] as [String : Any]
                    
                    sendInvites.append(current)
                }
            
                ref.child(team.teamName).child("teamInvites").setValue(sendInvites)
                
                callbacks.updateCell(indexPath: position)
                
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertInvitesToSendableValue(invites: [TeamInviteObject]) -> [[String: Any]]{
        var array = [[String: Any]]()
        
        for invite in invites{
            let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid] as [String : String]
            array.append(current)
        }
        
        return array
    }
    
    func sendRequestToJoin(freeAgent: FreeAgentObject, team: TeamObject, callbacks: TeamInteractionCallbacks, indexPath: IndexPath){
        //First, lets update thhe team.
        
        let ref = Database.database().reference().child("Teams").child(team.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let request = RequestObject(status: "PENDING", teamId: team.teamId, teamName: team.teamName, captainId: team.teamCaptain, requestId: "\(self.generateRandomDigits(6))")
                request.profile = freeAgent
                
                guard !request.profile.game.isEmpty else {
                    return
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
                
                for dbRequest in dbRequests{
                    if(dbRequest.profile.userId == request.profile.userId){
                        //show error, already there
                        return
                    }
                }
                
                dbRequests.append(request)
                
                var putBackRequests = [[String: Any]]()
                for request in dbRequests{
                    let profile = ["game": request.profile.game, "consoles": request.profile.consoles, "gamerTag": request.profile.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.profile.userId, "questions": request.profile.questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "captainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                self.updateCaptain(request: request, team: team, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCaptain(request: RequestObject, team: TeamObject, callbacks: TeamInteractionCallbacks, indexPath: IndexPath){
        let ref = Database.database().reference().child("Users").child(team.teamCaptain)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
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
                
                for dbRequest in dbRequests{
                    if(dbRequest.profile.userId == request.profile.userId){
                        //show error, already there
                        return
                    }
                }
                
                dbRequests.append(request)
                
                var putBackRequests = [[String: Any]]()
                for request in dbRequests{
                    let profile = ["game": request.profile.game, "consoles": request.profile.consoles, "gamerTag": request.profile.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.profile.userId, "questions": request.profile.questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "captainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                callbacks.successfulRequest(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func generateRandomDigits(_ digitNumber: Int) -> String {
        var number = ""
        for i in 0..<digitNumber {
            var randomNumber = arc4random_uniform(10)
            while randomNumber == 0 && i == 0 {
                randomNumber = arc4random_uniform(10)
            }
            number += "\(randomNumber)"
        }
        return number
    }
}
