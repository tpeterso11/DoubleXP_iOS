//
//  CommunityViews.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Reddit Card

struct CommunityRedditCard: View {
    let post: RedditPost
    let isLiked: Bool
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "FF4500"), Color(hex: "FF6B6B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("🔥")
                            .font(.system(size: 16))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("u/\(post.author)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("r/\(post.subreddit) • \(post.relativeTime)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text("Reddit")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "FF4500"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "FF4500").opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Title
            Text(post.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(3)
            
            // Preview image if available
            if let imageUrl = post.previewImageURL {
                CachedAsyncImageView(url: imageUrl)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Self text preview
            if let text = post.selftext, !text.isEmpty {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.system(size: 16))
                        Text(post.formattedScore)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(isLiked ? Color(hex: "FF4500") : .white.opacity(0.5))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(post.numComments)")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - User Post Card

struct CommunityUserPostCard: View {
    let post: CommunityUserPost
    let isLiked: Bool
    let onLike: () -> Void
    
    @State private var showComments: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                if let url = post.avatarURL {
                    CachedAsyncImageView(url: url)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "4ADE80"), Color(hex: "22C55E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("😊")
                                .font(.system(size: 18))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Community • \(post.relativeTime)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Content
            Text(post.text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
            
            // Image if available
            if let imageUrl = post.imageURL {
                CachedAsyncImageView(url: imageUrl)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(post.likeCount)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(isLiked ? Color(hex: "FF6B6B") : .white.opacity(0.5))
                }
                
                Button(action: { showComments = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("\(post.commentCount)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .sheet(isPresented: $showComments) {
            // CommentsView integration would go here
            Text("Comments")
        }
    }
}

// MARK: - Video Card

struct CommunityVideoCard: View {
    let video: CommunityVideo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let url = video.thumbnailURL {
                    CachedAsyncImageView(url: url)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1a2e"))
                        .frame(height: 180)
                        .overlay(
                            Text("▶️")
                                .font(.system(size: 40))
                        )
                }
                
                // Duration
                Text(video.formattedDuration)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                
                // Play button overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(video.channelTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if !video.formattedViewCount.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text("\(video.formattedViewCount) views")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Article Card

struct CommunityArticleCard: View {
    let article: CommunityArticle
    let isLiked: Bool
    let onLike: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = article.imageURL {
                CachedAsyncImageView(url: url)
                    .frame(width: 100, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Color(hex: "9333EA"), Color(hex: "DB2777")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 80)
                    .overlay(
                        Text("📰")
                            .font(.system(size: 28))
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(article.source.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .tracking(0.5)
                
                Text(article.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(article.relativeTime)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Short Card

struct CommunityShortCard: View {
    let short: CommunityShort
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Thumbnail
            ZStack(alignment: .bottomLeading) {
                if let url = short.thumbnailURL {
                    CachedAsyncImageView(url: url)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "2d2d4e")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 180)
                        .overlay(
                            Text("🎬")
                                .font(.system(size: 36))
                        )
                }
                
                // Play icon
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Channel name
            Text(short.channelTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Member Row

struct CommunityMemberRow: View {
    let member: CommunityMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let url = member.avatarURL {
                    CachedAsyncImageView(url: url)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("👤")
                                .font(.system(size: 22))
                        )
                }
                
                // Online indicator
                if member.isOnline {
                    Circle()
                        .fill(Color(hex: "4ADE80"))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "0a0a0f"), lineWidth: 2)
                        )
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.screenName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(member.isOnline ? "Online now" : member.relativeLastActive)
                    .font(.system(size: 12))
                    .foregroundColor(member.isOnline ? Color(hex: "4ADE80") : .white.opacity(0.4))
            }
            
            Spacer()
            
            // View profile button
            Button(action: {}) {
                Text("View")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FF6B6B").opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Empty State View

struct CommunityEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(actionTitle)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

struct CommunityLoadingView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header skeleton
            headerSkeleton
            
            // Tab skeleton
            tabSkeleton
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Stats skeleton
                    statsSkeleton
                    
                    // Filter skeleton
                    filterSkeleton
                    
                    // Card skeletons
                    ForEach(0..<4, id: \.self) { _ in
                        cardSkeleton
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Header Skeleton
    
    private var headerSkeleton: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                skeletonRect(width: 40, height: 40, cornerRadius: 12)
                Spacer()
                HStack(spacing: 8) {
                    skeletonRect(width: 40, height: 40, cornerRadius: 12)
                    skeletonRect(width: 40, height: 40, cornerRadius: 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            
            // Game info
            HStack(spacing: 14) {
                skeletonRect(width: 64, height: 64, cornerRadius: 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    skeletonRect(width: 140, height: 20, cornerRadius: 6)
                    skeletonRect(width: 100, height: 14, cornerRadius: 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Action buttons
            HStack(spacing: 10) {
                skeletonRect(width: nil, height: 46, cornerRadius: 12)
                skeletonRect(width: 46, height: 46, cornerRadius: 12)
                skeletonRect(width: 46, height: 46, cornerRadius: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "FF6B6B").opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Tab Skeleton
    
    private var tabSkeleton: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(spacing: 8) {
                    skeletonRect(width: 60, height: 16, cornerRadius: 4)
                    skeletonRect(width: 40, height: 2, cornerRadius: 1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "0a0a0f"))
    }
    
    // MARK: - Stats Skeleton
    
    private var statsSkeleton: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 6) {
                    skeletonRect(width: 40, height: 20, cornerRadius: 4)
                    skeletonRect(width: 60, height: 12, cornerRadius: 3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Filter Skeleton
    
    private var filterSkeleton: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                skeletonRect(width: CGFloat(50 + (index % 3) * 20), height: 34, cornerRadius: 17)
            }
            Spacer()
        }
    }
    
    // MARK: - Card Skeleton
    
    private var cardSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                skeletonCircle(size: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    skeletonRect(width: 100, height: 14, cornerRadius: 4)
                    skeletonRect(width: 80, height: 10, cornerRadius: 3)
                }
                
                Spacer()
                
                skeletonRect(width: 50, height: 20, cornerRadius: 10)
            }
            
            // Content lines
            VStack(alignment: .leading, spacing: 8) {
                skeletonRect(width: nil, height: 14, cornerRadius: 4)
                skeletonRect(width: 260, height: 14, cornerRadius: 4)
            }
            
            // Image placeholder (50% chance)
            if Int.random(in: 0...1) == 1 {
                skeletonRect(width: nil, height: 160, cornerRadius: 12)
            }
            
            // Actions
            HStack(spacing: 20) {
                skeletonRect(width: 50, height: 16, cornerRadius: 4)
                skeletonRect(width: 50, height: 16, cornerRadius: 4)
                Spacer()
                skeletonRect(width: 20, height: 16, cornerRadius: 4)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Skeleton Shapes
    
    private func skeletonRect(width: CGFloat?, height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isAnimating ? 0.08 : 0.04),
                        Color.white.opacity(isAnimating ? 0.04 : 0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
    }
    
    private func skeletonCircle(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isAnimating ? 0.08 : 0.04),
                        Color.white.opacity(isAnimating ? 0.04 : 0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size, height: size)
    }
}

// MARK: - Error View

struct CommunityErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF6B6B").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: retry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compose View

struct CommunityComposeView: View {
    @ObservedObject var viewModel: CommunityFeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var postText: String = ""
    @State private var isPosting: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxCharacters = 500
    
    var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        postText.count <= maxCharacters &&
        !isPosting
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0f")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Game context
                    gameContext
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Compose area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // User info
                            HStack(spacing: 12) {
                                if let poko = PokoProvider.shared.userSelectedPoko,
                                   let url = URL(string: poko.headshotUrl) {
                                    CachedAsyncImageView(url: url)
                                        .frame(width: 44, height: 44)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text("😊")
                                                .font(.system(size: 20))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(UserProvider.shared.currentUser?.screenName ?? "You")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Posting to \(viewModel.game.gameName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            // Text field
                            TextField("What's on your mind?", text: $postText, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .lineLimit(10...)
                                .focused($isTextFieldFocused)
                                .padding(.horizontal, 16)
                            
                            // Selected image preview
                            if let image = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button(action: { selectedImage = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .shadow(radius: 4)
                                    }
                                    .padding(8)
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                    
                    // Bottom toolbar
                    bottomToolbar
                }
                
                // Posting overlay
                if isPosting {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Posting...")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color(hex: "1a1a2e"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Create Post")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: post) {
                        Text("Post")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                canPost
                                    ? LinearGradient(
                                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(!canPost)
                }
            }
            .toolbarBackground(Color(hex: "0a0a0f"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - Game Context
    
    private var gameContext: some View {
        HStack(spacing: 10) {
            if let url = viewModel.game.bestImageURL {
                CachedAsyncImageView(url: url)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Text(viewModel.game.gameName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            if let stats = viewModel.stats {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "4ADE80"))
                        .frame(width: 6, height: 6)
                    Text("\(stats.formattedMemberCount) members")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                // Add image button
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
                
                Button(action: {}) {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.leading, 16)
                
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Character count
                Text("\(postText.count)/\(maxCharacters)")
                    .font(.system(size: 12))
                    .foregroundColor(
                        postText.count > maxCharacters
                            ? Color(hex: "FF6B6B")
                            : .white.opacity(0.4)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "0a0a0f"))
        }
    }
    
    // MARK: - Post Action
    
    private func post() {
        guard canPost else { return }
        
        isPosting = true
        
        Task {
            do {
                try await viewModel.createPost(
                    text: postText.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageUrl: nil // TODO: Upload image and get URL
                )
                
                await MainActor.run {
                    isPosting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    // Show error
                }
            }
        }
    }
}










































































