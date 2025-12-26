//
//  RivalInvitePickerSheers.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI

// MARK: - Friend Picker Sheet

struct FriendPickerSheet: View {
    
    let friends: [RivalRecipient]
    let selectedFriend: RivalRecipient?
    let onSelect: (RivalRecipient) -> Void
    
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredFriends: [RivalRecipient] {
        if searchText.isEmpty {
            return friends.sorted { lhs, rhs in
                // Online friends first
                if lhs.isOnline != rhs.isOnline {
                    return lhs.isOnline
                }
                return lhs.gamerTag.lowercased() < rhs.gamerTag.lowercased()
            }
        }
        return friends.filter { $0.gamerTag.lowercased().contains(searchText.lowercased()) }
    }
    
    private var onlineFriends: [RivalRecipient] {
        filteredFriends.filter { $0.isOnline }
    }
    
    private var offlineFriends: [RivalRecipient] {
        filteredFriends.filter { !$0.isOnline }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search bar
                        searchBar
                        
                        if filteredFriends.isEmpty {
                            emptyState
                        } else {
                            // Online Section
                            if !onlineFriends.isEmpty {
                                friendSection(title: "Online", friends: onlineFriends, showOnlineIndicator: true)
                            }
                            
                            // Offline Section
                            if !offlineFriends.isEmpty {
                                friendSection(title: "Offline", friends: offlineFriends, showOnlineIndicator: false)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Search friends...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func friendSection(title: String, friends: [RivalRecipient], showOnlineIndicator: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                
                if showOnlineIndicator {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                Text("(\(friends.count))")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(spacing: 8) {
                ForEach(friends) { friend in
                    friendRow(friend)
                }
            }
        }
    }
    
    private func friendRow(_ friend: RivalRecipient) -> some View {
        let isSelected = selectedFriend?.id == friend.id
        
        return Button {
            onSelect(friend)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: Double(friend.gamerTag.hashValue % 100) / 100, saturation: 0.6, brightness: 0.8),
                                    Color(hue: Double(friend.gamerTag.hashValue % 100) / 100, saturation: 0.8, brightness: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(friend.avatarInitial)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    // Online indicator
                    if friend.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 3, y: 3)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.gamerTag)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(friend.isOnline ? (friend.onlineStatus == "in_game" ? "In Game" : "Online") : "Offline")
                        .font(.system(size: 13))
                        .foregroundColor(friend.isOnline ? .green : .white.opacity(0.5))
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.94, green: 0.58, blue: 0.98))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color(red: 0.94, green: 0.58, blue: 0.98).opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No friends found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Game Picker Sheet

struct GamePickerSheet: View {
    
    let games: [RivalGame]
    let selectedGame: RivalGame?
    let onSelect: (RivalGame) -> Void
    
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredGames: [RivalGame] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Search bar
                        searchBar
                        
                        if filteredGames.isEmpty {
                            emptyState
                        } else {
                            // Games grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(filteredGames) { game in
                                    gameCard(game)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Search games...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func gameCard(_ game: RivalGame) -> some View {
        let isSelected = selectedGame?.id == game.id
        
        return Button {
            onSelect(game)
            dismiss()
        } label: {
            VStack(spacing: 10) {
                // Game image
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.12), Color(white: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Group {
                            if let urlString = game.imageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    gameImagePlaceholder
                                }
                            } else {
                                gameImagePlaceholder
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .overlay(
                        // Selection checkmark
                        Group {
                            if isSelected {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                                            .background(Circle().fill(Color.black))
                                            .padding(8)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                
                // Game info
                VStack(spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(game.genreDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var gameImagePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No games found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
