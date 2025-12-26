//
//  UserProfile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import UIKit
import SwiftEntryKit

struct UserProfile {
    let id: String
    let username: String
    let handle: String
    let isOnline: Bool
    let headerImageURL: String?
    let headerVideoURL: String?
    let pokoAvatar: String
    let pokoName: String
    let bio: String?
    let followerCount: Int
    let followingCount: Int
    let gamesCount: Int
    let isOwnProfile: Bool
    let isFollowing: Bool
    
    let socials: [SocialLink]
    let lookingFor: [String]
    let aboutMe: [AboutMeTag]
    let badges: [Badge]
    let games: [GameItem]
    let wishlistGames: [GameItem]
    let pokos: [Poko]
    let recentUploads: [ContentItem]
    let commonGames: [GameItem]
    let communities: [ProfileCommunity]
    
    var matchCount: Int {
        aboutMe.filter { $0.isMatch }.count
    }
    
    var highlightedVideo: String?
    
    // NEW: Quiz data
    let quizzes: [ProfileQuizItem]
    
    // NEW: Proximity data
    let proximityDistance: Double? // Distance in miles, nil if not near or location disabled
}

struct SocialLink: Identifiable {
    let id = UUID()
    let platform: SocialPlatform
    let handle: String
}

enum SocialPlatform {
    case discord, twitter, instagram, tiktok, twitch
    
    var iconName: String {
        switch self {
        case .discord: return "discord_icon"
        case .twitter: return "x_icon"
        case .instagram: return "instagram_icon"
        case .tiktok: return "tiktok_icon"
        case .twitch: return "twitch_icon"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .discord: return .purple
        case .twitter: return .black
        case .instagram: return .pink
        case .tiktok: return .black
        case .twitch: return .purple
        }
    }
}

struct AboutMeTag: Identifiable {
    let id = UUID()
    let text: String
    let isMatch: Bool
}

struct Badge: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let tier: BadgeTier
}

enum BadgeTier {
    case gold, silver, bronze, special
    
    var gradientColors: [Color] {
        switch self {
        case .gold: return [Color.yellow, Color.orange]
        case .silver: return [Color.gray, Color.gray]
        case .bronze: return [Color.brown, Color.brown]
        case .special: return [Color.purple, Color.purple]
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GameItem: Identifiable {
    let id: String
    let name: String
    let coverImage: String
    let slug: String
}

// Note: PokoThumbnail now uses the Poko model directly from your codebase

struct ContentItem: Identifiable {
    let id = UUID()
    let thumbnailImage: String
    let isVideo: Bool
}

// MARK: - Main Profile View

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var showStickyHeader: Bool = false
    @State private var heroPokoImage: UIImage?
    @State private var showAllGames = false
    @State private var isHeaderVideoPlaying = true
    @State private var selectedVideo: ProfileVideo? = nil
    @State private var selectedCommunity: ProfileCommunity? = nil
    @State private var selectedQuiz: ProfileQuizItem? = nil
    
    private let headerHeight: CGFloat = 300
    private var onBack: (() -> Void)?
    private var onEditProfile: (() -> Void)?
    private var onGameSelected: ((GameItem) -> Void)?
    
    // MARK: - Initializers
    
    init(
        uid: String,
        onBack: (() -> Void)? = nil,
        onEditProfile: (() -> Void)? = nil,
        onGameSelected: ((GameItem) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(uid: uid))
        self.onBack = onBack
        self.onEditProfile = onEditProfile
        self.onGameSelected = onGameSelected
    }
    
    init(
        onBack: (() -> Void)? = nil,
        onEditProfile: (() -> Void)? = nil,
        onGameSelected: ((GameItem) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel())
        self.onBack = onBack
        self.onEditProfile = onEditProfile
        self.onGameSelected = onGameSelected
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error: error)
            } else if let profile = viewModel.userProfile {
                profileContent(profile: profile)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            Task {
                await viewModel.loadProfile()
            }
        }
        .onChange(of: viewModel.userProfile?.pokoAvatar) { newValue in
            Task {
                await loadHeroPokoImage(urlString: newValue)
            }
        }
        .onDisappear {
            // Pauses the header player via the representable
            isHeaderVideoPlaying = false
            YouTubePlaybackCoordinator.shared.pauseAll()
        }
        .fullScreenCover(item: $selectedVideo) { video in
             FullScreenVideoPlayerView(video: video)
         }
        .fullScreenCover(item: $selectedCommunity) { community in
             // Present your CommunityPageView here
             /*CommunityPageView(
                game: <#GamerConnectGame#>, communityId: community.id,
                 onDismiss: {
                     selectedCommunity = nil
                 }
             )*/
         }
        .fullScreenCover(isPresented: $showAllGames) {
            if let profile = viewModel.userProfile {
                UserGamesGridView(
                    games: profile.games,
                    username: profile.username,
                    onGameSelected: onGameSelected,
                    onDismiss: {
                        showAllGames = false
                    }
                )
            }
        }
        .fullScreenCover(item: $selectedQuiz) { quiz in
            QuizDetailView(
                quiz: quiz,
                isOwnProfile: viewModel.userProfile?.isOwnProfile ?? false
            )
        }
    }
    
