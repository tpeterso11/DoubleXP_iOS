//
//  BasicSponsorPage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/23/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class BasicSponsorPage: ParentVC {
    
    @IBOutlet weak var body: UIView!
    @IBOutlet weak var middleImage: UIImageView!
    @IBOutlet weak var middle: UIView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var moreInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        middle.layer.cornerRadius = 15.0
        middle.layer.borderWidth = 1.0
        middle.layer.borderColor = UIColor.clear.cgColor
        middle.layer.masksToBounds = true
        
        middle.layer.shadowColor = UIColor.black.cgColor
        middle.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        middle.layer.shadowRadius = 2.0
        middle.layer.shadowOpacity = 0.5
        middle.layer.masksToBounds = false
        middle.layer.shadowPath = UIBezierPath(roundedRect: middle.bounds, cornerRadius: middle.layer.cornerRadius).cgPath
        
        body.layer.cornerRadius = 10.0
        body.layer.borderWidth = 1.0
        body.layer.borderColor = UIColor.clear.cgColor
        body.layer.masksToBounds = true
        
        body.layer.shadowColor = UIColor.black.cgColor
        body.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        body.layer.shadowRadius = 2.0
        body.layer.shadowOpacity = 0.5
        body.layer.masksToBounds = false
        body.layer.shadowPath = UIBezierPath(roundedRect: body.bounds, cornerRadius: body.layer.cornerRadius).cgPath
    }
}
