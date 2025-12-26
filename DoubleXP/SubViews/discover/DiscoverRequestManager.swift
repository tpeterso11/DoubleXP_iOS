//
//  DiscoverRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import FirebaseDatabase

// MARK: - Response Models

struct DiscoverFeedResponse: Codable {
    let featuredGames: [GamerConnectGame]
    let categories: [DiscoverPageCategory]
}

struct DiscoverPageCategory: Codable, Identifiable {
    var id: String { title }
    let title: String
    let imageUrl: String
    let games: [GamerConnectGame]
}

// MARK: - Player Search Response

struct DiscoverPlayerSearchResponse: Codable {
    let gameSlug: String
    let meta: PlayerSearchMeta
    let users: [PlayerSearchUser]
    
    enum CodingKeys: String, CodingKey {
        case gameSlug = "game_slug"
        case meta
        case users
    }
}

struct PlayerSearchMeta: Codable {
    let source: String
    let requestedLimit: Int
    let matchedUserIds: Int
    let returnedUsers: Int
    let durationMs: Int
    
    enum CodingKeys: String, CodingKey {
        case source
        case requestedLimit = "requested_limit"
        case matchedUserIds = "matched_user_ids"
        case returnedUsers = "returned_users"
        case durationMs = "duration_ms"
    }
}

struct PlayerSearchUser: Codable {
    let uId: String
    let screenName: String
    let gamerTag: String
    let bio: String
    let tagline: String
    let selectedAge: String
    let primaryLanguage: String
    let secondaryLanguage: String
    let gamingExperience: String
    let timezone: String
    let ps: Bool
    let xbox: Bool
    let pc: Bool
    let mobile: Bool
    let nintendo: Bool
    let onlineStatus: String
    let games: [String]
    let userLookingFor: [String]
    let userAbout: [String]
    let communities: [String]
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case screenName = "screen_name"
        case gamerTag = "gamer_tag"
        case bio
        case tagline
        case selectedAge = "selected_age"
        case primaryLanguage = "primary_language"
        case secondaryLanguage = "secondary_language"
        case gamingExperience = "gaming_experience"
        case timezone
        case ps
        case xbox
        case pc
        case mobile
        case nintendo
        case onlineStatus = "online_status"
        case games
        case userLookingFor = "user_looking_for"
        case userAbout = "user_about"
        case communities
    }
    
    /// Convert to the existing User class
    func toUser() -> User {
        let user = User(uId: uId)
        user.screenName = screenName
        user.gamerTag = gamerTag
        user.bio = bio
        user.tagline = tagline
        user.selectedAge = selectedAge
        user.primaryLanguage = primaryLanguage
        user.secondaryLanguage = secondaryLanguage
        user.gamingExperience = gamingExperience
        user.timezone = timezone
        user.ps = ps
        user.xbox = xbox
        user.pc = pc
        user.mobile = mobile
        user.nintendo = nintendo
        user.onlineStatus = onlineStatus
        user.games = games
        user.userLookingFor = userLookingFor
        user.userAbout = userAbout
        user.communities = communities
        return user
    }
}

// MARK: - DiscoverRequestManager

class DiscoverRequestManager {
    static let shared = DiscoverRequestManager()
    
    private let baseURL = "https://us-central1-gameterminal-767f7.cloudfunctions.net"
    private let db = Database.database().reference()
    
    private init() {}
    
    // MARK: - Games Tab
    
