//
//  PlayerSearchView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI

// MARK: - Player Search View (Design 2: Immersive Tiles)

struct PlayerSearchView: View {
    @StateObject private var viewModel = PlayerSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Callback for when a player is tapped
    var onPlayerTapped: ((PlayerSearchResult) -> Void)? = nil
    
    // Callback for adding games (when user has no games)
    var onAddGamesTapped: (() -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if viewModel.isInGamePlayerSearch {
                // Player Results View (after selecting a game)
                playerResultsView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Main View (game tiles or empty state)
                mainView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isInGamePlayerSearch)
        .task {
            await viewModel.loadInitialData()
        }
        .gesture(dismissGesture)
        .offset(y: dragOffset)
        .animation(.interactiveSpring(), value: dragOffset)
    }
    
    // MARK: - Main View
    
    private var mainView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // Content based on state
                if viewModel.showEmptyState {
                    emptyStateView
                } else if viewModel.isLoadingGames {
                    loadingView
                } else if !viewModel.searchText.isEmpty {
                    // Show search results
                    searchResultsView
                } else {
                    // Show user's games
                    userGamesSection
                    
                    // Divider
                    dividerSection
                    
                    // Alternative options
                    alternativeOptionsSection
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.bottom, 20)
            
            // Title
            Text("Find Players")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
            
