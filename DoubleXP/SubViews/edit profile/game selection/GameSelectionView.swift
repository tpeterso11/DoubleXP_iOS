//
//  GameSelectionView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// Note: GameSelectionColors, CachedAsyncImage, ShimmerModifier, and Color extension
// are defined in GameSelectionUtilities.swift

// MARK: - Game Selection View

struct GameSelectionView: View {
    @StateObject private var viewModel: GameSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSearchSheet: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    
    // Callbacks
    var onComplete: (([GamerConnectGame]) -> Void)?
    var onSkip: (() -> Void)?
    var onSeeMore: (() -> Void)?
    
    init(isOnboarding: Bool = true,
         onComplete: (([GamerConnectGame]) -> Void)? = nil,
         onSkip: (() -> Void)? = nil,
         onSeeMore: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: GameSelectionViewModel(isOnboarding: isOnboarding))
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onSeeMore = onSeeMore
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [GameSelectionColors.backgroundGradientStart,
                         GameSelectionColors.backgroundGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Ambient glow
            ambientGlow
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Hero text
                heroSection
                
                // Search bar
                searchBar
                
                // Category tabs
                categoryTabs
                
                // Selected games bar (moved up from bottom)
                if !viewModel.selectedGames.isEmpty {
                    selectedGamesBar
                        .padding(.bottom, 16)
                }
                
                // Main content area
                Spacer()
                
                if viewModel.isLoading {
                    loadingSkeletonView
                } else if viewModel.hasError {
                    errorView
                } else if viewModel.isEndOfList || viewModel.currentCards.isEmpty {
                    endOfListView
                } else {
                    cardStackSection
                }
                
                Spacer()
            }
        }
        .task {
            await viewModel.loadGames()
        }
        .sheet(isPresented: $showSearchSheet) {
            GameSearchSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Ambient Glow
    
    private var ambientGlow: some View {
        RadialGradient(
            colors: [GameSelectionColors.coralStart.opacity(0.2), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 300
        )
        .ignoresSafeArea()
        .offset(y: -100)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // Onboarding dots (only show if onboarding)
            if viewModel.isOnboarding {
                onboardingDots
            }
            
            Spacer()
            
            // Skip button (only show if onboarding)
            if viewModel.isOnboarding {
                Button(action: { onSkip?() }) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                // Placeholder for layout balance
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Onboarding Dots
    
    private var onboardingDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == 0 ?
                          LinearGradient(colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                                         startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [Color.white.opacity(0.2)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: index == 0 ? 28 : 8, height: 8)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Pick Your Games")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Swipe right on games you play")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        Button(action: { showSearchSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                
                Text(viewModel.isSearching ? viewModel.searchQuery : "Search games...")
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.isSearching ? .white : .white.opacity(0.4))
                
                Spacer()
                
                if viewModel.isSearching {
                    Button(action: { viewModel.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameGenre.allCases) { genre in
                    GenreTab(
                        genre: genre,
                        isSelected: viewModel.selectedGenre == genre,
                        action: { viewModel.selectGenre(genre) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Selected Games Bar
    
    private var selectedGamesBar: some View {
        HStack(spacing: 12) {
            // Selected game thumbnails
            HStack(spacing: -10) {
                ForEach(viewModel.selectedGames.prefix(4)) { game in
                    GameMiniThumbnail(game: game)
                }
                
                if viewModel.selectedGames.count > 4 {
                    Text("+\(viewModel.selectedGames.count - 4)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Count info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("\(viewModel.selectedGames.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(GameSelectionColors.coralStart)
                    Text(" games")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("selected")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Continue button
            Button(action: { onComplete?(viewModel.selectedGames) }) {
                Text("Continue")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: GameSelectionColors.coralStart.opacity(0.4), radius: 12, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Card Stack Section
    
    private var cardStackSection: some View {
        VStack(spacing: 20) {
            // Card stack
            ZStack {
                ForEach(Array(viewModel.currentCards.enumerated().reversed()), id: \.element.id) { index, game in
                    SwipeableGameCard(
                        game: game,
                        isTopCard: index == 0,
                        stackIndex: index,
                        dragOffset: index == 0 ? dragOffset : .zero,
                        dragRotation: index == 0 ? dragRotation : 0,
                        onSwipeLeft: { viewModel.skipGame(game) },
                        onSwipeRight: { viewModel.selectGame(game) },
                        onDragChanged: { offset, rotation in
                            dragOffset = offset
                            dragRotation = rotation
                        },
                        onDragEnded: {
                            dragOffset = .zero
                            dragRotation = 0
                        }
                    )
                }
            }
            .frame(height: 320)
            
            // Action buttons
            actionButtons
            
            // Swipe hint
            Text("Swipe or tap the buttons")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 32) {
            // Skip button
            Button(action: {
                if let topCard = viewModel.currentCards.first {
                    viewModel.skipGame(topCard)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 64, height: 64)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    )
            }
            
            // Like button
            Button(action: {
                if let topCard = viewModel.currentCards.first {
                    viewModel.selectGame(topCard)
                }
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: GameSelectionColors.coralStart.opacity(0.4), radius: 16, y: 8)
            }
        }
    }
    
    // MARK: - Loading Skeleton View
    
    private var loadingSkeletonView: some View {
        VStack(spacing: 20) {
            // Skeleton card
            SkeletonCardView()
                .frame(width: 260, height: 340)
            
            // Skeleton buttons
            HStack(spacing: 32) {
                Circle()
                    .fill(GameSelectionColors.skeletonBase)
                    .frame(width: 64, height: 64)
                    .shimmer()
                
                Circle()
                    .fill(GameSelectionColors.skeletonBase)
                    .frame(width: 64, height: 64)
                    .shimmer()
            }
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(GameSelectionColors.coralStart)
            
            Text("Something went wrong")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(viewModel.errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Button(action: { viewModel.retryLoading() }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }
    
    // MARK: - End of List View
    
    private var endOfListView: some View {
        VStack(spacing: 24) {
            // Emoji
            Text("🎮")
                .font(.system(size: 64))
            
            // Title
            Text(viewModel.selectedGames.isEmpty ? "No games found" : "That's all of our recommendations!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Search for a specific game or see more")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            // Selected games preview
            if !viewModel.selectedGames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedGames.prefix(5)) { game in
                        GameMiniThumbnail(game: game, size: 56)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: { showSearchSheet = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search for Games")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: { onSeeMore?() }) {
                    Text("See More Games")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if !viewModel.selectedGames.isEmpty {
                    Button(action: { onComplete?(viewModel.selectedGames) }) {
                        Text("Continue with \(viewModel.selectedGames.count) games")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(GameSelectionColors.coralStart)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(GameSelectionColors.coralStart.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(GameSelectionColors.coralStart.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
    }
}

// MARK: - Genre Tab

struct GenreTab: View {
    let genre: GameGenre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.white.opacity(0.06)
                        }
                    }
                )
                .clipShape(Capsule())
                .shadow(color: isSelected ? GameSelectionColors.coralStart.opacity(0.3) : .clear,
                        radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Mini Thumbnail

struct GameMiniThumbnail: View {
    let game: GamerConnectGame
    var size: CGFloat = 36
    
    var body: some View {
        GameSelectionCachedAsyncImage(url: game.displayImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                gameGradientPlaceholder
            case .empty:
                gameGradientPlaceholder
            @unknown default:
                gameGradientPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.25)
                .stroke(Color.black, lineWidth: 2)
        )
    }
    
    private var gameGradientPlaceholder: some View {
        LinearGradient(
            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Swipeable Game Card

struct SwipeableGameCard: View {
    let game: GamerConnectGame
    let isTopCard: Bool
    let stackIndex: Int
    let dragOffset: CGSize
    let dragRotation: Double
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onDragChanged: (CGSize, Double) -> Void
    let onDragEnded: () -> Void
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Game image
            GameSelectionCachedAsyncImage(url: game.displayImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    cardPlaceholder
                case .empty:
                    cardPlaceholder
                @unknown default:
                    cardPlaceholder
                }
            }
            .frame(width: 260, height: 340)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Game title
            Text(game.gameName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Swipe indicators
            if isTopCard {
                swipeIndicators
            }
        }
        .frame(width: 260, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .scaleEffect(cardScale)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .offset(x: isTopCard ? dragOffset.width : 0)
        .rotationEffect(.degrees(isTopCard ? dragRotation : 0))
        .gesture(
            isTopCard ?
            DragGesture()
                .onChanged { value in
                    let rotation = Double(value.translation.width / 20)
                    onDragChanged(value.translation, rotation)
                }
                .onEnded { value in
                    handleSwipeEnd(translation: value.translation)
                }
            : nil
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
    }
    
    private var cardPlaceholder: some View {
        LinearGradient(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var cardScale: CGFloat {
        switch stackIndex {
        case 0: return 1.0
        case 1: return 0.94
        case 2: return 0.88
        default: return 0.82
        }
    }
    
    private var cardOffset: CGFloat {
        switch stackIndex {
        case 0: return 0
        case 1: return 18
        case 2: return 36
        default: return 54
        }
    }
    
    private var cardOpacity: Double {
        switch stackIndex {
        case 0: return 1.0
        case 1: return 0.7
        case 2: return 0.4
        default: return 0.2
        }
    }
    
    @ViewBuilder
    private var swipeIndicators: some View {
        // Like indicator
        if dragOffset.width > 30 {
            Text("LIKE")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(GameSelectionColors.greenStart)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .rotationEffect(.degrees(15))
                .position(x: 220, y: 30)
                .opacity(min(Double(dragOffset.width) / 100, 1))
        }
        
        // Nope indicator
        if dragOffset.width < -30 {
            Text("NOPE")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .rotationEffect(.degrees(-15))
                .position(x: 40, y: 30)
                .opacity(min(Double(-dragOffset.width) / 100, 1))
        }
    }
    
    private func handleSwipeEnd(translation: CGSize) {
        if translation.width > swipeThreshold {
            withAnimation(.easeOut(duration: 0.3)) {
                onDragChanged(CGSize(width: 500, height: 0), 15)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipeRight()
                onDragEnded()
            }
        } else if translation.width < -swipeThreshold {
            withAnimation(.easeOut(duration: 0.3)) {
                onDragChanged(CGSize(width: -500, height: 0), -15)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipeLeft()
                onDragEnded()
            }
        } else {
            onDragEnded()
        }
    }
}

// MARK: - Skeleton Card View

struct SkeletonCardView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28)
                .fill(GameSelectionColors.skeletonBase)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(GameSelectionColors.skeletonHighlight)
                    .frame(width: 160, height: 24)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shimmer()
    }
}
