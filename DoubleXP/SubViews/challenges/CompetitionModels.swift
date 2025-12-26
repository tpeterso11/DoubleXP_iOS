//
//  CompetitionModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

// MARK: - Competition Model

struct Competition: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let extendedDescription: String
    let rules: [String]
    let type: CompetitionType
    let tier: CompetitionTier
    let xpReward: Int
    let maxAttempts: Int
    let imageUrl: String
    let gameSlug: String? // Optional - if set, only users with this game can see it
    let startsAt: TimeInterval
    let endsAt: TimeInterval
    let createdAt: TimeInterval
    let isActive: Bool
    let submissionType: SubmissionType
    let totalEntries: Int
    let sponsorName: String? // For sponsored competitions
    let sponsorLogoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case extendedDescription = "extended_description"
        case rules
        case type
        case tier
        case xpReward = "xp_reward"
        case maxAttempts = "max_attempts"
        case imageUrl = "image_url"
        case gameSlug = "game_slug"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case createdAt = "created_at"
        case isActive = "is_active"
        case submissionType = "submission_type"
        case totalEntries = "total_entries"
        case sponsorName = "sponsor_name"
        case sponsorLogoUrl = "sponsor_logo_url"
    }
    
    // MARK: - Computed Properties
    
    var isExpired: Bool {
        Date().timeIntervalSince1970 > endsAt
    }
    
    var hasStarted: Bool {
        Date().timeIntervalSince1970 >= startsAt
    }
    
    var timeRemaining: String {
        let now = Date().timeIntervalSince1970
        let remaining = endsAt - now
        
        if remaining <= 0 { return "Ended" }
        
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else if hours > 0 {
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m left"
        } else {
            let minutes = Int(remaining / 60)
            return "\(minutes)m left"
        }
    }
    
    var isFeatured: Bool {
        tier == .featured
    }
    
    var isSponsored: Bool {
        tier == .sponsored
    }
}

// MARK: - Competition Type

enum CompetitionType: String, Codable, CaseIterable {
    case photoOp = "photo_op"
    case gameplay = "gameplay"
    case speedrun = "speedrun"
    case exploration = "exploration"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .photoOp: return "Photo Op"
        case .gameplay: return "Gameplay"
        case .speedrun: return "Speedrun"
        case .exploration: return "Exploration"
        case .achievement: return "Achievement"
        }
    }
    
    var icon: String {
        switch self {
        case .photoOp: return "📸"
        case .gameplay: return "🎮"
        case .speedrun: return "⚡"
        case .exploration: return "🗺️"
        case .achievement: return "🏆"
        }
    }
}

// MARK: - Competition Tier

enum CompetitionTier: String, Codable {
    case regular = "regular"
    case featured = "featured"
    case sponsored = "sponsored"
}

// MARK: - Submission Type

enum SubmissionType: String, Codable {
    case screenshot = "screenshot"
    case video = "video"
    case youtubeUrl = "youtube_url"
    case either = "either" // Screenshot or video
    
    var displayName: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .video: return "Video"
        case .youtubeUrl: return "YouTube Link"
        case .either: return "Screenshot or Video"
        }
    }
}

// MARK: - Competition Entry

struct CompetitionEntry: Identifiable, Codable {
    let id: String
    let competitionId: String
    let userId: String
    let attemptNumber: Int
    let submissionUrl: String
    let submissionType: SubmissionType
    let caption: String?
    let status: EntryStatus
    let submittedAt: TimeInterval
    let reviewedAt: TimeInterval?
    let reviewedBy: String?
    let xpAwarded: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case competitionId = "competition_id"
        case userId = "user_id"
        case attemptNumber = "attempt_number"
        case submissionUrl = "submission_url"
        case submissionType = "submission_type"
        case caption
        case status
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case xpAwarded = "xp_awarded"
    }
}

// MARK: - Entry Status

enum EntryStatus: String, Codable {
    case pending = "pending"
    case underReview = "under_review"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "FFD700" // Yellow/Gold
        case .underReview: return "00D2FF" // Cyan
        case .approved: return "4ADE80" // Green
        case .rejected: return "FF6B6B" // Red
        }
    }
}

// MARK: - User Competition Summary

/// Quick summary of a user's participation in a competition
struct UserCompetitionSummary: Codable {
    let competitionId: String
    let userId: String
    let attemptsUsed: Int
    let latestEntryId: String?
    let latestStatus: EntryStatus?
    let hasWon: Bool
    
    var attemptsRemaining: Int {
        max(0, 3 - attemptsUsed) // Max 3 attempts
    }
    
    var canSubmit: Bool {
        attemptsRemaining > 0 && !hasWon
    }
}
