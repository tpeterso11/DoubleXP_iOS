//
//  GameAPIService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import Combine

private extension DecodableRegistrationGame {
    func asGamerConnectGame() -> GamerConnectGame {
        GamerConnectGame(
            id: id,
            imageUrl: imageUrl,
            gameName: gameName,
            developer: developer
        )
    }
}

// MARK: - Cache Containers

struct StartupCacheContainer: Codable {
    let timestamp: Date
    let response: StartupGamesResponse
}

struct RegistrationCacheContainer: Codable {
    let timestamp: Date
    let response: RegistrationGamesResponse
}

struct FeaturedGamesCacheContainer: Codable {
    let timestamp: Date
    let response: FeaturedGamesResponse
}

struct RecommendationsCacheContainer: Codable {
    let timestamp: Date
    let seedsKey: String
    let response: RecommendationsResponse
}

// MARK: - Service

#if DEBUG
private let dbgNet = DebugNetworkController.shared
#endif

struct StartupGamesResponse: Codable {
    let trendingGames: [GamerConnectGame]
    let upcomingGames: [GamerConnectGame]
    let recommendedGames: [GamerConnectGame]
    let featuredGames: [GamerConnectGame]?
}

struct FeaturedGamesResponse: Codable {
    let featuredGames: [GamerConnectGame]
}

private struct DecodableRegistrationGame: Codable {
    let id: String
    let gameName: String
    let developer: String
    let imageUrl: String
}

struct RegistrationGamesResponse: Codable {
    fileprivate let actionGames: [DecodableRegistrationGame]
    fileprivate let sportsGames: [DecodableRegistrationGame]
    fileprivate let shooterGames: [DecodableRegistrationGame]
    fileprivate let casualGames: [DecodableRegistrationGame]
    fileprivate let mmoGames: [DecodableRegistrationGame]
}

struct RecommendationsResponse: Codable {
    let recommended: [GamerConnectGame]
    let featured: [GamerConnectGame]?
}

@MainActor
final class GameAPIService: ObservableObject {
    
    static let shared = GameAPIService()
    
    // MARK: - Published Properties
    
    // Startup games
    @Published var trendingGames: [GamerConnectGame] = []
    @Published var upcomingGames: [GamerConnectGame] = []
    @Published var featuredGames: [GamerConnectGame] = []
    @Published var recommendedGames: [GamerConnectGame] = []
    @Published var isLoadingStartupGames = false
    @Published var startupGamesErrorMessage: String?
    
    // Registration games
    @Published var actionGames: [GamerConnectGame] = []
    @Published var sportsGames: [GamerConnectGame] = []
    @Published var shooterGames: [GamerConnectGame] = []
    @Published var casualGames: [GamerConnectGame] = []
    @Published var mmoGames: [GamerConnectGame] = []
    @Published var allRegistrationGames: [GamerConnectGame] = []
    @Published var isLoadingRegistrationGames = false
    @Published var registrationGamesErrorMessage: String?
    
    // MARK: - Private Properties
    
    private let storage = GameStorageManager.shared
    
    private let startupGamesURL = "https://games-datfkcsqgq-uc.a.run.app/v1/startup-games"
    private let registrationGamesURL = "https://games-datfkcsqgq-uc.a.run.app/v1/registration-games"
    private let featuredGamesURL = "https://games-datfkcsqgq-uc.a.run.app/v1/featured-games"
    
    private init() {}
    
    // MARK: - Startup Games
    
