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
    @IBOutlet weak var reject: UIImageView!
    @IBOutlet weak var accept: UIImageView!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var gamerTagMan: UILabel!
    @IBOutlet weak var gamerTagSub: UILabel!
    @IBOutlet weak var requestType: UILabel!
    @IBOutlet weak var requestSince: UILabel!
    private var currentRequest: Any?
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        drawer.layer.cornerRadius = 10
        drawer.layer.masksToBounds = true
        
        super.awakeFromNib()
    }
    
    func setUI(friendRequest: FriendRequestObject?, team: TeamObject?){
        if(friendRequest != nil){
            currentRequest = friendRequest
            gamerTagMan.text = friendRequest?.gamerTag
            gamerTagSub.text = friendRequest?.gamerTag
            
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
        else{
            currentRequest = team
            gamerTagMan.text = team?.teamName
            gamerTagSub.text = team?.teamName
            
            requestType.text = "Team Invite"
            
            requestSince.isHidden = true
        }
        
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(profileClicked))
        profile.isUserInteractionEnabled = true
        profile.addGestureRecognizer(profileTap)
        
        if(currentRequest is TeamObject){
            profile.image = #imageLiteral(resourceName: "dashboard.png")
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
        else{
            landing?.navigateToTeamDashboard(team: (currentRequest as! TeamObject), newTeam: false)
        }
    }
}
