//
//  PlaceholderTextView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

@IBDesignable
class PlaceholderTextView: UITextView {

    private let placeholderLabel: UILabel = UILabel()

    @IBInspectable var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    @IBInspectable var placeholderColor: UIColor = UIColor.lightGray {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    @IBInspectable var placeholderFontSize: CGFloat = 14 {
        didSet {
            updatePlaceholderFont()
        }
    }

    @IBInspectable var placeholderFontName: String = "" {
        didSet {
            updatePlaceholderFont()
        }
    }

    override var font: UIFont? {
        didSet {
            updatePlaceholderFont()
        }
    }

    override var text: String! {
        didSet {
            textDidChange()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupPlaceholder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderLabel.frame.origin = CGPoint(x: textContainerInset.left + 4, y: textContainerInset.top)
        placeholderLabel.frame.size.width = frame.width - textContainerInset.left - textContainerInset.right - 8
    }

    private func setupPlaceholder() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.numberOfLines = 0
        placeholderLabel.backgroundColor = .clear
        updatePlaceholderFont()

        addSubview(placeholderLabel)
        sendSubviewToBack(placeholderLabel)

        textDidChange()
    }

    private func updatePlaceholderFont() {
        if let customFont = UIFont(name: placeholderFontName, size: placeholderFontSize) {
            placeholderLabel.font = customFont
        } else {
            placeholderLabel.font = self.font ?? UIFont.systemFont(ofSize: placeholderFontSize)
        }
    }

    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}