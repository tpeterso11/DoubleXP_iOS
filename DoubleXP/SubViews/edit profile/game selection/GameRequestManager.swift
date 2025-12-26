//
//  GameRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

// MARK: - Game Request Manager

actor GameRequestManager {
    static let shared = GameRequestManager()
    
    // TODO: Update with your actual Firebase Functions URL
    private let baseURL = "https://us-central1-gameterminal-767f7.cloudfunctions.net/gameSelection"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Fetch games by genre, excluding already viewed games
    func fetchGames(genre: GameGenre, excludeIDs: [String] = []) async throws -> [GamerConnectGame] {
        // Check debug settings (must hop to MainActor to read)
        let (useMock, useCached, shouldCache) = await MainActor.run {
            return (
                DebugSettings.shared.mockGameAPI,
                DebugSettings.shared.useCachedGameResponses,
                DebugSettings.shared.cacheGameResponses
            )
        }
        
        // Priority 1: Mock data
        /*#if DEBUG
        if useMock {
            return try await fetchGamesMock(genre: genre, excludeIDs: excludeIDs)
        }
        #endif
        
        // Priority 2: Cached response
        #if DEBUG
        if useCached {
            let cached: [GamerConnectGame]? = await MainActor.run {
                return DebugSettings.shared.getCachedGamesResponse(for: genre.apiValue)
            }
            if let cachedGames = cached {
                // Filter out excluded IDs
                return cachedGames.filter { !excludeIDs.contains($0.id) }
            }
            // Fall through to live API if no cache exists
        }
        #endif
        */
        // Priority 3: Live API
        let games = try await fetchGamesFromAPI(genre: genre, excludeIDs: excludeIDs)
        
        // Cache the response if enabled
        #if DEBUG
        if shouldCache {
            await MainActor.run {
                DebugSettings.shared.cacheGamesResponse(games, for: genre.apiValue)
            }
        }
        #endif
        
        return games
    }
    
    /// Search for games by query
    func searchGames(query: String) async throws -> [GamerConnectGame] {
        /*let (useMock, useCached, shouldCache) = await MainActor.run {
            return (
                DebugSettings.shared.mockGameAPI,
                DebugSettings.shared.useCachedGameResponses,
                DebugSettings.shared.cacheGameResponses
            )
        }
        
        #if DEBUG
        if useMock {
            return try await searchGamesMock(query: query)
        }
        
        if useCached {
            let cached: [GamerConnectGame]? = await MainActor.run {
                return DebugSettings.shared.getCachedSearchResponse(for: query)
            }
            if let cachedGames = cached {
                return cachedGames
            }
        }
        #endif*/
        
        let games = try await searchGamesFromAPI(query: query)
        
        /*#if DEBUG
        if shouldCache {
            await MainActor.run {
                DebugSettings.shared.cacheSearchResponse(games, for: query)
            }
        }
        #endif*/
        
        return games
    }
    
    /// Fetch all games for the "See More" page (paginated by genre)
    func fetchAllGamesByGenre(limit: Int = 15) async throws -> [GameGenre: [GamerConnectGame]] {
        let (useMock, useCached, shouldCache) = await MainActor.run {
            return (
                DebugSettings.shared.mockGameAPI,
                DebugSettings.shared.useCachedGameResponses,
                DebugSettings.shared.cacheGameResponses
            )
        }
        
        #if DEBUG
        if useMock {
            return try await fetchAllGamesByGenreMock(limit: limit)
        }
        
        if useCached {
            let cached: [String: [GamerConnectGame]]? = await MainActor.run {
                return DebugSettings.shared.getCachedAllGenresResponse()
            }
            if let cachedCategories = cached {
                // Convert string keys back to GameGenre
                var result: [GameGenre: [GamerConnectGame]] = [:]
                for (key, games) in cachedCategories {
                    if let genre = GameGenre.fromAPIValue(key) {
                        result[genre] = games
                    }
                }
                if !result.isEmpty {
                    return result
                }
            }
        }
        #endif
        
        let result = try await fetchAllGamesByGenreFromAPI(limit: limit)
        
        #if DEBUG
        if shouldCache {
            // Convert to string keys for caching
            var cacheDict: [String: [GamerConnectGame]] = [:]
            for (genre, games) in result {
                cacheDict[genre.apiValue] = games
            }
            await MainActor.run {
                DebugSettings.shared.cacheAllGenresResponse(cacheDict)
            }
        }
        #endif
        
        return result
    }
    
    // MARK: - Live API Calls
    
    private func fetchGamesFromAPI(genre: GameGenre, excludeIDs: [String]) async throws -> [GamerConnectGame] {
        var components = URLComponents(string: "\(baseURL)/v1/games-by-genre")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "genre", value: genre.apiValue),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "min_popularity", value: "50")
        ]
        
        if !excludeIDs.isEmpty {
            queryItems.append(URLQueryItem(name: "exclude", value: excludeIDs.joined(separator: ",")))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GameRequestError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameRequestError.invalidResponse
        }
        
        //guard httpResponse.statusCode == 200 else {
        //    throw GameRequestError.httpError(statusCode: httpResponse.statusCode)
        //}
        
        let decoded = try JSONDecoder().decode(GamesResponse.self, from: data)
        return decoded.games
    }
    
    func searchGamesFromAPI(
            gameName: String? = nil,
            slug: String? = nil
        ) async throws -> [GamerConnectGame] {
            let trimmedName = gameName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let trimmedSlug = slug?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !trimmedName.isEmpty || !trimmedSlug.isEmpty else {
                print("❌ [searchGamesFromAPI] Both gameName and slug are empty")
                throw GameRequestError.invalidQuery
            }

            var components = URLComponents(string: "\(baseURL)/v1/search-games")!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "20")
            ]

            if !trimmedSlug.isEmpty {
                print("🔎 [searchGamesFromAPI] Searching by slug = '\(trimmedSlug)'")
                queryItems.append(URLQueryItem(name: "slug", value: trimmedSlug))
            } else {
                print("🔎 [searchGamesFromAPI] Searching by name = '\(trimmedName)'")
                queryItems.append(URLQueryItem(name: "q", value: trimmedName))
            }

            components.queryItems = queryItems

            guard let url = components.url else {
                print("❌ [searchGamesFromAPI] Failed to build URL from components")
                throw GameRequestError.invalidURL
            }

            print("🌐 [searchGamesFromAPI] Requesting URL: \(url.absoluteString)")

            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await URLSession.shared.data(from: url)
            } catch {
                print("❌ [searchGamesFromAPI] Network error:", error)
                throw error
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [searchGamesFromAPI] Response is not HTTPURLResponse: \(response)")
                throw GameRequestError.invalidResponse
            }

            print("📩 [searchGamesFromAPI] Status code: \(httpResponse.statusCode)")
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                print("📩 [searchGamesFromAPI] Content-Type: \(contentType)")
            }

            guard httpResponse.statusCode == 200 else {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-UTF8 body, length: \(data.count)>"
                print("❌ [searchGamesFromAPI] HTTP error \(httpResponse.statusCode). Body:\n\(bodyString)")
                throw GameRequestError.httpError(statusCode: httpResponse.statusCode)
            }

            do {
                let decoded = try JSONDecoder().decode(GamesResponse.self, from: data)
                print("✅ [searchGamesFromAPI] Decoded \(decoded.games.count) games.")
                return decoded.games
            } catch {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-UTF8 body, length: \(data.count)>"
                print("❌ [searchGamesFromAPI] JSON decode failed with error: \(error)")
                print("📦 [searchGamesFromAPI] Raw response body:\n\(bodyString)")
                throw error
            }
        }

        /// Backwards-compatible wrapper for existing call sites
        func searchGamesFromAPI(query: String) async throws -> [GamerConnectGame] {
            try await searchGamesFromAPI(gameName: query, slug: nil)
        }
    
    private func fetchAllGamesByGenreFromAPI(limit: Int) async throws -> [GameGenre: [GamerConnectGame]] {
        var components = URLComponents(string: "\(baseURL)/v1/all-genres-preview")!
        
        components.queryItems = [
            URLQueryItem(name: "limit_per_genre", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw GameRequestError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameRequestError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GameRequestError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(AllGenresResponse.self, from: data)
        
        var result: [GameGenre: [GamerConnectGame]] = [:]
        for (genreKey, categoryData) in decoded.categories {
            if let genre = GameGenre.fromAPIValue(genreKey) {
                result[genre] = categoryData.games
            }
        }
        
        return result
    }
    
    // MARK: - Mock Data Methods
    
    #if DEBUG
    private func fetchGamesMock(genre: GameGenre, excludeIDs: [String]) async throws -> [GamerConnectGame] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let games = MockGameData.games(for: genre)
        return games.filter { !excludeIDs.contains($0.id) }
    }
    
    private func searchGamesMock(query: String) async throws -> [GamerConnectGame] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let lowercasedQuery = query.lowercased()
        return MockGameData.allGames.filter {
            $0.gameName.lowercased().contains(lowercasedQuery)
        }
    }
    
    private func fetchAllGamesByGenreMock(limit: Int) async throws -> [GameGenre: [GamerConnectGame]] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var result: [GameGenre: [GamerConnectGame]] = [:]
        
        for genre in GameGenre.allCases where genre != .all {
            let games = MockGameData.games(for: genre)
            result[genre] = Array(games.prefix(limit))
        }
        
        return result
    }
    #endif
}

