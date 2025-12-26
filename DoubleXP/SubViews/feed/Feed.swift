//
//  Feed.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI

enum TimeoutError: Error { case timedOut }

enum FeedSection: Int, CaseIterable, Identifiable {
    case forYou
    case news
    case shorts  // easy to add more later

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .forYou:  return "For You"
        case .news:    return "News"
        case .shorts:  return "Shorts"
        }
    }
}

enum FeedLoadState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    
    static func == (lhs: FeedLoadState, rhs: FeedLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct FeedView: View {
    @Environment(\.openURL) private var openURL
    
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var newsService = NewsAPIService.shared
    
    // Active section for swipeable pages
    @State private var activeSection: FeedSection = .forYou
    
    // Parallax tracking
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollOffset: CGFloat? = nil
    
    // Pull/stretch control
    private let headerHeight: CGFloat = 280
    private let maxHeaderStretch: CGFloat = 80
    private let refreshTrigger: CGFloat = 72
    @State private var isRefreshing: Bool = false
    @State private var armedForRefresh: Bool = true
    
    // Section activity tracking
    @State private var loadedSections: Set<FeedSection> = []
    @State private var isForYouActive: Bool = false
    @State private var isNewsActive: Bool = false
    @State private var isShortsActive: Bool = false
    @Binding var isActive: Bool
    
    // Namespace for transitions
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void
    
    // News article selection
    @State private var selectedNewsArticle: Article? = nil
    
    // DEBUG drawer state
    #if DEBUG
    @State private var showDebugDrawer: Bool = false
    @State private var dbgUseMockHeader: Bool = FeedDataManager.shared.useMockData
    @State private var dbgUseMockGames: Bool = DebugSettings.shared.mockGameAPI
    @StateObject private var dbgNet = DebugNetworkController.shared
    #endif
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackgroundColor.ignoresSafeArea()
            
            // Content based on load state
            switch viewModel.loadState {
            case .idle, .loading:
                FeedLoadingSkeletonView()
                    .transition(.opacity)
                    .zIndex(1)
                
            case .error(let message):
                FeedErrorView(
                    message: message,
                    onRetry: {
                        Task {
                            await viewModel.loadInitialData(
                                userGames: UserProvider.shared.currentUser?.games ?? []
                            )
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
                
            case .loaded:
                VStack(spacing: 0) {
                    // Section strip tabs
                    sectionStrip
                    
                    // Horizontally swipeable pages
                    TabView(selection: $activeSection) {
                        forYouPage
                            .tag(FeedSection.forYou)
                        
                        newsPage
                            .tag(FeedSection.news)
                        
                        shortsPage
                            .tag(FeedSection.shorts)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .transition(.opacity)
                .zIndex(0)
            }
            
            // News article overlay
            if let selected = selectedNewsArticle {
                NewsArticleView(
                    article: selected,
                    namespace: namespace,
                    onDismiss: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedNewsArticle = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onChange(of: scrollOffset) { _, newValue in
            handlePullToRefresh(with: newValue)
        }
        .onChange(of: activeSection) { _, newValue in
            isForYouActive = (newValue == .forYou)
            isNewsActive = (newValue == .news)
            isShortsActive = (newValue == .shorts)
            
            if newValue == .news, newsService.articles.isEmpty {
                Task { await newsService.ensureInitialPage() }
            }
        }
        .task {
            loadedSections = Set(FeedSection.allCases)
            isForYouActive = true
            
            // Only load if we haven't loaded yet
            if viewModel.loadState == .idle {
                await viewModel.loadInitialData(
                    userGames: UserProvider.shared.currentUser?.games ?? []
                )
            }
        }
        #if DEBUG
        .overlay(alignment: .trailing) {
            debugDrawerOverlay
        }
        #endif
    }
    
    // MARK: - Section Strip
    
    private var sectionStrip: some View {
        HStack(spacing: 12) {
            ForEach(FeedSection.allCases) { section in
                let isActive = section == activeSection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        activeSection = section
                    }
                } label: {
                    Text(section.title)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isActive ? Color.white.opacity(0.18) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isActive ? Color.white.opacity(0.9) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            #if DEBUG
            if DebugSettings.isDebugRuntime {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showDebugDrawer = true
                    }
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - For You Page
    
    private var forYouPage: some View {
        Group {
            if loadedSections.contains(.forYou) {
                forYouPageContent
                    .onAppear { isForYouActive = true }
                    .onDisappear { isForYouActive = false }
            } else {
                Color.appBackgroundColor.ignoresSafeArea()
            }
        }
    }
    
    private var forYouPageContent: some View {
        ZStack(alignment: .top) {
            Color.appBackgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Space for header
                    Color.clear
                        .frame(height: headerHeight + 54)
                        .background(
                            FeedScrollOffsetTracker(
                                initialOffset: $initialScrollOffset,
                                currentOffset: $scrollOffset
                            )
                        )
                    
                    // Pull to refresh indicator
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                    }
                    
                    // Feed content
                    VStack(alignment: .leading, spacing: 24) {
                        // For You Section (Hero Stack)
                        ForYouSectionView(
                            featuredGames: viewModel.featuredGames,
                            recommendedGames: viewModel.recommendedGames,
                            namespace: namespace,
                            onGameTapped: onGameTapped,
                            onPauseHeader: {
                                // Pause the carousel header
                                isForYouActive = false
                            },
                            onResumeHeader: {
                                // Resume the carousel header
                                isForYouActive = true
                            }
                        )
                        
                        // Upcoming Games Section (Hype Meter)
                        if !viewModel.upcomingGames.isEmpty {
                            UpcomingHypeMeterSection(
                                games: viewModel.upcomingGames,
                                namespace: namespace,
                                onGameTapped: onGameTapped
                            )
                        }
                        
                        // Game Invites
                        ForEach(viewModel.feedItems) { item in
                            feedItemView(for: item.itemType)
                        }
                        
                        Spacer(minLength: 42)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 64)
                    .background(Color.appBackgroundColor)
                }
            }
            
            // Carousel Header
            if !viewModel.carouselItems.isEmpty {
                NewSwiftyCarouselHeader(
                    items: viewModel.carouselItems,
                    actions: CarouselActions(
                        onPrimaryAction: { item in viewModel.handlePrimaryAction(for: item) },
                        onSecondaryAction: { item in viewModel.handleSecondaryAction(for: item) },
                        onItemAppear: { item in viewModel.trackCarouselView(item) },
                        onItemDisappear: { item in viewModel.cleanupCarouselItem(item) }
                    ),
                    scrollOffset: min(scrollOffset, maxHeaderStretch),
                    headerHeight: headerHeight,
                    isActive: $isActive
                )
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
                .zIndex(10)
            } else {
                // Header error or loading state
                headerPlaceholderView
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .zIndex(10)
            }
            
            // Status Bar
            FeedStatusBar(
                onMessagesTap: { print("Messages tapped") },
                onInvitesTap: { print("Invites tapped") },
                isVisible: isForYouActive && isActive
            )
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .offset(y: {
                let minHeight = headerHeight * 0.7
                let expandedHeight = headerHeight + min(scrollOffset, maxHeaderStretch)
                let containerHeight = max(minHeight, expandedHeight)
                return containerHeight - 10
            }())
            .ignoresSafeArea(edges: .horizontal)
            .zIndex(11)
        }
        .coordinateSpace(name: "feed")
    }
    
    // MARK: - Feed Item View Builder (for invites only now)
    
    @ViewBuilder
    private func feedItemView(for item: FeedItem.FeedItemType) -> some View {
        switch item {
        case .invite(let rival):
            GameInviteCell(rival: rival, onRespond: { response in
                viewModel.handleRivalAction(rival: rival, action: response)
            })
            .padding(.horizontal, 20)
        case .accepted(let rival):
            GameInviteCell(rival: rival, onRespond: { _ in
                viewModel.dismissRivalResponse(rival: rival)
            })
            .padding(.horizontal, 20)
        case .rejected(let rival):
            GameInviteCell(rival: rival, onRespond: { _ in
                viewModel.dismissRivalResponse(rival: rival)
            })
            .padding(.horizontal, 20)
        default:
            // Header, recommended, upcoming, sectionHeader handled separately
            EmptyView()
        }
    }
    
    // MARK: - News Page
    
    private var newsPage: some View {
        Group {
            if loadedSections.contains(.news) {
                newsPageContent
                    .onAppear { isNewsActive = true }
                    .onDisappear { isNewsActive = false }
            } else {
                ZStack {
                    Color.appBackgroundColor.ignoresSafeArea()
                    ProgressView().tint(.white.opacity(0.5))
                }
            }
        }
    }
    
    private var newsPageContent: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()
            
            if newsService.isLoading && newsService.articles.isEmpty {
                ProgressView().tint(.white)
            } else if let error = newsService.errorMessage, !error.isEmpty, newsService.articles.isEmpty {
                VStack(spacing: 12) {
                    Text("Couldn't load news")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                    Button {
                        Task { await newsService.ensureInitialPage() }
                    } label: {
                        Text("Retry")
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(newsService.articles) { article in
                            NewsRow(
                                article: article,
                                namespace: namespace,
                                selectedArticle: $selectedNewsArticle
                            )
                            .opacity(selectedNewsArticle?.id == article.id ? 0 : 1)
                            .onAppear {
                                Task { await newsService.loadMoreIfNeeded(currentItem: article) }
                            }
                        }
                        
                        if newsService.isLoading {
                            ProgressView().tint(.white).padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 64)
                }
            }
        }
    }
    
    // MARK: - Shorts Page
    
    private var shortsPage: some View {
        Group {
            if loadedSections.contains(.shorts) {
                ShortsPageView(isActive: $isShortsActive)
                    .onAppear { isShortsActive = true }
                    .onDisappear { isShortsActive = false }
            } else {
                ZStack {
                    Color.appBackgroundColor.ignoresSafeArea()
                    ProgressView().tint(.white.opacity(0.5))
                }
            }
        }
    }
    
    // MARK: - Pull to Refresh
    
    private func handlePullToRefresh(with offset: CGFloat) {
        let pull = max(0, offset)
        if pull < 10 { armedForRefresh = true }
        
        guard armedForRefresh, !isRefreshing, pull >= refreshTrigger else { return }
        armedForRefresh = false
        isRefreshing = true
        
        Task {
            await viewModel.refreshFeed(userGames: UserProvider.shared.currentUser?.games ?? [])
            await MainActor.run { isRefreshing = false }
        }
    }
    
    // MARK: - Header Placeholder View
    
    @ViewBuilder
    private var headerPlaceholderView: some View {
        switch viewModel.headerLoadState {
        case .loading, .idle:
            // Loading state
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                        .scaleEffect(1.2)
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
        case .error(let message):
            // Error state with retry
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "2d1f1f"),
                        Color(hex: "1a1a1a"),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "FF6B6B").opacity(0.8))
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Task {
                            await viewModel.retryHeaderLoad()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Retry")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 40)
            }
            
        case .loaded:
            // Shouldn't reach here if carouselItems is empty, but just in case
            Color.black
        }
    }
    
    // MARK: - Debug Drawer
    
    #if DEBUG
    @ViewBuilder
    private var debugDrawerOverlay: some View {
        ZStack {
            if showDebugDrawer {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            showDebugDrawer = false
                        }
                    }
                    .zIndex(40)
            }
            
            DebugDrawerView(
                isPresented: $showDebugDrawer,
                useMockHeader: $dbgUseMockHeader,
                useMockGames: $dbgUseMockGames,
                onApplyHeaderToggle: { enabled in
                    FeedDataManager.shared.useMockData = enabled
                    Task {
                        await viewModel.loadInitialData(
                            userGames: UserProvider.shared.currentUser?.games ?? []
                        )
                    }
                },
                onApplyGamesToggle: { enabled in
                    DebugSettings.shared.mockGameAPI = enabled
                    Task {
                        await GameAPIService.shared.fetchStartupGames()
                        await viewModel.loadInitialData(
                            userGames: UserProvider.shared.currentUser?.games ?? []
                        )
                    }
                },
                netEnabled: $dbgNet.enabled,
                netLatencyMs: $dbgNet.baseLatencyMs,
                netJitterMs: $dbgNet.jitterMs,
                netFailurePct: $dbgNet.failureRatePct,
                netTimeoutPct: $dbgNet.timeoutRatePct
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .allowsHitTesting(showDebugDrawer)
            .zIndex(45)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showDebugDrawer)
    }
    #endif
}


struct FeedLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Carousel Skeleton (Header + Status Bar area)
            FeedShimmerView()
                .frame(height: 340)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeedShimmerView().frame(width: 100, height: 24).cornerRadius(4)
                        FeedShimmerView().frame(width: 220, height: 36).cornerRadius(6)
                        HStack {
                            FeedShimmerView().frame(width: 120, height: 40).cornerRadius(10)
                            FeedShimmerView().frame(width: 40, height: 40).cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
            
            // Section Strip Skeleton
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    FeedShimmerView().frame(width: 80, height: 32).cornerRadius(16)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // Feed Items Skeleton
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(0..<3) { _ in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                FeedShimmerView().frame(width: 140, height: 20).cornerRadius(4)
                                Spacer()
                                FeedShimmerView().frame(width: 60, height: 16).cornerRadius(4)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<3) { _ in
                                        FeedShimmerView().frame(width: 280, height: 180).cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(Color.appBackgroundColor)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - News Row
struct NewsRow: View {
    let article: Article
    let namespace: Namespace.ID
    @Binding var selectedArticle: Article?

    var body: some View {
        switch article.cellKind {
        case .video:
            NewsVideoRow(article: article, namespace: namespace, selectedArticle: $selectedArticle)
        case .image:
            NewsImageRow(article: article, namespace: namespace, selectedArticle: $selectedArticle)
        case .text:
            NewsTextRow(article: article, namespace: namespace, selectedArticle: $selectedArticle)
        }
    }
}

enum NewsCellKind {
    case video
    case image
    case text
}

struct NewsReactionStrip: View {
    @Binding var selectedReaction: ReactionType?

    @Environment(\.colorScheme) private var scheme

    private var pillBackground: Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.05)
    }

    private var accentColor: Color {
        scheme == .dark ? .white : .black
    }

    private var mutedColor: Color {
        scheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var body: some View {
        HStack(spacing: 18) {
            Button {
                toggle(.fire)
            } label: {
                Text("🔥")
                    .font(.system(size: 19))
                    .opacity(selectedReaction == .fire ? 1.0 : 0.35)
                    .scaleEffect(selectedReaction == .fire ? 1.05 : 1.0)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.9),
                        value: selectedReaction == .fire
                    )
            }
            .buttonStyle(.plain)

            Button {
                toggle(.upvote)
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        selectedReaction == .upvote ? accentColor : mutedColor
                    )
            }
            .buttonStyle(.plain)

            Button {
                toggle(.downvote)
            } label: {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        selectedReaction == .downvote ? accentColor : mutedColor
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(pillBackground)
        .clipShape(Capsule())
    }

    private func toggle(_ type: ReactionType) {
        if selectedReaction == type {
            selectedReaction = nil
        } else {
            selectedReaction = type
        }
    }
}

struct NewsBottomBar: View {
    @Binding var selectedReaction: ReactionType?

    var onShare: () -> Void
    var onOpen: () -> Void

    @Environment(\.colorScheme) private var scheme

    private var iconBackground: Color {
        scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.08)
    }

    private var iconForeground: Color {
        .white
    }

    var body: some View {
        HStack(spacing: 12) {
            NewsReactionStrip(selectedReaction: $selectedReaction)

            Spacer(minLength: 0)

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconForeground)
                    .frame(width: 32, height: 32)
                    .background(iconBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconForeground)
                    .frame(width: 32, height: 32)
                    .background(iconBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Color.black.opacity(scheme == .dark ? 0.25 : 0.12)
                .blur(radius: 6)
        )
    }
}

