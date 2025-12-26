//
//  YouTubeShortsService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

struct YouTubeShort: Hashable, Codable {
    let videoId: String
    let title: String
    let channelTitle: String
    let thumbnailUrl: URL?
    var id: String { videoId }
    var embedUrl: URL? {
            URL(string: "https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1&controls=0&modestbranding=1")
        }
}

// MARK: - YouTube Shorts Provider
@MainActor
final class YouTubeShortsService: ObservableObject {
    
    static let shared = YouTubeShortsService()
    
    // Published state
    @Published private(set) var shorts: [YouTubeShort] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // API configuration
    private let apiKey = "AIzaSyAyjFRqU4u2fx7_Ik5dEiDuNbXb9F0Ykjc"
    private let session: URLSession
    
    // Pagination & seen tracking
    private var nextPageToken: String?
    private var seenVideoIds: Set<String> = []
    
    // Dev flags
    var useMockData: Bool = true
    var filterSeenVideos: Bool = true
    
    // Cache keys
    private let seenVideosKey = "YouTubeShortsService.SeenVideos"
    private let cachedShortsKey = "YouTubeShortsService.CachedShorts"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
        
        if let data = UserDefaults.standard.data(forKey: seenVideosKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            seenVideoIds = decoded
        }
    }
    
    // MARK: - Public API
    
    func ensureInitialPage() async {
        guard shorts.isEmpty else { return }
        
        if useMockData {
            await loadMockData()
        } else {
            await fetchNextPage()
        }
    }
    
    func fetchNextPage() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let newShorts = await fetchGamingShorts(pageToken: nextPageToken)
        
        let filtered = filterSeenVideos
            ? newShorts.filter { !seenVideoIds.contains($0.videoId) }
            : newShorts
        
        shorts.append(contentsOf: filtered)
        isLoading = false
    }
    
    func loadMoreIfNeeded(currentShort: YouTubeShort) async {
        guard let index = shorts.firstIndex(where: { $0.videoId == currentShort.videoId }) else {
            return
        }
        
        let thresholdIndex = shorts.index(shorts.endIndex, offsetBy: -3)
        if index >= thresholdIndex && !isLoading {
            await fetchNextPage()
        }
    }
    
    func markShortSeen(_ short: YouTubeShort) {
        seenVideoIds.insert(short.videoId)
        persistSeenVideos()
    }
    
    func clearSeenVideos() {
        seenVideoIds.removeAll()
        UserDefaults.standard.removeObject(forKey: seenVideosKey)
    }
    
    func refresh() async {
        shorts.removeAll()
        nextPageToken = nil
        await fetchNextPage()
    }
    
    // MARK: - Private Fetching
    
    private func fetchGamingShorts(pageToken: String?) async -> [YouTubeShort] {
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=50&q=%23shorts%20%23gaming&type=video&videoCategoryId=20&key=\(apiKey)"
        
        if let token = pageToken {
            urlString += "&pageToken=\(token)"
        }
        
        guard let searchUrl = URL(string: urlString) else {
            print("Error: Invalid search URL")
            return []
        }
        
        do {
            let (searchData, _) = try await session.data(from: searchUrl)
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: searchData)
            
            // LOG THE RESPONSE
            print("📊 [YouTube API] Fetched \(searchResponse.items.count) search results")
            
            nextPageToken = searchResponse.nextPageToken
            
            let videoIds = searchResponse.items.map { $0.id.videoId }
            print("📊 [YouTube API] Video IDs: \(videoIds)")
            
            let details = await fetchVideoDetails(for: videoIds)
            print("📊 [YouTube API] Got details for \(details.count) videos")
            
            let shorts = details.compactMap { detail -> YouTubeShort? in
                guard let duration = parseISO8601Duration(detail.contentDetails.duration),
                      duration <= 61 else {
                    print("⏭️ [YouTube API] Skipping \(detail.id) - duration: \(detail.contentDetails.duration)")
                    return nil
                }
                
                print("✅ [YouTube API] Valid short: \(detail.id) - \(detail.snippet.title)")
                
                return YouTubeShort(
                    videoId: detail.id,
                    title: detail.snippet.title,
                    channelTitle: detail.snippet.channelTitle,
                    thumbnailUrl: URL(string: detail.snippet.thumbnails.high.url)
                )
            }
            
            print("📊 [YouTube API] Returning \(shorts.count) valid shorts")
            return shorts
            
        } catch {
            print("❌ [YouTube API] Error: \(error)")
            return []
        }
    }
    
    private func fetchVideoDetails(for videoIds: [String]) async -> [YouTubeVideoItem] {
        guard !videoIds.isEmpty else { return [] }
        
        let idsString = videoIds.joined(separator: ",")
        let detailsUrlString = "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=\(idsString)&key=\(apiKey)"
        
        guard let detailsUrl = URL(string: detailsUrlString) else { return [] }
        
        do {
            let (data, _) = try await session.data(from: detailsUrl)
            let response = try JSONDecoder().decode(YouTubeShortsListResponse.self, from: data)
            return response.items
        } catch {
            print("Error fetching video details: \(error)")
            return []
        }
    }
    
    private func loadMockData() async {
        if let data = UserDefaults.standard.data(forKey: cachedShortsKey),
           let cached = try? JSONDecoder().decode([YouTubeShort].self, from: data) {
            shorts = cached
            print("✅ Loaded \(cached.count) cached YouTube Shorts")
            return
        }
        
        let fetched = await fetchGamingShorts(pageToken: nil)
        shorts = fetched
        
        if let encoded = try? JSONEncoder().encode(fetched) {
            UserDefaults.standard.set(encoded, forKey: cachedShortsKey)
            print("💾 Cached \(fetched.count) YouTube Shorts for dev")
        }
    }
    
    private func persistSeenVideos() {
        if let encoded = try? JSONEncoder().encode(seenVideoIds) {
            UserDefaults.standard.set(encoded, forKey: seenVideosKey)
        }
    }
    
    private func parseISO8601Duration(_ durationString: String) -> TimeInterval? {
        var totalSeconds: TimeInterval = 0
        let scanner = Scanner(string: durationString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "PT")
        
        while !scanner.isAtEnd {
            var value: Double = 0
            if scanner.scanDouble(&value) {
                var unit: NSString?
                if scanner.scanCharacters(from: CharacterSet.letters, into: &unit) {
                    switch unit {
                    case "H":
                        totalSeconds += value * 3600
                    case "M":
                        totalSeconds += value * 60
                    case "S":
                        totalSeconds += value
                    default:
                        break
                    }
                }
            }
        }
        return totalSeconds > 0 ? totalSeconds : nil
    }
}


