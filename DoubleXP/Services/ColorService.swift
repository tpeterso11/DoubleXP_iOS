//
//  ColorService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/6/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ColorService {
    static let shared = ColorService()
    
    // A simple in-memory cache. The key will be the image URL string.
    private var colorCache = NSCache<NSString, UIColor>()
    
    private init() {}
    
    /// Asynchronously finds the dominant color for an image, using a cache to avoid re-calculation.
    /// - Parameters:
    ///   - image: The `UIImage` to analyze.
    ///   - cacheKey: A unique string to identify this image, typically its URL.
    /// - Returns: The dominant `UIColor`, fetched from the cache or newly calculated.
    func findDominantColor(for image: UIImage, with cacheKey: String) async -> UIColor? {
        let key = cacheKey as NSString
        
        // 1. Check the cache first. If we find a color, return it instantly.
        if let cachedColor = colorCache.object(forKey: key) {
            print("✅ [ColorService] Found dominant color in cache for key: \(cacheKey)")
            return cachedColor
        }
        
        // 2. If not in the cache, perform the calculation on a background thread.
        print("🟡 [ColorService] No cached color. Calculating dominant color for key: \(cacheKey)")
        
        guard let coreImage = CIImage(image: image) else {
            print("🔴 [ColorService] Failed to convert UIImage to CIImage.")
            return nil
        }

        let extentVector = CIVector(x: coreImage.extent.origin.x, y: coreImage.extent.origin.y, z: coreImage.extent.size.width, w: coreImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: coreImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            print("🔴 [ColorService] Failed to create Core Image filter.")
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let red   = CGFloat(bitmap[0]) / 255.0
        let green = CGFloat(bitmap[1]) / 255.0
        let blue  = CGFloat(bitmap[2]) / 255.0
        let alpha = CGFloat(bitmap[3]) / 255.0
        
        let dominantColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        
        // 3. Store the newly calculated color in the cache for next time.
        print("💾 [ColorService] Caching new dominant color for key: \(cacheKey)")
        colorCache.setObject(dominantColor, forKey: key)
        
        return dominantColor
    }
}

extension UIColor {

    /// A computed property that returns either black or white, whichever
    /// provides better contrast against the current color.
    var contrastingTextColor: UIColor {
        // This algorithm calculates the "perceived brightness" of the color.
        // A value greater than 0.5 is considered a "light" color.
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the RGBA components of the color
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Formula for luminance (perceived brightness)
        let luminance = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        
        // If the color is light, return black text. Otherwise, return white text.
        return luminance > 0.5 ? .black : .white
    }
}
