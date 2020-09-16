//
//  TeamBuildFAResults.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//
import UIKit
import Firebase
import ExpyTableView

class TeamBuildFAResults: ParentVC, UITableViewDelegate, UITableViewDataSource, TeamCallbacks{
    
    var team: TeamObject?
    var currentUser: User?
    var finalList = [FreeAgentObject]()
    var quizPayload = [Any]()
    var quizOverlayShowing = false
    var expandedCells = [Int]()
    var quizSet = false
    var localImageCache = NSCache<NSString, UIImage>()
    
    @IBOutlet weak var quizViewProfile: UIButton!
    @IBOutlet weak var quizViewInvite: UIButton!
    @IBOutlet weak var closeButton: UIView!
    //@IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var quizSpecializationLabel: UILabel!
    @IBOutlet weak var quizFALabel: UILabel!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var quizView: UIView!
    
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var empty: UIView!
    @IBOutlet weak var faResults: ExpyTableView!
    @IBOutlet weak var quizTable: UITableView!
    private var teamNeedsQuestion: FAQuestion?
    var currentQuizPos = 0
    var cellHeights: [CGFloat] = []
    enum Const {
           static let closeCellHeight: CGFloat = 88
           static let openCellHeight: CGFloat = 175
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
        
        doSearch(needs: team!.selectedTeamNeeds)
        //self.view.sendSubviewToBack(self.clickArea)
    }
    
    func doSearch(needs: [String]){
        let ref = Database.database().reference().child("Free Agents V2")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var results = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for agent in snapshot.children{
                    let currentObj = agent as! DataSnapshot
                    for profile in currentObj.children{
                        let currentProfile = profile as! DataSnapshot
                        let dict = currentProfile.value as! [String: Any]
                        let game = dict["game"] as? String ?? ""
                        if((game as String) == self.team!.games[0]){
                            let consoles = dict["consoles"] as? [String] ?? [String]()
                            if(consoles.contains((self.team?.consoles[0])!)){
                                let gamerTag = dict["gamerTag"] as? String ?? ""
                                let competitionId = dict["competitionId"] as? String ?? ""
                                let userId = dict["userId"] as? String ?? ""
                                
                                var questions = [FAQuestion]()
                                let questionList = dict["questions"] as? [[String: Any]] ?? [[String: Any]]()
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
                                results.append(result)
                            }
                        }
                    }
                }
            }
            
