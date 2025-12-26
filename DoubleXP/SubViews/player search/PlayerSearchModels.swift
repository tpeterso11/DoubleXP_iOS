//
//  PlayerSearchModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// MARK: - Search Mode

enum PlayerSearchMode: String, CaseIterable {
    case games = "games"
    case players = "players"
    
    var displayName: String {
        switch self {
        case .games: return "Games"
        case .players: return "Players"
        }
    }
    
    var icon: String {
        switch self {
        case .games: return "gamecontroller.fill"
        case .players: return "person.fill"
        }
    }
    
    var placeholder: String {
        switch self {
        case .games: return "Search for a game..."
        case .players: return "Search by gamertag..."
        }
    }
}

// MARK: - Player Search Result

struct PlayerSearchResult: Identifiable, Equatable {
    let id: String
    let oddsId: String?
    let gamerTag: String
    let avatarUrl: String?
    let bio: String?
    let isOnline: Bool
    let onlineStatus: PlayerOnlineStatus
    let level: Int
    let xp: Int
    let gamesInCommon: [String] // Game slugs or names
    let matchPercentage: Int? // Compatibility score
    let rank: String? // e.g., "Diamond", "Gold"
    let platforms: [String] // e.g., ["PS5", "PC"]
    let friendCount: Int
    let joinedDate: Date?
    
    var avatarInitial: String {
        String(gamerTag.prefix(1)).uppercased()
    }
    
    var levelDisplay: String {
        "Lvl \(level)"
    }
    
    var xpDisplay: String {
        if xp >= 1000 {
            return String(format: "%.1fk XP", Double(xp) / 1000.0)
        }
        return "\(xp) XP"
    }
    
