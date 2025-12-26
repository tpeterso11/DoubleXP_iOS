//
//  BottomMenuView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/14/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
// MARK: - View

public struct BottomMenuItem: Identifiable {
    public let id: String
    let title: String
    let systemIcon: String
}

// MARK: - Bottom Menu View
struct BottomMenuView: View {
    @Binding var selectedID: String

    let profileAvatarUrl: URL?
    @Binding var shouldAnimateProfileAvatar: Bool
    
    // Callbacks for fullScreenCover presentations
    var onDiscoverTapped: (() -> Void)? = nil
    var onMessagesTapped: (() -> Void)? = nil
    var onCompeteTapped: (() -> Void)? = nil // NEW: Compete/Challenges callback
    
    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.1)

            HStack {
                // MARK: - Home Tab
                bottomItem(
                    id: "home",
                    systemName: "house.fill",
                    title: "Home"
                )

                Spacer()

                // MARK: - Discover Button (fullScreenCover)
                overlayItem(
                    systemName: "sparkles",
                    title: "Discover",
                    onTap: { onDiscoverTapped?() }
                )

                Spacer()

                // MARK: - Compete/Challenges Button (fullScreenCover)
                overlayItem(
                    systemName: "trophy.fill",
                    title: "Compete",
                    onTap: { onCompeteTapped?() }
                )

                Spacer()

                // MARK: - Messages / Chat Button (fullScreenCover)
                overlayItem(
                    systemName: "bubble.left.and.bubble.right.fill",
                    title: "Chat",
                    onTap: { onMessagesTapped?() }
                )

                Spacer()

                // MARK: - Profile Tab
                ProfileTabIconView(
                    isSelected: selectedID == "profile",
                    avatarUrl: profileAvatarUrl,
                    title: "Profile",
                    shouldAnimateOnAppear: $shouldAnimateProfileAvatar
                )
                .onTapGesture {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selectedID = "profile"
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(
                Color(.systemBackground)
                    .opacity(0.95)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // MARK: - Overlay Item (for fullScreenCover presentations)
    
    @ViewBuilder
    private func overlayItem(systemName: String, title: String, onTap: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.secondary)

            Text(title)
                .font(.caption2)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    // MARK: - Standard Tab Item Helper

    @ViewBuilder
    private func bottomItem(id: String, systemName: String, title: String) -> some View {
        let isSelected = (selectedID == id)

        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .symbolVariant(isSelected ? .fill : .none)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .foregroundColor(isSelected ? .primary : .secondary)

            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedID = id
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Profile Tab Icon View

struct ProfileTabIconView: View {
    let isSelected: Bool
    let avatarUrl: URL?
    let title: String

    @Binding var shouldAnimateOnAppear: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))

                if let url = avatarUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().scaleEffect(0.6)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackImage
                        @unknown default:
                            fallbackImage
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackImage
                }
            }
            .frame(width: 34, height: 34)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                runPopInIfNeeded()
            }

            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }

    private var fallbackImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.gray)
            .clipShape(Circle())
    }

    private func runPopInIfNeeded() {
        guard shouldAnimateOnAppear else {
            scale = 1.0
            opacity = 1.0
            return
        }

        scale = 0.4
        opacity = 0.0

        withAnimation(.spring(response: 0.5, dampingFraction: 0.55, blendDuration: 0.1)) {
            scale = 1.05
            opacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                scale = 1.0
            }
        }

        shouldAnimateOnAppear = false
    }
}
