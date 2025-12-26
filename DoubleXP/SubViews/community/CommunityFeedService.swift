//
//  CommunityFeedService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import FirebaseDatabase

// MARK: - Community Feed Service

class CommunityFeedService {
    static let shared = CommunityFeedService()
    
    private let baseURL = "https://us-central1-gameterminal-767f7.cloudfunctions.net/community" // Replace with your actual API base URL
    private let db = Database.database().reference()
    private let appId = "default-app-id"
    
    private init() {}
    
    // MARK: - API Requests
    
    /// Fetch community feed data from the API
    func fetchCommunityFeed(
        gameName: String,
        mode: String = "normal"
    ) async throws -> CommunityFeedResponse {
        var components = URLComponents(string: "\(baseURL)/v1/community-feed")!
        components.queryItems = [
            URLQueryItem(name: "game_name", value: gameName),
            URLQueryItem(name: "mode", value: mode)
        ]
        
        guard let url = components.url else {
            throw CommunityFeedError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityFeedError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let message = httpResponse.statusCode
            throw CommunityFeedError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let jsonString = String(data: data, encoding: .utf8) {
                print("🌐 CommunityFeed raw JSON:\n\(jsonString)")
            }

            let response = try decoder.decode(CommunityFeedResponse.self, from: data)
            return response

        } catch let DecodingError.keyNotFound(key, context) {
            print("🧨 Decoding error: key '\(key.stringValue)' not found")
            print("   CodingPath:", context.codingPath.map { $0.stringValue })
            print("   DebugDescription:", context.debugDescription)
            throw DecodingError.keyNotFound(key, context)      // <- no bare `error`

        } catch let DecodingError.typeMismatch(type, context) {
            print("🧨 Decoding error: type mismatch for \(type)")
            print("   CodingPath:", context.codingPath.map { $0.stringValue })
            print("   DebugDescription:", context.debugDescription)
            throw DecodingError.typeMismatch(type, context)

        } catch let DecodingError.valueNotFound(type, context) {
            print("🧨 Decoding error: value not found for \(type)")
            print("   CodingPath:", context.codingPath.map { $0.stringValue })
            print("   DebugDescription:", context.debugDescription)
            throw DecodingError.valueNotFound(type, context)

        } catch let DecodingError.dataCorrupted(context) {
            print("🧨 Decoding error: data corrupted")
            print("   CodingPath:", context.codingPath.map { $0.stringValue })
            print("   DebugDescription:", context.debugDescription)
            throw DecodingError.dataCorrupted(context)

        } catch {
            // HERE `error` *is* valid (implicit from the catch)
            print("🧨 Unknown decoding error:", error)
            throw error
        }
    }
    
    // MARK: - Firebase: Community Stats
    
