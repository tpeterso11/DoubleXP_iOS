//
//  DiscoverViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import FirebaseDatabase

// MARK: - DiscoverViewModel

@MainActor
class DiscoverViewModel: ObservableObject {
    
    // MARK: - Games Tab State
    @Published var featuredGames: [GamerConnectGame] = []
    @Published var categories: [DiscoverPageCategory] = []
    @Published var preloadedImages: [String: UIImage] = [:]
    @Published var isLoadingGames: Bool = false
    @Published var gamesError: String?
    private var gamesTabLoaded: Bool = false
    
    // MARK: - Players Tab State
    @Published var recommendedPlayers: [User] = []
    @Published var userGamesForPlayerSearch: [GamerConnectGame] = []
    @Published var isLoadingPlayers: Bool = false
    @Published var playersError: String?
    private var playersTabLoaded: Bool = false
    
    // MARK: - Communities Tab State
    @Published var featuredCommunities: [DiscoverCommunity] = []
    @Published var userCommunities: [DiscoverCommunity] = []
    @Published var suggestedCommunities: [DiscoverCommunity] = []
    @Published var isLoadingCommunities: Bool = false
    @Published var communitiesError: String?
    private var communitiesTabLoaded: Bool = false
    
    // MARK: - Dependencies
    private let storage = GameStorageManager.shared
    private let userProvider = UserProvider.shared
    private let requestManager = DiscoverRequestManager.shared
    
    // MARK: - Tab Loading Coordinator
    
    func loadTabIfNeeded(_ tab: DiscoverTab) async {
        switch tab {
        case .games:
            if !gamesTabLoaded {
                await loadGamesTab()
            }
        case .players:
            if !playersTabLoaded {
                await loadPlayersTab()
            }
        case .communities:
            if !communitiesTabLoaded {
                await loadCommunitiesTab()
            }
        }
    }
    
    // MARK: - Games Tab Loading
    
    func loadGamesTab() async {
        guard !isLoadingGames else { return }
        
        withAnimation { isLoadingGames = true }
        gamesError = nil
        
        do {
            // Get user's games for personalization
            let userGames = userProvider.currentUser?.games ?? []
            
            // Fetch discover feed
            let gamingExperience = userProvider.currentUser?.gamingExperience ?? "5"
            let feed = try await requestManager.fetchDiscoverFeed(userGames: userGames, gamingExperience: gamingExperience)
            
            // Prefetch critical images
            var urlsToPrefetch: [String] = []
            if let firstHeroUrl = feed.featuredGames.first?.imageUrl {
                urlsToPrefetch.append(firstHeroUrl)
            }
            let categoryUrls = feed.categories.map { $0.imageUrl }
            urlsToPrefetch.append(contentsOf: categoryUrls)
            
            await prefetchImages(urls: urlsToPrefetch)
            
            // Cache all games
            var allFetchedGames = feed.featuredGames
            for cat in feed.categories {
                allFetchedGames.append(contentsOf: cat.games)
            }
            storage.save(games: allFetchedGames)
            
            // Update state
            self.featuredGames = feed.featuredGames
            self.categories = feed.categories
            self.gamesTabLoaded = true
            
            withAnimation(.easeOut(duration: 0.4)) {
                self.isLoadingGames = false
            }
            
        } catch {
            print("🔴 [DiscoverVM] Games tab error: \(error)")
            withAnimation {
                self.gamesError = "Could not load games. Please try again."
                self.isLoadingGames = false
            }
        }
    }
    
    // MARK: - Players Tab Loading
    
