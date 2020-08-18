//
//  QuizOptionCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class QuizOptionCell: UITableViewCell {
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var optionBack: UIImageView!
    @IBOutlet weak var selectedCell: UIView!
    @IBOutlet weak var selectedText: UILabel!
    @IBOutlet weak var optionBlur: UIVisualEffectView!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.masksToBounds = true
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 8, bottom: 4, right: 8))
    }
}
