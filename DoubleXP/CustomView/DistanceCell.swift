//
//  DistanceCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class DistanceCell : UITableViewCell {
    
    @IBOutlet weak var lottie: AnimationView!
    @IBOutlet weak var howFar: UILabel!
    @IBOutlet weak var cover: UIView!
    @IBOutlet weak var fifty: UIView!
    @IBOutlet weak var fiftyCover: UIView!
    @IBOutlet weak var hundred: UIView!
    @IBOutlet weak var hundredCover: UIView!
    @IBOutlet weak var timezoneButton: UIView!
    @IBOutlet weak var timezoneCover: UIView!
    @IBOutlet weak var globalButton: UIView!
    @IBOutlet weak var globalCover: UIView!
}
