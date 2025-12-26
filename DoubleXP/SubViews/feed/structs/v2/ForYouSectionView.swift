//
//  ForYouSectionView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ForYouSectionView: View {
    let featuredGames: [GamerConnectGame]
    let recommendedGames: [GamerConnectGame]
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void
    var onPauseHeader: (() -> Void)? = nil
    var onResumeHeader: (() -> Void)? = nil
    
    // Video playback manager
    @StateObject private var videoManager = FeedVideoPlaybackManager.shared
    
    // Current featured game index for swiping
    @State private var currentFeaturedIndex: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            sectionHeader
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Featured Hero Stack
            if !featuredGames.isEmpty {
                featuredHeroStack
                    .padding(.bottom, 20)
            }
            
            // "Based on your games" label + horizontal scroll
            if !recommendedGames.isEmpty {
                recommendedGamesSection
            }
        }
        .onAppear {
            // Wire up video manager callbacks
            videoManager.onGameVideoStarted = onPauseHeader
            videoManager.onGameVideoEnded = onResumeHeader
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack {
            Text("For You")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button {
                // See all action
            } label: {
                Text("See All →")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Featured Hero Stack
    
    private var featuredHeroStack: some View {
        VStack(spacing: 12) {
            // Hero Card
            TabView(selection: $currentFeaturedIndex) {
                ForEach(Array(featuredGames.prefix(5).enumerated()), id: \.element.id) { index, game in
                    FeaturedGameCard(
                        game: game,
                        namespace: namespace,
                        onTap: { onGameTapped(game) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
            .padding(.horizontal, 20)
            
            // Story-style indicators
            HStack(spacing: 6) {
                ForEach(0..<min(featuredGames.count, 5), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            index == currentFeaturedIndex
                                ? LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: 32, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: currentFeaturedIndex)
                }
            }
        }
    }
    
    // MARK: - Recommended Games Section
    
    private var recommendedGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Based on your games")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendedGames.prefix(10)) { game in
                        SmallGameCard(
                            game: game,
                            namespace: namespace,
                            onTap: { onGameTapped(game) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Featured Game Card (with Video Support)

struct FeaturedGameCard: View {
    let game: GamerConnectGame
    let namespace: Namespace.ID
    var onTap: () -> Void
    
    @StateObject private var videoManager = FeedVideoPlaybackManager.shared
    
    // Video playback state
    @State private var isVideoPlaying: Bool = false
    @State private var showVideoUI: Bool = false
    @State private var youtubePlayerView: YouTubePlayerView?
    @State private var videoOpacity: Double = 0
    @State private var uiOpacity: Double = 1
    
    // Check if this game has a trailer
    private var hasTrailer: Bool {
        // For now, always show play button for testing
        // In production: return trailerVideoID != nil
        return true
    }
    
    private var trailerVideoID: String? {
        // Try to get YouTube video ID from videos array
        if let videos = game.videos, let firstVideo = videos.first {
            if let videoId = firstVideo.video_id {
                return videoId
            }
        }
        // Default test video for development
        return "dQw4w9WgXcQ" // Remove this line in production
    }
    
    private var isThisCardPlaying: Bool {
        videoManager.activeVideoID == game.id
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"),
                                 Color(hex: "FF8E53"),
                                 Color(hex: "9333EA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 8)
                .opacity(0.5)
                .offset(y: 4)
            
            // Card content
            ZStack {
                // Background image
                if let url = game.bestImageURL {
                    CachedAsyncImageView(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .opacity(isThisCardPlaying ? 0 : 1)
                } else {
                    Color(hex: "1a1a1a")
                }
                
                // YouTube Player (when playing)
                if isThisCardPlaying, let playerView = youtubePlayerView {
                    YouTubePlayerRepresentableWrapper(playerView: playerView)
                        .opacity(videoOpacity)
                        .transition(.opacity)
                }
                
                // 🔹 Only show overlay + base UI when NOT playing
                if !isThisCardPlaying {
                    LinearGradient(
                        colors: [.black.opacity(0.85),
                                 .black.opacity(0.3),
                                 .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    baseUIContent
                }
                
                // Video playback controls (when playing)
                if isThisCardPlaying {
                    videoPlaybackControls
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isThisCardPlaying {
                onTap()
            }
        }
        .onChange(of: videoManager.activeVideoID) { _, newValue in
            if newValue != game.id && isVideoPlaying {
                resetVideoState()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { videoManager.isInFullscreen(gameID: game.id) },
            set: { if !$0 { videoManager.exitFullscreen() } }
        )) {
            if let videoID = trailerVideoID {
                FullscreenYouTubePlayerView(
                    videoID: videoID,
                    startTime: videoManager.currentTime,
                    isMuted: videoManager.isMuted,
                    onDismiss: {
                        videoManager.exitFullscreen()
                    }
                )
            }
        }
    }
    
    // MARK: - Base UI Content
    
    private var baseUIContent: some View {
        VStack(spacing: 0) {
            // Top row with play button
            HStack {
                Spacer()
                if hasTrailer {
                    Button(action: startVideoPlayback) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    }
                }
            }
            .padding(16)
            
            Spacer()
            
            // Bottom content
            VStack(alignment: .leading, spacing: 8) {
                // Featured badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("Featured")
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Title
                Text(game.gameName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                
                // Meta info
                Text(gameMetaText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Video Playback Controls
    
    private var videoPlaybackControls: some View {
        ZStack {
            // Tap to show/hide controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showVideoUI.toggle()
                    }
                }
            
            // Controls overlay
            if showVideoUI {
                VStack {
                    // Top bar with close
                    HStack {
                        Button(action: stopVideoPlayback) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Mute button
                        Button(action: { videoManager.toggleMute() }) {
                            Image(systemName: videoManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    // Bottom bar with expand
                    HStack {
                        // Progress indicator
                        Text(formatTime(videoManager.currentTime))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        // Expand button
                        Button(action: { videoManager.expandToFullscreen() }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                }
                .transition(.opacity)
            }
            
            // Progress bar at bottom
            VStack {
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(videoManager.playbackProgress), height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
    }
    
    // MARK: - Video Actions
    
    private func startVideoPlayback() {
        guard let videoID = trailerVideoID else { return }
        
        isVideoPlaying = true
        showVideoUI = true
        
        // Create YouTube player
        let player = YouTubePlayerView()
        youtubePlayerView = player
        
        // Start playback through manager
        videoManager.playYouTubeVideo(
            videoID: videoID,
            gameID: game.id,
            playerView: player
        ) { [self] in
            // Completion handler - fade back to base UI
            withAnimation(.easeOut(duration: 0.4)) {
                videoOpacity = 0
                uiOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                resetVideoState()
            }
        }
        
        // Fade in video
        withAnimation(.easeIn(duration: 0.3)) {
            videoOpacity = 1
            uiOpacity = 0
        }
        
        // Auto-hide controls after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showVideoUI = false
            }
        }
    }
    
    private func stopVideoPlayback() {
        // Fade out video
        withAnimation(.easeOut(duration: 0.3)) {
            videoOpacity = 0
            uiOpacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            videoManager.stopCurrentPlayback()
            resetVideoState()
        }
    }
    
    private func resetVideoState() {
        isVideoPlaying = false
        showVideoUI = false
        youtubePlayerView = nil
        videoOpacity = 0
        uiOpacity = 1
    }
    
    // MARK: - Helpers
    
    private var gameMetaText: String {
        game.categoryFilters.first ?? game.gameType ?? "Game"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func extractYouTubeID(from url: String) -> String? {
        // Handle various YouTube URL formats
        let patterns = [
            "(?<=v=)[^&#]+",
            "(?<=be/)[^&#]+",
            "(?<=embed/)[^&#]+",
            "(?<=youtu.be/)[^&#]+"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range, in: url) {
                return String(url[range])
            }
        }
        return nil
    }
}

// MARK: - YouTube Player Wrapper

struct YouTubePlayerRepresentableWrapper: UIViewRepresentable {
    let playerView: YouTubePlayerView
    
    func makeUIView(context: Context) -> YouTubePlayerView {
        return playerView
    }
    
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // No updates needed
    }
}

// MARK: - Fullscreen YouTube Player

struct FullscreenYouTubePlayerView: View {
    let videoID: String
    let startTime: Double
    let isMuted: Bool
    var onDismiss: () -> Void
    
    @State private var player: YouTubePlayerView?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                YouTubePlayerRepresentableWrapper(playerView: player)
                    .ignoresSafeArea()
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            let ytPlayer = YouTubePlayerView()
            ytPlayer.load(videoID: videoID, shouldAutoplay: true, startTime: startTime)
            if !isMuted {
                ytPlayer.unmute()
            }
            player = ytPlayer
        }
        .onDisappear {
            player?.pause()
        }
    }
}

// MARK: - Small Game Card

struct SmallGameCard: View {
    let game: GamerConnectGame
    let namespace: Namespace.ID
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            if let url = game.bestImageURL {
                CachedAsyncImageView(url: url)
                    .frame(width: 100, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .matchedGeometryEffect(id: game.id, in: namespace)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1a1a1a"))
                    .frame(width: 100, height: 130)
            }
            
            // Game name
            Text(game.gameName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Genre
            Text(game.categoryFilters.first ?? game.gameType ?? "Game")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(width: 100)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - GamerConnectGame Image Helper Extension

extension GamerConnectGame {
    /// Returns the best available image URL
    var bestImageURL: URL? {
        // Try imageUrl first
        if let urlString = imageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
            return url
        }
        // Try cover.url
        if let coverUrl = cover?.url, !coverUrl.isEmpty, let url = URL(string: coverUrl) {
            return url
        }
        // Try alternateImageUrl
        if let altUrl = alternateImageUrl, !altUrl.isEmpty, let url = URL(string: altUrl) {
            return url
        }
        return nil
    }
}
