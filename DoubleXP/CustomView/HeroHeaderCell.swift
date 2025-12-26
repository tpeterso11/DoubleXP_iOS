
import AVKit
import AVFoundation
import SwiftUI

struct FeedHeaderMediaObj: Hashable, Equatable {
    enum MediaType: Hashable {
        case image(named: String)
        case youtube(videoID: String)
        case nativeVideo(url: URL)
    }

    let id: String
    let media: MediaType // This property is now Hashable
    let title: String
    let description: String
    let gameID: String
    let showTrailerButton: Bool
    let imgUrl: String?
}

// MARK: - Delegates

/*struct HeroHeaderSwiftUI: View {
    let items: [FeedHeaderMediaObj]
    var onPlayTrailer: (FeedHeaderMediaObj.MediaType) -> Void
    var onMoreDetails: (String) -> Void

    @State private var index: Int = 0
    private let fallbackProgressThreshold: Float = 0.985

    var body: some View {
        VStack(spacing: 10) {
            TabView(selection: $index) {
                ForEach(Array(items.enumerated()), id: \.element.id) { (i, item) in
                    HeaderSlide(
                        item: item,
                        fallbackThreshold: fallbackProgressThreshold,
                        onAlmostFinished: { advance(from: i) },
                        onPlayTrailer: onPlayTrailer,
                        onMoreDetails: onMoreDetails
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8) // <- add x:
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 220)
        }
    }

    private func advance(from current: Int) {
        guard items.indices.contains(current) else { return }
        let next = current + 1
        if items.indices.contains(next) {
            withAnimation(.easeInOut) { index = next }
        }
    }
}*/

/*private struct HeaderSlide: View {
    let item: FeedHeaderMediaObj
    let fallbackThreshold: Float
    var onAlmostFinished: () -> Void
    var onPlayTrailer: (FeedHeaderMediaObj.MediaType) -> Void
    var onMoreDetails: (String) -> Void

    @State private var progress: Float = 0

    /*var body: some View {
        ZStack(alignment: .bottom) {
            mediaLayer
                .contentShape(Rectangle())

            // bottom gradient + controls
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if item.showTrailerButton {
                        CapsuleButton(title: "Play Trailer", system: "play.fill") {
                            onPlayTrailer(item.media)
                        }
                    } else {
                        CapsuleButton(iconOnlySystem: "info.circle") {
                            onMoreDetails(item.gameID)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 2)

                ProgressView(value: Double(progress))
                    .tint(.white.opacity(0.9))
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)
                    .padding(.top, 4)
            }
            .padding(16)
        }
    }*/

    @ViewBuilder
    /*private var mediaLayer: some View {
        switch item.media {
        case .image(let name):
            // Prefer remote image if provided, fall back to asset name.
            if let urlStr = item.imgUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.white.opacity(0.06)
                    }
                }
            } else {
                Image(name).resizable().scaledToFill()
            }

        case .youtube(let videoID):
            YouTubePlayerRepresentable(
                videoID: videoID, isActive: true,
                isMuted: true,
                startTime: 0,
                onProgress: { p in
                    progress = p
                    if p >= fallbackThreshold { onAlmostFinished() }
                },
                onFinished: {
                    progress = 1
                    onAlmostFinished()
                }
            )

        case .nativeVideo(let url):
            AVPlayerRepresentable(
                url: url,
                isMuted: true,
                startTime: 0,
                onProgress: { p in progress = p },
                onFinished: {
                    progress = 1
                    onAlmostFinished()
                }
            )
        }
    }*/
}

private struct CapsuleButton: View {
    var title: String? = nil
    var system: String? = nil
    var iconOnlySystem: String? = nil
    var action: () -> Void

    init(title: String, system: String, action: @escaping () -> Void) {
        self.title = title; self.system = system; self.action = action
    }
    init(iconOnlySystem: String, action: @escaping () -> Void) {
        self.iconOnlySystem = iconOnlySystem; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let s = system { Image(systemName: s) }
                if let t = title { Text(t).fontWeight(.semibold) }
                if let only = iconOnlySystem, title == nil {
                    Image(systemName: only)
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct AVPlayerRepresentable: UIViewRepresentable {
    let url: URL
    var isMuted: Bool = true
    var startTime: TimeInterval = 0
    var onProgress: (Float) -> Void
    var onFinished: () -> Void

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.onProgress = onProgress
        v.onFinished = onFinished
        v.configure(url: url, isMuted: isMuted, startTime: startTime)
        return v
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // Keep callbacks fresh
        uiView.onProgress = onProgress
        uiView.onFinished = onFinished
        // Reconfigure only if needed (same URL won’t restart)
        uiView.configure(url: url, isMuted: isMuted, startTime: startTime)
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.cleanup()
    }
}

// MARK: - Backing UIView that hosts AVPlayerLayer

final class PlayerContainerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var finishedObserver: NSObjectProtocol?
    private var currentURL: URL?

    var onProgress: ((Float) -> Void)?
    var onFinished: (() -> Void)?

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as? AVPlayerLayer)?.frame = bounds
    }

    func configure(url: URL, isMuted: Bool, startTime: TimeInterval) {
        // Avoid rebuilding if nothing changed
        if currentURL == url, let player = player {
            player.isMuted = isMuted
            return
        }

        cleanup()

        currentURL = url
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = isMuted
        self.player = player

        let layer = self.layer as! AVPlayerLayer
        layer.player = player
        layer.videoGravity = .resizeAspectFill

        // Observe progress
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] current in
            guard
                let self,
                let duration = player.currentItem?.duration.seconds,
                duration.isFinite,
                duration > 0
            else { return }
            let progress = Float(current.seconds / duration)
            self.onProgress?(min(max(progress, 0), 1))
        }

        // Finished
        finishedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.onFinished?()
        }

        // Seek & play
        let t = CMTime(seconds: startTime, preferredTimescale: 600)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] _ in
            player?.play()
        }
    }

    func cleanup() {
        if let obs = finishedObserver { NotificationCenter.default.removeObserver(obs) }
        finishedObserver = nil

        if let token = timeObserver, let p = player { p.removeTimeObserver(token) }
        timeObserver = nil

        (layer as? AVPlayerLayer)?.player = nil
        player?.pause()
        player = nil
        currentURL = nil
    }

    deinit { cleanup() }
}*/
