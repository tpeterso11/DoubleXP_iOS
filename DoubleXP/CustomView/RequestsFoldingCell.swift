//
//  RequestsFoldingCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/12/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FoldingCell

class RequestsFoldingCell: FoldingCell{
    
    @IBOutlet weak var drawer: UIView!
    
    @IBOutlet weak var profile: UIButton!
    @IBOutlet weak var reject: UIButton!
    @IBOutlet weak var accept: UIButton!
    @IBOutlet weak var gamerTagMan: UILabel!
    @IBOutlet weak var gamerTagSub: UILabel!
    @IBOutlet weak var requestType: UILabel!
    @IBOutlet weak var requestSince: UILabel!
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var workOverlay: UIView!
    @IBOutlet weak var workOverlaySpinner: UIActivityIndicatorView!
    private var currentRequest: Any?
    private var indexPath: IndexPath!
    private var callbacks: RequestsUpdate!
    private var requested = false
    private var currentTableView: UITableView!
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        drawer.layer.cornerRadius = 10
        drawer.layer.masksToBounds = true
        
        super.awakeFromNib()
    }
    
    func setUI(friendRequest: FriendRequestObject?, team: TeamObject?, request: RequestObject?, indexPath: IndexPath, currentTableView: UITableView, callbacks: RequestsUpdate){
        self.indexPath = indexPath
        self.callbacks = callbacks
        self.currentTableView = currentTableView
        
        if(friendRequest != nil){
            currentRequest = friendRequest
            gamerTagMan.text = friendRequest?.gamerTag
            gamerTagSub.text = friendRequest?.gamerTag
            quizButton.isHidden = true
            
            requestType.text = "Friend Request"
            
            if(friendRequest != nil){
                if(!friendRequest!.date.isEmpty){
                    let daysSince = differenceInDays(date: friendRequest!.date)
                    
                    if(daysSince == 0){
                        requestSince.text = "Recieved: Today!"
                    }
                    else if(daysSince == -1){
                        requestSince.text = "Received: A while ago."
                    }
                    else{
                        requestSince.text = "Received: " + String(daysSince) + " days ago."
                    }
                }
                else{
                    requestSince.text = "Received: A while ago."
                }
            }
        }
        else if(request != nil){
            currentRequest = request
            gamerTagMan.text = request?.teamName
            gamerTagSub.text = request?.profile.gamerTag
            quizButton.isHidden = false
            
            
            quizButton.isUserInteractionEnabled = true
            quizButton.addTarget(self, action: #selector(quizClicked), for: .touchUpInside)
            
            
            requestType.text = "Invite Request"
        }
        else{
            currentRequest = team
            gamerTagMan.text = team?.teamName
            gamerTagSub.text = team?.teamName
            quizButton.isHidden = true
            
            requestType.text = "Team Invite"
            
            requestSince.isHidden = true
        }
        
    
        profile.addTarget(self, action: #selector(profileClicked), for: .touchUpInside)
        reject.addTarget(self, action: #selector(rejectClicked), for: .touchUpInside)
        accept.addTarget(self, action: #selector(acceptClicked), for: .touchUpInside)
        
        if(currentRequest is TeamObject){
            profile.titleLabel?.text = "View"
        }
    }
    
    func differenceInDays(date: String) -> Int{
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let previousDateFormated : Date? = dateFormatter.date(from: date)
        
        guard previousDateFormated != nil else{
            return -1
        }
        
        let difference = currentDate.timeIntervalSince(previousDateFormated!)
        let differenceInDays = Int(difference/(60 * 60 * 24 ))
        return differenceInDays
    }

    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
    
    @objc func profileClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let landing = delegate.currentLanding
        
        if(currentRequest is FriendRequestObject){
           landing?.navigateToProfile(uid: (currentRequest as! FriendRequestObject).uid)
        }
        else if(self.currentRequest is RequestObject){
            landing?.navigateToProfile(uid: (currentRequest as! RequestObject).profile.userId)
        }
        else{
            landing?.navigateToTeamDashboard(team: (currentRequest as! TeamObject), newTeam: false)
        }
    }
    
    @objc func acceptClicked(_ sender: AnyObject?) {
        self.showWork(indexPath: self.indexPath)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let manager = FriendsManager()
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            if(self.currentRequest is FriendRequestObject){
                manager.acceptFriendFromRequests(position: self.indexPath, otherUserRequest: (self.currentRequest as! FriendRequestObject), currentUserUid: delegate.currentUser!.uId, callbacks: self.callbacks)
            }
            else if(self.currentRequest is RequestObject){
                var currentTeam: TeamObject? = nil
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                for team in delegate.currentUser!.teams{
                    if(team.teamName == (self.currentRequest as! RequestObject).teamName){
                        currentTeam = team
                        break
                    }
                }
                
                if(currentTeam != nil){
                    let teamManager = TeamManager()
                    teamManager.acceptRequest(requestObject: self.currentRequest as! RequestObject, acceptedTeam: currentTeam!, callbacks: self.callbacks, indexPath: self.indexPath)
                }
            }
            else{
                let teamManager = TeamManager()
                teamManager.acceptTeamRequest(team: (self.currentRequest as! TeamObject), callbacks: self.callbacks, indexPath: self.indexPath)
            }
        }
    }
    
    func showWork(indexPath: IndexPath){
        self.currentTableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.currentTableView.delegate?.tableView!(self.currentTableView, didSelectRowAt: indexPath)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.workOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            self.isUserInteractionEnabled = false
            self.workOverlaySpinner.startAnimating()
        })
    }
    
    @objc func quizClicked(_ sender: AnyObject?) {
        callbacks.showQuizClicked(questions: (self.currentRequest as! RequestObject).profile.questions)
    }
    
    @objc func rejectClicked(_ sender: AnyObject?) {
        self.showWork(indexPath: self.indexPath)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let manager = FriendsManager()
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if(self.currentRequest is FriendRequestObject){
            manager.declineRequest(position: self.indexPath, otherUserRequest: (self.currentRequest as! FriendRequestObject), currentUserUid: delegate.currentUser!.uId, callbacks: self.callbacks)
            }
            else if(self.currentRequest is RequestObject){
                let manager = TeamManager()
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                var currentTeam: TeamObject?
                for team in delegate.currentUser!.teams{
                    if(team.teamName == (self.currentRequest as! RequestObject).teamName){
                        currentTeam = team
                        break
                    }
                }
                
                if(currentTeam != nil){
                    manager.rejectRequest(request: (self.currentRequest as! RequestObject), rejectedTeam: currentTeam!, callbacks: self.callbacks, indexPath: self.indexPath)
                }
            }
            else{
                let teamManager = TeamManager()
                teamManager.acceptTeamRequest(team: (self.currentRequest as! TeamObject), callbacks: self.callbacks, indexPath: self.indexPath)
            }
        }
    }
}
