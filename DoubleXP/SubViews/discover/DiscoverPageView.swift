//
//  DiscoverView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import FirebaseDatabase

// MARK: - Tab Enum

enum DiscoverTab: String, CaseIterable, Identifiable {
    case games = "Games"
    case players = "Players"
    case communities = "Communities"
    
    var id: String { rawValue }
}

// MARK: - Navigation Destination

enum DiscoverDestination: Hashable {
    case game(GamerConnectGame)
    case player(User)
    case category(DiscoverPageCategory)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .game(let game):
            hasher.combine("game")
            hasher.combine(game.id)
        case .player(let user):
            hasher.combine("player")
            hasher.combine(user.uId)
        case .category(let category):
            hasher.combine("category")
            hasher.combine(category.title)
        }
    }
    
    static func == (lhs: DiscoverDestination, rhs: DiscoverDestination) -> Bool {
        switch (lhs, rhs) {
        case (.game(let l), .game(let r)): return l.id == r.id
        case (.player(let l), .player(let r)): return l.uId == r.uId
        case (.category(let l), .category(let r)): return l.title == r.title
        default: return false
        }
    }
}

// MARK: - Community Model for Discover

struct DiscoverCommunity: Identifiable {
    let id: String
    let name: String
    let gameSlug: String
    let icon: String
    let memberCount: Int
    let onlineCount: Int
    let isFeatured: Bool
    let isJoined: Bool
    
    var formattedMemberCount: String {
        if memberCount >= 1000 {
            return String(format: "%.1fk", Double(memberCount) / 1000)
        }
        return "\(memberCount)"
    }
}

// MARK: - Main View

