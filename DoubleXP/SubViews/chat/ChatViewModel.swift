//
//  ChatViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var conversation: ConversationDisplay
    @Published var channelId: String
    
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var isLoadingMore = false
    @Published var error: String?
    
    @Published var typingUsers: [ChatFriend] = []
    @Published var isOtherUserTyping = false
    @Published var showImagePicker = false
    @Published var showGifPicker = false
    @Published var showRivalInviteSheet = false
    @Published var showGroupInfoSheet = false
    
    @Published var selectedImage: UIImage?
    
    // MARK: - Private Properties
    
    private let requestManager = ChatRequestManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    private var hasMoreMessages = true
    
    // MARK: - Computed Properties
    
    var canSendMessage: Bool { !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil }
    var currentUserId: String? { requestManager.getCurrentUserId() }
    var isGroupChat: Bool { conversation.isGroupChat }
    var displayName: String { conversation.displayName }
    var participants: [ChatFriend] { conversation.participants }
    var onlineParticipantCount: Int { conversation.onlineParticipantCount }
    var friend: ChatFriend? { conversation.friend }
    
    func participant(for senderId: String) -> ChatFriend? {
        conversation.participants.first { $0.id == senderId }
    }
    
    // MARK: - Initialization
    
    init(conversation: ConversationDisplay) {
        self.conversation = conversation
        self.channelId = conversation.id
        setupMessageListener()
    }
    
    convenience init(friend: ChatFriend, channelId: String) {
        let conv = ConversationDisplay(id: channelId, friend: friend, lastMessage: nil, lastMessageTime: nil, unreadCount: 0, lastMessageType: nil)
        self.init(conversation: conv)
    }
    
    deinit {
        Task { @MainActor in requestManager.removeMessageListener(channelId: channelId) }
        typingTimer?.invalidate()
    }
    
    private func setupMessageListener() {
        requestManager.setupMessageListener(channelId: channelId) { [weak self] message in
            Task { @MainActor in self?.handleNewMessage(message) }
        }
    }
    
    private func handleNewMessage(_ message: ChatMessage) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        if message.senderId != currentUserId {
            Task { try? await requestManager.markMessagesAsRead(channelId: channelId, messageIds: [message.id]) }
        }
    }
    
    // MARK: - Public Methods
    
    func loadMessages() async {
        isLoading = true
        error = nil
        do {
            messages = try await requestManager.loadMessages(channelId: channelId)
            let unreadIds = messages.filter { !$0.isRead && $0.senderId != currentUserId }.map { $0.id }
            if !unreadIds.isEmpty { try? await requestManager.markMessagesAsRead(channelId: channelId, messageIds: unreadIds) }
        } catch { self.error = "Failed to load messages" }
        isLoading = false
    }
    
    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages, let first = messages.first else { return }
        isLoadingMore = true
        do {
            let older = try await requestManager.loadMoreMessages(channelId: channelId, before: first)
            if older.isEmpty { hasMoreMessages = false } else { messages.insert(contentsOf: older, at: 0) }
        } catch { }
        isLoadingMore = false
    }
    
    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSending = true
        let original = messageText
        messageText = ""
        do {
            let msg = try await requestManager.sendTextMessage(channelId: channelId, text: text)
            if !messages.contains(where: { $0.id == msg.id }) { messages.append(msg) }
        } catch { self.error = "Failed to send"; messageText = original }
        isSending = false
        stopTypingIndicator()
    }
    
    func sendImageMessage() async {
        guard let image = selectedImage else { return }
        isSending = true
        selectedImage = nil
        do {
            let msg = try await requestManager.sendImageMessage(channelId: channelId, image: image)
            if !messages.contains(where: { $0.id == msg.id }) { messages.append(msg) }
        } catch { self.error = "Failed to send image" }
        isSending = false
    }
    
    func sendGifMessage(_ gifData: GifMessageData) async {
        isSending = true
        do {
            let msg = try await requestManager.sendGifMessage(channelId: channelId, gifData: gifData)
            if !messages.contains(where: { $0.id == msg.id }) { messages.append(msg) }
        } catch { self.error = "Failed to send GIF" }
        isSending = false
    }
    
    func sendRivalInvite(_ rival: RivalObj) async {
        isSending = true
        do {
            let msg = try await requestManager.sendRivalInvite(channelId: channelId, rivalInvite: rival)
            if !messages.contains(where: { $0.id == msg.id }) { messages.append(msg) }
        } catch { self.error = "Failed to send invite" }
        isSending = false
        showRivalInviteSheet = false
    }
    
    func respondToRivalInvite(messageId: String, response: RivalInviteResponse) async {
        do { try await requestManager.respondToRivalInvite(messageId: messageId, channelId: channelId, response: response) }
        catch { self.error = "Failed to respond" }
    }
    
    // MARK: - Group Management
    
    func addMember(_ memberId: String) async {
        guard isGroupChat else { return }
        do { try await requestManager.addGroupMember(channelId: channelId, memberId: memberId) }
        catch { self.error = "Failed to add member" }
    }
    
    func removeMember(_ memberId: String) async {
        guard isGroupChat else { return }
        do { try await requestManager.removeGroupMember(channelId: channelId, memberId: memberId) }
        catch { self.error = "Failed to remove member" }
    }
    
    func leaveGroup() async {
        guard isGroupChat, let userId = currentUserId else { return }
        do { try await requestManager.removeGroupMember(channelId: channelId, memberId: userId) }
        catch { self.error = "Failed to leave group" }
    }
    
    // MARK: - Typing Indicator
    
    func onTyping() {
        typingTimer?.invalidate()
        Task { await requestManager.sendTypingIndicator(channelId: channelId, isTyping: true) }
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.stopTypingIndicator() }
        }
    }
    
    private func stopTypingIndicator() {
        typingTimer?.invalidate()
        typingTimer = nil
        Task { await requestManager.sendTypingIndicator(channelId: channelId, isTyping: false) }
    }
    
    // MARK: - Actions
    
    func openImagePicker() { showImagePicker = true }
    func openGifPicker() { showGifPicker = true }
    func openRivalInvite() { showRivalInviteSheet = true }
    func openGroupInfo() { showGroupInfoSheet = true }
    func clearError() { error = nil }
    
    func isMessageFromCurrentUser(_ message: ChatMessage) -> Bool { message.senderId == currentUserId }
    
    func shouldShowSenderName(for message: ChatMessage, at index: Int) -> Bool {
        guard isGroupChat, message.senderId != currentUserId, message.senderId != "system" else { return false }
        if index == 0 { return true }
        return messages[index - 1].senderId != message.senderId
    }
    
    func shouldShowAvatar(for message: ChatMessage, at index: Int) -> Bool {
        guard isGroupChat, message.senderId != currentUserId, message.senderId != "system" else { return false }
        if index == messages.count - 1 { return true }
        return messages[index + 1].senderId != message.senderId
    }
}
