//
//  FeedPostCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class FeedPostCell: UITableViewCell {
    
    @IBOutlet weak var postVideo: UIView!
    
    @IBOutlet weak var playCover: UIView!
    @IBOutlet weak var youtubeImg: UIImageView!
    @IBOutlet weak var saveAnimation: LottieAnimationView!
    @IBOutlet weak var likeAnimation: LottieAnimationView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var gamertag: UILabel!
}
