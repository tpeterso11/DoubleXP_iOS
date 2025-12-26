//
//  Untitled.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

struct CustomYouTubePlayerView: UIViewRepresentable {
    let videoID: String
    let isVisible: Bool // Used to control play/pause

    func makeUIView(context: Context) -> YouTubePlayerView {
        let playerView = YouTubePlayerView()
        // Load the video, but don't autoplay. Mute for carousel.
        // `updateUIView` will handle playback.
        playerView.load(videoID: videoID, shouldAutoplay: false, playerVars: ["mute": 1])
        return playerView
    }

    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // When the `isVisible` state changes (from the carousel),
        // play or pause the video.
        if isVisible {
            uiView.play()
        } else {
            uiView.pause()
        }
    }
}

// MARK: - 4. SwiftUI View for ImageCache
// This new struct uses your ImageCache actor to load images
struct CachedAsyncImageView: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3) // Placeholder
            }
        }
        .task(id: url) { // This .task modifier re-runs if the URL changes
            self.image = await ImageCache.shared.image(for: url)
        }
    }
}


// MARK: - 5. Data Models for Carousel Items
// We use an enum to define the different media types
enum CarouselMediaItemType: Hashable {
    case image(URL)
    case nativeVideo(URL)
    case youtubeVideo(id: String)
}

struct CarouselMediaItem: Identifiable, Hashable {
    let id: String // --- FIXED: Changed from UUID to String ---
    let mediaType: CarouselMediaItemType
    let title: String
    let subtitle: String?
    
    // Properties needed for action handlers
    let gameID: String?
    let showTrailerButton: Bool
    
    // --- Mapped from FeedHeaderMediaObj ---
    // This initializer bridges the gap from your VM's data
    // to the data the View needs.
    init(mediaObj: FeedHeaderMediaObj) {
        self.id = mediaObj.id // --- FIXED: String = String ---
        self.title = mediaObj.title ?? "Untitled"
        self.subtitle = mediaObj.description
        self.gameID = mediaObj.gameID
        self.showTrailerButton = mediaObj.showTrailerButton
        
        switch mediaObj.media {
        case .image:
            // --- FIXED: Handle String? to URL conversion ---
            let url = URL(string: mediaObj.imgUrl ?? "")
            self.mediaType = .image(url ?? URL(string: "https://placehold.co/800x600/FF0000/white?text=Error")!)
        case .youtube(let videoID):
            self.mediaType = .youtubeVideo(id: videoID)
        case .nativeVideo(let url):
            self.mediaType = .nativeVideo(url)
        }
    }
    
    // --- ADDED: Conformance for String ID ---
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CarouselMediaItem, rhs: CarouselMediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct CarouselActions {
    var onPrimaryAction: (CarouselMediaItem) -> Void
    var onSecondaryAction: (CarouselMediaItem) -> Void
    var onItemAppear: (CarouselMediaItem) -> Void
    var onItemDisappear: (CarouselMediaItem) -> Void
}

// MARK: - 6. The New Carousel Header Component
// This is the same as before, but it now uses your components
private struct ButtonRowFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

/// Perf-friendly dot
private struct PagerDot: View {
    let isActive: Bool
    var body: some View {
        Circle()
            .fill(isActive ? Color.white : Color.white.opacity(0.5))
            .frame(width: 8, height: 8)
            .scaleEffect(isActive ? 1.0 : 0.9)
    }
}

private extension AnyTransition {
    static var lightFallFade: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: -2)),
            removal: .opacity.combined(with: .offset(y: 8))
        )
    }
}

// MARK: - Header

private struct FullscreenNativePlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let startSeconds: Double

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.modalPresentationCapturesStatusBarAppearance = true
        vc.entersFullScreenWhenPlaybackBegins = true
        vc.exitsFullScreenWhenPlaybackEnds = true
        vc.showsPlaybackControls = true
        player.seek(to: CMTime(seconds: startSeconds, preferredTimescale: 600))
        player.play()
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player = player
    }
}

private struct FullscreenYouTubePlayer: UIViewRepresentable {
    let videoID: String
    let startSeconds: Double
    let muted: Bool

    func makeUIView(context: Context) -> YouTubePlayerView {
        let v = YouTubePlayerView()
        v.load(videoID: videoID, shouldAutoplay: true, startTime: startSeconds)
        if muted { v.mute() } else { v.unmute() }
        return v
    }
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // no-op
    }
}

// MARK: - Header

struct NewSwiftyCarouselHeader: View {
    let items: [CarouselMediaItem]
    let actions: CarouselActions

    // --- Parallax inputs ---
    let scrollOffset: CGFloat
    let headerHeight: CGFloat

    // Paging / selection
    @State private var currentItemID: String?
    @State private var currentIndex: Int = 0

    // Timers / observers
    @State private var timer: Timer?
    @State private var youtubeMonitor: Timer?
    @State private var youtubeHealthTimer: Timer?
    @State private var youtubeReadyTimeout: Timer?
    @State private var nativeReadyPollers: [String: Timer] = [:]
    @State private var nativeBoundaryObservers: [String: Any] = [:]
    @State private var nativeHealthTimer: Timer?

