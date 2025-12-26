//
//  DiscoverGameBasicInfoCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/23/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class DiscoverGameBasicInfoCell: UITableViewCell {
    
    @IBOutlet weak var tableTopLogo: UIImageView!
    @IBOutlet weak var mobileLogo: UIImageView!
    @IBOutlet weak var nintendoLogo: UIImageView!
    @IBOutlet weak var pcLogo: UIImageView!
    @IBOutlet weak var xboxLogo: UIImageView!
    @IBOutlet weak var psLogo: UIImageView!
    @IBOutlet weak var addGameButton: UIButton!
    @IBOutlet weak var bottomDivider: UIView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var developer: UILabel!
    @IBOutlet weak var releaseDate: UILabel!
    @IBOutlet weak var genre: UILabel!
}
