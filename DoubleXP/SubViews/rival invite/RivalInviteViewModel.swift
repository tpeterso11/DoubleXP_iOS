//
//  RivalInviteViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI
import Combine

// MARK: - Rival Invite View Model

@MainActor
class RivalInviteViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Mode
    @Published var mode: RivalInviteMode = .challenge
    
    // Recipient
    @Published var selectedRecipient: RivalRecipient?
    @Published var availableFriends: [RivalRecipient] = []
    @Published var isLoadingFriends = false
    
    // Game
    @Published var selectedGame: RivalGame?
    @Published var availableGames: [RivalGame] = []
    @Published var isLoadingGames = false
    
    // Options
    @Published var selectedPlatform: RivalPlatform = .playstation
    @Published var selectedTiming: RivalTiming = .now
    @Published var customMessage: String = ""
    
    // UI State
    @Published var isSending = false
    @Published var showFriendPicker = false
    @Published var showGamePicker = false
    @Published var showPlatformPicker = false
    @Published var showTimingPicker = false
    @Published var showOnboarding = false
    
    // Result
    @Published var sendResult: SendResult?
    @Published var error: String?
    
    // MARK: - Current User Info
    
    var currentUserGamerTag: String {
        UserProvider.shared.currentUser?.gamerTag ?? "You"
    }
    
    var currentUserInitial: String {
        currentUserGamerTag.prefix(1).uppercased()
    }
    
    // MARK: - Computed Properties
    
    var canSend: Bool {
        selectedRecipient != nil && selectedGame != nil && !isSending
    }
    
    var recipientInitial: String {
        selectedRecipient?.avatarInitial ?? "?"
    }
    
    var modeSymbol: String {
        mode == .challenge ? "VS" : "+"
    }
    
    var accentColor: Color {
        mode == .challenge ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color(red: 0.3, green: 0.69, blue: 0.31)
    }
    
    var actionButtonText: String {
        if isSending {
            return "Sending..."
        }
        return "\(mode.icon) \(mode.actionButtonText)"
    }
    
    // MARK: - Initialization
    
    init(preselectedRecipient: RivalRecipient? = nil) {
        self.selectedRecipient = preselectedRecipient
        
        // Check if onboarding should be shown
        if !RivalInviteOnboardingState.hasSeenOnboarding {
            showOnboarding = true
        }
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await loadFriends()
        await loadGames()
    }
    
    func loadFriends() async {
        isLoadingFriends = true
        defer { isLoadingFriends = false }
        
        do {
            let friends = try await RivalInviteRequestManager.shared.fetchFriendsForInvite()
            availableFriends = friends
            
            #if DEBUG
            print("👥 [RivalInvite] Loaded \(friends.count) friends")
            #endif
            
            // Use mock data if no friends
            //if availableFriends.isEmpty {
            //    availableFriends = RivalRecipient.mockFriends
            //}
            
        } catch {
            #if DEBUG
            print("❌ [RivalInvite] Failed to load friends: \(error)")
            #endif
            // Fallback to mock data
            availableFriends = RivalRecipient.mockFriends
        }
    }
    
    func loadGames() async {
        isLoadingGames = true
        defer { isLoadingGames = false }
        
        do {
            let games = try await RivalInviteRequestManager.shared.fetchUserGames()
            availableGames = games
            
            // Auto-select first game if none selected
            if selectedGame == nil, let firstGame = games.first {
                selectedGame = firstGame
            }
            
            #if DEBUG
            print("🎮 [RivalInvite] Loaded \(games.count) games")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ [RivalInvite] Failed to load games: \(error)")
            #endif
            // Fallback to mock data
            availableGames = RivalGame.mockGames
            if selectedGame == nil {
                selectedGame = RivalGame.mockGames.first
            }
        }
    }
    
    // MARK: - Actions
    
    func toggleMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            mode = mode == .challenge ? .teamUp : .challenge
        }
    }
    
    func selectRecipient(_ recipient: RivalRecipient) {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedRecipient = recipient
            showFriendPicker = false
        }
    }
    
    func selectGame(_ game: RivalGame) {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedGame = game
            showGamePicker = false
        }
    }
    
    func selectPlatform(_ platform: RivalPlatform) {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedPlatform = platform
            showPlatformPicker = false
        }
    }
    
    func selectTiming(_ timing: RivalTiming) {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedTiming = timing
            showTimingPicker = false
        }
    }
    
    // MARK: - Send Invite
    
    func sendInvite() async {
        guard let recipient = selectedRecipient else {
            error = RivalInviteError.noRecipientSelected.localizedDescription
            return
        }
        
        guard let game = selectedGame else {
            error = RivalInviteError.noGameSelected.localizedDescription
            return
        }
        
        isSending = true
        error = nil
        
        do {
            let response = try await RivalInviteRequestManager.shared.sendRivalInvite(
                to: recipient,
                game: game,
                mode: mode,
                platform: selectedPlatform,
                timing: selectedTiming,
                customMessage: customMessage.isEmpty ? nil : customMessage
            )
            
            if response.success {
                sendResult = .success(inviteId: response.inviteId ?? "")
                
                #if DEBUG
                print("✅ [RivalInvite] Invite sent! ID: \(response.inviteId ?? "unknown")")
                #endif
            } else {
                error = response.error ?? "Unknown error"
                sendResult = .failure(message: response.error ?? "Unknown error")
            }
            
        } catch {
            self.error = error.localizedDescription
            sendResult = .failure(message: error.localizedDescription)
            
            #if DEBUG
            print("❌ [RivalInvite] Send failed: \(error)")
            #endif
        }
        
        isSending = false
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        RivalInviteOnboardingState.hasSeenOnboarding = true
        withAnimation(.easeOut(duration: 0.3)) {
            showOnboarding = false
        }
    }
    
    func resetOnboarding() {
        RivalInviteOnboardingState.resetOnboarding()
        showOnboarding = true
    }
    
    // MARK: - Reset
    
    func reset() {
        selectedRecipient = nil
        selectedGame = availableGames.first
        selectedPlatform = .playstation
        selectedTiming = .now
        customMessage = ""
        sendResult = nil
        error = nil
    }
}

// MARK: - Send Result

enum SendResult {
    case success(inviteId: String)
    case failure(message: String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Preview Helpers

extension RivalInviteViewModel {
    static var preview: RivalInviteViewModel {
        let vm = RivalInviteViewModel()
        vm.availableFriends = RivalRecipient.mockFriends
        vm.availableGames = RivalGame.mockGames
        vm.selectedRecipient = RivalRecipient.mockFriends.first
        vm.selectedGame = RivalGame.mockGames.first
        return vm
    }
    
    static var previewTeamUp: RivalInviteViewModel {
        let vm = preview
        vm.mode = .teamUp
        return vm
    }
    
    static var previewNoSelection: RivalInviteViewModel {
        let vm = RivalInviteViewModel()
        vm.availableFriends = RivalRecipient.mockFriends
        vm.availableGames = RivalGame.mockGames
        return vm
    }
}