// MARK: - Response Models

private struct GamesResponse: Decodable {
    let games: [GamerConnectGame]
}

private struct AllGenresResponse: Decodable {
    let categories: [String: CategoryData]
    
    struct CategoryData: Decodable {
        let title: String
        let games: [GamerConnectGame]
    }
}

// MARK: - Request Errors

enum GameRequestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error (HTTP \(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidQuery:
            return "Invalid Query"
        }
    }
}

// MARK: - GameGenre API Mapping

extension GameGenre {
    /// API value to send to backend
    var apiValue: String {
        switch self {
        case .all: return "all"
        case .fps: return "fps"
        case .battleRoyale: return "battle-royale"
        case .rpg: return "rpg"
        case .sports: return "sports"
        case .moba: return "moba"
        case .racing: return "racing"
        }
    }
    
    /// Create from API response key
    static func fromAPIValue(_ value: String) -> GameGenre? {
        switch value.lowercased() {
        case "all": return .all
        case "fps": return .fps
        case "battle-royale", "battleroyale": return .battleRoyale
        case "rpg": return .rpg
        case "sports": return .sports
        case "moba": return .moba
        case "racing": return .racing
        default: return nil
        }
    }
}

// MARK: - Mock Data

#if DEBUG
struct MockGameData {
    
