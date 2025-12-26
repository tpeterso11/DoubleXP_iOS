//
//  ChatListView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var dragOffset: CGFloat = 0
    @State private var showCreateGroupSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    loadingView
                } else if !viewModel.hasFriends {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Squad Chat")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    newChatButton
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $viewModel.selectedConversation) { conversation in
                ChatView(conversation: conversation)
            }
            .fullScreenCover(isPresented: $viewModel.showRivalInviteSheet) {
                RivalInviteDrawerView(isPresented: $viewModel.showRivalInviteSheet)
            }
            .fullScreenCover(isPresented: $viewModel.showUserSearchView) {
                PlayerSearchView(
                    onPlayerTapped: { player in
                        viewModel.showUserSearchView = false
                    },
                    onAddGamesTapped: {
                        viewModel.showUserSearchView = false
                    }
                )
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                CreateGroupChatSheet(
                    friends: viewModel.allFriends,
                    onCreate: { request in
                        Task {
                            await viewModel.createGroup(request: request)
                        }
                    }
                )
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            dismiss()
                        }
                        dragOffset = 0
                    }
            )
            .offset(y: dragOffset)
            .animation(.interactiveSpring(), value: dragOffset)
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    // MARK: - New Chat Button
    
    private var newChatButton: some View {
        Menu {
            Button {
                // Show friend picker for new chat
            } label: {
                Label("New Message", systemImage: "plus.message")
            }
            
            Button {
                showCreateGroupSheet = true
            } label: {
                Label("New Group", systemImage: "person.3")
            }
            
            Button {
                viewModel.openRivalInvite()
            } label: {
                Label("Send Rival Invite", systemImage: "flame")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text("New")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerGradient
                
                rivalChallengeBanner
                    .padding(.horizontal, 20)
                    .padding(.top, -60)
                
                if !viewModel.squadOnline.isEmpty {
                    squadSection
                }
                
                messagesSection
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var headerGradient: some View {
        LinearGradient(
            colors: [Color(hex: "667eea").opacity(0.15), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 200)
    }
    
    private var rivalChallengeBanner: some View {
        Button {
            viewModel.openRivalInvite()
        } label: {
            ZStack(alignment: .trailing) {
                Text("⚔️").font(.system(size: 80)).opacity(0.15).offset(x: 20)
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RIVAL CHALLENGE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color(hex: "FF6B6B"))
                        
                        Text("Challenge Your Friends")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Send a game invite and prove who's the best")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 12)
                        
                        HStack(spacing: 8) {
                            Text("⚔️")
                            Text("Send Challenge").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "ee5a5a")], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .background(LinearGradient(colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "FF4141").opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var squadSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Squad").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text("\(viewModel.squadOnline.count) Online")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "4CAF50"))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(hex: "4CAF50").opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(viewModel.squadOnline) { friend in
                    SquadMemberView(friend: friend) {
                        Task { await viewModel.startChat(with: friend) }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
    }
    
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Messages").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Menu {
                    Button("All") { }
                    Button("Unread") { }
                    Button("Groups") { }
                } label: {
                    HStack(spacing: 4) {
                        Text("All").font(.system(size: 12))
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.hasConversations {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredConversations) { conversation in
                        ConversationRowView(conversation: conversation)
                            .onTapGesture { viewModel.selectedConversation = conversation }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                noMessagesView
            }
        }
        .padding(.top, 24)
    }
    
    private var noMessagesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 40)).foregroundColor(.white.opacity(0.3))
            Text("No messages yet").font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.5))
            Text("Start a conversation with someone from your squad!").font(.system(size: 13)).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40).padding(.horizontal, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white).scaleEffect(1.2)
            Text("Loading chats...").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.slash").font(.system(size: 60)).foregroundColor(.white.opacity(0.3))
            VStack(spacing: 8) {
                Text("No Friends Yet").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Find players to add to your squad\nand start chatting!").font(.system(size: 14)).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
            }
            Button { viewModel.openUserSearch() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Find Players").font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 14)
                .background(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(40)
    }
}

// MARK: - Squad Member View

