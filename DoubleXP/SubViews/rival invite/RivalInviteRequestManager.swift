//
//  RivalInviteRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import FirebaseAuth
import FirebaseDatabase

// MARK: - Rival Invite Request Manager

@MainActor
class RivalInviteRequestManager {
    static let shared = RivalInviteRequestManager()
    
    private let baseURL = "https://us-central1-gameterminal-767f7.cloudfunctions.net/rivals/v1"
    private let dbRef = Database.database().reference()
    
    private init() {}
    
    // MARK: - Send Rival Invite
    
    /// Sends a rival invite to another user
    /// - Parameters:
    ///   - recipient: The user to invite
    ///   - game: The game to play
    ///   - mode: Challenge or Team Up
    ///   - platform: Platform to play on
    ///   - timing: When to play
    ///   - customMessage: Optional custom message
    /// - Returns: Response with invite ID or error
    func sendRivalInvite(
        to recipient: RivalRecipient,
        game: RivalGame,
        mode: RivalInviteMode,
        platform: RivalPlatform,
        timing: RivalTiming,
        customMessage: String? = nil
    ) async throws -> RivalInviteResponseV2 {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw RivalInviteError.notAuthenticated
        }
        
        // Create the request payload
        let request = RivalInviteRequest(
            senderId: currentUserId,
            recipientId: recipient.id,
            game: game,
            mode: mode,
            platform: platform,
            timing: timing,
            customMessage: customMessage
        )
        
        #if DEBUG
        print("📤 [RivalInvite] Sending invite to \(recipient.gamerTag)")
        print("   Game: \(game.name) (\(game.id))")
        print("   Mode: \(mode.rawValue)")
        print("   Platform: \(platform.rawValue)")
        print("   Timing: \(timing.rawValue)")
        #endif
        
        // TODO: Replace with actual API call when backend is ready
        // For now, we'll write directly to Firebase as a placeholder
        
        return try await sendViaFirebase(request: request, recipient: recipient)
        
        // Uncomment when API is ready:
        // return try await sendViaAPI(request: request)
    }
    
    // MARK: - Firebase Implementation (Placeholder)
    
    private func sendViaFirebase(request: RivalInviteRequest, recipient: RivalRecipient) async throws -> RivalInviteResponseV2 {
        
        let inviteId = UUID().uuidString
        
        let inviteData: [String: Any] = [
            "id": inviteId,
            "senderId": request.senderId,
            "senderGamerTag": UserProvider.shared.currentUser?.gamerTag ?? "Unknown",
            "recipientId": request.recipientId,
            "recipientGamerTag": recipient.gamerTag,
            "gameSlug": request.gameSlug,
            "gameName": request.gameName,
            "mode": request.mode,
            "platform": request.platform,
            "timing": request.timing,
            "customMessage": request.customMessage ?? "",
            "status": RivalInviteStatus.pending.rawValue,
            "sentAt": ServerValue.timestamp(),
            "timestamp": request.timestamp
        ]
        
        // Write to sender's sent invites
        let senderRef = dbRef.child("Users").child(request.senderId).child("sentRivalInvites").child(inviteId)
        
        // Write to recipient's pending invites
        let recipientRef = dbRef.child("Users").child(request.recipientId).child("pendingRivalInvites").child(inviteId)
        
        do {
            // Write to both locations
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let updates: [String: Any] = [
                    "Users/\(request.senderId)/sentRivalInvites/\(inviteId)": inviteData,
                    "Users/\(request.recipientId)/pendingRivalInvites/\(inviteId)": inviteData
                ]
                
                dbRef.updateChildValues(updates) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            
            #if DEBUG
            print("✅ [RivalInvite] Invite sent successfully: \(inviteId)")
            #endif
            
            // TODO: Trigger push notification via Cloud Function
            // This would be handled by a Firebase Cloud Function that listens
            // to writes on pendingRivalInvites
            
            return RivalInviteResponseV2(
                success: true,
                inviteId: inviteId,
                message: "Invite sent successfully",
                error: nil
            )
            
        } catch {
            #if DEBUG
            print("❌ [RivalInvite] Failed to send invite: \(error)")
            #endif
            throw RivalInviteError.sendFailed(error.localizedDescription)
        }
    }
    
    // MARK: - API Implementation (For Future Use)
    
    private func sendViaAPI(request: RivalInviteRequest) async throws -> RivalInviteResponse {
        
        guard let url = URL(string: "\(baseURL)/send-invite") else {
            throw RivalInviteError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode request body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RivalInviteError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RivalInviteError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(RivalInviteResponse.self, from: data)
    }
    
    // MARK: - Cancel Invite
    
    func cancelInvite(inviteId: String, recipientId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw RivalInviteError.notAuthenticated
        }
        
        let updates: [String: Any] = [
            "Users/\(currentUserId)/sentRivalInvites/\(inviteId)/status": RivalInviteStatus.cancelled.rawValue,
            "Users/\(recipientId)/pendingRivalInvites/\(inviteId)/status": RivalInviteStatus.cancelled.rawValue
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            dbRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        #if DEBUG
        print("🚫 [RivalInvite] Invite cancelled: \(inviteId)")
        #endif
    }
    
    // MARK: - Respond to Invite
    
    func respondToInvite(inviteId: String, senderId: String, accept: Bool) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw RivalInviteError.notAuthenticated
        }
        
        let newStatus = accept ? RivalInviteStatus.accepted : RivalInviteStatus.declined
        
        let updates: [String: Any] = [
            "Users/\(senderId)/sentRivalInvites/\(inviteId)/status": newStatus.rawValue,
            "Users/\(senderId)/sentRivalInvites/\(inviteId)/respondedAt": ServerValue.timestamp(),
            "Users/\(currentUserId)/pendingRivalInvites/\(inviteId)/status": newStatus.rawValue,
            "Users/\(currentUserId)/pendingRivalInvites/\(inviteId)/respondedAt": ServerValue.timestamp()
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            dbRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        #if DEBUG
        print("\(accept ? "✅" : "❌") [RivalInvite] Invite \(accept ? "accepted" : "declined"): \(inviteId)")
        #endif
    }
    
    // MARK: - Fetch Friends for Selection
    
    func fetchFriendsForInvite() async throws -> [RivalRecipient] {
        guard let currentUser = UserProvider.shared.currentUser else {
            throw RivalInviteError.notAuthenticated
        }
        
        // Convert friends to RivalRecipient format
        let recipients = currentUser.friends.map { friend in
            RivalRecipient(
                id: friend.uid,
                gamerTag: friend.gamerTag,
                avatarUrl: nil, // TODO: Fetch avatar URLs
                isOnline: false, // TODO: Check online status
                onlineStatus: nil
            )
        }
        
        return recipients
    }
    
    // MARK: - Fetch User's Games
    
    func fetchUserGames() async throws -> [RivalGame] {
        guard let currentUser = UserProvider.shared.currentUser else {
            throw RivalInviteError.notAuthenticated
        }
        
        // Get games from user's profile and GameStorageManager
        var rivalGames: [RivalGame] = []
        
        for slug in currentUser.games {
            if let game = GameStorageManager.shared.getGame(slug: slug) {
                rivalGames.append(RivalGame(
                    id: game.id,
                    name: game.gameName,
                    imageUrl: game.imageUrl,
                    genre: game.genresString,
                    supportedModes: nil
                ))
            }
        }
        
        return rivalGames
    }
}

