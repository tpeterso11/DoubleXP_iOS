//
//  RootView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

/// This is your new "root" view for the app (e.g., in your @main App struct).
/// It owns the ZStack that manages all overlays,
/// keeping your FeedView clean.
enum AppPhase {
    case preSplash
    case login
    case main
}

struct RootView: View {
    
    @Namespace private var gameTransitionNamespace
    @State private var selectedGame: GamerConnectGame? = nil
    @State private var appPhase: AppPhase = .preSplash
    
    // Bottom navigation state
    @State private var selectedTabID: String = "home"
    @State private var shouldAnimateProfileAvatar: Bool = true
    
    // Edit profile sheet state
    @State private var isShowingEditProfile = false
    
    // Chat sheet state
    @State private var isShowingChat = false
    
    // Discover sheet state
    @State private var isShowingDiscover = false
    
    // Challenges/Compete sheet state
    @State private var isShowingChallenges = false
    
    @Namespace private var gameDetailNamespace
    @Environment(\.scenePhase) private var scenePhase
    
    // Get current user's avatar URL
    private var profileAvatarUrl: URL? {
        // TODO: Replace with actual poko avatar URL from current user
        return nil
    }
    
    // Hides the native tab bar so we can use our custom one
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        mainContent
            .animation(.easeInOut(duration: 0.45), value: appPhase)
            .sheet(isPresented: $isShowingEditProfile) {
                NavigationStack {
                    EditProfileView()
                }
            }
            .fullScreenCover(isPresented: $isShowingChat) {
                ChatListView()
            }
            .fullScreenCover(isPresented: $isShowingDiscover) {
                discoverView
            }
            .fullScreenCover(isPresented: $isShowingChallenges) {
                NavigationStack {
                    ChallengesView()
                }
            }
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // LEVEL UP CELEBRATION OVERLAY
            // This appears on top of everything when user levels up
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            .overlay(LevelUpCelebrationOverlay())
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            .onChange(of: selectedTabID) { _, newTab in
                handleTabChange(newTab)
            }
            .onChange(of: isShowingDiscover) { _, isPresented in
                handleDiscoverChange(isPresented)
            }
            .onChange(of: isShowingChat) { _, isPresented in
                handleChatChange(isPresented)
            }
            .onChange(of: isShowingChallenges) { _, isPresented in
                handleChallengesChange(isPresented)
            }
            .onChange(of: selectedGame) { _, game in
                handleGameDetailChange(game != nil)
            }
            .onChange(of: appPhase) { _, newPhase in
                handleAppPhaseChange(newPhase)
            }
            .onChange(of: scenePhase) { _, phase in
                handleScenePhaseChange(phase)
            }
    }

    // MARK: - Main Content View

    private var mainContent: some View {
        ZStack {
            // MARK: - Main App Content
            if appPhase == .main {
                mainAppContent
            }
            
            // MARK: - Login Flow
            if appPhase == .login {
                LoginView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        appPhase = .main
                    }
                }
                .transition(.opacity)
            }
            
            // MARK: - Pre-Splash
            if appPhase == .preSplash {
                PreSplashView { isReturning in
                    withAnimation(.easeInOut(duration: 0.45)) {
                        appPhase = isReturning ? .main : .login
                    }
                }
                .transition(.opacity)
            }
            
            // MARK: - Game Detail View (Only when selectedGame exists)
            if let game = selectedGame {
                gameDetailView(game: game)
                    .zIndex(100)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
    }

    // MARK: - Main App Content

    private var mainAppContent: some View {
        ZStack(alignment: .bottom) {
            // 1. The Stable Engine: Native TabView
            TabView(selection: $selectedTabID) {
                homeTab
                profileTab
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            
            // 2. Custom Bottom Menu (Floating on Top)
            BottomMenuView(
                selectedID: $selectedTabID,
                profileAvatarUrl: profileAvatarUrl,
                shouldAnimateProfileAvatar: $shouldAnimateProfileAvatar,
                onDiscoverTapped: {
                    isShowingDiscover = true
                },
                onMessagesTapped: {
                    isShowingChat = true
                },
                onCompeteTapped: {
                    isShowingChallenges = true
                }
            )
            .ignoresSafeArea(.keyboard)
        }
        .transition(.opacity)
    }

    // MARK: - Tab Views

    private var homeTab: some View {
        FeedView(
            isActive: .constant(selectedTabID == "home" && selectedGame == nil && !isShowingDiscover && !isShowingChat && !isShowingChallenges),
            namespace: gameTransitionNamespace,
            onGameTapped: { game in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selectedGame = game
                }
            }
        )
        .tag("home")
        .toolbar(.hidden, for: .tabBar)
    }

    private var profileTab: some View {
        ZStack {
            if let currentUser = UserProvider.shared.currentUser {
                UserProfileView(
                    uid: currentUser.uId,
                    onBack: {
                        selectedTabID = "home"
                    },
                    onEditProfile: {
                        isShowingEditProfile = true
                    },
                    onGameSelected: { gameItem in
                        print("🔍 onGameSelected called with \(gameItem.name)")
                        if let fullGame = GameStorageManager.shared.getGame(slug: gameItem.slug) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                selectedGame = fullGame
                            }
                        } else {
                            print("⚠️ Could not find GamerConnectGame for id \(gameItem.slug)")
                        }
                    }
                )
            } else {
                ProgressView().tint(.white)
            }
        }
        .tag("profile")
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Discover View

    private var discoverView: some View {
        DiscoverPageView(
            onDismiss: {
                isShowingDiscover = false
            }
            // Note: onGameTapped removed - Discover now handles its own navigation stack
            // Games, players, and communities open within Discover and can be dismissed
            // to return to the previous screen
        )
    }

    // MARK: - Game Detail View

    private func gameDetailView(game: GamerConnectGame) -> some View {
        GameDetailView(
            game: game,
            namespace: gameDetailNamespace,
            dominantColorTask: nil,
            onDismiss: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selectedGame = nil
                }
            }
        )
    }

    // MARK: - Change Handlers

    private func handleTabChange(_ newTab: String) {
        if newTab != "profile" {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }

    private func handleDiscoverChange(_ isPresented: Bool) {
        if isPresented {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }

    private func handleChatChange(_ isPresented: Bool) {
        if isPresented {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }
    
    private func handleChallengesChange(_ isPresented: Bool) {
        if isPresented {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }

    private func handleGameDetailChange(_ isPresented: Bool) {
        if isPresented {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }

    private func handleAppPhaseChange(_ newPhase: AppPhase) {
        if newPhase != .main {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase != .active {
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
    }
    
    // MARK: - Helpers
    private func makeDominantColorTask(for game: GamerConnectGame) -> Task<UIColor?, Never>? {
        guard
            let urlString = game.imageUrl,
            let url = URL(string: urlString)
        else {
            return nil
        }
        
        return Task.detached(priority: .background) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                
                return await ColorService.shared.findDominantColor(
                    for: image,
                    with: urlString
                )
            } catch {
                print("🔴 Failed to fetch image for dominant color: \(error)")
                return nil
            }
        }
    }
}
