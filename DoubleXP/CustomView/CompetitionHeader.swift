//
//  CompetitionHeader.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/6/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie


class CompetitionHeader : UITableViewCell {
    
    @IBOutlet weak var liveAnim: LottieAnimationView!
    @IBOutlet weak var compTitle: UILabel!
    @IBOutlet weak var sponsorLabel: UILabel!
    @IBOutlet weak var sponsorContainer: UIView!
    @IBOutlet weak var promoImg: UIImageView!
}