struct SquadMemberView: View {
    let friend: ChatFriend
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: friend.bubbleGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .overlay(Text(friend.gamerTag.prefix(1).uppercased()).font(.system(size: 20, weight: .bold)).foregroundColor(.white))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(friend.onlineStatus == .inGame ? Color(hex: "4CAF50") : Color.clear, lineWidth: 2))
                    
                    if friend.onlineStatus == .inGame {
                        Text("🎮").font(.system(size: 12)).padding(4).background(Color(hex: "1a1a2e")).clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2)).offset(x: 6, y: 6)
                    }
                }
                Text(friend.gamerTag).font(.system(size: 11)).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                Text(friend.onlineStatus.displayText).font(.system(size: 9)).foregroundColor(Color(hex: "4CAF50"))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conversation Row View (Unified for DM and Group)

struct ConversationRowView: View {
    let conversation: ConversationDisplay
    
    var body: some View {
        HStack(spacing: 14) {
            avatarView
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    
                    if conversation.isGroupChat {
                        Text("\(conversation.memberCount)")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white.opacity(0.1)).clipShape(Capsule())
                    }
                    
                    Spacer()
                    Text(conversation.timeDisplayText).font(.system(size: 11)).foregroundColor(.white.opacity(0.3))
                }
                
                Text(conversation.previewText).font(.system(size: 12)).foregroundColor(.white.opacity(0.4)).lineLimit(1)
            }
            
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Circle())
            }
        }
        .padding(14).background(Color.white.opacity(0.03)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if conversation.isGroupChat {
            groupAvatarView
        } else {
            dmAvatarView
        }
    }
    
    private var dmAvatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: conversation.friend?.bubbleGradient ?? [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(Text(conversation.friend?.gamerTag.prefix(1).uppercased() ?? "?").font(.system(size: 18, weight: .bold)).foregroundColor(.white))
            
            if conversation.friend?.onlineStatus.isActive == true {
                Circle().fill(Color(hex: "4CAF50")).frame(width: 14, height: 14).overlay(Circle().stroke(Color(hex: "0a0a0f"), lineWidth: 3)).offset(x: 2, y: 2)
            }
        }
    }
    
    private var groupAvatarView: some View {
        ZStack {
            let displayParticipants = Array(conversation.participants.prefix(4))
            
            if let imageUrl = conversation.groupImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { groupPlaceholder }
                .frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                switch displayParticipants.count {
                case 1: singleAvatar(friend: displayParticipants[0], size: 50)
                case 2: twoAvatarsLayout(friends: displayParticipants)
                case 3: threeAvatarsLayout(friends: displayParticipants)
                default: fourAvatarsLayout(friends: displayParticipants)
                }
            }
            
            if conversation.onlineParticipantCount > 0 {
                Circle().fill(Color(hex: "4CAF50")).frame(width: 14, height: 14).overlay(Circle().stroke(Color(hex: "0a0a0f"), lineWidth: 3)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).offset(x: 2, y: 2)
            }
        }
        .frame(width: 50, height: 50)
    }
    
    private var groupPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Image(systemName: "person.3.fill").font(.system(size: 16)).foregroundColor(.white))
    }
    
    private func singleAvatar(friend: ChatFriend, size: CGFloat) -> some View {
        miniAvatar(friend: friend, size: size, cornerRadius: size * 0.28)
    }
    
    private func twoAvatarsLayout(friends: [ChatFriend]) -> some View {
        ZStack {
            miniAvatar(friend: friends[0], size: 32, cornerRadius: 10).offset(x: -8, y: -6)
            miniAvatar(friend: friends[1], size: 32, cornerRadius: 10).offset(x: 8, y: 6)
        }
    }
    
    private func threeAvatarsLayout(friends: [ChatFriend]) -> some View {
        ZStack {
            miniAvatar(friend: friends[0], size: 28, cornerRadius: 8).offset(x: 0, y: -10)
            miniAvatar(friend: friends[1], size: 28, cornerRadius: 8).offset(x: -10, y: 8)
            miniAvatar(friend: friends[2], size: 28, cornerRadius: 8).offset(x: 10, y: 8)
        }
    }
    
    private func fourAvatarsLayout(friends: [ChatFriend]) -> some View {
        let size: CGFloat = 24, offset: CGFloat = 12
        return ZStack {
            miniAvatar(friend: friends[0], size: size, cornerRadius: 6).offset(x: -offset, y: -offset)
            miniAvatar(friend: friends[1], size: size, cornerRadius: 6).offset(x: offset, y: -offset)
            miniAvatar(friend: friends[2], size: size, cornerRadius: 6).offset(x: -offset, y: offset)
            if friends.count > 3 { miniAvatar(friend: friends[3], size: size, cornerRadius: 6).offset(x: offset, y: offset) }
        }
    }
    
    private func miniAvatar(friend: ChatFriend, size: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(colors: friend.bubbleGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(Text(friend.gamerTag.prefix(1).uppercased()).font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.white))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color(hex: "0a0a0f"), lineWidth: 2))
    }
}

