//
//  ChallengesViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI
import Combine

// MARK: - Challenges ViewModel

@MainActor
final class ChallengesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Data
    @Published var allCompetitions: [Competition] = []
    @Published var userSummaries: [String: UserCompetitionSummary] = [:]
    
    // Sections
    @Published var featuredCompetitions: [Competition] = [] // Featured + Sponsored
    @Published var myGameChallenges: [Competition] = [] // Challenges for user's games
    @Published var generalChallenges: [Competition] = [] // No game requirement (in-app challenges)
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedTab: ChallengeTab = .all
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    
    // Detail Popup
    @Published var selectedCompetition: Competition?
    @Published var showCompetitionDetail: Bool = false
    
    // Google Connection (mirrors EditProfileViewModel pattern)
    @Published var isGoogleConnected: Bool = false
    @Published var googleEmail: String = ""
    @Published var showGoogleConnectionDrawer: Bool = false
    
    // Navigation
    @Published var showMoreFeatured: Bool = false
    @Published var showMoreMyGames: Bool = false
    
    // MARK: - Private Properties
    
    private let requestManager = CompetitionRequestManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var googleConnectionCancellable: AnyCancellable?
    
    // User's games for filtering
    private var userGames: [String] = []
    
    // Display limits
    private let featuredDisplayLimit = 4
    private let myGamesDisplayLimit = 4
    
    // MARK: - Computed Properties
    
    /// Filtered competitions based on tab and search
    var filteredCompetitions: [Competition] {
        var result: [Competition]
        
        // Filter by tab
        switch selectedTab {
        case .all:
            result = generalChallenges
        case .entered:
            result = allCompetitions.filter { competition in
                userSummaries[competition.id] != nil
            }
        }
        
        // Filter by search (after 3 characters)
        if searchText.count >= 3 {
            let searchLower = searchText.lowercased()
            result = result.filter { competition in
                competition.title.lowercased().contains(searchLower) ||
                competition.description.lowercased().contains(searchLower) ||
                competition.type.displayName.lowercased().contains(searchLower)
            }
        }
        
        return result
    }
    
    /// Limited featured for display (show max 4)
    var displayedFeatured: [Competition] {
        Array(featuredCompetitions.prefix(featuredDisplayLimit))
    }
    
    /// Limited my game challenges for display (show max 4)
    var displayedMyGameChallenges: [Competition] {
        Array(myGameChallenges.prefix(myGamesDisplayLimit))
    }
    
    /// Whether there are more featured to show
    var hasMoreFeatured: Bool {
        featuredCompetitions.count > featuredDisplayLimit
    }
    
    /// Whether there are more game challenges to show
    var hasMoreMyGameChallenges: Bool {
        myGameChallenges.count > myGamesDisplayLimit
    }
    
    /// Count of entered competitions
    var enteredCount: Int {
        userSummaries.count
    }
    
    // MARK: - Init
    
    init() {
        setupSearchDebounce()
        setupGoogleConnectionObserver()
    }
    
    deinit {
        googleConnectionCancellable?.cancel()
    }
    
    // MARK: - Google Connection Observer
    
    private func setupGoogleConnectionObserver() {
        googleConnectionCancellable = YouTubeRequestManager.shared.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .connected(let email):
                    self.isGoogleConnected = true
                    self.googleEmail = email
                    print("🔗 [Challenges] Google connected: \(email)")
                    
                case .disconnected:
                    self.isGoogleConnected = false
                    self.googleEmail = ""
                    print("🔗 [Challenges] Google disconnected")
                    
                case .connecting:
                    print("🔗 [Challenges] Google connecting...")
                    
                case .error(let message):
                    print("🔗 [Challenges] Google error: \(message)")
                }
            }
    }
    
    /// Check Google connection status on load
    func checkGoogleConnectionStatus() {
        Task {
            await YouTubeRequestManager.shared.restorePreviousSignIn()
            
            let state = YouTubeRequestManager.shared.connectionState
            if case .connected(let email) = state {
                self.isGoogleConnected = true
                self.googleEmail = email
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Load all competitions and user entries
    func loadData() async {
        guard let user = UserProvider.shared.currentUser else {
            error = "User not found"
            return
        }
        
        isLoading = true
        error = nil
        userGames = user.games
        
        do {
            // Fetch all competitions (we'll filter client-side)
            async let competitionsTask = requestManager.fetchCompetitions()
            async let summariesTask = requestManager.fetchAllUserCompetitionSummaries(userId: user.uId)
            
            let (fetchedCompetitions, fetchedSummaries) = try await (competitionsTask, summariesTask)
            
            allCompetitions = fetchedCompetitions
            userSummaries = fetchedSummaries
            
            // Categorize competitions
            categorizeCompetitions(fetchedCompetitions)
            
            // Check Google connection
            checkGoogleConnectionStatus()
            
            isLoading = false
            
            print("✅ [Challenges] Loaded \(allCompetitions.count) competitions")
            print("   Featured: \(featuredCompetitions.count)")
            print("   My Games: \(myGameChallenges.count)")
            print("   General: \(generalChallenges.count)")
            print("   Entered: \(userSummaries.count)")
            
        } catch {
            self.error = "Failed to load challenges: \(error.localizedDescription)"
            isLoading = false
            print("❌ [Challenges] Load error: \(error)")
        }
    }
    
    /// Categorize competitions into sections
    private func categorizeCompetitions(_ competitions: [Competition]) {
        var featured: [Competition] = []
        var myGames: [Competition] = []
        var general: [Competition] = []
        
        // Normalize user games for comparison
        let normalizedUserGames = Set(userGames.map { normalizeSlug($0) })
        
        for competition in competitions {
            // Check if featured or sponsored
            if competition.isFeatured || competition.isSponsored {
                // Only show if user has access (no game requirement OR user has the game)
                if isAccessible(competition, userGames: normalizedUserGames) {
                    featured.append(competition)
                }
                continue
            }
            
            // Check if game-specific
            if let gameSlug = competition.gameSlug, !gameSlug.isEmpty {
                // Only show if user has this game
                if normalizedUserGames.contains(normalizeSlug(gameSlug)) {
                    myGames.append(competition)
                }
                // If user doesn't have the game, skip it entirely
                continue
            }
            
            // General challenge (no game requirement)
            general.append(competition)
        }
        
        // Sort each category
        featuredCompetitions = featured.sorted { $0.endsAt < $1.endsAt }
        myGameChallenges = myGames.sorted { $0.endsAt < $1.endsAt }
        generalChallenges = general.sorted { $0.endsAt < $1.endsAt }
    }
    
    /// Check if user can access this competition
    private func isAccessible(_ competition: Competition, userGames: Set<String>) -> Bool {
        guard let gameSlug = competition.gameSlug, !gameSlug.isEmpty else {
            return true // No game requirement
        }
        return userGames.contains(normalizeSlug(gameSlug))
    }
    
    /// Normalize slug for comparison
    private func normalizeSlug(_ slug: String) -> String {
        return slug
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
    
    /// Refresh data (pull to refresh)
    func refresh() async {
        await loadData()
    }
    
    /// Select a competition to view details
    func selectCompetition(_ competition: Competition) {
        selectedCompetition = competition
        showCompetitionDetail = true
    }
    
    /// Close competition detail
    func closeDetail() {
        showCompetitionDetail = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedCompetition = nil
        }
    }
    
    /// Toggle search mode
    func toggleSearch() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSearching.toggle()
            if !isSearching {
                searchText = ""
            }
        }
    }
    
    /// Show Google connection drawer
    func showGoogleDrawer() {
        showGoogleConnectionDrawer = true
    }
    
    /// Called when Google connection succeeds
    func onGoogleConnectionSuccess() {
        // Refresh data to update any UI that depends on Google connection
        Task {
            await refresh()
        }
    }
    
    /// Get user summary for a competition
    func summary(for competitionId: String) -> UserCompetitionSummary? {
        userSummaries[competitionId]
    }
    
    /// Check if user has entered a competition
    func hasEntered(_ competitionId: String) -> Bool {
        userSummaries[competitionId] != nil
    }
    
    /// Get entry status text
    func entryStatusText(for competitionId: String) -> String? {
        guard let summary = userSummaries[competitionId] else { return nil }
        
        if summary.hasWon {
            return "✓ Won"
        } else if let status = summary.latestStatus {
            return status.displayName
        } else {
            return "Entered"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Challenge Tab

enum ChallengeTab: String, CaseIterable {
    case all = "All"
    case entered = "Entered"
}
