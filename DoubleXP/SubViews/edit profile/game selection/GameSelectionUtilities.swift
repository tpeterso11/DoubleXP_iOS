//
//  GameSelectionUtilities.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Cached Async Image

/// A SwiftUI wrapper around ImageCache that provides cached image loading
struct GameSelectionCachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    
    var body: some View {
        content(phase)
            .task(id: url) {
                await loadImage()
            }
    }
    
    private func loadImage() async {
        guard let url = url else {
            phase = .failure(URLError(.badURL))
            return
        }
        
        // Set to empty/loading state
        phase = .empty
        
        if let cachedImage = await ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cachedImage))
        } else {
            phase = .failure(URLError(.cannotLoadFromNetwork))
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 3))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Game Selection Colors

enum GameSelectionColors {
    static let background = Color(hex: "0a0a0a")
    static let backgroundGradientStart = Color(hex: "0f0a1a")
    static let backgroundGradientEnd = Color(hex: "08080c")
    static let cardBackground = Color(hex: "141414")
    static let coralStart = Color(hex: "FF6B6B")
    static let coralEnd = Color(hex: "FF8E53")
    static let greenStart = Color(hex: "4CD964")
    static let greenEnd = Color(hex: "2ECC71")
    static let skeletonBase = Color(hex: "1a1a1a")
    static let skeletonHighlight = Color(hex: "2a2a2a")
}

// MARK: - GamerConnectGame Display Helpers

extension GamerConnectGame {
    /// Returns the best available image URL for display
    var displayImageURL: URL? {
        // Prefer imageUrl, then cover url, then alternateImageUrl
        if let imageUrl = imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            return url
        }
        if let coverUrl = cover?.url, let url = URL(string: coverUrl) {
            return url
        }
        if let altUrl = alternateImageUrl, !altUrl.isEmpty, let url = URL(string: altUrl) {
            return url
        }
        return nil
    }
    
    /// Returns genre names as strings for display
    var genreNames: [String] {
        // Use categoryFilters first, then fall back to genres struct
        if !categoryFilters.isEmpty {
            return categoryFilters
        }
        if let genres = genres {
            return genres.compactMap { $0.name }
        }
        if let gameType = gameType {
            return [gameType]
        }
        return []
    }
}
