//
//  GameDetailView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import WebKit

struct CommunityPost: Identifiable, Sendable {
    let id: String
    let authorName: String
    let authorAvatar: String
    let timeAgo: String
    let type: PostType
    let title: String?
    let bodyText: String?
    let mediaUrl: String?
    var likes: Int
    var isLiked: Bool
    
    enum PostType {
        case text
        case video
    }
}

struct GameDetailView: View {
    // --- Transition Properties ---
    let game: GamerConnectGame
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    // --- State ---
    @StateObject private var viewModel: GameDetailViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var isFollowing: Bool = false
    @State private var selectedVideoID: String? = nil
    @State private var showVideoPlayer: Bool = false
    
    @State private var isGameFollowed: Bool = false
    @State private var followButtonScale: CGFloat = 1.0
    @State private var selectedMode: PlayerExperienceTier = .intermediate
    @State private var showCommunitySheet: Bool = false
    
    var dominantColorTask: Task<Color, Never>? // Updated to match RootView's type
    @State private var selectedImageURL: URL? = nil
    @State private var showImageViewer: Bool = false
    private var displayGame: GamerConnectGame {
            viewModel.enrichedGame ?? game
        }
    
    // --- Layout Constants ---
    private let heroHeight: CGFloat = UIScreen.main.bounds.height * 0.60
    
