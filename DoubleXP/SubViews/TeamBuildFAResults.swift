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

class TeamBuildFAResults: UIViewController, ExpyTableViewDelegate, ExpyTableViewDataSource, UITableViewDelegate, UITableViewDataSource, TeamCallbacks{
    
    var team: TeamObject?
    var currentUser: User?
    var finalList = [FreeAgentObject]()
    var quizPayload = [Any]()
    var quizOverlayShowing = false
    var expandedCells = [Int]()
    
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
    var currentQuizPos = 0
    var cellHeights: [CGFloat] = []
    enum Const {
           static let closeCellHeight: CGFloat = 125
           static let openCellHeight: CGFloat = 205
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
                                let questions = dict["questions"] as? [[String]] ?? [[String]]()
                                
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
        let selected = team!.selectedTeamNeeds
        finalList = [FreeAgentObject]()
        
        if(!selected.isEmpty){
            for freeAgent in results{
                if(selected.contains(freeAgent.questions[0][0])){
                    finalList.append(freeAgent)
                }
            }
            
            self.setup()
        }
        else{
            var amendedList = [FreeAgentObject]()
            for agent in results{
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
            self.setup()
        }
    }
    
     private func setup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.faResults.dataSource = self
            self.faResults.delegate = self
            
            let top2 = CGAffineTransform(translationX: 0, y: -10)
            
            UIView.animate(withDuration: 0.8, animations: {
                    self.faResults.alpha = 1
                    self.faResults.transform = top2
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! FreeAgentExpandingResultCell
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let current = self.finalList[section]
        cell.gamerTag.text = current.gamerTag
        
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
      return true //Return false if you want your section not to be expandable
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if(tableView == faResults){
            return self.finalList.count
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == faResults){
            return 3
        }
        else{
            return quizPayload.count
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
    
        switch state {
        case .willExpand:
            self.expandedCells.append(section)
            print("WILL EXPAND")
            
        case .willCollapse:
            self.expandedCells.remove(at: self.expandedCells.index(of: section)!)
            print("WILL COLLAPSE")
            
        case .didExpand:
            print("DID EXPAND")
            
        case .didCollapse:
            print("DID COLLAPSE")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == faResults){
            //If you don't deselect the row here, seperator of the above cell of the selected cell disappears.
            //Check here for detail: https://stackoverflow.com/questions/18924589/uitableviewcell-separator-disappearing-in-ios7
            
            tableView.deselectRow(at: indexPath, animated: false)
            
            if(indexPath.row == 1){
                self.showQuiz(position: indexPath.section)
            }
            else{
                let button = UIButton()
                button.tag = indexPath.section
                inviteClicked(button)
            }
            
            //This solution obviously has side effects, you can implement your own solution from the given link.
            //This is not a bug of ExpyTableView hence, I think, you should solve it with the proper way for your implementation.
            //If you have a generic solution for this, please submit a pull request or open an issue.
            
            print("DID SELECT row: \(indexPath.row), section: \(indexPath.section)")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == faResults){
            let cell = tableView.dequeueReusableCell(withIdentifier: "expanded", for: indexPath) as! FreeAgentExpandingActionCell
            
            if(indexPath.row == 1){
                cell.action.text = "View Quiz"
                //cell.actionIcon.image = #imageLiteral(resourceName: "message.png")
            }
            else if(indexPath.row == 2){
                cell.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
                cell.action.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                cell.action.text = "Invite"
            }
            else{
                cell.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
                cell.action.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                cell.action.text = "Invite"
                //cell.actionIcon.image = #imageLiteral(resourceName: "information.png")
            }
            //cell.friendName.text = current.gamerTag
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
                let currentObj = current as! [String]
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
                
                cell.question.text = currentObj[0]
                cell.answer.text = currentObj[1]
                
    
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == faResults){
            if(indexPath.row == 1){
                return CGFloat(40)
            }
            if(indexPath.row == 2){
                return CGFloat(40)
            }
            if(indexPath.row == 3){
                return CGFloat(40)
            }
            return CGFloat(80)
        }
        else{
            let current = self.quizPayload[indexPath.item]
            if(current is String){
                return CGFloat(50)
            }
            else if(current is StatObject){
                return cellHeights[indexPath.row]
            }
            else{
                return CGFloat(100)
            }
        }
    }
    
    /*func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }*/
    
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
        //self.finalList.remove(at: indexPath.item)
        //self.faResults.deleteRows(at: [indexPath], with: .automatic)
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
            
            self.quizPayload.append(statObject)
        }
        
        self.quizPayload.append("Quiz")
        for array in freeAgentObject.questions{
            self.quizPayload.append(array)
        }
        
        self.quizFALabel.text = freeAgentObject.gamerTag
        self.quizTable.delegate = self
        self.quizTable.dataSource = self
        
        quizViewInvite?.tag = position
        quizViewProfile?.tag = position
        quizViewInvite?.addTarget(self, action: #selector(inviteClicked), for: .touchUpInside)
        quizViewProfile?.addTarget(self, action: #selector(profileClicked), for: .touchUpInside)
        
        let top = CGAffineTransform(translationX: -269, y: 0)
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
        if(tableView == quizTable){
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.layoutIfNeeded()
            tableView.setContentOffset(contentOffset, animated: false)
        }
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