            if(!results.isEmpty){
                self.processResults(results: results)
            }
            else{
                self.showEmpty(teamNeeds: self.team!.selectedTeamNeeds.count > 0)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func showEmpty(teamNeeds: Bool){
        if(teamNeeds){
            emptyLabel.text = "No free agents match your criteria. Please try again later."
        }
        else{
            emptyLabel.text = "No free agents available. Please try again later."
        }
        
        let top = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
            self.empty.alpha = 1
            self.empty.transform = top
        }, completion: nil)
    }
    
    private func processResults(results: [FreeAgentObject]){
        self.teamNeedsQuestion = nil
        let selected = team!.selectedTeamNeeds
        finalList = [FreeAgentObject]()
        
        if(!selected.isEmpty){
            for freeAgent in results{
                for question in freeAgent.questions {
                    if(question.teamNeedQuestion == "true"){
                        self.teamNeedsQuestion = question
                        break
                    }
                }
                
                var answer = ""
                if(self.teamNeedsQuestion != nil){
                    if(!self.teamNeedsQuestion!.answer.isEmpty){
                        answer = self.teamNeedsQuestion!.answer
                    } else {
                        answer = self.teamNeedsQuestion!.answerArray[0]
                    }
                }
                
                if(selected.contains(answer)){
                    finalList.append(freeAgent)
                }
            }
            
            if(!finalList.isEmpty){
                self.setup()
            }
            else{
                self.showEmpty(teamNeeds: self.team!.selectedTeamNeeds.count > 0)
            }
        }
        else{
            var amendedList = [FreeAgentObject]()
            for agent in results {
                var contained = false
                for invite in team!.teamInvites{
                    if(agent.userId == invite.uid){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    for teammate in team!.teammates{
                        if(teammate.uid == agent.userId){
                            contained = true
                            break
                        }
                    }
                }
                
                if(!contained){
                    amendedList.append(agent)
                }
            }
            finalList.append(contentsOf: amendedList)
            
            if(finalList.isEmpty){
                self.showEmpty(teamNeeds: self.team!.selectedTeamNeeds.count > 0)
            } else {
                self.setup()
            }
        }
    }
    
     private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: self.finalList.count)
        
        self.faResults.estimatedRowHeight = Const.closeCellHeight
        self.faResults.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            self.faResults.refreshControl = UIRefreshControl()
            self.faResults.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.faResults.dataSource = self
            self.faResults.delegate = self
            self.reload(tableView: self.faResults)
            
            let top2 = CGAffineTransform(translationX: 0, y: -10)
            
            UIView.animate(withDuration: 0.8, animations: {
                    self.faResults.alpha = 1
                    self.faResults.transform = top2
            }, completion: nil)
        }
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.faResults.refreshControl?.endRefreshing()
            }
            self?.faResults.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == faResults){
            return self.finalList.count
        }
        else{
            return quizPayload.count
        }
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as RequestsFoldingCell = cell else {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == self.faResults){
            let cell = tableView.cellForRow(at: indexPath) as! FAResultsFoldingCell

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
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == faResults){
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FAResultsFoldingCell
            let current = self.finalList[indexPath.item]
            cell.gamerTag.text = current.gamerTag
            
            var currentGame: GamerConnectGame?
            let delegate = UIApplication.shared.delegate as! AppDelegate
            for game in delegate.gcGames{
                if(game.gameName == current.game){
                    currentGame = game
                }
            }
            
            cell.quizButton.tag = indexPath.item
            cell.inviteButton.tag = indexPath.item
            
            cell.gameBack.image = Utility.Image.placeholder
            cell.gameBack.moa.url = currentGame?.imageUrl
            cell.gameBack.contentMode = .scaleAspectFill
            cell.gameBack.clipsToBounds = true
            
            cell.quizButton.addTarget(self, action: #selector(quizClicked), for: .touchUpInside)
            cell.inviteButton.addTarget(self, action: #selector(inviteClicked), for: .touchUpInside)
            
            return cell
        }
        else{
            let current = quizPayload[indexPath.item]
            if(current is String){
                //header
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! FAHeaderCell
                cell.header.text = current as? String
                
                return cell
            }
            else if (current is StatObject){
                //stat
                let currentObj = current as! StatObject
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "statCell", for: indexPath) as! FoldingCellCell
                cell.setCollectionView(stat: currentObj)
                
                return cell
            }
            else{
                let current = quizPayload[indexPath.item] as! FAQuestion
                
                if(!current.answer.isEmpty){
                    if(current.answer.contains("/DXP/")){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath) as! OptionAnswerCell
                        let adjustedPayload = [current.answer]
                        cell.question.text = current.question
                        
                        cell.setOptions(options: adjustedPayload, cache: self.localImageCache)
                        
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
                        
                        cell.question.text = current.question
                        cell.answer.text = current.answer
                        
                        return cell
                    }
                } else {
                    let currentArray = current.answerArray
                    
                    if(currentArray[0].contains("/DXP/")){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath) as! OptionAnswerCell
                        
                        cell.question.text = current.question
                        cell.setOptions(options: current.answerArray, cache: self.localImageCache)
                        
                        return cell
                    } else if(currentArray.count > 1){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "multiOptionCell", for: indexPath) as! MultiOptionCell
                        
                        cell.question.text = current.question
                        
                        cell.setPayload(payload: currentArray)
                        
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
                        
                        cell.question.text = current.question
                        cell.answer.text = currentArray[0]
                        
                        return cell
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == faResults){
            return cellHeights[indexPath.row]
        }
        else{
            let cell = tableView.cellForRow(at: indexPath)
            if(cell is AnswerTableCell){
                return CGFloat(50)
            } else if (cell is MultiOptionCell){
                 return CGFloat(140)
            } else {
                return CGFloat(180)
            }
        }
    }
    
    @objc func quizClicked(_ sender: AnyObject?) {
        showQuiz(position: (sender?.tag)!)
    }
    
    @objc func profileClicked(_ sender: AnyObject?) {
        if(self.quizOverlayShowing){
            dismissMenu()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1) ) {
               let current = self.finalList[(sender?.tag)!]
               
               let delegate = UIApplication.shared.delegate as! AppDelegate
               delegate.currentLanding!.navigateToProfile(uid: current.userId)
            }
        }
        else{
            let current = self.finalList[(sender?.tag)!]
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentLanding!.navigateToProfile(uid: current.userId)
        }
    }
    
    @objc func inviteClicked(_ sender: AnyObject?) {
        if(self.quizOverlayShowing){
            dismissMenu()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1) ) {
               let current = self.finalList[(sender?.tag)!]
               let manager = TeamManager()
               
               let obj = FriendObject(gamerTag: current.gamerTag, date: "", uid: current.userId)
               let indexPath = IndexPath(row: (sender?.tag)!, section: 0)
               
                manager.inviteToTeam(team: self.team!, friend: obj, position: indexPath, callbacks: self)
            }
        }
        else{
            let current = finalList[(sender?.tag)!]
            let manager = TeamManager()
            
            let obj = FriendObject(gamerTag: current.gamerTag, date: "", uid: current.userId)
            let indexPath = IndexPath(row: (sender?.tag)!, section: 0)
            
            manager.inviteToTeam(team: team!, friend: obj, position: indexPath, callbacks: self)
        }
    }
    
    func updateCell(indexPath: IndexPath) {
        let cell = self.faResults.cellForRow(at: indexPath) as? FAResultsFoldingCell
        cell?.unfold(true, animated: false, completion: nil)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            self.faResults.beginUpdates()
            self.faResults.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if (cell?.frame.maxY)! > self.faResults.frame.maxY {
                self.faResults.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                    self.finalList.remove(at: indexPath.item)
                    self.faResults.deleteRows(at: [indexPath], with: .automatic)
                    
                    
                    if(self.finalList.count == 0){
                        self.showEmpty(teamNeeds: !self.team!.teamNeeds.isEmpty)
                    }
                }, completion: nil)
            })
    }
    
    
    private func showQuiz(position: Int){
        let current = finalList[position]
        configureList(freeAgentObject: current, position: position)
    }
    
    private func configureList(freeAgentObject: FreeAgentObject, position: Int){
        if(!freeAgentObject.statTree.isEmpty){
            self.quizPayload.append("Stats")
            
            var statObject = StatObject(gameName: self.team!.games[0])
            
            if(self.team!.games[0] == "Rainbow Six Siege"){
                statObject.currentRank = freeAgentObject.statTree["currentRank"] ?? ""
                statObject.killsPVP = freeAgentObject.statTree["killsPVP"] ?? ""
                statObject.totalRankedWins = freeAgentObject.statTree["totalRankedWins"] ?? ""
                statObject.totalRankedLosses = freeAgentObject.statTree["totalRankedLosses"] ?? ""
                statObject.totalRankedKills = freeAgentObject.statTree["totalRankedKills"] ?? ""
                statObject.totalRankedDeaths = freeAgentObject.statTree["totalRankedDeaths"] ?? ""
                statObject.mostUsedAttacker = freeAgentObject.statTree["mostUsedAttacker"] ?? ""
                statObject.mostUsedDefender = freeAgentObject.statTree["mostUsedDefender"] ?? ""
            }
            
            if(self.team!.games[0] == "The Division 2"){
                statObject.gearScore = freeAgentObject.statTree["gearScore"] ?? ""
                statObject.killsPVP = freeAgentObject.statTree["killsPVP"] ?? ""
                statObject.playerLevelGame = freeAgentObject.statTree["playerLevelGame"] ?? ""
                statObject.playerLevelPVP = freeAgentObject.statTree["playerLevelPVP"] ?? ""
            }
            
            if(self.team!.games[0] == "Call Of Duty Modern Warfare"){
                statObject.codKd = freeAgentObject.statTree["codKd"] ?? ""
                statObject.codLevel = freeAgentObject.statTree["codLevel"] ?? ""
                statObject.codWins = freeAgentObject.statTree["codWins"] ?? ""
                statObject.codWlRatio = freeAgentObject.statTree["codWlRatio"] ?? ""
                statObject.codBestKills = freeAgentObject.statTree["codBestKills"] ?? ""
            }
            
            self.quizPayload.append(statObject)
        }
        
        for array in freeAgentObject.questions{
            self.quizPayload.append(array)
        }
        
        self.quizFALabel.text = freeAgentObject.gamerTag
        
        if(!quizSet){
            self.quizTable.delegate = self
            self.quizTable.dataSource = self
            
            self.quizSet = true
        }
        else{
            self.quizTable.reloadData()
        }
        
        quizViewInvite?.tag = position
        quizViewProfile?.tag = position
        quizViewInvite?.addTarget(self, action: #selector(inviteClicked), for: .touchUpInside)
        quizViewProfile?.addTarget(self, action: #selector(profileClicked), for: .touchUpInside)
        
        let top = CGAffineTransform(translationX: -300, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0.0, options:[], animations: {
            self.blur.alpha = 1.0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                self.quizView.transform = top
                self.quizOverlayShowing = true
                
                //self.view.bringSubviewToFront(self.clickArea)
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
                //self.clickArea.isUserInteractionEnabled = true
                //self.clickArea.addGestureRecognizer(backTap)
                
                self.closeButton.isUserInteractionEnabled = true
                self.closeButton.addGestureRecognizer(backTap)
                
                DispatchQueue.main.async(execute: {
                    self.reload(tableView: self.quizTable)
                })
            }, completion: nil)
        })
    }
    
    func reload(tableView: UITableView) {
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.setContentOffset(contentOffset, animated: false)
    }
    
    @objc func dismissMenu(){
        //quizView.viewShowing = false
        
        let top = CGAffineTransform(translationX: 249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.2, options:[], animations: {
            self.quizView.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
                //self.clickArea.isUserInteractionEnabled = false
                self.quizOverlayShowing = false
                
                self.quizPayload = [Any]()
                //self.view.sendSubviewToBack(self.clickArea)
            }, completion: nil)
        })
    }
}


