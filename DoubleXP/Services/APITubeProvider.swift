//
//  APITubeProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import CryptoKit  // if your ArticleID.make uses CryptoKit

final class APITubeProvider: NewsProvider {
    private let apiKey = "api_live_iVuW8FsL6IXiZMDVYIY3i9Zhkpb6ShVAlnnYvFVAVE7s2q"
    private let cacheManager = JSONCacheManager<Article>(cacheFileName: "apitube")

    // In-memory storage while app is active
    private(set) var inMemoryArticles: [Article] = []

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        // 1) Disk cache first
        if let cached = cacheManager.load(), !cached.isEmpty {
            inMemoryArticles = cached
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // 2) Request
        var compReq = URLComponents(string: "https://api.apitube.io/v1/news/everything")!
        compReq.queryItems = [
            URLQueryItem(name: "topic.id", value: "video_games_news"),
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let url = compReq.url else {
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

            // ISO8601 with/without fractional seconds
            let isoNoFrac = ISO8601DateFormatter()
            isoNoFrac.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]

            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]

            // Fallback legacy formatter (rare)
            let fallbackFormatter: DateFormatter = {
                let fmt = DateFormatter()
                fmt.locale = Locale(identifier: "en_US_POSIX")
                fmt.timeZone = TimeZone(secondsFromGMT: 0)
                fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return fmt
            }()

            do {
                let decoded = try JSONDecoder().decode(APITubeResponse.self, from: data)

                let mapped: [Article] = decoded.results.compactMap { item -> Article? in
                    // Parse date
                    let parsedDate = isoFrac.date(from: item.published_at)
                                   ?? isoNoFrac.date(from: item.published_at)
                                   ?? fallbackFormatter.date(from: item.published_at)
                    guard let finalDate = parsedDate else {
                        print("❌ Could not parse APITube date:", item.published_at)
                        return nil
                    }

                    // Source label (domain → nice)
                    let sourceName = item.source.domain
                        .replacingOccurrences(of: "www.", with: "")
                        .lowercased()

                    // Deterministic ID (use href as canonical URL)
                    let id = ArticleID.make(
                        title: item.title,
                        url: item.href,
                        publishedAt: finalDate,
                        source: sourceName
                    )

                    return Article(
                        title: item.title,
                        description: item.excerpt,
                        url: item.href,
                        imageUrl: item.image,
                        publishedAt: finalDate,
                        id: id,                 // ← use generated deterministic id
                        isVideo: true,
                        videoUrl: item.href,
                        videoThumbnailUrl: item.image,
                        source: sourceName
                    )
                }

                // De-dupe by id, newest first
                var seen = Set<String>()
                var unique = [Article]()
                unique.reserveCapacity(mapped.count)
                for a in mapped.sorted(by: { $0.publishedAt > $1.publishedAt }) {
                    if seen.insert(a.id).inserted { unique.append(a) }
                }

                self.inMemoryArticles = unique
                self.cacheManager.save(unique)
                DispatchQueue.main.async { completion(unique) }
            } catch {
                print("❌ Failed to decode APITube response:", error)
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    // MARK: - Response DTOs
    private struct APITubeResponse: Decodable {
        let results: [Item]
        struct Item: Decodable {
            let title: String
            let href: String          // ← use this for the article URL
            let excerpt: String?
            let published_at: String
            let image: String?
            let source: Source
            struct Source: Decodable {
                let domain: String
            }
        }
    }
}
