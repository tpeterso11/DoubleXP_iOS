//
//  LookingOptionCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/27/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class LookingOptionCell : UICollectionViewCell {
    
    @IBOutlet weak var coverLabel: UILabel!
    @IBOutlet weak var cover: UIView!
    @IBOutlet weak var lookingLabel: UILabel!
    @IBOutlet weak var baseMaxWidth: NSLayoutConstraint!
    @IBOutlet weak var coverMaxWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        self.layer.cornerRadius = 4
        self.baseMaxWidth.constant = UIScreen.main.bounds.width - 8 * 2 - 8 * 2
        self.coverMaxWidth.constant = UIScreen.main.bounds.width - 8 * 2 - 8 * 2
    }
}
