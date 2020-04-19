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
    var tempIds = [String]()
    var tempTags = [String]()
    var tempTeammates = [TeammateObject]()
    
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
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    
                    let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                    invites.append(newInvite)
                }
                
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM.dd.yyyy"
                let result = formatter.string(from: date)
                
                let currentInvite = TeamInviteObject(gamerTag: friend.gamerTag, date: result, uid: friend.uid, teamName: team.teamName)
                invites.append(currentInvite)
                
                var sendList = [[String: Any]]()
                for invite in invites{
                    let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid] as [String : String]
                    sendList.append(current)
                }
                
                let dict = snapshot.value as? [String: Any]
                var teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
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
                    let dict = currentObj.value as? [String: Any]
                    
                    /*
                    self.teamInvites = teamInvites*/
                    
                    let teamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let teamInviteTags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                    let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                    let teamCaptain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? ""
                    let captainId = dict?["teamCaptainId"] as? String ?? String()
                    
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
                    let teammates = snapshot.childSnapshot(forPath: "teammates")
                    for teammate in teammates.children{
                        let currentTeammate = teammate as! DataSnapshot
                        let dict = currentTeammate.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                        teammateArray.append(teammate)
                    }
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: teamCaptain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInviteTags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                    currentTeam.teammates = teammateArray
                    
                    currentInvites.append(currentTeam)
                }
                //Got all the teams from the DB, now lets add our team.
                currentInvites.append(team)
                
                //convert them and send them back.
                var sendInvites = [[String: Any]]()
                for team in currentInvites{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamCaptainId": team.teamCaptainId, "teamInvites": self.convertInvitesToSendableValue(invites: team.teamInvites), "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl] as [String : Any]
                    
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
                let request = RequestObject(status: "PENDING", teamId: team.teamId, teamName: team.teamName, captainId: team.teamCaptainId, requestId: "\(self.generateRandomDigits(6))")
                request.profile = freeAgent
                
                guard !request.profile.game.isEmpty else {
                    return
                }
                
                var dbRequests = [RequestObject]()
                let teamRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                for invite in teamRequests.children{
                   let currentObj = invite as! DataSnapshot
                   let dict = currentObj.value as? [String: Any]
                   let status = dict?["status"] as? String ?? ""
                   let teamId = dict?["teamId"] as? String ?? ""
                   let teamName = dict?["teamName"] as? String ?? ""
                   let captainId = dict?["teamCaptainId"] as? String ?? ""
                   let requestId = dict?["requestId"] as? String ?? ""
                    
                    let requestsArray = snapshot.childSnapshot(forPath: "inviteRequests")
                    var requestProfiles = [FreeAgentObject]()
                    for requestObj in requestsArray.children {
                        let currentObj = requestObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let game = dict?["game"] as? String ?? ""
                        let consoles = dict?["consoles"] as? [String] ?? [String]()
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let competitionId = dict?["competitionId"] as? String ?? ""
                        let userId = dict?["userId"] as? String ?? ""
                        let questions = dict?["questions"] as? [[String]] ?? [[String]]()
                        
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
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "teamCaptainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
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
        let ref = Database.database().reference().child("Users").child(team.teamCaptainId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var dbRequests = [RequestObject]()
                let teamRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                for invite in teamRequests.children{
                   let currentObj = invite as! DataSnapshot
                   let dict = currentObj.value as? [String: Any]
                   let status = dict?["status"] as? String ?? ""
                   let teamId = dict?["teamId"] as? String ?? ""
                   let teamName = dict?["teamName"] as? String ?? ""
                   let captainId = dict?["teamCaptainId"] as? String ?? ""
                   let requestId = dict?["requestId"] as? String ?? ""
                    
                    let requestsArray = snapshot.childSnapshot(forPath: "inviteRequests")
                    var requestProfiles = [FreeAgentObject]()
                    for requestObj in requestsArray.children {
                        let currentObj = requestObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let game = dict?["game"] as? String ?? ""
                        let consoles = dict?["consoles"] as? [String] ?? [String]()
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let competitionId = dict?["competitionId"] as? String ?? ""
                        let userId = dict?["userId"] as? String ?? ""
                        let questions = dict?["questions"] as? [[String]] ?? [[String]]()
                        
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
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "teamCaptainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                callbacks.successfulRequest(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func acceptRequest(requestObject: RequestObject, acceptedTeam: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update other user first
        let ref = Database.database().reference().child("Users").child(requestObject.profile.userId)
        let teamsRef = Database.database().reference().child("Teams").child(acceptedTeam.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
                var teams = [TeamObject]()
                let teamsArray = snapshot.childSnapshot(forPath: "teams")
                for teamObj in teamsArray.children {
                    let currentObj = teamObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let teamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                    let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                    
                    var invites = [TeamInviteObject]()
                    let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                    for invite in teamInvites.children{
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let inviteTeamName = dict?["teamName"] as? String ?? ""
                        
                        let newInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: inviteTeamName)
                        invites.append(newInvite)
                    }
                    
                    let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let captain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? ""
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let captainId = dict?["teamCaptainId"] as? String ?? ""
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                    
                    var teammateArray = [TeammateObject]()
                    if(currentObj.hasChild("teammates")){
                        let teammates = currentObj.childSnapshot(forPath: "teammates")
                        for teammate in teammates.children{
                            let currentTeammate = teammate as! DataSnapshot
                            let dict = currentTeammate.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                            teammateArray.append(teammate)
                        }
                        currentTeam.teammates = teammateArray
                        teams.append(currentTeam)
                    }
                }
                
                let newTeam = acceptedTeam
                newTeam.teammateTags.append(requestObject.profile.gamerTag)
                
                for request in newTeam.requests{
                    if(request.requestId == requestObject.requestId){
                        newTeam.requests.remove(at: newTeam.requests.index(of: request)!)
                    }
                }
                
                newTeam.teammateIds.append(requestObject.profile.userId)
                
                let formatter = DateFormatter()
                //2016-12-08 03:37:22 +0000
                //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let newTeammate = TeammateObject(gamerTag: requestObject.profile.gamerTag, date: dateString, uid: requestObject.profile.userId)
                
                newTeam.teammates.append(newTeammate)
                
                teams.append(newTeam)
                
                var teammateList = [[String: Any]]()
                for teammate in newTeam.teammates{
                    let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                    teammateList.append(current)
                }
                
                var sendUp = [[String: Any]]()
                for team in teams{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamCaptainId": team.teamCaptainId, "teamInvites": team.teamInvites, "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammateList] as [String : Any]
                    
                    sendUp.append(current)
                }
                
                ref.child("teams").setValue(sendUp)
                
                var teamRefObj: [String: Any]? = nil
                for payload in sendUp{
                    if((payload["teamName"] as! String) == newTeam.teamName){
                        teamRefObj = payload
                        break
                    }
                }
                
                if(teamRefObj != nil){
                    teamsRef.setValue(teamRefObj)
                }
                
                self.updateCurrentUserAcceptRequest(request: requestObject, team: newTeam, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func updateCurrentUserAcceptRequest(request: RequestObject, team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update captain
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Users").child(team.teamCaptainId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var teamInviteReqs = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["teamCaptainId"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let gamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     let questions = profileDict?["questions"] as? [[String]] ?? [[String]]()
                     
                     let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                     let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                     newRequest.profile = result
                     
                     teamInviteReqs.append(newRequest)
                }
                
                for teamRequest in teamInviteReqs{
                    if(teamRequest.requestId == request.requestId){
                        teamInviteReqs.remove(at: teamInviteReqs.index(of: teamRequest)!)
                    }
                }
                
                var putBackRequests = [[String: Any]]()
                for request in teamInviteReqs {
                    let profile = ["game": request.profile.game, "consoles": request.profile.consoles, "gamerTag": request.profile.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.profile.userId, "questions": request.profile.questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "teamCaptainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                //update teams
                var teams = [TeamObject]()
                let teamsArray = snapshot.childSnapshot(forPath: "teams")
                for teamObj in teamsArray.children {
                    let currentObj = teamObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let teamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                    let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                    
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
                    
                    let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                    let captain = dict?["teamCaptain"] as? String ?? ""
                    let imageUrl = dict?["imageUrl"] as? String ?? ""
                    let teamChat = dict?["teamChat"] as? String ?? String()
                    let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                    let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                    let captainId = dict?["teamCaptainId"] as? String ?? String()
                    
                    let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                    
                    var teammateArray = [TeammateObject]()
                    if(currentObj.hasChild("teammates")){
                        let teammates = currentObj.childSnapshot(forPath: "teammates")
                        for teammate in teammates.children{
                            let currentTeammate = teammate as! DataSnapshot
                            let dict = currentTeammate.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                            teammateArray.append(teammate)
                        }
                        currentTeam.teammates = teammateArray
                        teams.append(currentTeam)
                    }
                }
                
                for alreadyTeam in teams{
                    if alreadyTeam.teamName == team.teamName{
                        teams.remove(at: teams.index(of: alreadyTeam)!)
                    }
                }
                
                teams.append(team)
                
                var teammateList = [[String: Any]]()
                for teammate in team.teammates{
                    let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                    teammateList.append(current)
                }
                
                var sendUp = [[String: Any]]()
                for team in teams{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamCaptainId": team.teamCaptainId, "teamInvites": team.teamInvites, "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammateList] as [String : Any]
                    
                    sendUp.append(current)
                }
                
                ref.child("teams").setValue(sendUp)
                
                self.updateTeamAcceptRequest(team: team, request: request, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func updateTeamAcceptRequest(team: TeamObject, request: RequestObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        for id in team.teammateIds {
            if (id != "" && id != request.profile.userId  && id != request.captainId) {
               let ref = Database.database().reference().child("Users").child(id)
               ref.observeSingleEvent(of: .value, with: { (snapshot) in
                   if(snapshot.exists()){
                       var teams = [TeamObject]()
                       let teamsArray = snapshot.childSnapshot(forPath: "teams")
                       for teamObj in teamsArray.children {
                           let currentObj = teamObj as! DataSnapshot
                           let dict = currentObj.value as? [String: Any]
                           let teamName = dict?["teamName"] as? String ?? ""
                           let teamId = dict?["teamId"] as? String ?? ""
                           let games = dict?["games"] as? [String] ?? [String]()
                           let consoles = dict?["consoles"] as? [String] ?? [String]()
                           let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                           let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                           
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
                           
                           let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                           let captain = dict?["teamCaptain"] as? String ?? ""
                           let imageUrl = dict?["imageUrl"] as? String ?? ""
                           let teamChat = dict?["teamChat"] as? String ?? String()
                           let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                           let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                           let captainId = dict?["teamCaptainId"] as? String ?? String()
                           
                           let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                           
                           var teammateArray = [TeammateObject]()
                           if(currentObj.hasChild("teammates")){
                               let teammates = currentObj.childSnapshot(forPath: "teammates")
                               for teammate in teammates.children{
                                   let currentTeammate = teammate as! DataSnapshot
                                   let dict = currentTeammate.value as? [String: Any]
                                   let gamerTag = dict?["gamerTag"] as? String ?? ""
                                   let date = dict?["date"] as? String ?? ""
                                   let uid = dict?["uid"] as? String ?? ""
                                   
                                   let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                                   teammateArray.append(teammate)
                               }
                               currentTeam.teammates = teammateArray
                               teams.append(currentTeam)
                           }
                       }
                       
                       teams.append(team)
                       
                       var teammateList = [[String: Any]]()
                       for teammate in team.teammates{
                           let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                           teammateList.append(current)
                       }
                       
                       var sendUp = [[String: Any]]()
                       for team in teams{
                           let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamCaptainId": team.teamCaptainId, "teamInvites": team.teamInvites, "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammateList] as [String : Any]
                           
                           sendUp.append(current)
                       }
                       
                       ref.child("teams").setValue(sendUp)
                   }
                   
               }) { (error) in
                   print(error.localizedDescription)
               }
           }
        }
        callbacks.updateCell(indexPath: indexPath)
    }
    
    
    func rejectRequest(request: RequestObject, rejectedTeam: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        let teamsRef = Database.database().reference().child("Teams").child(rejectedTeam.teamName)
        teamsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                var dbRequests = [RequestObject]()
                let teamRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                for invite in teamRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                  let teamId = dict?["teamId"] as? String ?? ""
                  let teamName = dict?["teamName"] as? String ?? ""
                  let captainId = dict?["teamCaptainId"] as? String ?? ""
                  let requestId = dict?["requestId"] as? String ?? ""
                   
                   let requestsArray = snapshot.childSnapshot(forPath: "inviteRequests")
                   var requestProfiles = [FreeAgentObject]()
                   for requestObj in requestsArray.children {
                       let currentObj = requestObj as! DataSnapshot
                       let dict = currentObj.value as? [String: Any]
                       let game = dict?["game"] as? String ?? ""
                       let consoles = dict?["consoles"] as? [String] ?? [String]()
                       let gamerTag = dict?["gamerTag"] as? String ?? ""
                       let competitionId = dict?["competitionId"] as? String ?? ""
                       let userId = dict?["userId"] as? String ?? ""
                       let questions = dict?["questions"] as? [[String]] ?? [[String]]()
                       
                       let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                       
                       requestProfiles.append(result)
                   }
                   
                   let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                   newRequest.profile = requestProfiles[0]
                   
                   dbRequests.append(newRequest)
                }
                
                for request in dbRequests{
                    if(request.requestId == request.requestId){
                        dbRequests.remove(at: dbRequests.index(of: request)!)
                    }
                }
                
                var putBackRequests = [[String: Any]]()
                for request in dbRequests{
                    let profile = ["game": request.profile.game, "consoles": request.profile.consoles, "gamerTag": request.profile.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.profile.userId, "questions": request.profile.questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "teamCaptainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                teamsRef.child("inviteRequests").setValue(putBackRequests)
                
                self.rejectRequestCaptain(request: request, team: rejectedTeam, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    
    private func rejectRequestCaptain(request: RequestObject, team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        let ref = Database.database().reference().child("Users").child(request.captainId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var teamInviteReqs = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["teamCaptainId"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let gamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     let questions = profileDict?["questions"] as? [[String]] ?? [[String]]()
                     
                     let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                     let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                     newRequest.profile = result
                     
                     teamInviteReqs.append(newRequest)
                }
                
                for teamRequest in teamInviteReqs{
                    if(teamRequest.requestId == request.requestId){
                        teamInviteReqs.remove(at: teamInviteReqs.index(of: teamRequest)!)
                    }
                }
                
                var putBackRequests = [[String: Any]]()
                for request in teamInviteReqs {
                    let profile = ["game": request.profile.game, "consoles": request.profile.consoles, "gamerTag": request.profile.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.profile.userId, "questions": request.profile.questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "teamCaptainId": request.captainId, "requestId": request.requestId, "profile": profile] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                
                callbacks.updateCell(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func acceptTeamRequest(team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update team
        let ref = Database.database().reference().child("Teams").child(team.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
                self.tempTags = [String]()
                let tagssArray = snapshot.childSnapshot(forPath: "teammateTags")
                for tag in tagssArray.children{
                    self.tempTags.append(tag as? String ?? "")
                }
                let profileManager = GamerProfileManager()
                self.tempTags.append(profileManager.getGamerTagForGame(gameName: team.games[0]))
                
                self.tempIds = [String]()
                let idsArray = snapshot.childSnapshot(forPath: "teammateIds")
                for id in idsArray.children{
                    self.tempIds.append(id as? String ?? "")
                }
                self.tempIds.append(currentUser!.uId)
                
                self.tempTeammates = [TeammateObject]()
                let teamArray = snapshot.childSnapshot(forPath: "teammates")
                for teammate in teamArray.children{
                    let currentObj = teammate as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["gamerTag"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let teammate = TeammateObject(gamerTag: tag, date: date, uid: uid)
                    self.tempTeammates.append(teammate)
                }
                
                let teammate = TeammateObject(gamerTag: profileManager.getGamerTagForGame(gameName: team.games[0]), date: "", uid: delegate.currentUser!.uId)
                self.tempTeammates.append(teammate)
                
                var sendList = [[String: Any]]()
                for teammate in self.tempTeammates{
                    let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("teammates").setValue(sendList)
                ref.child("teammateIds").setValue(self.tempIds)
                ref.child("teammateTags").setValue(self.tempTags)
                
                self.updateTeammates(team: team, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func recjectTeamRequest(team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update team
        let ref = Database.database().reference().child("Teams").child(team.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
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
                
                for invite in invites{
                    if(invite.uid == currentUser!.uId){
                        invites.remove(at: invites.index(of: invite)!)
                        break
                    }
                }
                
                var sendList = [[String: Any]]()
                for invite in invites{
                    let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("teamInvites").setValue(sendList)
                
                self.updateTeammates(team: team, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUserRejectTeam(team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //remove request from user.
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var currentInvites = [TeamObject]()
                    let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                    for invite in teamInvites.children{
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        
                        let teamName = dict?["teamName"] as? String ?? ""
                        let teamId = dict?["teamId"] as? String ?? ""
                        let games = dict?["games"] as? [String] ?? [String]()
                        let consoles = dict?["consoles"] as? [String] ?? [String]()
                        let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                        let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                        let teamInviteTags = dict?["teamInviteTags"] as? [String] ?? [String]()
                        let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                        let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                        let teamCaptain = dict?["teamCaptain"] as? String ?? ""
                        let imageUrl = dict?["imageUrl"] as? String ?? ""
                        let teamChat = dict?["teamChat"] as? String ?? ""
                        let captainId = dict?["teamCaptainId"] as? String ?? String()
                        
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
                        
                        let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: teamCaptain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInviteTags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
                        currentTeam.teammates = teammateArray
                        
                        currentInvites.append(currentTeam)
                    }
                
                for invite in currentInvites{
                    if(invite.teamId == team.teamId){
                        currentInvites.remove(at: currentInvites.index(of: invite)!)
                        break
                    }
                }
                    
                    //convert them and send them back.
                    var sendInvites = [[String: Any]]()
                    for team in currentInvites{
                        let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamCaptainId": team.teamCaptainId, "teamInvites": self.convertInvitesToSendableValue(invites: team.teamInvites), "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl] as [String : Any]
                        
                        sendInvites.append(current)
                    }
                
                    ref.child(team.teamName).child("teamInvites").setValue(sendInvites)
                    
                    callbacks.updateCell(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateTeammates(team: TeamObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        let unchangingList = self.tempIds
        
        if(!self.tempIds.isEmpty){
            
            for id in self.tempIds{
                let ref = Database.database().reference().child("Users").child(id).child("teams").child(team.teamName)
                self.tempIds.remove(at: self.tempIds.index(of: id)!)
                
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.exists()){
        
                        var sendList = [[String: Any]]()
                        for teammate in self.tempTeammates{
                            let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                            sendList.append(current)
                        }
                        
                        ref.child("teammates").setValue(sendList)
                        ref.child("teammateIds").setValue(unchangingList)
                        ref.child("teammateTags").setValue(self.tempTags)
                        
                        if(self.tempIds.isEmpty){
                            callbacks.updateCell(indexPath: indexPath)
                        }
                    }
                    
                }) { (error) in
                    if(!self.tempIds.isEmpty){
                        self.updateTeammates(team: team, callbacks: callbacks, indexPath: indexPath)
                    }
                    //update error
                }
            }
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
