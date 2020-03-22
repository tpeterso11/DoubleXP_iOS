//
//  InsetLabelSmall.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class InsetLabelSmall: UILabel {
    let topInset = CGFloat(8)
    let bottomInset = CGFloat(8)
    let leftInset = CGFloat(8)
    let rightInset = CGFloat(8)

    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
