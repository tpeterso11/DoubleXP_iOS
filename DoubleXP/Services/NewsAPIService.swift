//
//  NewsAPIService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

struct NewsAPIResponse: Codable {
    let articles: [UnifiedArticle]
}

// A Codable model that matches the standardized article format from your backend.
struct UnifiedArticle: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let url: String
    let imageUrl: String?
    let publishedAt: String // ISO 8601 date string from the server
    let isVideo: Bool
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let source: String
}

// A simple Codable wrapper for caching the news response.
struct NewsCacheContainer: Codable {
    let timestamp: Date
    let response: NewsAPIResponse
}

enum ArticleVisualKind {
    case video
    case image
    case text
}

extension Article {
    var visualKind: ArticleVisualKind {
        // Video wins first
        if isVideo {
            return .video
        }
        if let videoUrl = videoUrl, !videoUrl.isEmpty {
            return .video
        }
        if let thumb = videoThumbnailUrl, !thumb.isEmpty {
            return .video
        }

        // Then image-centric
        if let img = imageUrl, !img.isEmpty {
            return .image
        }

        // Fallback: text-only
        return .text
    }
}


// MARK: - Mapper to App's Existing Model
extension UnifiedArticle {
    // This function converts the data model from your API into your app's internal 'Article' model.
    func asArticle() -> Article {
        // The date from the server is already a well-formatted ISO string.
        let formatter = ISO8601DateFormatter()
        let publishedDate = formatter.date(from: self.publishedAt) ?? Date() // Fallback to now if parsing fails

        return Article(
            title: self.title,
            description: self.description,
            url: self.url,
            imageUrl: self.imageUrl,
            publishedAt: publishedDate,
            id: self.id,
            isVideo: self.isVideo,
            videoUrl: self.videoUrl,
            videoThumbnailUrl: self.videoThumbnailUrl,
            source: self.source
        )
    }
}

@MainActor
class NewsAPIService: ObservableObject {

    static let shared = NewsAPIService()
    
    // This service publishes an array of your app's existing 'Article' struct.
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // --- Caching Configuration ---
    // ⬇️ Set this to 'true' during development to use a persistent cache.
    private let devCacheEnabled = true
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "unifiedNewsFeedCache"

    // Seen IDs (for future expansion; you can hook this up when marking articles as read)
    private let seenIdsKey = "unifiedNewsSeenArticleIDs"
    private var seenIDs: Set<String> = []

    // Paging (client-side)
    private let pageSize: Int = 20
    private var allArticles: [Article] = []
    private var nextPageStartIndex: Int = 0
    private var didLoadOnce: Bool = false
    
    // !!! IMPORTANT !!!
    // Replace this placeholder with the actual, live URL for your NEW News Function.
    // It should end in "/news/v1/unified-feed"
    private let apiURLString = "https://news-datfkcsqgq-uc.a.run.app/v1/unified-feed"

    #if DEBUG
    private let debugNet = DebugNetworkController.shared
    #endif

    private init() {
        loadSeenIDs()
    }

    // MARK: - Public API

    /// Backward-compatible entry-point: if older code calls this, it just ensures the first page.
    func fetchUnifiedNews() async {
        await ensureInitialPage()
    }

    /// Called from your News tab `.task`.
    func ensureInitialPage() async {
        guard !didLoadOnce, !isLoading else { return }
        await fetchAndResetFromSource(forceNetwork: false)
    }

    /// Infinite-ish scroll: called from `NewsRow.onAppear`.
    func loadMoreIfNeeded(currentItem: Article) async {
        guard !isLoading else { return }
        guard let index = articles.firstIndex(where: { $0.id == currentItem.id }) else { return }
        
        let thresholdIndex = max(articles.count - 5, 0)
        guard index >= thresholdIndex else { return }

        // If we still have a client-side "next page", use it.
        if nextPageStartIndex < allArticles.count {
            let nextChunk = takeNextPage()
            if !nextChunk.isEmpty {
                articles.append(contentsOf: nextChunk)
                return
            }
        }

        // Optional: you could re-hit the network here and append.
        // For now, if we've exhausted allArticles, we simply stop.
    }

    // MARK: - Core fetch + mixing

