//
//  ShortVideoView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ShortVideoView: View {
    // MARK: - Properties
    let short: YouTubeShort
    let isActive: Bool
    
    // Callbacks
    var onSwipeUp: () -> Void = {}
    var onSwipeDown: () -> Void = {}
    var onVideoEnded: () -> Void = {}
    var onProgressUpdate: ((CGFloat) -> Void)?
    var onFollowToggle: () -> Void = {}
    
    // Follow state
    @State private var isFollowing: Bool = false
    
    // State
    @State private var showControls: Bool = true
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    // Constants
    private let swipeThreshold: CGFloat = 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Video Layer (Full Screen Background)
                ZStack {
                    Color.black
                    
                    // Only load player when active
                    if isActive {
                        ShortsPlayerRepresentable(
                            videoID: short.videoId,
                            isActive: isActive, // NEW: Pass through isActive
                            onProgress: { progress in
                                onProgressUpdate?(progress)
                            },
                            onVideoEnded: {
                                onVideoEnded()
                            }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                }
                
                // 2. Gradient Overlay (Bottom Only)
                if showControls {
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 250)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
                
                // 3. UI Controls Layer
                VStack {
                    Spacer()
                    
                    if showControls {
                        HStack(alignment: .bottom) {
                            // Left side: Title & Channel Info
                            VStack(alignment: .leading, spacing: 8) {
                                // Video Title
                                Text(short.title)
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                // Channel Info Row
                                HStack(spacing: 10) {
                                    // Channel Avatar
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(String(short.channelTitle.prefix(1)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    
                                    // Channel Name
                                    Text(short.channelTitle)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                            
                            // Right side: Follow Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isFollowing.toggle()
                                    onFollowToggle()
                                }
                            }) {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isFollowing ? .white : .black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isFollowing ? Color.white.opacity(0.2) : Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(isFollowing ? 0.3 : 0), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20) + 80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            // Swipe Gestures Logic
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.height / 2
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        if value.translation.height < -swipeThreshold {
                            // Swipe Up -> Next
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = -geometry.size.height
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSwipeUp()
                                dragOffset = 0
                            }
                        } else if value.translation.height > swipeThreshold {
                            // Swipe Down -> Previous
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = geometry.size.height
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSwipeDown()
                                dragOffset = 0
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .statusBar(hidden: true)
        .background(Color.black)
    }
}

struct ShortsPlayerRepresentable: UIViewRepresentable {
    let videoID: String
    let isActive: Bool // NEW: Add this
    var onProgress: ((CGFloat) -> Void)?
    var onVideoEnded: (() -> Void)?
    
    func makeUIView(context: Context) -> YouTubePlayerView {
        let playerView = YouTubePlayerView(frame: .zero)
        playerView.isUserInteractionEnabled = false
        
        context.coordinator.playerView = playerView
        context.coordinator.onProgress = onProgress
        context.coordinator.onVideoEnded = onVideoEnded
        context.coordinator.currentVideoID = videoID
        context.coordinator.isActive = isActive // NEW
        
        // Only load and start if active
        if isActive {
            playerView.load(videoID: videoID, shouldAutoplay: true)
            playerView.mute()
            context.coordinator.waitForReadyThenStartPolling()
        }
        
        return playerView
    }
    
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // Handle active state changes
        let wasActive = context.coordinator.isActive
        context.coordinator.isActive = isActive
        
        if wasActive != isActive {
            print("🎥 [ShortsPlayer] Active state changed: \(wasActive) -> \(isActive)")
            if isActive {
                // Becoming active - start playing
                if context.coordinator.currentVideoID != videoID {
                    // New video, load it
                    print("🔄 Loading and playing video: \(videoID)")
                    context.coordinator.currentVideoID = videoID
                    uiView.load(videoID: videoID, shouldAutoplay: true)
                    uiView.mute()
                    context.coordinator.waitForReadyThenStartPolling()
                } else {
                    // Same video, just resume
                    print("▶️ Resuming video: \(videoID)")
                    uiView.play()
                    context.coordinator.startPolling()
                }
            } else {
                // Becoming inactive - stop everything
                print("⏸️ Pausing video: \(videoID)")
                uiView.pause()
                context.coordinator.stopPolling()
            }
            return
        }
        
        // Only handle video changes if active
        if isActive && context.coordinator.currentVideoID != videoID {
            print("🔄 Switching to video: \(videoID)")
            context.coordinator.currentVideoID = videoID
            
            // Stop old polling
            context.coordinator.stopPolling()
            
            // Load new video
            uiView.load(videoID: videoID, shouldAutoplay: true)
            uiView.mute()
            
            // Wait for ready then start polling
            context.coordinator.waitForReadyThenStartPolling()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var playerView: YouTubePlayerView?
        var currentVideoID: String?
        var isActive: Bool = false // NEW
        var onProgress: ((CGFloat) -> Void)?
        var onVideoEnded: (() -> Void)?
        private var pollTimer: Timer?
        private var readyCheckTimer: Timer?
        
        func waitForReadyThenStartPolling() {
            // Don't start if not active
            guard isActive else {
                print("⚠️ [ShortsPlayer] Skipping polling - not active")
                return
            }
            
            // Stop any existing timers
            stopPolling()
            readyCheckTimer?.invalidate()
            
            var attempts = 0
            let maxAttempts = 40 // 8 seconds max wait
            
            readyCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
                guard let self = self, let playerView = self.playerView else {
                    timer.invalidate()
                    return
                }
                
                // Stop if became inactive
                if !self.isActive {
                    print("⏸️ [ShortsPlayer] Became inactive during ready check, stopping")
                    timer.invalidate()
                    self.readyCheckTimer = nil
                    return
                }
                
                attempts += 1
                
                // Check if player is ready
                if playerView.isPlayerReady {
                    timer.invalidate()
                    self.readyCheckTimer = nil
                    self.startPolling()
                } else if attempts >= maxAttempts {
                    timer.invalidate()
                    self.readyCheckTimer = nil
                    self.startPolling()
                }
            }
            
            RunLoop.main.add(readyCheckTimer!, forMode: .common)
        }
        
        func startPolling() {
            // Don't start if not active
            guard isActive else {
                print("⚠️ [ShortsPlayer] Skipping polling start - not active")
                return
            }
            
            stopPolling() // Ensure no duplicate timers
            
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                guard let self = self, let playerView = self.playerView else { return }
                
                // Stop polling if became inactive
                if !self.isActive {
                    print("⏸️ [ShortsPlayer] Became inactive during polling, stopping")
                    self.stopPolling()
                    return
                }
                
                // Skip if player not ready yet
                guard playerView.isPlayerReady else { return }
                
                playerView.samplePlayback { snapshot in
                    // Only process if we have valid data
                    if let current = snapshot.current,
                       let duration = snapshot.duration,
                       duration > 0,
                       current >= 0 {
                        let progress = CGFloat(min(current / duration, 1.0))
                        DispatchQueue.main.async {
                            self.onProgress?(progress)
                        }
                    }
                    
                    // Check if video ended
                    if snapshot.state == .ended {
                        print("🎬 [ShortsPlayer] Video ended")
                        self.stopPolling()
                        DispatchQueue.main.async {
                            self.onVideoEnded?()
                        }
                    }
                }
            }
            
            RunLoop.main.add(pollTimer!, forMode: .common)
            print("▶️ [ShortsPlayer] Started progress polling")
        }
        
        func stopPolling() {
            if pollTimer != nil {
                print("🛑 [ShortsPlayer] Stopping polling")
            }
            pollTimer?.invalidate()
            pollTimer = nil
            readyCheckTimer?.invalidate()
            readyCheckTimer = nil
        }
        
        deinit {
            stopPolling()
        }
    }
}

struct YouTubePlayerRepresentable: UIViewRepresentable {
    let videoID: String
    let autoplay: Bool
    let isMuted: Bool
    let disableInteraction: Bool
    var onPlayerReady: ((YouTubePlayerView) -> Void)?
    var onVideoEnded: (() -> Void)?
    var onError: ((Int) -> Void)?
    
    // For Shorts (autoplay, track end, auto-muted, no interaction)
    init(
        videoID: String,
        autoplay: Bool = true,
        onPlayerReady: ((YouTubePlayerView) -> Void)? = nil,
        onVideoEnded: (() -> Void)? = nil,
        onError: ((Int) -> Void)? = nil
    ) {
        self.videoID = videoID
        self.autoplay = autoplay
        self.isMuted = true
        self.disableInteraction = true
        self.onPlayerReady = onPlayerReady
        self.onVideoEnded = onVideoEnded
        self.onError = onError
    }
    
    // For Carousel (visibility-based play/pause, mute control, no interaction)
    init(
        videoID: String,
        isVisible: Bool,
        isMuted: Bool,
        onPlayerReady: @escaping (YouTubePlayerView) -> Void
    ) {
        self.videoID = videoID
        self.autoplay = isVisible
        self.isMuted = isMuted
        self.disableInteraction = true
        self.onPlayerReady = onPlayerReady
        self.onVideoEnded = nil
        self.onError = nil
    }
    
    func makeUIView(context: Context) -> YouTubePlayerView {
        let playerView = YouTubePlayerView(frame: .zero)
        playerView.isUserInteractionEnabled = !disableInteraction
        
        context.coordinator.playerView = playerView
        context.coordinator.onPlayerReady = onPlayerReady
        context.coordinator.onVideoEnded = onVideoEnded
        context.coordinator.onError = onError
        context.coordinator.isMuted = isMuted
        
        return playerView
    }
    
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // Only load if it's a different video
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            context.coordinator.hasEnded = false
            context.coordinator.hasErrored = false
            
            // Load with proper playerVars
            let playerVars: [String: Any] = [
                "playsinline": 1,
                "mute": isMuted ? 1 : 0,
                "controls": 0,
                "rel": 0,
                "showinfo": 0,
                "modestbranding": 1,
                "iv_load_policy": 3,
                "disablekb": 1,
                "autoplay": autoplay ? 1 : 0
            ]
            
            // Use diagnostic version during debugging
            //uiView.loadWithDiagnostics(videoID: videoID, shouldAutoplay: autoplay, startTime: nil, playerVars: playerVars)
            uiView.load(videoID: videoID, shouldAutoplay: autoplay, startTime: nil, playerVars: playerVars)
            // Start polling for video end AND errors
            context.coordinator.startPollingForEndAndErrors(playerView: uiView)
            
            // Async callback to avoid blocking UI thread
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    context.coordinator.onPlayerReady?(uiView)
                }
            }
        } else {
            // Handle play/pause for carousel visibility changes
            if autoplay {
                uiView.play()
            } else {
                uiView.pause()
            }
            
            // Update mute state
            if context.coordinator.isMuted != isMuted {
                context.coordinator.isMuted = isMuted
                if isMuted {
                    uiView.mute()
                } else {
                    uiView.unmute()
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var playerView: YouTubePlayerView?
        var currentVideoID: String?
        var onPlayerReady: ((YouTubePlayerView) -> Void)?
        var onVideoEnded: (() -> Void)?
        var onError: ((Int) -> Void)?
        var isMuted: Bool = true
        
        private var pollTimer: Timer?
        var hasEnded = false
        var hasErrored = false
        private var unstartedCount = 0
        
        func startPollingForEndAndErrors(playerView: YouTubePlayerView) {
            // Cancel existing timer
            pollTimer?.invalidate()
            unstartedCount = 0
            
            // Start new polling timer
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self, weak playerView] _ in
                guard let self = self, let playerView = playerView else {
                    self?.pollTimer?.invalidate()
                    return
                }
                
                // Don't poll if player view's superview hierarchy is not in a window (not visible)
                if playerView.window == nil {
                    // View is not in window hierarchy, likely off-screen
                    return
                }
                
                playerView.samplePlayback { snapshot in
                    // Rest of your existing code...
                    print("🎬 [YouTube] State: \(snapshot.state.rawValue), Current: \(snapshot.current ?? -1), Duration: \(snapshot.duration ?? -1)")
                    
                    // Check if video has ended
                    if snapshot.state == .ended && !self.hasEnded {
                        self.hasEnded = true
                        self.pollTimer?.invalidate()
                        
                        DispatchQueue.main.async {
                            self.onVideoEnded?()
                        }
                        return
                    }
                    
                    // Check if playing or buffering (good states)
                    if snapshot.state == .playing || snapshot.state == .buffering {
                        self.unstartedCount = 0 // Reset error counter
                    }
                    
                    // Check if video is stuck in unstarted state (indicates error)
                    if snapshot.state == .unstarted && !self.hasErrored {
                        self.unstartedCount += 1
                        
                        if self.unstartedCount > 8 { // 4 seconds (8 * 0.5s)
                            self.hasErrored = true
                            self.pollTimer?.invalidate()
                            
                            print("⚠️ [YouTube] Video \(self.currentVideoID ?? "unknown") failed to start")
                            
                            DispatchQueue.main.async {
                                self.onError?(153)
                            }
                        }
                    }
                    
                    // Call onPlayerReady when player becomes ready
                    if playerView.isPlayerReady && self.onPlayerReady != nil {
                        self.onPlayerReady?(playerView)
                        self.onPlayerReady = nil
                    }
                }
            }
            
            RunLoop.main.add(pollTimer!, forMode: .common)
        }
        
        deinit {
            pollTimer?.invalidate()
        }
    }
}


