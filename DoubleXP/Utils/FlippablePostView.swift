//
//  FlippablePostView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import Foundation

struct FlippablePostView: View {
    let manager: FlippableViewManager
    
    // State to track if the card is flipped
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // The two card faces are layered in a ZStack
            PostCardFront(manager: manager).modifier(FlipModifier(isFlipped: isFlipped, rotation: 0))
            PostCardBack(manager: manager).modifier(FlipModifier(isFlipped: isFlipped, rotation: -180))
        }
        .onTapGesture {
            // Animate the flip when tapped
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        .frame(height: 300) // Set a consistent height for the flippable area
    }
}

struct PlaceholderImageView: View {
    let symbolName: String
    let color: Color

    var body: some View {
        ZStack {
            color
            Image(systemName: symbolName)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct PostMetadataView: View {
    let iconName: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(.gray)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
    }
}
