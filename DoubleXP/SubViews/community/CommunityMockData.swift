//
//  CommunityMockData.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// MARK: - Mock Data Provider for Community Feed

struct CommunityMockData {
    
    // MARK: - Mock Stats
    
    static let mockStats = CommunityStats(
        memberCount: 28456,
        onlineCount: 3241,
        postsToday: 847,
        trendingRank: 3
    )
    
    // MARK: - Mock Twitch Stream
    
    
    
    // MARK: - Mock Articles
    
    static let mockArticles: [CommunityArticle] = [
        CommunityArticle(
            id: "article_001",
            title: "Valorant Episode 8 Act 2: Everything You Need to Know About the New Agent",
            summary: "The latest Valorant update brings a new controller agent that's shaking up the meta...",
            source: "IGN",
            sourceUrl: "https://ign.com/article/valorant-ep8-act2",
            imageUrl: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 3).ISO8601Format(),
            author: "John Smith"
        ),
        CommunityArticle(
            id: "article_002",
            title: "Pro Player Reveals Game-Changing Smoke Lineups for Pearl",
            summary: nil,
            source: "Kotaku",
            sourceUrl: nil,
            imageUrl: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 6).ISO8601Format(),
            author: nil
        ),
        CommunityArticle(
            id: "article_003",
            title: "VCT Champions 2024: Teams to Watch",
            summary: "With VCT Champions approaching, we break down the top contenders...",
            source: "The Verge",
            sourceUrl: nil,
            imageUrl: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 12).ISO8601Format(),
            author: "Jane Doe"
        ),
        CommunityArticle(
            id: "article_004",
            title: "Riot Games Announces Major Ranked System Overhaul",
            summary: nil,
            source: "GameSpot",
            sourceUrl: nil,
            imageUrl: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 24).ISO8601Format(),
            author: nil
        )
    ]
    
    // MARK: - Mock Shorts
    
    static let mockShorts: [CommunityShort] = [
        CommunityShort(videoId: "short_001", title: "INSANE 1v5 ACE 🔥", channelTitle: "AceuClips", thumbnailUrl: nil),
        CommunityShort(videoId: "short_002", title: "This smoke is BROKEN", channelTitle: "ProTips", thumbnailUrl: nil),
        CommunityShort(videoId: "short_003", title: "When the timing is perfect", channelTitle: "ValorantMemes", thumbnailUrl: nil),
        CommunityShort(videoId: "short_004", title: "New agent ability showcase", channelTitle: "GameLeaks", thumbnailUrl: nil),
        CommunityShort(videoId: "short_005", title: "Silver vs Radiant aim", channelTitle: "RankComparisons", thumbnailUrl: nil),
        CommunityShort(videoId: "short_006", title: "The luckiest wallbang ever", channelTitle: "ClipCentral", thumbnailUrl: nil),
        CommunityShort(videoId: "short_007", title: "POV: You're in Iron", channelTitle: "ValorantMemes", thumbnailUrl: nil),
        CommunityShort(videoId: "short_008", title: "Pro movement guide", channelTitle: "CoachJ", thumbnailUrl: nil),
        CommunityShort(videoId: "short_009", title: "When your duo is cracked", channelTitle: "BestPlays", thumbnailUrl: nil)
    ]
    
    // MARK: - Mock Videos
    
    static let mockVideos: [CommunityVideo] = [
        CommunityVideo(
            videoId: "video_001",
            title: "Complete Beginner's Guide to Valorant in 2024",
            channelTitle: "GameGuides",
            thumbnailUrl: nil,
            durationSeconds: 1245,
            viewCount: 2456000
        ),
        CommunityVideo(
            videoId: "video_002",
            title: "How I Hit Radiant in 30 Days (Full Journey)",
            channelTitle: "ClimbingPro",
            thumbnailUrl: nil,
            durationSeconds: 2456,
            viewCount: 892000
        ),
        CommunityVideo(
            videoId: "video_003",
            title: "VCT Champions Grand Finals Highlights",
            channelTitle: "EsportsCenter",
            thumbnailUrl: nil,
            durationSeconds: 987,
            viewCount: 5670000
        ),
        CommunityVideo(
            videoId: "video_004",
            title: "Every Agent Ranked from Worst to Best",
            channelTitle: "TierListGaming",
            thumbnailUrl: nil,
            durationSeconds: 1876,
            viewCount: 1234000
        )
    ]
    
    // MARK: - Mock Reddit Posts
    
    static let mockRedditPosts: [RedditPost] = [
        RedditPost(
                id: "abc123",
                title: "After 2000 hours, I finally hit Immortal. Here's what I learned.",
                selftext: "Started in Iron 2 back in Episode 1. It's been a long journey but I finally made it. AMA!",
                author: "ProGamer2024",
                subreddit: "VALORANT",
                score: 8742,
                numComments: 342,
                permalink: "/r/VALORANT/comments/abc123",
                thumbnail: nil,
                createdUtc: Date().addingTimeInterval(-3600 * 4).timeIntervalSince1970,
                url: nil,
                isVideo: false,
                preview: nil
            ),
            RedditPost(
                id: "def456",
                title: "New agent leak from official trailer frame-by-frame analysis",
                selftext: nil,
                author: "DataMiner99",
                subreddit: "VALORANT",
                score: 15234,
                numComments: 567,
                permalink: "/r/VALORANT/comments/def456",
                thumbnail: nil,
                createdUtc: Date().addingTimeInterval(-3600 * 8).timeIntervalSince1970,
                url: nil,
                isVideo: false,
                preview: nil
            ),
            RedditPost(
                id: "ghi789",
                title: "The ranked system needs a major overhaul - here's why",
                selftext: "I've compiled data from over 500 games to show the issues with the current system...",
                author: "CompetitiveAnalyst",
                subreddit: "VALORANT",
                score: 6123,
                numComments: 892,
                permalink: "/r/VALORANT/comments/ghi789",
                thumbnail: nil,
                createdUtc: Date().addingTimeInterval(-3600 * 12).timeIntervalSince1970,
                url: nil,
                isVideo: false,
                preview: nil
            ),
            RedditPost(
                id: "jkl012",
                title: "Anyone else think the new map is absolutely insane?",
                selftext: "The verticality is crazy! Best map they've released IMO.",
                author: "MapEnjoyer",
                subreddit: "VALORANT",
                score: 4521,
                numComments: 234,
                permalink: "/r/VALORANT/comments/jkl012",
                thumbnail: nil,
                createdUtc: Date().addingTimeInterval(-3600 * 2).timeIntervalSince1970,
                url: nil,
                isVideo: false,
                preview: nil
            )
    ]
    
    // MARK: - Mock User Posts
    
    static let mockUserPosts: [CommunityUserPost] = [
        CommunityUserPost(
            id: "post_001",
            userId: "user_001",
            userName: "ShadowSniper",
            userAvatar: nil,
            gameId: "game_001",
            gameName: "Valorant",
            text: "Anyone else think the new map is absolutely insane? The verticality is crazy! Looking for a duo to grind ranked tonight 🎯",
            imageUrl: nil,
            timestamp: Date().addingTimeInterval(-3600 * 1).timeIntervalSince1970 * 1000,
            likeCount: 127,
            commentCount: 28
        ),
        CommunityUserPost(
            id: "post_002",
            userId: "user_002",
            userName: "NightOwlGamer",
            userAvatar: nil,
            gameId: "game_001",
            gameName: "Valorant",
            text: "Finally hit Diamond after being hardstuck Plat for 3 acts! 🎉 If I can do it, you can too!",
            imageUrl: nil,
            timestamp: Date().addingTimeInterval(-3600 * 3).timeIntervalSince1970 * 1000,
            likeCount: 342,
            commentCount: 67
        ),
        CommunityUserPost(
            id: "post_003",
            userId: "user_003",
            userName: "TacticalMaster",
            userAvatar: nil,
            gameId: "game_001",
            gameName: "Valorant",
            text: "Pro tip: Stop taking fights you don't need to take. Learned this the hard way after watching my VODs. Position > Aim",
            imageUrl: nil,
            timestamp: Date().addingTimeInterval(-3600 * 6).timeIntervalSince1970 * 1000,
            likeCount: 567,
            commentCount: 89
        )
    ]
    
    // MARK: - Mock Members
    
    static let mockMembers: [CommunityMember] = [
        CommunityMember(
            id: "member_001",
            oderId: "order_001",
            screenName: "ProPlayer99",
            pokoHeadshotUrl: nil,
            games: ["valorant", "csgo"],
            isOnline: true,
            lastActive: Date().timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_002",
            oderId: "order_002",
            screenName: "NightGamer",
            pokoHeadshotUrl: nil,
            games: ["valorant"],
            isOnline: true,
            lastActive: Date().timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_003",
            oderId: "order_003",
            screenName: "CasualVibes",
            pokoHeadshotUrl: nil,
            games: ["valorant", "league"],
            isOnline: false,
            lastActive: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_004",
            oderId: "order_004",
            screenName: "CompetitorX",
            pokoHeadshotUrl: nil,
            games: ["valorant"],
            isOnline: true,
            lastActive: Date().timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_005",
            oderId: "order_005",
            screenName: "StreamerLife",
            pokoHeadshotUrl: nil,
            games: ["valorant", "apex"],
            isOnline: false,
            lastActive: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_006",
            oderId: "order_006",
            screenName: "TacticoolPlayer",
            pokoHeadshotUrl: nil,
            games: ["valorant", "r6siege"],
            isOnline: true,
            lastActive: Date().timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_007",
            oderId: "order_007",
            screenName: "AimTrainer",
            pokoHeadshotUrl: nil,
            games: ["valorant"],
            isOnline: false,
            lastActive: Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000
        ),
        CommunityMember(
            id: "member_008",
            oderId: "order_008",
            screenName: "TeamLeader42",
            pokoHeadshotUrl: nil,
            games: ["valorant", "overwatch"],
            isOnline: true,
            lastActive: Date().timeIntervalSince1970 * 1000
        )
    ]
    
    // MARK: - Full Mock Response
    
    static let mockFeedResponse = CommunityFeedResponse(
        featuredStream: nil,
        otherStreams: [],
        articles: mockArticles,
        shorts: mockShorts,
        videos: mockVideos,
        redditPosts: mockRedditPosts
    )
}

// MARK: - Mock Service Extension

extension CommunityFeedService {
    
    /// Use mock data instead of real API calls (for testing)
    func fetchMockCommunityFeed() async -> CommunityFeedResponse {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return CommunityMockData.mockFeedResponse
    }
    
    func fetchMockStats() async -> CommunityStats {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CommunityMockData.mockStats
    }
    
    func fetchMockMembers() async -> [CommunityMember] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CommunityMockData.mockMembers
    }
    
    func fetchMockUserPosts() async -> [CommunityUserPost] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CommunityMockData.mockUserPosts
    }
}