// MARK: - YouTube API Response Models

// These structs match the JSON structure from the YouTube API.

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
    let nextPageToken: String?
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeVideoId
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeShortsListResponse: Codable {
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Codable {
    let id: String
    let snippet: YouTubeSnippet
    let contentDetails: YouTubeContentDetails
}

struct YouTubeSnippet: Codable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let high: YouTubeThumbnail
}

struct YouTubeThumbnail: Codable {
    let url: String
}

struct YouTubeContentDetails: Codable {
    let duration: String
}

import UIKit
import WebKit
final class BasicYouTubePlayer: UIView {
    private let webView: WKWebView
    
    override init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: config)
        super.init(frame: frame)
        
        webView.scrollView.isScrollEnabled = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func loadVideo(videoID: String) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; }
                #player { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
                
                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1,
                            'autoplay': 1,
                            'mute': 1,
                            'controls': 1
                        },
                        events: {
                            'onReady': function(event) {
                                console.log('Player ready');
                                event.target.playVideo();
                            },
                            'onError': function(event) {
                                console.log('Error: ' + event.data);
                            },
                            'onStateChange': function(event) {
                                console.log('State: ' + event.data);
                            }
                        }
                    });
                }
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

import SwiftUI
struct BasicYouTubePlayerView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> BasicYouTubePlayer {
        let player = BasicYouTubePlayer()
        player.loadVideo(videoID: videoID)
        return player
    }
    
    func updateUIView(_ uiView: BasicYouTubePlayer, context: Context) {
        // Nothing to update
    }
}
