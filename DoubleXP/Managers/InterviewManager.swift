//
//  InterviewManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/20/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP
import Firebase
import SwiftNotificationCenter

class InterviewManager{
    var questions = [FAQuestion]()
    var currentQuestionIndex = -1
    var faObject: FreeAgentObject?
    var multiStepQuiz = false
    
    
    func initialize(gameName: String, uId: String){
        let profileManager = GamerProfileManager()
        faObject = FreeAgentObject(gamerTag: profileManager.getGamerTagForGame(gameName: gameName), competitionId: "", consoles: [String](), game: gameName, userId: uId, questions: [[String]]())
    }
    
    func setConsoles(console: String){
        faObject?.consoles.append(console)
        showConfirmation()
    }
    
    func showConsoles(){
        Broadcaster.notify(FreeAgentQuizNav.self) {
            $0.showConsoles()
        }
    }
    
    func showConfirmation(){
        Broadcaster.notify(FreeAgentQuizNav.self) {
            $0.showComplete()
        }
    }
    
    func showComplete(){
        Broadcaster.notify(FreeAgentQuizNav.self) {
            $0.showSubmitted()
        }
    }
    
    func showFirstQuestion(){
        Broadcaster.notify(FreeAgentQuizNav.self) {
            $0.addQuestion(question: questions[0])
        }
    }
    
    func showNextQuestion(){
        currentQuestionIndex += 1
        if(questions.count + 1 != (currentQuestionIndex + 1)){
            Broadcaster.notify(FreeAgentQuizNav.self) {
                $0.addQuestion(question: questions[currentQuestionIndex])
            }
        }
    }
    
    func updateAnswer(answer: String, question: FAQuestion){
        if(currentQuestionIndex == 0 && !question.question1SetURL.isEmpty){
            updateQuestions(answer: answer, faQuestion: question)
            
            getQuiz(url: question.question1SetURL, secondary: true, callbacks: nil)
        }
        else{
            updateQuestions(answer: answer, faQuestion: question)
            
            if((currentQuestionIndex + 1) != self.questions.count){
                showNextQuestion()
            }
            else{
               showConsoles()
            }
        }
    }
    
    func updateQuestions(answer: String, faQuestion: FAQuestion){
        for question in self.questions{
            if(question.question == faQuestion.question){
                question.answer = answer
                break
            }
        }
    }
    
    func getQuiz(url: String, secondary: Bool, callbacks: FreeAgentQuizNav?){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [[String: Any]] {
                
                    if(!secondary){
                        self.questions = [FAQuestion]()
                    }
                    else{
                        for question in self.questions{
                            if(question.questionNumber != "1"){
                                let position = self.questions.index(of: question)
                                self.questions.remove(at: position!)
                            }
                        }
                    }
                    
                    for item in jsonObj {
                        var questionNumber = ""
                        var question = ""
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
                        var required = ""
                        var questionDescription = ""
                        var acceptMultiple = ""
                        var question1SetURL = ""
                        var question2SetURL = ""
                        var question3SetURL = ""
                        var question4SetURL = ""
                        var question5SetURL = ""
                    
                        if let configDict = item as? [String: Any]{
                            for (key, value) in configDict {
                                if(key == "questionNumber"){
                                    questionNumber = (value as? String) ?? ""
                                }
                                if(key == "question"){
                                    question = (value as? String) ?? ""
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
                            }
                        }
                        let faQuestion = FAQuestion(question: question)
                        faQuestion.questionNumber = questionNumber
                        faQuestion.question = question
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
                        faQuestion.required = required
                        faQuestion.acceptMultiple = acceptMultiple
                        faQuestion.questionDescription = questionDescription
                        
                        self.questions.append(faQuestion)
                    }
                
                    DispatchQueue.main.async {
                        if(secondary){
                            self.showNextQuestion()
                        }
                        else{
                            if(!self.questions[0].question1SetURL.isEmpty){
                                self.multiStepQuiz = true
                            }
                            
                            self.checkProfileExists(multiStep: self.multiStepQuiz, callbacks: callbacks!)
                        }
                    }
                }
            }
        }
    }
    
    private func checkProfileExists(multiStep : Bool, callbacks: FreeAgentQuizNav) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let profiles = delegate.freeAgentProfiles ?? [FreeAgentObject]()
        var contained = false
        
        if(!profiles.isEmpty){
            for profile in profiles{
                if(profile.game == self.faObject?.game){
                    /*if(self.multiStepQuiz){
                        if(profile.questions[0][1] == self.faObject?.questions[0][1]){
                            contained = true
                        }
                    }
                    *///else{
                        contained = true
                    //}
                    break
                }
            }
        }
        else{
            contained = false
        }
        
        if(!contained){
            self.currentQuestionIndex = 0
            callbacks.onInitialQuizLoaded()
        }
        else{
            callbacks.showEmpty()
        }
    }
    
    func submitProfile(){
        processQuestions()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var profileList = [FreeAgentObject]()
            
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
                    profileList.append(result)
                }
            }
            
            profileList.append(self.faObject!)
            
            var array = [[String: Any]]()
            for profile in profileList{
                if(!(currentUser?.stats.isEmpty)!){
                    for statObj in currentUser!.stats{
                        if(statObj.gameName == self.faObject!.game){
                            if(statObj.gameName == "The Division 2"){
                                let statTree = ["gearScore": statObj.gearScore, "killsPVP": statObj.killsPVP, "playerLevelGame": statObj.playerLevelGame, "playerLevelPVP": statObj.playerLevelPVP]
                                
                                profile.statTree = statTree
                            }
                            else if(statObj.gameName == "Rainbow Six Siege"){
                                let statTree = ["currentRank": statObj.currentRank, "killsPVP": statObj.killsPVP, "totalRankedWins": statObj.totalRankedWins, "totalRankedLosses": statObj.totalRankedLosses, "totalRankedKills": statObj.totalRankedKills, "totalRankedDeaths": statObj.totalRankedDeaths, "mostUsedAttacker": statObj.mostUsedAttacker, "mostUsedDefender": statObj.mostUsedDefender]
                                profile.statTree = statTree
                            }
                        }
                    }
                }
                
                array.append(["gamerTag": profile.gamerTag, "competitionId": profile.competitionId, "consoles": profile.consoles, "game": profile.game, "userId": profile.userId, "questions": profile.questions, "statTree": profile.statTree])
            }
            
            ref.setValue(array)
            self.showComplete()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func processQuestions(){
        var questionsArray = [[String]]()
        for question in self.questions{
            var questionArray = [String]()
            questionArray.append(question.question)
            questionArray.append(question.answer)
            
            questionsArray.append(questionArray)
        }
        
        faObject?.questions = questionsArray
    }
}
