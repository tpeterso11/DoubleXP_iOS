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

class FADash: ParentVC, FACallbacks, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var faList: UICollectionView!
    @IBOutlet weak var searchTeams: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var profileList: UITableView!
    private var profilePayload: [FreeAgentObject] = [FreeAgentObject]()
    private var quizPayload = [[String]]()
    
    private var registered = [Int]()
    
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var quizView: UIView!
    @IBOutlet weak var quizTable: UITableView!
    @IBOutlet weak var backButton: UIView!
    @IBOutlet weak var emptyLayout: UIView!
    @IBOutlet weak var createEmpty: UIButton!
    
    private var quizOverlayShowing = false
    private var profilesLoaded = false
    
    enum Const {
           static let closeCellHeight: CGFloat = 90
           static let openCellHeight: CGFloat = 185
           static let rowsCount = 1
    }
    var cellHeights: [CGFloat] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loadProfiles()
        }
        
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
                if(!self.profilesLoaded){
                    let manager = FreeAgentManager()
                    manager.cacheProfiles(profiles: self.profilePayload)
                    
                    self.setup()
                }
                else{
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.profileList.reloadData()
                    }, completion: nil)
                }
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
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: (self.profilePayload.count))
        profileList.estimatedRowHeight = Const.closeCellHeight
        profileList.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            profileList.refreshControl = UIRefreshControl()
            profileList.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
        
        self.profileList.delegate = self
        self.profileList.dataSource = self
        
        let top = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.8, animations: {
            self.profileList.alpha = 1
            self.profileList.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.reload(tableView: self.profileList)
            }, completion: nil)
        })
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.profileList.refreshControl?.endRefreshing()
            }
            self?.profileList.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == profileList){
            return self.profilePayload.count
        }
        else{
            return quizPayload.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == profileList){
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! FADashFoldingCell
            let current = profilePayload[indexPath.item]
            cell.coverLabel.text = current.game
            cell.underLabel.text = current.gamerTag
            
            cell.quizButton.tag = indexPath.item
            cell.deleteButton.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
            cell.quizButton.addTarget(self, action: #selector(quizButtonClicked), for: .touchUpInside)
            
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
    
    func tableView(_ tableView : UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(tableView == profileList){
            guard case let cell as FADashFoldingCell = cell else {
                return
            }

            cell.backgroundColor = .clear

            if cellHeights[indexPath.row] == Const.closeCellHeight {
                cell.unfold(false, animated: false, completion: nil)
            } else {
                cell.unfold(true, animated: false, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView : UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == profileList){
            return cellHeights[indexPath.row]
        }
        else{
            return CGFloat(100)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == profileList){
            let cell = tableView.cellForRow(at: indexPath) as! FADashFoldingCell
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
    
    private func showQuiz(position: Int){
        let currentProfile = profilePayload[position]
        
        for array in currentProfile.questions{
            self.quizPayload.append(array)
        }
        
        quizTable.delegate = self
        quizTable.dataSource = self
        
        let top = CGAffineTransform(translationX: -340, y: 0)
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
        
        //let closeTap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        //clickArea.isUserInteractionEnabled = true
        //clickArea.addGestureRecognizer(closeTap)
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
        self.profilePayload.remove(at: indexPath.item)
        
        self.profileList.deleteRows(at: [indexPath], with: .fade)
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
        
        clickArea.isUserInteractionEnabled = false
    }
    
    @objc func deleteButtonClicked(_ sender: AnyObject?) {
        let manager = FreeAgentManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        manager.deleteProfile(faObject: profilePayload[(sender?.tag)!], indexPath: indexPath, currentUser: currentUser!, callbacks: self)
    }
    
    @objc func quizButtonClicked(_ sender: AnyObject?) {
        var position = sender?.tag
        if(sender?.tag != nil){
            showQuiz(position: sender!.tag)
        }
    }
}
