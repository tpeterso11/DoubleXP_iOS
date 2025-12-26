//
//  FlippableRedditCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit
import SwiftUI

final class FlippableRedditCell: UICollectionViewCell {
    static let reuseIdentifier = "FlippableRedditCell"

    // A hosting controller is the standard way to embed SwiftUI views in UIKit.
    private var hostingController: UIHostingController<FlippablePostView>?

    // This configures the cell with a RedditPost, creating or updating the SwiftUI view.
    func configure(with post: RedditPost) {
        let manager = FlippableViewManager(post: post)
        let flippableContentView = FlippablePostView(manager: manager)

        // If the cell is being reused, just update the SwiftUI view it's hosting.
        if let hostingController = self.hostingController {
            hostingController.rootView = flippableContentView
        } else {
            // If it's a new cell, create the hosting controller and add its view.
            let newHostingController = UIHostingController(rootView: flippableContentView)
            self.hostingController = newHostingController
            newHostingController.view.backgroundColor = .clear

            contentView.addSubview(newHostingController.view)
            newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newHostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                newHostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                newHostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                newHostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // It's good practice to ensure the view is reset, although SwiftUI's state should handle this.
    }
}
