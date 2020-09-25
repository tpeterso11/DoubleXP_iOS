//
//  UpcomingGameCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/14/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import CountdownLabel
import CollectionViewSlantedLayout

class UpcomingGameCell: CollectionViewSlantedCell {
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var gameBack: UIImageView!
    @IBOutlet weak var closeClickArea: UIView!
    @IBOutlet weak var cellHeader: UILabel!
    var releaseDate: NSDate?
}
