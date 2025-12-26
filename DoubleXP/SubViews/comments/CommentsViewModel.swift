//
//  CommentsViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import FirebaseDatabase // CHANGED: Realtime Database
import FirebaseAuth
import Combine
import CoreLocation

enum CommentMediaType: String, Codable {
    case article
    case short
    case video
}

struct CommentModel: Identifiable, Codable {
    var id: String? // CHANGED: Regular string, assigned manually from snapshot.key
    let mediaId: String
    let mediaType: String
    let userId: String
    let userName: String
    let userAvatar: String
    let text: String
    let timestamp: TimeInterval // CHANGED: RTDB handles TimeIntervals/Numbers easier than Dates in queries usually, but Codable works with Date too. We'll use Date for simplicity.
    let parentId: String?
    var likeCount: Int
    
    // New Social Context Fields
    let userGames: [String]?
    let userAboutMe: [String]?
    let userLookingFor: [String]?
    
    // Location Data
    let userLatitude: Double?
    let userLongitude: Double?
    
    // Local-only
    var isLikedByMe: Bool = false
    var replies: [CommentModel] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case mediaId
        case mediaType
        case userId
        case userName
        case userAvatar
        case text
        case timestamp
        case parentId
        case likeCount
        case userGames
        case userAboutMe
        case userLookingFor
        case userLatitude
        case userLongitude
    }
}

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentModel] = []
    @Published var isLoading = true
    
    private let mediaId: String
    private let mediaType: MediaType
    let authorId: String? // The Author of the article/video/post
    
    // MOCK: This should match the authenticated user's ID
    let currentUserId = "user_123"
    
    private var dbHandle: DatabaseHandle?
    private let reactions = ReactionsManager.shared
    private var rawComments: [CommentModel] = []
    
    init(mediaId: String, mediaType: MediaType, authorId: String?) {
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.authorId = authorId
        subscribeToComments()
    }
    
    deinit {
        if let handle = dbHandle {
            CommentsManager.shared.removeListener(handle: handle)
        }
    }
    
    func subscribeToComments() {
        isLoading = true
        dbHandle = CommentsManager.shared.listenToComments(for: mediaId) { [weak self] fetchedComments in
            guard let self = self else { return }
            self.rawComments = fetchedComments
            self.rebuildCommentTree()
            self.isLoading = false
        }
    }
    
    private func rebuildCommentTree() {
        var topLevel: [CommentModel] = []
        var replyMap: [String: [CommentModel]] = [:]
        
        for var comment in rawComments {
            if let id = comment.id {
                comment.isLikedByMe = reactions.viewStateForMedia(type: .comment, id: id).isLiked
            }
            
            if let parentId = comment.parentId {
                replyMap[parentId, default: []].append(comment)
            } else {
                topLevel.append(comment)
            }
        }
        
        for i in 0..<topLevel.count {
            let parentId = topLevel[i].id ?? ""
            if let replies = replyMap[parentId] {
                topLevel[i].replies = replies
            }
        }
        
        self.comments = topLevel
    }
    
    func sendComment(text: String, replyingTo parent: CommentModel? = nil) {
        Task {
            do {
                try await CommentsManager.shared.postComment(
                    mediaId: mediaId,
                    mediaType: mediaType,
                    text: text,
                    parentId: parent?.id
                )
            } catch {
                print("Failed to send comment: \(error)")
            }
        }
    }
    
    func toggleLike(for comment: CommentModel) {
        guard let id = comment.id else { return }
        
        reactions.toggleLike(type: .comment, id: id)
        let isNowLiked = reactions.viewStateForMedia(type: .comment, id: id).isLiked
        
        if let index = rawComments.firstIndex(where: { $0.id == id }) {
            rawComments[index].isLikedByMe = isNowLiked
            rawComments[index].likeCount += (isNowLiked ? 1 : -1)
            rebuildCommentTree()
        }
        
        Task {
            await CommentsManager.shared.updateLikeCount(commentId: id, increment: isNowLiked)
        }
    }
}
