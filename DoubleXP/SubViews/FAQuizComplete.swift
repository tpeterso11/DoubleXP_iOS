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

class FAQuizComplete: ParentVC{
    @IBOutlet weak var viewTeams: UIButton!
    @IBOutlet weak var finish: UIButton!
    @IBOutlet weak var logo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageName = "FAQuiz Complete"
        viewTeams.addTarget(self, action: #selector(viewTamsClicked), for: .touchUpInside)
        finish.addTarget(self, action: #selector(finishClicked), for: .touchUpInside)
    }
    
    @objc func viewTamsClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToViewTeams()
    }
    
    @objc func finishClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentDash()
    }
}
