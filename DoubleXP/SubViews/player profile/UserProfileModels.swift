//
//  UserProfileModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Additional Models for Videos & Communities

struct ProfileVideo: Identifiable, Equatable {
    let id: String
    let youtubeVideoId: String
    let title: String
    let thumbnailUrl: String?
    let duration: String // e.g., "12:34"
    let viewCount: Int
    let uploadedAt: Date?
    let isHighlighted: Bool
    
    var viewCountDisplay: String {
        if viewCount >= 1_000_000 {
            return String(format: "%.1fM views", Double(viewCount) / 1_000_000)
        } else if viewCount >= 1_000 {
            return String(format: "%.1fK views", Double(viewCount) / 1_000)
        }
        return "\(viewCount) views"
    }
    
    static func == (lhs: ProfileVideo, rhs: ProfileVideo) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProfileCommunity: Identifiable, Equatable {
    let id: String
    let name: String
    let imageUrl: String?
    let memberCount: Int
    let gameSlug: String?
    let gameName: String?
    let role: CommunityRole
    
    static func == (lhs: ProfileCommunity, rhs: ProfileCommunity) -> Bool {
        lhs.id == rhs.id
    }
}

enum CommunityRole: String {
    case owner = "owner"
    case moderator = "mod"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .owner: return "OWNER"
        case .moderator: return "MOD"
        case .member: return ""
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .owner: return Color(hex: "FFD700")
        case .moderator: return Color(hex: "9C27B0")
        case .member: return .clear
        }
    }
}

// MARK: - Extended UserProfile

/*extension UserProfile {
    // Add these computed properties or add to your UserProfile struct
    var highlightedVideo: ProfileVideo? {
        videos.first { $0.isHighlighted }
    }
    
    var nonHighlightedVideos: [ProfileVideo] {
        videos.filter { !$0.isHighlighted }
    }
}*/

// Note: Add these properties to your UserProfile struct:
// let videos: [ProfileVideo]
// let communities: [ProfileCommunity]

// MARK: - Profile Header YouTube Player (UIViewRepresentable)

struct ProfileHeaderYouTubePlayer: UIViewRepresentable {
    let videoId: String
    let shouldPlay: Bool   // you already have this

    func makeUIView(context: Context) -> YouTubePlayerView {
        YouTubePlayerView(frame: .zero)
    }

    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // No video? Pause/resign and bail.
        guard !videoId.isEmpty else {
            uiView.pause()
            YouTubePlaybackCoordinator.shared.resign(uiView)
            return
        }

        if shouldPlay {
            // Claim global ownership
            YouTubePlaybackCoordinator.shared.claim(uiView)

            if !uiView.isPlayerReady {
                // First-time load
                uiView.load(
                    videoID: videoId,
                    shouldAutoplay: true,
                    startTime: nil,
                    playerVars: [
                        "controls": 0,
                        "disablekb": 1,
                        "fs": 0,
                        "modestbranding": 1,
                        "playsinline": 1,
                        "rel": 0,
                        "showinfo": 0,
                        "mute": 1,
                        "loop": 1,
                        "playlist": videoId
                    ]
                )
            } else {
                // Already loaded, just resume
                uiView.play()
            }
        } else {
            // View says we shouldn't be playing
            uiView.pause()
            YouTubePlaybackCoordinator.shared.resign(uiView)
        }
    }
}

struct UserGamesGridView: View {
    let games: [GameItem]
    let username: String
    let onGameSelected: ((GameItem) -> Void)?
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    
    private var filteredGames: [GameItem] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Search bar
                if games.count > 12 {
                    searchBar
                }
                
