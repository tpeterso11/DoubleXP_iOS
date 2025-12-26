//
//  GamerConnectGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol GameRepresentable {
    func asGamerConnectGame() -> GamerConnectGame
}

struct Cover: Codable, Hashable, Sendable { let url: String? }
struct Genre: Codable, Hashable, Sendable { let name: String? }
struct Platform: Codable, Hashable, Sendable { let name: String?; let abbreviation: String? }
struct Screenshot: Codable, Hashable, Sendable { let url: String? }
struct Video: Codable, Hashable, Sendable { let video_id: String?; let name: String? }
struct InvolvedCompany: Codable, Hashable, Sendable {
    let company: Company
    let developer: Bool?
    struct Company: Codable, Hashable, Sendable { let name: String? }
}
struct GameMode: Codable, Hashable, Sendable { let name: String? }
struct ReleaseDate: Codable, Hashable, Sendable { let y: Int? }
struct Theme: Codable, Hashable, Sendable { let name: String? }
struct PlayerPerspective: Codable, Hashable, Sendable { let name: String? }
struct SimilarGame: Codable, Hashable, Sendable { let id: Int; let name: String; let cover: Cover? }
struct AgeRating: Codable, Hashable, Sendable { let category: Int?; let rating: Int? }
struct Website: Codable, Hashable, Sendable { let category: Int?; let url: String? }

// MARK: - GamerConnectGame (Canonical Model)
struct GamerConnectGame: Codable, Hashable, Identifiable, Sendable {
    // Identity
    let id: String

    // Required
    var imageUrl: String?
    var gameName: String
    var developer: String?

    // Optionals/meta
    var hook: String?
    var twitchGameId: String?
    var twitterHandle: String?
    var twitchHandle: String?

    /// "yes" / "no"
    var available: String

    var statsAvailable: Bool
    var teamNeeds: [String]
    var availableConsoles: [String]
    var gameModes: [String]
    var secondaryName: String?
    var releaseDate: String?          // "yyyy-MM-dd"
    var gameType: String?
    var categoryFilters: [String] = []
    var lookingFor: [String] = []
    var ratings: [[String: String]] = []
    var quickReviews: [[String: String]] = []
    var gameDescription: String = ""
    var alternateImageUrl: String?
    var ideal: String?
    var quizUrl: String?
    var timeCommitment: String?
    var complexity: String?
    var ratingsBreakdown: [String: Int]?
    var slug: String
    var metacriticScore: Int?
    var userScore: Int?

    // --- New Fields from IGDB ---
    let summary: String?
    let cover: Cover?
    let first_release_date: TimeInterval?
    let involved_companies: [InvolvedCompany]?
    let genres: [Genre]?
    let platforms: [Platform]?
    let screenshots: [Screenshot]?
    let videos: [Video]?
    
    // Data for Gamers
    let storyline: String?
    let aggregated_rating: Double?
    let aggregated_rating_count: Int?
    let total_rating: Double?
    let total_rating_count: Int?
    let game_modes_struct: [GameMode]? // renamed to avoid conflict with existing gameModes [String]
    let release_dates: [ReleaseDate]?
    
    // Data for Newcomers
    let themes: [Theme]?
    let player_perspectives: [PlayerPerspective]?
    let similar_games: [SimilarGame]?
    let age_ratings: [AgeRating]?
    let websites: [Website]?
    //let primaryStore: StoreLink?      // <- NEW
    //let allStores: [StoreLink]?       // <- NEW
    
    var complexityScore: Double?
    var complexityLabel: String?
    var timeScore: Double?
    var timeLabel: String?
    var hypeCount: Int?
    

