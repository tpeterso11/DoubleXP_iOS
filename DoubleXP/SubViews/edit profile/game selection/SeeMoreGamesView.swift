//
//  SeeMoreGamesView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// Note: GameSelectionColors, CachedAsyncImage, ScaleButtonStyle, and Color extension
// are defined in GameSelectionUtilities.swift

// MARK: - See More Games View

struct SeeMoreGamesView: View {
    @StateObject private var viewModel = SeeMoreGamesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var onGameSelected: ((GamerConnectGame) -> Void)?
    var selectedGameIDs: Set<String> = []
    
    var body: some View {
        ZStack {
            GameSelectionColors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasError {
                errorView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(GameGenre.allCases.filter { $0 != .all }, id: \.self) { genre in
                            if let games = viewModel.gamesByGenre[genre], !games.isEmpty {
                                genreSection(genre: genre, games: games)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Browse Games")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(GameSelectionColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.loadAllGames()
        }
    }
    
    // MARK: - Genre Section
    
    private func genreSection(genre: GameGenre, games: [GamerConnectGame]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(genre.emoji)
                    .font(.system(size: 20))
                
                Text(genre.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(games.count) games")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            
            // Horizontal scroll of games
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(games) { game in
                        SeeMoreGameCard(
                            game: game,
                            isSelected: selectedGameIDs.contains(game.id),
                            onTap: { onGameSelected?(game) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: GameSelectionColors.coralStart))
                .scaleEffect(1.5)
            
            Text("Loading games...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(GameSelectionColors.coralStart)
            
            Text("Couldn't load games")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Button(action: {
                Task { await viewModel.loadAllGames() }
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - See More Game Card

struct SeeMoreGameCard: View {
    let game: GamerConnectGame
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Game cover
                GameSelectionCachedAsyncImage(url: game.displayImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 120, height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Selection indicator
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(GameSelectionColors.coralStart)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -8, y: 8)
                }
                
                // Name overlay
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .overlay(
                        Text(game.gameName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                        , alignment: .bottom
                    )
                }
            }
            .frame(width: 120, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? GameSelectionColors.coralStart : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? GameSelectionColors.coralStart.opacity(0.3) : .black.opacity(0.2),
                    radius: isSelected ? 12 : 8,
                    y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - See More Games View Model

@MainActor
class SeeMoreGamesViewModel: ObservableObject {
    @Published var gamesByGenre: [GameGenre: [GamerConnectGame]] = [:]
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    
    func loadAllGames() async {
        isLoading = true
        hasError = false
        
        do {
            let games = try await GameRequestManager.shared.fetchAllGamesByGenre(limit: 15)
            
            // Save all games to storage
            for (_, genreGames) in games {
                GameStorageManager.shared.save(games: genreGames)
            }
            
            gamesByGenre = games
        } catch {
            hasError = true
        }
        
        isLoading = false
    }
}
