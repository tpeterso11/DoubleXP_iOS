//
//  DefaultTextField.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

class DefaultTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup(
        fontSize: CGFloat = 16,
        placeholderText: String = "",
        textColor: UIColor = .label,
        placeholderColor: UIColor = .placeholderText,
        cornerRadius: CGFloat = 8,
        backgroundColor: UIColor = .secondarySystemBackground
    ) {
        self.font = UIFont(name: "Moon-Light", size: fontSize)
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Moon-Light", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        ]
        
        if self.placeholder == nil || self.placeholder == "" {
            self.placeholder = placeholderText
        }

        self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: attributes)

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
