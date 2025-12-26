//
//  BottomLeftLabel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit

@IBDesignable
class BottomLeftLabel: UILabel {

    override func drawText(in rect: CGRect) {
        guard let labelText = text else {
            super.drawText(in: rect)
            return
        }

        let textSize = (labelText as NSString).boundingRect(
            with: CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font as Any],
            context: nil
        ).size

        let newRect = CGRect(
            x: rect.origin.x,
            y: rect.maxY - textSize.height,
            width: rect.width,
            height: textSize.height
        )

        super.drawText(in: newRect)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.textAlignment = .left // Make sure horizontal alignment stays left
    }
}
