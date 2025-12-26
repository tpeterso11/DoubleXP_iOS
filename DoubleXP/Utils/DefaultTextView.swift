//
//  DefaultTextView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

class DefaultTextView: UITextView {
    
    private let placeholderLabel = UILabel()

    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    init(
        fontSize: CGFloat = 16,
        placeholder: String = "",
        textColor: UIColor = .label,
        placeholderColor: UIColor = .placeholderText,
        cornerRadius: CGFloat = 8,
        backgroundColor: UIColor = .secondarySystemBackground
    ) {
        super.init(frame: .zero, textContainer: nil)

        // Set up text view
        self.font = UIFont(name: "Moon-Light", size: fontSize)
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true

        // Set up placeholder
        placeholderLabel.font = UIFont(name: "Moon-Light", size: fontSize)
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.text = placeholder
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5)
        ])

        // Notification for text change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeHandler),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    @objc private func textDidChangeHandler() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}