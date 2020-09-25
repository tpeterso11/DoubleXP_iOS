//
//  AnnouncementCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import CollectionViewSlantedLayout

class AnnouncementCell: CollectionViewSlantedCell {
    @IBOutlet weak var announcementTitle: UILabel!
    @IBOutlet weak var announcementGame: UILabel!
    @IBOutlet weak var extraInfo: UILabel!
    @IBOutlet weak var announcementIgnore: UIImageView!
    
}
