//
//  ChatModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI

struct ChatChannel: Codable, Identifiable, Hashable {
    let id: String
    let participants: [String]  // User UIDs (2 for DM, 3-8 for group)
    let createdAt: Date
    var lastMessage: ChatMessage?
    var lastMessageAt: Date?
    var unreadCount: Int
    
    // Group chat properties (nil for DMs)
    var isGroupChat: Bool
    var groupName: String?
    var groupImageUrl: String?
    var groupCreatorId: String?
    var groupAdmins: [String]
    
    // Constants
    static let maxGroupParticipants = 8
    static let defaultMaxParticipants = 4
    
    // Computed property to get the other participant's UID (for DMs)
    func otherParticipant(currentUserId: String) -> String? {
        guard !isGroupChat else { return nil }
        return participants.first { $0 != currentUserId }
    }
    
    // Get all other participants (for group chats)
    func otherParticipants(currentUserId: String) -> [String] {
        participants.filter { $0 != currentUserId }
    }
    
    // Check if user is admin
    func isAdmin(_ userId: String) -> Bool {
        groupAdmins.contains(userId) || groupCreatorId == userId
    }
    
    // Check if user is creator
    func isCreator(_ userId: String) -> Bool {
        groupCreatorId == userId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatChannel, rhs: ChatChannel) -> Bool {
        lhs.id == rhs.id
    }
    
    // Default initializer for DMs (backward compatible)
    init(id: String, participants: [String], createdAt: Date, lastMessage: ChatMessage? = nil, lastMessageAt: Date? = nil, unreadCount: Int = 0) {
        self.id = id
        self.participants = participants
        self.createdAt = createdAt
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.isGroupChat = false
        self.groupName = nil
        self.groupImageUrl = nil
        self.groupCreatorId = nil
        self.groupAdmins = []
    }
    
    // Full initializer with group support
    init(id: String, participants: [String], createdAt: Date, lastMessage: ChatMessage? = nil, lastMessageAt: Date? = nil, unreadCount: Int = 0, isGroupChat: Bool, groupName: String? = nil, groupImageUrl: String? = nil, groupCreatorId: String? = nil, groupAdmins: [String] = []) {
        self.id = id
        self.participants = participants
        self.createdAt = createdAt
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.isGroupChat = isGroupChat
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
        self.groupCreatorId = groupCreatorId
        self.groupAdmins = groupAdmins
    }
}

// MARK: - Chat Message Model (Extended with sender info for groups)

struct ChatMessage: Codable, Identifiable, Hashable {
    let id: String
    let channelId: String
    let senderId: String
    var senderName: String?  // Cached for group chat display
    let type: MessageType
    let content: MessageContent
    let timestamp: Date
    var isRead: Bool
    var status: MessageStatus
    
    enum MessageType: String, Codable {
        case text
        case image
        case gif
        case rivalInvite
        case system
        // Group-specific system messages
        case memberJoined
        case memberLeft
        case groupCreated
        case groupRenamed
    }
    
    enum MessageStatus: String, Codable {
        case sending
        case sent
        case delivered
        case read
        case failed
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    // Backward compatible initializer
    init(id: String, channelId: String, senderId: String, type: MessageType, content: MessageContent, timestamp: Date, isRead: Bool, status: MessageStatus) {
        self.id = id
        self.channelId = channelId
        self.senderId = senderId
        self.senderName = nil
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
    }
    
    // Extended initializer with sender name
    init(id: String, channelId: String, senderId: String, senderName: String?, type: MessageType, content: MessageContent, timestamp: Date, isRead: Bool, status: MessageStatus) {
        self.id = id
        self.channelId = channelId
        self.senderId = senderId
        self.senderName = senderName
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
    }
}

// MARK: - Message Content

enum MessageContent: Codable, Hashable {
    case text(String)
    case image(ImageMessageData)
    case gif(GifMessageData)
    case rivalInvite(RivalObj)
    case system(String)
    
