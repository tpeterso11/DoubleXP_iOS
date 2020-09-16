//
//  Requests.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import PopupDialog
import MSPeekCollectionViewDelegateImplementation

class Requests: ParentVC, UITableViewDelegate, UITableViewDataSource, RequestsUpdate {

    var userRequests = [Any]()
    var cellHeights: [CGFloat] = []
    
    @IBOutlet weak var quizTable: UITableView!
    @IBOutlet weak var closeView: UIView!
    @IBOutlet weak var quizView: UIView!
    @IBOutlet weak var blurBack: UIVisualEffectView!
    @IBOutlet weak var quizCollection: UICollectionView!
    @IBOutlet weak var emptyLayout: UIView!
    @IBOutlet weak var requestList: UITableView!
    enum Const {
           static let closeCellHeight: CGFloat = 83
           static let openCellHeight: CGFloat = 205
           static let rowsCount = 1
    }
    
    var questionPayload = [[String]]()
    
    var quizSet = false
    
    @IBOutlet weak var requestsSub: UILabel!
    @IBOutlet weak var requestsHeader: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkRivals()
        //self.pageName = "Requests"
        //appDelegate.addToNavStack(vc: self)
    }
    
    private func animateView(){
        requestList.delegate = self
        requestList.dataSource = self
        
        let top = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.8, animations: {
            self.requestList.alpha = 1
            self.requestList.transform = top
        }, completion: nil)
    }
    
    private func buildRequests(user: User){
        if(!user.tempRivals.isEmpty){
            for rival in user.tempRivals{
                self.userRequests.append(rival)
            }
        }
        
        if(!user.pendingRequests.isEmpty){
            for request in user.pendingRequests{
                self.userRequests.append(request)
            }
        }
        
        if(!user.teamInviteRequests.isEmpty){
            for request in user.teamInviteRequests{
                self.userRequests.append(request)
            }
        }
        
        if(!user.teamInvites.isEmpty){
            for request in user.teamInvites{
                self.userRequests.append(request)
            }
        }
        
        cellHeights = Array(repeating: Const.closeCellHeight, count: self.userRequests.count)
        
        if(!userRequests.isEmpty){
            requestList.estimatedRowHeight = Const.closeCellHeight
            requestList.rowHeight = UITableView.automaticDimension
            
            if #available(iOS 10.0, *) {
                requestList.refreshControl = UIRefreshControl()
                requestList.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
            }
            
            animateView()
        }
        else{
            let top = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.emptyLayout.alpha = 1
                self.emptyLayout.transform = top
            }, completion: nil)
        }
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        for rival in currentUser.currentTempRivals{
            let dbDate = self.stringToDate(rival.date)
            
            if(dbDate != nil){
                let now = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let future = formatter.string(from: now as Date)
                let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                
                let validRival = !dbDate.compare(.isEarlier(than: dbFuture))
                
                if(dbFuture != nil){
                    if(!validRival){
                        currentUser.currentTempRivals.remove(at: currentUser.currentTempRivals.index(of: rival)!)
                    }
                }
            }
        }
        self.showView()
    }
    
    func showView(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let top = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.8, delay: 0.3, options:[], animations: {
            self.requestsHeader.alpha = 1
            self.requestsHeader.transform = top
            self.requestsSub.alpha = 1
            self.requestsSub.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                if(currentUser != nil){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.buildRequests(user: currentUser!)
                    }
                }
                else{
                    return
                }
            }, completion: nil)
        })
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.requestList.refreshControl?.endRefreshing()
            }
            self?.requestList.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == self.requestList){
            return cellHeights[indexPath.row]
        }
        else{
            return CGFloat(100)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == self.requestList){
            return self.userRequests.count
        }
        else{
            return self.questionPayload.count
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(tableView == self.requestList){
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
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == self.requestList){
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RequestsFoldingCell
            
            let current = userRequests[indexPath.item]
            
            if(current is FriendRequestObject){
                cell.setUI(friendRequest: (current as! FriendRequestObject), team: nil, request: nil, rival: nil, indexPath: indexPath, currentTableView: self.requestList, callbacks: self)
            }
            else if(current is RequestObject){
                cell.setUI(friendRequest: nil, team: nil, request: (current as! RequestObject), rival: nil, indexPath: indexPath, currentTableView: self.requestList, callbacks: self)
            }
            else if(current is RivalObj){
                cell.setUI(friendRequest: nil, team: nil, request: nil, rival: (current as! RivalObj), indexPath: indexPath, currentTableView: self.requestList, callbacks: self)
            }
            else{
                cell.setUI(friendRequest: nil, team: (current as! TeamInviteObject), request: nil, rival: nil, indexPath: indexPath, currentTableView: self.requestList, callbacks: self)
            }
            
            cell.layoutMargins = UIEdgeInsets.zero
            cell.separatorInset = UIEdgeInsets.zero
            
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "question", for: indexPath) as! RequestsQuizQuestionCell
            
            let current = self.questionPayload[indexPath.item]
            cell.question.text = current[0]
            cell.answer.text = current[1]
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == self.requestList){
            let cell = tableView.cellForRow(at: indexPath) as! RequestsFoldingCell

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
    
    //later, add "accepted" and "invited" array to user. This way. when they are invited or accepted, we can observe this in the DB and open a nice little overlay that says "you've been accepted, chat or check out the team". We cannot do this just by observing teams because if they create a team themselves, we do not want this overlay showing.
    
    func updateCell(indexPath: IndexPath) {
        if indexPath.item >= 0 && indexPath.item < self.userRequests.count {
            self.userRequests.remove(at: indexPath.item)
            self.requestList.deleteRows(at: [indexPath], with: .automatic)
            
            if(self.userRequests.isEmpty){
                UIView.animate(withDuration: 0.8, animations: {
                    self.emptyLayout.alpha = 1
                }, completion: nil)
            }
        }
    }
    
    func showQuiz(questions: [[String]]){
        self.questionPayload = [[String]]()
        self.questionPayload.append(contentsOf: questions)
        
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(hideQuiz))
        self.closeView.isUserInteractionEnabled = true
        self.closeView.addGestureRecognizer(closeTap)
        
        if(!quizSet){
            quizTable.delegate = self
            quizTable.dataSource = self
            self.reload(tableView: self.quizTable)
        }
        else{
            quizCollection.reloadData()
        }
        
        let top = CGAffineTransform(translationX: -340, y: 0)
        UIView.animate(withDuration: 0.5, animations: {
            self.blurBack.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.quizView.transform = top
            }, completion: nil)
        })
    }
    
    @objc func hideQuiz(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.5, animations: {
            self.quizView.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.blurBack.alpha = 0
            }, completion: nil)
        })
    }
    
    func showQuizClicked(questions: [[String]]){
        showQuiz(questions: questions)
    }
    
    func reload(tableView: UITableView) {
        if(tableView == quizTable){
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.layoutIfNeeded()
            tableView.setContentOffset(contentOffset, animated: false)
        }
    }
    
    func rivalRequestAlready() {
    }
    
    func rivalRequestSuccess() {
    }
    
    func rivalRequestFail() {
    }
    
    func rivalResponseAccepted(indexPath: IndexPath) {
        updateCell(indexPath: indexPath)
        showConfirmation()
    }
    
    func rivalResponseRejected(indexPath: IndexPath) {
        updateCell(indexPath: indexPath)
    }
    
    func rivalResponseFailed() {
        showFail()
    }
    
    func showConfirmation(){
        var buttons = [PopupDialogButton]()
        let title = "you accepted, we sent it."
        let message = "looks like you both are ready to play. go get online!"
        
        let buttonOne = CancelButton(title: "game time!") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func showFail(){
        var buttons = [PopupDialogButton]()
        let title = "there was an error with your request."
        let message = "try again, or jump in the chat and let them know."
        
        let buttonOne = CancelButton(title: "gotcha") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    struct Section {
        var name: String
        var items: [Any]
        
        init(name: String, items: [Any]?) {
            self.name = name
            self.items = [Any]()
        }
        
        func getCount() -> Int{
            return items.count
        }
    }
}
