//
//  FeedStructs.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/25/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI

struct FeedHeader: Hashable {
    let id: String
}

struct StatusBar: View {
    let hearts: Int // Number of filled hearts (0-4)
    let newFollowers: Int
    let newMessages: Int
    let newInvites: Int
    
    var onFollowersTap: () -> Void = {}
    var onMessagesTap: () -> Void = {}
    var onInvitesTap: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Hearts pill
            /*HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    PixelHeart(isFilled: index < hearts)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.62).opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(red: 1.0, green: 0.42, blue: 0.62).opacity(0.3), lineWidth: 1)
                    )
            )*/
            
            Spacer()
            
            // Right: Notifications pill
            HStack(spacing: 4) {
                NotificationButton(
                    icon: "person.2.fill",
                    count: newFollowers,
                    action: onFollowersTap
                )
                
                NotificationButton(
                    icon: "message.fill",
                    count: newMessages,
                    action: onMessagesTap
                )
                
                NotificationButton(
                    icon: "gamecontroller.fill",
                    count: newInvites,
                    action: onInvitesTap
                )
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            // Dark glassmorphic background - more translucent
            ZStack {
                // Blur effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Dark tint overlay - reduced opacity for more transparency
                Color.black.opacity(0.4)
            }
        )
        .overlay(
            // Bottom border only
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Notification Button Component

struct NotificationButton: View {
    let icon: String
    let count: Int
    let action: () -> Void
    
    private var hasNotifications: Bool {
        count > 0
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(hasNotifications ? 1.0 : 0.4))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(hasNotifications ? Color.white.opacity(0.15) : Color.clear)
                    )
                
                if hasNotifications {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
