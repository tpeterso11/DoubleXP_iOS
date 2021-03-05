//
//  ProfileTwitchCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import WebKit

class ProfileTwitchCell: UITableViewCell {
    
    @IBOutlet weak var fullWVShell: UIView!
    @IBOutlet weak var onlineView: UIView!
    @IBOutlet weak var connectView: UIView!
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet weak var notConnectedView: UIView!
    @IBOutlet weak var workBlur: UIVisualEffectView!
    @IBOutlet weak var workSpinner: AnimationView!
    @IBOutlet weak var currentUserView: UIView!
    @IBOutlet weak var twitchWV: WKWebView!
    @IBOutlet weak var twitchLogo: UIImageView!
    @IBOutlet weak var popOutPlayer: TestPlayer!
}
