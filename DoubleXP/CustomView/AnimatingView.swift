//
//  AnimatingView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/2/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class AnimatingView: UIView {
    
    
    var viewShowing = false
    
    func animateIn() {
        let layer = CAGradientLayer()
        let startLocations = [0, 0]
        let endLocations = [1, 2]

        layer.colors = [UIColor.darkGray.cgColor, UIColor.clear]
        layer.frame = self.frame
        layer.locations = startLocations as [NSNumber]
        layer.startPoint = CGPoint(x: 0.0, y: 1.0)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
        self.layer.addSublayer(layer)
        

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = startLocations
        anim.toValue = endLocations
        anim.duration = 0.5
        layer.add(anim, forKey: "loc")
        layer.locations = endLocations as [NSNumber]
        
        viewShowing = true
    }
}
