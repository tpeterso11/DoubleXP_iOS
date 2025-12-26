//
//  ChatBubbleLabel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/24/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

class ChatBubbleLabel: UILabel {

    private let tailLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStyle()
    }

    private func setupStyle() {
        self.backgroundColor = .clear
        self.textColor = .white
        self.font = UIFont.systemFont(ofSize: 16)
        self.numberOfLines = 0
        self.textAlignment = .left
        self.layer.masksToBounds = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Remove old tail
        tailLayer.removeFromSuperlayer()

        // Build bubble + tail path
        let bubblePath = UIBezierPath(
            roundedRect: bounds.inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)),
            cornerRadius: 18
        )

        let tailPath = UIBezierPath()
        let startX: CGFloat = 12
        let startY: CGFloat = bounds.height - 20
        tailPath.move(to: CGPoint(x: startX, y: startY))
        tailPath.addLine(to: CGPoint(x: startX - 10, y: startY + 10))
        tailPath.addLine(to: CGPoint(x: startX + 6, y: startY + 6))
        tailPath.close()

        bubblePath.append(tailPath)

        // Tail Layer
        tailLayer.path = bubblePath.cgPath
        tailLayer.fillColor = UIColor.systemBlue.cgColor

        layer.insertSublayer(tailLayer, at: 0)
        self.textInsets = UIEdgeInsets(top: 10, left: 26, bottom: 10, right: 14) // leave room for tail
    }

    private var textInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}
