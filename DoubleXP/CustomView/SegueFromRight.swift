//
//  SegueFromRight.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import UIKit

class SegueFromRight: UIStoryboardSegue {
    override func perform() {
        let src = self.source
        let dst = self.destination

        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width*2, y: 0) //Double the X-Axis
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (finished) in
            src.present(dst, animated: false, completion: nil)
        }
    }
}
