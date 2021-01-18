//
//  CallFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/12/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class CallFrag: UIViewController {
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let callManager = appDelegate.callManager
        callManager.initializeCallSDK(currentUser: appDelegate.currentUser!)
    }
}
