//
//  InnerCategoryView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct InnerCategoryView: View {
    let category: DiscoverPageCategory
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    let onGameTapped: (GamerConnectGame) -> Void
    
    @StateObject private var viewModel: InnerCategoryViewModel
    
    init(
            category: DiscoverPageCategory,
            namespace: Namespace.ID,
            onDismiss: @escaping () -> Void,
            onGameTapped: @escaping (GamerConnectGame) -> Void
        ) {
            self.category = category
            self.namespace = namespace
            self.onDismiss = onDismiss
            self.onGameTapped = onGameTapped
            _viewModel = StateObject(wrappedValue: InnerCategoryViewModel(category: category))
        }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. Dynamic Blurred Background (RESTORED: GeometryReader, No Animation)
            GeometryReader { geo in
                CachedAsyncImage(url: URL(string: category.imageUrl))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    // No .matchedGeometryEffect on the background image anymore
                    .blur(radius: 50)
                    .opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 2. Nav Bar
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button { } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60) // Safe area compensation
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // 3. Title & Hero Transition
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURATED LIST")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Color.indigo)
                            
                            Text(category.title)
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(.white)
                                // ✅ FIX: Prevents ellipsizing/jumping during animation
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                //.matchedGeometryEffect(id: "category_title_\(category.id)", in: namespace)
                            
                            Text("\(viewModel.games.count) experiences curated for you.")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        // 4. Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("Filter list...", text: $viewModel.searchText)
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        // 5. Loading State
                        if viewModel.isLoading {
                            InnerCategorySkeleton()
                                .transition(.opacity)
                        } else {
                            // 6. Content
                            VStack(alignment: .leading, spacing: 24) {
                                
                                // Featured Horizontal
                                if !viewModel.featuredGames.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("TOP PICKS")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1.5)
                                            .foregroundStyle(.white.opacity(0.6))
                                            .padding(.horizontal, 16)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(viewModel.featuredGames) { game in
                                                    GlassFeaturedCard(game: game) {
                                                        onGameTapped(game)   // 👈 TAP -> DETAILS
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                
                                // Vertical List
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("THE COLLECTION")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1.5)
                                            .foregroundStyle(.white.opacity(0.6))
                                        Spacer()
                                        Text("\(viewModel.filteredGames.count) Games")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.filteredGames) { game in
                                            GlassListRow(game: game) {
                                                    onGameTapped(game)       // 👈 TAP -> DETAILS
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await viewModel.loadFullGameDetails()
        }
    }
}


// MARK: - 5. Subviews

struct GlassFeaturedCard: View {
    let game: GamerConnectGame
    var onTap: (() -> Void)? = nil

    @ObservedObject private var userProvider = UserProvider.shared

    // MARK: - Derived State

    private var isInLibrary: Bool {
        guard let _ = userProvider.currentUser else { return false }

        let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !slug.isEmpty {
            return FollowInteractionManager.shared.isGameFollowed(slug: slug)
        } else if let user = userProvider.currentUser {
            // fallback: legacy flow where user.games stores names
            return user.games.contains { $0.caseInsensitiveCompare(game.gameName) == .orderedSame }
        } else {
            return false
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: URL(string: game.imageUrl ?? ""))
                .scaledToFill()
                .frame(width: 260, height: 160)
                .clipped()
            
            LinearGradient(
                colors: [.black.opacity(0.9), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MUST PLAY")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.indigo)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
                
                Text(game.gameName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(12)
            
            // "IN LIBRARY" Badge
            if isInLibrary {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("IN LIBRARY")
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        )
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(width: 260, height: 160)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

struct GlassListRow: View {
    let game: GamerConnectGame
    var onTap: (() -> Void)? = nil

    @ObservedObject private var userProvider = UserProvider.shared

    private var isInLibrary: Bool {
        guard let _ = userProvider.currentUser else { return false }

        let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !slug.isEmpty {
            return FollowInteractionManager.shared.isGameFollowed(slug: slug)
        } else if let user = userProvider.currentUser {
            return user.games.contains { $0.caseInsensitiveCompare(game.gameName) == .orderedSame }
        } else {
            return false
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: URL(string: game.imageUrl ?? ""))
                .scaledToFill()
                .frame(width: 60, height: 80)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.gameName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let rating = game.total_rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", rating / 10)) // IGDB is 0-100
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(4)
                    }
                    
                    if let genre = game.gameType {
                        Text(genre)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    // List Row Badge
                    if isInLibrary {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                            Text("Library")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.green)
                        .padding(.leading, 4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - 6. Skeleton

struct InnerCategorySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Featured Skeleton
            VStack(alignment: .leading, spacing: 12) {
                ShimmerView().frame(width: 80, height: 12).cornerRadius(4).padding(.horizontal, 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<2) { _ in
                            ShimmerView().frame(width: 260, height: 160).cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            // List Skeleton
            VStack(alignment: .leading, spacing: 12) {
                ShimmerView().frame(width: 100, height: 12).cornerRadius(4).padding(.horizontal, 16)
                
                ForEach(0..<5) { _ in
                    HStack(spacing: 16) {
                        ShimmerView().frame(width: 60, height: 80).cornerRadius(8)
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerView().frame(width: 140, height: 16).cornerRadius(4)
                            ShimmerView().frame(width: 80, height: 12).cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    
    @State private var image: UIImage?
    @State private var didLoad = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .transition(.opacity.animation(.easeOut(duration: 0.3)))
            } else {
                Color.zinc800 // Placeholder color
            }
        }
        .task(id: url) {
            guard let url = url, !didLoad else { return }
            if let loaded = await ImageCache.shared.image(for: url) {
                self.image = loaded
                self.didLoad = true
            }
        }
    }
}
