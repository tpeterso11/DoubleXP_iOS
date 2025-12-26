//
//  CommunityPageView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Main Community Page View

struct CommunityPageView: View {
    @StateObject private var viewModel: CommunityFeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showComposeSheet: Bool = false
    @State private var scrollOffset: CGFloat = 0
    
    @Namespace private var namespace
    
    init(game: GamerConnectGame) {
        _viewModel = StateObject(wrappedValue: CommunityFeedViewModel(game: game))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0a0a0f")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                CommunityLoadingView()
            } else if let error = viewModel.error {
                CommunityErrorView(error: error) {
                    Task { await viewModel.loadInitialData() }
                }
            } else {
                mainContent
            }
            
            // Floating Compose Button (for Feed tab, not for news/members)
            if !viewModel.isLoading && viewModel.error == nil {
                if viewModel.selectedTab == .feed || viewModel.selectedTab == .shorts {
                    floatingComposeButton
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadInitialData()
        }
        .sheet(isPresented: $showComposeSheet) {
            CommunityComposeView(viewModel: viewModel)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            communityHeader
            
            // Tabs
            tabBar
            
            // Tab Content
            TabView(selection: $viewModel.selectedTab) {
                feedTab
                    .tag(CommunityFeedTab.feed)
                
                shortsTab
                    .tag(CommunityFeedTab.shorts)
                
                newsTab
                    .tag(CommunityFeedTab.news)
                
                membersTab
                    .tag(CommunityFeedTab.members)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Header
    
    private var communityHeader: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "FF6B6B").opacity(0.2),
                    Color(hex: "9333EA").opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                
                // Game info
                HStack(spacing: 14) {
                    // Game icon
                    if let url = viewModel.game.bestImageURL {
                        CachedAsyncImageView(url: url)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("🎮")
                                    .font(.system(size: 32))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.game.gameName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            if let stats = viewModel.stats {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: "4ADE80"))
                                        .frame(width: 6, height: 6)
                                    Text("\(stats.formattedOnlineCount) online")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "4ADE80"))
                                }
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("\(stats.formattedMemberCount) members")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Action buttons
                HStack(spacing: 10) {
                    // Join button
                    Button(action: {
                        Task { await viewModel.toggleMembership() }
                    }) {
                        HStack(spacing: 6) {
                            if viewModel.isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: viewModel.isMember ? "checkmark" : "plus")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(viewModel.isMember ? "Joined" : "Join")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if viewModel.isMember {
                                Color.white.opacity(0.15)
                            } else {
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.isMember ? Color.white.opacity(0.2) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .disabled(viewModel.isJoining)
                    
                    // Notify button
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Share button
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(CommunityFeedTab.allCases) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                            
                            // Badge for shorts
                            if tab == .shorts && !viewModel.shorts.isEmpty {
                                Text("\(viewModel.shorts.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "FF6B6B"))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(viewModel.selectedTab == tab ? .white : .white.opacity(0.5))
                        
                        // Indicator
                        Rectangle()
                            .fill(
                                viewModel.selectedTab == tab
                                    ? LinearGradient(
                                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(hex: "0a0a0f"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Feed Tab
    
    private var feedTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Stats row
                if let stats = viewModel.stats {
                    statsRow(stats: stats)
                }
                
                // Filter pills
                filterPills
                
                // Featured stream
                if let stream = viewModel.featuredStream {
                    featuredStreamCard(stream: stream)
                }
                
                // Feed content
                if viewModel.filteredFeedItems.isEmpty {
                    CommunityEmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No posts yet",
                        subtitle: "Be the first to start a conversation!",
                        actionTitle: "Create Post",
                        action: { showComposeSheet = true }
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.filteredFeedItems) { item in
                        feedItemView(item: item)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                    
                    // Load more trigger
                    if viewModel.selectedFilter == .community {
                        loadMoreTrigger {
                            Task { await viewModel.loadMoreUserPosts() }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Shorts Tab
    
    private var shortsTab: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.shorts.isEmpty {
                CommunityEmptyStateView(
                    icon: "play.rectangle.fill",
                    title: "No shorts yet",
                    subtitle: "Share your best gaming moments!",
                    actionTitle: "Upload Short",
                    action: { showComposeSheet = true }
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(viewModel.shorts) { short in
                        CommunityShortCard(short: short)
                    }
                }
                .padding(16)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - News Tab
    
    private var newsTab: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.articles.isEmpty {
                CommunityEmptyStateView(
                    icon: "newspaper",
                    title: "No news available",
                    subtitle: "Check back later for updates",
                    actionTitle: nil,
                    action: nil
                )
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.articles) { article in
                        CommunityArticleCard(
                            article: article,
                            isLiked: viewModel.isArticleLiked(article),
                            onLike: { viewModel.toggleLikeForArticle(article) }
                        )
                    }
                }
                .padding(16)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Members Tab
    
    private var membersTab: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.members.isEmpty {
                CommunityEmptyStateView(
                    icon: "person.2",
                    title: "No members yet",
                    subtitle: "Be the first to join this community!",
                    actionTitle: nil,
                    action: nil
                )
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 0) {
                    // Online now section
                    let onlineMembers = viewModel.members.filter { $0.isOnline }
                    if !onlineMembers.isEmpty {
                        sectionHeader(title: "Online Now", count: onlineMembers.count)
                        
                        ForEach(onlineMembers) { member in
                            CommunityMemberRow(member: member)
                        }
                    }
                    
                    // All members
                    sectionHeader(title: "All Members", count: viewModel.members.count)
                    
                    ForEach(viewModel.members) { member in
                        CommunityMemberRow(member: member)
                            .onAppear {
                                // Load more when reaching end
                                if member.id == viewModel.members.last?.id {
                                    Task { await viewModel.loadMoreMembers() }
                                }
                            }
                    }
                    
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Helper Views
    
    private func statsRow(stats: CommunityStats) -> some View {
        HStack(spacing: 8) {
            statChip(value: "\(stats.postsToday)", label: "Posts Today")
            statChip(value: stats.formattedOnlineCount, label: "Active Now")
            if let rank = stats.trendingRank {
                statChip(value: "#\(rank)", label: "Trending")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CommunityContentFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(filter.icon)
                                .font(.system(size: 12))
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedFilter == filter
                                ? LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.06)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    viewModel.selectedFilter == filter
                                        ? Color.clear
                                        : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func featuredStreamCard(stream: TwitchStream) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            featuredStreamThumbnail(stream: stream)
            featuredStreamInfoRow(stream: stream)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Thumbnail + Overlays

    private func featuredStreamThumbnail(stream: TwitchStream) -> some View {
        ZStack {
            featuredStreamImage(stream: stream)

            // Center play button
            playOverlay

            // LIVE badge (top-left)
            liveBadge
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Viewer count (bottom-right)
            viewerCountBadge(viewers: stream.viewerCount ?? 0)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private func featuredStreamImage(stream: TwitchStream) -> some View {
        Group {
            if let url = stream.thumbnailURL() {
                CachedAsyncImageView(url: url)
                    .transition(.opacity)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1a1a2e"))
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Overlays

    private var playOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 56, height: 56)

            Image(systemName: "play.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .offset(x: 1) // tiny nudge to visually center the play triangle
        }
    }

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.9))
        .clipShape(Capsule())
    }

    private func viewerCountBadge(viewers: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.system(size: 10))
            Text(viewers.formatted())
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }

    private func featuredStreamInfoRow(stream: TwitchStream) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: "9333EA"))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("📺")
                        .font(.system(size: 16))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("")   // or stream.userDisplayName if you keep it
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(stream.title ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Text("Watch")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "9333EA"))
        }
    }
    
    @ViewBuilder
    private func feedItemView(item: AnyFeedItem) -> some View {
        switch item {
        case .reddit(let post):
            CommunityRedditCard(
                post: post,
                isLiked: viewModel.isRedditLiked(post),
                onLike: { viewModel.toggleLikeForReddit(post) }
            )
        case .userPost(let post):
            CommunityUserPostCard(
                post: post,
                isLiked: viewModel.isPostLiked(post),
                onLike: { viewModel.toggleLikeForPost(post) }
            )
        case .video(let video):
            CommunityVideoCard(video: video)
        case .article(let article):
            CommunityArticleCard(
                article: article,
                isLiked: viewModel.isArticleLiked(article),
                onLike: { viewModel.toggleLikeForArticle(article) }
            )
        }
    }
    
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 12)
    }
    
    private func loadMoreTrigger(action: @escaping () -> Void) -> some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).maxY)
        }
        .frame(height: 1)
        .onAppear {
            action()
        }
    }
    
    // MARK: - Floating Compose Button
    
    private var floatingComposeButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showComposeSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "FF6B6B").opacity(0.4), radius: 16, y: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
