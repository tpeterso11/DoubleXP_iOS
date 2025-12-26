//
//  CommunityStructs.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

// MARK: - Community Feed Models

/// Main response from /v1/community-feed endpoint
struct CommunityFeedResponse: Codable {
    let featuredStream: TwitchStream?
    let otherStreams: [TwitchStream]?
    let articles: [CommunityArticle]?
    let shorts: [CommunityShort]?
    let videos: [CommunityVideo]?
    let redditPosts: [RedditPost]?
}

// MARK: - Twitch Stream

struct TwitchStream: Codable, Identifiable {
    let id: String?
    let title: String?
    let viewerCount: Int?
    let thumbnailUrl: String?
    let language: String?
    let startedAt: String?
    let channelName: String?   // from backend: channelName

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case viewerCount   = "viewer_count"
        case thumbnailUrl  = "thumbnail_url"
        case language
        case startedAt     = "started_at"
        case channelName
    }
    
    /// Get properly sized thumbnail URL
    func thumbnailURL(width: Int = 440, height: Int = 248) -> URL? {
        let urlString = thumbnailUrl ?? ""
            .replacingOccurrences(of: "{width}", with: "\(width)")
            .replacingOccurrences(of: "{height}", with: "\(height)")
        return URL(string: urlString)
    }
}

// MARK: - Community Article

struct CommunityArticle: Codable, Identifiable {
    let id: String
    let title: String
    let summary: String?
    let source: String
    let sourceUrl: String?
    let imageUrl: String?
    let publishedAt: String?
    let author: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case source
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case publishedAt = "published_at"
        case author
    }
    
    var imageURL: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    var relativeTime: String {
        guard let dateString = publishedAt else { return "" }
        // Parse and format relative time
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let relFormatter = RelativeDateTimeFormatter()
            relFormatter.unitsStyle = .abbreviated
            return relFormatter.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}

// MARK: - Community Short (YouTube Shorts)

struct CommunityShort: Codable, Identifiable {
    let videoId: String
    let title: String
    let channelTitle: String
    let thumbnailUrl: String?
    
    var id: String { videoId }
    