    private func loadHeroPokoImage(urlString: String?) async {
        guard let urlString = urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            heroPokoImage = nil
            return
        }
        heroPokoImage = await ImageCache.shared.image(for: url)
    }
    
    private func handleBack() {
        if let onBack = onBack {
            onBack()
        } else {
            dismiss()
        }
    }
    
    /*private func videosSection(profile: UserProfile) -> some View {
             ProfileVideosSectionView(
                 videos: profile.nonHighlightedVideos, // Exclude highlighted (it's in header)
                 onVideoTapped: { video in
                     selectedVideo = video
                 }
             )
     }*/
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading profile...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 16)
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 16)
            Button("Try Again") {
                Task {
                    await viewModel.loadProfile()
                }
            }
            .padding(.top, 24)
            .foregroundColor(.white)
            Spacer()
        }
    }
    
    // MARK: - Profile Content
    
    private func profileContent(profile: UserProfile) -> some View {
        ZStack(alignment: .top) {
            scrollableContent(profile: profile)
            
            if showStickyHeader {
                stickyHeader(profile: profile)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func scrollableContent(profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection(profile: profile)
                
                if profile.isOnline {
                    onlineIndicator
                }
                
                bodyContent(profile: profile)
            }
            .background(scrollOffsetReader)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ProfileScrollOffsetKey.self) { value in
            scrollOffset = value
            showStickyHeader = value < -200
        }
    }
    
    private var scrollOffsetReader: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ProfileScrollOffsetKey.self,
                value: geo.frame(in: .named("scroll")).minY
            )
        }
    }
    
    private func bodyContent(profile: UserProfile) -> some View {
        VStack(spacing: 24) {
            if !profile.socials.isEmpty {
                socialsSection(profile: profile)
            }
            
            statsSection(profile: profile)
            
            if !profile.lookingFor.isEmpty {
                lookingForSection(profile: profile)
            }
            
            if !profile.aboutMe.isEmpty {
                aboutMeSection(profile: profile)
            }
            
            if let bio = profile.bio, !bio.isEmpty {
                bioSection(bio: bio)
            }
            
            if !profile.badges.isEmpty {
                badgesSection(profile: profile)
            }
            
            if !profile.communities.isEmpty {
                communitiesSection(profile: profile)
            }
            
            if !profile.games.isEmpty {
                gamesSection(profile: profile)
            }
            
            if !profile.wishlistGames.isEmpty {
                wishlistGamesSection(profile: profile)
            }
            
            if !profile.quizzes.isEmpty {
                quizzesSection(profile: profile)
            }
            
            if !profile.pokos.isEmpty {
                pokosSection(profile: profile)
            }
            
            if !profile.recentUploads.isEmpty {
                recentUploadsSection(profile: profile)
            }
            
            if !profile.commonGames.isEmpty && !profile.isOwnProfile {
                commonGamesSection(profile: profile)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 100) // Increased from 40 to 100 to account for bottom menu
    }
    
    // MARK: - Hero Section
    
    private func heroSection(profile: UserProfile) -> some View {
        ZStack(alignment: .bottom) {
            heroBackground(profile: profile)
            heroGradientOverlay
            heroTopBar
            heroContent(profile: profile)
        }
    }
    
    private func quizzesSection(profile: UserProfile) -> some View {
        ProfileQuizzesSection(
            quizzes: profile.quizzes,
            username: profile.username,
            isOwnProfile: profile.isOwnProfile,
            proximityDistance: profile.proximityDistance,
            onQuizTapped: { quiz in
                selectedQuiz = quiz
            }
        )
    }
    
    private func communitiesSection(profile: UserProfile) -> some View {
         ProfileCommunitiesSectionView(
             communities: profile.communities,
             onCommunityTapped: { community in
                 selectedCommunity = community
             }
         )
     }
    
    private func heroBackground(profile: UserProfile) -> some View {
         ProfileHeroBackgroundView(
             profile: profile,
             highlightedVideo: profile.highlightedVideo,
             headerHeight: headerHeight,
             isVideoPlaying: $isHeaderVideoPlaying
         )
     }
    
    private var heroBackgroundGradient: some View {
        let colors = [Color.gray, Color.black]
        return Rectangle().fill(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
    
    private var heroPlaceholderIcon: some View {
        Image(systemName: "gamecontroller.fill")
            .font(.system(size: 60))
            .foregroundColor(.white.opacity(0.1))
    }
    
    private var videoBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
            Text("GAMEPLAY")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.7))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 60)
        .padding(.trailing, 16)
    }
    
    private var heroGradientOverlay: some View {
        LinearGradient(
            colors: [.black, .black.opacity(0.6), .clear],
            startPoint: .bottom,
            endPoint: .top
        )
        .frame(height: headerHeight)
    }
    
    private var heroTopBar: some View {
        HStack {
            backButton
            Spacer()
            menuButton
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 50)
    }
    
    private var backButton: some View {
        Button(action: { handleBack() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    private var menuButton: some View {
        Button(action: {}) {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    private func heroContent(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Avatar + Name row
            HStack(alignment: .center, spacing: 16) {
                pokoAvatar(profile: profile)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.username)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(profile.handle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            actionButtons(profile: profile)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }
    
    private func pokoAvatar(profile: UserProfile) -> some View {
        ZStack(alignment: .bottom) {
            pokoAvatarRing(profile: profile)
            pokoBadge
        }
    }
    
    private func pokoAvatarRing(profile: UserProfile) -> some View {
        // Gradient ring around the avatar
        let ringGradient = LinearGradient(
            colors: [Color.red, Color.orange, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Circle()
            .stroke(ringGradient, lineWidth: 3)
            .frame(width: 84, height: 84)
            .background(
                Circle()
                    .fill(Color.black)
                    .frame(width: 78, height: 78)
            )
            .overlay(pokoAvatarContent(profile: profile))
    }
    
    @ViewBuilder
    private func pokoAvatarContent(profile: UserProfile) -> some View {
        if let image = heroPokoImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            pokoPlaceholder
        }
    }
    
    private var pokoPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 32))
            .foregroundColor(.white.opacity(0.3))
    }
    
    private var pokoBadge: some View {
        let gradientColors = [Color.red, Color.orange]
        let gradient = LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        
        return Text("POKO")
            .font(.system(size: 8, weight: .heavy))
            .tracking(1)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(gradient)
            .clipShape(Capsule())
            .offset(y: 6)
    }
    
    private func actionButtons(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            if profile.isOwnProfile {
                editProfileButton
            } else {
                followButton(isFollowing: profile.isFollowing)
                messageButton
            }
        }
    }
    
    private var editProfileButton: some View {
        Button(action: {
            onEditProfile?()
        }) {
            Text("Edit Profile")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
    
    private func followButton(isFollowing: Bool) -> some View {
        Button(action: { viewModel.followUser() }) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isFollowing ? .white : .black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(isFollowing ? .white.opacity(0.15) : .white)
                .clipShape(Capsule())
        }
    }
    
    private var messageButton: some View {
        Button(action: { viewModel.openMessaging() }) {
            Text("Message")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Online Indicator
    
    private var onlineIndicator: some View {
        HStack(spacing: 8) {
            onlineDot
            
            Text("Online Now")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(onlineIndicatorBackground)
    }
    
    private var onlineDot: some View {
        Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
            .shadow(color: .green.opacity(0.6), radius: 4)
    }
    
    private var onlineIndicatorBackground: some View {
        let startColor = Color.green.opacity(0.1)
        let endColor = Color.green.opacity(0.15)
        return LinearGradient(colors: [startColor, endColor], startPoint: .leading, endPoint: .trailing)
    }
    
    // MARK: - Sticky Header
    
    private func stickyHeader(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            backButton
            
            Text(profile.username)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            miniPokoAvatar
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 16)
        .background(.black.opacity(0.9))
        .background(.ultraThinMaterial)
    }
    
    private var miniPokoAvatar: some View {
        let gradientColors = [Color.gray, Color.black]
        let gradient = LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        
        return RoundedRectangle(cornerRadius: 8)
            .fill(gradient)
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
    
    // MARK: - Socials Section
    
    private func socialsSection(profile: UserProfile) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(profile.socials) { social in
                    SocialChip(social: social)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private func statsSection(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            StatBadge(value: formatCount(profile.followerCount), label: "Followers")
            StatBadge(value: formatCount(profile.followingCount), label: "Following")
            StatBadge(value: "\(profile.gamesCount)", label: "Games")
        }
    }
    
    // MARK: - Looking For Section
    
    private func lookingForSection(profile: UserProfile) -> some View {
        InfoBlock(title: "Looking For") {
            FlowLayout(spacing: 8) {
                ForEach(profile.lookingFor, id: \.self) { item in
                    LookingForTag(text: item)
                }
            }
        }
    }
    
    // MARK: - About Me Section
    
    private func aboutMeSection(profile: UserProfile) -> some View {
        InfoBlock(title: "About Me") {
            VStack(alignment: .leading, spacing: 14) {
                aboutMeTags(profile: profile)
                
                if profile.matchCount > 0 && !profile.isOwnProfile {
                    matchIndicator(count: profile.matchCount)
                }
            }
        }
    }
    
    private func aboutMeTags(profile: UserProfile) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(profile.aboutMe) { tag in
                AboutMeTagView(tag: tag)
            }
        }
    }
    
    private func matchIndicator(count: Int) -> some View {
        HStack(spacing: 10) {
            matchCheckmark
            
            Text("\(count) matches with you!")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var matchCheckmark: some View {
        ZStack {
            Circle()
                .fill(.green.opacity(0.2))
                .frame(width: 24, height: 24)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
        }
    }
    
    // MARK: - Bio Section
    
    private func bioSection(bio: String) -> some View {
        InfoBlock(title: "Bio") {
            Text(bio)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
        }
    }
    
    // MARK: - Badges Section
    
    private func badgesSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BADGES EARNED")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 12) {
                ForEach(profile.badges) { badge in
                    BadgeView(badge: badge)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Games Section
    
    private func gamesSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Custom header with action
            HStack {
                Text("GAMES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if profile.games.count > 8 {
                    Button(action: {
                        showAllGames = true
                    }) {
                        Text("See All \(profile.gamesCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            gamesGrid(games: profile.games)
        }
    }
    
    // MARK: - Wishlist Games Section
    
    private func wishlistGamesSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Custom header
            HStack {
                Text("GAMES I WANT")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
            
            wishlistGamesGrid(games: profile.wishlistGames)
        }
    }
    
    private func wishlistGamesGrid(games: [GameItem]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(games.prefix(8)) { game in
                GameThumbnail(game: game)
                    .onTapGesture {
                        onGameSelected?(game)
                    }
            }
        }
    }
    
    private func gamesGrid(games: [GameItem]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(games.prefix(8)) { game in
                GameThumbnail(game: game)
                    .onTapGesture {
                        onGameSelected?(game)
                    }
            }
        }
    }
    
    // MARK: - Pokos Section
    
    private func pokosSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MY POKOS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if profile.pokos.count > 8 {
                    Button(action: {}) {
                        Text("See All \(profile.pokos.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.red)
                    }
                }
            }
            
            pokosGrid(pokos: profile.pokos, isOwnProfile: profile.isOwnProfile)
        }
    }
    
    private func pokosGrid(pokos: [Poko], isOwnProfile: Bool) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(pokos.prefix(4), id: \.id) { poko in
                PokoThumbnail(poko: poko)
                    .onTapGesture {
                        showPokoDetail(poko: poko, isOwnProfile: isOwnProfile)
                    }
            }
        }
    }
    
    private func showPokoDetail(poko: Poko, isOwnProfile: Bool) {
        // Check if current user owns this poko
        let isOwned: Bool = {
            guard let currentUser = UserProvider.shared.currentUser else { return false }
            return currentUser.pokos.contains(where: { $0 == poko.id })
        }()
        
        PopupManager.showPokoDetail(
            poko: poko,
            isOwned: isOwned || isOwnProfile, // If viewing own profile, they own it
            isOwnProfile: isOwnProfile,
            onAdd: {
                // TODO: Add poko to user's collection
                print("Adding \(poko.name) to collection")
                Task {
                    await addPokoToCollection(poko: poko)
                }
            },
            onSetActive: {
                // TODO: Set this poko as active
                print("Setting \(poko.name) as active")
                Task {
                    await setPokoAsActive(poko: poko)
                }
            },
            onDismiss: {
                print("Poko detail dismissed")
            }
        )
    }
    
    private func addPokoToCollection(poko: Poko) async {
        // TODO: Implement adding poko to user's collection in Firebase
        // Example:
        // await PokoProvider.shared.addPokoToUser(poko: poko)
    }
    
    private func setPokoAsActive(poko: Poko) async {
        // TODO: Implement setting poko as active in Firebase
        // Example:
        // await PokoProvider.shared.setActivePoko(poko: poko)
    }
    
    // MARK: - Recent Uploads Section
    
    private func recentUploadsSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "RECENT UPLOADS", actionText: "See All", color: .blue)
            
            uploadsGrid(items: profile.recentUploads)
        }
    }
    
    private func uploadsGrid(items: [ContentItem]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(items.prefix(6)) { item in
                ContentThumbnail(item: item)
            }
        }
    }
    
    // MARK: - Common Games Section
    
    private func commonGamesSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            commonGamesHeader(count: profile.commonGames.count)
            commonGamesList(games: profile.commonGames)
        }
        .padding(20)
        .background(.green.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func commonGamesHeader(count: Int) -> some View {
        HStack(spacing: 10) {
            Text("🎮")
                .font(.system(size: 20))
            
            Text("Games You Both Play")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.green.opacity(0.2))
                .clipShape(Capsule())
        }
    }
    
    private func commonGamesList(games: [GameItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(games) { game in
                    CommonGameThumbnail(game: game)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, actionText: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            Button(action: {}) {
                Text(actionText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Supporting Views

struct LookingForTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.blue.opacity(0.15))
            .overlay(tagBorder)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var tagBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(.blue.opacity(0.3), lineWidth: 1)
    }
}

struct AboutMeTagView: View {
    let tag: AboutMeTag
    
    private var tagColor: Color {
        tag.isMatch ? .green : .orange
    }
    
    var body: some View {
        Text(tag.text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(tagColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(tagColor.opacity(0.15))
            .overlay(tagBorder)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var tagBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(tagColor.opacity(0.3), lineWidth: 1)
    }
}

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        Text(badge.emoji)
            .font(.system(size: 26))
            .frame(width: 54, height: 54)
            .background(badge.tier.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: shadowColor, radius: shadowRadius)
    }
    
    private var shadowColor: Color {
        badge.tier == .gold ? .orange.opacity(0.3) : .clear
    }
    
    private var shadowRadius: CGFloat {
        badge.tier == .gold ? 8 : 0
    }
}

struct CommonGameThumbnail: View {
    let game: GameItem
    
    var body: some View {
        VStack(spacing: 6) {
            thumbnailImage
            thumbnailLabel
        }
    }
    
    private var thumbnailImage: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.15))
            .frame(width: 60, height: 80)
            .overlay(thumbnailBorder)
            .overlay(thumbnailIcon)
    }
    
    private var thumbnailBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(.green.opacity(0.4), lineWidth: 2)
    }
    
    private var thumbnailIcon: some View {
        Image(systemName: "gamecontroller.fill")
            .foregroundColor(.white.opacity(0.3))
    }
    
    private var thumbnailLabel: some View {
        Text(game.name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(1)
            .frame(width: 60)
    }
}

