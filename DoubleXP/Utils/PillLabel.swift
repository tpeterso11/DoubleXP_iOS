//
//  PillLabel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/20/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

@IBDesignable
class PillLabel: UILabel {
    
    @IBInspectable var pillBackgroundColor: UIColor = .systemBlue {
        didSet {
            backgroundColor = pillBackgroundColor
        }
    }
    
    @IBInspectable var horizontalPadding: CGFloat = 12 {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    @IBInspectable var verticalPadding: CGFloat = 4 {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }
    
    private func setupStyle() {
        textAlignment = .center
        // Don’t override textColor or font here
        backgroundColor = pillBackgroundColor
        layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + horizontalPadding * 2,
                      height: size.height + verticalPadding * 2)
    }
}