    func fetchDiscoverFeed(userGames: [String], gamingExperience: String = "5") async throws -> DiscoverFeedResponse {
        var components = URLComponents(string: "\(baseURL)/discover/v1/discover-feed")!
        components.queryItems = [
            URLQueryItem(name: "user_games", value: userGames.joined(separator: ",")),
            URLQueryItem(name: "experience", value: gamingExperience)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        
        #if DEBUG
        print("🌐 [DiscoverRequestManager] Fetching: \(url.absoluteString)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(DiscoverFeedResponse.self, from: data)
    }
    
    // MARK: - Players Tab
    
    /// Fetch recommended players based on shared games
    /// Uses the GamePlayers index: GamePlayers/{gameSlug}/{uid} = true
    func fetchRecommendedPlayers(forUser userId: String, userGames: [String], limit: Int = 5) async throws -> [User] {
        var candidateScores: [String: Int] = [:] // uid -> shared game count
        
        // For each of the user's games, fetch players from GamePlayers index
        for gameSlug in userGames.prefix(10) {
            do {
                let snapshot = try await db.child("GamePlayers").child(gameSlug).getData()
                
                guard let playerDict = snapshot.value as? [String: Any] else { continue }
                
                for uid in playerDict.keys {
                    guard uid != userId else { continue } // Skip self
                    candidateScores[uid, default: 0] += 1
                }
            } catch {
                print("⚠️ [DiscoverRM] Failed to fetch GamePlayers for \(gameSlug): \(error)")
            }
        }
        
        // Sort by shared game count (descending)
        let sortedCandidates = candidateScores
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        // Fetch full user data for top candidates
        var recommendedUsers: [User] = []
        
        for uid in sortedCandidates {
            if let user = await UserProvider.shared.fetchUser(uid: uid) {
                recommendedUsers.append(user)
            }
        }
        
        return recommendedUsers
    }
    
    /// Search for players by game slug using the Cloud Function
    func searchPlayersForGame(gameSlug: String, limit: Int = 30) async throws -> [User] {
        let url = URL(string: "\(baseURL)/playerSearch/v1/player-search")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let body: [String: Any] = [
            "game_slug": gameSlug,
            "limit": limit
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        #if DEBUG
        print("🌐 [DiscoverRequestManager] Player search for: \(gameSlug)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(DiscoverPlayerSearchResponse.self, from: data)
        
        return searchResponse.users.map { $0.toUser() }
    }
    
    // MARK: - Communities Tab
    
    /// Fetch featured/active communities (most members)
    /// Reads from: ActiveCommunities/{slug} = true
    /// Stats from: community_stats/{slug}/memberCount
    func fetchFeaturedCommunities(limit: Int = 5) async throws -> [DiscoverCommunity] {
        let snapshot = try await db.child("ActiveCommunities").getData()
        
        guard let communitySlugs = snapshot.value as? [String: Any] else {
            return []
        }
        
        var communities: [DiscoverCommunity] = []
        
        // Fetch stats for each community
        for (slug, _) in communitySlugs.prefix(limit * 2) {
            if let community = try? await fetchCommunityInfo(gameSlug: slug) {
                communities.append(community)
            }
        }
        
        // Sort by member count and return top results
        return Array(communities.sorted { $0.memberCount > $1.memberCount }.prefix(limit))
    }
    
    /// Fetch communities that a user has joined
    /// User's communities stored in: Users/{uid}/communities = [slugs]
    func fetchUserCommunities(userId: String) async throws -> [DiscoverCommunity] {
        let userSnapshot = try await db.child("Users").child(userId).child("communities").getData()
        
        guard let communitySlugs = userSnapshot.value as? [String] else {
            return []
        }
        
        var communities: [DiscoverCommunity] = []
        
        for slug in communitySlugs {
            if let community = try? await fetchCommunityInfo(gameSlug: slug, isJoined: true) {
                communities.append(community)
            }
        }
        
        return communities
    }
    
    /// Fetch info for a single community
    /// Stats from: community_stats/{slug}/memberCount, onlineCount
    func fetchCommunityInfo(gameSlug: String, isJoined: Bool = false) async throws -> DiscoverCommunity {
        let statsSnapshot = try await db.child("community_stats").child(gameSlug).getData()
        
        let statsDict = statsSnapshot.value as? [String: Any] ?? [:]
        let memberCount = statsDict["memberCount"] as? Int ?? 0
        let onlineCount = statsDict["onlineCount"] as? Int ?? max(1, memberCount / 10)
        
        // Get game name from local storage or use slug
        let gameName: String
        if let game = GameStorageManager.shared.getGame(slug: gameSlug) {
            gameName = game.gameName
        } else {
            if let fetched = await IGDBService.shared.fetchGameDetails(bySlug: gameSlug, forceReload: false) {
                gameName = fetched.gameName
            } else {
                gameName = gameSlug.replacingOccurrences(of: "-", with: " ").capitalized
            }
        }
        
        let icon = generateCommunityIcon(for: gameSlug)
        
        return DiscoverCommunity(
            id: gameSlug,
            name: gameName,
            gameSlug: gameSlug,
            icon: icon,
            memberCount: memberCount,
            onlineCount: onlineCount,
            isFeatured: false,
            isJoined: isJoined
        )
    }
    
    /// Register a community as active (called when first user joins)
    /// Writes to: ActiveCommunities/{slug} = true
    func registerActiveCommunity(gameSlug: String) async throws {
        try await db.child("ActiveCommunities").child(gameSlug).setValue(true)
    }
    
    /// Join a community
    /// Updates:
    /// - community_members/{slug}/{uid} = { joinedAt: timestamp }
    /// - community_stats/{slug}/memberCount (increment via transaction)
    /// - Users/{uid}/communities (append slug)
    /// - ActiveCommunities/{slug} = true
    func joinCommunity(userId: String, gameSlug: String) async throws {
        // 1. Add user to community_members
        let joinData: [String: Any] = [
            "joinedAt": ServerValue.timestamp()
        ]
        try await db.child("community_members").child(gameSlug).child(userId).setValue(joinData)
        
        // 2. Increment member count using transaction
        let statsRef = db.child("community_stats").child(gameSlug).child("memberCount")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            statsRef.runTransactionBlock({ currentData in
                var count = currentData.value as? Int ?? 0
                count += 1
                currentData.value = count
                return TransactionResult.success(withValue: currentData)
            }, andCompletionBlock: { error, committed, snapshot in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
        
        // 3. Add to user's communities list
        let userCommunitiesRef = db.child("Users").child(userId).child("communities")
        let snapshot = try await userCommunitiesRef.getData()
        var communities = snapshot.value as? [String] ?? []
        if !communities.contains(gameSlug) {
            communities.append(gameSlug)
            try await userCommunitiesRef.setValue(communities)
        }
        
        // 4. Register as active community
        try await registerActiveCommunity(gameSlug: gameSlug)
        
        print("✅ [DiscoverRM] User \(userId) joined community \(gameSlug)")
    }
    
    /// Leave a community
    /// Updates:
    /// - community_members/{slug}/{uid} (remove)
    /// - community_stats/{slug}/memberCount (decrement via transaction)
    /// - Users/{uid}/communities (remove slug)
    func leaveCommunity(userId: String, gameSlug: String) async throws {
        // 1. Remove user from community_members
        try await db.child("community_members").child(gameSlug).child(userId).removeValue()
        
        // 2. Decrement member count using transaction
        let statsRef = db.child("community_stats").child(gameSlug).child("memberCount")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            statsRef.runTransactionBlock({ currentData in
                var count = currentData.value as? Int ?? 0
                count = max(0, count - 1)
                currentData.value = count
                return TransactionResult.success(withValue: currentData)
            }, andCompletionBlock: { error, committed, snapshot in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
        
        // 3. Remove from user's communities list
        let userCommunitiesRef = db.child("Users").child(userId).child("communities")
        let snapshot = try await userCommunitiesRef.getData()
        var communities = snapshot.value as? [String] ?? []
        communities.removeAll { $0 == gameSlug }
        try await userCommunitiesRef.setValue(communities)
        
        print("✅ [DiscoverRM] User \(userId) left community \(gameSlug)")
    }
    
    /// Check if user is a member of a community
    func isUserInCommunity(userId: String, gameSlug: String) async -> Bool {
        do {
            let snapshot = try await db.child("community_members").child(gameSlug).child(userId).getData()
            return snapshot.exists()
        } catch {
            return false
        }
    }
    
    /// Get members of a community
    /// Reads from: community_members/{slug}
    func getCommunityMembers(gameSlug: String, limit: Int = 50) async throws -> [User] {
        let snapshot = try await db.child("community_members").child(gameSlug)
            .queryLimited(toFirst: UInt(limit))
            .getData()
        
        guard let membersDict = snapshot.value as? [String: Any] else {
            return []
        }
        
        var users: [User] = []
        for uid in membersDict.keys {
            if let user = await UserProvider.shared.fetchUser(uid: uid) {
                users.append(user)
            }
        }
        
        return users
    }
    
    // MARK: - Helpers
    
    private func generateCommunityIcon(for gameSlug: String) -> String {
        let slug = gameSlug.lowercased()
        
        if slug.contains("valorant") || slug.contains("counter-strike") || slug.contains("fps") {
            return "⚔️"
        } else if slug.contains("fortnite") || slug.contains("apex") || slug.contains("battle") {
            return "🎯"
        } else if slug.contains("league") || slug.contains("dota") || slug.contains("moba") {
            return "🏆"
        } else if slug.contains("call-of-duty") || slug.contains("cod") {
            return "💀"
        } else if slug.contains("minecraft") {
            return "⛏️"
        } else if slug.contains("rocket") {
            return "🚀"
        } else if slug.contains("overwatch") {
            return "🦸"
        } else if slug.contains("fifa") || slug.contains("nba") || slug.contains("sports") {
            return "⚽"
        } else if slug.contains("racing") || slug.contains("forza") {
            return "🏎️"
        } else if slug.contains("rpg") || slug.contains("elden") || slug.contains("souls") {
            return "🗡️"
        } else if slug.contains("pokemon") {
            return "⚡"
        } else if slug.contains("zelda") {
            return "🛡️"
        } else if slug.contains("mario") {
            return "🍄"
        } else if slug.contains("gta") || slug.contains("grand-theft") {
            return "🚗"
        } else if slug.contains("destiny") {
            return "🌟"
        } else if slug.contains("halo") {
            return "🎖️"
        }
        
        return "🎮"
    }
}