    init(game: GamerConnectGame,
         namespace: Namespace.ID,
         dominantColorTask: Task<Color, Never>? = nil,
         onDismiss: @escaping () -> Void) {
        self.game = game
        self.namespace = namespace
        self.onDismiss = onDismiss
        self.dominantColorTask = dominantColorTask
        self._viewModel = StateObject(wrappedValue: GameDetailViewModel(game: game, user: UserProvider.shared.currentUser!))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // 1. Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // A. Hero Section
                    heroSection
                    
                    // B. Body Content (Overlaps Hero)
                    if viewModel.isLoading {
                        GameDetailSkeleton()
                            .padding(.top, -60) // Pull up overlap
                    } else {
                        bodyContent
                            .padding(.top, -60) // Pull up overlap
                            .padding(.bottom, 100) // Space for bottom bar
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
                    }
                )
            }
            .ignoresSafeArea(edges: .top)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // 2. Fixed Top Header (Nav + Actions)
            topHeader
            
            // 3. Fixed Bottom Bar (Buy)
            stickyBottomBar
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoID = selectedVideoID {
                GameDetailsVideoPlayerView(videoID: videoID, isPresented: $showVideoPlayer)
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let url = selectedImageURL {
                GameDetailsImageViewer(url: url, isPresented: $showImageViewer)
            }
        }
        .sheet(isPresented: $showCommunitySheet) {
            // Prefer enriched game if we have it, fall back to the shallow one
            CommunityPageView(game: viewModel.enrichedGame ?? game)
        }
        .task {
            await viewModel.fetchDetails()
            isGameFollowed = FollowInteractionManager.shared.isGameFollowed(slug: game.slug)
        }
        .onAppear {
            if let user = UserProvider.shared.currentUser {
                selectedMode = user.experienceTier   // <- from the User extension
            } else {
                selectedMode = .intermediate         // safe default
            }
        }
    }
    
    // MARK: - Components
    
    private var heroSection: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let isStretching = minY > 0
            let height = isStretching ? heroHeight + minY : heroHeight
            
            ZStack(alignment: .bottom) {
                // Image with Hero Transition
                GameDetailsHeroArt(game: game, namespace: namespace)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: height)
                    .clipped()
                    .offset(y: isStretching ? -minY : 0)
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.black, .black.opacity(0.6), .clear, .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
        }
        .frame(height: heroHeight)
    }
    
    private var topHeader: some View {
        VStack {
            HStack(spacing: 12) {
                // Back
                Button(action: onDismiss) {
                    CircleButton(icon: "arrow.left")
                }
                
                Spacer()
                
                // Community
                Button(action: {
                    showCommunitySheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Community")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                Button(action: {
                    Task {
                        do {
                            let newState = try await FollowInteractionManager.shared.toggleGameFollow(game: game)
                            
                            await MainActor.run {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                                    isGameFollowed = newState
                                    followButtonScale = 1.2
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.05)) {
                                    followButtonScale = 1.0
                                }
                            }
                        } catch {
                            print("❌ Failed to toggle follow: \(error)")
                        }
                    }
                }) {
                    CircleButton(
                        icon: isGameFollowed ? "checkmark" : "plus",
                        color: isGameFollowed ? .green : .white
                    )
                    .scaleEffect(followButtonScale)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Safe area
            
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    private func storeLabel(for type: String) -> String {
        switch type {
        case "steam": return "Get on Steam"
        case "epic":  return "Get on Epic"
        case "gog":   return "Get on GOG"
        case "xbox":  return "Get on Xbox"
        case "ps":    return "Get on PlayStation"
        case "switch":return "Get on Switch"
        default:      return "Get Game"
        }
    }

    private func storeIconName(for type: String) -> String {
        switch type {
        case "steam": return "pc"            // or some SF Symbol combo
        case "xbox":  return "xbox.logo"     // iOS 18 has some, otherwise use generic
        case "ps":    return "gamecontroller"
        default:      return "gamecontroller"
        }
    }
    
    private var complexityColor: Color {
        guard let label = viewModel.enrichedGame?.complexityLabel else {
            return .gray
        }
        
        switch label {
        case "Beginner-friendly":
            return .green
        case "Intermediate":
            return .orange
        case "Hardcore":
            return .red
        default:
            return .gray
        }
    }
    
    private var stickyBottomBar: some View {
            VStack(spacing: 0) {
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Spacer()
                    
                    // 👉 Use displayGame here so primaryStoreLink can come from enriched game
                    if let store = displayGame.primaryStoreLink,
                       let url = URL(string: store.url) {
                        Button {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } label: {
                            HStack(spacing: 8) {
                                Text(storeLabel(for: store.type.rawValue))
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: storeIconName(for: store.type.rawValue))
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                            .shadow(radius: 10, y: 4)
                        }
                    } else {
                        // Fallback: maybe hide the button or open a Google search
                        Button {
                            let query = displayGame.gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://www.google.com/search?q=\(query)+game") {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        } label: {
                            Text("Search Game")
                                .font(.system(size: 16, weight: .bold))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
            }
        }
    
    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // 1. Title & Metadata
            VStack(alignment: .leading, spacing: 8) {
                Text(game.gameName)
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(nil) // Allow wrap
                    .fixedSize(horizontal: false, vertical: true) // Dynamic height
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                
                HStack(spacing: 8) {
                    if let dev = viewModel.enrichedGame?.developer {
                        Text(dev).font(.system(size: 14, weight: .bold))
                    }
                    Text("•").foregroundColor(.gray)
                    if let date = viewModel.enrichedGame?.releaseDate {
                        Text(date).font(.system(size: 14, weight: .medium))
                    }
                }
                .foregroundStyle(Color.gray)
            }
            .padding(.horizontal, 24)
            
            ExperienceModeSelector(selectedMode: $selectedMode)
                .padding(.horizontal, 24)
                .padding(.top, 4)
            
            // 2. Stats Grid (4 Columns)
            HStack(spacing: 8) {
                ForEach(viewModel.primaryStats) { stat in
                    let color = (stat.label == "Complexity")
                        ? complexityColor   // your helper that maps label → color
                        : .white

                    StatBox(label: stat.label,
                            value: stat.value,
                            color: color)
                }
            }
            .padding(.horizontal, 24)
            
            // 3. Description (Full Dynamic)
            let desc = viewModel.enrichedGame?.summary ?? game.gameDescription
            if !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.zinc300)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }
            
            // 4. Community Posts (New)
            if !viewModel.communityPosts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("COMMUNITY POSTS").font(.system(size: 12, weight: .bold)).tracking(1).foregroundStyle(.gray)
                        Spacer()
                        Button("See All") { }.font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }.padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.communityPosts) { post in
                                CommunityPostRow(post: post) { viewModel.togglePostLike(post.id) }
                            }
                        }.padding(.horizontal, 24)
                    }
                }
            }
            
            // 5. Videos Section (New Split)
            if !viewModel.videoItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("VIDEOS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.videoItems) { item in
                                GameMediaCard(item: item) {
                                    if case .youtube(let id, _) = item {
                                        selectedVideoID = id
                                        showVideoPlayer = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            // 6. Screenshots Section (New Split)
            if !viewModel.screenshotItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SCREENSHOTS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.screenshotItems) { item in
                                GameMediaCard(item: item) {
                                    if case .image(let url) = item {
                                        selectedImageURL = url
                                        showImageViewer = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            // 7. Similar Games
            if !viewModel.similarGameItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOU MIGHT ALSO LIKE").font(.system(size: 12, weight: .bold)).tracking(1).foregroundStyle(.gray).padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.similarGameItems) { item in
                                GameMediaCard(item: item)
                            }
                        }.padding(.horizontal, 24)
                    }
                }
            }
        }
    }
}