    /// Fetches all startup data: trending, upcoming, featured, recommended
    /// Results are saved to GameStorageManager for app-wide access
    func fetchStartupGames() async {
            guard !isLoadingStartupGames else { return }
            isLoadingStartupGames = true
            startupGamesErrorMessage = nil
            
            #if DEBUG
            let dataSource = DebugSettings.shared.feedDataSource
            
            // Mock mode: use hardcoded mock data
            if dataSource == "mock" {
                trendingGames = MockGames.trending
                upcomingGames = MockGames.all
                featuredGames = MockGames.featured
                recommendedGames = MockGames.all
                isLoadingStartupGames = false
                print("🎭 [GameAPI] Using mock startup games")
                return
            }
            
            // Cached mode: load from GameStorageManager if available
            if dataSource == "cached" {
                let cached = storage.getCachedFeedData()
                if !cached.featured.isEmpty || !cached.trending.isEmpty {
                    trendingGames = cached.trending
                    upcomingGames = cached.upcoming
                    featuredGames = cached.featured
                    recommendedGames = cached.recommended.isEmpty ? cached.trending : cached.recommended
                    isLoadingStartupGames = false
                    print("📦 [GameAPI] Using cached startup games")
                    return
                } else {
                    print("⚠️ [GameAPI] No cached data available, falling back to live")
                }
            }
            
            // Live mode: fetch from API
            #endif
            
            // Build URL with query params
            let seeds: [String] = UserProvider.shared.currentUser?.games ?? []
            
            guard var comps = URLComponents(string: startupGamesURL) else {
                startupGamesErrorMessage = "Invalid Startup API URL."
                isLoadingStartupGames = false
                return
            }
            
            var items: [URLQueryItem] = [
                URLQueryItem(name: "rec_limit", value: "8"),
                URLQueryItem(name: "include_featured", value: "true"),
                URLQueryItem(name: "trending_limit", value: "12"),
                URLQueryItem(name: "upcoming_limit", value: "12"),
                URLQueryItem(name: "include_errors", value: "1")
            ]
            if !seeds.isEmpty {
                items.append(URLQueryItem(name: "seeds", value: seeds.joined(separator: ",")))
            }
            comps.queryItems = items
            
            // Network request
            do {
                #if DEBUG
                try await dbgNet.simulateHit()
                #endif
                
                guard let url = comps.url else {
                    startupGamesErrorMessage = "Could not construct Startup API URL."
                    isLoadingStartupGames = false
                    return
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                let api = try JSONDecoder().decode(StartupGamesResponse.self, from: data)
                
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 RAW STARTUP RESPONSE:")
                    print(jsonString.prefix(500))
                }
                #endif
                
                // Update published properties
                self.trendingGames = api.trendingGames
                self.upcomingGames = api.upcomingGames
                self.featuredGames = api.featuredGames ?? []
                self.recommendedGames = api.recommendedGames
                
                // Save ALL fetched games to GameStorageManager
                let allFetched = api.trendingGames + api.upcomingGames + (api.featuredGames ?? []) + api.recommendedGames
                GameStorageManager.shared.saveDeduped(games: allFetched)
                
                // Also cache the feed data for "cached" mode
                #if DEBUG
                if DebugSettings.shared.cacheFeedResponses {
                    storage.cacheFeedData(
                        featured: api.featuredGames ?? [],
                        recommended: api.recommendedGames,
                        upcoming: api.upcomingGames,
                        trending: api.trendingGames
                    )
                    print("💾 [GameAPI] Cached feed data for later use")
                }
                #else
                storage.cacheFeedData(
                    featured: api.featuredGames ?? [],
                    recommended: api.recommendedGames,
                    upcoming: api.upcomingGames,
                    trending: api.trendingGames
                )
                #endif
                
                print("✅ [GameAPI] Startup games fetched: \(allFetched.count) total")
                
            } catch {
                print("❌ [GameAPI] Failed to fetch startup games: \(error)")
                startupGamesErrorMessage = "Failed to fetch startup games."
            }
            
            isLoadingStartupGames = false
        }
        
    
    // MARK: - Registration Games
    
    func fetchRegistrationGames() async {
        guard !isLoadingRegistrationGames else { return }
        isLoadingRegistrationGames = true
        registrationGamesErrorMessage = nil
        
        #if DEBUG
        if DebugSettings.shared.mockGameAPI {
            actionGames = MockGames.action
            sportsGames = MockGames.sports
            shooterGames = MockGames.shooter
            casualGames = MockGames.casual
            mmoGames = MockGames.mmo
            updateAllRegistrationGames()
            isLoadingRegistrationGames = false
            return
        }
        #endif
        
        guard let url = URL(string: registrationGamesURL) else {
            registrationGamesErrorMessage = "Invalid Registration API URL."
            isLoadingRegistrationGames = false
            return
        }
        
        do {
            #if DEBUG
            try await dbgNet.simulateHit()
            #endif
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let api = try JSONDecoder().decode(RegistrationGamesResponse.self, from: data)
            applyRegistrationBuckets(from: api)
            
            // Save to storage
            GameStorageManager.shared.saveDeduped(games: allRegistrationGames)
            
        } catch {
            registrationGamesErrorMessage = "Failed to fetch registration games."
        }
        
        isLoadingRegistrationGames = false
    }
    
    private func applyRegistrationBuckets(from api: RegistrationGamesResponse) {
        actionGames = api.actionGames.map { $0.asGamerConnectGame() }
        sportsGames = api.sportsGames.map { $0.asGamerConnectGame() }
        shooterGames = api.shooterGames.map { $0.asGamerConnectGame() }
        casualGames = api.casualGames.map { $0.asGamerConnectGame() }
        mmoGames = api.mmoGames.map { $0.asGamerConnectGame() }
        updateAllRegistrationGames()
    }
    