// MARK: - Errors

enum RivalInviteError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case sendFailed(String)
    case noRecipientSelected
    case noGameSelected
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to send invites"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .sendFailed(let message):
            return "Failed to send invite: \(message)"
        case .noRecipientSelected:
            return "Please select a friend to invite"
        case .noGameSelected:
            return "Please select a game"
        }
    }
}

// MARK: - Mock Data

extension RivalRecipient {
    static let mockFriends: [RivalRecipient] = [
        RivalRecipient(id: "user1", gamerTag: "ShadowBlade99", avatarUrl: nil, isOnline: true, onlineStatus: "online"),
        RivalRecipient(id: "user2", gamerTag: "NightHawk", avatarUrl: nil, isOnline: true, onlineStatus: "in_game"),
        RivalRecipient(id: "user3", gamerTag: "PhoenixRider", avatarUrl: nil, isOnline: false, onlineStatus: nil),
        RivalRecipient(id: "user4", gamerTag: "CyberWolf", avatarUrl: nil, isOnline: true, onlineStatus: "online"),
        RivalRecipient(id: "user5", gamerTag: "StormBreaker", avatarUrl: nil, isOnline: false, onlineStatus: nil),
    ]
}

extension RivalGame {
    static let mockGames: [RivalGame] = [
        RivalGame(id: "street-fighter-6", name: "Street Fighter 6", imageUrl: nil, genre: "Fighting", supportedModes: ["1v1"]),
        RivalGame(id: "call-of-duty-warzone", name: "Call of Duty: Warzone", imageUrl: nil, genre: "Battle Royale", supportedModes: ["multiplayer", "co-op"]),
        RivalGame(id: "it-takes-two", name: "It Takes Two", imageUrl: nil, genre: "Co-op Adventure", supportedModes: ["co-op"]),
        RivalGame(id: "rocket-league", name: "Rocket League", imageUrl: nil, genre: "Sports", supportedModes: ["1v1", "multiplayer"]),
        RivalGame(id: "fortnite", name: "Fortnite", imageUrl: nil, genre: "Battle Royale", supportedModes: ["multiplayer", "co-op"]),
    ]
}
