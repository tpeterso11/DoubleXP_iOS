//
//  IGDBGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/5/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

struct IGDBGame: Codable, Identifiable {
    let id: Int
    
    // --- Data for Everyone ---
    let name: String?
    let summary: String? // The main synopsis
    let cover: Cover?
    let first_release_date: TimeInterval?
    let involved_companies: [InvolvedCompany]?
    let genres: [Genre]?
    let platforms: [Platform]?
    let screenshots: [Screenshot]?
    let videos: [Video]?
    let hypes: Int?
    
    // --- Data for Gamers ---
    let storyline: String? // Deeper narrative summary
    let aggregated_rating: Double? // Critic score (like Metacritic)
    let aggregated_rating_count: Int?
    let total_rating: Double? // User score
    let total_rating_count: Int?
    let game_modes: [GameMode]?
    let release_dates: [ReleaseDate]?
    
    // --- Data for Newcomers ---
    let themes: [Theme]? // e.g., "Action", "Fantasy", "Sci-fi"
    let player_perspectives: [PlayerPerspective]? // e.g., "First-person", "Third-person"
    
    let similar_games: [SimilarGame]?
    let age_ratings: [AgeRating]?
    let websites: [Website]?
    let slug: String?
    
    //let game_modes: [GameMode]?
    
    // Computed property to get a high-res cover image URL
    var coverURL: URL? {
        guard let urlString = cover?.url else { return nil }
        let highResURL = "https:" + urlString.replacingOccurrences(of: "t_thumb", with: "t_cover_big_2x")
        return URL(string: highResURL)
    }
}

extension IGDBGame {
    /// True if the first_release_date is in the past (or today)
    var isReleased: Bool {
        guard let releaseTimestamp = first_release_date else { return false }
        let releaseDate = Date(timeIntervalSince1970: releaseTimestamp)
        return releaseDate <= Date()
    }
    
    /// "yyyy-MM-dd" formatted release date (UTC) or nil.
    var releaseDateString: String? {
        guard let timestamp = first_release_date else { return nil }
        let date = Date(timeIntervalSince1970: timestamp)
        return IGDBGame.dateFormatter.string(from: date)
    }
    
