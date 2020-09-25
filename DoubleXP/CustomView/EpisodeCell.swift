//
//  EpisodeCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import CollectionViewSlantedLayout

class EpisodeCell: CollectionViewSlantedCell {
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var forgetEpisode: UIImageView!
    @IBOutlet weak var sub: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var clickArea: UIView!
    
}