struct SocialChip: View {
    let social: SocialLink
    
    var body: some View {
        HStack(spacing: 8) {
            socialIcon
            handleText
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08))
        .overlay(chipBorder)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var socialIcon: some View {
        Image(systemName: iconSystemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(social.platform.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var handleText: some View {
        Text(social.handle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
    }
    
    private var chipBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(.white.opacity(0.12), lineWidth: 1)
    }
    
    private var iconSystemName: String {
        switch social.platform {
        case .discord: return "bubble.left.fill"
        case .twitter: return "xmark"
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .twitch: return "tv.fill"
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            valueText
            labelText
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(badgeBorder)
    }
    
    private var valueText: some View {
        Text(value)
            .font(.system(size: 22, weight: .heavy))
            .foregroundColor(.white)
    }
    
    private var labelText: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundColor(.white.opacity(0.5))
    }
    
    private var badgeBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(.white.opacity(0.1), lineWidth: 1)
    }
}

struct InfoBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleText
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var titleText: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.white.opacity(0.5))
    }
}

struct GameThumbnail: View {
    let game: GameItem
    
    var body: some View {
        ZStack(alignment: .bottom) {
            thumbnailImageBackground
            thumbnailGradient
            thumbnailLabel
        }
        .aspectRatio(3/4, contentMode: .fit) // 3:4 card shape
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Layers
    
    /// Game art as the background (falls back to soft tint if no URL)
    private var thumbnailImageBackground: some View {
        Group {
            if let url = imageURL {
                CachedAsyncImageView(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            }
        }
    }
    
    /// Optional gradient over the bottom to help text readability
    private var thumbnailGradient: some View {
        LinearGradient(
            colors: [.black.opacity(0.85), .clear],
            startPoint: .bottom,
            endPoint: .top
        )
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
    
    private var thumbnailLabel: some View {
        Text(game.name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
    }
    
    // MARK: - Helpers
    
    private var imageURL: URL? {
        // Adjust property name if yours isn't `coverImage`
        guard !game.coverImage.isEmpty,
              let url = URL(string: game.coverImage) else {
            return nil
        }
        return url
    }
}


struct PokoThumbnail: View {
    let poko: Poko
    
    @State private var loadedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 6) {
            thumbnailImage
            pokoNameLabel
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let urlString = poko.imageUrl
        guard !urlString.isEmpty,
              let url = URL(string: urlString) else { return }
        
        if let image = await ImageCache.shared.image(for: url) {
            // Remove white background
            loadedImage = removeWhiteBackground(from: image)
        }
    }
    
    private func removeWhiteBackground(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        
        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255] // RGB threshold for "white"
        
        guard let maskedImage = cgImage.copy(maskingColorComponents: colorMasking) else {
            return image
        }
        
        return UIImage(cgImage: maskedImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private var thumbnailImage: some View {
        ZStack(alignment: .top) {
            // Background gradient (shows through transparent areas)
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.gray, Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Poko image
            Group {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            // Equipped badge
            if poko.currentPoko {
                VStack {
                    Text("EQUIPPED")
                        .font(.system(size: 7, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    poko.currentPoko ? Color.red.opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
    }
    
    private var pokoNameLabel: some View {
        Text(poko.name)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(poko.currentPoko ? Color.red : Color.white.opacity(0.7))
            .lineLimit(1)
    }
}

struct ContentThumbnail: View {
    let item: ContentItem
    
    var body: some View {
        ZStack {
            thumbnailBackground
            
            if item.isVideo {
                playIcon
            }
        }
    }
    
    private var thumbnailBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.white.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
    }
    
    private var playIcon: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 20))
            .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let position = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: position, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + lineHeight
        }
    }
}


extension PopupManager {
    
    /// Shows a Poko detail popup with game card styling
    /// - Parameters:
    ///   - poko: The Poko to display
    ///   - isOwned: Whether the current user already owns this poko
    ///   - isOwnProfile: Whether viewing your own profile (shows "Set as Active" instead of "Add")
    ///   - onAdd: Called when user taps "Add to My Pokos"
    ///   - onSetActive: Called when user taps "Set as Active Poko" (own profile, already owned)
    ///   - onDismiss: Called when popup is dismissed
    static func showPokoDetail(
        poko: Poko,
        isOwned: Bool,
        isOwnProfile: Bool,
        onAdd: @escaping () -> Void = {},
        onSetActive: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Configure attributes for pop animation
        var attributes = EKAttributes.centerFloat
        attributes.displayDuration = .infinity
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.4, radius: 16))
        attributes.roundCorners = .all(radius: 20)
        attributes.entryBackground = .color(color: EKColor(PokoPopupColors.background))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.5)))
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.positionConstraints.size = .init(width: .offset(value: 24), height: .intrinsic)
        
        // Pop animation
        attributes.entranceAnimation = .init(
            scale: .init(from: 0.8, to: 1, duration: 0.4, spring: .init(damping: 0.75, initialVelocity: 0)),
            fade: .init(from: 0, to: 1, duration: 0.25)
        )
        attributes.exitAnimation = .init(
            scale: .init(from: 1, to: 0.85, duration: 0.25),
            fade: .init(from: 1, to: 0, duration: 0.2)
        )
        
        let popupView = PokoDetailPopupView(
            poko: poko,
            isOwned: isOwned,
            isOwnProfile: isOwnProfile,
            onAdd: {
                SwiftEntryKit.dismiss()
                onAdd()
            },
            onSetActive: {
                SwiftEntryKit.dismiss()
                onSetActive()
            },
            onDismiss: {
                SwiftEntryKit.dismiss()
                onDismiss()
            }
        )
        
        SwiftEntryKit.display(entry: popupView, using: attributes)
    }
}

