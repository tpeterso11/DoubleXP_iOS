//
//  CommunityFeedViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import SwiftUI
import FirebaseDatabase

// MARK: - Community Feed ViewModel

@MainActor
class CommunityFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Game info
    let game: GamerConnectGame
    
    // Tab & Filter
    @Published var selectedTab: CommunityFeedTab = .feed
    @Published var selectedFilter: CommunityContentFilter = .all
    
    // Loading states
    @Published var isLoading: Bool = true
    @Published var isLoadingMore: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var error: String?
    
    // Membership
    @Published var isMember: Bool = false
    @Published var isJoining: Bool = false
    
    // Stats
    @Published var stats: CommunityStats?
    
    // Content
    @Published var featuredStream: TwitchStream?
    @Published var otherStreams: [TwitchStream] = []
    @Published var articles: [CommunityArticle] = []
    @Published var shorts: [CommunityShort] = []
    @Published var videos: [CommunityVideo] = []
    @Published var redditPosts: [RedditPost] = []
    @Published var userPosts: [CommunityUserPost] = []
    @Published var members: [CommunityMember] = []
    
    // Pagination
    private var membersLastKey: String?
    private var userPostsLastTimestamp: Double?
    private var hasMoreMembers: Bool = true
    private var hasMorePosts: Bool = true
    
    // Listeners
    private var userPostsHandle: DatabaseHandle?
    
    // Services
    private let service = CommunityFeedService.shared
    private let reactions = ReactionsManager.shared
    
    // MARK: - Computed Properties
    
    var filteredFeedItems: [AnyFeedItem] {
        var items: [AnyFeedItem] = []
        
        switch selectedFilter {
        case .all:
            // Mix all content types
            items.append(contentsOf: redditPosts.map { AnyFeedItem.reddit($0) })
            items.append(contentsOf: userPosts.map { AnyFeedItem.userPost($0) })
            items.append(contentsOf: videos.prefix(5).map { AnyFeedItem.video($0) })
        case .twitter:
            // We don't have Twitter yet, show empty
            break
        case .reddit:
            items = redditPosts.map { AnyFeedItem.reddit($0) }
        case .youtube:
            items = videos.map { AnyFeedItem.video($0) }
        case .community:
            items = userPosts.map { AnyFeedItem.userPost($0) }
        }
        
        return items
    }
    
    var hasContent: Bool {
        switch selectedTab {
        case .feed:
            return !filteredFeedItems.isEmpty
        case .shorts:
            return !shorts.isEmpty
        case .news:
            return !articles.isEmpty
        case .members:
            return !members.isEmpty
        }
    }
    
    // MARK: - Init
    
    init(game: GamerConnectGame) {
        self.game = game
    }
    
    deinit {
        if let handle = userPostsHandle {
            service.removeListener(handle: handle, gameId: game.id)
        }
    }
    
    // MARK: - Load Data
    
    func loadInitialData() async {
        //guard !isLoading || error != nil else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Load membership status
            isMember = await service.checkMembership(gameId: game.id)
            
            // Load stats
            stats = try await service.fetchCommunityStats(gameId: game.id)
            
            // Load API data
            let response = try await service.fetchCommunityFeed(
                gameName: game.gameName,
                mode: "normal"
            )
            
            featuredStream = response.featuredStream
            otherStreams = response.otherStreams ?? []
            articles = response.articles ?? []
            shorts = response.shorts ?? []
            videos = response.videos ?? []
            redditPosts = response.redditPosts ?? []
            
            // Load user posts
            let (posts, lastTimestamp) = try await service.fetchUserPosts(
                gameId: game.id,
                limit: 20
            )
            userPosts = posts
            userPostsLastTimestamp = lastTimestamp
            hasMorePosts = lastTimestamp != nil
            
            // Load initial members
            let (fetchedMembers, lastKey) = try await service.fetchCommunityMembers(
                gameId: game.id,
                limit: 50
            )
            members = fetchedMembers
            membersLastKey = lastKey
            hasMoreMembers = lastKey != nil
            
            isLoading = false
            
            // Start real-time listener for user posts
            startUserPostsListener()
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func refresh() async {
        isRefreshing = true
        
        // Reset pagination
        membersLastKey = nil
        userPostsLastTimestamp = nil
        hasMoreMembers = true
        hasMorePosts = true
        
        do {
            // Reload stats
            stats = try await service.fetchCommunityStats(gameId: game.id)
            
            // Reload API data
            let response = try await service.fetchCommunityFeed(
                gameName: game.gameName,
                mode: "normal"
            )
            
            featuredStream = response.featuredStream
            otherStreams = response.otherStreams ?? []
            articles = response.articles ?? []
            shorts = response.shorts ?? []
            videos = response.videos ?? []
            redditPosts = response.redditPosts ?? []
            
            // Reload user posts
            let (posts, lastTimestamp) = try await service.fetchUserPosts(
                gameId: game.id,
                limit: 20
            )
            userPosts = posts
            userPostsLastTimestamp = lastTimestamp
            hasMorePosts = lastTimestamp != nil
            
            // Reload members
            let (fetchedMembers, lastKey) = try await service.fetchCommunityMembers(
                gameId: game.id,
                limit: 50
            )
            members = fetchedMembers
            membersLastKey = lastKey
            hasMoreMembers = lastKey != nil
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    // MARK: - Pagination
    
    func loadMoreMembers() async {
        guard !isLoadingMore && hasMoreMembers else { return }
        
        isLoadingMore = true
        
        do {
            let (fetchedMembers, lastKey) = try await service.fetchCommunityMembers(
                gameId: game.id,
                limit: 50,
                lastKey: membersLastKey
            )
            
            members.append(contentsOf: fetchedMembers)
            membersLastKey = lastKey
            hasMoreMembers = lastKey != nil
            
        } catch {
            print("Error loading more members: \(error)")
        }
        
        isLoadingMore = false
    }
    
    func loadMoreUserPosts() async {
        guard !isLoadingMore && hasMorePosts else { return }
        
        isLoadingMore = true
        
        do {
            let (posts, lastTimestamp) = try await service.fetchUserPosts(
                gameId: game.id,
                limit: 20,
                lastTimestamp: userPostsLastTimestamp
            )
            
            userPosts.append(contentsOf: posts)
            userPostsLastTimestamp = lastTimestamp
            hasMorePosts = lastTimestamp != nil
            
        } catch {
            print("Error loading more posts: \(error)")
        }
        
        isLoadingMore = false
    }
    
    // MARK: - Real-time Listener
    
    private func startUserPostsListener() {
        userPostsHandle = service.listenToUserPosts(
            gameId: game.id,
            limit: 20
        ) { [weak self] posts in
            Task { @MainActor in
                self?.userPosts = posts
            }
        }
    }
    
    // MARK: - Membership
    
    func toggleMembership() async {
        guard !isJoining else { return }
        
        isJoining = true
        
        do {
            if isMember {
                try await service.leaveCommunity(gameId: game.slug)
                isMember = false
                
                // Update local stats
                if var currentStats = stats {
                    stats = CommunityStats(
                        memberCount: max(0, currentStats.memberCount - 1),
                        onlineCount: currentStats.onlineCount,
                        postsToday: currentStats.postsToday,
                        trendingRank: currentStats.trendingRank
                    )
                }
            } else {
                try await service.joinCommunity(gameId: game.slug)
                isMember = true
                
                // Update local stats
                if var currentStats = stats {
                    stats = CommunityStats(
                        memberCount: currentStats.memberCount + 1,
                        onlineCount: currentStats.onlineCount,
                        postsToday: currentStats.postsToday,
                        trendingRank: currentStats.trendingRank
                    )
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isJoining = false
    }
    
    // MARK: - Reactions
    
    func toggleLikeForPost(_ post: CommunityUserPost) {
        reactions.toggleLike(type: .post, id: post.id)
        
        // Update local state
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            let isNowLiked = reactions.viewStateForMedia(type: .post, id: post.id).isLiked
            userPosts[index].likeCount += isNowLiked ? 1 : -1
        }
    }
    
    func isPostLiked(_ post: CommunityUserPost) -> Bool {
        reactions.viewStateForMedia(type: .post, id: post.id).isLiked
    }
    
    func toggleLikeForReddit(_ post: RedditPost) {
        reactions.toggleLike(type: .post, id: "reddit_\(post.id)")
    }
    
    func isRedditLiked(_ post: RedditPost) -> Bool {
        reactions.viewStateForMedia(type: .post, id: "reddit_\(post.id)").isLiked
    }
    
    func toggleLikeForArticle(_ article: CommunityArticle) {
        reactions.toggleLikeForArticle(articleID: article.id)
    }
    
    func isArticleLiked(_ article: CommunityArticle) -> Bool {
        reactions.viewStateForArticle(id: article.id).isLiked
    }
    
    // MARK: - Create Post
    
    func createPost(text: String, imageUrl: String? = nil) async throws {
        try await service.createUserPost(
            gameId: game.id,
            gameName: game.gameName,
            text: text,
            imageUrl: imageUrl
        )
    }
}

// MARK: - Feed Item Wrapper

enum AnyFeedItem: Identifiable {
    case reddit(RedditPost)
    case userPost(CommunityUserPost)
    case video(CommunityVideo)
    case article(CommunityArticle)
    
    var id: String {
        switch self {
        case .reddit(let post): return "reddit_\(post.id)"
        case .userPost(let post): return "user_\(post.id)"
        case .video(let video): return "video_\(video.id)"
        case .article(let article): return "article_\(article.id)"
        }
    }
}
