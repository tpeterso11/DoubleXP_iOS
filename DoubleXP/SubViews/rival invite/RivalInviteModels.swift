//
//  RivalInviteModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// MARK: - Rival Invite Mode

enum RivalInviteMode: String, CaseIterable, Codable {
    case challenge = "challenge"
    case teamUp = "team_up"
    
    var displayTitle: String {
        switch self {
        case .challenge: return "Challenge"
        case .teamUp: return "Team Up"
        }
    }
    
    var icon: String {
        switch self {
        case .challenge: return "⚔️"
        case .teamUp: return "🤝"
        }
    }
    
    var modeLabel: String {
        switch self {
        case .challenge: return "1v1 Challenge Mode"
        case .teamUp: return "Co-op Team Mode"
        }
    }
    
    var actionButtonText: String {
        switch self {
        case .challenge: return "Issue Challenge"
        case .teamUp: return "Send Team Invite"
        }
    }
}

// MARK: - Platform Options

enum RivalPlatform: String, CaseIterable, Codable, Identifiable {
    case playstation = "ps5"
    case xbox = "xbox"
    case pc = "pc"
    case nintendo = "switch"
    case mobile = "mobile"
    case crossplay = "crossplay"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        case .mobile: return "Mobile"
        case .crossplay: return "Crossplay"
        }
    }
    
    var icon: String {
        switch self {
        case .playstation: return "🎮"
        case .xbox: return "🎮"
        case .pc: return "🖥️"
        case .nintendo: return "🕹️"
        case .mobile: return "📱"
        case .crossplay: return "🌐"
        }
    }
    
    var shortName: String {
        switch self {
        case .playstation: return "PS5"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        case .mobile: return "Mobile"
        case .crossplay: return "Cross"
        }
    }
}

// MARK: - Timing Options

enum RivalTiming: String, CaseIterable, Codable, Identifiable {
    case now = "now"
    case fifteenMinutes = "15min"
    case thirtyMinutes = "30min"
    case oneHour = "1hour"
    case later = "later"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .now: return "Now"
        case .fifteenMinutes: return "15 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .later: return "Later"
        }
    }
    
    var icon: String {
        return "⏰"
    }
}

// MARK: - Rival Invite Recipient

struct RivalRecipient: Identifiable, Equatable {
    let id: String // User ID
    let gamerTag: String
    let avatarUrl: String?
    let isOnline: Bool
    let onlineStatus: String? // "online", "in_game", "away"
    
    var avatarInitial: String {
        gamerTag.prefix(1).uppercased()
    }
    
    static func == (lhs: RivalRecipient, rhs: RivalRecipient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Game for Rival Invite

struct RivalGame: Identifiable, Equatable {
    let id: String // Game slug
    let name: String
    let imageUrl: String?
    let genre: String?
    let supportedModes: [String]? // "1v1", "co-op", "multiplayer"
    
    var genreDisplay: String {
        genre ?? "Game"
    }
    
    static func == (lhs: RivalGame, rhs: RivalGame) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Rival Invite Request (for API)

struct RivalInviteRequest: Codable {
    let senderId: String
    let recipientId: String
    let gameSlug: String
    let gameName: String
    let mode: String // "challenge" or "team_up"
    let platform: String
    let timing: String
    let customMessage: String?
    let timestamp: TimeInterval
    
    init(
        senderId: String,
        recipientId: String,
        game: RivalGame,
        mode: RivalInviteMode,
        platform: RivalPlatform,
        timing: RivalTiming,
        customMessage: String? = nil
    ) {
        self.senderId = senderId
        self.recipientId = recipientId
        self.gameSlug = game.id
        self.gameName = game.name
        self.mode = mode.rawValue
        self.platform = platform.rawValue
        self.timing = timing.rawValue
        self.customMessage = customMessage
        self.timestamp = Date().timeIntervalSince1970
    }
}

// MARK: - Rival Invite Response (from API)

struct RivalInviteResponseV2: Codable {
    let success: Bool
    let inviteId: String?
    let message: String?
    let error: String?
}

// MARK: - Rival Invite Status

enum RivalInviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    case cancelled = "cancelled"
}

// MARK: - Sent Rival Invite (for tracking)

struct SentRivalInvite: Identifiable, Codable {
    let id: String
    let recipientId: String
    let recipientGamerTag: String
    let gameSlug: String
    let gameName: String
    let mode: RivalInviteMode
    let platform: RivalPlatform
    let timing: RivalTiming
    let status: RivalInviteStatus
    let sentAt: Date
    let respondedAt: Date?
}

// MARK: - Onboarding State

struct RivalInviteOnboardingState {
    static let hasSeenOnboardingKey = "RivalInvite_HasSeenOnboarding"
    
    static var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }
    
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: hasSeenOnboardingKey)
    }
}
