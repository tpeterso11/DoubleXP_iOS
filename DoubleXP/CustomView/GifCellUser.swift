//
//  GifCellUser.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/19/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class GifCellUser : UITableViewCell{
    
    @IBOutlet weak var gifImage: UIImageView!
    @IBOutlet weak var gifImageSender: UILabel!
    
    /*internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                gifImage.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                gifImage.addConstraint(aspectConstraint!)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
    }

    func setCustomImage(image : UIImage) {

        let aspect = image.size.width / image.size.height

        let constraint = NSLayoutConstraint(item: gifImage, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: gifImage, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
        constraint.priority = UILayoutPriority(rawValue: 999)

        aspectConstraint = constraint

        gifImage.image = image
    }*/
}
