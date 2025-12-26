//
//  GameSelectionViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import Combine

// MARK: - View Model

@MainActor
class GameSelectionViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentCards: [GamerConnectGame] = []
    @Published var selectedGames: [GamerConnectGame] = []
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isEndOfList: Bool = false
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var selectedGenre: GameGenre = .all
    
    // MARK: - Configuration
    
    let isOnboarding: Bool
    let maxSelectedGames: Int = 15
    
    // MARK: - Private Properties
    
    private let viewedGamesKey = "GamerConnect_ViewedGameIDs"
    private var viewedGameIDs: Set<String> = []
    private var allFetchedGames: [GamerConnectGame] = []
    private var currentIndex: Int = 0
    private let cardsToShow: Int = 3
    
    // MARK: - Initialization
    
    init(isOnboarding: Bool = true) {
        self.isOnboarding = isOnboarding
        loadViewedGames()
    }
    
    // MARK: - Public Methods
    
    func loadGames() async {
        guard !isLoading else { return }
        
        isLoading = true
        hasError = false
        isEndOfList = false
        
        do {
            let games = try await GameRequestManager.shared.fetchGames(
                genre: selectedGenre,
                excludeIDs: Array(viewedGameIDs)
            )
            
            // Save to local storage
            GameStorageManager.shared.save(games: games)
            
            allFetchedGames = games
            currentIndex = 0
            updateVisibleCards()
            
            if games.isEmpty {
                isEndOfList = true
            }
            
            // Preload images for visible cards
            await preloadImages(for: Array(games.prefix(5)))
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchGames(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        isLoading = true
        hasError = false
        
        do {
            let games = try await GameRequestManager.shared.searchGames(query: query)
            
            // Save to local storage
            GameStorageManager.shared.save(games: games)
            
            // Filter out already viewed games
            allFetchedGames = games.filter { !viewedGameIDs.contains($0.id) }
            currentIndex = 0
            updateVisibleCards()
            
            if allFetchedGames.isEmpty {
                isEndOfList = true
            }
            
            // Preload images
            await preloadImages(for: Array(allFetchedGames.prefix(5)))
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func selectGame(_ game: GamerConnectGame) {
        guard !selectedGames.contains(where: { $0.id == game.id }) else { return }
        guard selectedGames.count < maxSelectedGames else { return }
        
        selectedGames.append(game)
        markGameAsViewed(game)
        advanceToNextCard()
    }
    
    func skipGame(_ game: GamerConnectGame) {
        markGameAsViewed(game)
        advanceToNextCard()
    }
    
    func selectGenre(_ genre: GameGenre) {
        guard genre != selectedGenre else { return }
        selectedGenre = genre
        isSearching = false
        searchQuery = ""
        
        Task {
            await loadGames()
        }
    }
    
    func clearSearch() {
        isSearching = false
        searchQuery = ""
        Task {
            await loadGames()
        }
    }
    
    func retryLoading() {
        Task {
            if isSearching && !searchQuery.isEmpty {
                await searchGames(query: searchQuery)
            } else {
                await loadGames()
            }
        }
    }
    
    func removeSelectedGame(_ game: GamerConnectGame) {
        selectedGames.removeAll { $0.id == game.id }
    }
    
    // MARK: - Private Methods
    
    private func updateVisibleCards() {
        let endIndex = min(currentIndex + cardsToShow, allFetchedGames.count)
        if currentIndex < allFetchedGames.count {
            currentCards = Array(allFetchedGames[currentIndex..<endIndex])
        } else {
            currentCards = []
            isEndOfList = true
        }
    }
    
    private func advanceToNextCard() {
        currentIndex += 1
        updateVisibleCards()
        
        // Preload next batch of images
        let preloadStart = currentIndex + cardsToShow
        let preloadEnd = min(preloadStart + 3, allFetchedGames.count)
        if preloadStart < allFetchedGames.count {
            let gamesToPreload = Array(allFetchedGames[preloadStart..<preloadEnd])
            Task {
                await preloadImages(for: gamesToPreload)
            }
        }
    }
    
    private func markGameAsViewed(_ game: GamerConnectGame) {
        viewedGameIDs.insert(game.id)
        saveViewedGames()
    }
    
    private func loadViewedGames() {
        if let savedIDs = UserDefaults.standard.array(forKey: viewedGamesKey) as? [String] {
            viewedGameIDs = Set(savedIDs)
        }
    }
    
    private func saveViewedGames() {
        UserDefaults.standard.set(Array(viewedGameIDs), forKey: viewedGamesKey)
    }
    
    private func preloadImages(for games: [GamerConnectGame]) async {
        let urls = games.compactMap { $0.displayImageURL }
        await ImageCache.shared.preload(urls: urls)
    }
    
    // Clear viewed games (useful for testing or reset)
    func clearViewedGames() {
        viewedGameIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: viewedGamesKey)
    }
}

// MARK: - Game Genre

enum GameGenre: String, CaseIterable, Identifiable {
    case all = "All"
    case fps = "FPS"
    case battleRoyale = "Battle Royale"
    case rpg = "RPG"
    case sports = "Sports"
    case moba = "MOBA"
    case racing = "Racing"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .all: return "🎮"
        case .fps: return "🎯"
        case .battleRoyale: return "🏝️"
        case .rpg: return "🧙"
        case .sports: return "⚽"
        case .moba: return "⚔️"
        case .racing: return "🏎️"
        }
    }
    
    // Map to categoryFilters values used in GamerConnectGame
    var categoryFilterValues: [String] {
        switch self {
        case .all: return []
        case .fps: return ["FPS", "Shooter", "First-Person Shooter"]
        case .battleRoyale: return ["Battle Royale"]
        case .rpg: return ["RPG", "Role-Playing", "Action RPG", "JRPG"]
        case .sports: return ["Sports", "Sport", "Football", "Basketball", "Soccer"]
        case .moba: return ["MOBA", "Multiplayer Online Battle Arena"]
        case .racing: return ["Racing", "Driving", "Race"]
        }
    }
}
