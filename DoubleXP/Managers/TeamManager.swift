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
        //build invite
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM.dd.yyyy"
        let result = formatter.string(from: date)
        
        let currentInvite = TeamInviteObject(gamerTag: friend.gamerTag, date: result, uid: friend.uid, teamName: team.teamName)
        
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
                
                invites.append(currentInvite)
                
                var sendList = [[String: Any]]()
                for invite in invites{
                    let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid, "teamName": team.teamName] as [String : String]
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
                if(snapshot.hasChild("teamInvites")){
                    var currentInvites = [TeamInviteObject]()
                    for invite in snapshot.childSnapshot(forPath: "teamInvites").children {
                        let currentObj = invite as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let teamName = dict?["teamName"] as? String ?? ""
        
                        let teamInvite = TeamInviteObject(gamerTag: gamerTag, date: date, uid: uid, teamName: teamName)
                        currentInvites.append(teamInvite)
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    let newInvite = TeamInviteObject(gamerTag: friend.gamerTag, date: dateString, uid: friend.uid, teamName: team.teamName)
                    currentInvites.append(newInvite)
                    
                    ref.child("teamInvites").setValue(self.convertInvitesToSendableValue(invites: currentInvites))
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    let newInvite = TeamInviteObject(gamerTag: friend.gamerTag, date: dateString, uid: friend.uid, teamName: team.teamName)
                    
                    var currentInvites = [TeamInviteObject]()
                    currentInvites.append(newInvite)
                    ref.child("teamInvites").setValue(self.convertInvitesToSendableValue(invites: currentInvites))
                }
                
                callbacks.updateCell(indexPath: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertInvitesToSendableValue(invites: [TeamInviteObject]) -> [[String: Any]]{
        var array = [[String: Any]]()
        
        for invite in invites{
            let current = ["gamerTag": invite.gamerTag, "date": invite.date, "uid": invite.uid, "teamName": invite.teamName] as [String : String]
            array.append(current)
        }
        
        return array
    }
    
    func sendRequestToJoin(freeAgent: FreeAgentObject?, team: TeamObject, callbacks: TeamInteractionCallbacks, indexPath: IndexPath){
        //build request
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let manager = GamerProfileManager()
        let gamerTag = manager.getGamerTagForGame(gameName: team.games[0])
        let request = RequestObject(status: "PENDING", teamId: team.teamId, teamName: team.teamName, captainId: team.teamCaptainId, requestId: "\(self.generateRandomDigits(6))", userUid: currentUser?.uId ?? "", gamerTag: gamerTag)
        if(freeAgent != nil){
            request.profile = freeAgent!
        }
        
        //First, lets update thhe team.
        let ref = Database.database().reference().child("Teams").child(team.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var dbRequests = [RequestObject]()
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["captainId"] as? String ?? ""
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                    let userUid = dict?["userUid"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let profileGamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     
                    var questions = [FAQuestion]()
                    let questionList = dict?["questions"] as? [[String: Any]] ?? [[String: Any]]()
                            for question in questionList {
                                var questionNumber = ""
                                var questionString = ""
                                var option1 = ""
                                var option1Description = ""
                                var option2 = ""
                                var option2Description = ""
                                var option3 = ""
                                var option3Description = ""
                                var option4 = ""
                                var option4Description = ""
                                var option5 = ""
                                var option5Description = ""
                                var option6 = ""
                                var option6Description = ""
                                var option7 = ""
                                var option7Description = ""
                                var option8 = ""
                                var option8Description = ""
                                var option9 = ""
                                var option9Description = ""
                                var option10 = ""
                                var option10Description = ""
                                var required = ""
                                var questionDescription = ""
                                var teamNeedQuestion = "false"
                                var acceptMultiple = ""
                                var question1SetURL = ""
                                var question2SetURL = ""
                                var question3SetURL = ""
                                var question4SetURL = ""
                                var question5SetURL = ""
                                var optionsURL = ""
                                var maxOptions = ""
                                var answer = ""
                                var answerArray = [String]()
                                
                                for (key, value) in question {
                                    if(key == "questionNumber"){
                                        questionNumber = (value as? String) ?? ""
                                    }
                                    if(key == "question"){
                                        questionString = (value as? String) ?? ""
                                    }
                                    if(key == "option1"){
                                        option1 = (value as? String) ?? ""
                                    }
                                    if(key == "option1Description"){
                                        option1Description = (value as? String) ?? ""
                                    }
                                    if(key == "option2"){
                                        option2 = (value as? String) ?? ""
                                    }
                                    if(key == "option2Description"){
                                        option2Description = (value as? String) ?? ""
                                    }
                                    if(key == "option3"){
                                        option3 = (value as? String) ?? ""
                                    }
                                    if(key == "option3Description"){
                                        option3Description = (value as? String) ?? ""
                                    }
                                    if(key == "option4"){
                                        option4 = (value as? String) ?? ""
                                    }
                                    if(key == "option4Description"){
                                        option4Description = (value as? String) ?? ""
                                    }
                                    if(key == "option5"){
                                        option5 = (value as? String) ?? ""
                                    }
                                    if(key == "option5Description"){
                                        option5Description = (value as? String) ?? ""
                                    }
                                    if(key == "option6"){
                                        option6 = (value as? String) ?? ""
                                    }
                                    if(key == "option6Description"){
                                        option6Description = (value as? String) ?? ""
                                    }
                                    if(key == "option7"){
                                        option7 = (value as? String) ?? ""
                                    }
                                    if(key == "option7Description"){
                                        option7Description = (value as? String) ?? ""
                                    }
                                    if(key == "option8"){
                                        option8 = (value as? String) ?? ""
                                    }
                                    if(key == "option8Description"){
                                        option8Description = (value as? String) ?? ""
                                    }
                                    if(key == "option9"){
                                        option9 = (value as? String) ?? ""
                                    }
                                    if(key == "option9Description"){
                                        option9Description = (value as? String) ?? ""
                                    }
                                    if(key == "option10"){
                                        option10 = (value as? String) ?? ""
                                    }
                                    if(key == "option10Description"){
                                        option10Description = (value as? String) ?? ""
                                    }
                                    if(key == "required"){
                                        required = (value as? String) ?? ""
                                    }
                                    if(key == "questionDescription"){
                                        questionDescription = (value as? String) ?? ""
                                    }
                                    if(key == "acceptMultiple"){
                                        acceptMultiple = (value as? String) ?? ""
                                    }
                                    if(key == "question1SetURL"){
                                        question1SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question2SetURL"){
                                        question2SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question3SetURL"){
                                        question3SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question4SetURL"){
                                        question4SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question5SetURL"){
                                        question5SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "teamNeedQuestion"){
                                        teamNeedQuestion = (value as? String) ?? "false"
                                    }
                                    if(key == "optionsUrl"){
                                        optionsURL = (value as? String) ?? ""
                                    }
                                    if(key == "maxOptions"){
                                        maxOptions = (value as? String) ?? ""
                                    }
                                    if(key == "answer"){
                                        answer = (value as? String) ?? ""
                                    }
                                    if(key == "answerArray"){
                                        answerArray = (value as? [String]) ?? [String]()
                                    }
                            }
                                
                                let faQuestion = FAQuestion(question: questionString)
                                    faQuestion.questionNumber = questionNumber
                                    faQuestion.question = questionString
                                    faQuestion.option1 = option1
                                    faQuestion.option1Description = option1Description
                                    faQuestion.question1SetURL = question1SetURL
                                    faQuestion.option2 = option2
                                    faQuestion.option2Description = option2Description
                                    faQuestion.question2SetURL = question2SetURL
                                    faQuestion.option3 = option3
                                    faQuestion.option3Description = option3Description
                                    faQuestion.question3SetURL = question3SetURL
                                    faQuestion.option4 = option4
                                    faQuestion.option4Description = option4Description
                                    faQuestion.question4SetURL = question4SetURL
                                    faQuestion.option5 = option5
                                    faQuestion.option5Description = option5Description
                                    faQuestion.question5SetURL = question5SetURL
                                    faQuestion.option6 = option6
                                    faQuestion.option6Description = option6Description
                                    faQuestion.option7 = option7
                                    faQuestion.option7Description = option7Description
                                    faQuestion.option8 = option8
                                    faQuestion.option8Description = option8Description
                                    faQuestion.option9 = option9
                                    faQuestion.option9Description = option9Description
                                    faQuestion.option10 = option10
                                    faQuestion.option10Description = option10Description
                                    faQuestion.required = required
                                    faQuestion.acceptMultiple = acceptMultiple
                                    faQuestion.questionDescription = questionDescription
                                    faQuestion.teamNeedQuestion = teamNeedQuestion
                                    faQuestion.optionsUrl = optionsURL
                                    faQuestion.maxOptions = maxOptions
                                    faQuestion.answer = answer
                                    faQuestion.answerArray = answerArray
                    
                        questions.append(faQuestion)
                    }
                     
                     let result = FreeAgentObject(gamerTag: profileGamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                    let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId, userUid: userUid, gamerTag: gamerTag)
                     newRequest.profile = result
                     
                     dbRequests.append(newRequest)
                }
                
                for dbRequest in dbRequests{
                    if(dbRequest.userUid == request.userUid){
                        //show error, already there
                        return
                    }
                }
                
                dbRequests.append(request)
                
                var putBackRequests = [[String: Any]]()
                for request in dbRequests{
                    var questions = [[String: Any]]()
                    for question in request.profile.questions {
                        let currentQuestion = question
                        let currentDict = ["question": currentQuestion.question, "answer": currentQuestion.answer, "questionAnswered": currentQuestion.questionAnswered, "acceptMultiple": currentQuestion.acceptMultiple, "questionDescription": currentQuestion.questionDescription, "required": currentQuestion.required, "question5SetURL": currentQuestion.question5SetURL, "option5Description": currentQuestion.option5Description,  "option5": currentQuestion.option5, "question4SetURL": currentQuestion.question4SetURL, "option4Description": currentQuestion.option4Description, "option4": currentQuestion.option4,"question3SetURL": currentQuestion.question3SetURL, "option3Description": currentQuestion.option3Description, "option3": currentQuestion.option3,"question2SetURL": currentQuestion.question2SetURL, "option2Description": currentQuestion.option2Description, "option2": currentQuestion.option1,"question1SetURL": currentQuestion.question1SetURL, "option1Description": currentQuestion.option1Description, "option1": currentQuestion.option1, "teamNeedQuestion": currentQuestion.teamNeedQuestion, "optionsUrl": currentQuestion.optionsUrl, "maxOptions": currentQuestion.maxOptions, "answerArray": currentQuestion.answerArray, "questionNumber": currentQuestion.questionNumber] as [String : Any]
                        
                        questions.append(currentDict)
                    }
                    
                    
                    let profile = ["game": team.games[0], "consoles": team.consoles, "gamerTag": request.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.userUid, "questions": questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "captainId": request.captainId, "requestId": request.requestId, "profile": profile, "userUid": request.userUid, "gamerTag": request.gamerTag] as [String : Any]
                    
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
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let status = dict?["status"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let teamName = dict?["teamName"] as? String ?? ""
                    let captainId = dict?["captainId"] as? String ?? ""
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let requestId = dict?["requestId"] as? String ?? ""
                        let userUid = dict?["userUid"] as? String ?? ""
                     
                     let profile = currentObj.childSnapshot(forPath: "profile")
                     let profileDict = profile.value as? [String: Any]
                     let game = profileDict?["game"] as? String ?? ""
                     let consoles = profileDict?["consoles"] as? [String] ?? [String]()
                     let profileGamerTag = profileDict?["gamerTag"] as? String ?? ""
                     let competitionId = profileDict?["competitionId"] as? String ?? ""
                     let userId = profileDict?["userId"] as? String ?? ""
                     
                    var questions = [FAQuestion]()
                    let questionList = dict?["questions"] as? [[String: Any]] ?? [[String: Any]]()
                            for question in questionList {
                                var questionNumber = ""
                                var questionString = ""
                                var option1 = ""
                                var option1Description = ""
                                var option2 = ""
                                var option2Description = ""
                                var option3 = ""
                                var option3Description = ""
                                var option4 = ""
                                var option4Description = ""
                                var option5 = ""
                                var option5Description = ""
                                var option6 = ""
                                var option6Description = ""
                                var option7 = ""
                                var option7Description = ""
                                var option8 = ""
                                var option8Description = ""
                                var option9 = ""
                                var option9Description = ""
                                var option10 = ""
                                var option10Description = ""
                                var required = ""
                                var questionDescription = ""
                                var teamNeedQuestion = "false"
                                var acceptMultiple = ""
                                var question1SetURL = ""
                                var question2SetURL = ""
                                var question3SetURL = ""
                                var question4SetURL = ""
                                var question5SetURL = ""
                                var optionsURL = ""
                                var maxOptions = ""
                                var answer = ""
                                var answerArray = [String]()
                                
                                for (key, value) in question {
                                    if(key == "questionNumber"){
                                        questionNumber = (value as? String) ?? ""
                                    }
                                    if(key == "question"){
                                        questionString = (value as? String) ?? ""
                                    }
                                    if(key == "option1"){
                                        option1 = (value as? String) ?? ""
                                    }
                                    if(key == "option1Description"){
                                        option1Description = (value as? String) ?? ""
                                    }
                                    if(key == "option2"){
                                        option2 = (value as? String) ?? ""
                                    }
                                    if(key == "option2Description"){
                                        option2Description = (value as? String) ?? ""
                                    }
                                    if(key == "option3"){
                                        option3 = (value as? String) ?? ""
                                    }
                                    if(key == "option3Description"){
                                        option3Description = (value as? String) ?? ""
                                    }
                                    if(key == "option4"){
                                        option4 = (value as? String) ?? ""
                                    }
                                    if(key == "option4Description"){
                                        option4Description = (value as? String) ?? ""
                                    }
                                    if(key == "option5"){
                                        option5 = (value as? String) ?? ""
                                    }
                                    if(key == "option5Description"){
                                        option5Description = (value as? String) ?? ""
                                    }
                                    if(key == "option6"){
                                        option6 = (value as? String) ?? ""
                                    }
                                    if(key == "option6Description"){
                                        option6Description = (value as? String) ?? ""
                                    }
                                    if(key == "option7"){
                                        option7 = (value as? String) ?? ""
                                    }
                                    if(key == "option7Description"){
                                        option7Description = (value as? String) ?? ""
                                    }
                                    if(key == "option8"){
                                        option8 = (value as? String) ?? ""
                                    }
                                    if(key == "option8Description"){
                                        option8Description = (value as? String) ?? ""
                                    }
                                    if(key == "option9"){
                                        option9 = (value as? String) ?? ""
                                    }
                                    if(key == "option9Description"){
                                        option9Description = (value as? String) ?? ""
                                    }
                                    if(key == "option10"){
                                        option10 = (value as? String) ?? ""
                                    }
                                    if(key == "option10Description"){
                                        option10Description = (value as? String) ?? ""
                                    }
                                    if(key == "required"){
                                        required = (value as? String) ?? ""
                                    }
                                    if(key == "questionDescription"){
                                        questionDescription = (value as? String) ?? ""
                                    }
                                    if(key == "acceptMultiple"){
                                        acceptMultiple = (value as? String) ?? ""
                                    }
                                    if(key == "question1SetURL"){
                                        question1SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question2SetURL"){
                                        question2SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question3SetURL"){
                                        question3SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question4SetURL"){
                                        question4SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "question5SetURL"){
                                        question5SetURL = (value as? String) ?? ""
                                    }
                                    if(key == "teamNeedQuestion"){
                                        teamNeedQuestion = (value as? String) ?? "false"
                                    }
                                    if(key == "optionsUrl"){
                                        optionsURL = (value as? String) ?? ""
                                    }
                                    if(key == "maxOptions"){
                                        maxOptions = (value as? String) ?? ""
                                    }
                                    if(key == "answer"){
                                        answer = (value as? String) ?? ""
                                    }
                                    if(key == "answerArray"){
                                        answerArray = (value as? [String]) ?? [String]()
                                    }
                            }
                                
                                let faQuestion = FAQuestion(question: questionString)
                                    faQuestion.questionNumber = questionNumber
                                    faQuestion.question = questionString
                                    faQuestion.option1 = option1
                                    faQuestion.option1Description = option1Description
                                    faQuestion.question1SetURL = question1SetURL
                                    faQuestion.option2 = option2
                                    faQuestion.option2Description = option2Description
                                    faQuestion.question2SetURL = question2SetURL
                                    faQuestion.option3 = option3
                                    faQuestion.option3Description = option3Description
                                    faQuestion.question3SetURL = question3SetURL
                                    faQuestion.option4 = option4
                                    faQuestion.option4Description = option4Description
                                    faQuestion.question4SetURL = question4SetURL
                                    faQuestion.option5 = option5
                                    faQuestion.option5Description = option5Description
                                    faQuestion.question5SetURL = question5SetURL
                                    faQuestion.option6 = option6
                                    faQuestion.option6Description = option6Description
                                    faQuestion.option7 = option7
                                    faQuestion.option7Description = option7Description
                                    faQuestion.option8 = option8
                                    faQuestion.option8Description = option8Description
                                    faQuestion.option9 = option9
                                    faQuestion.option9Description = option9Description
                                    faQuestion.option10 = option10
                                    faQuestion.option10Description = option10Description
                                    faQuestion.required = required
                                    faQuestion.acceptMultiple = acceptMultiple
                                    faQuestion.questionDescription = questionDescription
                                    faQuestion.teamNeedQuestion = teamNeedQuestion
                                    faQuestion.optionsUrl = optionsURL
                                    faQuestion.maxOptions = maxOptions
                                    faQuestion.answer = answer
                                    faQuestion.answerArray = answerArray
                    
                        questions.append(faQuestion)
                    }
                     
                     let result = FreeAgentObject(gamerTag: profileGamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                     
                     
                    let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId, userUid: userUid, gamerTag: gamerTag)
                     newRequest.profile = result
                     
                     dbRequests.append(newRequest)
                }
                
                for dbRequest in dbRequests{
                    if(dbRequest.userUid == request.userUid){
                        //show error, already there
                        return
                    }
                }
                
                dbRequests.append(request)
                
                var putBackRequests = [[String: Any]]()
                for request in dbRequests{
                    var questions = [[String: Any]]()
                    for question in request.profile.questions {
                        let currentQuestion = question
                        let currentDict = ["question": currentQuestion.question, "answer": currentQuestion.answer, "questionAnswered": currentQuestion.questionAnswered, "acceptMultiple": currentQuestion.acceptMultiple, "questionDescription": currentQuestion.questionDescription, "required": currentQuestion.required, "question5SetURL": currentQuestion.question5SetURL, "option5Description": currentQuestion.option5Description,  "option5": currentQuestion.option5, "question4SetURL": currentQuestion.question4SetURL, "option4Description": currentQuestion.option4Description, "option4": currentQuestion.option4,"question3SetURL": currentQuestion.question3SetURL, "option3Description": currentQuestion.option3Description, "option3": currentQuestion.option3,"question2SetURL": currentQuestion.question2SetURL, "option2Description": currentQuestion.option2Description, "option2": currentQuestion.option1,"question1SetURL": currentQuestion.question1SetURL, "option1Description": currentQuestion.option1Description, "option1": currentQuestion.option1, "teamNeedQuestion": currentQuestion.teamNeedQuestion, "optionsUrl": currentQuestion.optionsUrl, "maxOptions": currentQuestion.maxOptions, "answerArray": currentQuestion.answerArray, "questionNumber": currentQuestion.questionNumber] as [String : Any]
                        
                        questions.append(currentDict)
                    }
                    
                    let profile = ["game": team.games[0], "consoles": team.consoles, "gamerTag": request.gamerTag,
                                   "competitionId": request.profile.competitionId, "userId": request.userUid, "questions": questions] as [String : Any]
                    
                    let newRequest = ["status": request.status, "teamId": request.teamId, "teamName": request.teamName, "captainId": request.captainId, "requestId": request.requestId, "profile": profile, "userUid": request.userUid, "gamerTag": request.gamerTag] as [String : Any]
                    
                    putBackRequests.append(newRequest)
                }
                
                ref.child("inviteRequests").setValue(putBackRequests)
                
                callbacks.successfulRequest(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func acceptRequest(requestObject: RequestObject, acceptedTeam: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update other user first
        let ref = Database.database().reference().child("Users").child(requestObject.userUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var teams = [EasyTeamObj]()
                if(snapshot.hasChild("teams")){
                    var teams = [EasyTeamObj]()
                    let teamsArray = snapshot.childSnapshot(forPath: "teams")
                    for teamObj in teamsArray.children {
                        let currentObj = teamObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let teamName = dict?["teamName"] as? String ?? ""
                        let teamId = dict?["teamId"] as? String ?? ""
                        let game = dict?["gameName"] as? String ?? ""
                        let teamCaptainId = dict?["teamCaptainId"] as? String ?? ""
                        let newTeam = dict?["newTeam"] as? String ?? ""
                        
                        teams.append(EasyTeamObj(teamName: teamName, teamId: teamId, gameName: game, teamCaptainId: teamCaptainId, newTeam: newTeam))
                    }
                }
                
                let easyTeam = EasyTeamObj(teamName: acceptedTeam.teamName, teamId: acceptedTeam.teamId, gameName: acceptedTeam.gameName, teamCaptainId: acceptedTeam.teamCaptainId, newTeam: "true")
                
                teams.append(easyTeam)
                var sendUp = [[String: Any]]()
                for team in teams{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "gameName": team.gameName, "teamCaptainId": team.teamCaptainId, "newTeam": team.newTeam] as [String : String]
                    sendUp.append(current)
                }
                
                ref.child("teams").setValue(sendUp)
                
                //update team obj
                self.updateTeam(requestObject: requestObject, acceptedTeam: acceptedTeam, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func updateTeam(requestObject: RequestObject, acceptedTeam: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        let teamsRef = Database.database().reference().child("Teams").child(acceptedTeam.teamName)
        teamsRef.observeSingleEvent(of: .value, with: { (snapshot) in
           if(snapshot.exists()){
            //remove request
            if(snapshot.hasChild("inviteRequests")){
                for invite in snapshot.childSnapshot(forPath: "inviteRequests").children {
                    let current = invite as? DataSnapshot
                    if(current != nil){
                        if(current!.hasChild("requestId")){
                            if(current!.childSnapshot(forPath: "requestId").value as? String ?? "" == requestObject.requestId){
                                teamsRef.child("inviteRequests").child(current!.key).removeValue()
                            }
                        }
                    }
                }
            }
            
            //update teammates
           var teammateArray = [TeammateObject]()
            if(snapshot.hasChild("teammates")){
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
                
                var contained = false
                for teammate in teammateArray {
                    if(teammate.uid == requestObject.userUid){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                   let formatter = DateFormatter()
                   formatter.dateFormat = "MM-dd-yyyy"
                   let now = Date()
                   let dateString = formatter.string(from:now)
                    
                    let newTeammate = TeammateObject(gamerTag: requestObject.gamerTag, date: dateString, uid: requestObject.userUid)
                   teammateArray.append(newTeammate)
                }
                
                var teammatesSendArray = [Dictionary<String, String>]()
                for teammate in teammateArray {
                    let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid]
                    teammatesSendArray.append(current)
                }
                
                teamsRef.child("teammates").setValue(teammatesSendArray)
           }
            
            //update ids
            if(snapshot.hasChild("teammateIds")){
                var ids = snapshot.childSnapshot(forPath: "teammateIds").value as? [String] ?? [String]()
                if(!ids.contains(requestObject.userUid)){
                    ids.append(requestObject.userUid)
                }
                teamsRef.child("teammateIds").setValue(ids)
            }
            
            //update tags
            if(snapshot.hasChild("teammateTags")){
                var tags = snapshot.childSnapshot(forPath: "teammateTags").value as? [String] ?? [String]()
                if(!tags.contains(requestObject.gamerTag)){
                    tags.append(requestObject.gamerTag)
                }
                teamsRef.child("teammateTags").setValue(tags)
            }
               
           self.removeRequestCaptain(request: requestObject, team: acceptedTeam, callbacks: callbacks, indexPath: indexPath)
        }
           
       }) { (error) in
           print(error.localizedDescription)
       }
    }
    
    func removeRequestCaptain(request: RequestObject, team: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update captain
        let ref = Database.database().reference().child("Users").child(team.teamCaptainId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let requestId = dict?["requestId"] as? String ?? ""
                    
                    if(requestId == request.requestId){
                        ref.child("inviteRequests").child(currentObj.key).removeValue()
                        break
                    }
                }
                
                callbacks.updateCell(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func rejectRequest(request: RequestObject, rejectedTeam: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        let teamsRef = Database.database().reference().child("Teams").child(rejectedTeam.teamName)
        teamsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
                 for invite in teamInviteRequests.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let requestId = dict?["requestId"] as? String ?? ""
                    
                    if(requestId == request.requestId){
                        teamsRef.child("inviteRequests").child(currentObj.key).removeValue()
                    }
                }
                
                self.removeRequestCaptain(request: request, team: rejectedTeam, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    /*
     TEAM INVITES V
     */
    func acceptTeamInvite(teamInvite: TeamInviteObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update team
        let ref = Database.database().reference().child("Teams").child(teamInvite.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var teamId = ""
                if(snapshot.hasChild("teamId")){
                    teamId = snapshot.childSnapshot(forPath: "teamId").value as? String ?? ""
                }
                
                var games = [String]()
                if(snapshot.hasChild("games")){
                    games = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                }
                
                var teamCaptainId = ""
                if(snapshot.hasChild("teamCaptainId")){
                    teamCaptainId = snapshot.childSnapshot(forPath: "teamCaptainId").value as? String ?? ""
                }
                
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let uid = dict?["uid"] as? String ?? ""
                    if(uid == teamInvite.uid){
                        ref.child("teamInvites").child(currentObj.key).removeValue()
                        break
                    }
                }
                
                if(snapshot.hasChild("teammateTags")){
                    var tagssArray = snapshot.childSnapshot(forPath: "teammateTags").value as? [String] ?? [String]()
                    if(!tagssArray.contains(teamInvite.gamerTag)){
                        tagssArray.append(teamInvite.gamerTag)
                        ref.child("teammateTags").setValue(tagssArray)
                    }
                }
                
                if(snapshot.hasChild("teammateIds")){
                    var idsArray = snapshot.childSnapshot(forPath: "teammateIds").value as? [String] ?? [String]()
                    if(!idsArray.contains(teamInvite.uid)){
                        idsArray.append(teamInvite.uid)
                        ref.child("teammateIds").setValue(idsArray)
                    }
                }
                
                if(snapshot.hasChild("teammates")){
                     var teammates = [TeammateObject]()
                     let teamArray = snapshot.childSnapshot(forPath: "teammates")
                     for teammate in teamArray.children{
                         let currentObj = teammate as! DataSnapshot
                         let dict = currentObj.value as? [String: Any]
                         let date = dict?["date"] as? String ?? ""
                         let tag = dict?["gamerTag"] as? String ?? ""
                         let uid = dict?["uid"] as? String ?? ""
                         
                         let teammate = TeammateObject(gamerTag: tag, date: date, uid: uid)
                         teammates.append(teammate)
                     }
                    
                    var contained = false
                    for teammate in teammates {
                        if(teammate.uid == teamInvite.uid){
                            contained = true
                            break
                        }
                    }
                    
                    if(!contained){
                       let formatter = DateFormatter()
                       formatter.dateFormat = "MM-dd-yyyy"
                       let now = Date()
                       let dateString = formatter.string(from:now)
                        
                       let newTeammate = TeammateObject(gamerTag: teamInvite.gamerTag, date: dateString, uid: teamInvite.uid)
                       teammates.append(newTeammate)
                    }
                    
                    var sendList = [[String: Any]]()
                    for teammate in teammates {
                        let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("teammates").setValue(sendList)
                }
                
                let easyTeam = EasyTeamObj(teamName: teamInvite.teamName, teamId: teamId, gameName: games[0], teamCaptainId: teamCaptainId, newTeam: "true")
                
                self.removeInvite(teamInvite: teamInvite)
                self.updateUserTeams(teamInvite: teamInvite, easyTeam: easyTeam, callbacks: callbacks, indexPath: indexPath)
                
                callbacks.updateCell(indexPath: indexPath)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateUserTeams(teamInvite: TeamInviteObject, easyTeam: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        let ref = Database.database().reference().child("Users").child(teamInvite.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var teams = [EasyTeamObj]()
                if(snapshot.hasChild("teams")){
                    let teamsArray = snapshot.childSnapshot(forPath: "teams")
                    for teamObj in teamsArray.children {
                        let currentObj = teamObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let teamName = dict?["teamName"] as? String ?? ""
                        let teamId = dict?["teamId"] as? String ?? ""
                        let game = dict?["gameName"] as? String ?? ""
                        let teamCaptainId = dict?["teamCaptainId"] as? String ?? ""
                        let newTeam = dict?["newTeam"] as? String ?? ""
                        
                        teams.append(EasyTeamObj(teamName: teamName, teamId: teamId, gameName: game, teamCaptainId: teamCaptainId, newTeam: newTeam))
                    }
                }
                
                teams.append(easyTeam)
                var sendUp = [[String: Any]]()
                for team in teams{
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "gameName": team.gameName, "teamCaptainId": team.teamCaptainId, "newTeam": team.newTeam] as [String : String]
                    sendUp.append(current)
                }
                
                ref.child("teams").setValue(sendUp)
                
                //update team obj
                self.updateTeamInvite(inviteObj: teamInvite, acceptedTeam: easyTeam, callbacks: callbacks, indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func updateTeamInvite(inviteObj: TeamInviteObject, acceptedTeam: EasyTeamObj, callbacks: RequestsUpdate, indexPath: IndexPath){
        let teamsRef = Database.database().reference().child("Teams").child(acceptedTeam.teamName)
        teamsRef.observeSingleEvent(of: .value, with: { (snapshot) in
           if(snapshot.exists()){
            //remove request
            if(snapshot.hasChild("teamInvites")){
                for invite in snapshot.childSnapshot(forPath: "teamInvites").children {
                    let current = invite as? DataSnapshot
                    if(current != nil){
                        if(current!.hasChild("uid")){
                            if(current!.childSnapshot(forPath: "uid").value as? String ?? "" == inviteObj.uid){
                                teamsRef.child("teamInvites").child(current!.key).removeValue()
                                break
                            }
                        }
                    }
                }
            }
            
            //update teammates
           var teammateArray = [TeammateObject]()
            if(snapshot.hasChild("teammates")){
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
                
                var contained = false
                for teammate in teammateArray {
                    if(teammate.uid == inviteObj.uid){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                   let formatter = DateFormatter()
                   formatter.dateFormat = "MM-dd-yyyy"
                   let now = Date()
                   let dateString = formatter.string(from:now)
                    
                    let newTeammate = TeammateObject(gamerTag: inviteObj.gamerTag, date: dateString, uid: inviteObj.uid)
                   teammateArray.append(newTeammate)
                }
                
                var teammatesSendArray = [Dictionary<String, String>]()
                for teammate in teammateArray {
                    let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid]
                    teammatesSendArray.append(current)
                }
                
                teamsRef.child("teammates").setValue(teammatesSendArray)
           }
            
            //update ids
            if(snapshot.hasChild("teammateIds")){
                var ids = snapshot.childSnapshot(forPath: "teammateIds").value as? [String] ?? [String]()
                if(!ids.contains(inviteObj.uid)){
                    ids.append(inviteObj.uid)
                }
                teamsRef.child("teammateIds").setValue(ids)
            }
            
            //update tags
            if(snapshot.hasChild("teammateTags")){
                var tags = snapshot.childSnapshot(forPath: "teammateTags").value as? [String] ?? [String]()
                if(!tags.contains(inviteObj.gamerTag)){
                    tags.append(inviteObj.gamerTag)
                }
                teamsRef.child("teammateTags").setValue(tags)
            }
               
            self.removeInvite(teamInvite: inviteObj)
            callbacks.updateCell(indexPath: indexPath)
        }
           
       }) { (error) in
           print(error.localizedDescription)
       }
    }
    
    func recjectTeamInvite(teamInvite: TeamInviteObject, callbacks: RequestsUpdate, indexPath: IndexPath){
        //update team
        let ref = Database.database().reference().child("Teams").child(teamInvite.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
                for invite in teamInvites.children{
                    let currentObj = invite as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let uid = dict?["uid"] as? String ?? ""
                    if(uid == teamInvite.uid){
                        ref.child("teamInvites").child(currentObj.key).removeValue()
                        break
                    }
                }
                
                self.removeInvite(teamInvite: teamInvite)
                callbacks.updateCell(indexPath: indexPath)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    /*private func updateCurrentUserRejectTeam(team: TeamInviteObject, callbacks: RequestsUpdate, indexPath: IndexPath){
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
                        
                        let currentTeam = TeamObject(teamName: teamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: teamCaptain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInviteTags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId, isRequest: "true")
                        currentTeam.teammates = teammateArray
                        
                        currentInvites.append(currentTeam)
                    }
                
                for invite in currentInvites{
                    if(invite.teamName == team.teamName){
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
    }*/
    
    private func removeInvite(teamInvite: TeamInviteObject){
        let ref = Database.database().reference().child("Users").child(teamInvite.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("teamInvites")){
                    for invite in snapshot.childSnapshot(forPath: "teamInvites").children {
                        let current = invite as? DataSnapshot
                        if(current != nil){
                            if(current!.hasChild("teamName")){
                                if(current?.childSnapshot(forPath: "teamName").value as? String ?? "" == teamInvite.teamName){
                                    ref.child("teamInvites").child(current!.key).removeValue()
                                }
                            }
                        }
                    }
                }
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
