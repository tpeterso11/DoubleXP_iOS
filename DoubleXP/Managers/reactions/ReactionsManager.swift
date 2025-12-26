//
//  ReactionsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI

enum MediaType: String, Codable {
    case game
    case article
    case video
    case post
    case comment
    case short
    // Add more types as needed
}

enum ReactionType: String, Codable {
    case upvote
    case downvote
    case fire
}

enum ReactionTargetKind: String, Codable {
    case game
    // Future: case media, content, etc.
}

/// Uniquely identifies a reaction target (e.g. a specific game).
struct ReactionTargetKey: Hashable, Codable {
    let kind: ReactionTargetKind
    let id: String
}

/// Aggregate counts for all reactions on a target.
struct ReactionCounts: Codable {
    var upvotes: Int
    var downvotes: Int
    var fire: Int
}

/// Full internal state for a given target: counts + the current user's reaction.
struct ReactionState: Codable {
    var counts: ReactionCounts
    var myReaction: ReactionType?
}

/// Lightweight view model for a target's reaction state.
struct ReactionViewState {
    let upvoteCount: Int
    let downvoteCount: Int
    let fireCount: Int
    let myReaction: ReactionType?
}

/// Payload we will send to the backend when flushing.
struct PendingReactionPayload: Codable, Hashable {
    let targetKind: ReactionTargetKind
    let targetID: String
    let finalReaction: ReactionType?
    let updatedAt: Date
    let artURLString: String?
}

// MARK: - Reactions Manager

import Firebase

@MainActor
final class ReactionsManager: ObservableObject {

    // Singleton instance
    static let shared = ReactionsManager()

    // In-memory state: "type:id" -> isLiked
    @Published private(set) var likedItems: Set<String> = []

    // Pending likes to sync with backend: "type:id" -> (timestamp, mediaType)
    private var pendingLikes: [String: (date: Date, type: MediaType)] = [:]
    
    private let likedStorageKey = "ReactionsManager.LikedItems.v2"
    private let pendingStorageKey = "ReactionsManager.PendingLikes.v2"
    
    // Firebase Config
    private let appId = "default-app-id"
    private let db = Database.database().reference()

    private init() {
        restoreFromDisk()
    }

    // MARK: - Helper to create unified key

    private func makeKey(type: MediaType, id: String) -> String {
        return "\(type.rawValue):\(id)"
    }

    // MARK: - Public View Accessors

    struct LikeState {
        let isLiked: Bool
    }
    
    func viewStateForArticle(id: String) -> LikeState {
        let key = makeKey(type: .article, id: id)
        return LikeState(isLiked: likedItems.contains(key))
    }
    
    func viewStateForGame(id: String) -> LikeState {
        let key = makeKey(type: .game, id: id)
        return LikeState(isLiked: likedItems.contains(key))
    }
    
    func viewStateForMedia(type: MediaType, id: String) -> LikeState {
        let key = makeKey(type: type, id: id)
        return LikeState(isLiked: likedItems.contains(key))
    }

    // MARK: - Mutation APIs

    func toggleLikeForArticle(articleID: String) {
        toggleLike(type: .article, id: articleID)
    }
    
    func toggleLikeForGame(gameID: String) {
        toggleLike(type: .game, id: gameID)
    }
    
    func toggleLike(type: MediaType, id: String) {
        let key = makeKey(type: type, id: id)
        
        if likedItems.contains(key) {
            // Unlike
            likedItems.remove(key)
        } else {
            // Like
            likedItems.insert(key)
        }
        
        pendingLikes[key] = (date: Date(), type: type)
        persistToDisk()
    }

    // MARK: - Flush Integration

    struct PendingLikePayload: Codable {
        let mediaType: MediaType
        let mediaID: String
        let isLiked: Bool
        let updatedAt: Date
    }

    func prepareFlushPayload() -> [PendingLikePayload] {
        return pendingLikes.map { key, value in
            // Extract the ID from the key (format: "type:id")
            let components = key.split(separator: ":")
            let id = components.count > 1 ? String(components[1]) : key
            
            return PendingLikePayload(
                mediaType: value.type,
                mediaID: id,
                isLiked: likedItems.contains(key),
                updatedAt: value.date
            )
        }
    }

    func markBatchAsSynced(_ payloads: [PendingLikePayload]) {
        for payload in payloads {
            let key = makeKey(type: payload.mediaType, id: payload.mediaID)
            pendingLikes.removeValue(forKey: key)
        }
        persistToDisk()
    }

    func flushPendingLikes(for userID: String) {
        let batch = prepareFlushPayload()
        guard !batch.isEmpty else { return }

        // Path: artifacts/{appId}/public/data/likes
        let likesRef = db.child("artifacts").child(appId).child("public").child("data").child("likes")
        
        var updates: [AnyHashable: Any] = [:]
        
        print("📤 Flushing \(batch.count) pending likes for user \(userID)")
        
        for payload in batch {
            let path = "\(payload.mediaID)/\(userID)"
            
            if payload.isLiked {
                // Write like metadata
                let data: [String: Any] = [
                    "type": payload.mediaType.rawValue,
                    "timestamp": ServerValue.timestamp()
                ]
                updates[path] = data
                print("  - Liked: \(path)")
            } else {
                // Delete the node (unlike)
                updates[path] = NSNull()
                print("  - Unliked: \(path)")
            }
        }
        
        // Perform atomic batch update
        likesRef.updateChildValues(updates) { [weak self] error, _ in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error flushing likes: \(error.localizedDescription)")
            } else {
                print("✅ Successfully synced \(batch.count) likes")
                Task { @MainActor in
                    self.markBatchAsSynced(batch)
                }
            }
        }
    }

    // MARK: - Persistence

    private struct PendingLikeRecord: Codable {
        let key: String
        let date: Date
        let type: MediaType
    }

    private func persistToDisk() {
        // Save liked items set
        let likedArray = Array(likedItems)
        if let encoded = try? JSONEncoder().encode(likedArray) {
            UserDefaults.standard.set(encoded, forKey: likedStorageKey)
        }
        
        // Save pending likes dictionary
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let records = pendingLikes.map { key, value in
            PendingLikeRecord(key: key, date: value.date, type: value.type)
        }
        
        if let encoded = try? encoder.encode(records) {
            UserDefaults.standard.set(encoded, forKey: pendingStorageKey)
        }
    }

    private func restoreFromDisk() {
        // Restore liked items
        if let data = UserDefaults.standard.data(forKey: likedStorageKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            likedItems = Set(decoded)
        }
        
        // Restore pending likes
        if let data = UserDefaults.standard.data(forKey: pendingStorageKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([PendingLikeRecord].self, from: data) {
                var tmp: [String: (date: Date, type: MediaType)] = [:]
                for record in decoded {
                    tmp[record.key] = (date: record.date, type: record.type)
                }
                pendingLikes = tmp
            }
        }
    }
}
