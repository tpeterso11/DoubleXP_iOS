//
//  Article.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

struct Article: Comparable, Codable, Hashable, Identifiable {
    let title: String
    let description: String?
    let url: String
    let imageUrl: String?
    let publishedAt: Date
    let id: String

    // ✅ New fields
    let isVideo: Bool
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let source: String

    // Sorting by published date
    static func < (lhs: Article, rhs: Article) -> Bool {
        return lhs.publishedAt < rhs.publishedAt
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}