    static func == (lhs: PlayerSearchResult, rhs: PlayerSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

enum PlayerOnlineStatus: String, Codable {
    case online = "online"
    case inGame = "in_game"
    case away = "away"
    case offline = "offline"
    
    var displayText: String {
        switch self {
        case .online: return "Online"
        case .inGame: return "In Game"
        case .away: return "Away"
        case .offline: return "Offline"
        }
    }
    
    var color: String {
        switch self {
        case .online: return "4ADE80"
        case .inGame: return "667eea"
        case .away: return "F59E0B"
        case .offline: return "6B7280"
        }
    }
}

// MARK: - Game Search Result (for IGDB)

struct GameSearchResult: Identifiable, Equatable {
    let id: String
    let slug: String
    let name: String
    let coverUrl: String?
    let genre: String?
    let platforms: [String]
    let releaseYear: Int?
    let playerCount: Int // Users playing this game on platform
    
    var genreDisplay: String {
        genre ?? "Game"
    }
    
    static func == (lhs: GameSearchResult, rhs: GameSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User's Game (for display tiles)

struct UserGameTile: Identifiable, Equatable {
    let id: String
    let slug: String
    let name: String
    let coverUrl: String?
    let genre: String?
    let onlinePlayerCount: Int
    let gradientColors: [String] // Hex colors for gradient
    
    var genreDisplay: String {
        genre ?? "Game"
    }
    
    var onlineDisplay: String {
        if onlinePlayerCount >= 1000 {
            return String(format: "%.1fk online", Double(onlinePlayerCount) / 1000.0)
        }
        return "\(onlinePlayerCount) online"
    }
    
    static func == (lhs: UserGameTile, rhs: UserGameTile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - API Response Models

struct PlayerSearchResponse: Codable {
    let success: Bool
    let players: [PlayerSearchResponseItem]
    let totalCount: Int
    let nextCursor: String?
}

struct PlayerSearchResponseItem: Codable {
    let id: String
    let oddsId: String?
    let gamerTag: String
    let avatarUrl: String?
    let bio: String?
    let isOnline: Bool
    let onlineStatus: String?
    let level: Int?
    let xp: Int?
    let games: [String]?
    let matchPercentage: Int?
    let rank: String?
    let platforms: [String]?
    let friendCount: Int?
    let joinedAt: Double?
    
    func toPlayerSearchResult() -> PlayerSearchResult {
        PlayerSearchResult(
            id: id,
            oddsId: oddsId,
            gamerTag: gamerTag,
            avatarUrl: avatarUrl,
            bio: bio,
            isOnline: isOnline,
            onlineStatus: PlayerOnlineStatus(rawValue: onlineStatus ?? "offline") ?? .offline,
            level: level ?? 1,
            xp: xp ?? 0,
            gamesInCommon: games ?? [],
            matchPercentage: matchPercentage,
            rank: rank,
            platforms: platforms ?? [],
            friendCount: friendCount ?? 0,
            joinedDate: joinedAt != nil ? Date(timeIntervalSince1970: joinedAt! / 1000) : nil
        )
    }
}

struct GameOnlineCountResponse: Codable {
    let success: Bool
    let counts: [String: Int] // slug -> count
}

// MARK: - Mock Data

extension PlayerSearchResult {
    static let mockPlayers: [PlayerSearchResult] = [
        PlayerSearchResult(
            id: "user1",
            oddsId: nil,
            gamerTag: "ShadowNinja",
            avatarUrl: nil,
            bio: "FPS enthusiast. Always looking for a squad.",
            isOnline: true,
            onlineStatus: .online,
            level: 42,
            xp: 12500,
            gamesInCommon: ["Call of Duty", "Battlefield"],
            matchPercentage: 92,
            rank: "Diamond",
            platforms: ["PS5", "PC"],
            friendCount: 234,
            joinedDate: Date().addingTimeInterval(-86400 * 180)
        ),
        PlayerSearchResult(
            id: "user2",
            oddsId: nil,
            gamerTag: "PixelWarrior",
            avatarUrl: nil,
            bio: "Competitive gamer since '09",
            isOnline: true,
            onlineStatus: .inGame,
            level: 67,
            xp: 34200,
            gamesInCommon: ["Fortnite", "Apex Legends"],
            matchPercentage: 87,
            rank: "Master",
            platforms: ["Xbox", "PC"],
            friendCount: 512,
            joinedDate: Date().addingTimeInterval(-86400 * 365)
        ),
        PlayerSearchResult(
            id: "user3",
            oddsId: nil,
            gamerTag: "CasualKing",
            avatarUrl: nil,
            bio: "Just here to have fun",
            isOnline: false,
            onlineStatus: .offline,
            level: 23,
            xp: 5600,
            gamesInCommon: ["FIFA 24"],
            matchPercentage: 65,
            rank: "Gold",
            platforms: ["PS5"],
            friendCount: 89,
            joinedDate: Date().addingTimeInterval(-86400 * 90)
        ),
        PlayerSearchResult(
            id: "user4",
            oddsId: nil,
            gamerTag: "NightOwlGamer",
            avatarUrl: nil,
            bio: "Late night gaming sessions are my thing",
            isOnline: true,
            onlineStatus: .away,
            level: 55,
            xp: 22100,
            gamesInCommon: ["Call of Duty", "Fortnite", "Battlefield"],
            matchPercentage: 95,
            rank: "Platinum",
            platforms: ["PC"],
            friendCount: 178,
            joinedDate: Date().addingTimeInterval(-86400 * 240)
        ),
        PlayerSearchResult(
            id: "user5",
            oddsId: nil,
            gamerTag: "ProSniper",
            avatarUrl: nil,
            bio: "Headshots only",
            isOnline: true,
            onlineStatus: .online,
            level: 89,
            xp: 67800,
            gamesInCommon: ["Call of Duty", "Battlefield", "Apex Legends"],
            matchPercentage: 88,
            rank: "Grandmaster",
            platforms: ["PC", "PS5", "Xbox"],
            friendCount: 891,
            joinedDate: Date().addingTimeInterval(-86400 * 500)
        )
    ]
}

extension UserGameTile {
    static let mockGames: [UserGameTile] = [
        UserGameTile(
            id: "cod",
            slug: "call-of-duty-warzone",
            name: "Call of Duty",
            coverUrl: nil,
            genre: "FPS • Shooter",
            onlinePlayerCount: 2400,
            gradientColors: ["2d5016", "1a3009"]
        ),
        UserGameTile(
            id: "bf",
            slug: "battlefield-2042",
            name: "Battlefield 2042",
            coverUrl: nil,
            genre: "FPS • Action",
            onlinePlayerCount: 1800,
            gradientColors: ["1a3a5c", "0d1f33"]
        ),
        UserGameTile(
            id: "fn",
            slug: "fortnite",
            name: "Fortnite",
            coverUrl: nil,
            genre: "Battle Royale",
            onlinePlayerCount: 5100,
            gradientColors: ["4a1a6b", "2d1041"]
        ),
        UserGameTile(
            id: "fifa",
            slug: "ea-sports-fc-24",
            name: "EA Sports FC 24",
            coverUrl: nil,
            genre: "Sports",
            onlinePlayerCount: 890,
            gradientColors: ["5c3a1a", "332009"]
        )
    ]
}
