//
//  ChatListViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import SwiftUI
import Combine

@MainActor
class ChatListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var conversations: [ConversationDisplay] = []
    @Published var onlineFriends: [ChatFriend] = []
    @Published var allFriends: [ChatFriend] = []
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    
    @Published var searchText = ""
    
    // Navigation
    @Published var selectedConversation: ConversationDisplay?
    @Published var showRivalInviteSheet = false
    @Published var showUserSearchView = false
    
    // MARK: - Private Properties
    
    private let requestManager = ChatRequestManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasFriends: Bool { !allFriends.isEmpty }
    var hasConversations: Bool { !conversations.isEmpty }
    var totalUnreadCount: Int { conversations.reduce(0) { $0 + $1.unreadCount } }
    
    var filteredConversations: [ConversationDisplay] {
        guard !searchText.isEmpty else { return conversations }
        return conversations.filter { conversation in
            if conversation.isGroupChat {
                if let groupName = conversation.groupName, groupName.localizedCaseInsensitiveContains(searchText) { return true }
                return conversation.participants.contains { $0.gamerTag.localizedCaseInsensitiveContains(searchText) }
            } else {
                return conversation.friend?.gamerTag.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var squadOnline: [ChatFriend] { Array(onlineFriends.prefix(8)) }
    
    // MARK: - Initialization
    
    init() { setupBindings() }
    
    private func setupBindings() {
        requestManager.$conversations.receive(on: DispatchQueue.main).sink { [weak self] in self?.conversations = $0 }.store(in: &cancellables)
        requestManager.$onlineFriends.receive(on: DispatchQueue.main).sink { [weak self] in self?.onlineFriends = $0 }.store(in: &cancellables)
        requestManager.$friends.receive(on: DispatchQueue.main).sink { [weak self] in self?.allFriends = $0 }.store(in: &cancellables)
        requestManager.$isLoading.receive(on: DispatchQueue.main).sink { [weak self] in self?.isLoading = $0 }.store(in: &cancellables)
        requestManager.$error.receive(on: DispatchQueue.main).sink { [weak self] in self?.error = $0?.localizedDescription }.store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadData() async { await requestManager.loadInitialData() }
    func refresh() async { isRefreshing = true; await requestManager.refresh(); isRefreshing = false }
    
    func startChat(with friend: ChatFriend) async {
        do {
            let channelId = try await requestManager.getOrCreateChannel(with: friend.id)
            if let existing = conversations.first(where: { $0.id == channelId }) {
                selectedConversation = existing
            } else {
                selectedConversation = ConversationDisplay(id: channelId, friend: friend, lastMessage: nil, lastMessageTime: nil, unreadCount: 0, lastMessageType: nil)
            }
        } catch { self.error = "Failed to start chat: \(error.localizedDescription)" }
    }
    
    func createGroup(request: CreateGroupRequest) async {
        do {
            let channelId = try await requestManager.createGroupChat(request: request)
            if let newConversation = conversations.first(where: { $0.id == channelId }) { selectedConversation = newConversation }
        } catch { self.error = "Failed to create group: \(error.localizedDescription)" }
    }
    
    func openRivalInvite() { showRivalInviteSheet = true }
    func openUserSearch() { showUserSearchView = true }
    func clearError() { error = nil }
}