    var thumbnailURL: URL? {
        guard let urlString = thumbnailUrl else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Community Video (YouTube)

struct CommunityVideo: Codable, Identifiable {
    let videoId: String
    let title: String
    let channelTitle: String
    let thumbnailUrl: String?
    let durationSeconds: Int?
    let viewCount: Int?
    
    var id: String { videoId }
    
    var thumbnailURL: URL? {
        guard let urlString = thumbnailUrl else { return nil }
        return URL(string: urlString)
    }
    
    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    var formattedViewCount: String {
        guard let count = viewCount else { return "" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Reddit Post

struct RedditPost: Codable, Identifiable {
    let id: String
    let title: String
    let selftext: String?
    let author: String
    let subreddit: String
    let score: Int
    let numComments: Int
    let permalink: String
    let thumbnail: String?
    let createdUtc: Double?
    let url: String?
    let isVideo: Bool?
    let preview: RedditPreview?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case selftext
        case author
        case subreddit
        case score
        case numComments = "num_comments"
        case permalink
        case thumbnail
        case createdUtc = "created_utc"
        case url
        case isVideo = "is_video"
        case preview
    }
    
    // MARK: - Memberwise-style init (for mocks / manual construction)
    init(
        id: String,
        title: String,
        selftext: String?,
        author: String,
        subreddit: String,
        score: Int,
        numComments: Int,
        permalink: String,
        thumbnail: String?,
        createdUtc: Double?,
        url: String?,
        isVideo: Bool?,
        preview: RedditPreview?
    ) {
        self.id = id
        self.title = title
        self.selftext = selftext
        self.author = author
        self.subreddit = subreddit
        self.score = score
        self.numComments = numComments
        self.permalink = permalink
        self.thumbnail = thumbnail
        self.createdUtc = createdUtc
        self.url = url
        self.isVideo = isVideo
        self.preview = preview
    }
    
    // MARK: - Custom Decodable (to synthesize id + make fields optional-safe)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try real id; if missing, fall back to permalink as a stable key
        let rawId = try container.decodeIfPresent(String.self, forKey: .id)
        let permalink = try container.decodeIfPresent(String.self, forKey: .permalink) ?? ""
        self.id = rawId ?? permalink
        
        self.title      = try container.decode(String.self, forKey: .title)
        self.selftext   = try container.decodeIfPresent(String.self, forKey: .selftext)
        self.author     = try container.decode(String.self, forKey: .author)
        self.subreddit  = try container.decode(String.self, forKey: .subreddit)
        self.score      = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        self.numComments = try container.decodeIfPresent(Int.self, forKey: .numComments) ?? 0
        self.permalink  = permalink
        self.thumbnail  = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        self.createdUtc = try container.decodeIfPresent(Double.self, forKey: .createdUtc)
        self.url        = try container.decodeIfPresent(String.self, forKey: .url)
        self.isVideo    = try container.decodeIfPresent(Bool.self, forKey: .isVideo)
        self.preview    = try container.decodeIfPresent(RedditPreview.self, forKey: .preview)
    }
    
    // MARK: - Encodable (because we customized Decodable but still conform to Codable)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(selftext, forKey: .selftext)
        try container.encode(author, forKey: .author)
        try container.encode(subreddit, forKey: .subreddit)
        try container.encode(score, forKey: .score)
        try container.encode(numComments, forKey: .numComments)
        try container.encode(permalink, forKey: .permalink)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(createdUtc, forKey: .createdUtc)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(isVideo, forKey: .isVideo)
        try container.encodeIfPresent(preview, forKey: .preview)
    }
    
    // MARK: - Computed helpers (unchanged)
    
    var formattedScore: String {
        if score >= 1000 {
            return String(format: "%.1fk", Double(score) / 1000)
        }
        return "\(score)"
    }
    
    var relativeTime: String {
        guard let timestamp = createdUtc else { return "" }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var previewImageURL: URL? {
        if let images = preview?.images, let first = images.first {
            let urlString = first.source.url.replacingOccurrences(of: "&amp;", with: "&")
            return URL(string: urlString)
        }
        if let thumb = thumbnail, thumb.hasPrefix("http") {
            return URL(string: thumb)
        }
        return nil
    }
}

struct RedditPreview: Codable {
    let images: [RedditPreviewImage]?
}

struct RedditPreviewImage: Codable {
    let source: RedditImageSource
}

struct RedditImageSource: Codable {
    let url: String
    let width: Int
    let height: Int
}

// MARK: - Community Member (for Members tab)

struct CommunityMember: Identifiable, Codable {
    let id: String
    let oderId: String
    let screenName: String
    let pokoHeadshotUrl: String?
    let games: [String]
    let isOnline: Bool
    let lastActive: Double?
    
    var avatarURL: URL? {
        guard let urlString = pokoHeadshotUrl else { return nil }
        return URL(string: urlString)
    }
    
    var relativeLastActive: String {
        guard let timestamp = lastActive else { return "Active recently" }
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Active \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - User Post (Community posts from our users)

struct CommunityUserPost: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let gameId: String
    let gameName: String
    let text: String
    let imageUrl: String?
    let timestamp: Double
    var likeCount: Int
    var commentCount: Int
    
    var avatarURL: URL? {
        guard let urlString = userAvatar else { return nil }
        return URL(string: urlString)
    }
    
    var imageURL: URL? {
        guard let urlString = imageUrl else { return nil }
        return URL(string: urlString)
    }
    
    var relativeTime: String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Community Stats

struct CommunityStats: Codable {
    let memberCount: Int
    let onlineCount: Int
    let postsToday: Int
    let trendingRank: Int?
    
    var formattedMemberCount: String {
        formatCount(memberCount)
    }
    
    var formattedOnlineCount: String {
        formatCount(onlineCount)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Feed Tab Type

enum CommunityFeedTab: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case shorts = "Shorts"
    case news = "News"
    case members = "Members"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .feed: return "flame.fill"
        case .shorts: return "play.rectangle.fill"
        case .news: return "newspaper.fill"
        case .members: return "person.2.fill"
        }
    }
}

// MARK: - Content Filter

enum CommunityContentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case twitter = "Twitter"
    case reddit = "Reddit"
    case youtube = "YouTube"
    case community = "Community"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "🔥"
        case .twitter: return "🐦"
        case .reddit: return "🔴"
        case .youtube: return "▶️"
        case .community: return "👥"
        }
    }
}