            // Subtitle
            Text("Select a game to find teammates")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.5))
                
                TextField(viewModel.searchPlaceholder, text: $viewModel.searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                if viewModel.isSearching {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Search Mode Toggle
            HStack(spacing: 8) {
                ForEach(PlayerSearchMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.setSearchMode(mode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 12))
                            Text(mode.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(viewModel.searchMode == mode ? Color(hex: "667eea") : .white.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.searchMode == mode
                            ? Color(hex: "667eea").opacity(0.2)
                            : Color.white.opacity(0.06)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - User Games Section
    
    private var userGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Label
            Text("YOUR GAMES")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)
            
            // Game Tiles
            VStack(spacing: 12) {
                ForEach(viewModel.userGames) { game in
                    GameTileView(
                        game: game,
                        onlineCount: viewModel.onlineCounts[game.slug] ?? game.onlinePlayerCount
                    ) {
                        viewModel.selectGame(game)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Divider Section
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            Text("or try these")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    // MARK: - Alternative Options Section
    
    private var alternativeOptionsSection: some View {
        VStack(spacing: 12) {
            AlternativeOptionButton(
                icon: "person.fill",
                title: "Search for a Player",
                description: "Find someone by their gamertag"
            ) {
                viewModel.setSearchMode(.players)
                isSearchFocused = true
            }
            
            AlternativeOptionButton(
                icon: "gamecontroller.fill",
                title: "Browse All Games",
                description: "Explore players from any game"
            ) {
                viewModel.setSearchMode(.games)
                isSearchFocused = true
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Visual Icon
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "667eea").opacity(0.2),
                                Color(hex: "764ba2").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Title
            Text("Build Your Game Library")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            // Description
            Text("Add the games you play to instantly\nconnect with other players who share\nyour interests")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Add Games Button
            Button {
                onAddGamesTapped?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Games")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                Text("or search manually")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }
            .padding(.top, 8)
            
            // Alternative options
            VStack(spacing: 12) {
                AlternativeOptionButton(
                    icon: "person.fill",
                    title: "Search for a Player",
                    description: "Find someone by their gamertag"
                ) {
                    viewModel.setSearchMode(.players)
                    isSearchFocused = true
                }
                
                AlternativeOptionButton(
                    icon: "magnifyingglass",
                    title: "Search for a Game",
                    description: "Find players by game title"
                ) {
                    viewModel.setSearchMode(.games)
                    isSearchFocused = true
                }
            }
        }
        .padding(40)
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.searchMode == .players {
                // Player results
                if viewModel.isLoadingPlayers && viewModel.playerResults.isEmpty {
                    searchLoadingView
                } else if viewModel.playerResults.isEmpty {
                    noResultsView
                } else {
                    playerResultsList
                }
            } else {
                // Game results
                if viewModel.isLoadingGameSearch && viewModel.gameSearchResults.isEmpty {
                    searchLoadingView
                } else if viewModel.gameSearchResults.isEmpty {
                    noResultsView
                } else {
                    gameResultsList
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var playerResultsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLAYERS")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
            
            ForEach(viewModel.playerResults) { player in
                PlayerCardView(player: player) {
                    onPlayerTapped?(player)
                }
            }
        }
    }
    
    private var gameResultsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GAMES")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
            
            ForEach(viewModel.gameSearchResults) { game in
                GameSearchResultRow(game: game) {
                    // Convert to UserGameTile and select
                    let tile = UserGameTile(
                        id: game.id,
                        slug: game.slug,
                        name: game.name,
                        coverUrl: game.coverUrl,
                        genre: game.genre,
                        onlinePlayerCount: game.playerCount,
                        gradientColors: ["667eea", "764ba2"]
                    )
                    viewModel.selectGame(tile)
                }
            }
        }
    }
    
    private var searchLoadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                SearchShimmerView()
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.searchMode == .players ? "person.slash" : "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No results found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Player Results View (After Selecting Game)
    
    private var playerResultsView: some View {
        VStack(spacing: 0) {
            // Header
            playerResultsHeader
            
            // Search within game
            playerResultsSearchBar
            
            // Results
            if viewModel.isLoadingPlayers && viewModel.playerResults.isEmpty {
                loadingView
            } else if viewModel.playerResults.isEmpty {
                noPlayersFoundView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.playerResults) { player in
                            PlayerCardView(player: player) {
                                onPlayerTapped?(player)
                            }
                        }
                        
                        // Load more
                        if viewModel.hasMorePlayers {
                            ProgressView()
                                .tint(.white.opacity(0.5))
                                .padding()
                                .onAppear {
                                    Task {
                                        await viewModel.loadMorePlayers()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var playerResultsHeader: some View {
        HStack(spacing: 14) {
            // Back Button
            Button {
                viewModel.exitGamePlayerSearch()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedGame?.name ?? "Players")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(viewModel.playerResults.count) players found")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 16)
    }
    
    private var playerResultsSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Search players...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var noPlayersFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No players found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Be the first to join this community!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Dismiss Gesture
    
    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 && !viewModel.isInGamePlayerSearch {
                    dragOffset = value.translation.height * 0.5
                }
            }
            .onEnded { value in
                if value.translation.height > 100 && !viewModel.isInGamePlayerSearch {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Game Tile View

struct GameTileView: View {
    let game: UserGameTile
    let onlineCount: Int
    let onTap: () -> Void
    
    @State private var image: UIImage? = nil
    
    private var gradientColors: [Color] {
        game.gradientColors.map { Color(hex: $0) }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern overlay
                patternOverlay
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            Text(game.genreDisplay)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "4ADE80"))
                                    .frame(width: 6, height: 6)
                                
                                Text(formatOnlineCount(onlineCount))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow button
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(GameTileButtonStyle())
    }
    
    private var patternOverlay: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: -20)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 50, y: geo.size.height - 30)
            }
        }
    }
    
    private func formatOnlineCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk online", Double(count) / 1000.0)
        }
        return "\(count) online"
    }
}

struct GameTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Player Card View

struct PlayerCardView: View {
    let player: PlayerSearchResult
    let onTap: () -> Void
    
    @State private var avatarImage: UIImage? = nil
    
    private var avatarGradient: [Color] {
        let gradients: [[Color]] = [
            [Color(hex: "667eea"), Color(hex: "764ba2")],
            [Color(hex: "f093fb"), Color(hex: "f5576c")],
            [Color(hex: "4facfe"), Color(hex: "00f2fe")],
            [Color(hex: "43e97b"), Color(hex: "38f9d7")],
            [Color(hex: "fa709a"), Color(hex: "fee140")]
        ]
        let index = abs(player.id.hashValue) % gradients.count
        return gradients[index]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                avatarView
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Name row
                    HStack(spacing: 8) {
                        Text(player.gamerTag)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let matchPercent = player.matchPercentage, matchPercent >= 80 {
                            Text("\(matchPercent)% Match")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "4ADE80"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "4ADE80").opacity(0.2),
                                            Color(hex: "22C55E").opacity(0.2)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(hex: "4ADE80").opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    
                    // Rank/Level
                    HStack(spacing: 6) {
                        if let rank = player.rank {
                            Text(rank)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text(player.levelDisplay)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Tags
                    if !player.gamesInCommon.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(player.gamesInCommon.prefix(3), id: \.self) { game in
                                Text(game)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PlayerCardButtonStyle())
        .task {
            await loadAvatarImage()
        }
    }
    
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: avatarGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Text(player.avatarInitial)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Rank badge
            if let rank = player.rank {
                Text(String(rank.prefix(1)))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .offset(x: 4, y: 4)
            }
            
            // Online indicator
            if player.isOnline {
                Circle()
                    .fill(Color(hex: player.onlineStatus.color))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .offset(x: 2, y: -50)
            }
        }
    }
    
    private func loadAvatarImage() async {
        guard let urlString = player.avatarUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        avatarImage = await ImageCache.shared.image(for: url)
    }
}

struct PlayerCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Alternative Option Button

struct AlternativeOptionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "667eea").opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Search Result Row

struct GameSearchResultRow: View {
    let game: GameSearchResult
    let onTap: () -> Void
    
    @State private var coverImage: UIImage? = nil
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1a1a2e"), Color(hex: "2a2a4e")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    if let image = coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(game.genreDisplay)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "4ADE80"))
                                .frame(width: 5, height: 5)
                            
                            Text("\(game.playerCount) players")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "4ADE80"))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await loadCoverImage()
        }
    }
    
    private func loadCoverImage() async {
        guard let urlString = game.coverUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        coverImage = await ImageCache.shared.image(for: url)
    }
}

// MARK: - Shimmer View

struct SearchShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100)
                        .offset(x: isAnimating ? geo.size.width + 100 : -100)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}