    // Custom coding for enum with associated values
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .data)
            self = .text(text)
        case "image":
            let data = try container.decode(ImageMessageData.self, forKey: .data)
            self = .image(data)
        case "gif":
            let data = try container.decode(GifMessageData.self, forKey: .data)
            self = .gif(data)
        case "rivalInvite":
            let data = try container.decode(RivalObj.self, forKey: .data)
            self = .rivalInvite(data)
        case "system":
            let text = try container.decode(String.self, forKey: .data)
            self = .system(text)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown message type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .data)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
        case .gif(let data):
            try container.encode("gif", forKey: .type)
            try container.encode(data, forKey: .data)
        case .rivalInvite(let rival):
            try container.encode("rivalInvite", forKey: .type)
            try container.encode(rival, forKey: .data)
        case .system(let text):
            try container.encode("system", forKey: .type)
            try container.encode(text, forKey: .data)
        }
    }
    
    // Text preview for message list
    var textPreview: String {
        switch self {
        case .text(let text): return text
        case .image: return "📷 Photo"
        case .gif: return "GIF"
        case .rivalInvite: return "⚔️ Rival Invite"
        case .system(let text): return text
        }
    }
}

// MARK: - Image Message Data

struct ImageMessageData: Codable, Hashable {
    let imageUrl: String
    let thumbnailUrl: String?
    let width: Int?
    let height: Int?
    let fileSize: Int?
}

// MARK: - GIF Message Data

struct GifMessageData: Codable, Hashable {
    let gifUrl: String
    let previewUrl: String?
    let width: Int?
    let height: Int?
    let source: String?  // e.g., "giphy", "tenor"
}

// MARK: - Chat Friend Model (for display)

struct ChatFriend: Identifiable, Hashable {
    let id: String  // User UID
    let gamerTag: String
    let profileImageUrl: String?
    let pokoId: String?
    var onlineStatus: OnlineStatus
    var currentGame: String?  // Game they're currently playing
    var channelId: String?  // Existing chat channel if any
    var lastMessage: String?
    var lastMessageTime: Date?
    var unreadCount: Int
    
    enum OnlineStatus: String, Codable {
        case online
        case inGame
        case away
        case offline
        
        var displayText: String {
            switch self {
            case .online: return "Online"
            case .inGame: return "In Game"
            case .away: return "Away"
            case .offline: return "Offline"
            }
        }
        
        var isActive: Bool {
            self == .online || self == .inGame
        }
        
        var statusColor: Color {
            switch self {
            case .online: return Color(hex: "4CAF50")
            case .inGame: return Color(hex: "2196F3")
            case .away: return Color(hex: "FFC107")
            case .offline: return Color(hex: "9E9E9E")
            }
        }
    }
    
    // Bubble gradient for group chats (based on user ID hash)
    var bubbleGradient: [Color] {
        let gradients: [[Color]] = [
            [Color(hex: "667eea"), Color(hex: "764ba2")], // Purple
            [Color(hex: "f093fb"), Color(hex: "f5576c")], // Pink
            [Color(hex: "4facfe"), Color(hex: "00f2fe")], // Blue
            [Color(hex: "43e97b"), Color(hex: "38f9d7")], // Green
            [Color(hex: "fa709a"), Color(hex: "fee140")], // Orange
            [Color(hex: "a8edea"), Color(hex: "fed6e3")], // Teal/Pink
            [Color(hex: "ff9a9e"), Color(hex: "fecfef")], // Red/Pink
            [Color(hex: "ffecd2"), Color(hex: "fcb69f")]  // Peach
        ]
        let index = abs(id.hashValue) % gradients.count
        return gradients[index]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatFriend, rhs: ChatFriend) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Conversation Display Model (Extended for Group Chats)

struct ConversationDisplay: Identifiable, Hashable {
    let id: String  // Channel ID
    
    // For DMs - single friend
    let friend: ChatFriend?
    
    // For Group Chats
    let isGroupChat: Bool
    let groupName: String?
    let groupImageUrl: String?
    let participants: [ChatFriend]  // All members for group chats
    
    // Common properties
    let lastMessage: String?
    let lastMessageTime: Date?
    let lastMessageSenderId: String?
    let lastMessageSenderName: String?
    let unreadCount: Int
    let lastMessageType: ChatMessage.MessageType?
    
