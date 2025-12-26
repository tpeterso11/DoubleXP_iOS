//
//  GameSearchSheet.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// Note: GameSelectionColors, CachedAsyncImage, and Color extension
// are defined in GameSelectionUtilities.swift

// MARK: - Game Search Sheet

struct GameSearchSheet: View {
    @ObservedObject var viewModel: GameSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [GamerConnectGame] = []
    @State private var hasSearched: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                GameSelectionColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search input
                    searchInputSection
                    
                    // Content
                    if isSearching {
                        searchLoadingView
                    } else if hasSearched && searchResults.isEmpty {
                        noResultsView
                    } else if !searchResults.isEmpty {
                        searchResultsList
                    } else {
                        searchPromptView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Search Games")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(GameSelectionColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - Search Input Section
    
    private var searchInputSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.4))
            
            TextField("Search for a game...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Button(action: performSearch) {
                Text("Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart, GameSelectionColors.coralEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .opacity(searchText.isEmpty ? 0.5 : 1)
            .disabled(searchText.isEmpty)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Search Loading View
    
    private var searchLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: GameSelectionColors.coralStart))
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
        }
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No games found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Try searching with a different term")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
        }
    }
    
    // MARK: - Search Prompt View
    
    private var searchPromptView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            
            Text("Search for your favorite games")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            // Popular searches
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Searches")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)
                
                SearchSheetFlowLayout(spacing: 8) {
                    ForEach(popularSearches, id: \.self) { term in
                        Button(action: {
                            searchText = term
                            performSearch()
                        }) {
                            Text(term)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { game in
                    SearchResultRow(
                        game: game,
                        isSelected: viewModel.selectedGames.contains { $0.id == game.id },
                        onSelect: {
                            if viewModel.selectedGames.contains(where: { $0.id == game.id }) {
                                viewModel.removeSelectedGame(game)
                            } else {
                                viewModel.selectGame(game)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helpers
    
    private var popularSearches: [String] {
        ["Valorant", "Fortnite", "Minecraft", "League of Legends", "GTA", "Call of Duty", "FIFA", "Apex"]
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        hasSearched = true
        
        Task {
            do {
                let results = try await GameRequestManager.shared.searchGames(query: searchText)
                searchResults = results
                
                // Also update the main viewModel
                viewModel.searchQuery = searchText
                viewModel.isSearching = true
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let game: GamerConnectGame
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Game cover
                GameSelectionCachedAsyncImage(url: game.displayImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        LinearGradient(
                            colors: [GameSelectionColors.coralStart.opacity(0.5), GameSelectionColors.coralEnd.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Game info
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.gameName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if !game.genreNames.isEmpty {
                        Text(game.genreNames.prefix(2).joined(separator: " • "))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? GameSelectionColors.coralStart : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        Circle()
                            .fill(GameSelectionColors.coralStart)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? GameSelectionColors.coralStart.opacity(0.1) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? GameSelectionColors.coralStart.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout

private struct SearchSheetFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
