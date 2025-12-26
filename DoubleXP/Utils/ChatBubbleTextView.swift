//
//  ChatBubbleTextView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/24/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class ChatBubbleTextView: UITextView {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.textContainerInset = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        self.layer.cornerRadius = 18
        self.layer.masksToBounds = true
    }

    init() {
        super.init(frame: .zero, textContainer: nil)
        
        self.backgroundColor = UIColor(red: 0.78, green: 0.89, blue: 1.0, alpha: 1.0) // Light blue
        self.textColor = .black
        self.font = UIFont.systemFont(ofSize: 16)
        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = false
        self.textContainer.lineFragmentPadding = 0
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