    /// Fetch community stats for a game
    func fetchCommunityStats(gameId: String) async throws -> CommunityStats {
        let statsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_stats").child(gameId)
        
        return try await withCheckedThrowingContinuation { continuation in
            statsRef.observeSingleEvent(of: .value) { snapshot in
                if let dict = snapshot.value as? [String: Any] {
                    let memberCount = dict["memberCount"] as? Int ?? 0
                    let onlineCount = dict["onlineCount"] as? Int ?? 0
                    let postsToday = dict["postsToday"] as? Int ?? 0
                    let trendingRank = dict["trendingRank"] as? Int
                    
                    let stats = CommunityStats(
                        memberCount: memberCount,
                        onlineCount: onlineCount,
                        postsToday: postsToday,
                        trendingRank: trendingRank
                    )
                    continuation.resume(returning: stats)
                } else {
                    // Return default stats if none exist
                    let stats = CommunityStats(
                        memberCount: 0,
                        onlineCount: 0,
                        postsToday: 0,
                        trendingRank: nil
                    )
                    continuation.resume(returning: stats)
                }
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Firebase: Community Members
    
    /// Fetch members who have this game in their profile
    func fetchCommunityMembers(
        gameId: String,
        limit: Int = 50,
        lastKey: String? = nil
    ) async throws -> (members: [CommunityMember], lastKey: String?) {
        let membersRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_members").child(gameId)
        
        var query = membersRef.queryOrderedByKey().queryLimited(toFirst: UInt(limit + 1))
        
        if let lastKey = lastKey {
            query = membersRef.queryOrderedByKey().queryStarting(afterValue: lastKey).queryLimited(toFirst: UInt(limit + 1))
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            query.observeSingleEvent(of: .value) { snapshot in
                var members: [CommunityMember] = []
                var newLastKey: String? = nil
                
                let children = snapshot.children.allObjects as? [DataSnapshot] ?? []
                
                for (index, child) in children.enumerated() {
                    // If we got limit + 1 results, the last one is for pagination
                    if index == limit {
                        newLastKey = children[limit - 1].key
                        break
                    }
                    
                    guard let dict = child.value as? [String: Any] else { continue }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict)
                        var member = try JSONDecoder().decode(CommunityMember.self, from: jsonData)
                        members.append(member)
                    } catch {
                        print("Error decoding member: \(error)")
                    }
                }
                
                continuation.resume(returning: (members, newLastKey))
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Firebase: User Posts
    
    /// Fetch user posts for a game community
    func fetchUserPosts(
        gameId: String,
        limit: Int = 20,
        lastTimestamp: Double? = nil
    ) async throws -> (posts: [CommunityUserPost], lastTimestamp: Double?) {
        let postsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_posts").child(gameId)
        
        var query = postsRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: UInt(limit + 1))
        
        if let lastTimestamp = lastTimestamp {
            query = postsRef.queryOrdered(byChild: "timestamp")
                .queryEnding(beforeValue: lastTimestamp)
                .queryLimited(toLast: UInt(limit + 1))
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            query.observeSingleEvent(of: .value) { snapshot in
                var posts: [CommunityUserPost] = []
                var newLastTimestamp: Double? = nil
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let dict = childSnapshot.value as? [String: Any] else { continue }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict)
                        var post = try JSONDecoder().decode(CommunityUserPost.self, from: jsonData)
                        posts.append(post)
                    } catch {
                        print("Error decoding post: \(error)")
                    }
                }
                
                // Sort by timestamp descending (newest first)
                posts.sort { $0.timestamp > $1.timestamp }
                
                // Handle pagination
                if posts.count > limit {
                    newLastTimestamp = posts.last?.timestamp
                    posts = Array(posts.prefix(limit))
                }
                
                continuation.resume(returning: (posts, newLastTimestamp))
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Listen to user posts in real-time
    func listenToUserPosts(
        gameId: String,
        limit: Int = 20,
        completion: @escaping ([CommunityUserPost]) -> Void
    ) -> DatabaseHandle {
        let postsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_posts").child(gameId)
        
        let query = postsRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: UInt(limit))
        
        let handle = query.observe(.value) { snapshot in
            var posts: [CommunityUserPost] = []
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let dict = childSnapshot.value as? [String: Any] else { continue }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict)
                    var post = try JSONDecoder().decode(CommunityUserPost.self, from: jsonData)
                    posts.append(post)
                } catch {
                    print("Error decoding post: \(error)")
                }
            }
            
            // Sort by timestamp descending
            posts.sort { $0.timestamp > $1.timestamp }
            completion(posts)
        }
        
