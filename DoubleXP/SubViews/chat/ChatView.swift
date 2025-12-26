//
//  ChatView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var isInputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    
    init(conversation: ConversationDisplay) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    init(friend: ChatFriend, channelId: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(friend: friend, channelId: channelId))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                messagesScrollView
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { backButton }
            ToolbarItem(placement: .principal) { headerInfo }
            ToolbarItem(placement: .navigationBarTrailing) { headerActions }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $viewModel.showRivalInviteSheet) {
            SendRivalInviteSheet(
                friend: viewModel.friend ?? ChatFriend(id: "", gamerTag: viewModel.displayName, profileImageUrl: nil, pokoId: nil, onlineStatus: .offline, currentGame: nil, channelId: nil, lastMessage: nil, lastMessageTime: nil, unreadCount: 0),
                onSend: { rival in Task { await viewModel.sendRivalInvite(rival) } }
            )
        }
        .sheet(isPresented: $viewModel.showGroupInfoSheet) {
            GroupInfoSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerPlaceholder { image in
                viewModel.selectedImage = image
                Task { await viewModel.sendImageMessage() }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: { Text(viewModel.error ?? "") }
        .task { await viewModel.loadMessages() }
    }
    
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
        }
    }
    
    private var headerInfo: some View {
        Button { if viewModel.isGroupChat { viewModel.openGroupInfo() } } label: {
            HStack(spacing: 10) {
                headerAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.displayName).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    headerSubtitle
                }
            }
        }
        .disabled(!viewModel.isGroupChat)
    }
    
    @ViewBuilder
    private var headerAvatar: some View {
        if viewModel.isGroupChat {
            groupHeaderAvatar
        } else {
            dmHeaderAvatar
        }
    }
    
    private var dmHeaderAvatar: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(colors: viewModel.friend?.bubbleGradient ?? [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 36, height: 36)
            .overlay(Text(viewModel.friend?.gamerTag.prefix(1).uppercased() ?? "?").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
    }
    
    private var groupHeaderAvatar: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: "person.3.fill").font(.system(size: 12)).foregroundColor(.white))
    }
    
    @ViewBuilder
    private var headerSubtitle: some View {
        if viewModel.isOtherUserTyping || !viewModel.typingUsers.isEmpty {
            Text("typing...").font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).italic()
        } else if viewModel.isGroupChat {
            let online = viewModel.onlineParticipantCount
            Text(online > 0 ? "\(online) online" : "\(viewModel.participants.count) members")
                .font(.system(size: 11)).foregroundColor(online > 0 ? Color(hex: "4CAF50") : .white.opacity(0.5))
        } else {
            HStack(spacing: 4) {
                Circle().fill(viewModel.friend?.onlineStatus.isActive == true ? Color(hex: "4CAF50") : Color.gray).frame(width: 6, height: 6)
                Text(viewModel.friend?.onlineStatus.displayText ?? "Offline")
                    .font(.system(size: 11)).foregroundColor(viewModel.friend?.onlineStatus.isActive == true ? Color(hex: "4CAF50") : .gray)
            }
        }
    }
    
    private var headerActions: some View {
        HStack(spacing: 12) {
            Button { viewModel.openRivalInvite() } label: {
                Text("⚔️").font(.system(size: 18)).frame(width: 36, height: 36).background(Color(hex: "FF6B6B").opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Menu {
                if viewModel.isGroupChat {
                    Button { viewModel.openGroupInfo() } label: { Label("Group Info", systemImage: "info.circle") }
                } else {
                    Button { } label: { Label("View Profile", systemImage: "person") }
                }
                Button { } label: { Label("Mute", systemImage: "bell.slash") }
                Divider()
                if viewModel.isGroupChat {
                    Button(role: .destructive) { Task { await viewModel.leaveGroup() } } label: { Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right") }
                } else {
                    Button(role: .destructive) { } label: { Label("Block", systemImage: "hand.raised") }
                }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 16, weight: .medium)).foregroundColor(.white).frame(width: 36, height: 36).background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if viewModel.isLoadingMore { ProgressView().tint(.white).padding() }
                    
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: viewModel.isMessageFromCurrentUser(message),
                            sender: viewModel.participant(for: message.senderId),
                            isGroupChat: viewModel.isGroupChat,
                            showSenderName: viewModel.shouldShowSenderName(for: message, at: index),
                            showAvatar: viewModel.shouldShowAvatar(for: message, at: index),
                            onRivalResponse: { response in Task { await viewModel.respondToRivalInvite(messageId: message.id, response: response) } }
                        )
                        .id(message.id)
                    }
                    
                    if viewModel.isOtherUserTyping { typingIndicatorView }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }
    
    private var typingIndicatorView: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in Circle().fill(Color.white.opacity(0.5)).frame(width: 6, height: 6) }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                Menu {
                    Button { viewModel.openImagePicker() } label: { Label("Photo", systemImage: "photo") }
                    Button { viewModel.openGifPicker() } label: { Label("GIF", systemImage: "gift") }
                    Button { viewModel.openRivalInvite() } label: { Label("Rival Invite", systemImage: "flame") }
                } label: {
                    Image(systemName: "plus").font(.system(size: 20, weight: .medium)).foregroundColor(.white).frame(width: 40, height: 40).background(Color.white.opacity(0.08)).clipShape(Circle())
                }
                
                HStack {
                    TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                        .font(.system(size: 15)).foregroundColor(.white).lineLimit(1...5).focused($isInputFocused)
                        .onChange(of: viewModel.messageText) { _, _ in viewModel.onTyping() }
                }
                .padding(.horizontal, 16).padding(.vertical, 10).background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button { Task { await viewModel.sendMessage() } } label: {
                    Image(systemName: "arrow.up").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.canSendMessage ? .white : .white.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .background(viewModel.canSendMessage ? LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.canSendMessage || viewModel.isSending)
            }
            .padding(.horizontal, 20).padding(.vertical, 12).padding(.bottom, 20).background(Color.black)
        }
    }
}