// MARK: - Create Group Chat Sheet

struct CreateGroupChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""
    @State private var selectedFriends: Set<String> = []
    @State private var isCreating = false
    
    let friends: [ChatFriend]
    let onCreate: (CreateGroupRequest) -> Void
    
    private var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFriends.count >= 1 && selectedFriends.count <= ChatChannel.maxGroupParticipants - 1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        groupNameSection
                        friendsSelectionSection
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.white) }
                ToolbarItem(placement: .principal) { Text("New Group").font(.system(size: 17, weight: .semibold)).foregroundColor(.white) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createGroup() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canCreate ? Color(hex: "4CAF50") : .white.opacity(0.3))
                        .disabled(!canCreate || isCreating)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GROUP NAME").font(.system(size: 12, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.5))
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 48, height: 48)
                    Image(systemName: "person.3.fill").font(.system(size: 16)).foregroundColor(.white)
                }
                TextField("Enter group name...", text: $groupName)
                    .font(.system(size: 16)).foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var friendsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ADD MEMBERS").font(.system(size: 12, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(selectedFriends.count)/\(ChatChannel.maxGroupParticipants - 1)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedFriends.count >= ChatChannel.maxGroupParticipants - 1 ? Color(hex: "FF6B6B") : .white.opacity(0.5))
            }
            LazyVStack(spacing: 8) {
                ForEach(friends) { friend in
                    FriendSelectionRow(friend: friend, isSelected: selectedFriends.contains(friend.id), isDisabled: !selectedFriends.contains(friend.id) && selectedFriends.count >= ChatChannel.maxGroupParticipants - 1) { toggleFriend(friend) }
                }
            }
        }
    }
    
    private func toggleFriend(_ friend: ChatFriend) {
        if selectedFriends.contains(friend.id) { selectedFriends.remove(friend.id) }
        else if selectedFriends.count < ChatChannel.maxGroupParticipants - 1 { selectedFriends.insert(friend.id) }
    }
    
    private func createGroup() {
        guard canCreate else { return }
        isCreating = true
        let request = CreateGroupRequest(name: groupName.trimmingCharacters(in: .whitespacesAndNewlines), participantIds: Array(selectedFriends), imageUrl: nil)
        onCreate(request)
        dismiss()
    }
}

// MARK: - Friend Selection Row

struct FriendSelectionRow: View {
    let friend: ChatFriend
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: friend.bubbleGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Text(friend.gamerTag.prefix(1).uppercased()).font(.system(size: 16, weight: .bold)).foregroundColor(.white))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.gamerTag).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    Text(friend.onlineStatus.displayText).font(.system(size: 11)).foregroundColor(friend.onlineStatus.isActive ? Color(hex: "4CAF50") : .white.opacity(0.4))
                }
                Spacer()
                
                ZStack {
                    Circle().stroke(isSelected ? Color(hex: "4CAF50") : Color.white.opacity(0.3), lineWidth: 2).frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(Color(hex: "4CAF50")).frame(width: 16, height: 16)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: "4CAF50").opacity(0.1) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(hex: "4CAF50").opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle()).disabled(isDisabled).opacity(isDisabled ? 0.5 : 1)
    }
}
