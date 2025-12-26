//
//  ChallengesView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

// MARK: - Challenges View

struct ChallengesView: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @ObservedObject private var xpManager = XPManager.shared
    @Environment(\.dismiss) private var dismiss
    #if DEBUG
    @State private var showDebugDrawer = false
    #endif
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0D0D0D")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if viewModel.isLoading && viewModel.allCompetitions.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.allCompetitions.isEmpty {
                    errorView(error)
                } else {
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // XP Card
                            ChallengesXPCard()
                            
                            // Google Connection CTA
                            googleConnectionCard
                            
                            // Featured Section (if any)
                            if !viewModel.displayedFeatured.isEmpty {
                                featuredSection
                            }
                            
                            // My Game Challenges Section (with pink glow)
                            if !viewModel.displayedMyGameChallenges.isEmpty {
                                myGameChallengesSection
                            }
                            
                            // All Challenges Section (General)
                            allChallengesSection
                            
                            // Rules Card
                            rulesCard
                            
                            // Bottom spacing
                            Color.clear.frame(height: 100)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            
            // Competition Detail Popup
            if viewModel.showCompetitionDetail, let competition = viewModel.selectedCompetition {
                CompetitionDetailPopup(
                    competition: competition,
                    summary: viewModel.summary(for: competition.id),
                    onClose: { viewModel.closeDetail() },
                    onEnter: { /* Navigate to challenge page */ }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
            }
            
            // Google Connection Drawer
            if viewModel.showGoogleConnectionDrawer {
                GoogleConnectionDrawer(
                    isPresented: $viewModel.showGoogleConnectionDrawer,
                    onConnectionSuccess: {
                        viewModel.onGoogleConnectionSuccess()
                    }
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCompetitionDetail)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGoogleConnectionDrawer)
        .task {
            await viewModel.loadData()
        }
        .fullScreenCover(isPresented: $viewModel.showMoreFeatured) {
            MoreChallengesView(
                title: "Thirsty for more?",
                subtitle: "Featured & Sponsored Challenges",
                competitions: viewModel.featuredCompetitions,
                viewModel: viewModel
            )
        }
        .fullScreenCover(isPresented: $viewModel.showMoreMyGames) {
            MoreChallengesView(
                title: "Thirsty for more?",
                subtitle: "Challenges for Your Games",
                competitions: viewModel.myGameChallenges,
                viewModel: viewModel
            )
        }
        LevelUpCelebrationOverlay()
        // Debug Drawer
        #if DEBUG
        if showDebugDrawer {
            ChallengesDebugDrawer(isPresented: $showDebugDrawer)
                .transition(.opacity)
                .zIndex(100)
        }
        #endif
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Title (or search field)
                if viewModel.isSearching {
                    searchField
                } else {
                    VStack(spacing: 2) {
                        Text("Challenges")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(viewModel.allCompetitions.count) active")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // Search Button
                Button(action: { viewModel.toggleSearch() }) {
                    Image(systemName: viewModel.isSearching ? "xmark" : "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "0D0D0D")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            #if DEBUG
            Button(action: { showDebugDrawer = true }) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
            }
            #endif
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            
            TextField("Search challenges...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(maxWidth: 220)
    }
    
    // MARK: - Google Connection Card
    
    private var googleConnectionCard: some View {
        Button(action: {
            if !viewModel.isGoogleConnected {
                viewModel.showGoogleDrawer()
            }
        }) {
            HStack(spacing: 12) {
                // Google Icon
                Image(systemName: viewModel.isGoogleConnected ? "checkmark.circle.fill" : "link")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.isGoogleConnected ? Color(hex: "4ADE80") : Color(hex: "FF6B6B"))
                    .frame(width: 36, height: 36)
                    .background(
                        viewModel.isGoogleConnected
                            ? Color(hex: "4ADE80").opacity(0.15)
                            : Color(hex: "FF6B6B").opacity(0.15)
                    )
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isGoogleConnected ? "YouTube Connected" : "Connect YouTube")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(viewModel.isGoogleConnected ? "Ready for video challenges" : "Required for video submissions")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if !viewModel.isGoogleConnected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                viewModel.isGoogleConnected
                                    ? Color(hex: "4ADE80").opacity(0.2)
                                    : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isGoogleConnected)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Text("Featured")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("HOT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                
                Spacer()
                
                if viewModel.hasMoreFeatured {
                    Button(action: { viewModel.showMoreFeatured = true }) {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Featured Cards
            ForEach(viewModel.displayedFeatured) { competition in
                FeaturedChallengeCard(
                    competition: competition,
                    hasEntered: viewModel.hasEntered(competition.id),
                    entryStatus: viewModel.entryStatusText(for: competition.id)
                ) {
                    viewModel.selectCompetition(competition)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - My Game Challenges Section (with pink glow)
    
    private var myGameChallengesSection: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Text("My Game Challenges")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("🎮")
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                if viewModel.hasMoreMyGameChallenges {
                    Button(action: { viewModel.showMoreMyGames = true }) {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Game Challenge Cards with pink glow
            ForEach(viewModel.displayedMyGameChallenges) { competition in
                GameChallengeCard(
                    competition: competition,
                    hasEntered: viewModel.hasEntered(competition.id),
                    entryStatus: viewModel.entryStatusText(for: competition.id)
                ) {
                    viewModel.selectCompetition(competition)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - All Challenges Section (General)
    
    private var allChallengesSection: some View {
        VStack(spacing: 12) {
            // Section Header with Tabs
            HStack {
                Text("All Challenges")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Tab Pills
                HStack(spacing: 6) {
                    ForEach(ChallengeTab.allCases, id: \.self) { tab in
                        TabPill(
                            title: tab == .entered ? "\(tab.rawValue) (\(viewModel.enteredCount))" : tab.rawValue,
                            isSelected: viewModel.selectedTab == tab
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedTab = tab
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Challenge Cards
            if viewModel.filteredCompetitions.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredCompetitions) { competition in
                        ChallengeCard(
                            competition: competition,
                            hasEntered: viewModel.hasEntered(competition.id),
                            entryStatus: viewModel.entryStatusText(for: competition.id)
                        ) {
                            viewModel.selectCompetition(competition)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.selectedTab == .entered ? "trophy" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text(viewModel.selectedTab == .entered ? "No Entries Yet" : "No Challenges Found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Text(viewModel.selectedTab == .entered ? "Enter a challenge to see it here" : "Try a different search term")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Rules Card
    
    private var rulesCard: some View {
        Button(action: {
            // Show rules sheet
        }) {
            HStack {
                Text("📋")
                    .font(.system(size: 16))
                
                Text("Official Rules & Disclaimers")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("View")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading challenges...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await viewModel.loadData() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(hex: "FF6B6B"))
            .cornerRadius(12)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Game Challenge Card (with pink glow)

struct GameChallengeCard: View {
    let competition: Competition
    let hasEntered: Bool
    let entryStatus: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Image with pink glow
                ZStack {
                    // Pink glow behind
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "FF6B6B").opacity(0.3))
                        .blur(radius: 12)
                        .frame(width: 80, height: 80)
                        .offset(x: 2, y: 2)
                    
                    // Image
                    AsyncImage(url: URL(string: competition.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Rectangle()
                                .fill(Color(hex: "2d2d4e"))
                                .overlay(
                                    Text(competition.type.icon)
                                        .font(.system(size: 24))
                                )
                        case .empty:
                            Rectangle()
                                .fill(Color(hex: "2d2d4e"))
                                .overlay(
                                    ProgressView()
                                        .tint(.white.opacity(0.5))
                                        .scaleEffect(0.8)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color(hex: "2d2d4e"))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(14)
                    .clipped()
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    // Type Tag
                    Text(competition.type.displayName.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "FF6B6B").opacity(0.15))
                        .cornerRadius(6)
                    
                    // Title
                    Text(competition.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Description
                    Text(competition.description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                    
                    Spacer(minLength: 0)
                    
                    // Bottom Row
                    HStack {
                        // XP
                        Text("+\(competition.xpReward) XP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "4ADE80"))
                        
                        Spacer()
                        
                        // Status
                        if hasEntered, let status = entryStatus {
                            Text(status)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "4ADE80"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "4ADE80").opacity(0.15))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "4ADE80").opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Text(competition.timeRemaining)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "FF6B6B").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ChallengeCardButtonStyle())
    }
}

// MARK: - More Challenges View ("Thirsty for more?")

struct MoreChallengesView: View {
    let title: String
    let subtitle: String
    let competitions: [Competition]
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 24)
                
                // List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(competitions) { competition in
                            ChallengeCard(
                                competition: competition,
                                hasEntered: viewModel.hasEntered(competition.id),
                                entryStatus: viewModel.entryStatusText(for: competition.id)
                            ) {
                                viewModel.selectCompetition(competition)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Tab Pill

struct TabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? Color(hex: "FF6B6B").opacity(0.15)
                        : Color.white.opacity(0.05)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color(hex: "FF6B6B").opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedChallengeCard: View {
    let competition: Competition
    let hasEntered: Bool
    let entryStatus: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Background Image
                AsyncImage(url: URL(string: competition.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                            .overlay(
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                    }
                }
                .frame(height: 180)
                .clipped()
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Badge
                tierBadge
                    .padding(12)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Type
                    Text(competition.type.displayName.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Color(hex: "FF6B6B"))
                    
                    // Title
                    Text(competition.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.top, 4)
                    
                    // Description
                    Text(competition.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .padding(.top, 4)
                    
                    // Meta
                    HStack {
                        // XP Reward
                        Text("+\(competition.xpReward) XP")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "4ADE80"))
                        
                        Spacer()
                        
                        // Status / Time
                        if hasEntered, let status = entryStatus {
                            Text(status)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "4ADE80"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "4ADE80").opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "4ADE80").opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Text(competition.timeRemaining)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(16)
            }
            .frame(height: 180)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(tierBorderColor, lineWidth: competition.isFeatured ? 2 : 1)
            )
            .shadow(color: tierShadowColor, radius: 20, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tierBadge: some View {
        HStack(spacing: 4) {
            Text(competition.isFeatured ? "⭐" : "💎")
                .font(.system(size: 10))
            
            Text(competition.isFeatured ? "FEATURED" : "SPONSORED")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(competition.isFeatured ? .black : Color(hex: "00D2FF"))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            competition.isFeatured
                ? LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color(hex: "00D2FF").opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(competition.isSponsored ? Color(hex: "00D2FF").opacity(0.4) : .clear, lineWidth: 1)
        )
    }
    
    private var tierBorderColor: Color {
        if competition.isFeatured {
            return Color(hex: "FFD700").opacity(0.4)
        } else if competition.isSponsored {
            return Color(hex: "00D2FF").opacity(0.4)
        }
        return Color.white.opacity(0.1)
    }
    
    private var tierShadowColor: Color {
        if competition.isFeatured {
            return Color(hex: "FFD700").opacity(0.15)
        } else if competition.isSponsored {
            return Color(hex: "00D2FF").opacity(0.15)
        }
        return Color.black.opacity(0.2)
    }
}

// MARK: - Challenge Card (Regular)

struct ChallengeCard: View {
    let competition: Competition
    let hasEntered: Bool
    let entryStatus: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Image
                AsyncImage(url: URL(string: competition.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                            .overlay(
                                Text(competition.type.icon)
                                    .font(.system(size: 24))
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                            .overlay(
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                                    .scaleEffect(0.8)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color(hex: "2d2d4e"))
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(14)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    // Tags
                    HStack(spacing: 6) {
                        // Type Tag
                        Text(competition.type.displayName.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "FF6B6B"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "FF6B6B").opacity(0.15))
                            .cornerRadius(6)
                        
                        // Tier Badge (if not regular)
                        if competition.isFeatured || competition.isSponsored {
                            tierBadge
                        }
                    }
                    
                    // Title
                    Text(competition.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Description
                    Text(competition.description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                    
                    Spacer(minLength: 0)
                    
                    // Bottom Row
                    HStack {
                        // XP
                        Text("+\(competition.xpReward) XP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "4ADE80"))
                        
                        Spacer()
                        
                        // Status
                        if hasEntered, let status = entryStatus {
                            Text(status)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "4ADE80"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "4ADE80").opacity(0.15))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "4ADE80").opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Text(competition.timeRemaining)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ChallengeCardButtonStyle())
    }
    
    @ViewBuilder
    private var tierBadge: some View {
        if competition.isFeatured {
            HStack(spacing: 2) {
                Text("⭐")
                    .font(.system(size: 8))
                Text("FEATURED")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(6)
        } else if competition.isSponsored {
            HStack(spacing: 2) {
                Text("💎")
                    .font(.system(size: 8))
                Text("SPONSORED")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundColor(Color(hex: "00D2FF"))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: "00D2FF").opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "00D2FF").opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var borderColor: Color {
        if competition.isFeatured {
            return Color(hex: "FFD700").opacity(0.3)
        } else if competition.isSponsored {
            return Color(hex: "00D2FF").opacity(0.3)
        }
        return Color.white.opacity(0.1)
    }
}

// MARK: - Button Style

struct ChallengeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