// MARK: - Message Bubble View (Supports both DM and Group)

struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let sender: ChatFriend?
    let isGroupChat: Bool
    let showSenderName: Bool
    let showAvatar: Bool
    let onRivalResponse: (RivalInviteResponse) -> Void
    
    // Bubble gradient for this sender
    private var senderGradient: [Color] {
        sender?.bubbleGradient ?? [Color(hex: "667eea"), Color(hex: "764ba2")]
    }
    
    var body: some View {
        // System messages
        if message.type == .system || message.type == .memberJoined || message.type == .memberLeft || message.type == .groupCreated || message.type == .groupRenamed {
            systemMessageView
        } else {
            regularMessageView
        }
    }
    
    private var systemMessageView: some View {
        HStack {
            Spacer()
            if case .system(let text) = message.content {
                Text(text)
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.white.opacity(0.05)).clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var regularMessageView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 60) }
            else {
                if isGroupChat {
                    if showAvatar { senderAvatarView } else { Color.clear.frame(width: 28, height: 28) }
                }
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Sender name for group chats
                if !isFromCurrentUser && showSenderName && isGroupChat {
                    Text(sender?.gamerTag ?? message.senderName ?? "Unknown")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(senderGradient.first ?? Color.white.opacity(0.6)))
                        .padding(.leading, 4)
                }
                
                messageContent
                
                Text(formatTime(message.timestamp)).font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
    
    private var senderAvatarView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: senderGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 28, height: 28)
            .overlay(Text(sender?.gamerTag.prefix(1).uppercased() ?? "?").font(.system(size: 12, weight: .bold)).foregroundColor(.white))
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.content {
        case .text(let text): textBubble(text)
        case .image(let data): imageBubble(data)
        case .gif(let data): gifBubble(data)
        case .rivalInvite(let rival): rivalInviteBubble(rival)
        case .system: EmptyView()
        }
    }
    
    private func textBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15)).foregroundColor(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                Group {
                    if isFromCurrentUser {
                        LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        // For group chats: colored left border accent
                        Color.white.opacity(0.08)
                    }
                }
            )
            .overlay(
                // Colored accent for other users in group chats
                !isFromCurrentUser && isGroupChat
                ? RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: senderGradient, startPoint: .top, endPoint: .bottom))
                    .frame(width: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                : nil
            )
            .clipShape(ChatBubbleShape(isFromCurrentUser: isFromCurrentUser))
    }
    
    private func imageBubble(_ imageData: ImageMessageData) -> some View {
        AsyncImage(url: URL(string: imageData.imageUrl)) { phase in
            switch phase {
            case .success(let image): image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 220, maxHeight: 280).clipShape(RoundedRectangle(cornerRadius: 16))
            default: RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)).frame(width: 200, height: 150).overlay(Image(systemName: "photo").font(.system(size: 30)).foregroundColor(.white.opacity(0.3)))
            }
        }
    }
    
    private func gifBubble(_ gifData: GifMessageData) -> some View {
        AsyncImage(url: URL(string: gifData.gifUrl)) { phase in
            if case .success(let image) = phase { image.resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 220).clipShape(RoundedRectangle(cornerRadius: 16)) }
            else { RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)).frame(width: 200, height: 150) }
        }
    }
    
    private func rivalInviteBubble(_ rival: RivalObj) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("⚔️").font(.system(size: 20))
                Text(isFromCurrentUser ? "You sent a Rival Invite" : "Rival Invite")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "FF6B6B")).textCase(.uppercase).tracking(1)
            }
            
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: rival.gameImageUrl)) { image in image.resizable().aspectRatio(contentMode: .fill) }
                placeholder: { RoundedRectangle(cornerRadius: 10).fill(Color(hex: "1a1a2e")) }
                .frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rival.game).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(rival.type).font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                }
            }
            
            if !rival.customMessage.isEmpty {
                Text("\"\(rival.customMessage)\"").font(.system(size: 13)).foregroundColor(.white.opacity(0.7)).italic()
            }
            
            if rival.rivalStatus == "proposed" && !isFromCurrentUser {
                HStack(spacing: 10) {
                    Button { onRivalResponse(.accept) } label: {
                        Text("Accept").font(.system(size: 13, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(hex: "4CAF50")).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button { onRivalResponse(.decline) } label: {
                        Text("Decline").font(.system(size: 13, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else if rival.rivalStatus == "proposed" {
                Text("Waiting for response...").font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                HStack {
                    Image(systemName: rival.rivalStatus == "accepted" ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundColor(rival.rivalStatus == "accepted" ? Color(hex: "4CAF50") : Color(hex: "FF6B6B"))
                    Text(rival.rivalStatus == "accepted" ? "Challenge Accepted!" : "Challenge Declined").font(.system(size: 12, weight: .medium)).foregroundColor(rival.rivalStatus == "accepted" ? Color(hex: "4CAF50") : Color(hex: "FF6B6B"))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8).background((rival.rivalStatus == "accepted" ? Color(hex: "4CAF50") : Color(hex: "FF6B6B")).opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16).frame(width: 280)
        .background(LinearGradient(colors: [Color(hex: "FF6B6B").opacity(0.2), Color(hex: "FF6B6B").opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18, tailRadius: CGFloat = 4
        var path = Path()
        if isFromCurrentUser {
            path.addRoundedRect(in: rect, cornerRadii: RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: tailRadius, topTrailing: radius))
        } else {
            path.addRoundedRect(in: rect, cornerRadii: RectangleCornerRadii(topLeading: radius, bottomLeading: tailRadius, bottomTrailing: radius, topTrailing: radius))
        }
        return path
    }
}

// MARK: - Group Info Sheet

struct GroupInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .overlay(Image(systemName: "person.3.fill").font(.system(size: 28)).foregroundColor(.white))
                            
                            Text(viewModel.displayName).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                            Text("\(viewModel.participants.count) members").font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Members
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MEMBERS").font(.system(size: 12, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.5))
                            
                            ForEach(viewModel.participants) { participant in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(colors: participant.bubbleGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 44, height: 44)
                                        .overlay(Text(participant.gamerTag.prefix(1).uppercased()).font(.system(size: 16, weight: .bold)).foregroundColor(.white))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(participant.gamerTag).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                                        Text(participant.onlineStatus.displayText).font(.system(size: 11)).foregroundColor(participant.onlineStatus.statusColor)
                                    }
                                    Spacer()
                                }
                                .padding(12).background(Color.white.opacity(0.03)).clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Leave button
                        Button { Task { await viewModel.leaveGroup(); dismiss() } } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Leave Group")
                            }
                            .font(.system(size: 15, weight: .medium)).foregroundColor(Color(hex: "FF6B6B"))
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color(hex: "FF6B6B").opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.foregroundColor(.white) }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Send Rival Invite Sheet

struct SendRivalInviteSheet: View {
    let friend: ChatFriend
    let onSend: (RivalObj) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGame = ""
    @State private var customMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("⚔️").font(.system(size: 48))
                        Text("Challenge \(friend.gamerTag)").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Game").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.6))
                        TextField("Game name", text: $selectedGame).font(.system(size: 15)).foregroundColor(.white).padding().background(Color.white.opacity(0.08)).cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a message (optional)").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.6))
                        TextField("e.g., Let's run some ranked!", text: $customMessage).font(.system(size: 15)).foregroundColor(.white).padding().background(Color.white.opacity(0.08)).cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        let rival = RivalObj(id: UUID().uuidString, gamerTag: friend.gamerTag, senderPokoId: "", getterPokoId: friend.pokoId ?? "", game: selectedGame, gameImageUrl: "", type: "Competitive", date: ISO8601DateFormatter().string(from: Date()), uid: friend.id, durationMin: 30, customMessage: customMessage, customResponse: "", rivalStatus: "proposed", createdAtMs: Int64(Date().timeIntervalSince1970 * 1000), expiresAtMs: Int64(Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000))
                        onSend(rival)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) { Text("⚔️"); Text("Send Challenge").font(.system(size: 16, weight: .semibold)) }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "ee5a5a")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                    }
                    .disabled(selectedGame.isEmpty).opacity(selectedGame.isEmpty ? 0.5 : 1)
                    .padding(.horizontal).padding(.bottom, 30)
                }
            }
            .navigationTitle("Rival Invite").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.white) } }
        }
    }
}

// MARK: - Image Picker Placeholder

struct ImagePickerPlaceholder: View {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("Image Picker").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("Replace with PHPickerViewController").font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
                }
            }
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}
