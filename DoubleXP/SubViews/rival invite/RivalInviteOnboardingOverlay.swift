//
//  RivalInviteOnboardingOverlay.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Rival Invite Onboarding Overlay

struct RivalInviteOnboardingOverlay: View {
    
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var showContent = false
    
    private let totalPages = 3
    
    // Colors
    private let challengeColor = Color(red: 1.0, green: 0.42, blue: 0.42) // #FF6B6B
    private let teamUpColor = Color(red: 0.3, green: 0.69, blue: 0.31) // #4CAF50
    private let player1Color = Color(red: 0.31, green: 0.67, blue: 0.99) // #4facfe
    private let player2Color = Color(red: 0.94, green: 0.58, blue: 0.98) // #f093fb
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Page Content
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    addFriendPage
                        .tag(1)
                    
                    switchModePage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 500)
                
                Spacer()
                
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Action Button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [challengeColor, player2Color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [challengeColor.opacity(0.3), teamUpColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                HStack(spacing: 0) {
                    Text("⚔️")
                        .font(.system(size: 40))
                    Text("🤝")
                        .font(.system(size: 40))
                }
            }
            
            VStack(spacing: 12) {
                Text("Rival Invites")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Challenge friends to epic 1v1 battles\nor team up for co-op adventures!")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Feature highlights
            VStack(spacing: 16) {
                featureRow(icon: "⚡️", text: "Instant notifications to your friends")
                featureRow(icon: "🎮", text: "Choose any game from your library")
                featureRow(icon: "📅", text: "Schedule matches for later")
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Page 2: Add Friend
    
    private var addFriendPage: some View {
        VStack(spacing: 24) {
            // Illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(player2Color.opacity(0.2))
                    .blur(radius: 30)
                    .frame(width: 150, height: 150)
                
                // Player cards mockup
                HStack(spacing: -20) {
                    // Your card
                    playerMockup(initial: "Y", color: player1Color, label: "You")
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .zIndex(1)
                    
                    // Friend card with tap indicator
                    ZStack {
                        playerMockup(initial: "?", color: player2Color, label: "Friend")
                        
                        // Tap indicator
                        tapIndicator
                            .offset(x: 30, y: -30)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text("Add a Friend")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Tap the Player 2 avatar to select\na friend from your list")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Tip box
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                
                Text("Friends who are online will appear at the top of your list")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
    
    private func playerMockup(initial: String, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(initial)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var tapIndicator: some View {
        ZStack {
            // Ripple circles
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.white.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                    .frame(width: CGFloat(30 + i * 15), height: CGFloat(30 + i * 15))
            }
            
            // Hand icon
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Page 3: Switch Mode
    
    private var switchModePage: some View {
        VStack(spacing: 24) {
            // Mode toggle mockup
            VStack(spacing: 20) {
                // Challenge mode
                modeMockup(
                    icon: "⚔️",
                    title: "Challenge",
                    subtitle: "1v1 battles",
                    color: challengeColor,
                    isActive: true
                )
                
                // Toggle arrow
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                // Team up mode
                modeMockup(
                    icon: "🤝",
                    title: "Team Up",
                    subtitle: "Co-op play",
                    color: teamUpColor,
                    isActive: false
                )
            }
            
            VStack(spacing: 12) {
                Text("Switch Modes")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Tap the mode banner to switch between\nChallenge and Team Up modes")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Mode descriptions
            VStack(spacing: 12) {
                modeDescriptionRow(
                    icon: "⚔️",
                    title: "Challenge Mode",
                    description: "Competitive 1v1 matches",
                    color: challengeColor
                )
                
                modeDescriptionRow(
                    icon: "🤝",
                    title: "Team Up Mode",
                    description: "Cooperative gameplay together",
                    color: teamUpColor
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
    
    private func modeMockup(icon: String, title: String, subtitle: String, color: Color, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isActive ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .padding(.horizontal, 40)
    }
    
    private func modeDescriptionRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(icon)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}