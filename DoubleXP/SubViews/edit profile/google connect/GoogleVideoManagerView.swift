//
//  GoogleVideoManagerView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI

// MARK: - Main View

struct GoogleVideoManagerView: View {
    @StateObject private var viewModel: GoogleVideoManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    // For presenting Google Sign-In
    @State private var hostingController: UIViewController?
    
    init(userId: String? = nil) {
        _viewModel = StateObject(wrappedValue: GoogleVideoManagerViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Content based on connection state
            switch viewModel.connectionState {
            case .disconnected:
                DisconnectedOverlayView(
                    onConnect: connectGoogle,
                    onDismiss: { dismiss() }
                )
                
            case .connecting:
                LoadingView(message: "Connecting...")
                
            case .connected:
                ConnectedContentView(viewModel: viewModel, onDismiss: { dismiss() })
                
            case .error(let message):
                ErrorStateView(
                    message: message,
                    onRetry: connectGoogle,
                    onDismiss: { dismiss() }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadInitialData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .confirmationDialog(
            "Disconnect Google?",
            isPresented: $viewModel.showDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                Task { await viewModel.disconnectGoogle() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove access to your YouTube videos.")
        }
        .confirmationDialog(
            "Remove All Data?",
            isPresented: $viewModel.showRemoveDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All Data", role: .destructive) {
                Task { await viewModel.removeAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your highlight and showcase settings.")
        }
        .background {
            // Capture hosting controller for Google Sign-In
            HostingControllerResolver(controller: $hostingController)
        }
    }
    
    private func connectGoogle() {
        guard let vc = hostingController else { return }
        Task {
            await viewModel.connectGoogle(presenting: vc)
        }
    }
}

// MARK: - Disconnected Overlay (Design 3 Style)

struct DisconnectedOverlayView: View {
    let onConnect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "4285F4").opacity(0.25),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            // Back button
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 20)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Google Wordmark
                HStack(spacing: 0) {
                    Text("G").foregroundColor(Color(hex: "4285F4"))
                    Text("o").foregroundColor(Color(hex: "EA4335"))
                    Text("o").foregroundColor(Color(hex: "FBBC05"))
                    Text("g").foregroundColor(Color(hex: "4285F4"))
                    Text("l").foregroundColor(Color(hex: "34A853"))
                    Text("e").foregroundColor(Color(hex: "EA4335"))
                }
                .font(.system(size: 26, weight: .medium))
                .padding(.bottom, 6)
                
                Text("Connect your account")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 28)
                
                // Value Props
                VStack(spacing: 10) {
                    ValuePropCard(
                        icon: "🎬",
                        title: "Profile Highlight Video",
                        description: "Show off gameplay in your profile header",
                        iconBackground: Color(hex: "4285F4").opacity(0.15)
                    )
                    
                    ValuePropCard(
                        icon: "📹",
                        title: "Video Posts",
                        description: "Attach gameplay clips to your posts",
                        iconBackground: Color(hex: "34A853").opacity(0.15)
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // Connect Button
                Button(action: onConnect) {
                    HStack(spacing: 10) {
                        GoogleLogoView(size: 18)
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "333333"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 16)
                
                // Skip button
                Button("Skip for now") {}
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
                
                Spacer()
            }
        }
    }
}

// MARK: - Value Prop Card

struct ValuePropCard: View {
    let icon: String
    let title: String
    let description: String
    let iconBackground: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .background(iconBackground)
                .cornerRadius(10)
            
            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

// MARK: - Connected Content View

struct ConnectedContentView: View {
    @ObservedObject var viewModel: GoogleVideoManagerViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Video Manager")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 10)
            
            // Tab Bar
            TabBarView(selectedTab: $viewModel.selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            
            // Content
            TabView(selection: $viewModel.selectedTab) {
                HighlightTabView(viewModel: viewModel)
                    .tag(VideoManagerTab.highlight)
                
                ShowcaseTabView(viewModel: viewModel)
                    .tag(VideoManagerTab.showcase)
                
                SettingsTabView(viewModel: viewModel)
                    .tag(VideoManagerTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay {
            if viewModel.isLoading || viewModel.isSaving {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    @Binding var selectedTab: VideoManagerTab
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(VideoManagerTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedTab == tab
                                ? Color(hex: "4285F4")
                                : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

// MARK: - Highlight Tab

struct HighlightTabView: View {
    @ObservedObject var viewModel: GoogleVideoManagerViewModel
    @State private var showVideoPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Section Label
                Text("PROFILE HIGHLIGHT")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                
                // Highlight Video Card
                if let video = viewModel.highlightVideo {
                    HighlightVideoCard(
                        video: video,
                        onChangeVideo: { showVideoPicker = true },
                        youtubePlayerView: YouTubePlayerViewWrapper(videoId: video.id)
                    )
                    .padding(.horizontal, 20)
                } else {
                    // Empty State
                    EmptyHighlightCard(onSelectVideo: { showVideoPicker = true })
                        .padding(.horizontal, 20)
                }
                
                // Available Videos Section
                if !viewModel.allVideos.isEmpty {
                    Text("MORE VIDEOS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 10)
                    
                    VideoListView(
                        videos: viewModel.allVideos.filter { $0.id != viewModel.highlightVideo?.id },
                        onSelect: { video in
                            Task { await viewModel.setHighlightVideo(video) }
                        },
                        actionIcon: "star.fill",
                        actionColor: Color(hex: "4285F4")
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPickerSheet(
                videos: viewModel.allVideos,
                onSelect: { video in
                    Task { await viewModel.setHighlightVideo(video) }
                    showVideoPicker = false
                }
            )
        }
    }
}

// MARK: - Highlight Video Card with YouTube Player

struct HighlightVideoCard: View {
    let video: YouTubeVideo
    let onChangeVideo: () -> Void
    let youtubePlayerView: YouTubePlayerViewWrapper
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player
            ZStack(alignment: .topLeading) {
                youtubePlayerView
                    .aspectRatio(16/9, contentMode: .fit)
                    //.cornerRadius(16, corners: [.topLeft, .topRight])
                
                // Highlight Badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text("HIGHLIGHT")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "4285F4"))
                .cornerRadius(6)
                .padding(10)
            }
            
            // Video Info & Actions
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text(video.formattedDuration)
                    Text("•")
                    Text(video.formattedViewCount + " views")
                }
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                
                // Change Button
                Button(action: onChangeVideo) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(6)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            //.cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1a2040"), Color(hex: "2a1a40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "4285F4").opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Empty Highlight Card

struct EmptyHighlightCard: View {
    let onSelectVideo: () -> Void
    
    var body: some View {
        Button(action: onSelectVideo) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4285F4").opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "4285F4"))
                }
                
                Text("Select Highlight Video")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Choose a video to feature on your profile")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Showcase Tab

struct ShowcaseTabView: View {
    @ObservedObject var viewModel: GoogleVideoManagerViewModel
    @State private var showAddVideos = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("SHOWCASE VIDEOS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    Spacer()
                    
                    Text(viewModel.showcaseCountText)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if viewModel.canAddMoreShowcase {
                        Button {
                            showAddVideos = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "4285F4"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "4285F4").opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Showcase Grid
                if viewModel.showcaseVideos.isEmpty {
                    EmptyShowcaseView(onAdd: { showAddVideos = true })
                        .padding(.horizontal, 20)
                } else {
                    ShowcaseGrid(
                        videos: viewModel.showcaseVideos,
                        onRemove: { video in
                            Task { await viewModel.removeFromShowcase(video) }
                        }
                    )
                    .padding(.horizontal, 20)
                }
                
                // Available to Add
                if !viewModel.availableVideosForShowcase.isEmpty && viewModel.canAddMoreShowcase {
                    Text("AVAILABLE TO ADD")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 10)
                    
                    VideoListView(
                        videos: viewModel.availableVideosForShowcase,
                        onSelect: { video in
                            viewModel.selectedVideoIds.insert(video.id)
                            Task { await viewModel.addSelectedToShowcase() }
                        },
                        actionIcon: "plus.circle.fill",
                        actionColor: Color(hex: "34A853")
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $showAddVideos) {
            VideoPickerSheet(
                videos: viewModel.availableVideosForShowcase,
                multiSelect: true,
                maxSelections: GoogleVideoManagerViewModel.maxShowcaseVideos - viewModel.showcaseVideos.count,
                onSelectMultiple: { videos in
                    viewModel.selectedVideoIds = Set(videos.map { $0.id })
                    Task { await viewModel.addSelectedToShowcase() }
                    showAddVideos = false
                }
            )
        }
    }
}

// MARK: - Showcase Grid

struct ShowcaseGrid: View {
    let videos: [YouTubeVideo]
    let onRemove: (YouTubeVideo) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(videos) { video in
                ShowcaseVideoCell(video: video, onRemove: { onRemove(video) })
            }
        }
    }
}

// MARK: - Showcase Video Cell

struct ShowcaseVideoCell: View {
    let video: YouTubeVideo
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(8)
                .overlay(alignment: .bottomTrailing) {
                    Text(video.formattedDuration)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(3)
                        .padding(5)
                }
                
                // Title
                Text(video.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Views
                Text(video.formattedViewCount + " views")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .offset(x: 4, y: -4)
        }
    }
}

// MARK: - Empty Showcase View

struct EmptyShowcaseView: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 12) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "34A853"))
                
                Text("Add Showcase Videos")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Select up to 6 videos to showcase")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var viewModel: GoogleVideoManagerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Account Section
                SettingsSectionHeader(title: "ACCOUNT")
                
                AccountRow(
                    email: viewModel.userEmail,
                    onDisconnect: { viewModel.showDisconnectConfirmation = true }
                )
                .padding(.horizontal, 20)
                
                // Privacy Section
                SettingsSectionHeader(title: "PRIVACY")
                
                PrivacyToggleRow(
                    isPrivate: viewModel.isContentPrivate,
                    onToggle: {
                        Task { await viewModel.togglePrivacy() }
                    }
                )
                .padding(.horizontal, 20)
                
                // Recent Posts Section
                if !viewModel.recentPosts.isEmpty {
                    SettingsSectionHeader(title: "RECENT POSTS")
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.recentPosts) { post in
                            RecentPostRow(post: post)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Danger Zone
                SettingsSectionHeader(title: "DATA")
                
                Button {
                    viewModel.showRemoveDataConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(Color(hex: "EA4335"))
                        Text("Remove All Video Data")
                            .foregroundColor(Color(hex: "EA4335"))
                        Spacer()
                    }
                    .font(.system(size: 14))
                    .padding(14)
                    .background(Color(hex: "EA4335").opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Settings Components

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
            .tracking(1)
            .padding(.horizontal, 20)
    }
}

struct AccountRow: View {
    let email: String
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "4285F4"), Color(hex: "34A853")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("🎮")
                    .font(.system(size: 16))
            }
            .frame(width: 40, height: 40)
            .cornerRadius(10)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(email)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8))
                    Text("Connected")
                }
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "34A853"))
            }
            
            Spacer()
            
            // Disconnect
            Button("Disconnect", action: onDisconnect)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "4285F4").opacity(0.1),
                    Color(hex: "34A853").opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct PrivacyToggleRow: View {
    let isPrivate: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Private Content")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Only visible to friends")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isPrivate },
                set: { _ in onToggle() }
            ))
            .tint(Color(hex: "4285F4"))
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

