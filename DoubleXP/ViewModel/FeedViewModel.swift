//
//  FeedViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import Combine

struct ForYouPayload: Hashable, Equatable {
    let payload: [FeedCard]
}

enum FeedCard: Hashable, Equatable {
    case normal(GamerConnectGame)
    case featured(GamerConnectGame)
}

struct FeedItem: Identifiable, Hashable { // Added Hashable
    var id = UUID()
    var itemType: FeedItemType
    
    enum FeedItemType: Hashable {
        case header([FeedHeaderMediaObj]) // <-- Updated
        case recommended(ForYouPayload)
        case upcomingGames([GamerConnectGame])
        case sectionHeader(String)
        case invite(RivalObj)     // <-- Added
        case accepted(RivalObj)   // <-- Added
        case rejected(RivalObj)   // <-- Added
    }
    
    // Helper to generate IDs for ForEach
    var hashValue: Int {
        switch itemType {
        case .header(let items):
            return "header".hashValue ^ items.hashValue
        case .recommended(let items):
            return "recommended".hashValue ^ items.hashValue
        //case .featuredGames(let items):
        //    return "featured".hashValue ^ items.hashValue
        //case .trendingGames(let items):
        //    return "trending".hashValue ^ items.hashValue
        case .upcomingGames(let items):
            return "upcoming".hashValue ^ items.hashValue
        case .sectionHeader(let title):
            return "section".hashValue ^ title.hashValue
        case .invite(let item):
            return "invite".hashValue ^ item.hashValue
        case .accepted(let item):
            return "accepted".hashValue ^ item.hashValue
        case .rejected(let item):
            return "rejected".hashValue ^ item.hashValue
        }
    }
    
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

@MainActor
class FeedViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var loadState: FeedLoadState = .idle
    @Published var headerLoadState: FeedLoadState = .idle  // Separate state for header
    @Published var carouselItems: [CarouselMediaItem] = []
    @Published var feedItems: [FeedItem] = []
    
    // Game data - populated from cache or API
    @Published var featuredGames: [GamerConnectGame] = []
    @Published var recommendedGames: [GamerConnectGame] = []
    @Published var upcomingGames: [GamerConnectGame] = []
    @Published var trendingGames: [GamerConnectGame] = []
    
    // Track if initial load has completed (for skeleton logic)
    @Published private(set) var hasCompletedInitialLoad: Bool = false
    
    // MARK: - Services
    
    private let apiService = GameAPIService.shared
    private let feedDataManager = FeedDataManager.shared
    private let storage = GameStorageManager.shared
    private let firebaseService = AggregatedFirebaseService.shared
    
    // For mock invites during development
    private let shouldUseMockInvites = true
    
    // MARK: - Initialization
    
    init() {
        // Load cached data immediately for instant display
        loadCachedFeedData()
    }
    
    // MARK: - Cache Loading
    
    private func loadCachedFeedData() {
        let cached = storage.getCachedFeedData()
        
        self.featuredGames = cached.featured
        self.recommendedGames = cached.recommended.isEmpty ? cached.trending : cached.recommended
        self.upcomingGames = cached.upcoming
        self.trendingGames = cached.trending
        
        // If we have cached data, mark as loaded so UI shows content immediately
        if storage.hasCachedFeedData {
            print("📦 [FeedVM] Loaded cached feed data")
        }
    }
    
    // MARK: - Data Loading
    