// MARK: - Colors

private enum PokoPopupColors {
    static let background = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1) // #0f0f0f
    static let heroGradientStart = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1) // #1a1a2e
    static let heroGradientMid = UIColor(red: 0.086, green: 0.13, blue: 0.24, alpha: 1) // #16213e
    static let heroGradientEnd = UIColor(red: 0.06, green: 0.2, blue: 0.38, alpha: 1) // #0f3460
    
    static let coral = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1) // #FF6B6B
    static let coralEnd = UIColor(red: 1.0, green: 0.56, blue: 0.33, alpha: 1) // #FF8E53
    
    static let green = UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1) // #4CD964
    static let greenEnd = UIColor(red: 0.18, green: 0.8, blue: 0.44, alpha: 1) // #2ECC71
    
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0, alpha: 1) // #FFD700
    static let goldEnd = UIColor(red: 1.0, green: 0.55, blue: 0, alpha: 1) // #FF8C00
    
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.white.withAlphaComponent(0.6)
    static let textTertiary = UIColor.white.withAlphaComponent(0.4)
    
    static let cardBackground = UIColor.white.withAlphaComponent(0.06)
}

// MARK: - Poko Detail Popup View

final class PokoDetailPopupView: UIView {
    
    private let poko: Poko
    private let isOwned: Bool
    private let isOwnProfile: Bool
    private let onAdd: () -> Void
    private let onSetActive: () -> Void
    private let onDismiss: () -> Void
    
