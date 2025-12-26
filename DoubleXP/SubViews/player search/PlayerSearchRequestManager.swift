//
//  PlayerSearchRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

// MARK: - Player Search Request Manager

@MainActor
class PlayerSearchRequestManager {
    static let shared = PlayerSearchRequestManager()
    
    private let baseURL = "https://us-central1-gameterminal-767f7.cloudfunctions.net" // Replace with actual API
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Search Players by Game
    
    /// Search for players who play a specific game
    func searchPlayers(
        forGame gameSlug: String,
        query: String? = nil,
        limit: Int = 20,
        cursor: String? = nil
    ) async throws -> (players: [PlayerSearchResult], nextCursor: String?) {
        
        // Build URL with query parameters
        var components = URLComponents(string: "\(baseURL)/players/search")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "game", value: gameSlug),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        // Add current user ID for match calculation
        if let currentUserId = getCurrentUserId() {
            queryItems.append(URLQueryItem(name: "userId", value: currentUserId))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PlayerSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔍 [PlayerSearch] Searching players for game: \(gameSlug)")
        
        // For now, return mock data
        // TODO: Uncomment when API is ready
        /*
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlayerSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlayerSearchError.serverError(httpResponse.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(PlayerSearchResponse.self, from: data)
        let players = decoded.players.map { $0.toPlayerSearchResult() }
        
        return (players, decoded.nextCursor)
        */
        
        // Mock response with delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 second delay
        return (PlayerSearchResult.mockPlayers, nil)
    }
    
    // MARK: - Search Players by Gamertag
    
    /// Search for players by their gamertag (direct user search)
    func searchPlayersByGamertag(
        query: String,
        limit: Int = 20,
        cursor: String? = nil
    ) async throws -> (players: [PlayerSearchResult], nextCursor: String?) {
        
        guard !query.isEmpty else {
            return ([], nil)
        }
        
        var components = URLComponents(string: "\(baseURL)/players/search")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "gamertag"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        if let currentUserId = getCurrentUserId() {
            queryItems.append(URLQueryItem(name: "userId", value: currentUserId))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PlayerSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔍 [PlayerSearch] Searching players by gamertag: \(query)")
        
        // Mock response
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Filter mock data based on query
        let filtered = PlayerSearchResult.mockPlayers.filter {
            $0.gamerTag.lowercased().contains(query.lowercased())
        }
        
        return (filtered.isEmpty ? PlayerSearchResult.mockPlayers : filtered, nil)
    }
    
    // MARK: - Search Games (IGDB)
    
    /// Search for games via IGDB
    func searchGames(
        query: String,
        limit: Int = 20
    ) async throws -> [GameSearchResult] {
        
        guard !query.isEmpty else {
            return []
        }
        
        var components = URLComponents(string: "\(baseURL)/games/search")
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PlayerSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🎮 [PlayerSearch] Searching IGDB for games: \(query)")
        
        // Mock response - in production this hits IGDB via your backend
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return mock games that match query
        let mockGames: [GameSearchResult] = [
            GameSearchResult(id: "1", slug: "call-of-duty-warzone", name: "Call of Duty: Warzone", coverUrl: nil, genre: "FPS", platforms: ["PS5", "Xbox", "PC"], releaseYear: 2020, playerCount: 2400),
            GameSearchResult(id: "2", slug: "battlefield-2042", name: "Battlefield 2042", coverUrl: nil, genre: "FPS", platforms: ["PS5", "Xbox", "PC"], releaseYear: 2021, playerCount: 1800),
            GameSearchResult(id: "3", slug: "fortnite", name: "Fortnite", coverUrl: nil, genre: "Battle Royale", platforms: ["PS5", "Xbox", "PC", "Switch"], releaseYear: 2017, playerCount: 5100),
            GameSearchResult(id: "4", slug: "apex-legends", name: "Apex Legends", coverUrl: nil, genre: "Battle Royale", platforms: ["PS5", "Xbox", "PC"], releaseYear: 2019, playerCount: 3200),
            GameSearchResult(id: "5", slug: "ea-sports-fc-24", name: "EA Sports FC 24", coverUrl: nil, genre: "Sports", platforms: ["PS5", "Xbox", "PC"], releaseYear: 2023, playerCount: 890)
        ]
        
        return mockGames.filter {
            $0.name.lowercased().contains(query.lowercased())
        }
    }
    
    // MARK: - Get Online Player Counts
    
    /// Fetch online player counts for multiple games
    func getOnlinePlayerCounts(forGames slugs: [String]) async throws -> [String: Int] {
        
        guard !slugs.isEmpty else {
            return [:]
        }
        
        var components = URLComponents(string: "\(baseURL)/games/online-counts")
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "slugs", value: slugs.joined(separator: ","))
        ]
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PlayerSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📊 [PlayerSearch] Fetching online counts for \(slugs.count) games")
        
        // Mock response
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Return mock counts
        var counts: [String: Int] = [:]
        for slug in slugs {
            counts[slug] = Int.random(in: 100...5000)
        }
        
        return counts
    }
    
    // MARK: - Get User's Games
    
    /// Get games that the current user plays (from GameStorageManager or user profile)
    func getUserGames() -> [UserGameTile] {
        // Get user's games from their profile
        guard let currentUser = UserProvider.shared.currentUser,
              !currentUser.games.isEmpty else {
            return []
        }
        
        // Convert user's GameItems to UserGameTiles
        var tiles: [UserGameTile] = []
        
        for gameItem in currentUser.games {
            // Try to get full game info from storage
            if let fullGame = GameStorageManager.shared.getGame(slug: gameItem) {
                let tile = UserGameTile(
                    id: fullGame.id,
                    slug: fullGame.slug,
                    name: fullGame.gameName,
                    coverUrl: fullGame.imageUrl,
                    genre: fullGame.genresString,
                    onlinePlayerCount: Int.random(in: 500...5000), // Will be fetched separately
                    gradientColors: gradientColorsForGame(fullGame.slug)
                )
                tiles.append(tile)
            }
        }
        
        return tiles
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() -> String? {
        return UserProvider.shared.currentUser?.uId
    }
    
    private func getAuthToken() -> String? {
        // TODO: Get actual auth token
        return nil
    }
    
    /// Generate gradient colors based on game slug (for visual variety)
    private func gradientColorsForGame(_ slug: String) -> [String] {
        let gradients: [[String]] = [
            ["2d5016", "1a3009"], // Green (military/shooter)
            ["1a3a5c", "0d1f33"], // Blue (tactical)
            ["4a1a6b", "2d1041"], // Purple (fantasy/BR)
            ["5c3a1a", "332009"], // Orange (sports)
            ["1a5c5c", "0d3333"], // Teal (sci-fi)
            ["5c1a3a", "330d1f"], // Red (action)
            ["3a5c1a", "1f330d"], // Lime (racing)
            ["5c5c1a", "33330d"]  // Yellow (casual)
        ]
        
        // Hash the slug to get consistent colors
        let hash = abs(slug.hashValue)
        let index = hash % gradients.count
        
        return gradients[index]
    }
}

// MARK: - Errors

enum PlayerSearchError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noResults
    case notAuthenticated
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noResults:
            return "No results found"
        case .notAuthenticated:
            return "You must be logged in to search"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
