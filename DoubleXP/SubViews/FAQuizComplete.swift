//
//  FAQuizComplete.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/23/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import SwiftNotificationCenter
import FBSDKCoreKit

class FAQuizComplete: ParentVC{
    @IBOutlet weak var viewTeams: UIButton!
    @IBOutlet weak var finish: UIButton!
    @IBOutlet weak var logo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageName = "FAQuiz Complete"
        
        viewTeams.layer.shadowColor = UIColor.black.cgColor
        viewTeams.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        viewTeams.layer.shadowRadius = 2.0
        viewTeams.layer.shadowOpacity = 0.5
        viewTeams.layer.masksToBounds = false
        viewTeams.layer.shadowPath = UIBezierPath(roundedRect: viewTeams.bounds, cornerRadius: viewTeams.layer.cornerRadius).cgPath
        viewTeams.addTarget(self, action: #selector(viewTamsClicked), for: .touchUpInside)
        
        finish.layer.shadowColor = UIColor.black.cgColor
        finish.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        finish.layer.shadowRadius = 2.0
        finish.layer.shadowOpacity = 0.5
        finish.layer.masksToBounds = false
        finish.layer.shadowPath = UIBezierPath(roundedRect: finish.bounds, cornerRadius: finish.layer.cornerRadius).cgPath
        finish.addTarget(self, action: #selector(finishClicked), for: .touchUpInside)
    }
    
    @objc func viewTamsClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz - Navigate To Teams"))
        LandingActivity().navigateToViewTeams()
    }
    
    @objc func finishClicked(_ sender: AnyObject?) {
         AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz - FA Dash"))
        LandingActivity().navigateToTeamFreeAgentDash()
    }
}
