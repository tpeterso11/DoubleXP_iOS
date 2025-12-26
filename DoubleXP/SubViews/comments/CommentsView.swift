//
//  CommentsView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct CommentsView: View {
    @StateObject private var viewModel: CommentsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var inputText: String = ""
    @State private var replyingTo: CommentModel? = nil
    @FocusState private var isInputFocused: Bool
    
    // For navigating to Profile
    @State private var profileUserId: String?
    
    init(mediaId: String, mediaType: MediaType = .article, authorId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(mediaId: mediaId, mediaType: mediaType, authorId: authorId))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [Color.indigo.opacity(0.15), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                
                if viewModel.isLoading {
                    ProgressView().tint(.white).frame(maxHeight: .infinity)
                } else if viewModel.comments.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.comments) { comment in
                                CommentThreadView(comment: comment, viewModel: viewModel, onReply: { parent in
                                    replyingTo = parent
                                    isInputFocused = true
                                }, onProfileTap: { uid in
                                    profileUserId = uid
                                })
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            
            VStack {
                Spacer()
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        // Wrapper for UserProfileView presentation
        .sheet(item: Binding<ProfilePresentation?>(
            get: { profileUserId.map { ProfilePresentation(uid: $0) } },
            set: { profileUserId = $0?.uid }
        )) { item in
            UserProfileView(uid: item.uid)
        }
    }
    
    private struct ProfilePresentation: Identifiable {
        let uid: String
        var id: String { uid }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Comments")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                let total = viewModel.comments.reduce(0) { $0 + 1 + $1.replies.count }
                
                Text("\(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.05)), alignment: .bottom)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text("No comments yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Be the first to start the conversation!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            if let replyTarget = replyingTo {
                HStack {
                    Text("Replying to")
                        .foregroundStyle(.gray)
                        .font(.caption)
                    Text(replyTarget.userName)
                        .foregroundStyle(.white)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Button {
                        replyingTo = nil
                    } label: {
                        Image(systemName: "xmark").font(.caption).foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                AsyncImage(url: URL(string: PokoProvider.shared.userSelectedPoko?.headshotUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.zinc800
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                
                HStack {
                    TextField("", text: $inputText, prompt: Text("Add a comment...").foregroundColor(.gray))
                        .foregroundStyle(.white)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            submitComment()
                        }
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                Button(action: submitComment) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: .indigo.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1)
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.1)), alignment: .top)
        }
    }
    
    private func submitComment() {
        guard !inputText.isEmpty else { return }
        viewModel.sendComment(text: inputText, replyingTo: replyingTo)
        inputText = ""
        replyingTo = nil
        isInputFocused = false
    }
}

// MARK: - Component Views

struct CommentThreadView: View {
    let comment: CommentModel
    @ObservedObject var viewModel: CommentsViewModel
    let onReply: (CommentModel) -> Void
    let onProfileTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommentRow(comment: comment, isReply: false, viewModel: viewModel, onReply: onReply, onProfileTap: onProfileTap)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(comment.replies) { reply in
                        CommentRow(comment: reply, isReply: true, viewModel: viewModel, onReply: onReply, onProfileTap: onProfileTap)
                    }
                }
                .padding(.leading, 12)
                .padding(.vertical, 8)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 2)
                        .padding(.vertical, 4),
                    alignment: .leading
                )
                .padding(.leading, 26)
                .padding(.trailing, 20)
            }
            
            Divider().background(Color.white.opacity(0.05))
                .padding(.leading, 20)
        }
    }
}

struct CommentRow: View {
    let comment: CommentModel
    let isReply: Bool
    @ObservedObject var viewModel: CommentsViewModel
    let onReply: (CommentModel) -> Void
    let onProfileTap: (String) -> Void
    
    let myGames: [String] = ["Baldur's Gate 3", "Elden Ring", "Overwatch 2"]
    let myLocation: (lat: Double, long: Double) = (37.7749, -122.4194)
    
    var isCurrentUser: Bool {
        comment.userId == viewModel.currentUserId
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onProfileTap(comment.userId)
            } label: {
                AsyncImage(url: URL(string: comment.userAvatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.zinc800
                }
                .frame(width: isReply ? 32 : 40, height: isReply ? 32 : 40)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    // OP Badge - Dynamic Check
                    if let authorId = viewModel.authorId, comment.userId == authorId {
                        Text("OP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.indigo.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text(timeAgo(date: Date(timeIntervalSince1970: comment.timestamp)))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    // Logic: Hide "Near You" if it's me
                    if !isCurrentUser && isNearMe(lat: comment.userLatitude, long: comment.userLongitude) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 8))
                            Text("Near You")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.blue.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                    } else if let userGames = comment.userGames {
                        let commonCount = Set(userGames).intersection(myGames).count
                        if commonCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 8))
                                Text("\(commonCount) common")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(Color.green.opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Text(comment.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                
                HStack(spacing: 16) {
                    Button {
                        viewModel.toggleLike(for: comment)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLikedByMe ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(comment.isLikedByMe ? .pink : .gray)
                            
                            if comment.likeCount > 0 {
                                Text("\(comment.likeCount)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(comment.isLikedByMe ? .pink : .gray)
                            }
                        }
                    }
                    
                    Button {
                        onReply(comment)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 12))
                            Text("Reply")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.gray)
                    }
                }
                .padding(.top, 4)
            }
        }
        // Highlight logic: Light highlight for current user
        .padding(8) // Add padding so background doesn't hug text too tight
        .background(
            isCurrentUser ? Color.indigo.opacity(0.1) : Color.clear
        )
        .cornerRadius(12)
        // Reset padding for non-highlighted rows so alignment stays consistent
        .padding(.horizontal, isCurrentUser ? 0 : 8)
    }
    
    func isNearMe(lat: Double?, long: Double?) -> Bool {
        guard let lat = lat, let long = long else { return false }
        let latDiff = abs(lat - myLocation.lat)
        let longDiff = abs(long - myLocation.long)
        return latDiff < 0.1 && longDiff < 0.1
    }
    
    func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