    // Overlay fade timers
    @State private var overlayTextFadeTimer: Timer?
    @State private var overlayButtonsFadeTimer: Timer?

    // Media registries
    @State private var videoPlayers: [String: AVPlayer] = [:]
    @State private var youtubePlayerRefs: [String: YouTubePlayerView] = [:]
    @State private var preloadTask: Task<Void, Never>?
    @State private var isMuted: Bool = true

    // Dropped items
    @State private var droppedItemIDs: Set<String> = []

    // Health tracking
    @State private var lastNativeSecond: Double = 0
    @State private var nativeStallTicks: Int = 0
    @State private var nativePlayedAccum: Double = 0
    @State private var lastYouTubeSecond: Double = 0
    @State private var youTubeStallTicks: Int = 0
    @State private var ytDurationNilTicks: Int = 0
    @State private var ytPlayedAccum: Double = 0

    // Cached parallax
    @State private var cachedContainerHeight: CGFloat = 280
    @State private var cachedMediaHeight: CGFloat = 280
    @State private var cachedParallaxOffset: CGFloat = 0
    
    @State private var videoLoadStartTimes: [String: Date] = [:]
    @State private var videoFirstPlayTimes: [String: Date] = [:]
    @State private var videoHasEverPlayed: [String: Bool] = [:]
    @Binding var isActive: Bool

    // Collapse helpers
    private var minHeaderHeight: CGFloat { headerHeight * 0.7 }
    private var collapseProgress: CGFloat {
        let clamped = max(minHeaderHeight, min(cachedContainerHeight, headerHeight))
        let range = headerHeight - minHeaderHeight
        guard range > 0 else { return 1 }
        return 1 - ((clamped - minHeaderHeight) / range) // 0 expanded → 1 collapsed
    }
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    // Time-based fades
    private let overlayFadeAt: TimeInterval = 7.0
    private let buttonsFinalOpacity: Double = 0.4

    // Scroll-restore hysteresis + direction
    @State private var hasRestoredForCurrentExpand: Bool = false
    @State private var lastCollapseProgress: CGFloat = 1.0

    // Config
    private let imageHoldDuration: TimeInterval = 30.0
    private let transitionBeforeEndBuffer: TimeInterval = 3.0
    private let adjacentLoadDistance: Int = 1
    private let healthInterval: TimeInterval = 0.5
    private let readyTimeoutSeconds: TimeInterval = 12.0  // Increased to 12s
    private let stallTickThresholdYouTube: Int = 12  // Increased to 12 ticks (6 seconds of stalling)
    private let stallTickThresholdNative: Int = 12  // Increased to 12 ticks (6 seconds of stalling)
    private let minimumPlaybackSeconds: Double = 3.0  // Must have played for at least 3 seconds
    private let minimumTimeElapsed: Double = 6.0  // Must have been active for at least 6 seconds

    private let initialLoadTimeoutSeconds: TimeInterval = 15.0  // Time to start playing
    private let stallCheckInterval: TimeInterval = 2.0  // Check every 2 seconds instead of 0.5
    private let consecutiveStallsBeforeDrop: Int = 5  // Need 5 consecutive stalls (10 seconds)
    private let minimumSuccessfulPlayback: Double = 5.0  // If played 5+ seconds, never drop
    
    // Fullscreen state
    enum FullscreenKind {
        case none
        case native(player: AVPlayer, start: Double)
        case youtube(id: String, start: Double)
    }
    @State private var fullscreen: FullscreenKind = .none
    @State private var showFullscreen = false
    @State private var suppressInlineForCurrent = false

    // Geometry
    @State private var buttonRowFrame: CGRect = .zero // stored in .global space

    // Overlay opacities (time-based)
    @State private var overlayTextOpacity: Double = 1.0
    @State private var overlayButtonsOpacity: Double = 1.0

    // Convenience
    private var activeItems: [CarouselMediaItem] { items.filter { !droppedItemIDs.contains($0.id) } }
    private var currentItem: CarouselMediaItem? {
        guard let currentItemID else { return nil }
        return activeItems.first(where: { $0.id == currentItemID })
    }
    private var isCurrentVideo: Bool {
        guard let currentItem else { return false }
        switch currentItem.mediaType {
        case .image: return false
        case .nativeVideo, .youtubeVideo: return true
        }
    }

    // Scroll-driven text factor (0..1)
    private var textScrollFactor: Double {
        max(0, min(1, 1 - collapseProgress))
    }
    private var effectiveTextOpacity: Double {
        (isCurrentVideo ? overlayTextOpacity : 1.0) * textScrollFactor
    }

