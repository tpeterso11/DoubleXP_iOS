//
//  HeroHeaderView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI
import UIKit

struct YouTubePlayerViewRepresentable: UIViewRepresentable {
    // MARK: - Inputs from SwiftUI
    let videoID: String?
    @Binding var isMuted: Bool

    // MARK: - Output to SwiftUI
    // Callback to notify the parent view of state changes
    var onStateChange: (YouTubePlayerView.PlaybackState) -> Void

    // MARK: - UIViewRepresentable Conformance

    func makeUIView(context: Context) -> YouTubePlayerView {
        let playerView = YouTubePlayerView()
        // The coordinator will handle receiving updates from the player
        context.coordinator.setupPolling(for: playerView)
        return playerView
    }

    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // This method is called whenever the SwiftUI state changes.

        // Update the video if the ID has changed
        if let videoID = videoID, context.coordinator.currentVideoID != videoID {
            uiView.load(videoID: videoID, shouldAutoplay: true)
            context.coordinator.currentVideoID = videoID
        }

        // Update the mute state if it has changed
        if context.coordinator.isMuted != isMuted {
            isMuted ? uiView.mute() : uiView.unmute()
            context.coordinator.isMuted = isMuted
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator {
        private var parent: YouTubePlayerViewRepresentable
        private var pollHandle: YouTubePlayerView.TimePollHandle?
        private var lastKnownState: YouTubePlayerView.PlaybackState = .unknown
        
        // Track state to avoid redundant calls in updateUIView
        var currentVideoID: String?
        var isMuted: Bool = true

        init(_ parent: YouTubePlayerViewRepresentable) {
            self.parent = parent
        }
        
        func setupPolling(for player: YouTubePlayerView) {
            // If there's an old poll running, stop it first
            if let pollHandle {
                player.stopTimePolling(pollHandle)
            }
            
            // Start a new poll to get state updates from the player
            self.pollHandle = player.startTimePolling(interval: 0.5) { [weak self] snapshot in
                guard let self = self else { return }

                // If the state has actually changed, notify the parent SwiftUI view
                if snapshot.state != self.lastKnownState {
                    self.lastKnownState = snapshot.state
                    self.parent.onStateChange(snapshot.state)
                }
            }
        }
    }
}


struct HeroHeaderView: View {
    // MARK: - Properties & State
    
    let media: [FeedHeaderMediaObj]
    @Binding var isFollowing: Bool
    var onClose: () -> Void
    var onPopOut: (String) -> Void
    
    // (Keep all the @State variables and computed properties as they were)
    @State private var playerState: YouTubePlayerView.PlaybackState = .unknown
    @State private var isMuted: Bool = true
    @State private var showVideo = false
    @State private var showControls = false
    @State private var showIntroUI = false

    private var currentMedia: FeedHeaderMediaObj? { media.first }
    private var currentVideoID: String? {
        guard case .youtube(let id) = currentMedia?.media else { return nil }
        return id
    }

    // MARK: - Initializers
    
    // 1. THIS IS YOUR MAIN, FULLY-CONFIGURABLE INITIALIZER
    init(
        media: [FeedHeaderMediaObj],
        isFollowing: Binding<Bool>,
        onClose: @escaping () -> Void,
        onPopOut: @escaping (String) -> Void
    ) {
        self.media = media
        self._isFollowing = isFollowing
        self.onClose = onClose
        self.onPopOut = onPopOut
    }
    
    // 2. ✨ ADD THIS NEW CONVENIENCE INITIALIZER
    // It provides default values for the parameters you don't want to specify.
    init(media: [FeedHeaderMediaObj]) {
        self.init(
            media: media,
            isFollowing: .constant(false), // A non-changeable "false" value
            onClose: {},                   // An empty closure that does nothing
            onPopOut: { _ in }             // An empty closure that does nothing
        )
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Background Image (Poster)
            posterImage
            
            // Layer 2: Video Player (Using the representable)
            if showVideo {
                YouTubePlayerViewRepresentable(
                    videoID: currentVideoID,
                    isMuted: $isMuted,
                    onStateChange: { newState in
                        // The coordinator calls this closure when the player state changes
                        self.playerState = newState
                    }
                )
                .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
            
            // Layer 3: Bottom Gradient
            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
            }
            
            // Layer 4: UI Overlay (Buttons and Title)
            overlayUI
        }
        .clipped()
        .onAppear(perform: setupView)
        .onChange(of: media, perform: { _ in resetForNewMedia() })
        .onChange(of: playerState, perform: handlePlayerStateChange)
    }
    
    // MARK: - UI Subviews
    
    @ViewBuilder
    private var posterImage: some View {
        if let urlString = currentMedia?.imgUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.black }
        } else {
            Color.black
        }
    }
    
    private var overlayUI: some View {
        VStack {
            // Top Buttons
            HStack {
                controlButton(icon: "plus", action: { isFollowing.toggle() }, isSelected: isFollowing)
                Spacer()
                controlButton(icon: "xmark", action: onClose)
            }
            .padding(.horizontal)
            .padding(.top, 50)
            .opacity(showIntroUI ? 1 : 0)
            .scaleEffect(showIntroUI ? 1 : 0.95)
            
            Spacer()
            
            // Bottom Content
            HStack(alignment: .bottom) {
                Text(currentMedia?.title ?? "")
                    .font(.system(size: 48, weight: .heavy)).foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2).lineLimit(2)
                
                Spacer()
                
                if showControls, let videoID = currentVideoID {
                    controlButton(icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", action: { isMuted.toggle() })
                    controlButton(icon: "arrow.up.left.and.arrow.down.right", action: { onPopOut(videoID) })
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private func controlButton(icon: String, action: @escaping () -> Void, isSelected: Bool? = nil) -> some View {
        Button(action: action) {
            Image(systemName: isSelected == true ? "checkmark" : icon)
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.black.opacity(0.7))
                .clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showControls)
    }

    // MARK: - Logic & State Management
    
    private func setupView() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) { showIntroUI = true }
        playVideoWithDelay()
    }
    
    private func resetForNewMedia() {
        showVideo = false
        playerState = .unknown
        playVideoWithDelay()
    }

    private func playVideoWithDelay() {
        guard currentVideoID != nil else { return }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if !Task.isCancelled { showVideo = true }
        }
    }
    
    private func handlePlayerStateChange(to newState: YouTubePlayerView.PlaybackState) {
        switch newState {
        case .playing:
            withAnimation { showControls = true }
        case .paused, .ended:
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if playerState != .playing {
                    withAnimation { showControls = false }
                }
            }
        default:
            break
        }
    }
}