    private func updateAllRegistrationGames() {
        let all = actionGames + sportsGames + shooterGames + casualGames + mmoGames
        var unique = [GamerConnectGame]()
        var seen = Set<String>()
        for g in all where !seen.contains(g.id) {
            unique.append(g)
            seen.insert(g.id)
        }
        allRegistrationGames = unique
    }
}

// MARK: - Mock Data

enum MockGames {
    private static func fallback(_ seed: Int) -> String {
        "https://picsum.photos/seed/\(seed)/600/900"
    }
    
    static let all: [GamerConnectGame] = [
        GamerConnectGame(
            id: "bg3",
            imageUrl: "https://image.api.playstation.com/vulcan/ap/rnd/202308/2413/413362d3e50b2a819906bd9e2eb1c7a2b5c49ea184087c1d.png?w=880",
            gameName: "Baldur's Gate 3",
            developer: "Larian Studios",
            hook: "Party-based epic set in the D&D universe.",
            available: "yes",
            availableConsoles: ["PS5", "Xbox Series", "PC", "Mac"],
            gameModes: ["Single-player", "Co-op"],
            releaseDate: "2023-08-03",
            gameType: "RPG",
            categoryFilters: ["RPG", "Cinematic", "CRPG", "Action"],
            slug: "baldurs-gate-3"
        ),
        GamerConnectGame(
            id: "elden-ring",
            imageUrl: fallback(1245620),
            gameName: "ELDEN RING",
            developer: "FromSoftware",
            hook: "Open-world action RPG from Miyazaki x Martin.",
            available: "yes",
            availableConsoles: ["PS5", "PS4", "Xbox Series", "Xbox One", "PC"],
            releaseDate: "2022-02-25",
            gameType: "Action RPG",
            categoryFilters: ["Soulslike", "Open World", "Action", "RPG"],
            slug: "elden-ring"
        ),
        GamerConnectGame(
            id: "apex-legends",
            imageUrl: fallback(1172470),
            gameName: "Apex Legends",
            developer: "Respawn",
            hook: "Hero shooter battle royale.",
            available: "yes",
            availableConsoles: ["PS5", "PC"],
            releaseDate: "2019-02-04",
            gameType: "Battle Royale",
            categoryFilters: ["Shooter", "Competitive", "Action"],
            slug: "apex-legends"
        ),
        GamerConnectGame(
            id: "stardew-valley",
            imageUrl: fallback(413150),
            gameName: "Stardew Valley",
            developer: "ConcernedApe",
            hook: "Cozy farming life-sim.",
            available: "yes",
            availableConsoles: ["PS5", "Switch", "PC"],
            releaseDate: "2016-02-26",
            gameType: "Simulation",
            categoryFilters: ["Cozy", "Farming", "Casual", "Simulation"],
            slug: "stardew-valley"
        ),
        GamerConnectGame(
            id: "cod-mw3",
            imageUrl: fallback(999),
            gameName: "Call of Duty: MW3",
            developer: "Sledgehammer Games",
            hook: "The war has changed.",
            available: "yes",
            availableConsoles: ["PS5", "Xbox", "PC"],
            gameType: "Shooter",
            categoryFilters: ["Shooter", "Action", "Multiplayer"],
            slug: "call-of-duty-modern-warfare-3"
        ),
        GamerConnectGame(
            id: "fc-24",
            imageUrl: fallback(888),
            gameName: "EA SPORTS FC 24",
            developer: "EA",
            hook: "The world's game.",
            available: "yes",
            availableConsoles: ["PS5", "Xbox", "PC"],
            gameType: "Sports",
            categoryFilters: ["Sports", "Simulation", "Multiplayer"],
            slug: "ea-sports-fc-24"
        ),
        GamerConnectGame(
            id: "wow",
            imageUrl: fallback(777),
            gameName: "World of Warcraft",
            developer: "Blizzard",
            hook: "The standard for MMOs.",
            available: "yes",
            availableConsoles: ["PC"],
            gameType: "MMORPG",
            categoryFilters: ["MMO", "RPG", "Fantasy"],
            slug: "world-of-warcraft"
        )
    ]
    
    static let action: [GamerConnectGame] = all.filter { $0.categoryFilters.contains("Action") }
    static let sports: [GamerConnectGame] = all.filter { $0.categoryFilters.contains("Sports") }
    static let shooter: [GamerConnectGame] = all.filter { $0.categoryFilters.contains("Shooter") }
    static let casual: [GamerConnectGame] = all.filter { $0.categoryFilters.contains("Casual") }
    static let mmo: [GamerConnectGame] = all.filter { $0.categoryFilters.contains("MMO") }
    
    static let featured: [GamerConnectGame] = Array(all.prefix(3))
    static let trending: [GamerConnectGame] = Array(all.suffix(3))
}
