//
//  ChatRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Combine
import UIKit

/// ChatRequestManager handles all chat-related data fetching and messaging
/// This includes Firebase queries for friends, channels, online status,
/// and real-time messaging over Realtime Database
@MainActor
class ChatRequestManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ChatRequestManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var friends: [ChatFriend] = []
    @Published private(set) var onlineFriends: [ChatFriend] = []
    @Published private(set) var conversations: [ConversationDisplay] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: ChatError?
    
    // MARK: - Private Properties
    
    private let db = Database.database().reference()
    private let storage = Storage.storage().reference()
    
    // Realtime Database listener handles / refs
    private var friendsListener: DatabaseHandle?
    private var friendsRef: DatabaseReference?
    
    private var onlineStatusListener: DatabaseHandle?
    private var onlineStatusRef: DatabaseReference?
    
    private var conversationsListener: DatabaseHandle?
    private var conversationsRef: DatabaseReference?
    
    private var messageListeners: [String: DatabaseHandle] = [:]
    private var messageListenerRefs: [String: DatabaseReference] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Callbacks for Real-time Updates
    
    var onNewMessage: ((ChatMessage) -> Void)?
    var onMessageStatusUpdate: ((String, ChatMessage.MessageStatus) -> Void)?
    var onTypingIndicator: ((String, String?, Bool) -> Void)?
    var onRivalInviteReceived: ((RivalObj) -> Void)?
    var onOnlineStatusChange: ((String, ChatFriend.OnlineStatus) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    await self?.loadInitialData()
                } else {
                    self?.clearData()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() async {
        guard let userId = getCurrentUserId() else {
            error = .notAuthenticated
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await loadFriends(userId: userId)
            try await loadConversations(userId: userId)
            setupOnlineStatusListener(userId: userId)
            setupConversationsListener(userId: userId)
        } catch let err as ChatError {
            error = err
        } catch {
            self.error = .networkError(error)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadInitialData()
    }
    
    // MARK: - Friends Loading
    
    private func loadFriends(userId: String) async throws {
        print("💬 [ChatManager] Loading friends for user: \(userId)")
        
        let friendsRef = db.child("Users").child(userId).child("friends")
        let friendsSnapshot = try await friendsRef.getData()
        
        guard let friendsValue = friendsSnapshot.value as? [String: Any] else {
            self.friends = []
            self.onlineFriends = []
            return
        }
        
        var loadedFriends: [ChatFriend] = []
        
        for (friendId, value) in friendsValue {
            let data = value as? [String: Any] ?? [:]
            
            if let friendData = try? await fetchUserData(userId: friendId) {
                let friend = ChatFriend(
                    id: friendId,
                    gamerTag: friendData["gamerTag"] as? String ?? "Unknown",
                    profileImageUrl: friendData["profileImageUrl"] as? String,
                    pokoId: friendData["pokoId"] as? String,
                    onlineStatus: parseOnlineStatus(from: friendData),
                    currentGame: friendData["currentGame"] as? String,
                    channelId: data["channelId"] as? String,
                    lastMessage: nil,
                    lastMessageTime: nil,
                    unreadCount: 0
                )
                loadedFriends.append(friend)
            }
        }
        
        self.friends = loadedFriends
        self.onlineFriends = loadedFriends.filter { $0.onlineStatus.isActive }
    }
    
    private func fetchUserData(userId: String) async throws -> [String: Any] {
        let snap = try await db.child("Users").child(userId).getData()
        return snap.value as? [String: Any] ?? [:]
    }
    
    private func parseOnlineStatus(from data: [String: Any]) -> ChatFriend.OnlineStatus {
        if let statusString = data["onlineStatus"] as? String,
           let status = ChatFriend.OnlineStatus(rawValue: statusString) {
            return status
        }
        
        if let lastActiveDate = dateFromTimestampField(data["lastActiveAt"]) {
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            return lastActiveDate > fiveMinutesAgo ? .online : .offline
        }
        
        return .offline
    }
    
    // MARK: - Conversations Loading (DMs + Groups)
    
    private func loadConversations(userId: String) async throws {
        let channelsSnapshot = try await db.child("ChatChannels").getData()
        
        guard let channelsValue = channelsSnapshot.value as? [String: Any] else {
            self.conversations = []
            return
        }
        
        var loadedConversations: [ConversationDisplay] = []
        
        for (channelId, value) in channelsValue {
            guard let data = value as? [String: Any] else { continue }
            
            var participants: [String] = []
            if let arr = data["participants"] as? [String] {
                participants = arr
            } else if let dict = data["participants"] as? [String: Any] {
                let sortedKeys = dict.keys.sorted()
                participants = sortedKeys.compactMap { dict[$0] as? String }
            }
            
            guard participants.contains(userId) else { continue }
            
            let isGroupChat = data["isGroupChat"] as? Bool ?? (participants.count > 2)
            
            let lastMessage = data["lastMessage"] as? String
            let lastMessageTime = dateFromTimestampField(data["lastMessageAt"])
            let unreadCount = data["unreadCount_\(userId)"] as? Int ?? 0
            let lastMessageTypeRaw = data["lastMessageType"] as? String
            let lastMessageType = lastMessageTypeRaw.flatMap { ChatMessage.MessageType(rawValue: $0) }
            let lastMessageSenderId = data["lastMessageSenderId"] as? String
            let lastMessageSenderName = data["lastMessageSenderName"] as? String
            
            if isGroupChat {
                let groupName = data["groupName"] as? String ?? "Group Chat"
                let groupImageUrl = data["groupImageUrl"] as? String
                
                var groupParticipants: [ChatFriend] = []
                for participantId in participants {
                    if let userData = try? await fetchUserData(userId: participantId) {
                        let participant = ChatFriend(
                            id: participantId,
                            gamerTag: userData["gamerTag"] as? String ?? "Unknown",
                            profileImageUrl: userData["profileImageUrl"] as? String,
                            pokoId: userData["pokoId"] as? String,
                            onlineStatus: parseOnlineStatus(from: userData),
                            currentGame: userData["currentGame"] as? String,
                            channelId: channelId,
                            lastMessage: nil,
                            lastMessageTime: nil,
                            unreadCount: 0
                        )
                        groupParticipants.append(participant)
                    }
                }
                
                let conversation = ConversationDisplay(
                    id: channelId,
                    groupName: groupName,
                    groupImageUrl: groupImageUrl,
                    participants: groupParticipants,
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime,
                    lastMessageSenderId: lastMessageSenderId,
                    lastMessageSenderName: lastMessageSenderName,
                    unreadCount: unreadCount,
                    lastMessageType: lastMessageType
                )
                
                loadedConversations.append(conversation)
            } else {
                guard let otherUserId = participants.first(where: { $0 != userId }) else { continue }
                
                var friend: ChatFriend
                if let existingFriend = friends.first(where: { $0.id == otherUserId }) {
                    friend = existingFriend
                    if friend.channelId == nil {
                        friend.channelId = channelId
                    }
                } else {
                    let userData = try await fetchUserData(userId: otherUserId)
                    friend = ChatFriend(
                        id: otherUserId,
                        gamerTag: userData["gamerTag"] as? String ?? "Unknown",
                        profileImageUrl: userData["profileImageUrl"] as? String,
                        pokoId: userData["pokoId"] as? String,
                        onlineStatus: parseOnlineStatus(from: userData),
                        currentGame: userData["currentGame"] as? String,
                        channelId: channelId,
                        lastMessage: nil,
                        lastMessageTime: nil,
                        unreadCount: 0
                    )
                }
                
                let conversation = ConversationDisplay(
                    id: channelId,
                    friend: friend,
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime,
                    unreadCount: unreadCount,
                    lastMessageType: lastMessageType
                )
                
                loadedConversations.append(conversation)
            }
        }
        
        loadedConversations.sort {
            ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast)
        }
        
        self.conversations = loadedConversations
    }
    
    // MARK: - Real-time Listeners
    
    private func setupOnlineStatusListener(userId: String) {
        if let ref = onlineStatusRef, let handle = onlineStatusListener {
            ref.removeObserver(withHandle: handle)
        }
        
        let friendIds = friends.map { $0.id }
        guard !friendIds.isEmpty else { return }
        
        let ref = db.child("Users")
        onlineStatusRef = ref
        
        onlineStatusListener = ref.observe(.value, with: { [weak self] snapshot in
            guard let self = self else { return }
            guard let usersValue = snapshot.value as? [String: Any] else { return }
            
            Task { @MainActor in
                for friendId in friendIds {
                    guard let friendData = usersValue[friendId] as? [String: Any] else { continue }
                    let status = self.parseOnlineStatus(from: friendData)
                    let currentGame = friendData["currentGame"] as? String
                    
                    if let index = self.friends.firstIndex(where: { $0.id == friendId }) {
                        self.friends[index].onlineStatus = status
                        self.friends[index].currentGame = currentGame
                    }
                    
                    self.onOnlineStatusChange?(friendId, status)
                }
                
                self.onlineFriends = self.friends.filter { $0.onlineStatus.isActive }
            }
        })
    }
    
    private func setupConversationsListener(userId: String) {
        if let ref = conversationsRef, let handle = conversationsListener {
            ref.removeObserver(withHandle: handle)
        }
        
        let ref = db.child("ChatChannels")
        conversationsRef = ref
        
        conversationsListener = ref.observe(.value, with: { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                do {
                    try await self.loadConversations(userId: userId)
                } catch {
                    print("💬 [ChatManager] Conversations listener error: \(error)")
                }
            }
        })
    }
    
    // MARK: - Channel Management (DMs)
    
    func getOrCreateChannel(with friendId: String) async throws -> String {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        if let existingChannel = conversations.first(where: { !$0.isGroupChat && $0.friend?.id == friendId }) {
            return existingChannel.id
        }
        
        let channelsSnapshot = try await db.child("ChatChannels").getData()
        if let channelsValue = channelsSnapshot.value as? [String: Any] {
            for (channelId, value) in channelsValue {
                guard let data = value as? [String: Any] else { continue }
                
                let isGroupChat = data["isGroupChat"] as? Bool ?? false
                if isGroupChat { continue }
                
                var participants: [String] = []
                if let arr = data["participants"] as? [String] {
                    participants = arr
                } else if let dict = data["participants"] as? [String: Any] {
                    let sortedKeys = dict.keys.sorted()
                    participants = sortedKeys.compactMap { dict[$0] as? String }
                }
                
                if participants.contains(userId) && participants.contains(friendId) && participants.count == 2 {
                    return channelId
                }
            }
        }
        
        let channelId = UUID().uuidString
        let channelRef = db.child("ChatChannels").child(channelId)
        
        let nowServerTimestamp = ServerValue.timestamp()
        
        var channelData: [String: Any] = [:]
        channelData["participants"] = [userId, friendId]
        channelData["createdAt"] = nowServerTimestamp
        channelData["lastMessageAt"] = nowServerTimestamp
        channelData["lastMessage"] = NSNull()
        channelData["lastMessageType"] = NSNull()
        channelData["isGroupChat"] = false
        channelData["unreadCount_\(userId)"] = 0
        channelData["unreadCount_\(friendId)"] = 0
        
        try await channelRef.setValue(channelData)
        
        let userFriendRef = db.child("Users").child(userId).child("friends").child(friendId)
        try await userFriendRef.updateChildValues(["channelId": channelId])
        
        let friendUserRef = db.child("Users").child(friendId).child("friends").child(userId)
        try await friendUserRef.updateChildValues(["channelId": channelId])
        
        try await loadConversations(userId: userId)
        
        return channelId
    }
    
    // MARK: - Group Chat Management
    
    func createGroupChat(request: CreateGroupRequest) async throws -> String {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        guard request.isValid else {
            throw ChatError.unknown("Invalid group request")
        }
        
        var allParticipants = [userId] + request.participantIds
        
        guard allParticipants.count <= ChatChannel.maxGroupParticipants else {
            throw ChatError.groupTooLarge
        }
        
        let channelId = UUID().uuidString
        let channelRef = db.child("ChatChannels").child(channelId)
        
        let nowServerTimestamp = ServerValue.timestamp()
        
        var channelData: [String: Any] = [:]
        channelData["participants"] = allParticipants
        channelData["createdAt"] = nowServerTimestamp
        channelData["lastMessageAt"] = nowServerTimestamp
        channelData["isGroupChat"] = true
        channelData["groupName"] = request.name
        channelData["groupImageUrl"] = request.imageUrl ?? NSNull()
        channelData["groupCreatorId"] = userId
        channelData["groupAdmins"] = [userId]
        channelData["lastMessage"] = "Group created"
        channelData["lastMessageType"] = ChatMessage.MessageType.groupCreated.rawValue
        
        for participantId in allParticipants {
            channelData["unreadCount_\(participantId)"] = participantId == userId ? 0 : 1
        }
        
        try await channelRef.setValue(channelData)
        
        let messageId = UUID().uuidString
        let messageRef = db.child("ChatChannels").child(channelId).child("messages").child(messageId)
        
        var messageData: [String: Any] = [:]
        messageData["channelId"] = channelId
        messageData["senderId"] = "system"
        messageData["type"] = ChatMessage.MessageType.groupCreated.rawValue
        messageData["text"] = "Group chat created"
        messageData["timestamp"] = nowServerTimestamp
        messageData["isRead"] = true
        messageData["status"] = ChatMessage.MessageStatus.delivered.rawValue
        
        try await messageRef.setValue(messageData)
        
        try await loadConversations(userId: userId)
        
        return channelId
    }
    
    func addGroupMember(channelId: String, memberId: String) async throws {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let channelRef = db.child("ChatChannels").child(channelId)
        let snapshot = try await channelRef.getData()
        
        guard let data = snapshot.value as? [String: Any],
              let isGroupChat = data["isGroupChat"] as? Bool, isGroupChat else {
            throw ChatError.channelNotFound
        }
        
        let groupAdmins = data["groupAdmins"] as? [String] ?? []
        let groupCreatorId = data["groupCreatorId"] as? String
        guard groupAdmins.contains(userId) || groupCreatorId == userId else {
            throw ChatError.notGroupAdmin
        }
        
        var participants = data["participants"] as? [String] ?? []
        
        guard !participants.contains(memberId) else {
            return
        }
        
        guard participants.count < ChatChannel.maxGroupParticipants else {
            throw ChatError.groupTooLarge
        }
        
        participants.append(memberId)
        
        var updates: [String: Any] = [:]
        updates["participants"] = participants
        updates["unreadCount_\(memberId)"] = 0
        
        try await channelRef.updateChildValues(updates)
        
        let memberData = try await fetchUserData(userId: memberId)
        let memberName = memberData["gamerTag"] as? String ?? "Someone"
        
        try await sendSystemMessage(
            channelId: channelId,
            type: .memberJoined,
            text: "\(memberName) joined the group"
        )
    }
    
    func removeGroupMember(channelId: String, memberId: String) async throws {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let channelRef = db.child("ChatChannels").child(channelId)
        let snapshot = try await channelRef.getData()
        
        guard let data = snapshot.value as? [String: Any],
              let isGroupChat = data["isGroupChat"] as? Bool, isGroupChat else {
            throw ChatError.channelNotFound
        }
        
        let groupCreatorId = data["groupCreatorId"] as? String
        let groupAdmins = data["groupAdmins"] as? [String] ?? []
        let isLeavingSelf = memberId == userId
        
        if !isLeavingSelf && !groupAdmins.contains(userId) && groupCreatorId != userId {
            throw ChatError.notGroupAdmin
        }
        
        if memberId == groupCreatorId && !isLeavingSelf {
            throw ChatError.cannotRemoveCreator
        }
        
        var participants = data["participants"] as? [String] ?? []
        var admins = groupAdmins
        
        participants.removeAll { $0 == memberId }
        admins.removeAll { $0 == memberId }
        
        var updates: [String: Any] = [:]
        updates["participants"] = participants
        updates["groupAdmins"] = admins
        
        try await channelRef.updateChildValues(updates)
        
        try await channelRef.child("unreadCount_\(memberId)").removeValue()
        
        let memberData = try await fetchUserData(userId: memberId)
        let memberName = memberData["gamerTag"] as? String ?? "Someone"
        let messageText = isLeavingSelf ? "\(memberName) left the group" : "\(memberName) was removed"
        
        try await sendSystemMessage(
            channelId: channelId,
            type: .memberLeft,
            text: messageText
        )
    }
    
    func updateGroupSettings(channelId: String, newName: String?, newImageUrl: String?) async throws {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let channelRef = db.child("ChatChannels").child(channelId)
        let snapshot = try await channelRef.getData()
        
        guard let data = snapshot.value as? [String: Any],
              let isGroupChat = data["isGroupChat"] as? Bool, isGroupChat else {
            throw ChatError.channelNotFound
        }
        
        let groupAdmins = data["groupAdmins"] as? [String] ?? []
        let groupCreatorId = data["groupCreatorId"] as? String
        guard groupAdmins.contains(userId) || groupCreatorId == userId else {
            throw ChatError.notGroupAdmin
        }
        
        var updates: [String: Any] = [:]
        
        if let name = newName, !name.isEmpty {
            updates["groupName"] = name
        }
        
        if let imageUrl = newImageUrl {
            updates["groupImageUrl"] = imageUrl
        }
        
        guard !updates.isEmpty else { return }
        
        try await channelRef.updateChildValues(updates)
        
        if let name = newName, !name.isEmpty {
            try await sendSystemMessage(
                channelId: channelId,
                type: .groupRenamed,
                text: "Group renamed to \"\(name)\""
            )
        }
    }
    
    // MARK: - Message Loading
    
    func loadMessages(channelId: String, limit: Int = 50) async throws -> [ChatMessage] {
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let query = messagesRef
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
        
        let messagesSnapshot = try await query.getData()
        
        guard let messagesValue = messagesSnapshot.value as? [String: Any] else {
            return []
        }
        
        var messages: [ChatMessage] = []
        
        for (messageId, value) in messagesValue {
            guard let data = value as? [String: Any] else { continue }
            if let message = try? parseMessage(id: messageId, data: data) {
                messages.append(message)
            }
        }
        
        messages.sort { $0.timestamp < $1.timestamp }
        return messages
    }
    
    func loadMoreMessages(channelId: String, before message: ChatMessage, limit: Int = 50) async throws -> [ChatMessage] {
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        
        let messageTime = message.timestamp.timeIntervalSince1970
        
        let query = messagesRef
            .queryOrdered(byChild: "timestamp")
            .queryEnding(atValue: messageTime - 0.001)
            .queryLimited(toLast: UInt(limit))
        
        let snapshot = try await query.getData()
        
        guard let messagesValue = snapshot.value as? [String: Any] else {
            return []
        }
        
        var messages: [ChatMessage] = []
        
        for (messageId, value) in messagesValue {
            guard let data = value as? [String: Any] else { continue }
            if let parsed = try? parseMessage(id: messageId, data: data) {
                messages.append(parsed)
            }
        }
        
        messages.sort { $0.timestamp < $1.timestamp }
        return messages
    }
    
    private func parseMessage(id: String, data: [String: Any]) throws -> ChatMessage {
        guard let senderId = data["senderId"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ChatMessage.MessageType(rawValue: typeRaw),
              let timestampDate = dateFromTimestampField(data["timestamp"]) else {
            throw ChatError.decodingError(NSError(domain: "ChatManager", code: -1))
        }
        
        let senderName = data["senderName"] as? String
        
        let content: MessageContent
        switch type {
        case .text:
            let text = data["text"] as? String ?? ""
            content = .text(text)
        case .image:
            let imageData = ImageMessageData(
                imageUrl: data["imageUrl"] as? String ?? "",
                thumbnailUrl: data["thumbnailUrl"] as? String,
                width: data["width"] as? Int,
                height: data["height"] as? Int,
                fileSize: data["fileSize"] as? Int
            )
            content = .image(imageData)
        case .gif:
            let gifData = GifMessageData(
                gifUrl: data["gifUrl"] as? String ?? "",
                previewUrl: data["previewUrl"] as? String,
                width: data["width"] as? Int,
                height: data["height"] as? Int,
                source: data["source"] as? String
            )
            content = .gif(gifData)
        case .rivalInvite:
            if let rivalData = data["rivalInvite"] as? [String: Any] {
                let rival = RivalObj(
                    id: rivalData["id"] as? String ?? "",
                    gamerTag: rivalData["gamerTag"] as? String ?? "",
                    senderPokoId: rivalData["senderPokoId"] as? String ?? "",
                    getterPokoId: rivalData["getterPokoId"] as? String ?? "",
                    game: rivalData["game"] as? String ?? "",
                    gameImageUrl: rivalData["gameImageUrl"] as? String ?? "",
                    type: rivalData["type"] as? String ?? "",
                    date: rivalData["date"] as? String ?? "",
                    uid: rivalData["uid"] as? String ?? "",
                    durationMin: rivalData["durationMin"] as? Int ?? 0,
                    customMessage: rivalData["customMessage"] as? String ?? "",
                    customResponse: rivalData["customResponse"] as? String ?? "",
                    rivalStatus: rivalData["rivalStatus"] as? String ?? "proposed",
                    createdAtMs: rivalData["createdAtMs"] as? Int64 ?? 0,
                    expiresAtMs: rivalData["expiresAtMs"] as? Int64 ?? 0
                )
                content = .rivalInvite(rival)
            } else {
                throw ChatError.decodingError(NSError(domain: "ChatManager", code: -2))
            }
        case .system, .memberJoined, .memberLeft, .groupCreated, .groupRenamed:
            let text = data["text"] as? String ?? ""
            content = .system(text)
        }
        
        let statusRaw = data["status"] as? String ?? "sent"
        let status = ChatMessage.MessageStatus(rawValue: statusRaw) ?? .sent
        
        return ChatMessage(
            id: id,
            channelId: data["channelId"] as? String ?? "",
            senderId: senderId,
            senderName: senderName,
            type: type,
            content: content,
            timestamp: timestampDate,
            isRead: data["isRead"] as? Bool ?? false,
            status: status
        )
    }
    
    // MARK: - Message Sending
    
    func sendTextMessage(channelId: String, text: String) async throws -> ChatMessage {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let userData = try? await fetchUserData(userId: userId)
        let senderName = userData?["gamerTag"] as? String
        
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let newMessageRef = messagesRef.childByAutoId()
        let messageId = newMessageRef.key ?? UUID().uuidString
        let now = Date()
        
        var data: [String: Any] = [:]
        data["channelId"] = channelId
        data["senderId"] = userId
        data["senderName"] = senderName ?? NSNull()
        data["type"] = ChatMessage.MessageType.text.rawValue
        data["text"] = text
        data["timestamp"] = ServerValue.timestamp()
        data["isRead"] = false
        data["status"] = ChatMessage.MessageStatus.sent.rawValue
        
        try await newMessageRef.setValue(data)
        
        try await updateChannelMetadataForNewMessage(
            channelId: channelId,
            type: .text,
            textPreview: text,
            senderId: userId,
            senderName: senderName
        )
        
        let message = ChatMessage(
            id: messageId,
            channelId: channelId,
            senderId: userId,
            senderName: senderName,
            type: .text,
            content: .text(text),
            timestamp: now,
            isRead: false,
            status: .sent
        )
        
        onNewMessage?(message)
        return message
    }
    
    func sendImageMessage(channelId: String, image: UIImage) async throws -> ChatMessage {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw ChatError.imageUploadFailed
        }
        
        let userData = try? await fetchUserData(userId: userId)
        let senderName = userData?["gamerTag"] as? String
        
        let imageId = UUID().uuidString
        let path = "chatImages/\(channelId)/\(imageId).jpg"
        let imageRef = storage.child(path)
        
        _ = try await imageRef.putDataAsync(jpegData, metadata: nil)
        let downloadUrl = try await imageRef.downloadURL().absoluteString
        
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let newMessageRef = messagesRef.childByAutoId()
        let messageId = newMessageRef.key ?? UUID().uuidString
        let now = Date()
        
        var data: [String: Any] = [:]
        data["channelId"] = channelId
        data["senderId"] = userId
        data["senderName"] = senderName ?? NSNull()
        data["type"] = ChatMessage.MessageType.image.rawValue
        data["imageUrl"] = downloadUrl
        data["width"] = Int(image.size.width)
        data["height"] = Int(image.size.height)
        data["fileSize"] = jpegData.count
        data["timestamp"] = ServerValue.timestamp()
        data["isRead"] = false
        data["status"] = ChatMessage.MessageStatus.sent.rawValue
        
        try await newMessageRef.setValue(data)
        
        try await updateChannelMetadataForNewMessage(
            channelId: channelId,
            type: .image,
            textPreview: nil,
            senderId: userId,
            senderName: senderName
        )
        
        let imageData = ImageMessageData(
            imageUrl: downloadUrl,
            thumbnailUrl: nil,
            width: Int(image.size.width),
            height: Int(image.size.height),
            fileSize: jpegData.count
        )
        
        let message = ChatMessage(
            id: messageId,
            channelId: channelId,
            senderId: userId,
            senderName: senderName,
            type: .image,
            content: .image(imageData),
            timestamp: now,
            isRead: false,
            status: .sent
        )
        
        onNewMessage?(message)
        return message
    }
    
    func sendGifMessage(channelId: String, gifData: GifMessageData) async throws -> ChatMessage {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let userData = try? await fetchUserData(userId: userId)
        let senderName = userData?["gamerTag"] as? String
        
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let newMessageRef = messagesRef.childByAutoId()
        let messageId = newMessageRef.key ?? UUID().uuidString
        let now = Date()
        
        var data: [String: Any] = [:]
        data["channelId"] = channelId
        data["senderId"] = userId
        data["senderName"] = senderName ?? NSNull()
        data["type"] = ChatMessage.MessageType.gif.rawValue
        data["gifUrl"] = gifData.gifUrl
        if let preview = gifData.previewUrl { data["previewUrl"] = preview }
        if let width = gifData.width { data["width"] = width }
        if let height = gifData.height { data["height"] = height }
        if let source = gifData.source { data["source"] = source }
        data["timestamp"] = ServerValue.timestamp()
        data["isRead"] = false
        data["status"] = ChatMessage.MessageStatus.sent.rawValue
        
        try await newMessageRef.setValue(data)
        
        try await updateChannelMetadataForNewMessage(
            channelId: channelId,
            type: .gif,
            textPreview: nil,
            senderId: userId,
            senderName: senderName
        )
        
        let message = ChatMessage(
            id: messageId,
            channelId: channelId,
            senderId: userId,
            senderName: senderName,
            type: .gif,
            content: .gif(gifData),
            timestamp: now,
            isRead: false,
            status: .sent
        )
        
        onNewMessage?(message)
        return message
    }
    
    func sendRivalInvite(channelId: String, rivalInvite: RivalObj) async throws -> ChatMessage {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        let userData = try? await fetchUserData(userId: userId)
        let senderName = userData?["gamerTag"] as? String
        
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let newMessageRef = messagesRef.childByAutoId()
        let messageId = newMessageRef.key ?? UUID().uuidString
        let now = Date()
        
        let rivalData: [String: Any] = [
            "id": rivalInvite.id,
            "gamerTag": rivalInvite.gamerTag,
            "senderPokoId": rivalInvite.senderPokoId,
            "getterPokoId": rivalInvite.getterPokoId,
            "game": rivalInvite.game,
            "gameImageUrl": rivalInvite.gameImageUrl,
            "type": rivalInvite.type,
            "date": rivalInvite.date,
            "uid": rivalInvite.uid,
            "durationMin": rivalInvite.durationMin,
            "customMessage": rivalInvite.customMessage,
            "customResponse": rivalInvite.customResponse,
            "rivalStatus": rivalInvite.rivalStatus,
            "createdAtMs": rivalInvite.createdAtMs,
            "expiresAtMs": rivalInvite.expiresAtMs
        ]
        
        var data: [String: Any] = [:]
        data["channelId"] = channelId
        data["senderId"] = userId
        data["senderName"] = senderName ?? NSNull()
        data["type"] = ChatMessage.MessageType.rivalInvite.rawValue
        data["rivalInvite"] = rivalData
        data["timestamp"] = ServerValue.timestamp()
        data["isRead"] = false
        data["status"] = ChatMessage.MessageStatus.sent.rawValue
        
        try await newMessageRef.setValue(data)
        
        try await updateChannelMetadataForNewMessage(
            channelId: channelId,
            type: .rivalInvite,
            textPreview: "Rival invite",
            senderId: userId,
            senderName: senderName
        )
        
        let message = ChatMessage(
            id: messageId,
            channelId: channelId,
            senderId: userId,
            senderName: senderName,
            type: .rivalInvite,
            content: .rivalInvite(rivalInvite),
            timestamp: now,
            isRead: false,
            status: .sent
        )
        
        onNewMessage?(message)
        return message
    }
    
    private func sendSystemMessage(channelId: String, type: ChatMessage.MessageType, text: String) async throws {
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        let newMessageRef = messagesRef.childByAutoId()
        
        var data: [String: Any] = [:]
        data["channelId"] = channelId
        data["senderId"] = "system"
        data["type"] = type.rawValue
        data["text"] = text
        data["timestamp"] = ServerValue.timestamp()
        data["isRead"] = false
        data["status"] = ChatMessage.MessageStatus.delivered.rawValue
        
        try await newMessageRef.setValue(data)
        
        let channelRef = db.child("ChatChannels").child(channelId)
        var updates: [String: Any] = [:]
        updates["lastMessageAt"] = ServerValue.timestamp()
        updates["lastMessageType"] = type.rawValue
        updates["lastMessage"] = text
        updates["lastMessageSenderId"] = "system"
        updates["lastMessageSenderName"] = NSNull()
        
        try await channelRef.updateChildValues(updates)
    }
    
    func respondToRivalInvite(messageId: String, channelId: String, response: RivalInviteResponse) async throws {
        let statusString = (response == .accept) ? "accepted" : "rejected"
        
        let rivalStatusRef = db
            .child("ChatChannels")
            .child(channelId)
            .child("messages")
            .child(messageId)
            .child("rivalInvite")
            .child("rivalStatus")
        
        try await rivalStatusRef.setValue(statusString)
    }
    
    func markMessagesAsRead(channelId: String, messageIds: [String]) async throws {
        guard let userId = getCurrentUserId() else {
            throw ChatError.notAuthenticated
        }
        
        guard !messageIds.isEmpty else { return }
        
        let messagesRef = db.child("ChatChannels").child(channelId).child("messages")
        var updates: [String: Any] = [:]
        
        for id in messageIds {
            updates["\(id)/isRead"] = true
            updates["\(id)/status"] = ChatMessage.MessageStatus.read.rawValue
        }
        
        try await messagesRef.updateChildValues(updates)
        
        let channelRef = db.child("ChatChannels").child(channelId)
        try await channelRef.updateChildValues(["unreadCount_\(userId)": 0])
        
        for id in messageIds {
            onMessageStatusUpdate?(id, .read)
        }
    }
    
    func sendTypingIndicator(channelId: String, isTyping: Bool) async {
        guard let userId = getCurrentUserId() else { return }
        
        let userName = try? await fetchUserData(userId: userId)["gamerTag"] as? String
        
        let typingRef = db
            .child("ChatChannels")
            .child(channelId)
            .child("typing")
            .child(userId)
        
        var data: [String: Any] = [
            "isTyping": isTyping,
            "timestamp": ServerValue.timestamp()
        ]
        
        if let name = userName {
            data["userName"] = name
        }
        
        do {
            try await typingRef.setValue(data)
        } catch {
            print("💬 [ChatManager] Failed to send typing indicator: \(error)")
        }
    }
    
    private func updateChannelMetadataForNewMessage(
        channelId: String,
        type: ChatMessage.MessageType,
        textPreview: String?,
        senderId: String,
        senderName: String? = nil
    ) async throws {
        let channelRef = db.child("ChatChannels").child(channelId)
        let snapshot = try await channelRef.getData()
        let data = snapshot.value as? [String: Any] ?? [:]
        
        var participants: [String] = []
        if let arr = data["participants"] as? [String] {
            participants = arr
        } else if let dict = data["participants"] as? [String: Any] {
            let sortedKeys = dict.keys.sorted()
            participants = sortedKeys.compactMap { dict[$0] as? String }
        }
        
        var updates: [String: Any] = [:]
        updates["lastMessageAt"] = ServerValue.timestamp()
        updates["lastMessageType"] = type.rawValue
        updates["lastMessageSenderId"] = senderId
        updates["lastMessageSenderName"] = senderName ?? NSNull()
        
        if let preview = textPreview, !preview.isEmpty {
            updates["lastMessage"] = preview
        } else {
            switch type {
            case .image: updates["lastMessage"] = "Photo"
            case .gif: updates["lastMessage"] = "GIF"
            case .rivalInvite: updates["lastMessage"] = "Rival Invite"
            case .system, .memberJoined, .memberLeft, .groupCreated, .groupRenamed: updates["lastMessage"] = "System message"
            case .text: break
            }
        }
        
        for participantId in participants {
            let key = "unreadCount_\(participantId)"
            if participantId == senderId {
                updates[key] = 0
            } else {
                let current = data[key] as? Int ?? 0
                updates[key] = current + 1
            }
        }
        
        try await channelRef.updateChildValues(updates)
    }
    
    // MARK: - Message Listener
    
    func setupMessageListener(channelId: String, onMessage: @escaping (ChatMessage) -> Void) {
        if let handle = messageListeners[channelId],
           let ref = messageListenerRefs[channelId] {
            ref.removeObserver(withHandle: handle)
        }
        
        let ref = db.child("ChatChannels").child(channelId).child("messages")
        messageListenerRefs[channelId] = ref
        
        let handle = ref
            .queryOrdered(byChild: "timestamp")
            .observe(.childAdded, with: { [weak self] snapshot in
                guard let self = self,
                      let data = snapshot.value as? [String: Any] else { return }
                if let message = try? self.parseMessage(id: snapshot.key, data: data) {
                    onMessage(message)
                    self.onNewMessage?(message)
                }
            })
        
        messageListeners[channelId] = handle
    }
    
    func removeMessageListener(channelId: String) {
        if let handle = messageListeners[channelId],
           let ref = messageListenerRefs[channelId] {
            ref.removeObserver(withHandle: handle)
        }
        messageListeners.removeValue(forKey: channelId)
        messageListenerRefs.removeValue(forKey: channelId)
    }
    
    // MARK: - Cleanup
    
    private func removeAllListeners() {
        if let ref = friendsRef, let handle = friendsListener {
            ref.removeObserver(withHandle: handle)
        }
        
        if let ref = onlineStatusRef, let handle = onlineStatusListener {
            ref.removeObserver(withHandle: handle)
        }
        
        if let ref = conversationsRef, let handle = conversationsListener {
            ref.removeObserver(withHandle: handle)
        }
        
        for (channelId, handle) in messageListeners {
            if let ref = messageListenerRefs[channelId] {
                ref.removeObserver(withHandle: handle)
            }
        }
        
        messageListeners.removeAll()
        messageListenerRefs.removeAll()
    }
    
    private func clearData() {
        removeAllListeners()
        friends = []
        onlineFriends = []
        conversations = []
        error = nil
    }
    
    // MARK: - Helpers
    
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid ?? UserProvider.shared.getUser()?.uId
    }
    
    var hasFriends: Bool {
        !friends.isEmpty
    }
    
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }
    
    private func dateFromTimestampField(_ value: Any?) -> Date? {
        guard let value = value else { return nil }
        
        if let timeInterval = value as? TimeInterval {
            if timeInterval > 10_000_000_000 {
                return Date(timeIntervalSince1970: timeInterval / 1000.0)
            } else {
                return Date(timeIntervalSince1970: timeInterval)
            }
        }
        
        if let intVal = value as? Int {
            if intVal > 10_000_000_000 {
                return Date(timeIntervalSince1970: TimeInterval(intVal) / 1000.0)
            } else {
                return Date(timeIntervalSince1970: TimeInterval(intVal))
            }
        }
        
        if let int64Val = value as? Int64 {
            if int64Val > 10_000_000_000 {
                return Date(timeIntervalSince1970: TimeInterval(int64Val) / 1000.0)
            } else {
                return Date(timeIntervalSince1970: TimeInterval(int64Val))
            }
        }
        
        return nil
    }
}