struct CommunityPostRow: View {
    let post: CommunityPost
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: post.authorAvatar)) { img in img.resizable().scaledToFill() } placeholder: { Color.gray }
                    .frame(width: 24, height: 24).clipShape(Circle())
                Text(post.authorName).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                Text("•").font(.caption).foregroundStyle(.gray)
                Text(post.timeAgo).font(.system(size: 11)).foregroundStyle(.gray)
                Spacer()
            }
            
            if post.type == .video, let mediaUrl = post.mediaUrl, let url = URL(string: mediaUrl) {
                VStack(alignment: .leading, spacing: 6) {
                    if let title = post.title { Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(2) }
                    ZStack {
                        AsyncImage(url: url) { img in img.resizable().aspectRatio(contentMode: .fill) } placeholder: { Color.black }
                        Image(systemName: "play.fill").font(.title3).foregroundStyle(.white).padding(10).background(.ultraThinMaterial).clipShape(Circle())
                    }
                    .frame(height: 120).frame(maxWidth: .infinity).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            } else {
                Text(post.bodyText ?? "").font(.system(size: 13)).foregroundStyle(.white.opacity(0.9)).lineLimit(4).lineSpacing(4)
            }
            
            HStack {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart").foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likes)").font(.system(size: 12, weight: .medium)).foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "bubble.right").font(.system(size: 12)).foregroundColor(.gray)
            }
        }
        .padding(12).frame(width: 280).background(.ultraThinMaterial).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Helper Views

struct CircleButton: View {
    let icon: String
    var color: Color = .white
    
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            )
            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.gray)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct GameMediaCard: View {
    let item: MediaItem
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            switch item {
            case .youtube(let id, _):
                AsyncImage(url: URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.zinc300.opacity(0.1)
                    }
                }
                
                // Play Button Overlay
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
            case .image(let url):
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.zinc300.opacity(0.1)
                    }
                }
            }
        }
        .frame(width: 260, height: 146)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

struct GameDetailsHeroArt: View {
    let game: GamerConnectGame
    let namespace: Namespace.ID
    
    var body: some View {
        CachedAsyncImage(url: URL(string: game.imageUrl ?? ""))
            //.matchedGeometryEffect(id: "game_cover_\(game.id)", in: namespace)
    }
}

// MARK: - Skeleton Loading

struct GameDetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView().frame(width: 200, height: 40).cornerRadius(8)
                ShimmerView().frame(width: 150, height: 16).cornerRadius(4)
            }
            .padding(.horizontal, 24)
            
            // Stats Grid
            HStack(spacing: 8) {
                ForEach(0..<4) { _ in
                    ShimmerView().frame(height: 60).cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<5) { _ in
                    ShimmerView().frame(height: 14).cornerRadius(4)
                }
            }
            .padding(.horizontal, 24)
            
            // Media
            VStack(alignment: .leading, spacing: 12) {
                ShimmerView().frame(width: 60, height: 12).cornerRadius(4).padding(.horizontal, 24)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            ShimmerView().frame(width: 260, height: 146).cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

// MARK: - Animation Helper

struct StaggeredFadeInModifier: ViewModifier {
    let show: Bool
    let delayIndex: Int
    
    func body(content: Content) -> some View {
        content
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 16)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(0.1 * Double(delayIndex)),
                value: show
            )
    }
}