        return handle
    }
    
    func removeListener(handle: DatabaseHandle, gameId: String) {
        let postsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_posts").child(gameId)
        postsRef.removeObserver(withHandle: handle)
    }
    
    // MARK: - Firebase: Post a User Post
    
    func createUserPost(
        gameId: String,
        gameName: String,
        text: String,
        imageUrl: String? = nil
    ) async throws {
        guard let currentUser = await UserProvider.shared.currentUser else {
            throw CommunityFeedError.notAuthenticated
        }
        
        let postsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_posts").child(gameId)
        
        let postId = postsRef.childByAutoId().key ?? UUID().uuidString
        
        let post = CommunityUserPost(
            id: postId,
            userId: currentUser.uId,
            userName: currentUser.screenName,
            userAvatar: PokoProvider.shared.userSelectedPoko?.headshotUrl,
            gameId: gameId,
            gameName: gameName,
            text: text,
            imageUrl: imageUrl,
            timestamp: Date().timeIntervalSince1970 * 1000,
            likeCount: 0,
            commentCount: 0
        )
        
        let data = try JSONEncoder().encode(post)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CommunityFeedError.encodingError
        }
        
        try await postsRef.child(postId).setValue(dict)
        
        // Increment posts today counter
        let statsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_stats").child(gameId).child("postsToday")
        
        try await statsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value += 1
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
    }
    
    // MARK: - Firebase: Join/Leave Community
    
    func joinCommunity(gameId: String) async throws {
        guard let currentUser = await UserProvider.shared.currentUser else {
            throw CommunityFeedError.notAuthenticated
        }
        
        // --- Existing: write member under artifacts/community_members ---
        let memberRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_members").child(gameId).child(currentUser.uId)
        
        let memberData: [String: Any] = [
            "id": currentUser.uId,
            "screenName": currentUser.screenName,
            "pokoHeadshotUrl": PokoProvider.shared.userSelectedPoko?.headshotUrl ?? "",
            "games": currentUser.games,
            "isOnline": true,
            "lastActive": ServerValue.timestamp()
        ]
        
        try await memberRef.setValue(memberData)
        
        // --- Existing: increment memberCount under artifacts/community_stats ---
        let statsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_stats").child(gameId).child("memberCount")
        
        try await statsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value += 1
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
        
        // --- NEW: add gameId to user's "communities" array ---
        let userCommunitiesRef = db.child("Users").child(currentUser.uId).child("communities")
        
        try await userCommunitiesRef.runTransactionBlock { currentData in
            var communities = currentData.value as? [String] ?? []
            
            if !communities.contains(gameId) {
                communities.append(gameId)
            }
            
            currentData.value = communities
            return TransactionResult.success(withValue: currentData)
        }
        
        let uid = currentUser.uId
        _ = await UserProvider.shared.loadUser(uid: uid)
    }

    func leaveCommunity(gameId: String) async throws {
        guard let currentUser = await UserProvider.shared.currentUser else {
            throw CommunityFeedError.notAuthenticated
        }
        
        // --- Existing: remove member under artifacts/community_members ---
        let memberRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_members").child(gameId).child(currentUser.uId)
        
        try await memberRef.removeValue()
        
        // --- Existing: decrement memberCount under artifacts/community_stats ---
        let statsRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_stats").child(gameId).child("memberCount")
        
        try await statsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value = max(0, value - 1)
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
        
        // --- NEW: remove gameId from user's "communities" array ---
        let userCommunitiesRef = db.child("Users").child(currentUser.uId).child("communities")
        
        try await userCommunitiesRef.runTransactionBlock { currentData in
            var communities = currentData.value as? [String] ?? []
            
            if let index = communities.firstIndex(of: gameId) {
                communities.remove(at: index)
            }
            
            currentData.value = communities
            return TransactionResult.success(withValue: currentData)
        }
        let uid = currentUser.uId
        _ = await UserProvider.shared.loadUser(uid: uid)
    }
    
    func checkMembership(gameId: String) async -> Bool {
        guard let currentUser = await UserProvider.shared.currentUser else {
            return false
        }
        
        let memberRef = db.child("artifacts").child(appId).child("public").child("data")
            .child("community_members").child(gameId).child(currentUser.uId)
        
        return await withCheckedContinuation { continuation in
            memberRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot.exists())
            }
        }
    }
}

// MARK: - Errors

enum CommunityFeedError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case notAuthenticated
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .notAuthenticated:
            return "You must be logged in"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        }
    }
}