    init(
        id: String,
        imageUrl: String,
        gameName: String,
        developer: String = "",
        hook: String? = nil,
        statsAvailable: Bool = false,
        teamNeeds: [String] = [],
        twitterHandle: String? = nil,
        twitchHandle: String? = nil,
        available: String = "no",
        availableConsoles: [String] = [],
        gameModes: [String] = [],
        secondaryName: String? = nil,
        releaseDate: String? = nil,
        gameType: String? = nil,
        categoryFilters: [String] = [],
        lookingFor: [String] = [],
        ratings: [[String: String]] = [],
        quickReviews: [[String: String]] = [],
        gameDescription: String = "",
        alternateImageUrl: String? = nil,
        ideal: String? = nil,
        quizUrl: String? = nil,
        timeCommitment: String? = nil,
        complexity: String? = nil,
        slug: String? = nil,
        metacriticScore: Int? = nil,
        userScore: Int? = nil,
        //mainStore: StoreLink? = nil,
        //allStores: [StoreLink]? = nil,
        
        // New Optionals defaults
        summary: String? = nil,
        cover: Cover? = nil,
        first_release_date: TimeInterval? = nil,
        involved_companies: [InvolvedCompany]? = nil,
        genres: [Genre]? = nil,
        platforms: [Platform]? = nil,
        screenshots: [Screenshot]? = nil,
        videos: [Video]? = nil,
        storyline: String? = nil,
        aggregated_rating: Double? = nil,
        aggregated_rating_count: Int? = nil,
        total_rating: Double? = nil,
        total_rating_count: Int? = nil,
        game_modes_struct: [GameMode]? = nil,
        release_dates: [ReleaseDate]? = nil,
        themes: [Theme]? = nil,
        player_perspectives: [PlayerPerspective]? = nil,
        similar_games: [SimilarGame]? = nil,
        age_ratings: [AgeRating]? = nil,
        websites: [Website]? = nil,
        complexityScore: Double? = nil,
        complexityLabel: String? = nil,
        timeScore: Double? = nil,
        timeLabel: String? = nil,
        hypeCount: Int? = nil,
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.gameName = gameName
        self.developer = developer
        self.hook = hook
        self.statsAvailable = statsAvailable
        self.teamNeeds = teamNeeds
        self.twitterHandle = twitterHandle
        self.twitchHandle = twitchHandle
        self.available = available
        self.availableConsoles = availableConsoles
        self.gameModes = gameModes
        self.secondaryName = secondaryName
        self.releaseDate = releaseDate
        self.gameType = gameType
        self.categoryFilters = categoryFilters
        self.lookingFor = lookingFor
        self.ratings = ratings
        self.quickReviews = quickReviews
        self.gameDescription = gameDescription
        self.alternateImageUrl = alternateImageUrl
        self.ideal = ideal
        self.quizUrl = quizUrl
        self.timeCommitment = timeCommitment
        self.complexity = complexity
        self.slug = slug ?? ""
        self.metacriticScore = metacriticScore
        self.userScore = userScore
        
        // Init new fields
        self.summary = summary
        self.cover = cover
        self.first_release_date = first_release_date
        self.involved_companies = involved_companies
        self.genres = genres
        self.platforms = platforms
        self.screenshots = screenshots
        self.videos = videos
        self.storyline = storyline
        self.aggregated_rating = aggregated_rating
        self.aggregated_rating_count = aggregated_rating_count
        self.total_rating = total_rating
        self.total_rating_count = total_rating_count
        self.game_modes_struct = game_modes_struct
        self.release_dates = release_dates
        self.themes = themes
        self.player_perspectives = player_perspectives
        self.similar_games = similar_games
        self.age_ratings = age_ratings
        self.websites = websites
        self.complexityScore = complexityScore
        self.complexityLabel = complexityLabel
        self.timeScore = timeScore
        self.timeLabel = timeLabel
        //self.primaryStore = mainStore
        //self.allStores = allStores
        self.hypeCount = hypeCount
    }
}

// MARK: - RawgGame (API Model)
struct RawgGame: Decodable {
    let id: Int
    let name: String
    let released: String?
    let background_image: String?
    let rating: Double
    let slug: String
    let genres: [Genre]?
    let platforms: [PlatformWrapper]?
    let added: Int?
    let ratings_count: Int?
    let metacritic: Int?

    struct Genre: Decodable { let name: String }
    struct PlatformWrapper: Decodable {
        let platform: Platform
        struct Platform: Decodable { let name: String }
    }
}

extension RawgGame: GameRepresentable {
    func asGamerConnectGame() -> GamerConnectGame {
        let idString = String(id)
        let imageUrl = background_image ?? ""
        
        var available = "no"
        if let s = released {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "yyyy-MM-dd"
            if let d = fmt.date(from: s), d <= Date() {
                available = "yes"
            }
        }

        let consoles: [String] = (platforms ?? []).map { $0.platform.name }
        let genreNames = genres?.compactMap { $0.name } ?? []

        return GamerConnectGame(
            id: idString,
            imageUrl: imageUrl,
            gameName: name,
            developer: "",
            available: available,
            availableConsoles: consoles,
            secondaryName: slug,
            releaseDate: released,
            gameType: genreNames.first ?? "Multigenre",
            categoryFilters: genreNames,
            gameDescription: "",
            alternateImageUrl: imageUrl,
            slug: slug,
            metacriticScore: metacritic,
            userScore: ratings_count
        )
    }
}
