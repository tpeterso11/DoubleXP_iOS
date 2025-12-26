//
//  DefaultButton.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit

class DefaultButton: UIButton {

    @IBInspectable var fontSize: CGFloat = 18
    @IBInspectable var customCornerRadius: CGFloat = 8

    // MARK: - Init for programmatic use
    init(
        title: String,
        fontSize: CGFloat = 18,
        backgroundColor: UIColor = .systemBlue,
        titleColor: UIColor = .white,
        customCornerRadius: CGFloat = 8
    ) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        self.setTitleColor(titleColor, for: .normal)
        self.backgroundColor = backgroundColor
        self.fontSize = fontSize
        self.customCornerRadius = customCornerRadius
        configure()
    }

    // MARK: - Init for storyboard/XIB use
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Let storyboard set title and colors first
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Delay font styling to override storyboard's default
            DispatchQueue.main.async {
                self.configure()
            }
    }

    // MARK: - Style Setup
    private func configure() {
        if let moonFont = UIFont(name: "Moon-Bold", size: fontSize) {
            titleLabel?.font = moonFont
        }

        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.85
        titleLabel?.lineBreakMode = .byTruncatingTail
        titleLabel?.textAlignment = .center

        layer.cornerRadius = customCornerRadius
        clipsToBounds = true

        if constraints.isEmpty {
            heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
}