    // MARK: - UI Elements
    
    private let heroContainer = UIView()
    private let pokoImageView = UIImageView()
    private let specialBadge = UIView()
    private let specialBadgeLabel = UILabel()
    private let popularityBadge = UIView()
    private let popularityLabel = UILabel()
    private let ownedBadge = UIView()
    private let ownedBadgeLabel = UILabel()
    
    private let contentContainer = UIView()
    private let titleRowStack = UIStackView()
    private let nameLabel = UILabel()
    private let priceTag = UILabel()
    private let typeBadge = UILabel()
    private let descriptionLabel = UILabel()
    
    private let buttonStack = UIStackView()
    private let dismissButton = UIButton(type: .system)
    private let primaryButton = UIButton(type: .system)
    
    // MARK: - Init
    
    init(
        poko: Poko,
        isOwned: Bool,
        isOwnProfile: Bool,
        onAdd: @escaping () -> Void,
        onSetActive: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.poko = poko
        self.isOwned = isOwned
        self.isOwnProfile = isOwnProfile
        self.onAdd = onAdd
        self.onSetActive = onSetActive
        self.onDismiss = onDismiss
        
        super.init(frame: .zero)
        setupView()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = PokoPopupColors.background
        layer.cornerRadius = 20
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        
        setupHeroSection()
        setupContentSection()
        setupButtons()
        setupConstraints()
    }
    