    func loadPlayersTab() async {
        guard !isLoadingPlayers else { return }
        
        withAnimation { isLoadingPlayers = true }
        playersError = nil
        
        do {
            guard let currentUser = userProvider.currentUser else {
                throw NSError(domain: "DiscoverVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // 1. Load recommended players
            let recommended = try await requestManager.fetchRecommendedPlayers(
                forUser: currentUser.uId,
                userGames: currentUser.games,
                limit: 5
            )
            
            // 2. Load user's games for player search
            let userGameSlugs = currentUser.games
            var resolvedGames: [GamerConnectGame] = []
            
            for slug in userGameSlugs {
                // Try local cache first
                if let cached = storage.getGame(slug: slug) {
                    resolvedGames.append(cached)
                } else {
                    // Fetch from IGDB if not cached
                    if let fetched = await IGDBService.shared.fetchGameDetails(bySlug: slug, forceReload: false) {
                        resolvedGames.append(fetched)
                    }
                }
            }
            
            // Update state
            self.recommendedPlayers = recommended
            self.userGamesForPlayerSearch = resolvedGames
            self.playersTabLoaded = true
            
            withAnimation(.easeOut(duration: 0.4)) {
                self.isLoadingPlayers = false
            }
            
        } catch {
            print("🔴 [DiscoverVM] Players tab error: \(error)")
            withAnimation {
                self.playersError = "Could not load players. Please try again."
                self.isLoadingPlayers = false
            }
        }
    }
    
    // MARK: - Communities Tab Loading
    
    func loadCommunitiesTab() async {
        guard !isLoadingCommunities else { return }
        
        withAnimation { isLoadingCommunities = true }
        communitiesError = nil
        
        do {
            guard let currentUser = userProvider.currentUser else {
                throw NSError(domain: "DiscoverVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // 1. Fetch featured communities (active communities with most members)
            let featured = try await requestManager.fetchFeaturedCommunities(limit: 5)
            
            // 2. Fetch user's joined communities
            let userJoined = try await requestManager.fetchUserCommunities(userId: currentUser.uId)
            
            // 3. Fetch suggested communities (games user follows but hasn't joined community)
            let userGameSlugs = Set(currentUser.games)
            let joinedSlugs = Set(userJoined.map { $0.gameSlug })
            let suggestedSlugs = userGameSlugs.subtracting(joinedSlugs)
            
            var suggested: [DiscoverCommunity] = []
            for slug in suggestedSlugs {
                if let community = try? await requestManager.fetchCommunityInfo(gameSlug: slug) {
                    suggested.append(community)
                }
            }
            
            // Update state
            self.featuredCommunities = featured
            self.userCommunities = userJoined
            self.suggestedCommunities = suggested
            self.communitiesTabLoaded = true
            
            withAnimation(.easeOut(duration: 0.4)) {
                self.isLoadingCommunities = false
            }
            
        } catch {
            print("🔴 [DiscoverVM] Communities tab error: \(error)")
            withAnimation {
                self.communitiesError = "Could not load communities. Please try again."
                self.isLoadingCommunities = false
            }
        }
    }
    
    // MARK: - Image Prefetching
    
    private func prefetchImages(urls: [String]) async {
        let images = await withTaskGroup(of: (String, UIImage?).self) { group -> [String: UIImage] in
            for urlString in urls {
                guard let url = URL(string: urlString) else { continue }
                
                group.addTask {
                    if await self.preloadedImages[urlString] != nil {
                        return (urlString, nil)
                    }
                    
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            return (urlString, image)
                        }
                    } catch {
                        print("⚠️ Failed to prefetch: \(urlString)")
                    }
                    return (urlString, nil)
                }
            }
            
            var results: [String: UIImage] = [:]
            for await (key, image) in group {
                if let image = image {
                    results[key] = image
                }
            }
            return results
        }
        
        self.preloadedImages.merge(images) { (_, new) in new }
    }
    
    // MARK: - Refresh Methods
    
    func refreshCurrentTab(_ tab: DiscoverTab) async {
        switch tab {
        case .games:
            gamesTabLoaded = false
            await loadGamesTab()
        case .players:
            playersTabLoaded = false
            await loadPlayersTab()
        case .communities:
            communitiesTabLoaded = false
            await loadCommunitiesTab()
        }
    }
}
