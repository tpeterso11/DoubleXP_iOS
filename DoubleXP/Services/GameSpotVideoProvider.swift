//
//  GameSpotVideoProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import CryptoKit // only if ArticleID.make uses CryptoKit

final class GameSpotVideoProvider: NewsProvider {
    private let apiKey = "6e61e45d268953e5164c5c434c36ee6607b82f1c"
    private let cacheManager = JSONCacheManager<Article>(cacheFileName: "gamespot_videos")

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0) // treat as UTC for stability
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        // 1) Cache first
        if let cached = cacheManager.load(), !cached.isEmpty {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // 2) Request
        var components = URLComponents(string: "https://www.gamespot.com/api/videos/")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sort", value: "publish_date:desc"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let url = components.url else {
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

            struct Response: Decodable {
                struct Video: Decodable {
                    let publish_date: String
                    let title: String
                    let deck: String?
                    let site_detail_url: String
                    let thumbnail: String?
                    let video_url: String?
                }
                let results: [Video]
            }

            do {
                let decoded = try JSONDecoder().decode(Response.self, from: data)

                // Return Article? so nil is allowed on parse failures
                let mapped: [Article] = decoded.results.compactMap { item -> Article? in
                    guard let pubDate = self.formatter.date(from: item.publish_date) else {
                        print("❌ GameSpot video date parse failed:", item.publish_date)
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
                        imageUrl: item.thumbnail,
                        publishedAt: pubDate,
                        id: id,
                        isVideo: true,
                        videoUrl: item.video_url,
                        videoThumbnailUrl: item.thumbnail,
                        source: "gamespot.com"
                    )
                }

                // Optional: sort newest first + de-dupe by id
                let sorted = mapped.sorted { $0.publishedAt > $1.publishedAt }
                var seen = Set<String>()
                var unique: [Article] = []
                unique.reserveCapacity(sorted.count)
                for a in sorted { if seen.insert(a.id).inserted { unique.append(a) } }

                self.cacheManager.save(unique)
                DispatchQueue.main.async { completion(unique) }
            } catch {
                print("❌ GameSpot video decoding failed:", error)
                if let s = String(data: data, encoding: .utf8) { print(s) }
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
}
