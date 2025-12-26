//
//  GameDetailViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import Combine

// We need to move the MediaItem enum here so the View and ViewModel can share it.
enum MediaItem: Identifiable {
    case youtube(id: String, duration: TimeInterval?)
    case image(url: URL)
    
    var id: String {
        switch self {
        case .youtube(let id, _):
            return id
        case .image(let url):
            return url.absoluteString
        }
    }
}

enum PlayerExperienceTier: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case hardcore
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .hardcore: return "Hardcore"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green      // 🌱
        case .intermediate: return .orange // medium
        case .hardcore: return .red        // sweaty
        }
    }
    
    /// 0, 1, 2 for layout math
    var index: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .hardcore: return 2
        }
    }
}

struct GameDetailStat: Identifiable {
    let id: String          // for ForEach
    let label: String
    let value: String
    let colorHint: Color?   // optional, view can ignore or use
}

@MainActor
class GameDetailViewModel: ObservableObject {
    
    // The initial, simple game object
    let game: GamerConnectGame
    let experienceTier: PlayerExperienceTier
    
    // The fully detailed game object, fetched from the network
    @Published var enrichedGame: GamerConnectGame?
    @Published var isLoading: Bool = true
    
    // Data for the carousels, processed from enrichedGame
    @Published var videoItems: [MediaItem] = []     // Separated
    @Published var screenshotItems: [MediaItem] = [] // Separated
    @Published var similarGameItems: [MediaItem] = []
    @Published var communityPosts: [CommunityPost] = []
    
    // State for the intro animation
    @Published var showContentBlocks: [Bool] = Array(repeating: false, count: 10) // For staggering
    
    
    init(game: GamerConnectGame, user: User) {
        self.game = game
        self.experienceTier = user.experienceTier
    }
    
    var primaryStats: [GameDetailStat] {
        // pull from enrichedGame / GamerConnectGame
        let game = enrichedGame
        
        let complexityValue = game?.complexityLabel ?? "--"
        let timeValue       = game?.timeCommitment ?? game?.timeLabel ?? "--"
        let criticValue     = game?.criticScoreString ?? "--"   // however you expose it
        let userValue       = game?.userScoreString ?? "--"
        let platformValue   = game?.platformsString ?? "--"             // e.g. "PS5 • PC"
        let ageValue        = game?.ageRatingString ?? "--"                // e.g. "T (Teen)"

        switch experienceTier {
        case .beginner:
            return [
                GameDetailStat(id: "complexity", label: "Complexity", value: complexityValue, colorHint: nil),
                GameDetailStat(id: "time",       label: "Time",       value: timeValue,       colorHint: nil),
                GameDetailStat(id: "platforms",  label: "Plays On",   value: platformValue,   colorHint: nil),
                GameDetailStat(id: "age",        label: "Age",        value: ageValue,        colorHint: nil)
            ]
            
        case .intermediate:
            return [
                GameDetailStat(id: "time",       label: "Time",       value: timeValue,       colorHint: nil),
                GameDetailStat(id: "complexity", label: "Complexity", value: complexityValue, colorHint: nil),
                GameDetailStat(id: "critic",     label: "Critic",     value: criticValue,     colorHint: nil),
                GameDetailStat(id: "user",       label: "User",       value: userValue,       colorHint: nil)
            ]
            
        case .hardcore:
            return [
                GameDetailStat(id: "time",       label: "Time",       value: timeValue,       colorHint: nil),
                GameDetailStat(id: "complexity", label: "Complexity", value: complexityValue, colorHint: nil),
                GameDetailStat(id: "critic",     label: "Critic",     value: criticValue,     colorHint: nil),
                GameDetailStat(id: "user",       label: "User",       value: userValue,       colorHint: nil)
            ]
        }
    }
    
    /// This replaces the fetchEnrichedGameDetails() logic from the UIKit file
    func fetchDetails() async {
        // Avoid refetching if we already have rich data
        /*if let existing = GameStorageManager.shared.getGame(id: game.id), existing.summary != nil {
            self.enrichedGame = existing
            self.processEnrichedData(existing)
            self.loadMockCommunityPosts()
            self.isLoading = false
            self.runIntroAnimation()
            return
        }*/
        
        self.isLoading = true
        
        let igdbGame = await IGDBService.shared.fetchGameDetails(bySlug: game.slug)
        
        if let fullGame = igdbGame {
            self.enrichedGame = fullGame
            self.processEnrichedData(fullGame)
            GameStorageManager.shared.save(game: fullGame)
        }
        
        self.loadMockCommunityPosts()
        
        withAnimation(.easeOut(duration: 0.5)) {
            self.isLoading = false
        }
        self.runIntroAnimation()
    }
    
    private func processEnrichedData(_ game: GamerConnectGame) {
        // Separate Videos
        if let vids = game.videos {
            self.videoItems = vids.compactMap { video in
                guard let id = video.video_id,
                      !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return nil
                }
                return .youtube(id: id, duration: nil)
            }
        } else {
            self.videoItems = []
        }

        // Screenshots → [MediaItem]
        if let shots = game.screenshots {
            self.screenshotItems = shots.compactMap { shot in
                guard var path = shot.url,
                      !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return nil
                }
                
                // IGDB often returns "//..." or "//images.igdb.com/..."
                if !path.hasPrefix("http") {
                    path = "https:" + path
                }
                
                guard let url = URL(string: path) else {
                    return nil
                }
                
                return .image(url: url)
            }
        } else {
            self.screenshotItems = []
        }
        
        // Similar Games
        if let similar = game.similar_games {
            self.similarGameItems = similar.compactMap { sim -> MediaItem? in
                guard let urlStr = sim.cover?.url else { return nil }
                let highRes = "https:" + urlStr.replacingOccurrences(of: "t_thumb", with: "t_cover_big_2x")
                guard let url = URL(string: highRes) else { return nil }
                return .image(url: url)
            }
        }
    }
    
    private func loadMockCommunityPosts() {
        self.communityPosts = [
            CommunityPost(id: "p1", authorName: "EldenLord99", authorAvatar: "https://i.pravatar.cc/150?img=11", timeAgo: "2h ago", type: .video, title: "Finally beat Malenia!", bodyText: nil, mediaUrl: "https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=400", likes: 1240, isLiked: true),
            CommunityPost(id: "p2", authorName: "CasualGamer", authorAvatar: "https://i.pravatar.cc/150?img=5", timeAgo: "5h ago", type: .text, title: nil, bodyText: "Does anyone else think the exploration in this game ruins other open worlds?", mediaUrl: nil, likes: 856, isLiked: false)
        ]
    }
    
    func togglePostLike(_ postID: String) {
        if let index = communityPosts.firstIndex(where: { $0.id == postID }) {
            communityPosts[index].isLiked.toggle()
            communityPosts[index].likes += communityPosts[index].isLiked ? 1 : -1
        }
    }
    
    private func runIntroAnimation() {
        for i in 0..<showContentBlocks.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 * Double(i))) {
                showContentBlocks[i] = true
            }
        }
    }
}

extension User {
    var experienceTier: PlayerExperienceTier {
        let level = Int(gamingExperience) ?? 3
        switch level {
        case ...2:  return .beginner
        case 3:     return .intermediate
        default:    return .hardcore
        }
    }
}
