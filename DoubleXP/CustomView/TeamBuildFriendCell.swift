//
//  TeamBuildFriendCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FoldingCell

class TeamBuildFriendCell: FoldingCell{
    
    @IBOutlet weak var drawer: UIView!
    
    
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
        
    }

    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
    
    
}