extension Article {
    var cellKind: NewsCellKind {
        if isVideo, (videoThumbnailUrl ?? imageUrl) != nil {
            return .video
        } else if imageUrl != nil {
            return .image
        } else {
            return .text
        }
    }
}

private struct ArticleReactionStrip: View {
    let article: Article
    let state: ReactionViewState
    let onToggleFire: () -> Void
    let onToggleUpvote: () -> Void
    let onToggleDownvote: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var myReaction: ReactionType? { state.myReaction }

    var body: some View {
        HStack(spacing: 10) {
            // Reactions pill
            HStack(spacing: 18) {
                // 🔥
                Button(action: onToggleFire) {
                    Text("🔥")
                        .font(.system(size: 18))
                        .opacity(myReaction == .fire ? 1.0 : 0.40)
                        .scaleEffect(myReaction == .fire ? 1.05 : 1.0)
                        .animation(
                            .spring(response: 0.25, dampingFraction: 0.9),
                            value: myReaction == .fire
                        )
                }
                .buttonStyle(.plain)

                // 👍
                Button(action: onToggleUpvote) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            myReaction == .upvote ? activeColor : mutedColor
                        )
                }
                .buttonStyle(.plain)

                // 👎
                Button(action: onToggleDownvote) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            myReaction == .downvote ? activeColor : mutedColor
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(pillBackground)
            .clipShape(Capsule())

            Spacer(minLength: 0)
        }
    }

    private var pillBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.06)
        : Color.black.opacity(0.035)
    }

    private var activeColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var mutedColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.55)
        : Color.black.opacity(0.45)
    }
}

