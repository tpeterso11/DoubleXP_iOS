//
//  NewsAPIProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CryptoKit

class NewsAPIProvider: NewsProvider {
    private let apiKey = "258318830ae34f888fb1a4d7128bbda2" // Replace with your actual key
    private let cacheManager = JSONCacheManager<Article>(cacheFileName: "newsapi")

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        if let cached = cacheManager.load() {
            completion(cached)
            return
        }

        let query = "qInTitle=gaming OR videogame OR esports"
        let domains = "ign.com,pcgamer.com,gamespot.com"
        let urlStr = "https://newsapi.org/v2/everything?\(query)&domains=\(domains)&language=en&sortBy=publishedAt&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        fetchWithRetry(url: url) { data in
            guard let data = data else {
                completion([])
                return
            }

            struct NewsAPIResponse: Decodable {
                struct NewsArticle: Decodable {
                    let title: String
                    let description: String?
                    let url: String
                    let urlToImage: String?
                    let publishedAt: String
                }

                let status: String
                let totalResults: Int?
                let articles: [NewsArticle]
            }

            let formatter = ISO8601DateFormatter()

            do {
                let decoded = try JSONDecoder().decode(NewsAPIResponse.self, from: data)

                let articles = decoded.articles.compactMap { item -> Article? in
                    guard let date = formatter.date(from: item.publishedAt) else { return nil }

                    let source = self.extractSourceName(from: item.url)
                    let id = ArticleID.make(
                        title: item.title,
                        url: item.url,
                        publishedAt: date,
                        source: source
                    )

                    return Article(
                        title: item.title,
                        description: item.description,
                        url: item.url,
                        imageUrl: item.urlToImage,
                        publishedAt: date, id: id,
                        isVideo: false,
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        source: source
                    )
                }

                self.cacheManager.save(articles)
                completion(articles)
            } catch {
                print("❌ NewsAPI decoding error:", error)
                completion([])
            }
        }
    }

    /// Extracts source name from a URL (e.g. https://www.ign.com/... → IGN)
    private func extractSourceName(from urlString: String) -> String {
        guard let host = URL(string: urlString)?.host else { return "Unknown" }

        let mapping: [String: String] = [
            "ign.com": "IGN",
            "pcgamer.com": "PC Gamer",
            "gamespot.com": "GameSpot"
        ]

        let domain = host.replacingOccurrences(of: "www.", with: "")
        return mapping[domain] ?? domain.capitalized
    }
}

enum ArticleID {
    static func make(title: String?,
                     url: String?,
                     publishedAt: Date?,
                     source: String?) -> String {
        // Build a canonical fingerprint
        let canonicalURL = normalizeURL(url)
        let canonicalTitle = normalizeText(title)
        let canonicalSource = normalizeText(source)
        let canonicalDate = iso8601UTCString(from: publishedAt)

        // Prefer URL (most stable) + source, with date/title as tie-breakers
        // If url is nil, title+date+source still makes a stable fingerprint
        let fingerprint = [
            "u=\(canonicalURL ?? "")",
            "s=\(canonicalSource ?? "")",
            "d=\(canonicalDate ?? "")",
            "t=\(canonicalTitle ?? "")"
        ].joined(separator: "|")

        return sha256Base64URL(fingerprint)
    }

    // MARK: helpers

    private static func normalizeText(_ s: String?) -> String? {
        guard let s = s?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }
        // Collapse internal whitespace and lowercase for stability
        let collapsed = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.lowercased()
    }

    private static func iso8601UTCString(from date: Date?) -> String? {
        guard let date else { return nil }
        // Second-level precision is enough; UTC ensures stability across locales/timezones
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }

    /// Normalize URL: lowercase host, strip common tracking params, sort query, remove trailing slash.
    private static func normalizeURL(_ s: String?) -> String? {
        guard let s, let components = URLComponents(string: s) else { return nil }
        var c = components

        // lowercase scheme+host for stability
        c.scheme = c.scheme?.lowercased()
        c.host   = c.host?.lowercased()

        // remove default ports
        if c.port == 80 || c.port == 443 { c.port = nil }

        // clean path: remove trailing slash (except root)
        if var p = c.percentEncodedPath.removingPercentEncoding {
            if p.count > 1 && p.hasSuffix("/") { p.removeLast() }
            c.percentEncodedPath = p.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? p
        }

        // drop tracking params (extend as needed)
        let tracking = Set(["utm_source","utm_medium","utm_campaign","utm_term","utm_content","gclid","fbclid","mc_cid","mc_eid"])
        if var items = c.queryItems, !items.isEmpty {
            items = items.filter { $0.name.isEmpty == false && tracking.contains($0.name) == false }
                         .sorted { $0.name < $1.name }
            c.queryItems = items.isEmpty ? nil : items
        }

        return c.string
    }

    private static func sha256Base64URL(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        // Base64URL (no padding, URL-safe)
        var b64 = Data(digest).base64EncodedString()
        b64 = b64.replacingOccurrences(of: "+", with: "-")
                 .replacingOccurrences(of: "/", with: "_")
                 .replacingOccurrences(of: "=", with: "")
        // Keep it short if you like (e.g., 22-27 chars is common for b64url(SHA256))
        return b64
    }
}
