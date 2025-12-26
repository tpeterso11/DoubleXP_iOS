//
//  SteamProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

class SteamProvider: NewsProvider {
    private let apiKey = "YOUR_STEAM_KEY"
    private let appID: Int
    private let cacheManager: JSONCacheManager<Article>

    init(appID: Int) {
        self.appID = appID
        self.cacheManager = JSONCacheManager<Article>(cacheFileName: "steam_\(appID)")
    }

    func fetchArticles(completion: @escaping ([Article]) -> Void) {
        if let cached = cacheManager.load() {
            completion(cached)
            return
        }

        let urlStr = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=\(appID)&count=10&maxlength=300&format=json"
        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        fetchWithRetry(url: url) { data in
            guard let data = data else {
                completion([])
                return
            }

            struct Resp: Decodable {
                struct NewsItem: Decodable {
                    let title: String
                    let url: String
                    let contents: String
                    let timestamp: TimeInterval
                }

                struct AppNews: Decodable {
                    let newsitems: [NewsItem]
                }

                let appnews: AppNews
            }

            do {
                let decoded = try JSONDecoder().decode(Resp.self, from: data)
                let articles = decoded.appnews.newsitems.map { item in
                    let date = Date(timeIntervalSince1970: item.timestamp)
                    let id = ArticleID.make(
                        title: item.title,
                        url: item.url,
                        publishedAt: date,
                        source: "Steam"
                    )
                    return Article(
                        title: item.title,
                        description: item.contents,
                        url: item.url,
                        imageUrl: nil,
                        publishedAt: date,
                        id: id,
                        isVideo: false,
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        source: "Steam"
                    )
                }

                self.cacheManager.save(articles)
                completion(articles)
            } catch {
                print("❌ Steam decoding failed:", error)
                completion([])
            }
        }
    }
}