    func loadInitialData(userGames: [String]) async {
        // Check if we should show skeleton (first load with no cached data)
        let shouldShowSkeleton = !hasCompletedInitialLoad && !storage.hasCachedFeedData
        
        if shouldShowSkeleton {
            withAnimation { loadState = .loading }
            // Small delay for skeleton visibility (better UX)
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
        
        // Fetch header content - handle errors separately
        headerLoadState = .loading
        do {
            let headerResult = try await fetchHeaderContent()
            feedDataManager.headerContent = headerResult
            self.carouselItems = headerResult.map { CarouselMediaItem(mediaObj: $0) }
            headerLoadState = .loaded
            print("✅ [FeedVM] Header loaded: \(headerResult.count) items")
        } catch {
            let message = headerErrorMessage(from: error)
            print("❌ [FeedVM] Header fetch failed: \(error)")
            headerLoadState = .error(message)
            // Continue loading the rest of the feed even if header fails
        }
        
        // Fetch game data
        do {
            // GameAPIService.fetchStartupGames() handles mock/cached/live logic internally
            await apiService.fetchStartupGames()
            
            // Check for API errors
            if let error = apiService.startupGamesErrorMessage {
                throw FeedError.apiError(error)
            }
            
            // Update local state from API service
            self.featuredGames = apiService.featuredGames
            self.recommendedGames = apiService.recommendedGames.isEmpty ? apiService.trendingGames : apiService.recommendedGames
            self.upcomingGames = apiService.upcomingGames
            self.trendingGames = apiService.trendingGames
            
            // Build feed payload
            buildFeedPayload()
            
            // Mark complete
            hasCompletedInitialLoad = true
            
            withAnimation(.easeOut(duration: 0.4)) {
                loadState = .loaded
            }
            
            print("✅ [FeedVM] Feed loaded")
            
        } catch {
            handleLoadError(error)
        }
    }
    
    func refreshFeed(userGames: [String]) async {
        // Invalidate cache to force fresh fetch
        storage.invalidateFeedCache()
        
        // Refresh header
        headerLoadState = .loading
        do {
            let headerResult = try await fetchHeaderContent()
            feedDataManager.headerContent = headerResult
            self.carouselItems = headerResult.map { CarouselMediaItem(mediaObj: $0) }
            headerLoadState = .loaded
        } catch {
            let message = headerErrorMessage(from: error)
            print("⚠️ [FeedVM] Header refresh failed: \(error)")
            headerLoadState = .error(message)
        }
        
        // Refresh game data
        do {
            await apiService.fetchStartupGames()
            
            // Check for errors but don't fail - keep existing data
            if let error = apiService.startupGamesErrorMessage {
                print("⚠️ [FeedVM] Refresh warning: \(error)")
            }
            
            // Update state
            self.featuredGames = apiService.featuredGames
            self.recommendedGames = apiService.recommendedGames.isEmpty ? apiService.trendingGames : apiService.recommendedGames
            self.upcomingGames = apiService.upcomingGames
            self.trendingGames = apiService.trendingGames
            
            // Update cache
            storage.cacheFeedData(
                featured: apiService.featuredGames,
                recommended: apiService.recommendedGames,
                upcoming: apiService.upcomingGames,
                trending: apiService.trendingGames
            )
            
            // Rebuild feed
            buildFeedPayload()
            
            print("✅ [FeedVM] Feed refreshed")
            
        } catch {
            print("❌ [FeedVM] Refresh failed: \(error.localizedDescription)")
            // Keep existing data on refresh failure
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchHeaderContent() async throws -> [FeedHeaderMediaObj] {
        #if DEBUG
        let dataSource = DebugSettings.shared.headerDataSource
        
        // Mock mode: use FeedDataManager's mock data
        if dataSource == "mock" {
            print("🎭 [FeedVM] Using mock header data")
            FeedDataManager.shared.useMockData = true
            return try await feedDataManager.fetchHeaderContent()
        }
        
        // Cached mode: check if we have cached header data
        if dataSource == "cached" {
            // For now, header caching uses FeedDataManager's internal state
            // If headerContent is already populated, return it
            if !feedDataManager.headerContent.isEmpty {
                print("📦 [FeedVM] Using cached header data")
                return feedDataManager.headerContent
            }
            // If no cache, throw an error instead of falling back
            print("❌ [FeedVM] No cached header data available")
            throw FeedError.networkError("No cached header data available")
        }
        
        // Live mode: fetch from Firebase
        print("🌐 [FeedVM] Fetching live header data")
        FeedDataManager.shared.useMockData = false
        #endif
        
        return try await feedDataManager.fetchHeaderContent()
    }
    
    /// Retry loading header content after an error
    func retryHeaderLoad() async {
        headerLoadState = .loading
        
        do {
            let headerResult = try await fetchHeaderContent()
            feedDataManager.headerContent = headerResult
            self.carouselItems = headerResult.map { CarouselMediaItem(mediaObj: $0) }
            
            withAnimation(.easeOut(duration: 0.3)) {
                headerLoadState = .loaded
            }
            print("✅ [FeedVM] Header retry successful")
        } catch {
            let message = headerErrorMessage(from: error)
            print("❌ [FeedVM] Header retry failed: \(error)")
            withAnimation(.easeOut(duration: 0.3)) {
                headerLoadState = .error(message)
            }
        }
    }
    
    private func headerErrorMessage(from error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection"
            case .timedOut:
                return "Request timed out"
            default:
                return "Network error"
            }
        }
        
        // Check for FeedDataManager's notImplemented error
        if "\(error)".contains("notImplemented") {
            return "Firebase not configured"
        }
        
        return "Failed to load content"
    }
    
    private func buildFeedPayload() {
        var items: [FeedItem] = []
        
        // Header
        let headerContent = feedDataManager.headerContent
        if !headerContent.isEmpty {
            items.append(FeedItem(itemType: .header(headerContent)))
        }
        
        // For You section
        if !recommendedGames.isEmpty || !featuredGames.isEmpty {
            let payload = ForYouPayload(payload: interleaveFeatured(featured: featuredGames, others: recommendedGames))
            items.append(FeedItem(itemType: .recommended(payload)))
        }
        
        // Upcoming section
        if !upcomingGames.isEmpty {
            items.append(FeedItem(itemType: .sectionHeader("Upcoming Games")))
            items.append(FeedItem(itemType: .upcomingGames(upcomingGames)))
        }
        
        // Invites
        /*if shouldUseMockInvites {
            let mockInvite = RivalObj(
                id: "mock-invite-1",
                gamerTag: "PixelAvenger",
                senderPokoId: "poko-sender-1",
                getterPokoId: "poko-getter-1",
                game: "Cyberpunk 2077",
                gameImageUrl: "https://placehold.co/400x200/F59E0B/000000?text=Cyberpunk+2077",
                type: "Co-op Mission",
                date: "2025-11-17",
                uid: "user-uid-1",
                durationMin: 120,
                customMessage: "Let's tear up Night City!",
                customResponse: "",
                rivalStatus: "proposed",
                createdAtMs: Int64(Date().timeIntervalSince1970 * 1000) - 100000,
                expiresAtMs: Int64(Date().timeIntervalSince1970 * 1000) + 86400000
            )
            items.append(FeedItem(itemType: .invite(mockInvite)))
        } else {
            for invite in firebaseService.gameInvites {
                switch invite.rivalStatus {
                case "accepted":
                    items.append(FeedItem(itemType: .accepted(invite)))
                case "rejected":
                    items.append(FeedItem(itemType: .rejected(invite)))
                default:
                    items.append(FeedItem(itemType: .invite(invite)))
                }
            }
        }*/
        
        self.feedItems = items
    }
    
    private func interleaveFeatured(
        featured rawFeatured: [GamerConnectGame],
        others rawOthers: [GamerConnectGame]
    ) -> [FeedCard] {
        var seen = Set<String>()
        
        let featured = rawFeatured.filter { g in
            guard !seen.contains(g.id) else { return false }
            seen.insert(g.id)
            return true
        }
        
        let others = rawOthers.filter { g in
            guard !seen.contains(g.id) else { return false }
            seen.insert(g.id)
            return true
        }
        
        var out: [FeedCard] = []
        var iF = 0, iO = 0
        
        while iF < featured.count || iO < others.count {
            if iO < others.count {
                out.append(.normal(others[iO]))
                iO += 1
            }
            if iO < others.count {
                out.append(.normal(others[iO]))
                iO += 1
            }
            if iF < featured.count {
                out.append(.featured(featured[iF]))
                iF += 1
            }
        }
        
        return out
    }
    
    // MARK: - Error Handling
    
    private func handleLoadError(_ error: Error) {
        let message: String
        
        if let feedError = error as? FeedError {
            message = feedError.userMessage
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                message = "No internet connection. Please check your network and try again."
            case .timedOut:
                message = "Request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Unable to reach server. Please try again later."
            default:
                message = "Network error occurred. Please try again."
            }
        } else {
            message = "Something went wrong. Please try again."
        }
        
        print("❌ [FeedVM] Load error: \(error)")
        
        // If we have cached data, show it instead of error
        if storage.hasCachedFeedData {
            print("📦 [FeedVM] Showing cached data after error")
            loadCachedFeedData()
            buildFeedPayload()
            hasCompletedInitialLoad = true
            withAnimation { loadState = .loaded }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                loadState = .error(message)
            }
        }
    }
    
    // MARK: - Carousel Actions
    
    func handlePrimaryAction(for item: CarouselMediaItem) {
        let gameID = item.gameID ?? ""
        switch item.mediaType {
        case .youtubeVideo(let id):
            handlePlayTrailer(.youtube(videoID: id))
        case .nativeVideo(let url):
            handlePlayTrailer(.nativeVideo(url: url))
        case .image:
            handleMoreDetails(gameID)
        }
    }
    
    func handleSecondaryAction(for item: CarouselMediaItem) {
        let gameID = item.gameID ?? ""
        handleMoreDetails(gameID)
    }
    
    func trackCarouselView(_ item: CarouselMediaItem) {
        print("📊 [FeedVM] Carousel item viewed: \(item.title)")
    }
    
    func cleanupCarouselItem(_ item: CarouselMediaItem) {
        print("🧹 [FeedVM] Cleaning up carousel item: \(item.title)")
    }
    
    private func handlePlayTrailer(_ media: FeedHeaderMediaObj.MediaType) {
        print("▶️ [FeedVM] Playing trailer: \(media)")
    }
    
    private func handleMoreDetails(_ gameID: String) {
        print("ℹ️ [FeedVM] Showing details for game: \(gameID)")
    }
    
    // MARK: - Rival Actions
    
    func handleRivalAction(rival: RivalObj, action: String) {
        feedItems.removeAll {
            if case .invite(let item) = $0.itemType { return item.id == rival.id }
            return false
        }
        if action == "accepted" {
            firebaseService.acceptInvite(invite: rival)
        } else {
            firebaseService.declineInvite(invite: rival)
        }
    }
    
    func dismissRivalResponse(rival: RivalObj) {
        feedItems.removeAll {
            switch $0.itemType {
            case .accepted(let item), .rejected(let item):
                return item.id == rival.id
            default:
                return false
            }
        }
    }
}


