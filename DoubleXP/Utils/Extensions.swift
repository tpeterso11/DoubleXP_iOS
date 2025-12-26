//
//  Extensions.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/6/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    /// Creates a placeholder image with a subtle dark gradient.
    static func placeholder(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: size)
            
            // A subtle, dark gray to black gradient
            let darkColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
            let blackColor = UIColor.black.cgColor
            gradientLayer.colors = [darkColor, blackColor]
            
            // Make it a diagonal gradient
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            gradientLayer.render(in: context.cgContext)
        }
        
        return image
    }
}

private var taskKey: Void?

extension UIImageView {
    
    private var imageLoadTask: Task<Void, Never>? {
        get { objc_getAssociatedObject(self, &taskKey) as? Task<Void, Never> }
        set { objc_setAssociatedObject(self, &taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Loads an image asynchronously from a URL with full support for caching and placeholders.
    ///
    /// This method automatically cancels any previous in-flight requests for the same image view,
    /// preventing incorrect images from showing up in reused cells during fast scrolling.
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - placeholder: An optional placeholder image to display while the image is loading.
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        // Cancel any previous download task for this specific image view.
        imageLoadTask?.cancel()

        // 1. Set the placeholder image immediately.
        self.image = placeholder
        
        guard let url = url else { return }

        // 2. Start a new background task to load the image.
        imageLoadTask = Task {
            // Fetch the image from the cache or network.
            let loadedImage = await ImageCache.shared.image(for: url)
            
            // If this task has been cancelled, do not proceed.
            if Task.isCancelled { return }
            
            // Update the UI on the main thread with a gentle cross-fade animation.
            await MainActor.run {
                UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.image = loadedImage ?? placeholder
                })
            }
        }
    }
}