    private func setupHeroSection() {
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.clipsToBounds = true
        addSubview(heroContainer)
        
        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            PokoPopupColors.heroGradientStart.cgColor,
            PokoPopupColors.heroGradientMid.cgColor,
            PokoPopupColors.heroGradientEnd.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 400, height: 240)
        heroContainer.layer.insertSublayer(gradientLayer, at: 0)
        
        // Radial glow overlay
        let glowView = UIView()
        glowView.translatesAutoresizingMaskIntoConstraints = false
        glowView.backgroundColor = .clear
        heroContainer.addSubview(glowView)
        
        let glowLayer = CAGradientLayer()
        glowLayer.type = .radial
        glowLayer.colors = [
            PokoPopupColors.coral.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 1.2)
        glowLayer.endPoint = CGPoint(x: 1.2, y: 0.5)
        glowLayer.frame = CGRect(x: 0, y: 0, width: 400, height: 240)
        glowView.layer.addSublayer(glowLayer)
        
        NSLayoutConstraint.activate([
            glowView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            glowView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            glowView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            glowView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor)
        ])
        
        // Poko image
        pokoImageView.translatesAutoresizingMaskIntoConstraints = false
        pokoImageView.contentMode = .scaleAspectFit
        pokoImageView.layer.shadowColor = UIColor.black.cgColor
        pokoImageView.layer.shadowOffset = CGSize(width: 0, height: 20)
        pokoImageView.layer.shadowRadius = 40
        pokoImageView.layer.shadowOpacity = 0.4
        heroContainer.addSubview(pokoImageView)
        
        // Special edition badge
        specialBadge.translatesAutoresizingMaskIntoConstraints = false
        specialBadge.layer.cornerRadius = 12
        specialBadge.clipsToBounds = true
        specialBadge.isHidden = true
        heroContainer.addSubview(specialBadge)
        
        let specialGradient = CAGradientLayer()
        specialGradient.colors = [PokoPopupColors.gold.cgColor, PokoPopupColors.goldEnd.cgColor]
        specialGradient.startPoint = CGPoint(x: 0, y: 0)
        specialGradient.endPoint = CGPoint(x: 1, y: 1)
        specialGradient.frame = CGRect(x: 0, y: 0, width: 120, height: 28)
        specialBadge.layer.insertSublayer(specialGradient, at: 0)
        
        specialBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        specialBadgeLabel.text = "⭐ LIMITED"
        specialBadgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .heavy)
        specialBadgeLabel.textColor = .black
        specialBadge.addSubview(specialBadgeLabel)
        
        NSLayoutConstraint.activate([
            specialBadgeLabel.centerXAnchor.constraint(equalTo: specialBadge.centerXAnchor),
            specialBadgeLabel.centerYAnchor.constraint(equalTo: specialBadge.centerYAnchor)
        ])
        
        // Popularity badge
        popularityBadge.translatesAutoresizingMaskIntoConstraints = false
        popularityBadge.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        popularityBadge.layer.cornerRadius = 12
        popularityBadge.isHidden = true
        heroContainer.addSubview(popularityBadge)
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        popularityBadge.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: popularityBadge.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: popularityBadge.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: popularityBadge.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: popularityBadge.bottomAnchor)
        ])
        
        popularityLabel.translatesAutoresizingMaskIntoConstraints = false
        popularityLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        popularityLabel.textColor = .white
        popularityBadge.addSubview(popularityLabel)
        
        NSLayoutConstraint.activate([
            popularityLabel.centerXAnchor.constraint(equalTo: popularityBadge.centerXAnchor),
            popularityLabel.centerYAnchor.constraint(equalTo: popularityBadge.centerYAnchor)
        ])
        
        // Owned badge (top center, only shown when owned)
        ownedBadge.translatesAutoresizingMaskIntoConstraints = false
        ownedBadge.backgroundColor = PokoPopupColors.green.withAlphaComponent(0.2)
        ownedBadge.layer.cornerRadius = 14
        ownedBadge.layer.borderWidth = 1
        ownedBadge.layer.borderColor = PokoPopupColors.green.withAlphaComponent(0.4).cgColor
        ownedBadge.isHidden = true
        heroContainer.addSubview(ownedBadge)
        
        ownedBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        ownedBadgeLabel.text = "✓ In Your Collection"
        ownedBadgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        ownedBadgeLabel.textColor = PokoPopupColors.green
        ownedBadge.addSubview(ownedBadgeLabel)
        
        NSLayoutConstraint.activate([
            ownedBadgeLabel.topAnchor.constraint(equalTo: ownedBadge.topAnchor, constant: 8),
            ownedBadgeLabel.bottomAnchor.constraint(equalTo: ownedBadge.bottomAnchor, constant: -8),
            ownedBadgeLabel.leadingAnchor.constraint(equalTo: ownedBadge.leadingAnchor, constant: 14),
            ownedBadgeLabel.trailingAnchor.constraint(equalTo: ownedBadge.trailingAnchor, constant: -14)
        ])
    }
    
    private func startBobbingAnimation() {
        let bobAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        bobAnimation.fromValue = 0
        bobAnimation.toValue = -10
        bobAnimation.duration = 1.5
        bobAnimation.autoreverses = true
        bobAnimation.repeatCount = .infinity
        bobAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        pokoImageView.layer.add(bobAnimation, forKey: "bobbing")
    }
    
    private func setupContentSection() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)
        
        // Title row with name and price
        titleRowStack.translatesAutoresizingMaskIntoConstraints = false
        titleRowStack.axis = .horizontal
        titleRowStack.alignment = .center
        titleRowStack.distribution = .equalSpacing
        contentContainer.addSubview(titleRowStack)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = PokoPopupColors.textPrimary
        titleRowStack.addArrangedSubview(nameLabel)
        
        priceTag.translatesAutoresizingMaskIntoConstraints = false
        priceTag.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        priceTag.textColor = PokoPopupColors.green
        priceTag.backgroundColor = PokoPopupColors.green.withAlphaComponent(0.15)
        priceTag.layer.cornerRadius = 12
        priceTag.clipsToBounds = true
        priceTag.textAlignment = .center
        titleRowStack.addArrangedSubview(priceTag)
        
        // Type badge
        typeBadge.translatesAutoresizingMaskIntoConstraints = false
        typeBadge.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        typeBadge.textColor = PokoPopupColors.coral
        typeBadge.backgroundColor = PokoPopupColors.coral.withAlphaComponent(0.15)
        typeBadge.layer.cornerRadius = 8
        typeBadge.clipsToBounds = true
        typeBadge.textAlignment = .center
        contentContainer.addSubview(typeBadge)
        
        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = PokoPopupColors.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        contentContainer.addSubview(descriptionLabel)
    }
    
    private func setupButtons() {
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        contentContainer.addSubview(buttonStack)
        
        // Dismiss button
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle("CLOSE", for: .normal)
        dismissButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        dismissButton.setTitleColor(PokoPopupColors.textSecondary, for: .normal)
        dismissButton.backgroundColor = PokoPopupColors.cardBackground
        dismissButton.layer.cornerRadius = 14
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(dismissButton)
        
        // Primary button
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        primaryButton.layer.cornerRadius = 14
        primaryButton.clipsToBounds = true
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(primaryButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Hero section - increased height for more breathing room
            heroContainer.topAnchor.constraint(equalTo: topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroContainer.heightAnchor.constraint(equalToConstant: 240),
            
            // Poko image - centered with room for badge above
            pokoImageView.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            pokoImageView.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor, constant: 16),
            pokoImageView.widthAnchor.constraint(equalToConstant: 120),
            pokoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Special badge
            specialBadge.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 16),
            specialBadge.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            specialBadge.heightAnchor.constraint(equalToConstant: 28),
            
            // Popularity badge
            popularityBadge.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 16),
            popularityBadge.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -16),
            popularityBadge.heightAnchor.constraint(equalToConstant: 28),
            popularityBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Owned badge (centered at top with more padding)
            ownedBadge.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 20),
            ownedBadge.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            
            // Content section
            contentContainer.topAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            
            // Title row
            titleRowStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 24),
            titleRowStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            titleRowStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Price tag size
            priceTag.heightAnchor.constraint(equalToConstant: 32),
            priceTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Type badge
            typeBadge.topAnchor.constraint(equalTo: titleRowStack.bottomAnchor, constant: 12),
            typeBadge.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            typeBadge.heightAnchor.constraint(equalToConstant: 28),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: typeBadge.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Button stack
            buttonStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    // MARK: - Configure Content
    
    private func configureContent() {
        // Name
        nameLabel.text = poko.name
        
        // Type badge
        let typeText = "  \(poko.type.uppercased()) TYPE  "
        typeBadge.text = typeText
        
        // Description (fluff for now)
        descriptionLabel.text = getPokoDescription()
        
        // Price tag
        priceTag.text = "  Free  "
        
        // Load poko image
        if let url = URL(string: poko.imageUrl) {
            pokoImageView.loadImage(from: url)
        }
        
        // Special edition badge
        if poko.specialEdition == "true" {
            specialBadge.isHidden = false
        }
        
        // Popularity badge
        if poko.popular {
            popularityBadge.isHidden = false
            popularityLabel.text = "🔥 \(formatCount(poko.selectionCount))"
        }
        
        // Configure based on ownership state
        if isOwned {
            configureOwnedState()
        } else {
            configureNotOwnedState()
        }
        
        // Start the bobbing animation
        startBobbingAnimation()
    }
    
    private func configureOwnedState() {
        // Show owned badge
        ownedBadge.isHidden = false
        
        // Hide special badge if showing owned badge (to avoid clutter)
        if poko.specialEdition == "true" {
            specialBadge.isHidden = true
        }
        
        // Change price tag to show "Owned"
        priceTag.text = "  Owned  "
        priceTag.textColor = PokoPopupColors.green
        priceTag.backgroundColor = PokoPopupColors.green.withAlphaComponent(0.15)
        
        if isOwnProfile {
            // Own profile - show "Set as Active" button
            primaryButton.setTitle("SET AS ACTIVE", for: .normal)
            primaryButton.setTitleColor(.white, for: .normal)
            
            // Green gradient for own profile
            let gradient = CAGradientLayer()
            gradient.colors = [PokoPopupColors.green.cgColor, PokoPopupColors.greenEnd.cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            gradient.frame = CGRect(x: 0, y: 0, width: 200, height: 52)
            primaryButton.layer.insertSublayer(gradient, at: 0)
        } else {
            // Other's profile, but you own it too - just show close
            primaryButton.isHidden = true
            buttonStack.distribution = .fill
        }
    }
    
    private func configureNotOwnedState() {
        // Not owned - show "Add to My Pokos"
        primaryButton.setTitle("ADD TO MY POKOS", for: .normal)
        primaryButton.setTitleColor(.white, for: .normal)
        
        // Coral gradient
        let gradient = CAGradientLayer()
        gradient.colors = [PokoPopupColors.coral.cgColor, PokoPopupColors.coralEnd.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = CGRect(x: 0, y: 0, width: 200, height: 52)
        primaryButton.layer.insertSublayer(gradient, at: 0)
        
        // Add shadow to primary button
        primaryButton.layer.shadowColor = PokoPopupColors.coral.cgColor
        primaryButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        primaryButton.layer.shadowRadius = 16
        primaryButton.layer.shadowOpacity = 0.25
    }
    
    // MARK: - Helpers
    
    private func getPokoDescription() -> String {
        // Fluff descriptions based on type - replace with real data later
        let descriptions: [String: String] = [
            "mystic": "A mysterious creature touched by ancient magic. Its presence brings wonder and intrigue wherever it goes.",
            "dragon": "A powerful being with scales that shimmer like precious gems. Fiercely loyal to those who earn its trust.",
            "nature": "A gentle spirit deeply connected to the natural world. Flowers bloom in its wake and animals gather near.",
            "guardian": "A protective companion that watches over its friends. Its strength comes from the bonds it forms.",
            "cosmic": "Born from stardust and moonlight, this ethereal being carries the wisdom of the universe.",
            "fire": "A spirited creature with an inner flame that never dims. Its warmth brings comfort to allies.",
            "water": "A serene being that flows like the tide. Calm and adaptable, yet powerful when needed.",
            "electric": "Crackling with energy and excitement, this lively companion brings spark to every adventure."
        ]
        
        let type = poko.type.lowercased()
        return descriptions[type] ?? "A unique companion with its own special charm. Every Poko has a story waiting to be discovered."
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
    
    // MARK: - Actions
    
    @objc private func dismissTapped() {
        onDismiss()
    }
    
    @objc private func primaryTapped() {
        if isOwned && isOwnProfile {
            onSetActive()
        } else if !isOwned {
            onAdd()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frames
        if let heroGradient = heroContainer.layer.sublayers?.first as? CAGradientLayer {
            heroGradient.frame = heroContainer.bounds
        }
        
        if let glowView = heroContainer.subviews.first,
           let glowLayer = glowView.layer.sublayers?.first as? CAGradientLayer {
            glowLayer.frame = glowView.bounds
        }
        
        // Update button gradients
        if let gradient = primaryButton.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = primaryButton.bounds
        }
        
        if let specialGradient = specialBadge.layer.sublayers?.first as? CAGradientLayer {
            specialGradient.frame = specialBadge.bounds
        }
    }
}

struct ProfileScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
