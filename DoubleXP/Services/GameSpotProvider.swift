//
//  GameSpotProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CryptoKit // only if ArticleID.make uses CryptoKit

final class GameSpotProvider: NewsProvider {
    private let apiKey = "6e61e45d268953e5164c5c434c36ee6607b82f1c"
    private let cacheManager = JSONCacheManager<Article>(cacheFileName: "gamespot")

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        // 1) Cache first
        if let cached = cacheManager.load(), !cached.isEmpty {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // 2) Request
        guard let url = URL(string:
            "https://www.gamespot.com/api/articles/?api_key=\(apiKey)&format=json&sort=publish_date:desc&limit=20"
        ) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        // 3) Fetch + parse
        fetchWithRetry(url: url) { [weak self] data in
            guard let self = self else { return }
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            struct GameSpotResponse: Decodable {
                struct GameSpotArticle: Decodable {
                    let title: String
                    let deck: String?
                    let publish_date: String          // "yyyy-MM-dd HH:mm:ss"
                    let site_detail_url: String       // canonical URL
                    let image: Image?
                    struct Image: Decodable { let original: String }
                }
                let results: [GameSpotArticle]
            }

            // GameSpot uses local time strings like "2025-08-20 10:45:00"
            let formatter: DateFormatter = {
                let fmt = DateFormatter()
                fmt.locale = Locale(identifier: "en_US_POSIX")
                fmt.timeZone = TimeZone(secondsFromGMT: 0) // treat as UTC to be stable
                fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return fmt
            }()

            do {
                let decoded = try JSONDecoder().decode(GameSpotResponse.self, from: data)

                // Important: return Article? in the closure
                let mapped: [Article] = decoded.results.compactMap { item -> Article? in
                    guard let pubDate = formatter.date(from: item.publish_date) else {
                        print("❌ Failed to parse GameSpot date:", item.publish_date)
                        return nil
                    }

                    // Deterministic ID from stable fields (use site_detail_url)
                    let id = ArticleID.make(
                        title: item.title,
                        url: item.site_detail_url,
                        publishedAt: pubDate,
                        source: "gamespot.com"
                    )

                    return Article(
                        title: item.title,
                        description: item.deck,
                        url: item.site_detail_url,
                        imageUrl: item.image?.original,
                        publishedAt: pubDate,
                        id: id,
                        isVideo: false,
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        source: "gamespot.com"
                    )
                }

                // Optional: sort newest first + de-dupe by id
                let sorted = mapped.sorted { $0.publishedAt > $1.publishedAt }
                var seen = Set<String>()
                var unique = [Article]()
                unique.reserveCapacity(sorted.count)
                for a in sorted { if seen.insert(a.id).inserted { unique.append(a) } }

                self.cacheManager.save(unique)
                DispatchQueue.main.async { completion(unique) }
            } catch {
                print("❌ GameSpot decoding failed:", error)
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
}
