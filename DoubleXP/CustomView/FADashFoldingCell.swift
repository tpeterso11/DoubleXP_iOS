//
//  FADashFoldingCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/20/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FoldingCell

class FADashFoldingCell: FoldingCell{
    
    @IBOutlet weak var drawer: UIView!
    @IBOutlet weak var coverLabel: UILabel!
    @IBOutlet weak var underLabel: UILabel!
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        drawer.layer.cornerRadius = 10
        drawer.layer.masksToBounds = true
        
        /*inviteButton.layer.shadowColor = UIColor.black.cgColor
        inviteButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        inviteButton.layer.shadowRadius = 2.0
        inviteButton.layer.shadowOpacity = 0.5
        inviteButton.layer.masksToBounds = false
        inviteButton.layer.shadowPath = UIBezierPath(roundedRect: inviteButton.bounds, cornerRadius: inviteButton.layer.cornerRadius).cgPath
        
        profileButton.layer.shadowColor = UIColor.black.cgColor
        profileButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        profileButton.layer.shadowRadius = 2.0
        profileButton.layer.shadowOpacity = 0.5
        profileButton.layer.masksToBounds = false
        profileButton.layer.shadowPath = UIBezierPath(roundedRect: inviteButton.bounds, cornerRadius: inviteButton.layer.cornerRadius).cgPath*/
        
        super.awakeFromNib()
    }

    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
    
    
}
