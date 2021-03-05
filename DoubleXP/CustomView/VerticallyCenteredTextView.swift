//
//  VerticallyCenteredTextView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Foundation

class VerticallyCenteredTextView: UITextView {
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
}
