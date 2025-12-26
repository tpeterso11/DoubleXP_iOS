//
//  FeedRivalCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class FeedRivalCell: UITableViewCell {
    
    @IBOutlet weak var statusCover: UIView!
    @IBOutlet weak var gameOfChoice: UILabel!
    @IBOutlet weak var typePill: PillLabel!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var senderPoko: UIImageView!
    @IBOutlet weak var acceptButon: UIView!
    @IBOutlet weak var rejectButton: UIView!
    @IBOutlet weak var senderTag: UILabel!
    @IBOutlet weak var inviteInfo: UILabel!
    
    override func prepareForReuse() {
            super.prepareForReuse()
            statusCover.alpha = 0
            statusCover.isHidden = true
        }
    
}
