//
//  FollowInteractionManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import FirebaseDatabase

enum FollowInteractionError: Error {
    case userNotLoaded
    case missingSlug
}

final class FollowInteractionManager {
    static let shared = FollowInteractionManager()
    private init() {}
    
    // MARK: - Helpers
    
    /// Returns true if the current user follows this slug.
    @MainActor func isGameFollowed(slug: String) -> Bool {
        guard let user = UserProvider.shared.getUser() else { return false }
        return user.games.contains { $0.caseInsensitiveCompare(slug) == .orderedSame }
    }
    
    // MARK: - Public API
    
    /// Toggle follow/unfollow for a game.
    /// Returns the new follow state (true = now following).
    func toggleGameFollow(game: GamerConnectGame) async throws -> Bool {
        guard let user = await UserProvider.shared.getUser() else {
            throw FollowInteractionError.userNotLoaded
        }
        
        let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug.isEmpty else {
            throw FollowInteractionError.missingSlug
        }
        
        var followed = user.games
        let isCurrentlyFollowing = followed.contains { $0.caseInsensitiveCompare(slug) == .orderedSame }
        let shouldFollow = !isCurrentlyFollowing
        
        if shouldFollow {
            if !isCurrentlyFollowing {
                followed.append(slug)
            }
        } else {
            followed.removeAll { $0.caseInsensitiveCompare(slug) == .orderedSame }
        }
        
        // Firebase path: Users/<uid>/games (array of slugs)
        let ref = Database.database().reference()
            .child("Users")
            .child(user.uId)
            .child("games")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setValue(followed) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Update in-memory user model
        user.games = followed
        
        // Local cache: make sure we can look this game up later even offline
        GameStorageManager.shared.save(game: game)
        
        return shouldFollow
    }
}
