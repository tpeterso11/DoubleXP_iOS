//
//  PokoSelectionViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI
import FirebaseDatabase

// MARK: - Extended Poko Stats (add these fields to your Firebase Poko object)

enum PokoRarity: String, CaseIterable {
    case common = "Common"
    case rare = "Rare"
    case legendary = "Legendary"
    
    var stars: String {
        switch self {
        case .common: return "★"
        case .rare: return "★★"
        case .legendary: return "★★★"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Filter Options

enum PokoFilterOption: String, CaseIterable {
    case all = "All"
    case owned = "Owned"
    case featured = "⭐"
}

@MainActor
class PokoSelectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allPokos: [Poko] = []
    @Published var ownedPokos: [Poko] = []
    @Published var featuredPokos: [Poko] = [] // Special editions
    @Published var popularPokos: [Poko] = []
    
    @Published var selectedPoko: Poko?
    @Published var viewingPoko: Poko? // Currently highlighted in grid
    
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published var isSaving: Bool = false
    
    @Published var currentFilter: PokoFilterOption = .all
    private var originalSelectedPokoId: String?
    @Published var isBackstoryExpanded: Bool = false
    
    @Published var userCoins: Int = 0 // Load from user if you have a coins field
    
    // MARK: - Configuration
    
    let isOnboarding: Bool
    
    // Callback when selection is confirmed (for onboarding flow or edit profile)
    var onSelectionConfirmed: ((Poko) -> Void)?
    
    // MARK: - Private
    
    private var hasLoaded = false
    
    // MARK: - Init
    
    init(isOnboarding: Bool = false) {
        self.isOnboarding = isOnboarding
    }
    
    // MARK: - Load Data
    
    func loadPokos() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        isLoading = true
        error = nil
        
        do {
            // Load all pokos from provider
            let pokos = await PokoProvider.shared.getPokos(forceReload: true)
            
            self.allPokos = pokos.filter { $0.available }
            self.ownedPokos = PokoProvider.shared.allUserPokos
            self.featuredPokos = pokos.filter { $0.specialEdition == "true" && $0.available }
            self.popularPokos = pokos.filter { $0.popular }
            
            // Set initial viewing poko
            if let userSelected = PokoProvider.shared.userSelectedPoko {
                self.selectedPoko = userSelected
                self.viewingPoko = userSelected
                self.originalSelectedPokoId = userSelected.id
            } else if let firstOwned = ownedPokos.first {
                self.viewingPoko = firstOwned
            } else if let firstAvailable = allPokos.first {
                self.viewingPoko = firstAvailable
            }
            
            // Load user coins if available
            if let user = UserProvider.shared.currentUser {
                // self.userCoins = user.coins // Uncomment when you have coins field
                self.userCoins = 2450 // Placeholder
            }
            
            isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    var hasNewSelection: Bool {
        guard let selected = selectedPoko else { return false }
        if let originalId = originalSelectedPokoId {
            return selected.id != originalId
        } else {
            // No original – any selection counts as "new"
            return true
        }
    }
    
    // MARK: - Filtering
    
    var filteredPokos: [Poko] {
        switch currentFilter {
        case .all:
            return allPokos
        case .owned:
            return ownedPokos
        case .featured:
            return featuredPokos
        }
    }
    
    // MARK: - Selection
    
    func selectPoko(_ poko: Poko) {
        // Single tap now does both: view AND select
        withAnimation(.easeInOut(duration: 0.3)) {
            viewingPoko = poko
            selectedPoko = poko
            isBackstoryExpanded = false
        }
    }
    
    func confirmSelection(_ poko: Poko) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPoko = poko
        }
    }
    
    func commitSelectionIfNeeded() {
        guard hasNewSelection, let poko = selectedPoko, !isSaving else { return }
        saveSelection(poko)   // your existing saveSelection(_:), which hits Firebase and posts notifications
    }
    
    func confirmCurrentSelection() {
        guard let poko = viewingPoko else { return }
        confirmSelection(poko)
    }
    
    // MARK: - Save to Firebase
    
    private func saveSelection(_ poko: Poko) {
        guard let user = UserProvider.shared.currentUser else {
            error = "User not loaded"
            return
        }
        
        isSaving = true
        
        let userRef = Database.database().reference()
            .child("Users")
            .child(user.uId)
        
        // Start from what we already know the user owns
        var ownedIds = user.pokos                // [String]
        if !ownedIds.contains(poko.id) {
            ownedIds.append(poko.id)
        }
        
        // 🔹 Match the exact keys your loader uses:
        // let currentSelectedPokoId = value["selectedPoko"]
        // let ownedPokos            = value["ownedPokos"]
        let updates: [String: Any] = [
            "selectedPoko": poko.id,
            "ownedPokos": ownedIds
        ]
        
        userRef.updateChildValues(updates) { [weak self] error, _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isSaving = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                // 🔹 Keep provider caches in sync immediately
                /*if var current = UserProvider.shared.currentUser {
                    current.currentSelectedPokoId = poko.id
                    current.pokos = ownedIds
                    UserProvider.shared.currentUser = current
                }
                
                PokoProvider.shared.userSelectedPoko = poko*/
                
                // Optionally still reload from backend if you want a “source of truth” refresh:
                _ = await UserProvider.shared.loadUser(uid: user.uId)
                
                // Tell the rest of the app
                NotificationCenter.default.post(name: .userProviderDidUpdateUser, object: nil)
                NotificationCenter.default.post(
                    name: .userPokoDidChange,
                    object: nil,
                    userInfo: ["poko": poko]
                )
                
                // Callback back to the UI (EditProfile / Onboarding)
                self.onSelectionConfirmed?(poko)
            }
        }
    }
    
    // MARK: - Helpers
    
    func isOwned(_ poko: Poko) -> Bool {
        ownedPokos.contains { $0.id == poko.id }
    }
    
    func isSelected(_ poko: Poko) -> Bool {
        selectedPoko?.id == poko.id
    }
    
    func isViewing(_ poko: Poko) -> Bool {
        viewingPoko?.id == poko.id
    }
    
    func isFeatured(_ poko: Poko) -> Bool {
        poko.specialEdition == "true"
    }
    
    func isLocked(_ poko: Poko) -> Bool {
        // A poko is locked if user doesn't own it and it's not available for selection
        // Adjust logic based on your business rules
        !isOwned(poko) && !poko.available
    }
    
    func toggleBackstory() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isBackstoryExpanded.toggle()
        }
    }
    
    func selectRandomPoko() {
        let available = currentFilter == .owned ? ownedPokos : allPokos.filter { $0.available }
        guard let random = available.randomElement() else { return }
        selectPoko(random)
    }
}