struct DiscoverPageView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    var onDismiss: (() -> Void)? = nil
    @Namespace private var animationNamespace
    
    // Navigation stack for internal navigation
    @State private var navigationPath = NavigationPath()
    
    @State private var dragOffset: CGFloat = 0
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedTab: DiscoverTab = .games
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                mainContentView
                
                if isSearchActive {
                    searchOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: DiscoverDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .task {
            await viewModel.loadGamesTab()
        }
        .onChange(of: selectedTab) { newTab in
            Task {
                await viewModel.loadTabIfNeeded(newTab)
            }
        }
        .gesture(navigationPath.isEmpty ? dismissGesture : nil)
        .offset(y: navigationPath.isEmpty ? dragOffset : 0)
        .animation(.interactiveSpring(), value: dragOffset)
    }
    
    // MARK: - Destination View Builder
    
    @ViewBuilder
    private func destinationView(for destination: DiscoverDestination) -> some View {
        switch destination {
        case .game(let game):
            DiscoverGameDetailWrapper(
                game: game,
                onBack: { navigationPath.removeLast() }
            )
            
        case .player(let user):
            DiscoverPlayerDetailWrapper(
                user: user,
                onBack: { navigationPath.removeLast() },
                onGameTapped: { game in
                    navigationPath.append(DiscoverDestination.game(game))
                }
            )
            
        case .category(let category):
            DiscoverCategoryDetailWrapper(
                category: category,
                namespace: animationNamespace,
                onBack: { navigationPath.removeLast() },
                onGameTapped: { game in
                    navigationPath.append(DiscoverDestination.game(game))
                }
            )
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToGame(_ game: GamerConnectGame) {
        navigationPath.append(DiscoverDestination.game(game))
    }
    
    private func navigateToPlayer(_ user: User) {
        navigationPath.append(DiscoverDestination.player(user))
    }
    
    private func navigateToCategory(_ category: DiscoverPageCategory) {
        navigationPath.append(DiscoverDestination.category(category))
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            floatingHeader
            tabBar
            
            TabView(selection: $selectedTab) {
                gamesTabContent
                    .tag(DiscoverTab.games)
                
                playersTabContent
                    .tag(DiscoverTab.players)
                
                communitiesTabContent
                    .tag(DiscoverTab.communities)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Floating Header
    
    private var floatingHeader: some View {
        HStack(spacing: 10) {
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSearchActive = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(searchPlaceholder)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.95), Color.black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private var searchPlaceholder: String {
        switch selectedTab {
        case .games: return "Search games..."
        case .players: return "Search players..."
        case .communities: return "Search communities..."
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 32) {
            ForEach(DiscoverTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.4))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color(red: 1, green: 0.42, blue: 0.42) : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Divider().background(Color.white.opacity(0.08))
        }
    }
    
    // MARK: - Games Tab Content
    
    private var gamesTabContent: some View {
        Group {
            if viewModel.isLoadingGames {
                GamesTabSkeletonView()
            } else if let error = viewModel.gamesError {
                errorView(message: error) {
                    Task { await viewModel.loadGamesTab() }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let featured = viewModel.featuredGames.first {
                            DiscoverFeaturedGameCard(game: featured, onTap: {
                                navigateToGame(featured)
                            })
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                        }
                        
                        ForEach(viewModel.categories) { category in
                            DiscoverGameRowSection(
                                title: category.title,
                                games: category.games,
                                onSeeAll: {
                                    navigateToCategory(category)
                                },
                                onGameTap: { game in
                                    navigateToGame(game)
                                }
                            )
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
    }
    
    // MARK: - Players Tab Content
    
    private var playersTabContent: some View {
        Group {
            if viewModel.isLoadingPlayers {
                PlayersTabSkeletonView()
            } else if let error = viewModel.playersError {
                errorView(message: error) {
                    Task { await viewModel.loadPlayersTab() }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !viewModel.recommendedPlayers.isEmpty {
                            RecommendedPlayersCard(
                                players: viewModel.recommendedPlayers,
                                onPlayerTap: { user in
                                    navigateToPlayer(user)
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                        }
                        
                        if !viewModel.userGamesForPlayerSearch.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("YOUR GAMES")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(2)
                                    
                                    Text("Select a game to find teammates")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.userGamesForPlayerSearch) { game in
                                        PlayerSearchGameCard(game: game, onTap: {
                                            // Could navigate to a "find players for game" view
                                        })
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
    }
    
    // MARK: - Communities Tab Content
    
    private var communitiesTabContent: some View {
        Group {
            if viewModel.isLoadingCommunities {
                CommunitiesTabSkeletonView()
            } else if let error = viewModel.communitiesError {
                errorView(message: error) {
                    Task { await viewModel.loadCommunitiesTab() }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !viewModel.featuredCommunities.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Featured")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("See All") {}
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
                                }
                                .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(viewModel.featuredCommunities) { community in
                                            FeaturedCommunityCard(community: community)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                        }
                        
                        if !viewModel.userCommunities.isEmpty {
                            CommunitySectionList(
                                title: "Your Communities",
                                communities: viewModel.userCommunities,
                                showJoinButton: false
                            )
                            .padding(.bottom, 28)
                        }
                        
                        if !viewModel.suggestedCommunities.isEmpty {
                            CommunitySectionList(
                                title: "For Your Games",
                                communities: viewModel.suggestedCommunities,
                                showJoinButton: true
                            )
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(message)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            
            Button("Try Again") { retry() }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Search Overlay
    
    private var searchOverlay: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { closeSearch() }
            
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button { closeSearch() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        TextField(searchPlaceholder, text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Button("Cancel") { closeSearch() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)
                .padding(.bottom, 16)
                
                // Search results would go here
                // For now, show placeholder
                if !searchText.isEmpty {
                    searchResultsView
                }
                
                Spacer()
            }
        }
    }
    
    private var searchResultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Filter games by search text
                let filteredGames = viewModel.categories
                    .flatMap { $0.games }
                    .filter { $0.gameName.localizedCaseInsensitiveContains(searchText) }
                
                if !filteredGames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GAMES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(filteredGames.prefix(5)) { game in
                                Button {
                                    closeSearch()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigateToGame(game)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: game.imageUrl ?? "")) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.white.opacity(0.1)
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(game.gameName)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text(game.gameType ?? "Game")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Filter players by search text
                let filteredPlayers = viewModel.recommendedPlayers
                    .filter {
                        $0.screenName.localizedCaseInsensitiveContains(searchText) ||
                        $0.gamerTag.localizedCaseInsensitiveContains(searchText)
                    }
                
                if !filteredPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PLAYERS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(filteredPlayers.prefix(5)) { player in
                                Button {
                                    closeSearch()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigateToPlayer(player)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 44, height: 44)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(player.screenName.isEmpty ? player.gamerTag : player.screenName)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("\(player.games.count) games")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                if filteredGames.isEmpty && filteredPlayers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        
                        Text("No results for \"\(searchText)\"")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.top, 16)
        }
    }
    
    private func closeSearch() {
        isSearchFocused = false
        withAnimation(.easeOut(duration: 0.25)) {
            isSearchActive = false
            searchText = ""
        }
    }
    
    // MARK: - Dismiss Gesture
    
    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isSearchActive else { return }
                if value.translation.height > 0 {
                    dragOffset = value.translation.height * 0.6
                }
            }
            .onEnded { value in
                guard !isSearchActive else { return }
                if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                    onDismiss?()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Detail Wrappers for Navigation

struct DiscoverGameDetailWrapper: View {
    let game: GamerConnectGame
    let onBack: () -> Void
    
    @Namespace private var namespace
    
    var body: some View {
        GameDetailView(
            game: game,
            namespace: namespace,
            dominantColorTask: nil,
            onDismiss: onBack
        )
        .navigationBarHidden(true)
    }
}

struct DiscoverPlayerDetailWrapper: View {
    let user: User
    let onBack: () -> Void
    let onGameTapped: (GamerConnectGame) -> Void
    
    var body: some View {
        UserProfileView(
            uid: user.uId,
            onBack: onBack,
            onEditProfile: nil,
            onGameSelected: { gameItem in
                if let fullGame = GameStorageManager.shared.getGame(slug: gameItem.slug) {
                    onGameTapped(fullGame)
                }
            }
        )
        .navigationBarHidden(true)
    }
}

struct DiscoverCategoryDetailWrapper: View {
    let category: DiscoverPageCategory
    let namespace: Namespace.ID
    let onBack: () -> Void
    let onGameTapped: (GamerConnectGame) -> Void
    
    var body: some View {
        InnerCategoryView(
            category: category,
            namespace: namespace,
            onDismiss: onBack,
            onGameTapped: onGameTapped
        )
        .navigationBarHidden(true)
    }
}

// MARK: - Featured Game Card

struct DiscoverFeaturedGameCard: View {
    let game: GamerConnectGame
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.12), Color(white: 0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 1, green: 0.42, blue: 0.42).opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .offset(x: 50, y: -50)
                    }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("⭐ EDITOR'S PICK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.42, blue: 0.42), Color(red: 1, green: 0.56, blue: 0.33)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text(game.gameName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(game.hook ?? game.gameDescription ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(24)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Row Section

struct DiscoverGameRowSection: View {
    let title: String
    let games: [GamerConnectGame]
    let onSeeAll: () -> Void
    let onGameTap: (GamerConnectGame) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All", action: onSeeAll)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(games) { game in
                        DiscoverGameCard(game: game, onTap: { onGameTap(game) })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 28)
    }
}

// MARK: - Game Card

struct DiscoverGameCard: View {
    let game: GamerConnectGame
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: game.imageUrl ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color(white: 0.15))
                        }
                    }
                    .frame(width: 140, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(red: 0.29, green: 0.87, blue: 0.5))
                            .frame(width: 6, height: 6)
                        
                        Text("2.1k")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.5))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(8)
                }
                
                Text(game.gameName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(game.gameType ?? "Game")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 140)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recommended Players Card

struct RecommendedPlayersCard: View {
    let players: [User]
    let onPlayerTap: (User) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recommended For You")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("TOP 5")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.42, blue: 0.42), Color(red: 1, green: 0.56, blue: 0.33)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            .padding(.bottom, 16)
            
            VStack(spacing: 12) {
                ForEach(Array(players.prefix(5).enumerated()), id: \.element.uId) { index, user in
                    RecommendedPlayerRow(
                        rank: index + 1,
                        user: user,
                        onTap: { onPlayerTap(user) }
                    )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.1), Color(white: 0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1, green: 0.42, blue: 0.42).opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 100, y: -100)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Recommended Player Row

struct RecommendedPlayerRow: View {
    let rank: Int
    let user: User
    let onTap: () -> Void
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1, green: 0.84, blue: 0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.white.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(rankColor)
                    .frame(width: 24)
                
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if user.onlineStatus == "online" {
                        Circle()
                            .fill(Color(red: 0.29, green: 0.87, blue: 0.5))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color(white: 0.06), lineWidth: 2))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.screenName.isEmpty ? user.gamerTag : user.screenName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Plays \(user.games.count) of your games")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Search Game Card

struct PlayerSearchGameCard: View {
    let game: GamerConnectGame
    let onTap: () -> Void
    
    private let cardColors: [(Color, Color)] = [
        (Color(red: 0.07, green: 0.31, blue: 0.31), Color(red: 0.04, green: 0.16, blue: 0.16)),
        (Color(red: 0.1, green: 0.3, blue: 0.1), Color(red: 0.05, green: 0.15, blue: 0.05)),
        (Color(red: 0.24, green: 0.1, blue: 0.36), Color(red: 0.1, green: 0.05, blue: 0.15))
    ]
    
    var body: some View {
        let colorPair = cardColors[abs(game.id.hashValue) % cardColors.count]
        
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [colorPair.0, colorPair.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [colorPair.0.opacity(0.5), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .offset(x: -40, y: -40)
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(game.gameName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Text(game.gameType ?? "Game")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(red: 0.29, green: 0.87, blue: 0.5))
                                    .frame(width: 6, height: 6)
                                
                                Text("2.1k online")
                                    .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.5))
                            }
                        }
                        .font(.system(size: 13))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(20)
            }
            .frame(height: 100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Community Card

struct FeaturedCommunityCard: View {
    let community: DiscoverCommunity
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.23, green: 0.1, blue: 0.17), Color(red: 0.1, green: 0.05, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 1, green: 0.42, blue: 0.42).opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .offset(x: 40, y: -40)
                }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("🔥 FEATURED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(community.icon)
                            .font(.system(size: 24))
                        
                        Text(community.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(community.formattedMemberCount) members • \(community.onlineCount) online")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button("Join") {}
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .frame(width: 260, height: 160)
    }
}

// MARK: - Community Section List

struct CommunitySectionList: View {
    let title: String
    let communities: [DiscoverCommunity]
    let showJoinButton: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(communities) { community in
                    CommunityListCard(community: community, showJoinButton: showJoinButton)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Community List Card

struct CommunityListCard: View {
    let community: DiscoverCommunity
    let showJoinButton: Bool
    
    private let cardColors: [(Color, Color)] = [
        (Color(red: 0.07, green: 0.31, blue: 0.31), Color(red: 0.04, green: 0.16, blue: 0.16)),
        (Color(red: 0.1, green: 0.3, blue: 0.1), Color(red: 0.05, green: 0.15, blue: 0.05)),
        (Color(red: 0.24, green: 0.1, blue: 0.36), Color(red: 0.1, green: 0.05, blue: 0.15))
    ]
    
    var body: some View {
        let colorPair = cardColors[abs(community.id.hashValue) % cardColors.count]
        
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [colorPair.0, colorPair.1],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [colorPair.0.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .offset(x: -30, y: -30)
                }
            
            HStack(spacing: 14) {
                Text(community.icon)
                    .font(.system(size: 22))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(14)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(community.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("\(community.formattedMemberCount) members")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("\(community.onlineCount) online")
                            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.5))
                    }
                    .font(.system(size: 12))
                }
                
                Spacer()
                
                if showJoinButton {
                    Button("Join") {}
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(red: 1, green: 0.42, blue: 0.42).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 1, green: 0.42, blue: 0.42).opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                } else {
                    HStack(spacing: 8) {
                        Text("Joined")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
        }
    }
}

struct PlayersTabSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top 5 Card Skeleton
                VStack(spacing: 16) {
                    HStack {
                        ShimmerView().frame(width: 150, height: 20).cornerRadius(6)
                        Spacer()
                        ShimmerView().frame(width: 50, height: 24).cornerRadius(8)
                    }
                    
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            ShimmerView().frame(width: 24, height: 20).cornerRadius(4)
                            ShimmerView().frame(width: 44, height: 44).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                ShimmerView().frame(width: 100, height: 14).cornerRadius(4)
                                ShimmerView().frame(width: 140, height: 11).cornerRadius(3)
                            }
                            Spacer()
                            ShimmerView().frame(width: 32, height: 32).cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .background(Color(white: 0.08))
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
                
                // Your Games Section Skeleton
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView().frame(width: 100, height: 12).cornerRadius(4)
                        ShimmerView().frame(width: 200, height: 14).cornerRadius(4)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView()
                                .frame(height: 100)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Communities Tab Skeleton

struct CommunitiesTabSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Featured Section Skeleton
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        ShimmerView().frame(width: 80, height: 20).cornerRadius(6)
                        Spacer()
                        ShimmerView().frame(width: 50, height: 16).cornerRadius(4)
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(0..<2, id: \.self) { _ in
                                ShimmerView()
                                    .frame(width: 260, height: 160)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
                
                // Your Communities Skeleton
                VStack(alignment: .leading, spacing: 14) {
                    ShimmerView()
                        .frame(width: 140, height: 12)
                        .cornerRadius(4)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { _ in
                            ShimmerView()
                                .frame(height: 80)
                                .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 28)
                
                // For Your Games Skeleton
                VStack(alignment: .leading, spacing: 14) {
                    ShimmerView()
                        .frame(width: 120, height: 12)
                        .cornerRadius(4)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView()
                                .frame(height: 80)
                                .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var startPoint = UnitPoint(x: -1, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.12),
                Color.white.opacity(0.05)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                startPoint = UnitPoint(x: 1, y: 0.5)
                endPoint = UnitPoint(x: 2, y: 0.5)
            }
        }
    }
}

struct GamesTabSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Featured Card Skeleton
                ShimmerView()
                    .frame(height: 200)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                
                // Row Skeletons
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ShimmerView()
                                .frame(width: 120, height: 20)
                                .cornerRadius(6)
                            Spacer()
                            ShimmerView()
                                .frame(width: 60, height: 16)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(0..<4, id: \.self) { _ in
                                    VStack(alignment: .leading, spacing: 10) {
                                        ShimmerView()
                                            .frame(width: 140, height: 190)
                                            .cornerRadius(16)
                                        
                                        ShimmerView()
                                            .frame(width: 100, height: 14)
                                            .cornerRadius(4)
                                        
                                        ShimmerView()
                                            .frame(width: 60, height: 12)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
        }
    }
}
