//
//  AlertCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/30/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class AlertCell: UITableViewCell {
    
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var clearAlert: UIImageView!
    @IBOutlet weak var acceptedIcon: UIView!
    @IBOutlet weak var rejectedIcon: UIView!
    @IBOutlet weak var onlineIcon: UIView!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var senderTag: UILabel!
    @IBOutlet weak var typeImage: UIImageView!
}