struct RecentPostRow: View {
    let post: RecentPost
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            if let url = post.thumbnailURL {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(width: 60, height: 34)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 34)
                    .cornerRadius(4)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(post.formattedDate)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Video indicator
            if post.hasVideo {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "4285F4"))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

// MARK: - Video List View

struct VideoListView: View {
    let videos: [YouTubeVideo]
    let onSelect: (YouTubeVideo) -> Void
    let actionIcon: String
    let actionColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(videos) { video in
                VideoRowView(
                    video: video,
                    actionIcon: actionIcon,
                    actionColor: actionColor,
                    onAction: { onSelect(video) }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct VideoRowView: View {
    let video: YouTubeVideo
    let actionIcon: String
    let actionColor: Color
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
            }
            .frame(width: 72, height: 40)
            .cornerRadius(6)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(video.formattedDuration) • \(video.formattedDate)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Action Button
            Button(action: onAction) {
                Image(systemName: actionIcon)
                    .font(.system(size: 18))
                    .foregroundColor(actionColor)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Video Picker Sheet

struct VideoPickerSheet: View {
    let videos: [YouTubeVideo]
    var multiSelect: Bool = false
    var maxSelections: Int = 1
    var onSelect: ((YouTubeVideo) -> Void)? = nil
    var onSelectMultiple: (([YouTubeVideo]) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(videos) { video in
                        VideoPickerRow(
                            video: video,
                            isSelected: selectedIds.contains(video.id),
                            onTap: {
                                if multiSelect {
                                    if selectedIds.contains(video.id) {
                                        selectedIds.remove(video.id)
                                    } else if selectedIds.count < maxSelections {
                                        selectedIds.insert(video.id)
                                    }
                                } else {
                                    onSelect?(video)
                                }
                            }
                        )
                    }
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle(multiSelect ? "Select Videos" : "Choose Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                if multiSelect {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add (\(selectedIds.count))") {
                            let selected = videos.filter { selectedIds.contains($0.id) }
                            onSelectMultiple?(selected)
                        }
                        .disabled(selectedIds.isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct VideoPickerRow: View {
    let video: YouTubeVideo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(width: 100, height: 56)
                .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(video.formattedDuration) • \(video.formattedViewCount) views")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "4285F4") : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "4285F4"))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: "4285F4").opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            // Back button
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 20)
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "EA4335"))
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "4285F4"))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Google Logo View

struct GoogleLogoView: View {
    let size: CGFloat
    
    var body: some View {
        // Simplified Google "G" logo
        ZStack {
            Circle()
                .fill(Color.clear)
            
            Image(systemName: "g.circle.fill")
                .font(.system(size: size))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "4285F4"), Color(hex: "34A853")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - YouTube Player Wrapper

struct YouTubePlayerViewWrapper: UIViewRepresentable {
    let videoId: String
    
    func makeUIView(context: Context) -> YouTubePlayerView {
        let player = YouTubePlayerView()
        player.load(videoID: videoId, shouldAutoplay: false)
        return player
    }
    
    func updateUIView(_ uiView: YouTubePlayerView, context: Context) {
        // Only reload if video ID changes
    }
}

// MARK: - Hosting Controller Resolver

struct HostingControllerResolver: UIViewControllerRepresentable {
    @Binding var controller: UIViewController?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            self.controller = vc
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
