//
//  PlayerSearchViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Player Search ViewModel

@MainActor
class PlayerSearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Search State
    @Published var searchMode: PlayerSearchMode = .games
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var isSearchFocused: Bool = false
    
    // User's Games
    @Published var userGames: [UserGameTile] = []
    @Published var isLoadingGames: Bool = false
    @Published var hasGames: Bool = false
    
    // Selected Game (for player search within a game)
    @Published var selectedGame: UserGameTile? = nil
    @Published var isInGamePlayerSearch: Bool = false
    
    // Player Results
    @Published var playerResults: [PlayerSearchResult] = []
    @Published var isLoadingPlayers: Bool = false
    @Published var playersNextCursor: String? = nil
    @Published var hasMorePlayers: Bool = false
    
    // Game Search Results (IGDB)
    @Published var gameSearchResults: [GameSearchResult] = []
    @Published var isLoadingGameSearch: Bool = false
    
    // Online Counts
    @Published var onlineCounts: [String: Int] = [:]
    
    // Error State
    @Published var error: PlayerSearchError? = nil
    @Published var showError: Bool = false
    
    // MARK: - Private Properties
    
    private let requestManager = PlayerSearchRequestManager.shared
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var showEmptyState: Bool {
        !hasGames && !isLoadingGames
    }
    
    var showUserGames: Bool {
        hasGames && !isInGamePlayerSearch && searchText.isEmpty
    }
    
    var showSearchResults: Bool {
        !searchText.isEmpty || isInGamePlayerSearch
    }
    
    var currentGameName: String {
        selectedGame?.name ?? "All Games"
    }
    
    var searchPlaceholder: String {
        if isInGamePlayerSearch, let game = selectedGame {
            return "Search \(game.name) players..."
        }
        return searchMode.placeholder
    }
    
    // MARK: - Initialization
    
    init() {
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        // Debounce search input to avoid excessive API calls
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                
                if query.isEmpty {
                    // Clear results when search is empty
                    if !self.isInGamePlayerSearch {
                        self.playerResults = []
                        self.gameSearchResults = []
                    }
                } else {
                    Task {
                        await self.performSearch(query: query)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load initial data (user's games)
    func loadInitialData() async {
        isLoadingGames = true
        
        // Get user's games
        let games = requestManager.getUserGames()
        
        if games.isEmpty {
            // Try loading from mock data for testing
            userGames = UserGameTile.mockGames
            hasGames = !userGames.isEmpty
        } else {
            userGames = games
            hasGames = true
        }
        
        isLoadingGames = false
        
        // Fetch online counts for user's games
        if !userGames.isEmpty {
            await fetchOnlineCounts()
        }
    }
    
    /// Fetch online player counts for user's games
    func fetchOnlineCounts() async {
        let slugs = userGames.map { $0.slug }
        
        do {
            let counts = try await requestManager.getOnlinePlayerCounts(forGames: slugs)
            onlineCounts = counts
            
            // Update user games with counts
            userGames = userGames.map { game in
                var updatedGame = game
                if let count = counts[game.slug] {
                    updatedGame = UserGameTile(
                        id: game.id,
                        slug: game.slug,
                        name: game.name,
                        coverUrl: game.coverUrl,
                        genre: game.genre,
                        onlinePlayerCount: count,
                        gradientColors: game.gradientColors
                    )
                }
                return updatedGame
            }
        } catch {
            print("⚠️ Failed to fetch online counts: \(error)")
        }
    }
    
    /// Select a game to search for players
    func selectGame(_ game: UserGameTile) {
        selectedGame = game
        isInGamePlayerSearch = true
        searchText = ""
        
        // Load players for this game
        Task {
            await loadPlayersForSelectedGame()
        }
    }
    
    /// Go back from game player search to main view
    func exitGamePlayerSearch() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isInGamePlayerSearch = false
            selectedGame = nil
            playerResults = []
            searchText = ""
        }
    }
    
    /// Toggle search mode (games vs players)
    func setSearchMode(_ mode: PlayerSearchMode) {
        guard searchMode != mode else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            searchMode = mode
            // Clear previous results
            playerResults = []
            gameSearchResults = []
            
            // Re-trigger search if there's text
            if !searchText.isEmpty {
                Task {
                    await performSearch(query: searchText)
                }
            }
        }
    }
    
    /// Perform search based on current mode
    func performSearch(query: String) async {
        // Cancel any existing search
        searchTask?.cancel()
        
        guard !query.isEmpty else { return }
        
        isSearching = true
        
        searchTask = Task {
            do {
                if isInGamePlayerSearch {
                    // Search within selected game
                    await searchPlayersInGame(query: query)
                } else {
                    switch searchMode {
                    case .games:
                        await searchGames(query: query)
                    case .players:
                        await searchPlayersByGamertag(query: query)
                    }
                }
            }
            
            isSearching = false
        }
        
        await searchTask?.value
    }
    
    /// Load more players (pagination)
    func loadMorePlayers() async {
        guard let cursor = playersNextCursor, !isLoadingPlayers else { return }
        
        isLoadingPlayers = true
        
        do {
            let (newPlayers, nextCursor) = if let game = selectedGame {
                try await requestManager.searchPlayers(
                    forGame: game.slug,
                    query: searchText.isEmpty ? nil : searchText,
                    cursor: cursor
                )
            } else {
                try await requestManager.searchPlayersByGamertag(
                    query: searchText,
                    cursor: cursor
                )
            }
            
            playerResults.append(contentsOf: newPlayers)
            playersNextCursor = nextCursor
            hasMorePlayers = nextCursor != nil
            
        } catch {
            print("⚠️ Failed to load more players: \(error)")
        }
        
        isLoadingPlayers = false
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
        playerResults = []
        gameSearchResults = []
        isSearchFocused = false
    }
    
    /// Handle error
    func handleError(_ error: PlayerSearchError) {
        self.error = error
        self.showError = true
    }
    
    // MARK: - Private Methods
    
    private func loadPlayersForSelectedGame() async {
        guard let game = selectedGame else { return }
        
        isLoadingPlayers = true
        playerResults = []
        
        do {
            let (players, nextCursor) = try await requestManager.searchPlayers(
                forGame: game.slug
            )
            
            playerResults = players
            playersNextCursor = nextCursor
            hasMorePlayers = nextCursor != nil
            
        } catch {
            print("⚠️ Failed to load players for game: \(error)")
            handleError(error as? PlayerSearchError ?? .serverError(500))
        }
        
        isLoadingPlayers = false
    }
    
    private func searchPlayersInGame(query: String) async {
        guard let game = selectedGame else { return }
        
        isLoadingPlayers = true
        
        do {
            let (players, nextCursor) = try await requestManager.searchPlayers(
                forGame: game.slug,
                query: query
            )
            
            playerResults = players
            playersNextCursor = nextCursor
            hasMorePlayers = nextCursor != nil
            
        } catch {
            print("⚠️ Failed to search players in game: \(error)")
        }
        
        isLoadingPlayers = false
    }
    
    private func searchPlayersByGamertag(query: String) async {
        isLoadingPlayers = true
        
        do {
            let (players, nextCursor) = try await requestManager.searchPlayersByGamertag(
                query: query
            )
            
            playerResults = players
            playersNextCursor = nextCursor
            hasMorePlayers = nextCursor != nil
            
        } catch {
            print("⚠️ Failed to search players by gamertag: \(error)")
        }
        
        isLoadingPlayers = false
    }
    
    private func searchGames(query: String) async {
        isLoadingGameSearch = true
        
        do {
            let games = try await requestManager.searchGames(query: query)
            gameSearchResults = games
        } catch {
            print("⚠️ Failed to search games: \(error)")
        }
        
        isLoadingGameSearch = false
    }
}