    // Swipe gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in handleSwipe(translation: value.translation.width) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Media pager
            GeometryReader { proxy in
                let pageWidth = proxy.size.width
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(activeItems) { item in
                            ZStack {
                                // Suppress only the currently-selected inline when fullscreen is showing
                                if !(suppressInlineForCurrent && item.id == currentItemID) {
                                    mediaView(for: item)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Color.black // inline "ended"
                                }
                            }
                            .frame(width: pageWidth, height: cachedMediaHeight)
                            .clipped(antialiased: true)
                            .containerRelativeFrame(.horizontal)
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentItemID)
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: cachedContainerHeight)
                .offset(y: cachedParallaxOffset)
                .clipped(antialiased: true)
                .allowsHitTesting(false)
            }

            // Overlay
            overlayView
                .offset(y: cachedParallaxOffset)
                .highPriorityGesture(swipeGesture)
                .coordinateSpace(name: "headerOverlay")
                .onPreferenceChange(ButtonRowFrameKey.self) { buttonRowFrame = $0 }

            // Dots
            pagerView
                .offset(y: cachedParallaxOffset)

            // Traveling mute (videos only)
            if isCurrentVideo {
                translatingMuteButton
                    .offset(y: cachedParallaxOffset)
                    .opacity(overlayButtonsOpacity)
                    .highPriorityGesture(swipeGesture)
            }
        }
        .frame(height: cachedContainerHeight)
        .clipped()
        .contentShape(Rectangle())
        .highPriorityGesture(swipeGesture)
        .onAppear { updateParallaxCache(); startAutoScroll(); preloadAdjacentMedia() }
        .onDisappear { stopAllScheduling(); cleanupAllPlayers(); preloadTask?.cancel() }
        .onChange(of: scrollOffset) { _, _ in updateParallaxCache() }
        .onChange(of: currentItemID) { old, new in handleItemChange(from: old, to: new) }
        .onChange(of: isMuted) { _, v in updateMuteState(muted: v) }
        .fullScreenCover(isPresented: $showFullscreen, onDismiss: { handleFullscreenDismissAdvance() }) {
            switch fullscreen {
            case .none:
                EmptyView()
            case .native(let player, let start):
                FullscreenNativePlayer(player: player, startSeconds: start).ignoresSafeArea()
            case .youtube(let id, let start):
                FullscreenYouTubePlayer(videoID: id, startSeconds: start, muted: isMuted).ignoresSafeArea()
            }
        }.onChange(of: isActive) { oldValue, newValue in
            print("🎬 [Carousel] Active state changed: \(oldValue) -> \(newValue)")
            if !newValue {
                print("   ⏸️ Pausing carousel - stopping all timers and videos")
                // Stop ALL scheduling (timers, monitors, observers)
                stopAllScheduling()
                
                // Pause all video players
                videoPlayers.values.forEach { $0.pause() }
                youtubePlayerRefs.values.forEach { $0.pause() }
                
                // Cancel any ongoing preload tasks
                preloadTask?.cancel()
                
            } else {
                print("   ▶️ Resuming carousel")
                // Cancel preload task before starting new one
                preloadTask?.cancel()
                
                // Resume scheduling for current item
                if let currentItem {
                    scheduleForCurrentItem()
                }
                
                // Restart preloading
                preloadAdjacentMedia()
            }
        }
    }
    
    private func handleFullscreenDismissAdvance() {
        // inline was "ended" while fullscreen; just move on
        suppressInlineForCurrent = false
        withAnimation(.easeInOut(duration: 0.25)) {
            scrollToNextItem()
        }
        stopAllScheduling()
        scheduleForCurrentItem()
    }

    // MARK: - Parallax & restore
    private func updateParallaxCache() {
        let minHeight = minHeaderHeight
        let expandedHeight = headerHeight + scrollOffset
        let newContainerHeight = max(minHeight, expandedHeight)
        let newMediaHeight = max(minHeight, headerHeight + max(0, scrollOffset))
        if abs(cachedContainerHeight - newContainerHeight) > 0.1 { cachedContainerHeight = newContainerHeight }
        if abs(cachedMediaHeight - newMediaHeight) > 0.1 { cachedMediaHeight = newMediaHeight }
        if cachedParallaxOffset != 0 { cachedParallaxOffset = 0 }

        let cp = collapseProgress
        if cp < 0.15, lastCollapseProgress >= 0.15, !hasRestoredForCurrentExpand {
            restoreOverlaysAndRestartTimersIfNeeded()
            hasRestoredForCurrentExpand = true
        }
        if cp > 0.35 { hasRestoredForCurrentExpand = false }
        lastCollapseProgress = cp
    }

    private func restoreOverlaysAndRestartTimersIfNeeded() {
        withAnimation(.easeOut(duration: 0.18)) {
            overlayTextOpacity = 1.0
            overlayButtonsOpacity = 1.0
        }
        cancelOverlayFadeTimers()
        if isCurrentVideo { startOverlayFadeTimersForVideo() }
    }

    // MARK: - Media
    @ViewBuilder
    private func mediaView(for item: CarouselMediaItem) -> some View {
        let isCurrentOrAdjacent = shouldLoadMedia(for: item)
        let shouldShowVideo = isActive && item.id == currentItemID && !suppressInlineForCurrent
        
        ZStack {
            if isCurrentOrAdjacent {
                switch item.mediaType {
                case .image(let url):
                    OptimizedImageView(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .clipped()
                case .nativeVideo(let url):
                    NativeVideoView(
                        itemID: item.id,
                        url: url,
                        isVisible: shouldShowVideo,
                        isMuted: isMuted,
                        playerGetter: { getOrCreatePlayer(for: item.id, url: url) },
                        onPlayerCreated: { player in videoPlayers[item.id] = player }
                    )
                case .youtubeVideo(let id):
                    HeaderYouTubePlayerRepresentable(
                        videoID: id,
                        isVisible: shouldShowVideo,
                        isMuted: isMuted,
                        onPlayerReady: { playerView in youtubePlayerRefs[item.id] = playerView }
                    )
                }
            } else {
                Color.black.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
    }

    private func shouldLoadMedia(for item: CarouselMediaItem) -> Bool {
        guard let currentIndex = activeItems.firstIndex(where: { $0.id == currentItemID }),
              let itemIndex = activeItems.firstIndex(where: { $0.id == item.id }) else { return false }
        return abs(itemIndex - currentIndex) <= adjacentLoadDistance
    }

    // MARK: - Players
    private func getOrCreatePlayer(for itemID: String, url: URL) -> AVPlayer {
        if let p = videoPlayers[itemID] { return p }
        return AVPlayer(url: url)
    }

    private func cleanupDistantPlayers() {
        guard let currentIndex = activeItems.firstIndex(where: { $0.id == currentItemID }) else { return }
        let keep = Set(activeItems.enumerated()
            .filter { abs($0.offset - currentIndex) <= adjacentLoadDistance }
            .map { $0.element.id })
        videoPlayers = videoPlayers.filter { keep.contains($0.key) }
        youtubePlayerRefs = youtubePlayerRefs.filter { keep.contains($0.key) }
    }

    private func cleanupAllPlayers() {
        videoPlayers.values.forEach { $0.pause() }
        videoPlayers.removeAll()
        youtubePlayerRefs.removeAll()
        videoLoadStartTimes.removeAll()
        videoFirstPlayTimes.removeAll()
        videoHasEverPlayed.removeAll()
        removeAllNativeObservers()
        cancelOverlayFadeTimers()
    }

    // MARK: - Preload
    private func preloadAdjacentMedia() {
        guard let currentIndex = activeItems.firstIndex(where: { $0.id == currentItemID }) else { return }
        preloadTask?.cancel()
        preloadTask = Task {
            var urls: [URL] = []
            for offset in -adjacentLoadDistance...adjacentLoadDistance {
                let idx = currentIndex + offset
                guard idx >= 0, idx < activeItems.count else { continue }
                if case .image(let url) = activeItems[idx].mediaType { urls.append(url) }
            }
            if !urls.isEmpty { await ImageCache.shared.preload(urls: urls) }
        }
    }

    // MARK: - Item change
    private func handleItemChange(from oldValue: String?, to newValue: String?) {
        stopAllScheduling()
        resetOverlayFades(forVideo: false)
        nativePlayedAccum = 0
        ytPlayedAccum = 0
        hasRestoredForCurrentExpand = false
        lastCollapseProgress = collapseProgress
        suppressInlineForCurrent = false

        if let newValue, let newItem = activeItems.first(where: { $0.id == newValue }) {
            actions.onItemAppear(newItem)
            if let idx = activeItems.firstIndex(where: { $0.id == newValue }) { currentIndex = idx }
            currentActivatedAt = Date()
            preloadAdjacentMedia()
            cleanupDistantPlayers()
            scheduleForCurrentItem()
        }
        if let oldValue, let oldItem = items.first(where: { $0.id == oldValue }) {
            actions.onItemDisappear(oldItem)
        }
    }

    // MARK: - Overlay UI
    private var overlayView: some View {
        ZStack(alignment: .bottomLeading) {
            VStack { Spacer()
                LinearGradient(colors: [.black.opacity(0.8), .black.opacity(0)],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 180)
            }
            VStack(alignment: .leading, spacing: 10) {
                if let currentItem {
                    // Title/subtitle (time × scroll)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentItem.title)
                            .font(.title2.bold())
                            .lineLimit(2)
                            .opacity(effectiveTextOpacity)
                        if let subtitle = currentItem.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .lineLimit(2)
                                .opacity(effectiveTextOpacity)
                        }
                    }

                    // Buttons (relevant; time fade only)
                    HStack(spacing: 12) {
                        switch currentItem.mediaType {
                        case .nativeVideo, .youtubeVideo:
                            Button(action: { requestFullscreenPlay() }) {
                                HStack(spacing: 6) { Image(systemName: "play.fill"); Text("Play") }
                                    .font(.body.bold())
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                            }
                        case .image:
                            EmptyView()
                        }

                        Button(action: { actions.onSecondaryAction(currentItem) }) {
                            HStack(spacing: 6) { Image(systemName: "info.circle"); Text("Details") }
                                .font(.body.bold())
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Color.white.opacity(0.18))
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }

                        Spacer(minLength: 8)
                    }
                    .opacity(isCurrentVideo ? overlayButtonsOpacity : 1.0)
                    .padding(.top, 4)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ButtonRowFrameKey.self,
                                value: proxy.frame(in: .global) // store GLOBAL frame
                            )
                        }
                    )
                }
            }
            .foregroundStyle(.white)
            .shadow(radius: 5)
            .padding(20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Traveling mute aligned to button row
    private var translatingMuteButton: some View {
        GeometryReader { container in
            // GLOBAL frames
            let containerGlobal = container.frame(in: .global)
            let rowGlobal = buttonRowFrame

            let buttonSize: CGFloat = 44
            let topPad: CGFloat = 50
            let rightPad: CGFloat = 16
            let overlayPad: CGFloat = 20
            let collapsedLift: CGFloat = 10

            // START (corner) in container coords
            let startX = container.size.width - rightPad - buttonSize/2
            let startY = topPad + buttonSize/2

            // Convert rowGlobal -> container coords
            let hasRow = !rowGlobal.isEmpty
            let rowMaxXInContainer = hasRow ? (rowGlobal.maxX - containerGlobal.minX) : 0
            let rowMidYInContainer = hasRow ? (rowGlobal.midY - containerGlobal.minY) : 0

            // Target Y: exactly midY of row (slightly lifted), clamped within header
            let minY = topPad + buttonSize/2
            let maxY = container.size.height - buttonSize/2 - 16
            let targetY = min(max((hasRow ? rowMidYInContainer : startY) - collapsedLift, minY), maxY)

            // Target X: to the right edge of the row (or near right)
            let gap: CGFloat = 8
            let targetX: CGFloat = {
                if hasRow {
                    let x = min(container.size.width - overlayPad - buttonSize/2,
                                rowMaxXInContainer + gap + buttonSize/2)
                    return max(buttonSize/2 + overlayPad, x)
                } else {
                    return container.size.width - overlayPad - buttonSize/2
                }
            }()

            let x = lerp(startX, targetX, collapseProgress)
            let y = lerp(startY, targetY, collapseProgress)

            Button(action: { isMuted.toggle() }) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .position(x: x, y: y)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .allowsHitTesting(true)
    }

    // MARK: - Dots
    private var pagerView: some View {
        HStack(spacing: 6) {
            ForEach(activeItems, id: \.id) { item in
                PagerDot(isActive: (currentItemID == item.id))
                    .transition(.lightFallFade)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
        .padding(.bottom, 10)
    }

    // MARK: - Swipe
    private func handleSwipe(translation: CGFloat) {
        guard let currentIndex = activeItems.firstIndex(where: { $0.id == currentItemID }) else { return }
        let targetIndex = translation < 0 ? min(currentIndex + 1, activeItems.count - 1)
                                          : max(currentIndex - 1, 0)
        if targetIndex != currentIndex {
            let targetID = activeItems[targetIndex].id
            withAnimation(.easeOut(duration: 0.25)) { currentItemID = targetID }
        }
    }

    // MARK: - Mute
    private func updateMuteState(muted: Bool) {
        videoPlayers.values.forEach { $0.isMuted = muted }
        youtubePlayerRefs.values.forEach { muted ? $0.mute() : $0.unmute() }
    }

    // MARK: - Fullscreen request
    private func requestFullscreenPlay() {
        guard let currentItem else { return }
        stopAllScheduling()                 // stop timers/auto-advance
        suppressInlineForCurrent = true     // "end" inline feed video

        switch currentItem.mediaType {
        case .nativeVideo:
            guard let player = videoPlayers[currentItem.id] else { return }
            let t = player.currentTime().seconds
            fullscreen = .native(player: player, start: max(0, t))
            showFullscreen = true

        case .youtubeVideo(let vid):
            if let yt = youtubePlayerRefs[currentItem.id] {
                yt.samplePlayback { snapshot in
                    let t = max(0, snapshot.current ?? 0)
                    fullscreen = .youtube(id: vid, start: t)
                    showFullscreen = true
                }
            } else {
                fullscreen = .youtube(id: vid, start: 0)
                showFullscreen = true
            }

        case .image:
            // no-op
            break
        }
    }

    // MARK: - Auto-scroll / scheduling (unchanged core)
    private func startAutoScroll() {
        guard !activeItems.isEmpty else { return }
        if currentItemID == nil {
            let firstItem = activeItems.first
            currentItemID = firstItem?.id
            if let firstItem { actions.onItemAppear(firstItem) }
        }
        scheduleForCurrentItem()
    }

    private func stopAllScheduling() {
        timer?.invalidate(); timer = nil
        youtubeMonitor?.invalidate(); youtubeMonitor = nil
        youtubeHealthTimer?.invalidate(); youtubeHealthTimer = nil
        youtubeReadyTimeout?.invalidate(); youtubeReadyTimeout = nil
        nativeReadyPollers.values.forEach { $0.invalidate() }
        nativeReadyPollers.removeAll()
        nativeHealthTimer?.invalidate(); nativeHealthTimer = nil
        removeAllNativeObservers()
        cancelOverlayFadeTimers()
        nativeStallTicks = 0; lastNativeSecond = 0; nativePlayedAccum = 0
        youTubeStallTicks = 0; lastYouTubeSecond = 0; ytDurationNilTicks = 0; ytPlayedAccum = 0
    }

    private func resetOverlayFades(forVideo: Bool) {
        cancelOverlayFadeTimers()
        overlayTextOpacity = 1.0
        overlayButtonsOpacity = 1.0
    }

    private func scheduleForCurrentItem() {
        guard let currentItem else { return }

        switch currentItem.mediaType {
        case .image:
            resetOverlayFades(forVideo: false)
            timer = Timer.scheduledTimer(withTimeInterval: imageHoldDuration, repeats: false) { [self] _ in
                scrollToNextItem()
            }

        case .nativeVideo:
            resetOverlayFades(forVideo: true)
            scheduleNativeBoundary(for: currentItem.id)
            startNativeHealthMonitoring(for: currentItem.id)
            startOverlayFadeTimersForVideo()

        case .youtubeVideo:
            resetOverlayFades(forVideo: true)
            startYouTubeProgressMonitoring(for: currentItem.id)
            startYouTubeHealthMonitoring(for: currentItem.id)
            startOverlayFadeTimersForVideo()
        }
    }

    private func startOverlayFadeTimersForVideo() {
        cancelOverlayFadeTimers()
        overlayTextFadeTimer = Timer.scheduledTimer(withTimeInterval: overlayFadeAt, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.35)) { overlayTextOpacity = 0.0 }
        }
        overlayButtonsFadeTimer = Timer.scheduledTimer(withTimeInterval: overlayFadeAt, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.35)) { overlayButtonsOpacity = buttonsFinalOpacity }
        }
    }

    private func cancelOverlayFadeTimers() {
        overlayTextFadeTimer?.invalidate(); overlayTextFadeTimer = nil
        overlayButtonsFadeTimer?.invalidate(); overlayButtonsFadeTimer = nil
    }

    // MARK: - Native boundary / health
    private func scheduleNativeBoundary(for itemID: String) {
        removeNativeObserver(for: itemID)
        nativeReadyPollers[itemID]?.invalidate()
        nativeReadyPollers[itemID] = nil

        var attempts = 0
        let poller = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [self] t in
            attempts += 1
            let elapsed = Double(attempts) * 0.2

            // If user swiped away, stop polling this item silently.
            guard currentItemID == itemID else {
                t.invalidate(); nativeReadyPollers[itemID] = nil
                return
            }

            guard let player = videoPlayers[itemID] else {
                if elapsed >= readyTimeoutSeconds, secondsSinceActivated(for: itemID) >= minimumTimeElapsed {
                    t.invalidate(); nativeReadyPollers[itemID] = nil
                    dropItemAndAdvance(id: itemID, reason: "native-player-missing")
                }
                return
            }

            let seconds = player.currentItem?.asset.duration.seconds ?? 0
            if seconds.isFinite, seconds > 0 {
                t.invalidate(); nativeReadyPollers[itemID] = nil
                addBoundaryObserver(for: itemID, player: player, totalSeconds: seconds)
                player.play()
            } else if elapsed >= readyTimeoutSeconds, secondsSinceActivated(for: itemID) >= minimumTimeElapsed {
                t.invalidate(); nativeReadyPollers[itemID] = nil
                dropItemAndAdvance(id: itemID, reason: "native-duration-unknown")
            }
        }
        nativeReadyPollers[itemID] = poller
    }

    private func addBoundaryObserver(for itemID: String, player: AVPlayer, totalSeconds: Double) {
        removeNativeObserver(for: itemID)
        let fireAt = max(0, totalSeconds - transitionBeforeEndBuffer)
        let time = CMTime(seconds: fireAt, preferredTimescale: 600)
        let token = player.addBoundaryTimeObserver(forTimes: [NSValue(time: time)], queue: .main) { [self] in
            scrollToNextItem()
        }
        nativeBoundaryObservers[itemID] = token
    }

    private func removeNativeObserver(for itemID: String) {
        if let token = nativeBoundaryObservers[itemID], let player = videoPlayers[itemID] {
            player.removeTimeObserver(token)
        }
        nativeBoundaryObservers[itemID] = nil
    }

    private func removeAllNativeObservers() {
        for (id, token) in nativeBoundaryObservers {
            if let player = videoPlayers[id] { player.removeTimeObserver(token) }
        }
        nativeBoundaryObservers.removeAll()
    }

    private func startNativeHealthMonitoring(for itemID: String) {
        nativeHealthTimer?.invalidate()
        nativeStallTicks = 0
        nativePlayedAccum = 0
        lastNativeSecond = 0
        
        // Mark when we started trying to load this video
        if videoLoadStartTimes[itemID] == nil {
            videoLoadStartTimes[itemID] = Date()
        }

        nativeHealthTimer = Timer.scheduledTimer(withTimeInterval: stallCheckInterval, repeats: true) { [self] _ in
            guard currentItemID == itemID, let player = videoPlayers[itemID] else { return }

            let currentTime = player.currentTime().seconds
            let timeElapsed = secondsSinceActivated(for: itemID)
            
            // Track actual playback progress
            if currentTime.isFinite, currentTime > lastNativeSecond {
                let delta = currentTime - lastNativeSecond
                nativePlayedAccum += delta
                lastNativeSecond = currentTime
                
                // Mark that this video has successfully played
                if !videoHasEverPlayed[itemID, default: false] {
                    videoHasEverPlayed[itemID] = true
                    videoFirstPlayTimes[itemID] = Date()
                }
                
                // Reset stall counter when making progress
                nativeStallTicks = 0
            }
            
            // NEVER drop a video that has played successfully for the minimum duration
            if nativePlayedAccum >= minimumSuccessfulPlayback {
                return
            }
            
            // Check if video is actively playing or buffering
            let isPlaying = player.rate > 0.01
            let isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            
            if isPlaying || isBuffering {
                nativeStallTicks = 0
                return
            }
            
            // Only check for initial load failure if enough time has passed
            let loadTime = Date().timeIntervalSince(videoLoadStartTimes[itemID] ?? Date())
            if !videoHasEverPlayed[itemID, default: false] && loadTime > initialLoadTimeoutSeconds {
                dropItemAndAdvance(id: itemID, reason: "native-failed-to-load")
                return
            }
            
            // If video has started playing, only drop after many consecutive stalls
            if videoHasEverPlayed[itemID, default: false] {
                nativeStallTicks += 1
                
                if nativeStallTicks >= consecutiveStallsBeforeDrop {
                    // Extra safety: check if video actually ended naturally
                    if let duration = player.currentItem?.duration.seconds,
                       duration.isFinite,
                       currentTime >= duration - 1.0 {
                        // Video ended naturally, advance normally
                        scrollToNextItem()
                    } else {
                        dropItemAndAdvance(id: itemID, reason: "native-persistent-stall")
                    }
                }
            }
        }
    }
    
    // MARK: - YouTube monitors
    private func startYouTubeHealthMonitoring(for itemID: String) {
        youtubeHealthTimer?.invalidate()
        youTubeStallTicks = 0
        ytDurationNilTicks = 0
        ytPlayedAccum = 0
        lastYouTubeSecond = 0
        
        if videoLoadStartTimes[itemID] == nil {
            videoLoadStartTimes[itemID] = Date()
        }

        youtubeHealthTimer = Timer.scheduledTimer(withTimeInterval: stallCheckInterval, repeats: true) { [self] _ in
            guard currentItemID == itemID, let yt = youtubePlayerRefs[itemID] else {
                print("❌ [YT-Health] Guard failed - itemID: \(itemID), currentItemID: \(currentItemID ?? "nil")")
                return
            }

            yt.samplePlayback { snapshot in
                let ready = yt.isPlayerReady
                let duration = snapshot.duration ?? 0
                let currentTime = snapshot.current ?? 0
                let loadTime = Date().timeIntervalSince(videoLoadStartTimes[itemID] ?? Date())
                
                print("📊 [YT-Health] itemID: \(itemID), ready: \(ready), duration: \(duration), current: \(currentTime), played: \(ytPlayedAccum)")
                
                // Track actual playback progress
                if currentTime > lastYouTubeSecond {
                    let delta = currentTime - lastYouTubeSecond
                    ytPlayedAccum += delta
                    lastYouTubeSecond = currentTime
                    
                    print("✅ [YT-Health] Progress! delta: \(delta), totalPlayed: \(ytPlayedAccum)")
                    
                    if !videoHasEverPlayed[itemID, default: false] {
                        videoHasEverPlayed[itemID] = true
                        videoFirstPlayTimes[itemID] = Date()
                        print("🎬 [YT-Health] First play detected!")
                    }
                    
                    youTubeStallTicks = 0
                    ytDurationNilTicks = 0
                }
                
                // Check for initial load failure
                if !ready && loadTime > initialLoadTimeoutSeconds && !videoHasEverPlayed[itemID, default: false] {
                    print("🚫 [YT-Health] Failed to load - dropping")
                    dropItemAndAdvance(id: itemID, reason: "youtube-failed-to-load")
                    return
                }
                
                if !ready {
                    print("⏳ [YT-Health] Not ready yet, waiting...")
                    return
                }
                
                // Check for persistent invalid duration
                if duration <= 0 {
                    ytDurationNilTicks += 1
                    print("⚠️ [YT-Health] Invalid duration, tick: \(ytDurationNilTicks)/\(consecutiveStallsBeforeDrop)")
                    if ytDurationNilTicks >= consecutiveStallsBeforeDrop && !videoHasEverPlayed[itemID, default: false] {
                        print("🚫 [YT-Health] Invalid duration timeout - dropping")
                        dropItemAndAdvance(id: itemID, reason: "youtube-invalid-duration")
                    }
                    return
                }
                
                // Check if video has ended naturally
                let timeUntilEnd = duration - currentTime
                print("⏱️ [YT-Health] Time until end: \(timeUntilEnd)s")
                
                if currentTime >= duration - 1.0 && duration > 0 {
                    print("🏁 [YT-Health] Video ended naturally - advancing")
                    scrollToNextItem()
                    return
                }
                
                // Only check for stalls if video HASN'T played enough yet
                if ytPlayedAccum < minimumSuccessfulPlayback {
                    if videoHasEverPlayed[itemID, default: false] {
                        let timeNotAdvancing = (currentTime <= lastYouTubeSecond + 0.001)
                        
                        if timeNotAdvancing {
                            youTubeStallTicks += 1
                            print("⚠️ [YT-Health] Stalled, tick: \(youTubeStallTicks)/\(consecutiveStallsBeforeDrop)")
                            
                            if youTubeStallTicks >= consecutiveStallsBeforeDrop {
                                print("🚫 [YT-Health] Persistent stall - dropping")
                                dropItemAndAdvance(id: itemID, reason: "youtube-persistent-stall")
                            }
                        } else {
                            youTubeStallTicks = 0
                        }
                    }
                } else {
                    print("✨ [YT-Health] Video played successfully (\(ytPlayedAccum)s), waiting for natural end")
                }
            }
        }
    }

    private func startYouTubeProgressMonitoring(for itemID: String) {
        youtubeMonitor?.invalidate()
        youtubeMonitor = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            guard let yt = youtubePlayerRefs[itemID] else { return }
            yt.samplePlayback { snapshot in
                guard let duration = snapshot.duration, let current = snapshot.current, duration > 0 else { return }
                if (duration - current) <= transitionBeforeEndBuffer {
                    stopAllScheduling()
                    scrollToNextItem()
                }
            }
        }
    }

    // MARK: - Drop & advance
    private func dropItemAndAdvance(id: String, reason: String) {
        guard !droppedItemIDs.contains(id) else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            droppedItemIDs.insert(id)
        }
        removeNativeObserver(for: id)
        videoPlayers[id]?.pause()
        videoPlayers.removeValue(forKey: id)
        youtubePlayerRefs.removeValue(forKey: id)

        if currentItemID == id {
            stopAllScheduling()
            withAnimation(.easeOut(duration: 0.25)) {
                scrollToNextItem()
            }
        }
    }

    private func scrollToNextItem() {
        guard !activeItems.isEmpty else { return }
        if let currentItemID,
           let currentIndex = activeItems.firstIndex(where: { $0.id == currentItemID }) {
            let nextIndex = (currentIndex + 1) % activeItems.count
            let nextID = activeItems[nextIndex].id
            withAnimation(.easeOut(duration: 0.25)) { self.currentItemID = nextID }
        } else if let first = activeItems.first {
            withAnimation(.easeOut(duration: 0.25)) { self.currentItemID = first.id }
        }
    }
    
    @State private var currentActivatedAt: Date? = nil
    private func secondsSinceActivated(for id: String) -> Double {
        guard currentItemID == id, let t = currentActivatedAt else { return 0 }
        return Date().timeIntervalSince(t)
    }
}

