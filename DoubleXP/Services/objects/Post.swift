//
//  Post.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/20/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

struct Post: Codable {
    let id: String
    let source: String
    let reddit: RedditPost?
    let publishedAt: Date
}
