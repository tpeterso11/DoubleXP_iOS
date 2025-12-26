//
//  IGDBService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/5/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// A wrapper to hold our cached game data along with an expiration date.
// We change this from a struct to a class to make it compatible with NSCache.
private class CacheEntry {
    let game: IGDBGame
    let expirationDate: Date

    // Classes need an explicit initializer.
    init(game: IGDBGame, expirationDate: Date) {
        self.game = game
        self.expirationDate = expirationDate
    }

    func isExpired(asOf date: Date = Date()) -> Bool {
        return date > expirationDate
    }
}

// A reusable service to handle all IGDB API interactions.
class IGDBService {
    static let shared = IGDBService()
    
    private let twitchClientID = "aio1d4ucufi6bpzae0lxtndanh3nob"
    private let twitchClientSecret = "q77w14n9xvczqejlpv7q5rs8jeheev"
    
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    private let storage = GameStorageManager.shared

    private init() {}

    // Authentication
    struct TwitchTokenResponse: Codable {
        let access_token: String
        let expires_in: Int
    }

    private func getAuthToken() async throws -> String {
        if let token = accessToken, let expiration = tokenExpirationDate, expiration > Date() {
            return token
        }
        
        let urlString = "https://id.twitch.tv/oauth2/token?client_id=\(twitchClientID)&client_secret=\(twitchClientSecret)&grant_type=client_credentials"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TwitchTokenResponse.self, from: data)
        self.accessToken = tokenResponse.access_token
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60))
        return tokenResponse.access_token
    }

    // Fetching
    func fetchGameDetails(bySlug slug: String, forceReload: Bool = true) async -> GamerConnectGame? {
        // 1. Check Storage First
        if !forceReload, let cached = storage.getGame(slug: slug) {
            print("✅ [IGDBService] HIT local storage for: \(slug)")
            return cached
        }

        do {
            let token = try await getAuthToken()
            guard let url = URL(string: "https://api.igdb.com/v4/games") else { return nil }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(twitchClientID, forHTTPHeaderField: "Client-ID")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let fields = "name,slug,summary,storyline,hypes,aggregated_rating,aggregated_rating_count,total_rating,total_rating_count,first_release_date,involved_companies.company.name,involved_companies.developer,genres.name,platforms.name,platforms.abbreviation,player_perspectives.name,themes.name,game_modes.name,cover.url,screenshots.url,videos.video_id,similar_games.name,similar_games.cover.url,age_ratings.category,age_ratings.rating,websites.category,websites.url,release_dates.y"

            let queryBody = """
            fields \(fields);
            where slug = "\(slug)";
            limit 1;
            """

            request.httpBody = queryBody.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            let games = try JSONDecoder().decode([IGDBGame].self, from: data)

            if let igdbGame = games.first {
                // Convert to canonical model
                let game = igdbGame.asGamerConnectGame()
                
                // 2. Save to Storage
                storage.save(game: game)
                return game
            }
            return nil
        } catch {
            print("🔴 [IGDBService] Error: \(error)")
            return nil
        }
    }
    
    func isYouTubeVideoEmbeddable(videoID: String) async -> Bool {
        let urlStr = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoID)&format=json"
        guard let url = URL(string: urlStr) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return http.statusCode == 200
            }
        } catch {
            return false
        }
        return false
    }
    
    func fetchGames(bySlugs slugs: [String]) async -> [GamerConnectGame] {
            // 1. Separate cached vs missing
            var foundGames: [GamerConnectGame] = []
            var missingSlugs: [String] = []
            
            // We assume GameStorageManager is available from DiscoverFeature.swift
            let storage = GameStorageManager.shared
            
            for slug in slugs {
                if let cached = storage.getGame(slug: slug) {
                    foundGames.append(cached)
                } else {
                    missingSlugs.append(slug)
                }
            }
            
            if missingSlugs.isEmpty {
                return foundGames
            }
            
            // 2. Fetch missing from IGDB
            do {
                let token = try await getAuthToken() // Accesses private method in main class
                guard let url = URL(string: "https://api.igdb.com/v4/games") else { return foundGames }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("aio1d4ucufi6bpzae0lxtndanh3nob", forHTTPHeaderField: "Client-ID") // Using ID from main file
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let fields = "name,slug,summary,storyline,aggregated_rating,aggregated_rating_count,total_rating,total_rating_count,first_release_date,involved_companies.company.name,involved_companies.developer,genres.name,platforms.name,platforms.abbreviation,player_perspectives.name,themes.name,game_modes.name,cover.url,screenshots.url,videos.video_id,videos.name,similar_games.name,similar_games.cover.url,age_ratings.category,age_ratings.rating,websites.category,websites.url,release_dates.y"
                
                // Batch query
                let slugList = missingSlugs.map { "\"\($0)\"" }.joined(separator: ",")
                let queryBody = """
                fields \(fields);
                where slug = (\(slugList));
                limit 50;
                """
                
                request.httpBody = queryBody.data(using: .utf8)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                // Use the private struct from the main file, assuming we can access it
                // (In a single file setup this works, otherwise make RawIGDBGame internal/public)
                // For this canvas, I will redefine a decoder helper here to be safe.
                struct BatchIGDBGame: Decodable {
                    let id: Int
                    let name: String
                    let slug: String
                    let summary: String?
                    let storyline: String?
                    let cover: Cover?
                    let genres: [Genre]?
                    let platforms: [Platform]?
                    let involved_companies: [InvolvedCompany]?
                    let first_release_date: TimeInterval?
                    let aggregated_rating: Double?
                    let aggregated_rating_count: Int?
                    let total_rating: Double?
                    let total_rating_count: Int?
                    let game_modes: [GameMode]?
                    let release_dates: [ReleaseDate]?
                    let themes: [Theme]?
                    let player_perspectives: [PlayerPerspective]?
                    let similar_games: [SimilarGame]?
                    let age_ratings: [AgeRating]?
                    let websites: [Website]?
                    let screenshots: [Screenshot]?
                    let videos: [Video]?
                }
                
                let rawGames = try JSONDecoder().decode([BatchIGDBGame].self, from: data)
                
                for raw in rawGames {
                    // Manual mapping logic (duplicated from main file for safety/isolation)
                    let developer = raw.involved_companies?.first(where: { $0.developer == true })?.company.name ?? ""
                    let rawUrl = raw.cover?.url ?? ""
                    let imageUrl = rawUrl.replacingOccurrences(of: "t_thumb", with: "t_cover_big_2x")
                        .replacingOccurrences(of: "//", with: "https://")
                    
                    let releaseDateStr: String? = {
                        guard let ts = raw.first_release_date else { return nil }
                        let date = Date(timeIntervalSince1970: ts)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter.string(from: date)
                    }()
                    
                    var isAvailable = "no"
                    if let ts = raw.first_release_date, Date().timeIntervalSince1970 >= ts {
                        isAvailable = "yes"
                    }

                    let game = GamerConnectGame(
                        id: String(raw.id),
                        imageUrl: imageUrl,
                        gameName: raw.name,
                        developer: developer,
                        hook: raw.storyline ?? raw.summary,
                        available: isAvailable,
                        availableConsoles: raw.platforms?.map { $0.name ?? "" } ?? [],
                        gameModes: raw.game_modes?.map { $0.name ?? "" } ?? [],
                        releaseDate: releaseDateStr,
                        gameType: raw.genres?.first?.name,
                        categoryFilters: raw.genres?.map { $0.name ?? "" } ?? [],
                        gameDescription: raw.summary ?? "",
                        slug: raw.slug,
                        metacriticScore: raw.aggregated_rating.map { Int($0) },
                        userScore: raw.total_rating.map { Int($0) },
                        summary: raw.summary,
                        cover: raw.cover,
                        first_release_date: raw.first_release_date,
                        involved_companies: raw.involved_companies,
                        genres: raw.genres,
                        platforms: raw.platforms,
                        screenshots: raw.screenshots,
                        videos: raw.videos,
                        storyline: raw.storyline,
                        aggregated_rating: raw.aggregated_rating,
                        aggregated_rating_count: raw.aggregated_rating_count,
                        total_rating: raw.total_rating,
                        total_rating_count: raw.total_rating_count,
                        game_modes_struct: raw.game_modes,
                        release_dates: raw.release_dates,
                        themes: raw.themes,
                        player_perspectives: raw.player_perspectives,
                        similar_games: raw.similar_games,
                        age_ratings: raw.age_ratings,
                        websites: raw.websites
                    )
                    
                    // Save and append
                    storage.save(game: game)
                    foundGames.append(game)
                }
                
            } catch {
                print("🔴 [IGDBService] Batch Fetch Error: \(error)")
            }
            
            return foundGames
        }
}