// MARK: - Feed Error

enum FeedError: Error {
    case apiError(String)
    case networkError(String)
    case unknown
    
    var userMessage: String {
        switch self {
        case .apiError(let msg):
            return msg
        case .networkError(let msg):
            return msg
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

private enum FeedCacheKeys {
    static let featuredGameIDs = "feed_featured_game_ids"
    static let recommendedGameIDs = "feed_recommended_game_ids"
    static let upcomingGameIDs = "feed_upcoming_game_ids"
    static let trendingGameIDs = "feed_trending_game_ids"
    static let feedLastUpdated = "feed_last_updated"
}

extension GameStorageManager {
    
    // MARK: - Cache Validity
    
    /// How long feed data is considered fresh (5 minutes)
    private var feedCacheTTL: TimeInterval { 300 }
    
    /// Check if feed cache is still valid
    var isFeedCacheValid: Bool {
        guard let lastUpdated = UserDefaults.standard.object(forKey: FeedCacheKeys.feedLastUpdated) as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastUpdated) < feedCacheTTL
    }
    
    /// Update the feed cache timestamp
    func markFeedCacheUpdated() {
        UserDefaults.standard.set(Date(), forKey: FeedCacheKeys.feedLastUpdated)
    }
    
    /// Invalidate feed cache (force refresh on next load)
    func invalidateFeedCache() {
        UserDefaults.standard.removeObject(forKey: FeedCacheKeys.feedLastUpdated)
    }
    
    // MARK: - Featured Games
    
    func cacheFeaturedGames(_ games: [GamerConnectGame]) {
        // Save games to main cache
        save(games: games)
        // Save ID list for feed
        let ids = games.map { $0.id }
        UserDefaults.standard.set(ids, forKey: FeedCacheKeys.featuredGameIDs)
    }
    
    func getCachedFeaturedGames() -> [GamerConnectGame] {
        guard let ids = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.featuredGameIDs) else {
            return []
        }
        return ids.compactMap { getGame(id: $0) }
    }
    
    // MARK: - Recommended Games
    
    func cacheRecommendedGames(_ games: [GamerConnectGame]) {
        save(games: games)
        let ids = games.map { $0.id }
        UserDefaults.standard.set(ids, forKey: FeedCacheKeys.recommendedGameIDs)
    }
    
    func getCachedRecommendedGames() -> [GamerConnectGame] {
        guard let ids = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.recommendedGameIDs) else {
            return []
        }
        return ids.compactMap { getGame(id: $0) }
    }
    
