//
//  RivalInviteDrawerView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Rival Invite Drawer View (Style 2: Video Game VS Screen)

struct RivalInviteDrawerView: View {
    
    @StateObject private var viewModel: RivalInviteViewModel
    @Binding var isPresented: Bool
    
    // Animation states
    @State private var dragOffset: CGFloat = 0
    @State private var showContent = false
    
    // Colors
    private var challengeColor: Color { Color(red: 1.0, green: 0.42, blue: 0.42) } // #FF6B6B
    private var teamUpColor: Color { Color(red: 0.3, green: 0.69, blue: 0.31) } // #4CAF50
    private var player1Color: Color { Color(red: 0.31, green: 0.67, blue: 0.99) } // #4facfe
    private var player2Color: Color { Color(red: 0.94, green: 0.58, blue: 0.98) } // #f093fb
    
    private var accentColor: Color {
        viewModel.mode == .challenge ? challengeColor : teamUpColor
    }
    
    init(isPresented: Binding<Bool>, preselectedRecipient: RivalRecipient? = nil) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: RivalInviteViewModel(preselectedRecipient: preselectedRecipient))
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            // Drawer
            VStack(spacing: 0) {
                Spacer()
                
                drawerContent
                    .background(drawerBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
                    .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Onboarding overlay
            if viewModel.showOnboarding {
                RivalInviteOnboardingOverlay(
                    onComplete: { viewModel.completeOnboarding() }
                )
                .transition(.opacity)
            }
            
            // Success overlay
            if let result = viewModel.sendResult, result.isSuccess {
                successOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.showOnboarding)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.sendResult?.isSuccess)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
            Task {
                await viewModel.loadInitialData()
            }
        }
        .sheet(isPresented: $viewModel.showFriendPicker) {
            FriendPickerSheet(
                friends: viewModel.availableFriends,
                selectedFriend: viewModel.selectedRecipient,
                onSelect: { viewModel.selectRecipient($0) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showGamePicker) {
            GamePickerSheet(
                games: viewModel.availableGames,
                selectedGame: viewModel.selectedGame,
                onSelect: { viewModel.selectGame($0) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Drawer Content
    
    private var drawerContent: some View {
        VStack(spacing: 0) {
            // Handle
            drawerHandle
            
            // VS Header with Players
            vsHeader
            
            // Mode Label
            modeLabel
            
            // Game Selection
            gameSelectionCard
            
            // Config Options
            configRow
            
            // Action Button
            actionButton
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Drawer Handle
    
    private var drawerHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.2))
            .frame(width: 40, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    // MARK: - VS Header
    
    private var vsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Player 1 (Current User)
                playerCard(
                    label: "Player 1",
                    labelColor: player1Color,
                    avatarColor: player1Color,
                    initial: viewModel.currentUserInitial,
                    name: viewModel.currentUserGamerTag,
                    tag: "@\(viewModel.currentUserGamerTag)",
                    isPlayer1: true
                )
                
                // VS / + Symbol
                vsSymbol
                
                // Player 2 (Recipient)
                playerCard(
                    label: "Player 2",
                    labelColor: player2Color,
                    avatarColor: player2Color,
                    initial: viewModel.selectedRecipient?.avatarInitial ?? "?",
                    name: viewModel.selectedRecipient?.gamerTag ?? "Select Friend",
                    tag: viewModel.selectedRecipient != nil ? "@\(viewModel.selectedRecipient!.gamerTag)" : "Tap to choose",
                    isPlayer1: false
                )
                .onTapGesture {
                    viewModel.showFriendPicker = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func playerCard(
        label: String,
        labelColor: Color,
        avatarColor: Color,
        initial: String,
        name: String,
        tag: String,
        isPlayer1: Bool
    ) -> some View {
        VStack(spacing: 8) {
            // Label
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(labelColor)
                .textCase(.uppercase)
            
            // Avatar
            ZStack {
                // Glow
                Circle()
                    .fill(avatarColor.opacity(0.4))
                    .blur(radius: 15)
                    .frame(width: 70, height: 70)
                
                // Avatar
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isPlayer1 
                                ? [player1Color, Color(red: 0, green: 0.95, blue: 0.99)]
                                : [player2Color, Color(red: 0.96, green: 0.34, blue: 0.42)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: avatarColor.opacity(0.4), radius: 15, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(avatarColor.opacity(0.3), lineWidth: 2)
                            .padding(-4)
                    )
                    .overlay(
                        Text(initial)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                    )
            }
            
            // Name
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Tag
            Text(tag)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var vsSymbol: some View {
        ZStack {
            // Glow
            Circle()
                .fill(accentColor.opacity(0.3))
                .blur(radius: 20)
                .frame(width: 60, height: 60)
            
            // Symbol
            Text(viewModel.modeSymbol)
                .font(.system(size: 36, weight: .black))
                .foregroundColor(accentColor)
                .shadow(color: accentColor.opacity(0.6), radius: 15, x: 0, y: 0)
        }
    }
    
    // MARK: - Mode Label
    
    private var modeLabel: some View {
        HStack(spacing: 6) {
            Text(viewModel.mode.icon)
            Text(viewModel.mode.modeLabel)
                .font(.system(size: 12, weight: .bold))
                .tracking(3)
                .textCase(.uppercase)
        }
        .foregroundColor(accentColor)
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(accentColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.bottom, 16)
        .onTapGesture {
            viewModel.toggleMode()
        }
    }
    
    // MARK: - Game Selection Card
    
    private var gameSelectionCard: some View {
        Button {
            viewModel.showGamePicker = true
        } label: {
            HStack(spacing: 14) {
                // Game Image
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.1), Color(white: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Group {
                            if let game = viewModel.selectedGame, let urlString = game.imageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.title2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            } else {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Game Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedGame?.name ?? "Select Game")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(viewModel.selectedGame?.genreDisplay ?? "Tap to choose")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Change Button
                Text("Select")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.15))
                    )
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Config Row
    
    private var configRow: some View {
        HStack(spacing: 12) {
            // Platform
            configItem(
                label: "Platform",
                value: viewModel.selectedPlatform.shortName,
                icon: viewModel.selectedPlatform.icon
            ) {
                viewModel.showPlatformPicker = true
            }
            .confirmationDialog("Select Platform", isPresented: $viewModel.showPlatformPicker) {
                ForEach(RivalPlatform.allCases) { platform in
                    Button("\(platform.icon) \(platform.displayName)") {
                        viewModel.selectPlatform(platform)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            
            // When
            configItem(
                label: "When",
                value: viewModel.selectedTiming.displayName,
                icon: viewModel.selectedTiming.icon
            ) {
                viewModel.showTimingPicker = true
            }
            .confirmationDialog("Select Time", isPresented: $viewModel.showTimingPicker) {
                ForEach(RivalTiming.allCases) { timing in
                    Button("\(timing.icon) \(timing.displayName)") {
                        viewModel.selectTiming(timing)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func configItem(label: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                
                HStack(spacing: 4) {
                    Text(icon)
                        .font(.system(size: 14))
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("▼")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            Task {
                await viewModel.sendInvite()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(viewModel.actionButtonText)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if viewModel.canSend {
                        LinearGradient(
                            colors: viewModel.mode == .challenge 
                                ? [challengeColor, challengeColor.opacity(0.8)]
                                : [teamUpColor, teamUpColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: viewModel.canSend ? accentColor.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
            // Shimmer effect
            .overlay(
                shimmerOverlay
                    .opacity(viewModel.canSend && !viewModel.isSending ? 1 : 0)
            )
        }
        .disabled(!viewModel.canSend)
        .padding(.horizontal, 20)
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.2),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.5)
            .offset(x: -geometry.size.width * 0.25)
            .mask(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Drawer Background
    
    private var drawerBackground: some View {
        ZStack {
            // Base color
            Color(red: 0.04, green: 0.04, blue: 0.07) // #0a0a12
            
            // Top border
            VStack {
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 3)
                Spacer()
            }
        }
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentColor)
                }
                
                Text(viewModel.mode == .challenge ? "Challenge Sent!" : "Invite Sent!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                if let recipient = viewModel.selectedRecipient {
                    Text("Waiting for \(recipient.gamerTag) to respond")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 100 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Dismiss
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            isPresented = false
        }
    }
}