//
//  ReviewCellLarge.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Cosmos

class ReviewCellLarge : UICollectionViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var review: UILabel!
    @IBOutlet weak var ratingDesc: UILabel!
    @IBOutlet weak var ratingBar: CosmosView!
    @IBOutlet weak var ratingView: UIView!
}