                // Games grid
                ScrollView {
                    gamesGrid
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Extra padding for bottom menu
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("\(username)'s Games")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(games.count) games")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .background(Color.black)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Search games...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Games Grid
    
    private var gamesGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        
        return LazyVGrid(columns: columns, spacing: 10) {
            if filteredGames.isEmpty {
                emptyState
            } else {
                ForEach(filteredGames) { game in
                    GameThumbnail(game: game)
                        .onTapGesture {
                            onGameSelected?(game)
                            onDismiss()
                        }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No games found")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Try a different search")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .gridCellColumns(3)
    }
}

// MARK: - Full Screen Video Player View

struct FullScreenVideoPlayerView: View {
    let video: ProfileVideo
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // YouTube Player
            FullScreenYouTubePlayer(
                videoId: video.youtubeVideoId,
                isPlaying: $isPlaying,
                currentTime: $currentTime,
                duration: $duration
            )
            .ignoresSafeArea()
            
            // Touch overlay to show/hide controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                    scheduleHideControls()
                }
            
            // Controls overlay
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .onAppear {
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
        .statusBarHidden(true)
    }
    
    // MARK: - Controls Overlay
    
    private var controlsOverlay: some View {
        ZStack {
            // Gradient backgrounds
            VStack {
                // Top gradient
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                
                Spacer()
                
                // Bottom gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .ignoresSafeArea()
            
            // Top bar
            VStack {
                HStack {
                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Video title
                    VStack(spacing: 2) {
                        Text(video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                
                Spacer()
            }
            
            // Center playback controls
            HStack(spacing: 50) {
                // Rewind 10 seconds
                Button {
                    seekRelative(-10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button {
                    isPlaying.toggle()
                    scheduleHideControls()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                // Forward 10 seconds
                Button {
                    seekRelative(10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            // Bottom progress bar
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)
                            
                            // Progress
                            Capsule()
                                .fill(Color.red)
                                .frame(width: duration > 0 ? geo.size.width * CGFloat(currentTime / duration) : 0, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // Time labels
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(formatTime(duration))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls = false
                    }
                }
            }
        }
    }
    
    private func seekRelative(_ seconds: Double) {
        // This would need to communicate with the YouTube player
        // For now, update local state
        let newTime = max(0, min(duration, currentTime + seconds))
        currentTime = newTime
        scheduleHideControls()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Full Screen YouTube Player (UIViewRepresentable)

struct FullScreenYouTubePlayer: UIViewRepresentable {
    let videoId: String
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    
    func makeUIView(context: Context) -> YouTubePlayerView {
        let player = YouTubePlayerView(frame: .zero)
        context.coordinator.player = player
        
        // Set up progress handler
        player.progressUpdateHandler = { progress in
            // Progress is 0-1
            if let dur = context.coordinator.cachedDuration, dur > 0 {
                DispatchQueue.main.async {
                    self.currentTime = Double(progress) * dur
                }
            }
        }
        
        return player
    }
    
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        if !uiView.isPlayerReady {
            uiView.load(
                videoID: videoId,
                shouldAutoplay: true,
                startTime: nil,
                playerVars: [
                    "controls": 0,
                    "playsinline": 1,
                    "rel": 0,
                    "showinfo": 0,
                    "fs": 0
                ]
            )
        } else {
            if isPlaying {
                uiView.play()
            } else {
                uiView.pause()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: YouTubePlayerView?
        var cachedDuration: Double?
    }
}

// MARK: - Videos Section (Horizontal Scroll)

struct ProfileVideosSectionView: View {
    let videos: [ProfileVideo]
    let onVideoTapped: (ProfileVideo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack {
                Text("VIDEOS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if videos.count > 4 {
                    Button {
                        // See all videos
                    } label: {
                        Text("See All \(videos.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "FF0000")) // YouTube red
                    }
                }
            }
            
            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        VideoCardView(video: video)
                            .onTapGesture {
                                onVideoTapped(video)
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Video Card View

struct VideoCardView: View {
    let video: ProfileVideo
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                // Thumbnail image
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1a1a2e"), Color(hex: "252540")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    
                    // Play overlay on hover/tap
                    Color.black.opacity(0.2)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Duration badge
                Text(video.duration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(6)
            }
            
            // Title
            Text(video.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            
            // View count
            Text(video.viewCountDisplay)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // YouTube thumbnail URL format
        let thumbnailUrl = video.thumbnailUrl ?? "https://img.youtube.com/vi/\(video.youtubeVideoId)/mqdefault.jpg"
        guard let url = URL(string: thumbnailUrl) else { return }
        thumbnailImage = await ImageCache.shared.image(for: url)
    }
}

// MARK: - Communities Section (2-Column Grid)

struct ProfileCommunitiesSectionView: View {
    let communities: [ProfileCommunity]
    let onCommunityTapped: (ProfileCommunity) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack {
                Text("COMMUNITIES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if communities.count > 4 {
                    Button {
                        // See all communities
                    } label: {
                        Text("See All \(communities.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                }
            }
            
            // 2-Column Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(communities.prefix(4)) { community in
                    CommunityGridCardView(community: community)
                        .onTapGesture {
                            onCommunityTapped(community)
                        }
                }
            }
        }
    }
}

// MARK: - Community Grid Card View

struct CommunityGridCardView: View {
    let community: ProfileCommunity
    
    @State private var communityImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Banner
            ZStack(alignment: .bottomLeading) {
                // Banner background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "252540")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 50)
                
                // Community avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if let image = communityImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    // Role badge
                    if community.role != .member {
                        Text(community.role.displayName)
                            .font(.system(size: 6, weight: .heavy))
                            .foregroundColor(community.role == .owner ? .black : .white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(community.role.badgeColor)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            .offset(y: -20)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black, lineWidth: 3)
                )
                .offset(x: 10, y: 22)
            }
            
            // Info section
            VStack(alignment: .leading, spacing: 2) {
                Text(community.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let gameName = community.gameName {
                    Text(gameName)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "4CAF50"))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 28)
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = community.imageUrl,
              let url = URL(string: urlString) else { return }
        communityImage = await ImageCache.shared.image(for: url)
    }
}

// MARK: - Updated Hero Background with YouTube

struct ProfileHeroBackgroundView: View {
    let profile: UserProfile
    let highlightedVideo: String?
    let headerHeight: CGFloat
    @Binding var isVideoPlaying: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color.gray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Video or Image
            if let video = highlightedVideo {
                // YouTube video background (muted, autoplay, no interaction)
                ProfileHeaderYouTubePlayer(
                    videoId: highlightedVideo ?? "",
                    shouldPlay: isVideoPlaying
                )
                .allowsHitTesting(false) // Disable touch
                
                // "GAMEPLAY" badge
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
                
            } else if let headerURL = profile.headerImageURL, let url = URL(string: headerURL) {
                // Static image fallback
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
            } else {
                // Placeholder
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.1))
            }
        }
        .frame(height: headerHeight)
        .clipped()
    }
}

// MARK: - Mock Data

/*extension ProfileVideo {
    static let mockVideos: [ProfileVideo] = [
        ProfileVideo(
            id: "v1",
            youtubeVideoId: "dQw4w9WgXcQ",
            title: "Epic Win Compilation - Warzone Season 5",
            thumbnailUrl: nil,
            duration: "12:34",
            viewCount: 15420,
            uploadedAt: Date().addingTimeInterval(-86400 * 7),
            isHighlighted: true
        ),
        ProfileVideo(
            id: "v2",
            youtubeVideoId: "ScMzIvxBSi4",
            title: "1v4 Clutch Moment",
            thumbnailUrl: nil,
            duration: "2:15",
            viewCount: 8230,
            uploadedAt: Date().addingTimeInterval(-86400 * 3),
            isHighlighted: false
        ),
        ProfileVideo(
            id: "v3",
            youtubeVideoId: "ZZ5LpwO-An4",
            title: "How I Got Diamond Rank",
            thumbnailUrl: nil,
            duration: "18:42",
            viewCount: 42100,
            uploadedAt: Date().addingTimeInterval(-86400 * 14),
            isHighlighted: false
        ),
        ProfileVideo(
            id: "v4",
            youtubeVideoId: "9bZkp7q19f0",
            title: "Funny Moments with the Squad",
            thumbnailUrl: nil,
            duration: "8:56",
            viewCount: 5670,
            uploadedAt: Date().addingTimeInterval(-86400 * 5),
            isHighlighted: false
        )
    ]
}*/

extension ProfileCommunity {
    static let mockCommunities: [ProfileCommunity] = [
        ProfileCommunity(
            id: "c1",
            name: "Warzone Warriors",
            imageUrl: nil,
            memberCount: 12500,
            gameSlug: "call-of-duty-warzone",
            gameName: "Call of Duty: Warzone",
            role: .owner
        ),
        ProfileCommunity(
            id: "c2",
            name: "Apex Legends Ranked",
            imageUrl: nil,
            memberCount: 8420,
            gameSlug: "apex-legends",
            gameName: "Apex Legends",
            role: .moderator
        ),
        ProfileCommunity(
            id: "c3",
            name: "Fortnite Builders",
            imageUrl: nil,
            memberCount: 23100,
            gameSlug: "fortnite",
            gameName: "Fortnite",
            role: .member
        ),
        ProfileCommunity(
            id: "c4",
            name: "FIFA Ultimate Team",
            imageUrl: nil,
            memberCount: 5670,
            gameSlug: "ea-sports-fc-24",
            gameName: "EA Sports FC 24",
            role: .member
        )
    ]
}

struct ProfileQuizzesSection: View {
    let quizzes: [ProfileQuizItem]
    let username: String
    let isOwnProfile: Bool
    let proximityDistance: Double?
    let onQuizTapped: (ProfileQuizItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            sectionHeader
            
            // Proximity indicator (if applicable)
            if let distance = proximityDistance {
                proximityIndicator(distance: distance)
            }
            
            // Quiz cards horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(quizzes.prefix(5)) { quiz in
                        AnswerPeekCard(
                            quiz: quiz,
                            isOwnProfile: isOwnProfile
                        )
                        .onTapGesture {
                            onQuizTapped(quiz)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Text("QUIZ ANSWERS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            // Tap hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 10))
                Text("Tap to view")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.4))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
            
            Spacer()
            
            if quizzes.count > 5 {
                Button {
                    // See all quizzes
                } label: {
                    Text("See All \(quizzes.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }
            }
        }
    }
    
    // MARK: - Proximity Indicator
    
    private func proximityIndicator(distance: Double) -> some View {
        HStack(spacing: 10) {
            // Location icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            
            // Distance text
            VStack(alignment: .leading, spacing: 2) {
                Text("Nearby Gamer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.1f", distance)) miles away")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.blue.opacity(0.08)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Answer Peek Card

struct AnswerPeekCard: View {
    let quiz: ProfileQuizItem
    let isOwnProfile: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row: Icon and answer count
            HStack(alignment: .top) {
                // Quiz icon
                Text(quiz.quiz.gameIcon)
                    .font(.system(size: 44))
                
                Spacer()
                
                // Answer preview badge
                answerCountBadge
            }
            
            // Quiz title
            Text(quiz.quiz.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Meta info
            VStack(alignment: .leading, spacing: 4) {
                Text("Completed \(quiz.formattedDate)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                if !isOwnProfile {
                    Text("View \(quiz.answerCount) answers")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.55, green: 0.57, blue: 1.0))
                }
            }
            
            Spacer()
            
            // View answers button
            viewAnswersButton
        }
        .frame(width: 260)
        .padding(20)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Answer Count Badge
    
    private var answerCountBadge: some View {
        VStack(spacing: 2) {
            Text("\(quiz.answerCount)")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
            
            Text("ANSWERS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - View Answers Button
    
    private var viewAnswersButton: some View {
        HStack {
            Text(isOwnProfile ? "View My Answers" : "View Answers")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.55, green: 0.57, blue: 1.0))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Card Styling
    
    private var cardBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.1),
                    Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Radial glow (top right)
            RadialGradient(
                colors: [
                    Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.2),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 120
            )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.3),
                lineWidth: 2
            )
    }
}

// MARK: - Quiz Detail View (Full Screen)

struct QuizDetailView: View {
    let quiz: ProfileQuizItem
    let isOwnProfile: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Quiz info card
                        quizInfoCard
                        
                        // Answers list
                        answersSection
                        
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                                .shadow(color: .black.opacity(0.6), radius: 5, x: 3, y: 3)
                                .shadow(color: .white.opacity(0.02), radius: 5, x: -3, y: -3)
                        )
                }
                
                Spacer()
                
                Text("Quiz Answers")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
    
    // MARK: - Quiz Info Card
    
    private var quizInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(quiz.quiz.gameIcon)
                    .font(.system(size: 48))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quiz.quiz.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(quiz.quiz.gameName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                infoItem(icon: "checkmark.circle", label: "Completed", value: quiz.formattedDate)
                
                Spacer()
                
                infoItem(icon: "list.bullet", label: "Answers", value: "\(quiz.answerCount)")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func infoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Answers Section
    
    private var answersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ANSWERS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            ForEach(Array(quiz.completion.answers.enumerated()), id: \.element.questionId) { index, answer in
                if let question = quiz.quiz.questions.first(where: { $0.id == answer.questionId }) {
                    AnswerRow(
                        questionNumber: index + 1,
                        question: question,
                        answer: answer
                    )
                }
            }
        }
    }
}

// MARK: - Answer Row

struct AnswerRow: View {
    let questionNumber: Int
    let question: QuizQuestion
    let answer: QuizAnswer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question header
            HStack(spacing: 8) {
                Text("Q\(questionNumber)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                    .clipShape(Capsule())
                
                if question.isImportant {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("IMPORTANT")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // Question text
            Text(question.questionText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Answer
            VStack(alignment: .leading, spacing: 6) {
                ForEach(answer.selectedOptions, id: \.self) { option in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.55, green: 0.57, blue: 1.0))
                        
                        Text(option)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.55, green: 0.57, blue: 1.0).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.55, green: 0.57, blue: 1.0).opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ProfileQuizItem: Identifiable {
    let id: String
    let quiz: GameQuiz
    let completion: UserQuizCompletion
    let answerCount: Int
    let completedDate: Date
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedDate, relativeTo: Date())
    }
}