    // DM initializer (backward compatible)
    init(id: String, friend: ChatFriend, lastMessage: String?, lastMessageTime: Date?, unreadCount: Int, lastMessageType: ChatMessage.MessageType?) {
        self.id = id
        self.friend = friend
        self.isGroupChat = false
        self.groupName = nil
        self.groupImageUrl = nil
        self.participants = [friend]
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.lastMessageSenderId = nil
        self.lastMessageSenderName = nil
        self.unreadCount = unreadCount
        self.lastMessageType = lastMessageType
    }
    
    // Group chat initializer
    init(id: String, groupName: String, groupImageUrl: String?, participants: [ChatFriend], lastMessage: String?, lastMessageTime: Date?, lastMessageSenderId: String?, lastMessageSenderName: String?, unreadCount: Int, lastMessageType: ChatMessage.MessageType?) {
        self.id = id
        self.friend = nil
        self.isGroupChat = true
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.lastMessageSenderId = lastMessageSenderId
        self.lastMessageSenderName = lastMessageSenderName
        self.unreadCount = unreadCount
        self.lastMessageType = lastMessageType
    }
    
    // Display name (works for both DM and group)
    var displayName: String {
        if isGroupChat {
            return groupName ?? "Group Chat"
        }
        return friend?.gamerTag ?? "Unknown"
    }
    
    // Online count for groups
    var onlineParticipantCount: Int {
        participants.filter { $0.onlineStatus.isActive }.count
    }
    
    // Member count for groups
    var memberCount: Int {
        participants.count
    }
    
    var timeDisplayText: String {
        guard let time = lastMessageTime else { return "" }
        
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(time) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        } else if calendar.isDateInYesterday(time) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: time, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: time)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: time)
        }
    }
    
    var previewText: String {
        guard let message = lastMessage else { return "No messages yet" }
        
        // For group chats, prepend sender name
        var prefix = ""
        if isGroupChat, let senderName = lastMessageSenderName {
            prefix = "\(senderName): "
        }
        
        switch lastMessageType {
        case .rivalInvite:
            return "\(prefix)⚔️ Rival Invite"
        case .image:
            return "\(prefix)📷 Photo"
        case .gif:
            return "\(prefix)GIF"
        case .memberJoined, .memberLeft, .groupCreated, .groupRenamed:
            return message // System messages don't need prefix
        default:
            return "\(prefix)\(message)"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConversationDisplay, rhs: ConversationDisplay) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Typing Indicator (Extended for groups)

struct TypingIndicator: Codable {
    let channelId: String
    let userId: String
    let userName: String?  // For group display
    let isTyping: Bool
    let timestamp: Date
    
    init(channelId: String, userId: String, userName: String? = nil, isTyping: Bool, timestamp: Date) {
        self.channelId = channelId
        self.userId = userId
        self.userName = userName
        self.isTyping = isTyping
        self.timestamp = timestamp
    }
}

// MARK: - Chat Error (Extended)

enum ChatError: LocalizedError {
    case notAuthenticated
    case channelNotFound
    case messageSendFailed
    case imageUploadFailed
    case networkError(Error)
    case decodingError(Error)
    case groupTooLarge
    case notGroupAdmin
    case cannotRemoveCreator
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to use chat"
        case .channelNotFound:
            return "Chat channel not found"
        case .messageSendFailed:
            return "Failed to send message"
        case .imageUploadFailed:
            return "Failed to upload image"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .groupTooLarge:
            return "Group cannot have more than \(ChatChannel.maxGroupParticipants) members"
        case .notGroupAdmin:
            return "Only group admins can perform this action"
        case .cannotRemoveCreator:
            return "Cannot remove the group creator"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Send Message Request

struct SendMessageRequest {
    let channelId: String
    let content: MessageContent
    let replyToMessageId: String?
    
    init(channelId: String, content: MessageContent, replyToMessageId: String? = nil) {
        self.channelId = channelId
        self.content = content
        self.replyToMessageId = replyToMessageId
    }
}

struct CreateGroupRequest {
    let name: String
    let participantIds: [String]  // Not including creator
    let imageUrl: String?
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        participantIds.count >= 1 &&
        participantIds.count <= ChatChannel.maxGroupParticipants - 1
    }
}

// MARK: - Rival Invite Response

enum RivalInviteResponse: String, Codable {
    case accept
    case decline
}