    // MARK: - Upcoming Games
    
    func cacheUpcomingGames(_ games: [GamerConnectGame]) {
        save(games: games)
        let ids = games.map { $0.id }
        UserDefaults.standard.set(ids, forKey: FeedCacheKeys.upcomingGameIDs)
    }
    
    func getCachedUpcomingGames() -> [GamerConnectGame] {
        guard let ids = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.upcomingGameIDs) else {
            return []
        }
        return ids.compactMap { getGame(id: $0) }
    }
    
    // MARK: - Trending Games
    
    func cacheTrendingGames(_ games: [GamerConnectGame]) {
        save(games: games)
        let ids = games.map { $0.id }
        UserDefaults.standard.set(ids, forKey: FeedCacheKeys.trendingGameIDs)
    }
    
    func getCachedTrendingGames() -> [GamerConnectGame] {
        guard let ids = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.trendingGameIDs) else {
            return []
        }
        return ids.compactMap { getGame(id: $0) }
    }
    
    // MARK: - Bulk Cache Update
    
    /// Cache all feed data at once (called after fetchStartupGames)
    func cacheFeedData(
        featured: [GamerConnectGame],
        recommended: [GamerConnectGame],
        upcoming: [GamerConnectGame],
        trending: [GamerConnectGame]
    ) {
        // Save all games to main cache
        let allGames = featured + recommended + upcoming + trending
        save(games: allGames)
        
        // Save ID lists
        UserDefaults.standard.set(featured.map { $0.id }, forKey: FeedCacheKeys.featuredGameIDs)
        UserDefaults.standard.set(recommended.map { $0.id }, forKey: FeedCacheKeys.recommendedGameIDs)
        UserDefaults.standard.set(upcoming.map { $0.id }, forKey: FeedCacheKeys.upcomingGameIDs)
        UserDefaults.standard.set(trending.map { $0.id }, forKey: FeedCacheKeys.trendingGameIDs)
        
        // Mark cache as updated
        markFeedCacheUpdated()
    }
    
    /// Get all cached feed data at once
    func getCachedFeedData() -> (
        featured: [GamerConnectGame],
        recommended: [GamerConnectGame],
        upcoming: [GamerConnectGame],
        trending: [GamerConnectGame]
    ) {
        return (
            featured: getCachedFeaturedGames(),
            recommended: getCachedRecommendedGames(),
            upcoming: getCachedUpcomingGames(),
            trending: getCachedTrendingGames()
        )
    }
    
    /// Check if we have any cached feed data
    var hasCachedFeedData: Bool {
        let featured = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.featuredGameIDs)
        let recommended = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.recommendedGameIDs)
        let upcoming = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.upcomingGameIDs)
        let trending = UserDefaults.standard.stringArray(forKey: FeedCacheKeys.trendingGameIDs)
        
        // Has data if any list is non-empty
        return !(featured?.isEmpty ?? true) ||
               !(recommended?.isEmpty ?? true) ||
               !(upcoming?.isEmpty ?? true) ||
               !(trending?.isEmpty ?? true)
    }
}