    static let allGames: [GamerConnectGame] = [
        // FPS Games
        GamerConnectGame(
            id: "1",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co2mvt.jpg",
            gameName: "Valorant",
            developer: "Riot Games",
            available: "yes",
            categoryFilters: ["FPS", "Tactical Shooter"],
            slug: "valorant"
        ),
        GamerConnectGame(
            id: "2",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co5vst.jpg",
            gameName: "Counter-Strike 2",
            developer: "Valve",
            available: "yes",
            categoryFilters: ["FPS", "Tactical Shooter"],
            slug: "counter-strike-2"
        ),
        GamerConnectGame(
            id: "3",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co5tkj.jpg",
            gameName: "Overwatch 2",
            developer: "Blizzard",
            available: "yes",
            categoryFilters: ["FPS", "Hero Shooter"],
            slug: "overwatch-2"
        ),
        GamerConnectGame(
            id: "4",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co2wc7.jpg",
            gameName: "Call of Duty: Warzone",
            developer: "Activision",
            available: "yes",
            categoryFilters: ["FPS", "Battle Royale"],
            slug: "call-of-duty-warzone"
        ),
        GamerConnectGame(
            id: "5",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co4jni.jpg",
            gameName: "Halo Infinite",
            developer: "343 Industries",
            available: "yes",
            categoryFilters: ["FPS", "Sci-Fi"],
            slug: "halo-infinite"
        ),
        
        // Battle Royale Games
        GamerConnectGame(
            id: "6",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3wk8.jpg",
            gameName: "Fortnite",
            developer: "Epic Games",
            available: "yes",
            categoryFilters: ["Battle Royale", "Third Person Shooter"],
            slug: "fortnite"
        ),
        GamerConnectGame(
            id: "7",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co1wkt.jpg",
            gameName: "Apex Legends",
            developer: "Respawn Entertainment",
            available: "yes",
            categoryFilters: ["Battle Royale", "FPS"],
            slug: "apex-legends"
        ),
        GamerConnectGame(
            id: "8",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co1r7g.jpg",
            gameName: "PUBG: Battlegrounds",
            developer: "PUBG Corporation",
            available: "yes",
            categoryFilters: ["Battle Royale", "Tactical Shooter"],
            slug: "pubg-battlegrounds"
        ),
        GamerConnectGame(
            id: "9",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3wlj.jpg",
            gameName: "Fall Guys",
            developer: "Mediatonic",
            available: "yes",
            categoryFilters: ["Battle Royale", "Party Game"],
            slug: "fall-guys"
        ),
        
        // RPG Games
        GamerConnectGame(
            id: "10",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co4jni.jpg",
            gameName: "Elden Ring",
            developer: "FromSoftware",
            available: "yes",
            categoryFilters: ["RPG", "Action"],
            slug: "elden-ring"
        ),
        GamerConnectGame(
            id: "11",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co1ycj.jpg",
            gameName: "Final Fantasy XIV",
            developer: "Square Enix",
            available: "yes",
            categoryFilters: ["RPG", "MMORPG"],
            slug: "final-fantasy-xiv"
        ),
        GamerConnectGame(
            id: "12",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3vke.jpg",
            gameName: "Genshin Impact",
            developer: "miHoYo",
            available: "yes",
            categoryFilters: ["RPG", "Action"],
            slug: "genshin-impact"
        ),
        GamerConnectGame(
            id: "13",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co5w3k.jpg",
            gameName: "Diablo IV",
            developer: "Blizzard",
            available: "yes",
            categoryFilters: ["RPG", "Action"],
            slug: "diablo-iv"
        ),
        GamerConnectGame(
            id: "14",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co670h.jpg",
            gameName: "Baldur's Gate 3",
            developer: "Larian Studios",
            available: "yes",
            categoryFilters: ["RPG", "Turn-Based"],
            slug: "baldurs-gate-3"
        ),
        
        // Sports Games
        GamerConnectGame(
            id: "15",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co6y8h.jpg",
            gameName: "EA FC 24",
            developer: "EA Sports",
            available: "yes",
            categoryFilters: ["Sports", "Football"],
            slug: "ea-fc-24"
        ),
        GamerConnectGame(
            id: "16",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co6qz8.jpg",
            gameName: "NBA 2K24",
            developer: "2K Sports",
            available: "yes",
            categoryFilters: ["Sports", "Basketball"],
            slug: "nba-2k24"
        ),
        GamerConnectGame(
            id: "17",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co6kzd.jpg",
            gameName: "Madden NFL 24",
            developer: "EA Sports",
            available: "yes",
            categoryFilters: ["Sports", "American Football"],
            slug: "madden-nfl-24"
        ),
        GamerConnectGame(
            id: "18",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co5w0w.jpg",
            gameName: "Rocket League",
            developer: "Psyonix",
            available: "yes",
            categoryFilters: ["Sports", "Racing"],
            slug: "rocket-league"
        ),
        
        // MOBA Games
        GamerConnectGame(
            id: "19",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co49wj.jpg",
            gameName: "League of Legends",
            developer: "Riot Games",
            available: "yes",
            categoryFilters: ["MOBA", "Strategy"],
            slug: "league-of-legends"
        ),
        GamerConnectGame(
            id: "20",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co1wyy.jpg",
            gameName: "Dota 2",
            developer: "Valve",
            available: "yes",
            categoryFilters: ["MOBA", "Strategy"],
            slug: "dota-2"
        ),
        GamerConnectGame(
            id: "21",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3p5f.jpg",
            gameName: "Smite 2",
            developer: "Hi-Rez Studios",
            available: "yes",
            categoryFilters: ["MOBA", "Action"],
            slug: "smite-2"
        ),
        
        // Racing Games
        GamerConnectGame(
            id: "22",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3ofx.jpg",
            gameName: "Forza Horizon 5",
            developer: "Playground Games",
            available: "yes",
            categoryFilters: ["Racing", "Open World"],
            slug: "forza-horizon-5"
        ),
        GamerConnectGame(
            id: "23",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co3qfi.jpg",
            gameName: "Gran Turismo 7",
            developer: "Polyphony Digital",
            available: "yes",
            categoryFilters: ["Racing", "Simulation"],
            slug: "gran-turismo-7"
        ),
        GamerConnectGame(
            id: "24",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co5vkh.jpg",
            gameName: "Need for Speed Unbound",
            developer: "Criterion Games",
            available: "yes",
            categoryFilters: ["Racing", "Arcade"],
            slug: "need-for-speed-unbound"
        ),
        GamerConnectGame(
            id: "25",
            imageUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big_2x/co23jy.jpg",
            gameName: "Mario Kart 8 Deluxe",
            developer: "Nintendo",
            available: "yes",
            categoryFilters: ["Racing", "Party Game"],
            slug: "mario-kart-8-deluxe"
        )
    ]
    
    static func games(for genre: GameGenre) -> [GamerConnectGame] {
        if genre == .all {
            return allGames
        }
        
        return allGames.filter { game in
            game.categoryFilters.contains { filter in
                genre.categoryFilterValues.contains { genreValue in
                    filter.lowercased().contains(genreValue.lowercased())
                }
            }
        }
    }
}
#endif
