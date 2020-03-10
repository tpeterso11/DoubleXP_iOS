//
//  FADash.swift
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
import SendBirdSDK
import ExpyTableView

class FADash: ParentVC, ExpyTableViewDelegate, ExpyTableViewDataSource, FACallbacks, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var faList: UICollectionView!
    @IBOutlet weak var searchTeams: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var profileList: ExpyTableView!
    private var profilePayload: [FreeAgentObject] = [FreeAgentObject]()
    private var quizPayload = [[String]]()
    
    private var registered = [Int]()
    
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var quizView: UIView!
    @IBOutlet weak var quizTable: UITableView!
    @IBOutlet weak var backButton: UIView!
    @IBOutlet weak var emptyLayout: UIView!
    @IBOutlet weak var createEmpty: UIButton!
    
    private var quizOverlayShowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        navDictionary = ["state": "backOnly"]
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        if(!delegate.navStack.contains(self)){
            delegate.navStack.append(self)
        }
        self.pageName = "Free Agent Dash"
        
        loadProfiles()
        searchTeams.addTarget(self, action: #selector(searchButtonClicked), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonClicked), for: .touchUpInside)
    }
    
    private func loadProfiles(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.profilePayload = [FreeAgentObject]()
            
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
                    self.profilePayload.append(result)
                }
            }
            
            if(!self.profilePayload.isEmpty){
                let manager = FreeAgentManager()
                manager.cacheProfiles(profiles: self.profilePayload)
                
                self.profileList.delegate = self
                self.profileList.dataSource = self
                
                self.reload(tableView: self.profileList)
            }
            else{
                self.createEmpty.addTarget(self, action: #selector(self.createButtonClicked), for: .touchUpInside)
                
                let top = CGAffineTransform(translationX: 0, y: -10)
                UIView.animate(withDuration: 0.8, animations: {
                    self.emptyLayout.alpha = 1
                    self.emptyLayout.transform = top
                }, completion: nil)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! FreeAgentDashCell
        let current = profilePayload[section]
        cell.gameName.text = current.game
        
        var backUrl = ""
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let games = delegate.gcGames!
        for game in games{
            if(game.gameName == current.game){
                backUrl = game.imageUrl
                break
            }
        }
        
        cell.gameBack.moa.url = backUrl
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        cell.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == profileList){
            return 3
        }
        else{
            return quizPayload.count
        }
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        return true //Return false if you want your section not to be expandable
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if(tableView == profileList){
            return profilePayload.count
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
    
        switch state {
        case .willExpand:
            print("WILL EXPAND")
            
        case .willCollapse:
            print("WILL COLLAPSE")
            
        case .didExpand:
            self.registered.append(section)
            print("DID EXPAND")
            
        case .didCollapse:
            if(self.registered.contains(section)){
                self.registered.remove(at: self.registered.index(of: section)!)
            }
            print("DID COLLAPSE")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == profileList){
            //If you don't deselect the row here, seperator of the above cell of the selected cell disappears.
            //Check here for detail: https://stackoverflow.com/questions/18924589/uitableviewcell-separator-disappearing-in-ios7
            
            tableView.deselectRow(at: indexPath, animated: false)
            
            if(indexPath.row == 1){
                self.showQuiz(position: indexPath.section)
            }
            else{
                if(self.registered.contains(indexPath.section)){
                    let button = UIButton()
                    button.tag = indexPath.section
                    deleteButtonClicked(button)
                }
                else{
                    self.registered.append(indexPath.section)
                }
            }
            
            //This solution obviously has side effects, you can implement your own solution from the given link.
            //This is not a bug of ExpyTableView hence, I think, you should solve it with the proper way for your implementation.
            //If you have a generic solution for this, please submit a pull request or open an issue.
            
            print("DID SELECT row: \(indexPath.row), section: \(indexPath.section)")
        }
        else{
            self.showQuiz(position: indexPath.item)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == profileList){
            let cell = tableView.dequeueReusableCell(withIdentifier: "expanded", for: indexPath) as! FreeAgentDashExpanded
            
            if(indexPath.row == 1){
                cell.action.text = "View Quiz"
                //cell.actionIcon.image = #imageLiteral(resourceName: "message.png")
            }
            else if(indexPath.row == 2){
                //cell.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
                //cell.action.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                cell.action.text = "Delete"
            }
            else{
                //cell.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
                //cell.action.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                cell.action.text = "Delete"
                //cell.actionIcon.image = #imageLiteral(resourceName: "information.png")
            }
            //cell.friendName.text = current.gamerTag
            return cell
        }
        else{
            let current = quizPayload[indexPath.item]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableCell
            
            cell.question.text = current[0]
            cell.answer.text = current[1]
            

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == profileList){
            if(indexPath.row == 1){
                return CGFloat(60)
            }
            if(indexPath.row == 2){
                return CGFloat(60)
            }
            if(indexPath.row == 3){
                return CGFloat(60)
            }
            return CGFloat(60)
        }
        else{
            //let current = self.profilePayload[indexPath.item]
            //if(current is String){
            //    return CGFloat(50)
            //}
            //else{
                return CGFloat(100)
            //}
        }
    }
    
    private func showQuiz(position: Int){
        let currentProfile = profilePayload[position]
        
        for array in currentProfile.questions{
            self.quizPayload.append(array)
        }
        
        quizTable.delegate = self
        quizTable.dataSource = self
        
        let top = CGAffineTransform(translationX: -240, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0.0, options:[], animations: {
            self.blur.alpha = 1.0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                self.quizView.transform = top
                self.quizOverlayShowing = true
                
                let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
                
                self.backButton.isUserInteractionEnabled = true
                self.backButton.addGestureRecognizer(backTap)
                
                DispatchQueue.main.async(execute: {
                    self.reload(tableView: self.quizTable)
                })
            }, completion: nil)
        })
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToViewTeams()
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentFront()
    }
    
    func updateCell(indexPath: IndexPath) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var profiles = delegate.freeAgentProfiles ?? [FreeAgentObject]()
        for profile in profiles{
            if(profile.game == self.profilePayload[indexPath.item].game){
                profiles.remove(at: profiles.index(of: profile)!)
            }
        }
        self.profilePayload.remove(at: indexPath.section)
        
        self.profileList.deleteSections([indexPath.section], with: .fade)
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
                
                self.quizPayload = [[String]]()
                //self.view.sendSubviewToBack(self.clickArea)
            }, completion: nil)
        })
    }
    
    @objc func deleteButtonClicked(_ sender: AnyObject?) {
        let manager = FreeAgentManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let indexPath = IndexPath(item: 0, section: (sender?.tag)!)
        manager.deleteProfile(faObject: profilePayload[(sender?.tag)!], indexPath: indexPath, currentUser: currentUser!, callbacks: self)
    }
}