fileprivate enum NewsReactionSelection {
    case fire, up, down
}

fileprivate struct NewsInteractionBar: View {
    let urlString: String
    @Binding var selection: NewsReactionSelection?

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 12) {
            reactionsPill

            Spacer(minLength: 0)

            if let url = URL(string: urlString) {
                // Share
                ShareLink(item: url) {
                    iconCircle(systemName: "square.and.arrow.up")
                }

                // Open in browser
                Button {
                    openURL(url)
                } label: {
                    iconCircle(systemName: "arrow.up.right")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    private var reactionsPill: some View {
        HStack(spacing: 18) {
            // 🔥
            Button {
                toggle(.fire)
            } label: {
                Text("🔥")
                    .font(.system(size: 18))
                    .opacity(selection == .fire ? 1.0 : 0.35)
                    .scaleEffect(selection == .fire ? 1.05 : 1.0)
            }
            .buttonStyle(.plain)

            // 👍
            Button {
                toggle(.up)
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(selection == .up ? .white : .white.opacity(0.45))
            }
            .buttonStyle(.plain)

            // 👎
            Button {
                toggle(.down)
            } label: {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(selection == .down ? .white : .white.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private func iconCircle(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Color.white.opacity(0.09))
            .clipShape(Circle())
    }

    private func toggle(_ target: NewsReactionSelection) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            selection = (selection == target) ? nil : target
        }
    }
}

struct NewsVideoRow: View {
    let article: Article
    let namespace: Namespace.ID
    @Binding var selectedArticle: Article?
    @State private var showComments = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var thumbnailURL: URL? {
        if let v = article.videoThumbnailUrl, let url = URL(string: v) {
            return url
        }
        if let img = article.imageUrl, let url = URL(string: img) {
            return url
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerContent

            if selectedArticle?.id != article.id {
                FloatingActionBar(
                    articleID: article.id,
                    namespace: namespace,
                    articleURL: article.url,
                    // 2. PASS THE ACTION
                    onCommentTapped: {
                        showComments = true
                    }
                ).padding(.vertical, 12)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedArticle = article
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(mediaId: article.id, mediaType: .article)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerContent: some View {
        ZStack(alignment: .bottomLeading) {
            // Thumbnail
            if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        placeholder
                    case .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }

            // Dark gradient at bottom for readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.15),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(maxWidth: .infinity)
            .frame(height: 130, alignment: .bottom)
            .allowsHitTesting(false)

            // Title + source
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(article.source)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.85))

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(relativeTimeString(for: article.publishedAt))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }

                Text(article.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // Play badge (centered)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.65))
                            .frame(width: 46, height: 46)

                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 18)
                }
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16/9, contentMode: .fit)
        .clipped()
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white
    }
}

// MARK: - IMAGE-CENTRIC CELL

struct NewsImageRow: View {
    let article: Article
    let namespace: Namespace.ID
    @Binding var selectedArticle: Article?
    @State private var showComments = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var imageURL: URL? {
        if let img = article.imageUrl, let url = URL(string: img) {
            return url
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerContent

            if selectedArticle?.id != article.id {
                FloatingActionBar(
                    articleID: article.id,
                    namespace: namespace,
                    articleURL: article.url,
                    // 2. PASS THE ACTION
                    onCommentTapped: {
                        showComments = true
                    }
                )
                .padding(.vertical, 12)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedArticle = article
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(mediaId: article.id, mediaType: .article)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // 🔹 This group is the SOURCE of the hero transition
                Group {
                    if let url = imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure(_):
                                placeholder
                            case .empty:
                                placeholder
                            @unknown default:
                                placeholder
                            }
                        }
                    } else {
                        placeholder
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
                .clipped()
                .matchedGeometryEffect(
                    id: "article-hero-\(article.id)",
                    in: namespace,
                    isSource: selectedArticle?.id != article.id
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.70),
                        Color.black.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(maxWidth: .infinity)
                .frame(height: 110, alignment: .bottom)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(article.source)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.85))

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text(relativeTimeString(for: article.publishedAt))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()
                    }

                    Text(article.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)

            if let desc = article.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13.5))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.72)
            : Color.black.opacity(0.7)
    }
}