extension View {
    func staggeredFadeIn(show: Bool, delayIndex: Int) -> some View {
        self.modifier(StaggeredFadeInModifier(show: show, delayIndex: delayIndex))
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Data Helpers
extension GamerConnectGame {
    var criticScoreString: String {
        if let score = aggregated_rating { return "\(Int(score.rounded()))" }
        return "N/A"
    }
    
    var userScoreString: String {
        if let score = total_rating { return "\(Int(score.rounded()))" }
        return "N/A"
    }
    
    var releaseDateString: String {
        if let timestamp = first_release_date {
            return Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(date: .abbreviated, time: .omitted)
        }
        return "N/A"
    }
    
    var releaseDateShort: String {
        if let timestamp = first_release_date {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return "TBA"
    }
    
    var ageRatingString: String {
        guard let ratings = age_ratings,
              let esrb = ratings.first(where: { $0.category == 1 }) else {
            return "N/A"
        }
        
        // Mapping based on IGDB Enum: https://api-docs.igdb.com/#age-rating-enum
        switch esrb.rating {
        case 6: return "RP"
        case 7: return "EC"
        case 8: return "E"
        case 9: return "E10+"
        case 10: return "T"
        case 11: return "M"
        case 12: return "AO"
        default: return "N/A"
        }
    }
    
    var developerString: String {
        if let companies = involved_companies,
           let developer = companies.first(where: { $0.developer == true })?.company.name {
            return developer
        }
        return "N/A"
    }
    
    var platformsString: String {
        if let platforms = platforms {
            return platforms.compactMap { $0.abbreviation ?? $0.name }.joined(separator: ", ")
        }
        return "N/A"
    }
    
    var genresString: String {
        if let genres = genres {
            return genres.compactMap { $0.name }.joined(separator: ", ")
        }
        return "N/A"
    }
}

struct GameDetailsVideoPlayerView: View {
    let videoID: String
    @Binding var isPresented: Bool
    
    @State private var isLoading: Bool = true
    @State private var isPlaying: Bool = true
    @State private var showControls: Bool = true
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var playerRef: YouTubePlayerView?
    
    // Get screen size directly - no GeometryReader needed
    private let screenSize = UIScreen.main.bounds.size
    
    var body: some View {
        ZStack {
            // Layer 0: Black background
            Color.black.ignoresSafeArea()
            
            // Layer 1: YouTube Player - create immediately with screen size
            GameDetailsFullscreenYouTubePlayer(
                videoID: videoID,
                startSeconds: 0,
                muted: false,
                onPlayerReady: { player in
                    print("✅ Player ready! Frame: \(player.frame)")
                    playerRef = player
                    isLoading = false
                    startTimePolling(player: player)
                }
            )
            .frame(width: screenSize.width, height: screenSize.height)
            .ignoresSafeArea()
            .zIndex(1)
            
            // Layer 2: Loading indicator
            if isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                    Spacer()
                }
                .zIndex(2)
            }
            
            // Layer 3: Controls overlay
            if showControls && !isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls = false
                        }
                    }
                    .zIndex(3)
                
                VStack {
                    Spacer()
                    centerControls
                    Spacer()
                    bottomBar
                }
                .zIndex(4)
                .transition(.opacity)
            }
            
            // Layer 5: Tap area when controls hidden
            if !showControls && !isLoading {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls = true
                        }
                        scheduleControlsHide()
                    }
                    .zIndex(5)
            }
            
            // Layer 100: Back button - ALWAYS visible
            VStack {
                HStack {
                    Button(action: {
                        print("🔙 Back button tapped")
                        playerRef?.pause()
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
            .zIndex(100)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear {
            print("🎬 Player appeared - videoID: \(videoID), screen size: \(screenSize)")
            scheduleControlsHide()
        }
        .onDisappear {
            print("👋 Player disappeared")
            controlsHideTask?.cancel()
            playerRef?.pause()
        }
    }
    
    // MARK: - Time Polling
    private func startTimePolling(player: YouTubePlayerView) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            guard playerRef != nil else {
                timer.invalidate()
                return
            }
            
            player.samplePlayback { snapshot in
                DispatchQueue.main.async {
                    if let current = snapshot.current {
                        currentTime = current
                    }
                    if let dur = snapshot.duration, dur > 0 {
                        duration = dur
                    }
                    isPlaying = snapshot.state == .playing
                }
            }
        }
    }
    
    // MARK: - Center Controls
    private var centerControls: some View {
        HStack(spacing: 50) {
            Button(action: {
                seekRelative(-10)
                scheduleControlsHide()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: {
                togglePlayPause()
                scheduleControlsHide()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 3)
                }
            }
            
            Button(action: {
                seekRelative(10)
                scheduleControlsHide()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: progressWidth(in: geo.size.width), height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let pct = max(0, min(1, value.location.x / geo.size.width))
                            seekTo(pct * duration)
                        }
                )
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(formatTime(duration))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
    }
    
    // MARK: - Helpers
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return totalWidth * CGFloat(currentTime / duration)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let total = Int(time)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
    private func togglePlayPause() {
        if isPlaying {
            playerRef?.pause()
        } else {
            playerRef?.play()
        }
        isPlaying.toggle()
    }
    
    private func seekRelative(_ seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seekTo(newTime)
    }
    
    private func seekTo(_ time: Double) {
        currentTime = time
        playerRef?.seekTo(time)
    }
    
    private func scheduleControlsHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls = false
                    }
                }
            }
        }
    }
}

