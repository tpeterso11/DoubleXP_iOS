//
//  Short.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

struct Short {
    let id: String
    let title: String
    let creator: String?
    let videoUrl: String
    let thumbnailUrl: String?
    let publishedAt: Date

    // extra metadata
    let duration: TimeInterval        // seconds
    let categoryId: String
    let tags: [String]
    let description: String
    let definition: String            // "hd" / "sd"
    let dimension: String             // "2d" / "3d"
    let embedHtml: String

    // computed
    var isVertical: Bool {             // parse out width/height
        guard
            let wMatch = embedHtml.firstMatch(of: #"width="(\d+)""#),
            let hMatch = embedHtml.firstMatch(of: #"height="(\d+)""#),
            let w = Int(wMatch[1]), let h = Int(hMatch[1])
        else { return false }
        return h > w
    }

    var isShortFormat: Bool {
        duration <= 60
            && categoryId == "20"
            && dimension == "2d"
            && isVertical
    }

    var score: Int?
}

fileprivate extension String {
    func firstMatch(of pattern: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m  = re.firstMatch(in: self, range: NSRange(self.startIndex..., in: self))
        else { return nil }
        return (0..<m.numberOfRanges).compactMap {
            let r = m.range(at: $0)
            guard r.location != NSNotFound else { return nil }
            return (self as NSString).substring(with: r)
        }
    }
}
