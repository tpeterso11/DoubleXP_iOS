//
//  TwitchPlayerView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/14/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit
import WebKit
import SwiftUI

// MARK: - Twitch Player View (Modernized for Efficiency)
@IBDesignable
public class TwitchPlayerView: WKWebView, WKNavigationDelegate {

    public enum Content {
        case channel(name: String)
        case video(id: String)
        case collection(id: String, videoId: String)
    }

    public enum Theme: String { case light, dark }
    public enum Layout: String { case videoWithChat = "video-with-chat", videoOnly = "video" }

    public struct Configuration {
        let content: Content
        let parentURL: URL

        var theme: Theme = .dark
        var layout: Layout = .videoOnly
        var allowsFullScreen: Bool = true
        var isMuted: Bool = true          // ← default muted to enable autoplay reliably
        var autoplay: Bool = true         // ← default to autoplay

        public init(content: Content, parentURL: URL) {
            self.content = content
            self.parentURL = parentURL
        }
    }

    // MARK: - Properties

    public var playerConfiguration: Configuration? {
        didSet { if playerConfiguration != nil { loadPlayer() } }
    }

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var isSetup = false

    // MARK: - Init

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        } else {
            configuration.requiresUserActionForMediaPlayback = false
        }
        super.init(frame: frame, configuration: configuration)
        commonInit()
    }

    public convenience init(frame: CGRect) {
        let webConfig = WKWebViewConfiguration()
        self.init(frame: frame, configuration: webConfig)
    }

    required public init?(coder: NSCoder) {
        let webConfig = WKWebViewConfiguration()
        super.init(frame: .zero, configuration: webConfig)
        commonInit()
    }

    private func commonInit() {
        guard !isSetup else { return }
        isSetup = true

        isOpaque = false
        backgroundColor = .clear
        scrollView.isScrollEnabled = false
        navigationDelegate = self

        // Disable all touch interactions on the player
        isUserInteractionEnabled = false

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Lifecycle / Controls

    public func shutdown() {
        stopLoading()
        load(URLRequest(url: URL(string: "about:blank")!))
    }

    @MainActor public func pause() async throws { try await executePlayerCommand("player.pause()") }
    @MainActor public func play()  async throws { try await executePlayerCommand("player.play()") }
    @MainActor public func seek(to timestamp: TimeInterval) async throws { try await executePlayerCommand("player.seek(\(timestamp))") }
    @MainActor public func setVolume(to level: Float) async throws {
        let clamped = max(0.0, min(1.0, level))
        try await executePlayerCommand("player.setVolume(\(clamped))")
    }
    @MainActor public func setChannel(to name: String) async throws { try await executePlayerCommand("player.setChannel('\(name)')") }
    @MainActor public func setVideo(to id: String, at timestamp: TimeInterval = 0) async throws { try await executePlayerCommand("player.setVideo('\(id)', \(timestamp))") }

    private func loadPlayer() {
        guard let config = playerConfiguration else { return }
        activityIndicator.startAnimating()
        let html = buildPlayerHTML(with: config)
        loadHTMLString(html, baseURL: config.parentURL)
    }

    @MainActor
    private func executePlayerCommand(_ command: String) async throws {
        let script = "performPlayerCommand(() => { \(command); })"
        _ = try await evaluateJavaScript(script)
    }

    private func buildPlayerHTML(with config: Configuration) -> String {
        let optionsString = buildOptionsString(for: config)
        let autoplayJS  = config.autoplay ? "true" : "false"
        let mutedJS     = config.isMuted   ? "true" : "false"

        return Self.playerHTMLTemplate
            .replacingOccurrences(of: "/* OPTIONS_PLACEHOLDER */", with: optionsString)
            .replacingOccurrences(of: "__AUTOPLAY__", with: autoplayJS)
            .replacingOccurrences(of: "__MUTED__",    with: mutedJS)
    }

    private func buildOptionsString(for config: Configuration) -> String {
        let parentDomains = [config.parentURL.host].compactMap { $0 }
        var options: [String: Any] = [
            "theme": config.theme.rawValue,
            "layout": config.layout.rawValue,
            "allowfullscreen": config.allowsFullScreen,
            "muted": config.isMuted,
            "parent": parentDomains
        ]
        switch config.content {
        case .channel(let name): options["channel"] = name
        case .video(let id): options["video"] = id
        case .collection(let id, let videoId):
            options["collection"] = id
            options["video"] = videoId
        }
        return options.map { key, value in
            if let stringValue = value as? String {
                return "'\(key)': '\(stringValue)'"
            } else if let arrayValue = value as? [String] {
                let quoted = arrayValue.map { "'\($0)'" }.joined(separator: ", ")
                return "'\(key)': [\(quoted)]"
            } else {
                return "'\(key)': \(value)"
            }
        }.joined(separator: ",\n          ")
    }

    private static let playerHTMLTemplate = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background-color:transparent;}
        #twitch-embed{width:100%;height:100%;}
      </style>
    </head>
    <body>
      <div id="twitch-embed"></div>
      <script src="https://embed.twitch.tv/embed/v1.js"></script>
      <script type="text/javascript">
        var player;
        var commandQueue=[];
        function performPlayerCommand(c){ player ? c() : commandQueue.push(c); }

        const embed = new Twitch.Embed("twitch-embed", {
          width: "100%",
          height: "100%",
          playsinline: true,
          /* OPTIONS_PLACEHOLDER */
        });

        embed.addEventListener(Twitch.Embed.VIDEO_READY, () => {
          player = embed.getPlayer();

          // Autoplay path (muted first to satisfy iOS autoplay policies)
          if (__AUTOPLAY__) {
            try { player.setMuted(__MUTED__); } catch (e) {}
            try { player.play(); } catch (e) {}
          }

          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.twitchPlayer) {
            window.webkit.messageHandlers.twitchPlayer.postMessage("ready");
          }
          while (commandQueue.length > 0) { (commandQueue.shift())(); }
        });
      </script>
    </body>
    </html>
    """

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("TwitchPlayerView failed to load: \(error.localizedDescription)")
    }

    // MARK: - IB support (unchanged)

    @IBInspectable private var channel: String?
    @IBInspectable private var videoID: String?
    @IBInspectable private var collectionID: String?
    @IBInspectable private var isDarkTheme: Bool = true
    @IBInspectable private var hasChat: Bool = false
    @IBInspectable private var allowsFS: Bool = true

    public override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
        configureFromInspectables()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
        configureFromInspectables()
    }

    private func configureFromInspectables() {
        guard let placeholderParent = URL(string: "https://www.your-domain.com") else { return }
        let content: Content
        if let channel, !channel.isEmpty {
            content = .channel(name: channel)
        } else if let videoID, !videoID.isEmpty {
            content = (collectionID?.isEmpty == false) ? .collection(id: collectionID!, videoId: videoID) : .video(id: videoID)
        } else { return }

        var config = Configuration(content: content, parentURL: placeholderParent)
        config.theme = isDarkTheme ? .dark : .light
        config.layout = hasChat ? .videoWithChat : .videoOnly
        config.allowsFullScreen = allowsFS
        config.autoplay = true
        config.isMuted = true
        self.playerConfiguration = config
    }
}


struct TwitchEmbedView: UIViewRepresentable {
    let channelName: String   // e.g. stream.userName or stream.channelName

    func makeUIView(context: Context) -> TwitchPlayerView {
        let view = TwitchPlayerView(frame: .zero)

        if let parentURL = URL(string: "https://www.doublexpapp.com") {
            var config = TwitchPlayerView.Configuration(
                content: .channel(name: channelName),
                parentURL: parentURL
            )
            config.theme = .dark
            config.layout = .videoOnly
            config.allowsFullScreen = true
            config.autoplay = true
            config.isMuted = true      // keep muted for autoplay
            view.playerConfiguration = config
        }

        return view
    }

    func updateUIView(_ uiView: TwitchPlayerView, context: Context) {
        guard let parentURL = URL(string: "https://www.doublexpapp.com") else { return }

        // If channel might change, rebuild config when it does
        var config = TwitchPlayerView.Configuration(
            content: .channel(name: channelName),
            parentURL: parentURL
        )
        config.theme = .dark
        config.layout = .videoOnly
        config.allowsFullScreen = true
        config.autoplay = true
        config.isMuted = true

        uiView.playerConfiguration = config
    }
}