    /// Comma-separated developer names from involved_companies.
    /// Falls back to first company name if no explicit developer flag is set.
    var developerNames: String? {
        guard let companies = involved_companies, !companies.isEmpty else {
            return nil
        }
        
        // Prefer companies explicitly marked as developer
        let explicitDevelopers = companies
            .filter { $0.developer == true }
            .compactMap { $0.company.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if !explicitDevelopers.isEmpty {
            return explicitDevelopers.joined(separator: ", ")
        }
        
        // Fallback: just use the first non-empty company name
        if let firstName = companies
            .compactMap({ $0.company.name?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) {
            return firstName
        }
        
        return nil
    }
    
    /// High-res screenshot URLs from `screenshots`
    var screenshotURLs: [String] {
        (screenshots ?? []).compactMap { shot in
            guard let url = shot.url else { return nil }
            // bump quality from t_thumb to something big for fullscreen
            return "https:" + url.replacingOccurrences(of: "t_thumb", with: "t_screenshot_huge")
        }
    }
    
    /// YouTube (or video) IDs from `videos`
    var videoIDs: [String] {
        (videos ?? []).compactMap { $0.video_id }.filter { !$0.isEmpty }
    }
    
    /// Simplified "similar game" summary models for UI carousels
    var similarGameSummaries: [SimilarGameSummary] {
        (similar_games ?? []).map { sg in
            let imageUrl: String
            if let raw = sg.cover?.url {
                imageUrl = "https:" + raw.replacingOccurrences(of: "t_thumb",
                                                                with: "t_cover_big_2x")
            } else {
                imageUrl = ""
            }
            
            return SimilarGameSummary(
                id: sg.id,
                name: sg.name,
                imageUrl: imageUrl,
                slug: ""
            )
        }
    }
    
    /// "Main" website: try official site or Steam/store first, then fallback to any.
    var primaryWebsiteURL: String? {
        // IGDB website categories:
        // 1 = official, 13 = Steam; you can tweak this priority
        let primary = websites?.first(where: { $0.category == 1 || $0.category == 13 })?.url
        if let primary { return primary }
        return websites?.first?.url
    }
    
    /// Primary age rating (use the first one if multiple)
    var primaryAgeRating: AgeRating? {
        age_ratings?.first
    }
    
    // MARK: - Shared DateFormatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - GameRepresentable Conformance
extension IGDBGame: GameRepresentable {
    func asGamerConnectGame() -> GamerConnectGame {
        // Core identifiers
        let idString = String(id)
        let slugValue = slug ?? idString
        
        // Cover -> string URL
        let coverUrlString: String = {
            guard let raw = cover?.url else { return "" }
            return "https:" + raw.replacingOccurrences(of: "t_thumb",
                                                       with: "t_cover_big_2x")
        }()
        
        // Developer names (from involved_companies)
        let developerNames: String = {
            guard let companies = involved_companies, !companies.isEmpty else { return "" }
            
            let explicit = companies
                .filter { $0.developer == true }
                .compactMap { $0.company.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if !explicit.isEmpty {
                return explicit.joined(separator: ", ")
            }
            
            if let first = companies
                .compactMap({ $0.company.name?.trimmingCharacters(in: .whitespacesAndNewlines) })
                .first(where: { !$0.isEmpty }) {
                return first
            }
            
            return ""
        }()
        
        // Platforms / genres as strings
        let platformNames: [String] = platforms?.compactMap { $0.name } ?? []
        let genreNames: [String] = genres?.compactMap { $0.name } ?? []
        
        // Availability + release date string
        let isReleased: Bool = {
            guard let ts = first_release_date else { return false }
            return Date(timeIntervalSince1970: ts) <= Date()
        }()
        
        let releaseDateString: String? = {
            guard let ts = first_release_date else { return nil }
            let date = Date(timeIntervalSince1970: ts)
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            return fmt.string(from: date)
        }()
        
        // Heuristics
        let complexity = GameHeuristics.computeComplexity(for: self)
        let time = GameHeuristics.computeTimeCommitment(for: self)
        
        return GamerConnectGame(
            id: idString,
            imageUrl: coverUrlString,
            gameName: name ?? "Unknown Game",
            developer: developerNames,
            
            // Optional/meta
            hook: storyline ?? summary,
            statsAvailable: false,
            teamNeeds: [],
            twitterHandle: nil,
            twitchHandle: nil,
            available: isReleased ? "yes" : "no",
            availableConsoles: platformNames,
            gameModes: [],                                     // you still store raw game_modes_struct below
            secondaryName: nil,
            releaseDate: releaseDateString,
            gameType: genreNames.first,
            categoryFilters: genreNames,
            lookingFor: [],
            ratings: [],
            quickReviews: [],
            gameDescription: summary ?? storyline ?? "",
            alternateImageUrl: coverUrlString,
            ideal: nil,
            quizUrl: nil,
            timeCommitment: nil,
            complexity: nil,
            slug: slugValue,
            metacriticScore: aggregated_rating.flatMap { Int($0.rounded()) },
            userScore: total_rating.flatMap { Int($0.rounded()) },
            
            // Raw IGDB-style fields pushed through
            summary: summary,
            cover: cover,
            first_release_date: first_release_date,
            involved_companies: involved_companies,
            genres: genres,
            platforms: platforms,
            screenshots: screenshots,
            videos: videos,
            storyline: storyline,
            aggregated_rating: aggregated_rating,
            aggregated_rating_count: aggregated_rating_count,
            total_rating: total_rating,
            total_rating_count: total_rating_count,
            game_modes_struct: game_modes,            // 👈 from IGDBGame.game_modes
            release_dates: release_dates,
            themes: themes,
            player_perspectives: player_perspectives,
            similar_games: similar_games,
            age_ratings: age_ratings,
            websites: websites,
            
            // Heuristic outputs
            complexityScore: complexity.score,
            complexityLabel: complexity.label,
            timeScore: time.score,
            timeLabel: time.label,
            hypeCount: hypes
        )
    }
}


struct SimilarGameSummary: Codable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String
    let slug: String
}

struct GameStoreLink: Equatable, Codable {
    enum StoreType: String, Codable {
        case steam
        case epic
        case gog
        case xbox
        case playstation
        case nintendoSwitch
        case unknown
    }

    let type: StoreType
    let url: String
}

// MARK: - Supporting Models

/*struct InvolvedCompany: Codable {
    let company: Company?
    let developer: Bool
}

struct ReleaseDate: Codable {
    let y: Int? // The year
}

struct Company: Codable {
    let name: String?
}

struct Cover: Codable {
    let url: String?
}

struct Genre: Codable {
    let name: String?
}

struct Platform: Codable {
    let name: String?
    let abbreviation: String?
}

struct Screenshot: Codable {
    let url: String?
}

struct Video: Codable {
    let video_id: String?
}

struct GameMode: Codable {
    let name: String?
}

struct Theme: Codable {
    let name: String?
}

struct PlayerPerspective: Codable {
    let name: String?
}

struct SimilarGame: Codable, Identifiable {
    let id: Int
    let name: String?
    let cover: Cover?
}

struct AgeRating: Codable {
    let category: Int? // 1 = ESRB, 2 = PEGI
    let rating: Int?
    
    // Helper to get the string value of the rating
    var ratingString: String? {
        switch rating {
            case 6: return "RP"
            case 7: return "EC"
            case 8: return "E"
            case 9: return "E10+"
            case 10: return "T"
            case 11: return "M"
            case 12: return "AO"
            default: return nil
        }
    }
}

struct Website: Codable {
    let category: Int?
    let url: String?
}*/


// MARK: - Twitch Authentication Model

struct TwitchTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

extension GamerConnectGame {
    /// All recognized store links for this game, derived from `websites`.
    var allStoreLinks: [GameStoreLink] {
        guard let websites = websites, !websites.isEmpty else { return [] }

        var seen = Set<String>()
        var links: [GameStoreLink] = []

        for site in websites {
            guard let urlString = site.url, !urlString.isEmpty else { continue }

            let lower = urlString.lowercased()
            let type: GameStoreLink.StoreType?

            if lower.contains("store.steampowered.com") {
                type = .steam
            } else if lower.contains("epicgames.com") {
                type = .epic
            } else if lower.contains("gog.com") {
                type = .gog
            } else if lower.contains("xbox.com")
                        || (lower.contains("microsoft.com") && lower.contains("xbox")) {
                type = .xbox
            } else if lower.contains("playstation.com")
                        || lower.contains("sonyentertainmentnetwork.com") {
                type = .playstation
            } else if lower.contains("nintendo.com") {
                type = .nintendoSwitch
            } else {
                type = nil
            }

            guard let storeType = type else { continue }

            let key = "\(storeType.rawValue)|\(urlString)"
            if seen.insert(key).inserted {
                links.append(GameStoreLink(type: storeType, url: urlString))
            }
        }

        return links
    }

    /// The "primary" store to show in UI (badge/button).
    var primaryStoreLink: GameStoreLink? {
        let stores = allStoreLinks
        guard !stores.isEmpty else { return nil }

        // Preference order: tweak however you want
        let preferredOrder: [GameStoreLink.StoreType] = [
            .steam,
            .playstation,
            .xbox,
            .nintendoSwitch,
            .epic,
            .gog
        ]

        for pref in preferredOrder {
            if let match = stores.first(where: { $0.type == pref }) {
                return match
            }
        }

        // Fallback: just pick the first one
        return stores.first
    }
}
