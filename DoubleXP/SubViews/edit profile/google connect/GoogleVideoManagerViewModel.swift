//
//  GoogleVideoManagerViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

// MARK: - Tab Selection

enum VideoManagerTab: String, CaseIterable {
    case highlight = "Highlight"
    case showcase = "Showcase"
    case settings = "Settings"
}

// MARK: - View Model

@MainActor
final class GoogleVideoManagerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Connection State
    @Published var connectionState: GoogleConnectionState = .disconnected
    @Published var userEmail: String = ""
    
    // Navigation
    @Published var selectedTab: VideoManagerTab = .highlight
    
    // Videos
    @Published var allVideos: [YouTubeVideo] = []
    @Published var highlightVideo: YouTubeVideo?
    @Published var showcaseVideos: [YouTubeVideo] = []
    @Published var recentPosts: [RecentPost] = [] // For settings tab
    
    // Loading States
    @Published var isLoading = false
    @Published var isLoadingVideos = false
    @Published var isSaving = false
    
    // Error Handling
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Settings
    @Published var isContentPrivate = false
    @Published var showDisconnectConfirmation = false
    @Published var showRemoveDataConfirmation = false
    
    // Selection Mode (for showcase)
    @Published var isSelectingVideos = false
    @Published var selectedVideoIds: Set<String> = []
    
    // MARK: - Private Properties
    
    private let requestManager = YouTubeRequestManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var videoSettings: UserVideoSettings = UserVideoSettings()
    
    static let maxShowcaseVideos = 6
    
    // MARK: - Init
    
    init(userId: String? = nil) {
        self.currentUserId = userId
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe connection state from request manager
        requestManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                if case .connected(let email) = state {
                    self?.userEmail = email
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load initial data when view appears
    func loadInitialData() async {
        print("📹 [VideoManager] loadInitialData called, current connectionState: \(connectionState)")
        
        // First, check/restore the connection state from request manager
        await requestManager.restorePreviousSignIn()
        
        // Sync the connection state directly from request manager
        // (Don't rely on Combine publisher timing)
        self.connectionState = requestManager.connectionState
        if case .connected(let email) = requestManager.connectionState {
            self.userEmail = email
        }
        
        print("📹 [VideoManager] After restore, connectionState: \(connectionState)")
        
        // Now check if we're connected
        guard connectionState.isConnected else {
            print("📹 [VideoManager] Not connected, skipping video load")
            return
        }
        
        print("📹 [VideoManager] Connected! Loading videos...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load video settings from Firebase first
            await loadVideoSettings()
            
            // Then fetch videos from YouTube
            try await loadAllVideos()
            
            // Load recent posts for settings
            await loadRecentPosts()
            
            print("📹 [VideoManager] Loaded \(allVideos.count) videos")
            
        } catch {
            print("📹 [VideoManager] Error loading videos: \(error)")
            handleError(error)
        }
    }
    
    /// Connect Google account
    func connectGoogle(presenting viewController: UIViewController) async {
        do {
            try await requestManager.signIn(presenting: viewController)
            
            // After successful connection, load videos
            await loadInitialData()
            
        } catch {
            handleError(error)
        }
    }
    
    /// Disconnect Google account
    func disconnectGoogle() async {
        do {
            try await requestManager.disconnect()
            
            // Clear local state
            clearLocalState()
            
        } catch {
            handleError(error)
        }
    }
    
    /// Remove all user data and disconnect
    func removeAllData() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Clear video settings from Firebase
            await clearVideoSettingsFromFirebase()
            
            // Disconnect Google
            try await requestManager.disconnect()
            
            // Clear local state
            clearLocalState()
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Video Loading
    
    /// Load all videos from YouTube
    func loadAllVideos() async throws {
        isLoadingVideos = true
        defer { isLoadingVideos = false }
        
        let videos = try await requestManager.fetchMyVideos(maxResults: 50)
        
        // Apply saved settings to videos
        allVideos = videos.map { video in
            var v = video
            v.isHighlight = videoSettings.highlightVideoId == video.id
            v.isShowcase = videoSettings.showcaseVideoIds.contains(video.id)
            return v
        }
        
        // Update highlight and showcase from settings
        updateSelectedVideos()
    }
    
    /// Refresh videos
    func refreshVideos() async {
        do {
            try await loadAllVideos()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Highlight Video Management
    
    /// Set a video as the highlight
    func setHighlightVideo(_ video: YouTubeVideo) async {
        isSaving = true
        defer { isSaving = false }
        
        // Update local state
        videoSettings.highlightVideoId = video.id
        videoSettings.lastUpdated = Date()
        
        highlightVideo = video
        
        // Update all videos to reflect change
        allVideos = allVideos.map { v in
            var updated = v
            updated.isHighlight = v.id == video.id
            return updated
        }
        
        // Save to Firebase
        await saveVideoSettings()
    }
    
    /// Remove highlight video
    func removeHighlightVideo() async {
        isSaving = true
        defer { isSaving = false }
        
        let previousId = videoSettings.highlightVideoId
        
        videoSettings.highlightVideoId = nil
        videoSettings.lastUpdated = Date()
        highlightVideo = nil
        
        // Update all videos
        if let previousId = previousId {
            allVideos = allVideos.map { v in
                var updated = v
                if v.id == previousId {
                    updated.isHighlight = false
                }
                return updated
            }
        }
        
        await saveVideoSettings()
    }
    
    // MARK: - Showcase Video Management
    
    /// Toggle showcase selection mode
    func toggleSelectionMode() {
        isSelectingVideos.toggle()
        if !isSelectingVideos {
            selectedVideoIds.removeAll()
        }
    }
    
    /// Toggle video selection for showcase
    func toggleVideoSelection(_ video: YouTubeVideo) {
        if selectedVideoIds.contains(video.id) {
            selectedVideoIds.remove(video.id)
        } else if selectedVideoIds.count < Self.maxShowcaseVideos {
            selectedVideoIds.insert(video.id)
        }
    }
    
    /// Add selected videos to showcase
    func addSelectedToShowcase() async {
        isSaving = true
        defer { isSaving = false }
        
        // Add new selections to existing showcase (up to max)
        var newShowcaseIds = videoSettings.showcaseVideoIds
        for id in selectedVideoIds {
            if !newShowcaseIds.contains(id) && newShowcaseIds.count < Self.maxShowcaseVideos {
                newShowcaseIds.append(id)
            }
        }
        
        videoSettings.showcaseVideoIds = newShowcaseIds
        videoSettings.lastUpdated = Date()
        
        // Update local state
        updateSelectedVideos()
        
        // Update all videos
        allVideos = allVideos.map { v in
            var updated = v
            updated.isShowcase = newShowcaseIds.contains(v.id)
            return updated
        }
        
        // Clear selection mode
        isSelectingVideos = false
        selectedVideoIds.removeAll()
        
        await saveVideoSettings()
    }
    
    /// Remove a video from showcase
    func removeFromShowcase(_ video: YouTubeVideo) async {
        isSaving = true
        defer { isSaving = false }
        
        videoSettings.showcaseVideoIds.removeAll { $0 == video.id }
        videoSettings.lastUpdated = Date()
        
        // Update local state
        showcaseVideos.removeAll { $0.id == video.id }
        
        // Update all videos
        allVideos = allVideos.map { v in
            var updated = v
            if v.id == video.id {
                updated.isShowcase = false
            }
            return updated
        }
        
        await saveVideoSettings()
    }
    
    /// Reorder showcase videos
    func moveShowcaseVideo(from source: IndexSet, to destination: Int) async {
        showcaseVideos.move(fromOffsets: source, toOffset: destination)
        videoSettings.showcaseVideoIds = showcaseVideos.map { $0.id }
        videoSettings.lastUpdated = Date()
        
        await saveVideoSettings()
    }
    
    // MARK: - Settings Management
    
    /// Toggle content privacy
    func togglePrivacy() async {
        isSaving = true
        defer { isSaving = false }
        
        isContentPrivate.toggle()
        videoSettings.isPrivate = isContentPrivate
        videoSettings.lastUpdated = Date()
        
        await saveVideoSettings()
    }
    
    // MARK: - Firebase Operations
    
    /// Load video settings from Firebase
    private func loadVideoSettings() async {
        guard let userId = currentUserId else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(userId)
            .child("videoSettings")
        
        do {
            let snapshot = try await ref.getData()
            
            if let data = snapshot.value as? [String: Any] {
                videoSettings.highlightVideoId = data["highlightVideoId"] as? String
                videoSettings.showcaseVideoIds = data["showcaseVideoIds"] as? [String] ?? []
                videoSettings.isPrivate = data["isPrivate"] as? Bool ?? false
                
                if let timestamp = data["lastUpdated"] as? TimeInterval {
                    videoSettings.lastUpdated = Date(timeIntervalSince1970: timestamp)
                }
                
                isContentPrivate = videoSettings.isPrivate
            }
        } catch {
            print("⚠️ [ViewModel] Failed to load video settings: \(error)")
        }
    }
    
    /// Save video settings to Firebase
    private func saveVideoSettings() async {
        guard let userId = currentUserId else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(userId)
            .child("videoSettings")
        
        var data: [String: Any] = [
            "showcaseVideoIds": videoSettings.showcaseVideoIds,
            "isPrivate": videoSettings.isPrivate,
            "lastUpdated": videoSettings.lastUpdated.timeIntervalSince1970
        ]
        
        if let highlightId = videoSettings.highlightVideoId {
            data["highlightVideoId"] = highlightId
        } else {
            data["highlightVideoId"] = NSNull()
        }
        
        do {
            try await ref.setValue(data)
        } catch {
            print("⚠️ [ViewModel] Failed to save video settings: \(error)")
            handleError(error)
        }
    }
    
    /// Clear all video settings from Firebase
    private func clearVideoSettingsFromFirebase() async {
        guard let userId = currentUserId else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(userId)
            .child("videoSettings")
        
        do {
            try await ref.removeValue()
        } catch {
            print("⚠️ [ViewModel] Failed to clear video settings: \(error)")
        }
    }
    
    /// Load recent posts for settings tab
    private func loadRecentPosts() async {
        guard let userId = currentUserId else { return }
        
        let ref = Database.database().reference()
            .child("Posts")
            .queryOrdered(byChild: "authorId")
            .queryEqual(toValue: userId)
            .queryLimited(toLast: 5)
        
        do {
            let snapshot = try await ref.getData()
            
            var posts: [RecentPost] = []
            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let data = snap.value as? [String: Any] {
                    let post = RecentPost(
                        id: snap.key,
                        title: data["title"] as? String ?? "Untitled",
                        thumbnailURL: data["thumbnailURL"] as? String,
                        createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? 0),
                        hasVideo: data["videoId"] != nil
                    )
                    posts.append(post)
                }
            }
            
            recentPosts = posts.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("⚠️ [ViewModel] Failed to load recent posts: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSelectedVideos() {
        // Update highlight video
        if let highlightId = videoSettings.highlightVideoId {
            highlightVideo = allVideos.first { $0.id == highlightId }
        } else {
            highlightVideo = nil
        }
        
        // Update showcase videos (maintain order from settings)
        showcaseVideos = videoSettings.showcaseVideoIds.compactMap { id in
            allVideos.first { $0.id == id }
        }
    }
    
    private func clearLocalState() {
        allVideos = []
        highlightVideo = nil
        showcaseVideos = []
        recentPosts = []
        videoSettings = UserVideoSettings()
        isContentPrivate = false
        selectedVideoIds.removeAll()
        isSelectingVideos = false
        userEmail = ""
    }
    
    private func handleError(_ error: Error) {
        if let ytError = error as? YouTubeAPIError {
            errorMessage = ytError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
    
    // MARK: - Computed Properties
    
    var canAddMoreShowcase: Bool {
        showcaseVideos.count < Self.maxShowcaseVideos
    }
    
    var showcaseCountText: String {
        "\(showcaseVideos.count)/\(Self.maxShowcaseVideos)"
    }
    
    var availableVideosForShowcase: [YouTubeVideo] {
        allVideos.filter { video in
            !videoSettings.showcaseVideoIds.contains(video.id) &&
            video.id != videoSettings.highlightVideoId
        }
    }
}

// MARK: - Recent Post Model

struct RecentPost: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String?
    let createdAt: Date
    let hasVideo: Bool
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
