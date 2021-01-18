//
//  RecommendOptionsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/29/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class RecommendOptionsCell: UITableViewCell {
    @IBOutlet weak var bestImg: UIImageView!
    @IBOutlet weak var luckImg: UIImageView!
    @IBOutlet weak var locationImg: UIImageView!
    @IBOutlet weak var locationTag: UILabel!
    @IBOutlet weak var luckyTag: UILabel!
    @IBOutlet weak var bestTag: UILabel!
    @IBOutlet weak var locationButton: UIView!
    @IBOutlet weak var luckyButton: UIView!
    @IBOutlet weak var bestMatch: UIView!
    @IBOutlet weak var selection: UILabel!
    @IBOutlet weak var selectedTag: UILabel!
}
