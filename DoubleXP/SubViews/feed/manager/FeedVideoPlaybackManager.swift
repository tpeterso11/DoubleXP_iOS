//
//  FeedVideoPlaybackManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI
import AVFoundation
import Combine

// MARK: - Feed Video Playback Manager

/// Coordinates video playback across the feed to ensure only one video plays at a time
/// and handles transitions between inline and fullscreen playback
@MainActor
final class FeedVideoPlaybackManager: ObservableObject {
    
    static let shared = FeedVideoPlaybackManager()
    
    // MARK: - Published State
    
    /// Currently playing video ID (game ID or carousel item ID)
    @Published var activeVideoID: String? = nil
    
    /// Whether the active video is in fullscreen mode
    @Published var isFullscreen: Bool = false
    
    /// Whether the active video is muted
    @Published var isMuted: Bool = false
    
    /// Playback progress (0.0 - 1.0)
    @Published var playbackProgress: Float = 0.0
    
    /// Current playback time in seconds
    @Published var currentTime: Double = 0
    
    /// Total duration in seconds
    @Published var duration: Double = 0
    
    // MARK: - Internal State
    
    private var youtubePlayer: YouTubePlayerView?
    private var nativePlayer: AVPlayer?
    private var progressTimer: Timer?
    private var onPlaybackComplete: (() -> Void)?
    
    // Callback to pause header when game video starts
    var onGameVideoStarted: (() -> Void)?
    var onGameVideoEnded: (() -> Void)?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start playing a YouTube video for a game
    func playYouTubeVideo(
        videoID: String,
        gameID: String,
        playerView: YouTubePlayerView,
        onComplete: @escaping () -> Void
    ) {
        // Stop any existing playback
        stopCurrentPlayback()
        
        // Notify header to pause
        onGameVideoStarted?()
        
        // Set up new playback
        activeVideoID = gameID
        youtubePlayer = playerView
        isMuted = false // Start unmuted when user initiated
        isFullscreen = false
        onPlaybackComplete = onComplete
        
        // Load and play
        playerView.load(videoID: videoID, shouldAutoplay: true)
        playerView.unmute()
        
        // Start progress monitoring
        startProgressMonitoring()
        
        print("▶️ [VideoManager] Started YouTube video \(videoID) for game \(gameID)")
    }
    
    /// Start playing a native video for a game
    func playNativeVideo(
        url: URL,
        gameID: String,
        player: AVPlayer,
        onComplete: @escaping () -> Void
    ) {
        // Stop any existing playback
        stopCurrentPlayback()
        
        // Notify header to pause
        onGameVideoStarted?()
        
        // Set up new playback
        activeVideoID = gameID
        nativePlayer = player
        isMuted = false
        isFullscreen = false
        onPlaybackComplete = onComplete
        
        // Configure and play
        player.isMuted = false
        player.seek(to: .zero)
        player.play()
        
        // Add end observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nativeVideoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Start progress monitoring
        startNativeProgressMonitoring()
        
        print("▶️ [VideoManager] Started native video for game \(gameID)")
    }
    
    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        
        if let yt = youtubePlayer {
            isMuted ? yt.mute() : yt.unmute()
        }
        if let native = nativePlayer {
            native.isMuted = isMuted
        }
        
        print("🔊 [VideoManager] Mute toggled: \(isMuted)")
    }
    
    /// Expand to fullscreen
    func expandToFullscreen() {
        isFullscreen = true
        print("📺 [VideoManager] Expanded to fullscreen")
    }
    
    /// Exit fullscreen
    func exitFullscreen() {
        isFullscreen = false
        print("📺 [VideoManager] Exited fullscreen")
    }
    
    /// Stop current playback and restore UI
    func stopCurrentPlayback() {
        // Stop progress monitoring
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Stop YouTube
        if let yt = youtubePlayer {
            yt.pause()
        }
        youtubePlayer = nil
        
        // Stop native
        if let native = nativePlayer {
            native.pause()
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: native.currentItem
            )
        }
        nativePlayer = nil
        
        // Reset state
        let wasPlaying = activeVideoID != nil
        activeVideoID = nil
        isFullscreen = false
        playbackProgress = 0
        currentTime = 0
        duration = 0
        onPlaybackComplete = nil
        
        // Notify header it can resume
        if wasPlaying {
            onGameVideoEnded?()
        }
        
        print("⏹️ [VideoManager] Stopped playback")
    }
    
    /// Check if a specific game's video is currently playing
    func isPlaying(gameID: String) -> Bool {
        return activeVideoID == gameID && !isFullscreen
    }
    
    /// Check if a specific game's video is in fullscreen
    func isInFullscreen(gameID: String) -> Bool {
        return activeVideoID == gameID && isFullscreen
    }
    
    // MARK: - Private Methods
    
    private func startProgressMonitoring() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollYouTubeProgress()
            }
        }
    }
    
    private func pollYouTubeProgress() {
        guard let yt = youtubePlayer else { return }
        
        yt.samplePlayback { [weak self] snapshot in
            guard let self = self else { return }
            
            if let current = snapshot.current, let dur = snapshot.duration, dur > 0 {
                self.currentTime = current
                self.duration = dur
                self.playbackProgress = Float(current / dur)
                
                // Check if video ended
                if snapshot.state == .ended {
                    self.handlePlaybackComplete()
                }
            }
        }
    }
    
    private func startNativeProgressMonitoring() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollNativeProgress()
            }
        }
    }
    
    private func pollNativeProgress() {
        guard let player = nativePlayer else { return }
        
        let current = player.currentTime().seconds
        let dur = player.currentItem?.duration.seconds ?? 0
        
        if current.isFinite && dur.isFinite && dur > 0 {
            self.currentTime = current
            self.duration = dur
            self.playbackProgress = Float(current / dur)
        }
    }
    
    @objc private func nativeVideoDidEnd() {
        handlePlaybackComplete()
    }
    
    private func handlePlaybackComplete() {
        print("🏁 [VideoManager] Playback complete")
        
        // Call completion handler
        onPlaybackComplete?()
        
        // Stop and clean up
        stopCurrentPlayback()
    }
}

// MARK: - Video Playback State for Views

struct GameVideoState: Equatable {
    let isPlaying: Bool
    let isFullscreen: Bool
    let isMuted: Bool
    let progress: Float
    
    static let idle = GameVideoState(isPlaying: false, isFullscreen: false, isMuted: false, progress: 0)
}