// MARK: - TEXT CELL

struct NewsTextRow: View {
    let article: Article
    let namespace: Namespace.ID
    @Binding var selectedArticle: Article?
    @State private var showComments = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var thumbnailURL: URL? {
        if let img = article.imageUrl, let url = URL(string: img) {
            return url
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerContent

            if selectedArticle?.id != article.id {
                FloatingActionBar(
                    articleID: article.id,
                    namespace: namespace,
                    articleURL: article.url,
                    // 2. PASS THE ACTION
                    onCommentTapped: {
                        showComments = true
                    }
                ).padding(.vertical, 12)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedArticle = article
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(mediaId: article.id, mediaType: .article)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerContent: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(article.source)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryTextColor)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor.opacity(0.8))

                    Text(relativeTimeString(for: article.publishedAt))
                        .font(.caption2)
                        .foregroundColor(secondaryTextColor.opacity(0.8))

                    Spacer()
                }

                Text(article.title)
                    .font(.system(size: 16.5, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                if let desc = article.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }

            if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        thumbPlaceholder
                    case .empty:
                        thumbPlaceholder
                    @unknown default:
                        thumbPlaceholder
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var thumbPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.12))
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.92)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.72)
            : Color.black.opacity(0.7)
    }
}

struct FloatingActionBar: View {
    let articleID: String
    let namespace: Namespace.ID
    let articleURL: String
    var onCommentTapped: () -> Void
    
    @EnvironmentObject private var reactionsManager: ReactionsManager
    
    private var isLiked: Bool {
        reactionsManager.viewStateForArticle(id: articleID).isLiked
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Like button
            Button {
                reactionsManager.toggleLikeForArticle(articleID: articleID)
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(isLiked ? Color.red : Color.zinc300)
            }
            .buttonStyle(.plain)
            
            Divider().frame(height: 20).background(Color.white.opacity(0.2))
            
            // Comment button (placeholder)
            Button {
                onCommentTapped()
            } label: {
                Image(systemName: "bubble.right")
                    .font(.body)
            }
            .buttonStyle(.plain)
            
            Divider().frame(height: 20).background(Color.white.opacity(0.2))
            
            // Share button
            ShareLink(item: URL(string: articleURL)!) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.zinc300)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .matchedGeometryEffect(id: "actionBar-\(articleID)", in: namespace)
    }
}

// MARK: - Relative Time Helper

fileprivate func relativeTimeString(for date: Date) -> String {
    let now = Date()
    let seconds = Int(now.timeIntervalSince(date))

    if seconds < 60 {
        return "just now"
    }
    let minutes = seconds / 60
    if minutes < 60 {
        return "\(minutes)m ago"
    }
    let hours = minutes / 60
    if hours < 24 {
        return "\(hours)h ago"
    }
    let days = hours / 24
    if days < 7 {
        return "\(days)d ago"
    }
    let weeks = days / 7
    if weeks < 4 {
        return "\(weeks)w ago"
    }
    let months = weeks / 4
    if months < 12 {
        return "\(months)mo ago"
    }
    let years = months / 12
    return "\(years)y ago"
}

// MARK: - Player shims (only used when showVideo == true)

private struct NativeVideoQuickView: View {
    let url: URL
    @State private var player: AVPlayer? = nil

    var body: some View {
        VideoPlayerContainer(player: player)
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: url)
                    player?.isMuted = true
                    player?.play()
                }
            }
            .onDisappear {
                player?.pause()
            }
    }
}

private struct VideoPlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer?
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController()
        c.showsPlaybackControls = false
        c.videoGravity = .resizeAspectFill
        return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {
        ui.player = player
    }
}

// MARK: - Quiet offset tracker

private struct FeedScrollOffsetTracker: View {
    @Binding var initialOffset: CGFloat?
    @Binding var currentOffset: CGFloat

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            Color.clear.onChange(of: minY) { _, newValue in
                if initialOffset == nil { initialOffset = newValue }
                if let initial = initialOffset { currentOffset = newValue - initial }
            }
        }
    }
}

// MARK: - Local reactions helper (legacy, currently unused)

private struct Reactions {
    var fire: Int
    var up: Int
    var down: Int
    var selection: Selection? = nil
    enum Selection { case fire, up, down }
}

// MARK: - Date helper

private func daysUntil(from dateString: String?) -> Int? {
    guard let s = dateString, !s.isEmpty else { return nil }
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd"
    guard let d = fmt.date(from: s) else { return nil }
    let cal = Calendar.current
    let start = cal.startOfDay(for: Date())
    let end  = cal.startOfDay(for: d)
    return cal.dateComponents([.day], from: start, to: end).day
}

// MARK: - Upcoming Game Card

struct UpcomingGameCard: View {
    let game: GamerConnectGame
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var reactionsManager: ReactionsManager

    private var isLiked: Bool {
        reactionsManager.viewStateForGame(id: game.id).isLiked
    }

