//
//  YouTubeRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import GoogleSignIn
import FirebaseDatabase

// MARK: - YouTube Request Manager

@MainActor
final class YouTubeRequestManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = YouTubeRequestManager()
    
    // MARK: - Properties
    
    @Published private(set) var connectionState: GoogleConnectionState = .disconnected
    @Published private(set) var currentChannel: YouTubeChannel?
    @Published private(set) var isLoading = false
    
    private let youtubeAPIKey = "AIzaSyAyjFRqU4u2fx7_Ik5dEiDuNbXb9F0Ykjc" // Your API key
    private let youtubeBaseURL = "https://www.googleapis.com/youtube/v3"
    
    // Required YouTube scopes
    private let youtubeScopes = [
        "https://www.googleapis.com/auth/youtube.readonly"
    ]
    
    // Token cache
    private var cachedAccessToken: String?
    private var tokenExpirationDate: Date?
    
    private let urlSession: URLSession
    
    // MARK: - Init
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
        
        // Check for existing sign-in
        Task {
            await restorePreviousSignIn()
        }
    }
    
    // MARK: - Authentication
    
    /// Restore previous Google sign-in if available
    /// This checks both GIDSignIn's cached state AND Firebase-stored tokens
    func restorePreviousSignIn() async {
        print("🔐 [YouTubeRequestManager] Checking for previous sign-in...")
        
        // First, try to restore from GIDSignIn's internal state
        // This is important for session persistence across app launches
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            print("🔐 [YouTubeRequestManager] GIDSignIn restored previous sign-in")
        } catch {
            print("🔐 [YouTubeRequestManager] GIDSignIn restore failed: \(error.localizedDescription)")
        }
        
        // Now check if we have a current user
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            print("🔐 [YouTubeRequestManager] Found user: \(currentUser.profile?.email ?? "unknown")")
            
            // Check if we have YouTube scope
            let grantedScopes = currentUser.grantedScopes ?? []
            print("🔐 [YouTubeRequestManager] Granted scopes: \(grantedScopes)")
            
            let hasYouTubeScope = youtubeScopes.allSatisfy { scope in
                grantedScopes.contains(scope)
            }
            
            if hasYouTubeScope {
                let email = currentUser.profile?.email ?? "Connected"
                connectionState = .connected(email: email)
                cachedAccessToken = currentUser.accessToken.tokenString
                tokenExpirationDate = currentUser.accessToken.expirationDate
                print("🔐 [YouTubeRequestManager] Restored session for \(email)")
                
                // Also update Firebase with current tokens (in case they were refreshed)
                await storeTokensInFirebase(user: currentUser)
                return
            } else {
                print("🔐 [YouTubeRequestManager] Missing YouTube scope")
            }
        }
        
        // If GIDSignIn doesn't have a user, check Firebase for stored tokens
        print("🔐 [YouTubeRequestManager] Checking Firebase for stored tokens...")
        if await restoreFromFirebaseTokens() {
            print("🔐 [YouTubeRequestManager] Restored from Firebase tokens")
            return
        }
        
        print("🔐 [YouTubeRequestManager] No valid session found, marking disconnected")
        connectionState = .disconnected
    }
    
    /// Try to restore session from Firebase-stored tokens
    private func restoreFromFirebaseTokens() async -> Bool {
        guard let uid = getCurrentUserUID() else {
            print("🔐 [YouTubeRequestManager] No user ID available for Firebase restore")
            return false
        }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
        
        do {
            let snapshot = try await ref.getData()
            
            guard let data = snapshot.value as? [String: Any] else {
                return false
            }
            
            let accessToken = data["googleApiAccessToken"] as? String ?? ""
            let refreshToken = data["googleApiRefreshToken"] as? String ?? ""
            let expirationTimestamp = data["googleApiTokenExpiration"] as? Double ?? 0
            let email = data["googleEmail"] as? String ?? "Connected"
            
            // Check if we have valid tokens
            guard !accessToken.isEmpty, !refreshToken.isEmpty else {
                print("🔐 [YouTubeRequestManager] No tokens found in Firebase")
                return false
            }
            
            let expirationDate = Date(timeIntervalSince1970: expirationTimestamp / 1000)
            
            // If token is expired, we'll need to refresh it
            if expirationDate < Date() {
                print("🔐 [YouTubeRequestManager] Firebase token expired, will refresh on next API call")
            }
            
            // Cache the tokens
            cachedAccessToken = accessToken
            tokenExpirationDate = expirationDate
            
            // Mark as connected
            connectionState = .connected(email: email)
            print("🔐 [YouTubeRequestManager] Restored from Firebase - email: \(email)")
            
            return true
            
        } catch {
            print("🔐 [YouTubeRequestManager] Firebase restore error: \(error)")
            return false
        }
    }
    
    /// Sign in with Google and request YouTube access
    func signIn(presenting viewController: UIViewController) async throws {
        connectionState = .connecting
        
        do {
            // Configure with YouTube scopes
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: youtubeScopes
            )
            
            let user = result.user
            let email = user.profile?.email ?? "Connected"
            
            // Cache token
            cachedAccessToken = user.accessToken.tokenString
            tokenExpirationDate = user.accessToken.expirationDate
            
            connectionState = .connected(email: email)
            
            // Store tokens in Firebase for the current user
            await storeTokensInFirebase(user: user)
            
        } catch {
            connectionState = .error(error.localizedDescription)
            throw YouTubeAPIError.networkError(error)
        }
    }
    
    /// Sign out and disconnect Google account
    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        
        cachedAccessToken = nil
        tokenExpirationDate = nil
        currentChannel = nil
        connectionState = .disconnected
        
        // Remove tokens from Firebase
        await removeTokensFromFirebase()
    }
    
    /// Disconnect account completely (revokes access)
    func disconnect() async throws {
        do {
            try await GIDSignIn.sharedInstance.disconnect()
            
            cachedAccessToken = nil
            tokenExpirationDate = nil
            currentChannel = nil
            connectionState = .disconnected
            
            // Remove tokens and video settings from Firebase
            await removeTokensFromFirebase()
            await removeVideoSettingsFromFirebase()
            
        } catch {
            throw YouTubeAPIError.networkError(error)
        }
    }
    
    // MARK: - Token Management
    
    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken() async throws -> String {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw YouTubeAPIError.notAuthenticated
        }
        
        // Check if token is expired or about to expire (within 5 minutes)
        if let expirationDate = tokenExpirationDate,
           expirationDate.addingTimeInterval(-300) > Date(),
           let cachedToken = cachedAccessToken {
            return cachedToken
        }
        
        // Refresh token
        do {
            let user = try await currentUser.refreshTokensIfNeeded()
            cachedAccessToken = user.accessToken.tokenString
            tokenExpirationDate = user.accessToken.expirationDate
            
            // Update Firebase
            await storeTokensInFirebase(user: user)
            
            return user.accessToken.tokenString
        } catch {
            connectionState = .error("Session expired")
            throw YouTubeAPIError.tokenRefreshFailed
        }
    }
    
    // MARK: - Firebase Token Storage
    
    private func storeTokensInFirebase(user: GIDGoogleUser) async {
        guard let uid = getCurrentUserUID() else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
        
        let tokenData: [String: Any] = [
            "googleApiAccessToken": user.accessToken.tokenString,
            "googleApiRefreshToken": user.refreshToken.tokenString,
            "googleApiTokenExpiration": user.accessToken.expirationDate?.timeIntervalSince1970,
            "googleEmail": user.profile?.email ?? ""
        ]
        
        do {
            try await ref.updateChildValues(tokenData)
        } catch {
            print("⚠️ [YouTubeRequestManager] Failed to store tokens: \(error)")
        }
    }
    
    private func removeTokensFromFirebase() async {
        guard let uid = getCurrentUserUID() else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
        
        let keysToRemove = [
            "googleApiAccessToken",
            "googleApiRefreshToken",
            "googleApiTokenExpiration",
            "googleEmail"
        ]
        
        var updates: [String: Any?] = [:]
        for key in keysToRemove {
            updates[key] = NSNull()
        }
        
        do {
            try await ref.updateChildValues(updates as [String: Any])
        } catch {
            print("⚠️ [YouTubeRequestManager] Failed to remove tokens: \(error)")
        }
    }
    
    private func removeVideoSettingsFromFirebase() async {
        guard let uid = getCurrentUserUID() else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
            .child("videoSettings")
        
        do {
            try await ref.removeValue()
        } catch {
            print("⚠️ [YouTubeRequestManager] Failed to remove video settings: \(error)")
        }
    }
    
    private func getCurrentUserUID() -> String? {
        // Get user ID from UserProvider
        return UserProvider.shared.getUser()?.uId
    }
    
    // MARK: - YouTube API Requests
    
    /// Fetch the authenticated user's YouTube channel
    func fetchMyChannel() async throws -> YouTubeChannel {
        print("📺 [YouTubeAPI] Fetching my channel...")
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await getValidAccessToken()
        print("📺 [YouTubeAPI] Got access token: \(String(accessToken.prefix(20)))...")
        
        // Use 'mine=true' to get the authenticated user's channel
        // This is the most efficient way as per YouTube API docs
        var components = URLComponents(string: "\(youtubeBaseURL)/channels")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "mine", value: "true"),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]
        
        print("📺 [YouTubeAPI] Request URL: \(components.url?.absoluteString ?? "nil")")
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        print("📺 [YouTubeAPI] Response received: \(data.count) bytes")
        
        // Debug: print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📺 [YouTubeAPI] Raw response: \(String(jsonString.prefix(500)))...")
        }
        
        try validateResponse(response)
        
        let channelResponse = try JSONDecoder().decode(YouTubeChannelListResponse.self, from: data)
        
        guard let item = channelResponse.items?.first else {
            print("📺 [YouTubeAPI] No channel found in response")
            throw YouTubeAPIError.noVideosFound
        }
        
        let channel = YouTubeChannel(
            id: item.id,
            title: item.snippet?.title ?? "",
            description: item.snippet?.description ?? "",
            thumbnailURL: item.snippet?.thumbnails?.bestURL ?? "",
            uploadsPlaylistId: item.contentDetails?.relatedPlaylists?.uploads,
            subscriberCount: Int(item.statistics?.subscriberCount ?? "0"),
            videoCount: Int(item.statistics?.videoCount ?? "0")
        )
        
        print("📺 [YouTubeAPI] Found channel: \(channel.title), uploads playlist: \(channel.uploadsPlaylistId ?? "nil")")
        
        self.currentChannel = channel
        return channel
    }
    
    /// Fetch videos from a playlist (typically the uploads playlist)
    /// This is the recommended method per YouTube API documentation
    func fetchPlaylistVideos(playlistId: String, maxResults: Int = 50, pageToken: String? = nil) async throws -> (videos: [YouTubeVideo], nextPageToken: String?) {
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await getValidAccessToken()
        
        var components = URLComponents(string: "\(youtubeBaseURL)/playlistItems")!
        var queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "playlistId", value: playlistId),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validateResponse(response)
        
        let playlistResponse = try JSONDecoder().decode(YouTubePlaylistItemsResponse.self, from: data)
        
        guard let items = playlistResponse.items, !items.isEmpty else {
            return ([], nil)
        }
        
        // Extract video IDs to fetch additional details (duration, stats)
        let videoIds = items.compactMap { $0.contentDetails?.videoId }
        
        // Fetch video details for duration and stats
        let videoDetails = try await fetchVideoDetails(videoIds: videoIds)
        
        // Combine playlist items with video details
        let videos = items.compactMap { item -> YouTubeVideo? in
            guard let videoId = item.contentDetails?.videoId,
                  let snippet = item.snippet else { return nil }
            
            let details = videoDetails[videoId]
            
            return YouTubeVideo(
                id: videoId,
                title: snippet.title ?? "",
                description: snippet.description ?? "",
                thumbnailURL: snippet.thumbnails?.bestURL ?? "",
                channelTitle: snippet.channelTitle ?? "",
                publishedAt: parseDate(snippet.publishedAt) ?? Date(),
                duration: details?.duration,
                viewCount: details?.viewCount,
                likeCount: details?.likeCount
            )
        }
        
        return (videos, playlistResponse.nextPageToken)
    }
    
    /// Fetch details for specific video IDs (for duration, view counts, etc.)
    func fetchVideoDetails(videoIds: [String]) async throws -> [String: (duration: String?, viewCount: Int?, likeCount: Int?)] {
        guard !videoIds.isEmpty else { return [:] }
        
        let accessToken = try await getValidAccessToken()
        
        // API allows up to 50 IDs per request
        let idsString = videoIds.prefix(50).joined(separator: ",")
        
        var components = URLComponents(string: "\(youtubeBaseURL)/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "contentDetails,statistics"),
            URLQueryItem(name: "id", value: idsString),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validateResponse(response)
        
        let videoResponse = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
        
        var details: [String: (duration: String?, viewCount: Int?, likeCount: Int?)] = [:]
        
        for item in videoResponse.items ?? [] {
            details[item.id] = (
                duration: item.contentDetails?.duration,
                viewCount: Int(item.statistics?.viewCount ?? "0"),
                likeCount: Int(item.statistics?.likeCount ?? "0")
            )
        }
        
        return details
    }
    
    /// Fetch all uploaded videos for the current user
    func fetchMyVideos(maxResults: Int = 50) async throws -> [YouTubeVideo] {
        print("📺 [YouTubeAPI] fetchMyVideos called, maxResults: \(maxResults)")
        
        // Step 1: Get the channel to find the uploads playlist
        let channel = try await fetchMyChannel()
        
        guard let uploadsPlaylistId = channel.uploadsPlaylistId else {
            print("📺 [YouTubeAPI] No uploads playlist found!")
            throw YouTubeAPIError.noVideosFound
        }
        
        print("📺 [YouTubeAPI] Fetching videos from playlist: \(uploadsPlaylistId)")
        
        // Step 2: Fetch videos from the uploads playlist
        let (videos, _) = try await fetchPlaylistVideos(
            playlistId: uploadsPlaylistId,
            maxResults: maxResults
        )
        
        print("📺 [YouTubeAPI] Fetched \(videos.count) videos")
        
        return videos
    }
    
    /// Fetch videos by specific IDs
    func fetchVideos(ids: [String]) async throws -> [YouTubeVideo] {
        guard !ids.isEmpty else { return [] }
        
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await getValidAccessToken()
        
        let idsString = ids.joined(separator: ",")
        
        var components = URLComponents(string: "\(youtubeBaseURL)/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: idsString),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validateResponse(response)
        
        let videoResponse = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
        
        return (videoResponse.items ?? []).compactMap { item -> YouTubeVideo? in
            guard let snippet = item.snippet else { return nil }
            
            return YouTubeVideo(
                id: item.id,
                title: snippet.title ?? "",
                description: snippet.description ?? "",
                thumbnailURL: snippet.thumbnails?.bestURL ?? "",
                channelTitle: snippet.channelTitle ?? "",
                publishedAt: parseDate(snippet.publishedAt) ?? Date(),
                duration: item.contentDetails?.duration,
                viewCount: Int(item.statistics?.viewCount ?? "0"),
                likeCount: Int(item.statistics?.likeCount ?? "0")
            )
        }
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw YouTubeAPIError.tokenExpired
        case 403:
            throw YouTubeAPIError.quotaExceeded
        case 404:
            throw YouTubeAPIError.noVideosFound
        default:
            throw YouTubeAPIError.apiError(
                code: httpResponse.statusCode,
                message: "Request failed with status \(httpResponse.statusCode)"
            )
        }
    }
    
    // MARK: - Helpers
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}

// MARK: - Legacy Compatibility

/// Bridge for existing code that uses SocialMediaManagerCallback pattern
protocol YouTubeRequestDelegate: AnyObject {
    func onYoutubeSuccessful(videos: [YouTubeVideo])
    func onYoutubeFail(error: YouTubeAPIError?)
    func onChannelsLoaded(channels: [YouTubeChannel])
}

extension YouTubeRequestManager {
    
    /// Legacy method for compatibility with existing callback-based code
    func getYoutubeAccess(
        currentUser: User,
        tryRefresh: Bool = true,
        delegate: YouTubeRequestDelegate
    ) {
        Task { @MainActor in
            do {
                let videos = try await fetchMyVideos()
                delegate.onYoutubeSuccessful(videos: videos)
            } catch let error as YouTubeAPIError {
                delegate.onYoutubeFail(error: error)
            } catch {
                delegate.onYoutubeFail(error: .networkError(error))
            }
        }
    }
}
