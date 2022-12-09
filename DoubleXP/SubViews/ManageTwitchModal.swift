//
//  ManageTwitchModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/24/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class ManageTwitchModal: UIViewController {
    
    @IBOutlet weak var streamingButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var streamingAnimation: AnimationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.streamingAnimation.currentFrame = 12
        self.streamingButton.addTarget(self, action: #selector(streamButtonClicked), for: .touchUpInside)
    }
    
    @objc private func streamButtonClicked(){
        self.streamingAnimation.loopMode = .loop
        self.streamingAnimation.play()
    }
}