// MARK: - YouTube Player UIViewRepresentable
private struct GameDetailsFullscreenYouTubePlayer: UIViewRepresentable {
    let videoID: String
    let startSeconds: Double
    let muted: Bool
    let onPlayerReady: (YouTubePlayerView) -> Void
    
    func makeUIView(context: Context) -> UIView {
        print("📺 makeUIView called - videoID: \(videoID)")
        
        // Create container that will hold the player
        let container = UIView()
        container.backgroundColor = .black
        
        // Create player
        let player = YouTubePlayerView()
        player.backgroundColor = .black
        player.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(player)
        
        // Pin player to container edges
        NSLayoutConstraint.activate([
            player.topAnchor.constraint(equalTo: container.topAnchor),
            player.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            player.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            player.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        context.coordinator.player = player
        context.coordinator.container = container
        
        print("🎬 Loading video immediately...")
        
        DispatchQueue.main.async {
            print("🎬 Loading video (Async)...")
            
            player.load(
                videoID: videoID,
                shouldAutoplay: true,
                startTime: startSeconds,
                playerVars: [
                    "playsinline": 1,
                    "controls": 0,
                    "rel": 0,
                    "modestbranding": 1,
                    "showinfo": 0
                ]
            )
            
            if muted {
                player.mute()
            } else {
                player.unmute()
            }
        }
        
        
        // Poll for ready state
        context.coordinator.readyTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            print("⏱️ Checking if player is ready...")
            if player.isPlayerReady {
                print("✅ Player is ready! Frame: \(player.frame)")
                timer.invalidate()
                context.coordinator.readyTimer = nil
                
                // Force layout
                player.setNeedsLayout()
                player.layoutIfNeeded()
                
                onPlayerReady(player)
            }
        }
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("🔄 updateUIView called")
        // Force layout update
        if let player = context.coordinator.player {
            player.setNeedsLayout()
            player.layoutIfNeeded()
        }
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: YouTubePlayerView?
        var container: UIView?
        var readyTimer: Timer?
        
        deinit {
            print("🗑️ Coordinator deinit")
            readyTimer?.invalidate()
            player?.pause()
        }
    }
}

// MARK: - YouTube Player View Controller

struct ExperienceModeSelector: View {
    @Binding var selectedMode: PlayerExperienceTier
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Customize My Content")
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .kerning(1.3)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            ExperienceModeSlider(selectedMode: $selectedMode)
        }
    }
}


struct ExperienceModeSlider: View {
    @Binding var selectedMode: PlayerExperienceTier
    @Namespace private var highlightNamespace
    
    var body: some View {
        ZStack {
            // Outer pill background (navy-ish)
            Capsule()
                .fill(Color(red: 0.07, green: 0.11, blue: 0.20)) // tweak to taste
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            
            HStack(spacing: 0) {
                ForEach(PlayerExperienceTier.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            selectedMode = mode
                        }
                    } label: {
                        ZStack {
                            // Sliding dark pill behind the active segment
                            if selectedMode == mode {
                                Capsule()
                                    .fill(Color.black.opacity(0.95))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "modeHighlight",
                                                           in: highlightNamespace)
                            }
                            
                            HStack(spacing: 6) {
                                // Dot (colored only when selected, gray otherwise)
                                Circle()
                                    .fill(dotColor(for: mode,
                                                   isSelected: selectedMode == mode))
                                    .frame(width: 7, height: 7)
                                
                                Text(mode.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(2.0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundColor(
                                selectedMode == mode
                                ? Color.white
                                : Color.white.opacity(0.7)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(3)
        }
        .frame(height: 40)
    }
    
    private func dotColor(for mode: PlayerExperienceTier,
                          isSelected: Bool) -> Color {
        guard isSelected else {
            return Color.gray.opacity(0.6)   // subtle gray dots for inactive
        }
        return mode.color                    // green / orange / red for active
    }
}

struct GameDetailsImageViewer: View {
    let url: URL
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if phase.error != nil {
                    Text("Failed to load image")
                        .foregroundColor(.white)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .padding()
            
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}