    private func fetchAndResetFromSource(forceNetwork: Bool) async {
        isLoading = true
        errorMessage = nil
        
        var mapped: [Article] = []

        // 1. Try cache (unless we're forcing network)
        if !forceNetwork, let cachedArticles = loadFromCache() {
            mapped = cachedArticles
        } else {
            guard let url = URL(string: apiURLString) else {
                errorMessage = "Invalid News API URL."
                isLoading = false
                return
            }

            #if DEBUG
            // Simulate latency / failures if enabled
            try? await debugNet.simulateHit()
            #endif

            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw URLError(.badServerResponse, userInfo: ["statusCode": statusCode])
                }

                let apiResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
                
                // Map the API models to your app's Article model.
                mapped = apiResponse.articles.map { $0.asArticle() }

                // Save raw response to cache for future runs.
                saveToCache(apiResponse)

            } catch {
                let errorInfo = (error as? URLError)?.userInfo["statusCode"] ?? "unknown"
                self.errorMessage = "Failed to fetch news. Server responded with error code: \(errorInfo)."
                print("🔴 \(self.errorMessage ?? "Unknown error")")
                isLoading = false
                return
            }
        }

        // 2. Apply mixing / de-dupe / "no 5 text in a row" style logic.
        let mixed = Self.mixArticles(mapped, seenIDs: seenIDs)

        // 3. Reset paging from this new mixed list.
        allArticles = mixed
        nextPageStartIndex = 0
        let firstPage = takeNextPage()
        self.articles = firstPage

        didLoadOnce = true
        isLoading = false
        print("✅ News feed loaded: \(articles.count) visible / \(allArticles.count) total mixed.")
    }

    /// Pull the next slice from `allArticles` using `pageSize`.
    private func takeNextPage() -> [Article] {
        guard !allArticles.isEmpty else { return [] }
        guard nextPageStartIndex < allArticles.count else { return [] }

        let end = min(nextPageStartIndex + pageSize, allArticles.count)
        let slice = Array(allArticles[nextPageStartIndex..<end])
        nextPageStartIndex = end
        return slice
    }

    // MARK: - Mixing logic
    //
    // This ensures we don't get 5+ text articles in a row
    // when we *do* have video/image items to sprinkle in.
    //
    // Strategy:
    //  - Partition into videos / images / text (using Article.visualKind)
    //  - Walk them in a repeating pattern: [video, image, video, text]
    //  - If a slot's bucket is empty, fall back to the next bucket that has items.
    //  - If only text left, you *can* end up with text runs, but that's unavoidable.

    private static func mixArticles(
        _ raw: [Article],
        seenIDs: Set<String>
    ) -> [Article] {
        // De-dupe by ID and drop any in the external seenIDs set
        var seenInBatch = Set<String>()
        var deduped: [Article] = []

        for article in raw {
            let id = article.id
            if id.isEmpty {
                // If no stable ID, keep it (we can't de-dupe)
                deduped.append(article)
                continue
            }
            if seenIDs.contains(id) { continue }
            if seenInBatch.contains(id) { continue }
            seenInBatch.insert(id)
            deduped.append(article)
        }

        // Partition
        var videos: [Article] = []
        var images: [Article] = []
        var texts:  [Article] = []

        for article in deduped {
            switch article.visualKind {
            case .video:
                videos.append(article)
            case .image:
                images.append(article)
            case .text:
                texts.append(article)
            }
        }

        // Pattern: video -> image -> video -> text
        enum Slot {
            case video1
            case image
            case video2
            case text
        }
        let pattern: [Slot] = [.video1, .image, .video2, .text]

        var patternIndex = 0
        var result: [Article] = []

        var videoIndex = 0
        var imageIndex = 0
        var textIndex  = 0

        func nextVideo() -> Article? {
            guard videoIndex < videos.count else { return nil }
            let a = videos[videoIndex]
            videoIndex += 1
            return a
        }

        func nextImage() -> Article? {
            guard imageIndex < images.count else { return nil }
            let a = images[imageIndex]
            imageIndex += 1
            return a
        }

        func nextText() -> Article? {
            guard textIndex < texts.count else { return nil }
            let a = texts[textIndex]
            textIndex += 1
            return a
        }

        while videoIndex < videos.count || imageIndex < images.count || textIndex < texts.count {
            var used = false

            // Try each slot in order starting from patternIndex,
            // falling back if that bucket is empty.
            for offset in 0..<pattern.count {
                let slot = pattern[(patternIndex + offset) % pattern.count]
                switch slot {
                case .video1, .video2:
                    if let v = nextVideo() {
                        result.append(v)
                        patternIndex = (patternIndex + offset + 1) % pattern.count
                        used = true
                    }
                case .image:
                    if let i = nextImage() {
                        result.append(i)
                        patternIndex = (patternIndex + offset + 1) % pattern.count
                        used = true
                    }
                case .text:
                    if let t = nextText() {
                        result.append(t)
                        patternIndex = (patternIndex + offset + 1) % pattern.count
                        used = true
                    }
                }
                if used { break }
            }

            if !used {
                // All pattern slots empty for remaining buckets → bail.
                break
            }
        }

        return result
    }

    // MARK: - Caching Logic
    
    private func saveToCache(_ response: NewsAPIResponse) {
        let cacheContainer = NewsCacheContainer(timestamp: Date(), response: response)
        if let encodedData = try? JSONEncoder().encode(cacheContainer) {
            userDefaults.set(encodedData, forKey: cacheKey)
            print("💾 Saved new news data to cache.")
        }
    }
    
    private func loadFromCache() -> [Article]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cacheContainer = try? JSONDecoder().decode(NewsCacheContainer.self, from: data) else {
            return nil
        }
        
        // If dev mode is on, the cache is always valid.
        if devCacheEnabled {
            print("Dev cache enabled. Using cached news regardless of age.")
            return cacheContainer.response.articles.map { $0.asArticle() }
        }
        
        // For users, news cache lasts for 1 hour (3600 seconds).
        let oneHourInSeconds: TimeInterval = 3600
        if Date().timeIntervalSince(cacheContainer.timestamp) < oneHourInSeconds {
            return cacheContainer.response.articles.map { $0.asArticle() }
        } else {
            userDefaults.removeObject(forKey: cacheKey)
            print("News cache expired. Clearing old data.")
            return nil
        }
    }

    // MARK: - Seen IDs (future use)

    private func loadSeenIDs() {
        if let array = userDefaults.array(forKey: seenIdsKey) as? [String] {
            seenIDs = Set(array)
        } else {
            seenIDs = []
        }
    }

    private func persistSeenIDs() {
        let arr = Array(seenIDs)
        userDefaults.set(arr, forKey: seenIdsKey)
    }

    /// Call this later when the user actually opens / reads an article.
    func markArticleSeen(_ article: Article) {
        guard !article.id.isEmpty else { return }
        seenIDs.insert(article.id)
        persistSeenIDs()
    }
}