// MARK: - Optimized Image View with Cache
private struct OptimizedImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var loadTask: Task<Void, Never>?
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Color.black.opacity(0.3)
            }
        }
        .onAppear { loadImage() }
        .onDisappear { loadTask?.cancel() }
    }
    
    private func loadImage() {
        loadTask = Task {
            if let cached = await ImageCache.shared.image(for: url) {
                image = cached
            }
        }
    }
}

// MARK: - Native Video View Wrapper (Optimized)
private struct NativeVideoView: View {
    let itemID: String
    let url: URL
    let isVisible: Bool
    let isMuted: Bool
    let playerGetter: () -> AVPlayer
    let onPlayerCreated: (AVPlayer) -> Void
    
    @State private var player: AVPlayer?
    
    var body: some View {
        Group {
            if let player {
                VideoPlayerWithoutControls(player: player)
            } else {
                Color.black
            }
        }
        .onAppear {
            if player == nil {
                let newPlayer = playerGetter()
                newPlayer.isMuted = isMuted
                player = newPlayer
                onPlayerCreated(newPlayer)
            }
            
            if isVisible {
                player?.seek(to: .zero)
                player?.play()
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                player?.seek(to: .zero)
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onChange(of: isMuted) { _, newValue in
            player?.isMuted = newValue
        }
        .onDisappear {
            player?.pause()
        }
    }
}

// MARK: - Video Player Without Controls
private struct VideoPlayerWithoutControls: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.isUserInteractionEnabled = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// Add this import at the top if not already there
import AVKit

// MARK: - YouTube Video View Wrapper (Optimized)
struct HeaderYouTubePlayerRepresentable: UIViewRepresentable {
    let videoID: String
    let isVisible: Bool
    let isMuted: Bool
    let onPlayerReady: (YouTubePlayerView) -> Void

    func makeUIView(context: Context) -> YouTubePlayerView {
        let view = YouTubePlayerView(frame: .zero)
        // optional: assign a progress handler / callbacks on context.coordinator
        return view
    }

    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // No video id? Pause + resign.
        guard !videoID.isEmpty else {
            uiView.pause()
            YouTubePlaybackCoordinator.shared.resign(uiView)
            return
        }

        if isVisible {
            // Claim coordinator whenever this cell becomes the "on-screen" one
            YouTubePlaybackCoordinator.shared.claim(uiView)

            if !uiView.isPlayerReady {
                uiView.load(
                    videoID: videoID,
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
                        "mute": isMuted ? 1 : 0
                    ]
                )
            } else {
                if isMuted { uiView.mute() } else { uiView.unmute() }
                uiView.play()
            }

            // Let the carousel keep a reference to this view
            onPlayerReady(uiView)
        } else {
            // Cell no longer visible → pause + resign
            uiView.pause()
            YouTubePlaybackCoordinator.shared.resign(uiView)
        }
    }
}
