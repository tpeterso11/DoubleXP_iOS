//
//  YouTubeModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// MARK: - YouTube Video Model

struct YouTubeVideo: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let channelTitle: String
    let publishedAt: Date
    let duration: String?
    let viewCount: Int?
    let likeCount: Int?
    
    // App-specific properties (not from API)
    var isHighlight: Bool = false
    var isShowcase: Bool = false
    var addedToProfileAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, thumbnailURL, channelTitle, publishedAt
        case duration, viewCount, likeCount
        case isHighlight, isShowcase, addedToProfileAt
    }
    
    // Formatted duration (e.g., "PT4M13S" -> "4:13")
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        return Self.formatISO8601Duration(duration)
    }
    
    // Formatted view count (e.g., "12400" -> "12.4K")
    var formattedViewCount: String {
        guard let count = viewCount else { return "" }
        return Self.formatCount(count)
    }
    
    // Formatted date (e.g., "3 days ago")
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
    
    // MARK: - Formatters
    
    static func formatISO8601Duration(_ duration: String) -> String {
        // Parse ISO 8601 duration (e.g., "PT4M13S", "PT1H2M3S")
        var result = duration
            .replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: ":")
            .replacingOccurrences(of: "M", with: ":")
            .replacingOccurrences(of: "S", with: "")
        
        let components = result.split(separator: ":")
        
        switch components.count {
        case 1: // Only seconds
            let seconds = Int(components[0]) ?? 0
            return String(format: "0:%02d", seconds)
        case 2: // Minutes:Seconds
            let minutes = Int(components[0]) ?? 0
            let seconds = Int(components[1]) ?? 0
            return String(format: "%d:%02d", minutes, seconds)
        case 3: // Hours:Minutes:Seconds
            let hours = Int(components[0]) ?? 0
            let minutes = Int(components[1]) ?? 0
            let seconds = Int(components[2]) ?? 0
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        default:
            return duration
        }
    }
    
    static func formatCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK", thousands).replacingOccurrences(of: ".0K", with: "K")
        case 1_000_000..<1_000_000_000:
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM", millions).replacingOccurrences(of: ".0M", with: "M")
        default:
            let billions = Double(count) / 1_000_000_000.0
            return String(format: "%.1fB", billions).replacingOccurrences(of: ".0B", with: "B")
        }
    }
}

// MARK: - YouTube Channel Model

struct YouTubeChannel: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let uploadsPlaylistId: String?
    let subscriberCount: Int?
    let videoCount: Int?
}

// MARK: - User Video Settings (stored in Firebase)

struct UserVideoSettings: Codable {
    var highlightVideoId: String?
    var showcaseVideoIds: [String]
    var isPrivate: Bool
    var lastUpdated: Date
    
    init() {
        self.highlightVideoId = nil
        self.showcaseVideoIds = []
        self.isPrivate = false
        self.lastUpdated = Date()
    }
    
    static let maxShowcaseVideos = 6
}

// MARK: - API Response Models

struct YouTubeChannelListResponse: Codable {
    let kind: String
    let etag: String
    let items: [YouTubeChannelItem]?
    let pageInfo: PageInfo?
    
    struct YouTubeChannelItem: Codable {
        let kind: String
        let etag: String
        let id: String
        let snippet: ChannelSnippet?
        let contentDetails: ChannelContentDetails?
        let statistics: ChannelStatistics?
    }
    
    struct ChannelSnippet: Codable {
        let title: String?
        let description: String?
        let thumbnails: Thumbnails?
    }
    
    struct ChannelContentDetails: Codable {
        let relatedPlaylists: RelatedPlaylists?
        
        struct RelatedPlaylists: Codable {
            let uploads: String?
        }
    }
    
    struct ChannelStatistics: Codable {
        let subscriberCount: String?
        let videoCount: String?
    }
}

struct YouTubePlaylistItemsResponse: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let prevPageToken: String?
    let items: [PlaylistItem]?
    let pageInfo: PageInfo?
    
    struct PlaylistItem: Codable {
        let kind: String
        let etag: String
        let id: String
        let snippet: PlaylistItemSnippet?
        let contentDetails: PlaylistItemContentDetails?
    }
    
    struct PlaylistItemSnippet: Codable {
        let publishedAt: String?
        let channelId: String?
        let title: String?
        let description: String?
        let thumbnails: Thumbnails?
        let channelTitle: String?
        let resourceId: ResourceId?
        
        struct ResourceId: Codable {
            let kind: String?
            let videoId: String?
        }
    }
    
    struct PlaylistItemContentDetails: Codable {
        let videoId: String?
        let videoPublishedAt: String?
    }
}

struct YouTubeVideoListResponse: Codable {
    let kind: String
    let etag: String
    let items: [VideoItem]?
    let pageInfo: PageInfo?
    
    struct VideoItem: Codable {
        let kind: String
        let etag: String
        let id: String
        let snippet: VideoSnippet?
        let contentDetails: VideoContentDetails?
        let statistics: VideoStatistics?
    }
    
    struct VideoSnippet: Codable {
        let publishedAt: String?
        let channelId: String?
        let title: String?
        let description: String?
        let thumbnails: Thumbnails?
        let channelTitle: String?
        let tags: [String]?
        let categoryId: String?
    }
    
    struct VideoContentDetails: Codable {
        let duration: String?
        let dimension: String?
        let definition: String?
        let caption: String?
    }
    
    struct VideoStatistics: Codable {
        let viewCount: String?
        let likeCount: String?
        let commentCount: String?
    }
}

// MARK: - Shared Response Components

struct Thumbnails: Codable {
    let `default`: ThumbnailInfo?
    let medium: ThumbnailInfo?
    let high: ThumbnailInfo?
    let standard: ThumbnailInfo?
    let maxres: ThumbnailInfo?
    
    var bestURL: String? {
        maxres?.url ?? high?.url ?? medium?.url ?? `default`?.url
    }
    
    struct ThumbnailInfo: Codable {
        let url: String?
        let width: Int?
        let height: Int?
    }
}

struct PageInfo: Codable {
    let totalResults: Int?
    let resultsPerPage: Int?
}

// MARK: - OAuth Token Response

struct GoogleTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let scope: String?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
        case refreshToken = "refresh_token"
    }
}

// MARK: - Error Types

enum YouTubeAPIError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case tokenRefreshFailed
    case invalidResponse
    case networkError(Error)
    case apiError(code: Int, message: String)
    case noVideosFound
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to Google"
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication. Please sign in again."
        case .invalidResponse:
            return "Invalid response from YouTube"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(_, let message):
            return message
        case .noVideosFound:
            return "No videos found on this channel"
        case .quotaExceeded:
            return "API quota exceeded. Please try again later."
        }
    }
}

// MARK: - Connection State

enum GoogleConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(email: String)
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

















































