    var body: some View {
        ZStack {
            // 1. Background Image
            if let urlString = game.imageUrl, let url = URL(string: urlString) {
                CachedAsyncImageView(url: url)
                    .aspectRatio(contentMode: .fill)
                    .matchedGeometryEffect(
                        id: game.id,
                        in: namespace,
                        anchor: .center
                    )
            } else {
                Color(red: 0.15, green: 0.16, blue: 0.17) // Zinc-800
            }
            
            // 2. Gradient Overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.95), location: 0.0),
                    .init(color: .black.opacity(0.7), location: 0.3),
                    .init(color: .black.opacity(0.2), location: 0.6),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            // 3. Content Layer
            VStack(alignment: .leading) {
                // Top Badge
                HStack {
                    launchingBadge
                    Spacer()
                }
                .padding([.top, .leading], 12)
                
                Spacer()
                
                // Bottom Info
                VStack(alignment: .leading, spacing: 4) {
                    // Release Box
                    VStack(alignment: .center, spacing: 6) {
                        Text("Releases In")
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(1)
                            .foregroundColor(releaseLabelColor)
                        
                        if let days = daysUntil(from: game.releaseDate) {
                            Text(days > 0 ? "\(days) days" : "Today")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(daysTextColor(for: days))
                        }
                        
                        if let releaseDate = game.releaseDate {
                            Text(formatReleaseDate(releaseDate))
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        ZStack {
                            // Blur effect
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            
                            // Dark tint overlay
                            Color.black.opacity(0.85)
                        }
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(releaseBorderColor, lineWidth: 1)
                    )
                    .padding(.bottom, 8)
                    
                    // Title with background
                    Text(game.gameName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.6))
                        )
                    
                    // Platform/Developer
                    Text(game.developer ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.8))
                        .padding(.bottom, 8)
                    
                    // Like Button
                    likeButton
                }
                .padding(16)
            }
        }
        .frame(width: 220, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        .onTapGesture {
            onGameTapped(game)
        }
    }
    
    // MARK: - Launching Badge
    
    @ViewBuilder
    private var launchingBadge: some View {
        if let days = daysUntil(from: game.releaseDate) {
            Text(days <= 3 ? "Imminent" : "Launching Soon")
                .font(.system(size: 9, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: days <= 3 ?
                            [Color.red, Color.red.opacity(0.8)] :
                            [Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.93, green: 0.37, blue: 0.43)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(6)
                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Like Button
    
    private var likeButton: some View {
        Button {
            reactionsManager.toggleLikeForGame(gameID: game.id)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundStyle(isLiked ? Color.red : Color.white.opacity(0.6))
                
                Text(isLiked ? "Wishlisted" : "Wishlist")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isLiked ? Color.white : Color.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isLiked ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(isLiked ? Color.red.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Functions
    
    private func daysUntil(from dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        guard let releaseDate = formatter.date(from: dateString) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: releaseDate)
        
        return components.day
    }
    
    private func formatReleaseDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM d, yyyy"
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Dynamic Colors
    
    private func daysTextColor(for days: Int) -> Color {
        if days <= 1 {
            return Color(red: 1.0, green: 0.09, blue: 0.27) // Bright red
        } else if days <= 3 {
            return Color(red: 1.0, green: 0.28, blue: 0.28) // Medium red
        } else {
            return .white
        }
    }
    
    private var releaseLabelColor: Color {
        guard let days = daysUntil(from: game.releaseDate) else { return Color.red.opacity(0.7) }
        if days <= 3 {
            return Color.red
        }
        return Color.red.opacity(0.7)
    }
    
    private var releaseBorderColor: Color {
        guard let days = daysUntil(from: game.releaseDate) else { return Color.red.opacity(0.2) }
        if days <= 3 {
            return Color.red.opacity(0.4)
        }
        return Color.red.opacity(0.2)
    }
    
    private var borderColor: Color {
        guard let days = daysUntil(from: game.releaseDate) else { return Color.red.opacity(0.3) }
        if days <= 3 {
            return Color.red.opacity(0.5)
        }
        return Color.red.opacity(0.3)
    }
    
    private var shadowColor: Color {
        guard let days = daysUntil(from: game.releaseDate) else { return Color.black.opacity(0.3) }
        if days <= 3 {
            return Color.red.opacity(0.4)
        }
        return Color.black.opacity(0.3)
    }
}

private struct PopularCard: View {
    let game: GamerConnectGame
    let cardWidth: CGFloat
    let isCentered: Bool
    
    // --- SwiftUI Transition Props ---
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void
    // ---

    @Environment(\.colorScheme) private var scheme
    @State private var dwellTask: Task<Void, Never>? = nil
    @State private var showSpinner: Bool = false
    @State private var showVideo: Bool = false
    
    private var youtubeID: String? { game.twitchHandle }
    private var nativeURL: URL? { URL(string: game.quizUrl ?? "") }
    private var badgeText: String { game.gameType ?? game.categoryFilters.first ?? "Featured" }

    var body: some View {
        ZStack {
            // 1. Background Image/Video
            GameHeroArt(
                game: game,
                namespace: namespace,
                cornerRadius: 16,
                height: 320
            )
            .frame(width: cardWidth, height: 320)

            if showVideo {
                videoLayer
                    .frame(width: cardWidth, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.opacity)
            }
            
            // 2. Gradient Overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.9), location: 0.0),
                    .init(color: .black.opacity(0.2), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Spinner overlay
            if isCentered && showSpinner && !showVideo {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.1)
                    .frame(width: cardWidth, height: 320)
                    .transition(.opacity)
            }
            
            // 3. Content Layer
            VStack(alignment: .leading) {
                // Top Badge
                HStack {
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding([.top, .leading], 12)
                
                Spacer()
                
                // Bottom Info
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(game.gameName)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Subtitle (using gameType or category as studio)
                    if let type = game.gameType ?? game.categoryFilters.first {
                        Text("Genre: \(type)")
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.8))
                            .padding(.bottom, 12)
                    }
                    
                    // Button
                    Button(action: {
                        onGameTapped(game)
                    }) {
                        Text("View Details")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                }
                .padding(24)
            }
        }
        // Container Sizing & Styling
        .frame(width: cardWidth, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isCentered)
        .onChange(of: isCentered) { _, nowCentered in
            handleCenterChange(isCentered: nowCentered)
        }
        .onDisappear {
            dwellTask?.cancel()
            dwellTask = nil
            showSpinner = false
        }
        .onTapGesture {
            onGameTapped(game)
        }
        .zIndex(1)
    }

    @ViewBuilder
    private var videoLayer: some View {
        if let id = youtubeID, !id.isEmpty {
            YouTubePlayerRepresentable(videoID: id)
                .allowsHitTesting(false)
        } else if let mp4 = nativeURL {
            NativeVideoQuickView(url: mp4)
                .allowsHitTesting(false)
        }
    }

    private func handleCenterChange(isCentered: Bool) {
        dwellTask?.cancel()
        dwellTask = nil
        showSpinner = false
        guard isCentered, (youtubeID != nil || nativeURL != nil) else {
            showVideo = false
            return
        }
        showSpinner = true
        dwellTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showSpinner = false
                    showVideo = true
                }
            } catch {
            }
        }
    }
}

// MARK: - Hex Color Helper (uses plain Int; no UInt types)

fileprivate extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

#if DEBUG
struct DebugDrawerView: View {
    @Binding var isPresented: Bool
    @Binding var useMockHeader: Bool
    @Binding var useMockGames: Bool
    
    var onApplyHeaderToggle: (Bool) -> Void
    var onApplyGamesToggle: (Bool) -> Void
    
    @Binding var netEnabled: Bool
    @Binding var netLatencyMs: Int
    @Binding var netJitterMs: Int
    @Binding var netFailurePct: Int
    @Binding var netTimeoutPct: Int
    
    @ObservedObject private var debugSettings = DebugSettings.shared
    
    private let drawerWidth: CGFloat = 340
    @State private var dragOffsetX: CGFloat = 0
    @State private var toastMessage: String? = nil
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isPresented {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            if isPresented {
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            xpTestingSection
                            abTestSection
                            feedDataSection
                            gamingExperienceSection
                            gameAPISection
                            gameCacheSection
                            networkSection
                            utilitiesSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    bottomButtons
                }
                .frame(width: drawerWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1), alignment: .leading)
                .offset(x: dragOffsetX)
                .transition(.move(edge: .trailing))
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in dragOffsetX = max(0, value.translation.width) }
                        .onEnded { value in
                            if value.translation.width > 80 { dismiss() }
                            else { withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { dragOffsetX = 0 } }
                        }
                )
                .zIndex(1)
                
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message).font(.callout.weight(.medium)).foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color.black.opacity(0.8)).clipShape(Capsule())
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isPresented)
        .onAppear {
            useMockGames = debugSettings.mockGameAPI
            useMockHeader = debugSettings.mockFeedHeader
        }
    }
    
    private var header: some View {
        HStack {
            Label("Debug Settings", systemImage: "wrench.and.screwdriver").font(.headline).foregroundStyle(.white)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9)).symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14).background(Color.black.opacity(0.55))
    }
    
    // MARK: - XP Testing Section
    @State private var customXPAmount: String = "250"
    
    private var xpTestingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("XP & Level Testing").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("LV \(XPManager.shared.currentLevel)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF4757")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            
            // Current XP Display
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Current XP").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(XPManager.shared.xpInCurrentLevel) / \(XPManager.shared.xpRequiredForNextLevel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * XPManager.shared.levelProgress)
                    }
                }
                .frame(height: 6)
                
                Text("Total: \(XPManager.shared.totalXP) XP • \(XPManager.shared.xpToNextLevel) to next level")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Custom XP Amount Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom XP Amount").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    HStack {
                        Text("+")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "4ADE80"))
                        
                        TextField("Amount", text: $customXPAmount)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        
                        Text("XP")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        if let amount = Int(customXPAmount), amount > 0 {
                            Task {
                                await XPManager.shared.addXP(amount, source: .bonus)
                                showToast("+\(amount) XP added")
                            }
                        }
                    } label: {
                        Text("Add XP")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "4ADE80"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Quick Add XP Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add (triggers animation)").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 6) {
                    ForEach([10, 25, 50, 100, 500], id: \.self) { amount in
                        Button {
                            Task {
                                await XPManager.shared.addXP(amount, source: .bonus)
                                showToast("+\(amount) XP added")
                            }
                        } label: {
                            Text("+\(amount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(hex: "4ADE80").opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(hex: "4ADE80").opacity(0.5), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Level Up Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Level Up Testing").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                
                // Info about XP needed
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Need \(XPManager.shared.xpToNextLevel) XP to reach Level \(XPManager.shared.currentLevel + 1)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                HStack(spacing: 8) {
                    // Trigger actual level up with XP
                    Button {
                        let xpNeeded = XPManager.shared.xpToNextLevel
                        let targetLevel = XPManager.shared.currentLevel + 1
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            Task {
                                await XPManager.shared.addXP(xpNeeded, source: .bonus)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                            Text("Level Up (+\(XPManager.shared.xpToNextLevel) XP)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Celebration Preview (separate from actual XP)
            VStack(alignment: .leading, spacing: 8) {
                Text("Celebration Preview (no XP change)").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    Button {
                        let level = XPManager.shared.currentLevel
                        let title = LevelInfo.info(for: level).title
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            // Use showCelebration for proper animation
                            LevelUpCelebrationController.shared.showCelebration(
                                level: level,
                                title: title
                            )
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 12))
                            Text("Current Level")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.6), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        let level = XPManager.shared.currentLevel + 1
                        let title = LevelInfo.info(for: level).title
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            // Use showCelebration for proper animation
                            LevelUpCelebrationController.shared.showCelebration(
                                level: level,
                                title: title
                            )
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("Next Level")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.6), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Preview celebration without affecting XP. Uses current A/B variant.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Text("XP changes animate in the Feed status bar. Close drawer to see animations.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - A/B Test Section
    private var abTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("A/B Tests").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                Spacer()
                if ABTestManager.shared.overrides[ABTest.levelUpCelebration.rawValue] != nil {
                    Text("OVERRIDE")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            // Level Up Celebration Test
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level Up Celebration")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(ABTestManager.shared.levelUpVariant().displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                HStack(spacing: 8) {
                    ForEach(LevelUpVariant.allCases, id: \.rawValue) { variant in
                        let isSelected = ABTestManager.shared.levelUpVariant() == variant
                        Button {
                            ABTestManager.shared.setLocalOverride(
                                for: .levelUpCelebration,
                                variant: variant.rawValue
                            )
                            showToast("Set to \(variant.displayName)")
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: variant == .fullScreen ? "rectangle.inset.filled" : "rectangle.topthird.inset.filled")
                                    .font(.system(size: 20))
                                Text(variant == .fullScreen ? "Full Screen" : "Banner")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected
                                ? LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Assignment Info
            if let assignment = ABTestManager.shared.assignments[ABTest.levelUpCelebration.rawValue] {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Original Assignment")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(assignment.variant.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Text("Assigned: \(formatDate(assignment.assignedAt)) • Source: \(assignment.source.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else {
                Text("No assignment yet (will be assigned at registration)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Clear Override Button
            Button {
                ABTestManager.shared.setLocalOverride(for: .levelUpCelebration, variant: nil)
                showToast("Override cleared - using original assignment")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12))
                    Text("Clear Override (Use Original)")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(ABTestManager.shared.overrides[ABTest.levelUpCelebration.rawValue] == nil)
            .opacity(ABTestManager.shared.overrides[ABTest.levelUpCelebration.rawValue] == nil ? 0.5 : 1)
            
            Text("Override lets you test both variants. Clear to use the user's actual assignment.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Gaming Experience Section
    private var gamingExperienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gaming Experience").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                Spacer()
                gamingExperienceStatusBadge
            }
            
            Toggle(isOn: $debugSettings.overrideGamingExperience) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Override Experience Level").font(.body)
                    Text("Use debug value instead of database").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }.tint(.purple)
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Experience Level").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(experienceLevelLabel(for: debugSettings.debugGamingExperience)).font(.caption).foregroundStyle(.white.opacity(0.5))
                }
                
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            debugSettings.debugGamingExperience = level
                        } label: {
                            Text("\(level)")
                                .font(.callout.weight(.bold))
                                .foregroundColor(debugSettings.debugGamingExperience == level ? .black : .white.opacity(0.7))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(debugSettings.debugGamingExperience == level ? experienceLevelColor(for: level) : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!debugSettings.overrideGamingExperience)
                        .opacity(debugSettings.overrideGamingExperience ? 1 : 0.5)
                    }
                }
            }
            
            HStack {
                Image(systemName: "info.circle").font(.caption).foregroundStyle(.white.opacity(0.5))
                Text("Effective: \(debugSettings.effectiveGamingExperience) (\(debugSettings.overrideGamingExperience ? "Debug" : "Database"))")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }.padding(.top, 4)
            
            Text("Affects Discover feed recommendations. Lower = casual, Higher = hardcore.")
                .font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 2)
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var gamingExperienceStatusBadge: some View {
        Group {
            if debugSettings.overrideGamingExperience {
                Text("DEBUG: \(debugSettings.debugGamingExperience)").font(.caption2.weight(.bold)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.purple).clipShape(Capsule())
            } else {
                let dbValue = UserProvider.shared.currentUser?.gamingExperience ?? "5"
                Text("DB: \(dbValue)").font(.caption2.weight(.bold)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.green).clipShape(Capsule())
            }
        }
    }
    
    private func experienceLevelLabel(for level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Casual"
        case 3: return "Regular"
        case 4: return "Experienced"
        case 5: return "Hardcore"
        default: return "Unknown"
        }
    }
    
    private func experienceLevelColor(for level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .mint
        case 3: return .blue
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    // MARK: - Feed Data Section
    private var feedDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feed Data").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Header / Carousel").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    headerDataStatusBadge
                }
                HStack(spacing: 6) {
                    ForEach(["live", "cached", "mock"], id: \.self) { source in
                        Button { debugSettings.headerDataSource = source } label: {
                            Text(source.uppercased()).font(.caption2.weight(.bold))
                                .foregroundColor(debugSettings.headerDataSource == source ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 10).padding(.vertical, 6).frame(maxWidth: .infinity)
                                .background(debugSettings.headerDataSource == source ? feedSourceColor(for: source) : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }.buttonStyle(.plain)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Games Data").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    feedDataStatusBadge
                }
                HStack(spacing: 6) {
                    ForEach(["live", "cached", "mock"], id: \.self) { source in
                        Button { debugSettings.feedDataSource = source } label: {
                            Text(source.uppercased()).font(.caption2.weight(.bold))
                                .foregroundColor(debugSettings.feedDataSource == source ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 10).padding(.vertical, 6).frame(maxWidth: .infinity)
                                .background(debugSettings.feedDataSource == source ? feedSourceColor(for: source) : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }.buttonStyle(.plain)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            Toggle(isOn: $debugSettings.cacheFeedResponses) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Cache Responses").font(.body)
                    Text("Save API responses for offline/cached use").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }.tint(.green)
            
            Text("Priority: Mock > Cached > Live API").font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 4)
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var headerDataStatusBadge: some View {
        Text(debugSettings.headerDataSource.uppercased()).font(.caption2.weight(.bold)).foregroundColor(.black)
            .padding(.horizontal, 6).padding(.vertical, 3).background(feedSourceColor(for: debugSettings.headerDataSource)).clipShape(Capsule())
    }
    
    private var feedDataStatusBadge: some View {
        Text(debugSettings.feedDataSource.uppercased()).font(.caption2.weight(.bold)).foregroundColor(.black)
            .padding(.horizontal, 6).padding(.vertical, 3).background(feedSourceColor(for: debugSettings.feedDataSource)).clipShape(Capsule())
    }
    
    private func feedSourceColor(for source: String) -> Color {
        switch source {
        case "mock": return .orange
        case "cached": return .cyan
        default: return .green
        }
    }
    
    // MARK: - Game API Section
    private var gameAPISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Game Selection API").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                Spacer()
                statusBadge
            }
            
            Toggle(isOn: $useMockGames) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Mock Game Data").font(.body)
                    Text("Hardcoded local games (no network)").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }.tint(.orange).onChange(of: useMockGames) { _, newValue in if newValue { debugSettings.useCachedGameResponses = false } }
            
            Divider().background(Color.white.opacity(0.1))
            
            Toggle(isOn: $debugSettings.useCachedGameResponses) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Cached API Responses").font(.body)
                    Text("Load from previously cached real responses").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }.tint(.cyan).disabled(useMockGames).opacity(useMockGames ? 0.5 : 1)
            .onChange(of: debugSettings.useCachedGameResponses) { _, newValue in if newValue { useMockGames = false; debugSettings.mockGameAPI = false } }
            
            Divider().background(Color.white.opacity(0.1))
            
            Toggle(isOn: $debugSettings.cacheGameResponses) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Cache API Responses").font(.body)
                    Text("Save real API responses for later use").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }.tint(.green)
            
            Text("Priority: Mock > Cached > Live API").font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 4)
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var statusBadge: some View {
        Group {
            if useMockGames {
                Text("MOCK").font(.caption2.weight(.bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Color.orange).clipShape(Capsule())
            } else if debugSettings.useCachedGameResponses {
                Text("CACHED").font(.caption2.weight(.bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Color.cyan).clipShape(Capsule())
            } else {
                Text("LIVE").font(.caption2.weight(.bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Color.green).clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Game Cache Section
    private var gameCacheSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Selection Cache").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Viewed Games Cache").font(.body)
                    Text("\(debugSettings.viewedGamesCount) games marked as seen").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button { debugSettings.clearViewedGamesCache(); showToast("Viewed games cache cleared") } label: {
                    Text("Clear").font(.caption.weight(.semibold)).foregroundColor(.red).padding(.horizontal, 12).padding(.vertical, 6).background(Color.red.opacity(0.15)).clipShape(Capsule())
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("API Response Cache").font(.body)
                    Text(debugSettings.cachedResponsesInfo).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button { debugSettings.clearAPIResponseCache(); showToast("API response cache cleared") } label: {
                    Text("Clear").font(.caption.weight(.semibold)).foregroundColor(.red).padding(.horizontal, 12).padding(.vertical, 6).background(Color.red.opacity(0.15)).clipShape(Capsule())
                }
            }
            
            Text("Clear viewed games to see previously swiped games again.").font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 4)
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Network Section
    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Simulation").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            Toggle("Enable Simulation", isOn: $netEnabled).tint(.purple)
            Group {
                labeledStepper(title: "Base latency (ms)", value: $netLatencyMs, range: 0...5000, step: 50)
                labeledStepper(title: "Jitter (±ms)", value: $netJitterMs, range: 0...2000, step: 25)
                labeledStepper(title: "Failure rate (%)", value: $netFailurePct, range: 0...100, step: 5)
                labeledStepper(title: "Timeout rate (%)", value: $netTimeoutPct, range: 0...100, step: 5)
            }.disabled(!netEnabled).opacity(netEnabled ? 1 : 0.5)
            Text("Adds artificial delay/failures to network calls.").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func labeledStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text("\(value.wrappedValue)").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
    }
    
    // MARK: - Utilities Section
    private var utilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Utilities").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 10) {
                Button { debugSettings.resetAll(); useMockGames = false; useMockHeader = false; showToast("All debug flags reset") } label: {
                    Label("Reset All", systemImage: "arrow.counterclockwise").font(.callout.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(.white.opacity(0.18))
                
                Button { debugSettings.clearViewedGamesCache(); debugSettings.clearAPIResponseCache(); showToast("All caches cleared") } label: {
                    Label("Clear All", systemImage: "trash").font(.callout.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(.red.opacity(0.3))
            }
            Text("Reset restores defaults. Clear removes all cached data.").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
        .padding(12).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 10) {
            Button(role: .cancel) { dismiss() } label: { Text("Close").font(.body.weight(.semibold)).frame(maxWidth: .infinity) }.buttonStyle(.bordered).tint(.white.opacity(0.25))
            Button { applyAndReload() } label: { Text("Apply").font(.body.weight(.semibold)).frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).tint(.white.opacity(0.85))
        }
        .padding(.horizontal, 16).padding(.vertical, 12).background(Color.black.opacity(0.55))
    }
    
    private func applyAndReload() {
        debugSettings.mockGameAPI = useMockGames
        debugSettings.mockFeedHeader = useMockHeader
        onApplyHeaderToggle(useMockHeader)
        onApplyGamesToggle(useMockGames)
        showToast("Settings applied")
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { isPresented = false; dragOffsetX = 0 }
    }
    
    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeIn(duration: 0.2)) { toastMessage = nil } }
    }
}
#endif

#if DEBUG
private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let units: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).foregroundStyle(.white)
                Spacer()
                Text("\(Int(value)) \(units)")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.caption)
            }
            Slider(value: $value, in: range)
                .tint(.white)
        }
    }
}
#endif

