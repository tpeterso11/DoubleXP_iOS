//
//  RedditJSONAPIProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/20/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

/*struct RedditListing: Codable {
    let data: RedditListingData
}

struct RedditListingData: Codable {
    let children: [RedditPostContainer]
}

struct RedditPostContainer: Codable {
    let data: RawRedditPost
}

struct RawRedditPost: Codable {
    let created_utc: TimeInterval
    let id: String
    let title: String
    let url: String
    let permalink: String
    let author: String
    let subreddit: String
    let thumbnail: String?
    let preview: RedditPreview?
    let media: RedditMedia?
    let bodyText: String?
    let score: Int?
    let commentCount: Int?
}

struct RedditMedia: Codable {
    let reddit_video: RedditVideo?
}

struct RedditVideo: Codable {
    let fallback_url: String
}

struct SubredditSource {
    let subreddit: String
    let source: String
}

class RedditJSONAPIProvider {
    // JSON cache manager with filename "reddit-posts"
    private let jsonCache = JSONCacheManager<Post>(cacheFileName: "reddit-posts")

    // In-memory store while app is active
    private(set) var inMemoryPosts: [Post] = []

    func fetchAllPosts(from sources: [SubredditSource]) {
        let group = DispatchGroup()
        var results = Array(repeating: [Post](), count: sources.count)

        for (i, source) in sources.enumerated() {
            group.enter()
            fetchRedditPosts(from: source.subreddit, source: source.source) { posts in
                results[i] = posts
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let combined = results.flatMap { $0 }
            let sorted = combined.sorted { $0.publishedAt > $1.publishedAt }

            // ✅ Store in memory
            self.inMemoryPosts = sorted

            // ✅ Save to disk cache
            self.jsonCache.save(sorted)
        }
    }

    private func fetchRedditPosts(from subreddit: String, source: String, completion: @escaping ([Post]) -> Void) {
        let urlString = "https://www.reddit.com/r/\(subreddit).json"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                let listing = try JSONDecoder().decode(RedditListing.self, from: data)

                let posts: [Post] = listing.data.children.compactMap { container -> Post? in
                    let raw = container.data

                    let imageURL = raw.preview?.images.first?.source.url
                        .replacingOccurrences(of: "&amp;", with: "&")

                    let videoURL = raw.media?.reddit_video?.fallback_url

                    // Skip text-only
                    if imageURL == nil && videoURL == nil {
                        return nil
                    }

                    let redditPost = RedditPost(
                        title: raw.title,
                        url: raw.url,
                        permalink: "https://reddit.com" + raw.permalink,
                        author: raw.author,
                        subreddit: raw.subreddit,
                        thumbnail: raw.thumbnail,
                        imageURL: imageURL,
                        videoURL: videoURL,
                        bodyText: raw.bodyText, score: raw.score ?? 0,
                        commentCount: raw.commentCount
                    )

                    let date = Date(timeIntervalSince1970: raw.created_utc)

                    return Post(id: raw.id, source: source, reddit: redditPost, publishedAt: date)
                }

                DispatchQueue.main.async {
                    completion(posts)
                }

            } catch {
                print("❌ JSON decoding error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }

    /// Optional: Load cached posts on cold launch
    func loadCachedPosts() {
        if let cached = jsonCache.load() {
            self.inMemoryPosts = cached
        }
    }
}*/
