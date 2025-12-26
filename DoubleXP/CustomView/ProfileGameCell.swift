//
//  ProfileGameCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/13/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileGameCell: UITableViewCell {
    
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var gameBack: UIImageView!
    
    override var bounds: CGRect {
            didSet {
                setupShadow()
            }
        }

        private func setupShadow() {
            self.layer.cornerRadius = 10
            self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            self.layer.shadowRadius = 2
            self.layer.shadowOpacity = 0.5
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10)).cgPath
            self.layer.shouldRasterize = true
            self.layer.rasterizationScale = UIScreen.main.scale
        }
}
