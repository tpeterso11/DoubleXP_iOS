//
//  ViewTeams.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
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
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true"){
                list.append(game)
            }
        }
        
        gcGames = list
        
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
                    let dict = currentProfile.value as? [String: Any]
                    let game = dict?["game"] as? String ?? ""
                    let consoles = dict?["consoles"] as? [String] ?? [String]()
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let competitionId = dict?["competitionId"] as? String ?? ""
                    let userId = dict?["userId"] as? String ?? ""
                    
                    var questions = [FAQuestion]()
                            let questionList = dict?["questions"] as! [[String: Any]]
                            for question in questionList {
                                for (key, value) in question {
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
                                    var answer = ""
                                        var answerArray = [String]()
                                        
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
                                        if(key == "answer"){
                                            answer = (value as? String) ?? ""
                                        }
                                        if(key == "answerArray"){
                                            answerArray = (value as? [String]) ?? [String]()
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
                                        faQuestion.answer = answer
                                        faQuestion.answerArray = answerArray
                        
                            questions.append(faQuestion)
                        }
                    }
                    
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
                    let dict = currentObj.value as? [String: Any]
                    let currentTeamName = dict?["teamName"] as? String ?? ""
                    let teamId = dict?["teamId"] as? String ?? ""
                    let games = dict?["games"] as? [String] ?? [String]()
                    
                    if(self.addThisTeam(teamName: teamName, gameName: gameName, games: games, currentTeamName: currentTeamName)){
                        let consoles = dict?["consoles"] as? [String] ?? [String]()
                        let teammateTags = dict?["teammateTags"] as? [String] ?? [String]()
                        let teammateIds = dict?["teammateIds"] as? [String] ?? [String]()
                        
                        var invites = [TeamInviteObject]()
                        let teamInvites = currentObj.childSnapshot(forPath: "teamInvites")
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
                            let teammates = currentObj.childSnapshot(forPath: "teammates")
                            for invite in teammates.children{
                                let currentObj = invite as! DataSnapshot
                                let dict = currentObj.value as? [String: Any]
                                let gamerTag = dict?["gamerTag"] as? String ?? ""
                                let date = dict?["date"] as? String ?? ""
                                let uid = dict?["uid"] as? String ?? ""
                                
                                let teammate = TeammateObject(gamerTag: gamerTag, date: date, uid: uid)
                                teammateArray.append(teammate)
                            }
                        }
                        
                        var dbRequests = [RequestObject]()
                         let teamRequests = currentObj.childSnapshot(forPath: "inviteRequests")
                         for invite in teamRequests.children{
                            let currentObj = invite as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let status = dict?["status"] as? String ?? ""
                            let teamId = dict?["teamId"] as? String ?? ""
                            let teamName = dict?["teamName"] as? String ?? ""
                            let captainId = dict?["teamCaptainId"] as? String ?? ""
                            let requestId = dict?["requestId"] as? String ?? ""
                             
                            var requestProfiles = [FreeAgentObject]()
                            let test = dict?["profile"] as? [String: Any] ?? [String: Any]()
                            let game = test["game"] as? String ?? ""
                            let consoles = test["consoles"] as? [String] ?? [String]()
                            let gamerTag = test["gamerTag"] as? String ?? ""
                            let competitionId = test["competitionId"] as? String ?? ""
                            let userId = test["userId"] as? String ?? ""
                            
                            var questions = [FAQuestion]()
                                    let questionList = dict?["questions"] as! [[String: Any]]
                                    for question in questionList {
                                        for (key, value) in question {
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
                                            var answer = ""
                                                var answerArray = [String]()
                                                
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
                                                if(key == "answer"){
                                                    answer = (value as? String) ?? ""
                                                }
                                                if(key == "answerArray"){
                                                    answerArray = (value as? [String]) ?? [String]()
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
                                                faQuestion.answer = answer
                                                faQuestion.answerArray = answerArray
                                
                                    questions.append(faQuestion)
                                }
                            }
                            
                            let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                            
                            requestProfiles.append(result)
                            
                            
                            let newRequest = RequestObject(status: status, teamId: teamId, teamName: teamName, captainId: captainId, requestId: requestId)
                            newRequest.profile = requestProfiles[0]
                            
                            dbRequests.append(newRequest)
                         }
                        
                        let teamInvitetags = dict?["teamInviteTags"] as? [String] ?? [String]()
                        let captain = dict?["teamCaptain"] as? String ?? ""
                        let imageUrl = dict?["imageUrl"] as? String ?? ""
                        let teamChat = dict?["teamChat"] as? String ?? String()
                        let teamNeeds = dict?["teamNeeds"] as? [String] ?? [String]()
                        let selectedTeamNeeds = dict?["selectedTeamNeeds"] as? [String] ?? [String]()
                        let captainId = dict?["teamCaptainId"] as? String ?? String()
                        
                        let currentTeam = TeamObject(teamName: currentTeamName, teamId: teamId, games: games, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: captain, teamInvites: invites, teamChat: teamChat, teamInviteTags: teamInvitetags, teamNeeds: teamNeeds, selectedTeamNeeds: selectedTeamNeeds, imageUrl: imageUrl, teamCaptainId: captainId)
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
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for team in delegate.currentUser!.teams{
            if(team.teamName == currentTeamName){
                add = false
                break
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
        
        let cache = delegate.imageCache
        if(cache.object(forKey: game.imageUrl as NSString) != nil){
            cell.backgroundImage.image = cache.object(forKey: game.imageUrl as NSString)
        } else {
            cell.backgroundImage.image = Utility.Image.placeholder
            cell.backgroundImage.moa.onSuccess = { image in
                cell.backgroundImage.image = image
                delegate.imageCache.setObject(image, forKey: game.imageUrl as NSString)
                return image
            }
            cell.backgroundImage.moa.url = game.imageUrl
        }
        cell.backgroundImage.contentMode = .scaleAspectFill
        cell.backgroundImage.clipsToBounds = true
        
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
        
        //cell.gameBack.backgroundColor = UIColor(named: "whiteBackToDarkGrey")
        //cell.gameBack.moa.url = current.imageUrl
        //cell.gameBack.contentMode = .scaleAspectFill
        //cell.gameBack.clipsToBounds = true
        
        cell.underImage.image = Utility.Image.placeholder
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