#if DEBUG
private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onCommit: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.white)
                Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.white)
                .onChange(of: isOn) { _, _ in onCommit() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.leading, 14),
            alignment: .bottom
        )
    }
}
#endif

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch s.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self = Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Center detection

private struct CenterReport: Equatable {
    let id: String
    let distance: CGFloat
}

private struct CenterPrefKey: PreferenceKey {
    static var defaultValue: [CenterReport] = []
    static func reduce(value: inout [CenterReport], nextValue: () -> [CenterReport]) {
        value.append(contentsOf: nextValue())
    }
}

private struct CenterReporter: ViewModifier {
    let id: String
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                let midX = geo.frame(in: .global).midX
                let screenMid = UIScreen.main.bounds.midX
                let dist = abs(midX - screenMid)
                Color.clear
                    .preference(key: CenterPrefKey.self, value: [CenterReport(id: id, distance: dist)])
            }
        )
    }
}

private extension View {
    func reportCenter(id: String) -> some View {
        modifier(CenterReporter(id: id))
    }
}


// MARK: - External Structs (from original file)

struct HighlightedGameCell: View {
    let forYouGame: ForYouGame
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Game Art
            AsyncImage(url: URL(string: forYouGame.game.imageUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .scaledToFill()
            .frame(width: 280, height: 268)
            .cornerRadius(16)
            .clipped()
            
            // Gradient overlay for text readability
            VStack { Spacer(); LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom).frame(height: 100) }.cornerRadius(16)
            
            // Game Info
            VStack(alignment: .leading, spacing: 4) {
                Text(forYouGame.game.gameName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(forYouGame.game.gameType ?? forYouGame.game.categoryFilters.first ?? "")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
        .frame(width: 280)
    }
}

/// The smaller, standard game cell (used in the V-Stack)
struct StandardGameCell: View {
    let forYouGame: ForYouGame
    
    // --- SwiftUI Transition Props ---
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void
    // ---
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 1. Background Image
            AsyncImage(url: URL(string: forYouGame.game.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Color(red: 0.15, green: 0.16, blue: 0.17) // Zinc-800
                case .empty:
                    Color(red: 0.15, green: 0.16, blue: 0.17)
                @unknown default:
                    Color(red: 0.15, green: 0.16, blue: 0.17)
                }
            }
            .matchedGeometryEffect(id: forYouGame.game.id, in: namespace)
            
            // 2. Gradient Overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.09, green: 0.09, blue: 0.11), location: 0.0), // Zinc-900
                    .init(color: .clear, location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            // 3. Content Layer
            VStack {
                Spacer()
                
                // Info Box
                VStack(alignment: .leading, spacing: 4) {
                    Text(forYouGame.game.gameName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(forYouGame.game.gameType ?? forYouGame.game.categoryFilters.first ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    ZStack {
                        // Blur effect
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        
                        // Dark tint
                        Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.9)
                    }
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
            .padding(16)
        }
        .frame(width: 220, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(white: 0.3).opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onGameTapped(forYouGame.game)
        }
        .zIndex(1)
    }
}

struct GameHeroArt: View {
    let game: GamerConnectGame
    let namespace: Namespace.ID
    let cornerRadius: CGFloat
    let height: CGFloat?
    
    var body: some View {
        AsyncImage(url: URL(string: game.imageUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure(_):
                Color.white.opacity(0.07)
            case .empty:
                Color.white.opacity(0.07)
            @unknown default:
                Color.white.opacity(0.07)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .matchedGeometryEffect(id: game.id, in: namespace)
    }
}

extension Color {
    static var appBackgroundColor: Color {
        return Color.black
    }
}

