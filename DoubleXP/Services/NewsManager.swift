//
//  NewsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

class NewsManager {
    static let shared = NewsManager()

    private init() {}

    func loadNewsArticles() async {
        let videoProviders: [NewsProvider] = [
            VideoRSSProvider(feedURL: URL(string: "https://www.gamespot.com/feeds/video/")!, source: "GameSpot"),
            VideoRSSProvider(feedURL: URL(string: "https://www.gameinformer.com/videos.xml")!, source: "GameInformer"),
            VideoRSSProvider(feedURL: URL(string: "https://www.destructoid.com/feed/")!, source: "Destructoid"),
            VideoRSSProvider(feedURL: URL(string: "https://www.eurogamer.net/?format=rss")!, source: "Eurogamer"),
            VideoRSSProvider(feedURL: URL(string: "https://www.polygon.com/rss/index.xml")!, source: "Polygon"),
            VideoRSSProvider(feedURL: URL(string: "https://feeds.ign.com/ign/all")!, source: "IGN"),
        ]

        let allProviders: [NewsProvider] = [
            NewsAPIProvider(),
            GameSpotProvider(),
            GameSpotVideoProvider(),
            APITubeProvider()
        ] + videoProviders

        do {
            try await withCheckedThrowingContinuation { continuation in
                AggregatedNewsService.shared.fetchAllArticles(providers: allProviders)
                continuation.resume()
            }
        } catch {
            print("⚠️ Failed to fetch articles: \(error)")
        }
    }

    /*func loadRedditPosts() async {
        let sources = [
            SubredditSource(subreddit: "Games", source: "r/Games"),
            SubredditSource(subreddit: "GamingLeaksAndRumours", source: "r/GamingLeaksAndRumours"),
            SubredditSource(subreddit: "Nintendo", source: "r/Nintendo"),
            SubredditSource(subreddit: "PS5", source: "r/PS5"),
            SubredditSource(subreddit: "PlayStation", source: "r/PlayStation"),
            SubredditSource(subreddit: "XboxSeriesX", source: "r/XboxSeriesX")
        ]

        do {
            try await withCheckedThrowingContinuation { continuation in
                let redditService = RedditJSONAPIProvider()
                redditService.fetchAllPosts(from: sources)
                continuation.resume()
            }
        } catch {
            print("⚠️ Failed to fetch Reddit posts: \(error)")
        }
    }*/
}
