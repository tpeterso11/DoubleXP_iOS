//
//  AggregatedNewsService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

class AggregatedNewsService {
    static let shared = AggregatedNewsService() // 🔐 Singleton instance

    private var inMemoryArticles: [Article] = []
    private let cache = JSONCacheManager<Article>(cacheFileName: "aggregated-articles")

    private init() {} // 🚫 Prevent external instantiation

    func fetchAllArticles(providers: [NewsProvider]) {
        if let cached = cache.load() {
            inMemoryArticles = cached
            return
        }

        let group = DispatchGroup()
        var results = Array(repeating: [Article](), count: providers.count)

        for (i, provider) in providers.enumerated() {
            group.enter()
            provider.fetchArticles { articles in
                results[i] = articles
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let balanced = self.mergeEvenlyPrioritizingVideos(from: results)
            let sorted = balanced.sorted { $0.publishedAt > $1.publishedAt }
            self.inMemoryArticles = sorted
            self.cache.save(sorted)
        }
    }

    private func mergeEvenlyPrioritizingVideos(from sources: [[Article]]) -> [Article] {
        // Placeholder merge logic — replace with smarter distribution if needed
        return sources.flatMap { $0 }
    }

    func getInMemoryArticles() -> [Article] {
        return inMemoryArticles
    }
}
