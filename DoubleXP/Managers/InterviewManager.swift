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
import moa

class InterviewManager{
    var questions = [FAQuestion]()
    var imageCache = NSCache<NSString, UIImage>()
    var currentQuestionIndex = -1
    var faObject: FreeAgentObject?
    var multiStepQuiz = false
    var optionCache = [OptionObj]()
    var currentGCGame: GamerConnectGame!
    
    func initialize(gameName: String, uId: String, gamerConnectGame: GamerConnectGame){
        self.currentGCGame = gamerConnectGame
        let profileManager = GamerProfileManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        faObject = FreeAgentObject(gamerTag: profileManager.getGamerTag(user: delegate.currentUser!), competitionId: "", consoles: [String](), game: gameName, userId: uId, questions: [FAQuestion]())
    }
    
    func setConsoles(console: String){
        faObject?.consoles.append(console)
        submitProfile()
        //showConfirmation()
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
            $0.addQuestion(question: questions[0], interviewManager: self)
        }
    }
    
    func showNextQuestion(){
        currentQuestionIndex += 1
        if(questions.count + 1 != (currentQuestionIndex + 1)){
            Broadcaster.notify(FreeAgentQuizNav.self) {
                $0.addQuestion(question: questions[currentQuestionIndex], interviewManager: self)
            }
        }
    }
    
    func updateAnswer(answer: String?, answerArray: [String]?, question: FAQuestion){
        if(currentQuestionIndex == 0 && !question.question1SetURL.isEmpty){
            updateQuestions(answer: answer, answerArray: answerArray, faQuestion: question)
            
            getQuiz(url: question.question1SetURL, secondary: true, gameName: self.currentGCGame.gameName, callbacks: nil)
        }
        else{
            updateQuestions(answer: answer, answerArray: answerArray, faQuestion: question)
            
            if((currentQuestionIndex + 1) != self.questions.count){
                showNextQuestion()
            }
            else{
                if(currentGCGame.availablebConsoles.count == 1){
                    setConsoles(console: currentGCGame.availablebConsoles[0])
                    return
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser!
                var console = ""
                var consoleTwo = ""
                for profile in currentUser.gamerTags {
                    if(profile.game == currentGCGame.gameName){
                        if(console.isEmpty){
                            console = profile.console
                        } else {
                            consoleTwo = profile.console
                        }
                    }
                }
                if(!console.isEmpty && consoleTwo.isEmpty){
                    setConsoles(console: console)
                } else {
                    showConsoles()
                }
            }
        }
    }
    
    func updateQuestions(answer: String?, answerArray: [String]?, faQuestion: FAQuestion){
        for question in self.questions{
            if(question.question == faQuestion.question){
                let number = Int(question.maxOptions)
                if(number ?? 0 > 1){
                    question.answerArray = answerArray!
                } else {
                    question.answer = answer!
                }
                break
            }
        }
    }
    
    func getQuiz(url: String, secondary: Bool, gameName: String, callbacks: FreeAgentQuizNav?){
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
                        if(!optionsURL.isEmpty){
                            self.getOptions(url: optionsURL, gameName: gameName)
                        }
                        
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
    
    func getOptions(url: String, gameName: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArr = jsonObj!.value(forKey: "data") as? [String: Any] {
                        var options = [OptionObj]()
                        var tagOps = [String]()
                        for (key, value) in resultArr {
                            let option = value as? [String: Any] ?? [String: Any]()
                            let label = option["name"] as? String ?? ""
                            let title = option["title"] as? String ?? ""
                            let imageChild = option["image"] as? [String: Any] ?? [String: Any]()
                            let image = imageChild["full"] as? String ?? ""
                            let tags = option["tags"] as? [String] ?? [String]()
                            for tag in tags{
                                if(!tagOps.contains(tag)){
                                    tagOps.append(tag)
                                }
                            }
                            
                            if(gameName == "League of Legends"){
                                let imageUrl = self.convertLoLImageUrl(imageName: image)
                                let moa = Moa()
                                moa.onSuccess = { image in
                                  // image is loaded
                                    self.imageCache.setObject(image, forKey: imageUrl as NSString)
                                    return image
                                }
                                moa.url = imageUrl
                                
                                let optionObj = OptionObj(optionLabel: label, imageUrl: imageUrl, sortingTags: tags)
                                                           optionObj.title = title
                                                           options.append(optionObj)
                            } else {
                                let imageUrl = image
                                let moa = Moa()
                                moa.onSuccess = { image in
                                  // image is loaded
                                    self.imageCache.setObject(image, forKey: imageUrl as NSString)
                                    return image
                                }
                                moa.url = imageUrl
                                
                                let optionObj = OptionObj(optionLabel: label, imageUrl: imageUrl, sortingTags: tags)
                                                           optionObj.title = title
                                                           options.append(optionObj)
                            }
                        }
                        
                        self.optionCache = options.sorted { $0.optionLabel < $1.optionLabel }
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
            let delegate = UIApplication.shared.delegate as! AppDelegate
            var maxProfiles = 1
            
            let appProps = delegate.appProperties
            //if(appProps.value(forKey: "max_profiles") as? String != nil){
            if(appProps.value(forKey: "count") as? String != nil){
                //maxProfiles = Int((appProps.value(forKey: "max_profiles") as? String)!)!
                maxProfiles = Int((appProps.value(forKey: "count") as? String)!)!
            }
            
            if(maxProfiles > 1){
                self.currentQuestionIndex = 0
                callbacks.onInitialQuizLoaded()
            }
            else{
                callbacks.showEmpty()
            }
        }
    }
    
    func submitProfile(){
        faObject?.questions = self.questions
        
        sendFilterQuestions()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var profileList = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for profile in snapshot.children{
                    let currentProfile = profile as! DataSnapshot
                    let dict = currentProfile.value as? [String: Any]
                    let game = dict?["game"] as? String ?? ""
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let competitionId = dict?["competitionId"] as? String ?? ""
                    let userId = dict?["userId"] as? String ?? ""
                    
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
                    
                let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                profileList.append(result)
            }
        }
        profileList.append(self.faObject!)
        
        var array = [[String: Any]]()
        for profile in profileList{
            var questions = [[String: Any]]()
            for question in profile.questions {
                let currentQuestion = question
                let currentDict = ["question": currentQuestion.question, "answer": currentQuestion.answer, "questionAnswered": currentQuestion.questionAnswered, "acceptMultiple": currentQuestion.acceptMultiple, "questionDescription": currentQuestion.questionDescription, "required": currentQuestion.required, "question5SetURL": currentQuestion.question5SetURL, "option5Description": currentQuestion.option5Description,  "option5": currentQuestion.option5, "question4SetURL": currentQuestion.question4SetURL, "option4Description": currentQuestion.option4Description, "option4": currentQuestion.option4,"question3SetURL": currentQuestion.question3SetURL, "option3Description": currentQuestion.option3Description, "option3": currentQuestion.option3,"question2SetURL": currentQuestion.question2SetURL, "option2Description": currentQuestion.option2Description, "option2": currentQuestion.option1,"question1SetURL": currentQuestion.question1SetURL, "option1Description": currentQuestion.option1Description, "option1": currentQuestion.option1, "teamNeedQuestion": currentQuestion.teamNeedQuestion, "optionsUrl": currentQuestion.optionsUrl, "maxOptions": currentQuestion.maxOptions, "answerArray": currentQuestion.answerArray, "questionNumber": currentQuestion.questionNumber] as [String : Any]
                
                questions.append(currentDict)
            }
            
            array.append(["gamerTag": profile.gamerTag, "competitionId": profile.competitionId, "consoles": profile.consoles, "game": profile.game, "userId": profile.userId, "questions": questions, "statTree": profile.statTree])
        }
        ref.setValue(array)
        self.showComplete()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertLoLImageUrl(imageName: String) -> String{
        return "http://ddragon.leagueoflegends.com/cdn/10.11.1/img/champion/"+imageName
    }
    
    private func sendFilterQuestions(){
        var filterQuestions = [FAQuestion]()
        for question in self.questions {
            if(question.teamNeedQuestion == "true"){
                filterQuestions.append(question)
            }
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("gamerTags")){
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                for gamerTagObj in gamerTagsArray.children {
                    let currentObj = gamerTagObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let currentGame = dict?["game"] as? String ?? ""
                    
                    if(currentGame == self.currentGCGame.gameName){
                        for filterQuestion in filterQuestions {
                            if(!filterQuestion.answer.isEmpty){
                                ref.child("gamerTags").child(currentObj.key).child("filterQuestions").child(filterQuestion.question).setValue([filterQuestion.answer])
                            } else {
                                ref.child("gamerTags").child(currentObj.key).child("filterQuestions").child(filterQuestion.question).setValue(filterQuestion.answerArray)
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    //we basically need to refactor the quiz to have it so every time we answer a question, we add it to ONE central question dictionary. If it is a multi-answer, we append "array", if it's a single answer -> "answer". We will then have to make this change for Android to make sure we properly show quizzes in both apps.
    /*private func processQuestions(){
        var orderedDictionary = OrderedDictionary<FAQuestion, Any>()
    
        for question in self.questions {
            if(!question.answerArray.isEmpty){
                orderedDictionary[question] = question.answerArray
            } else {
                orderedDictionary[question] = question.answer
            }
        }
        
        faObject?.questions = orderedDictionary
    }*/
}
