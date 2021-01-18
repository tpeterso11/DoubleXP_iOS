//
//  DiscoverGameIdealCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/23/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import LinearProgressBar

class DiscoverGameIdealCell: UITableViewCell {
    
    @IBOutlet weak var gameDescription: UILabel!
    @IBOutlet weak var timeCommitment: UILabel!
    @IBOutlet weak var complexityBar: LinearProgressBar!
    @IBOutlet weak var complexityDesc: UILabel!
    @IBOutlet weak var testBar: LinearProgressBar!
    @IBOutlet weak var emoji: UIImageView!
    @IBOutlet weak var condition: UILabel!
}
