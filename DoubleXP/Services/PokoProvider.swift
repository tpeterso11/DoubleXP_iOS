//
//  PokoProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Firebase
import Foundation

struct Poko: Identifiable {
    let type: String
    let name: String
    let imageUrl: String
    let selectionCount: Int
    let popular: Bool
    let specialEdition: String
    let specialEditionEndDate: String
    let available: Bool
    let id: String
    let currentPoko: Bool        // current user has selected to use
    let headshotUrl: String
    let power: Int
    let speed: Int
    let defense: Int
    let originStory: String
    let xpBoost: Int
}

class PokoProvider {
    static let shared = PokoProvider()
    
    /// All available Pokos
    var pokoList: [Poko] = []
    var allUserPokos: [Poko] = []
    
    /// The Poko currently selected by the user (based on User.currentSelectedPokoId)
    /// This will be set after `loadPokos()` finishes and the user object is available.
    var userSelectedPoko: Poko?
    
    private let pokoRef = Database.database().reference().child("Pokos")
    
    private init() {}
    
    // MARK: - Public fetchers
    
    /// Simple async fetch – returns cached Pokos unless `forceReload` is true.
    func getPokos(forceReload: Bool = false) async -> [Poko] {
        if pokoList.isEmpty || forceReload {
            await loadPokos()
        }
        return pokoList
    }
    
    /// (If you still want a completion-based version, you can flesh this out later or remove it.)
    func getPokos(
        forceReload: Bool = false,
        completion: @escaping ([Poko]) -> Void
    ) async -> [Poko] {
        if pokoList.isEmpty || forceReload {
            await loadPokos()
        }
        completion(pokoList)
        return pokoList
    }
    
    /// Fetch a single Poko by id. Will load from Firebase if needed.
    func getPoko(byId pokoId: String, forceReload: Bool = false) async -> Poko? {
        if pokoList.isEmpty || forceReload {
            await loadPokos()
        }
        return pokoList.first { $0.id == pokoId }
    }
    
    // MARK: - Core loader
    
    func loadPokos() async {
        // Capture user's poko IDs on main actor BEFORE entering the closure
        let userPokoIds: Set<String> = await MainActor.run {
            guard let currentUser = UserProvider.shared.currentUser else {
                return Set<String>()
            }
            return Set(currentUser.pokos)
        }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pokoRef.observeSingleEvent(of: .value) { snapshot in
                var result: [(poko: Poko, rawCount: Int)] = []
                var userOwnedPokos: [Poko] = []
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                let now = Date()
                
                for child in snapshot.children {
                    guard
                        let childSnap = child as? DataSnapshot,
                        let dict = childSnap.value as? [String: Any]
                    else {
                        continue
                    }
                    
                    let type = dict["type"] as? String ?? "unknown"
                    let name = dict["name"] as? String ?? "Unnamed"
                    let imageUrl = dict["imageUrl"] as? String ?? ""
                    let selectionCount = dict["selectionCount"] as? Int ?? 0
                    let specialEdition = dict["specialEdition"] as? String ?? ""
                    let specialEditionEndDate = dict["specialEditionEndDate"] as? String ?? ""
                    let pokoId = dict["id"] as? String ?? ""
                    let currentPoko = dict["currentPokoId"] as? Bool ?? false
                    let pokoHeadshotUrl = dict["headshotUrl"] as? String ?? ""
                    
                    // New stat fields from Firebase (with safe defaults)
                    let speed = dict["speed"] as? Int ?? 75
                    let power = dict["power"] as? Int ?? 75
                    let defense = dict["defense"] as? Int ?? 75
                    let backstory = dict["backstory"] as? String ?? ""
                    let xpBoost = dict["xpBoost"] as? Int ?? 0
                    
                    var isAvailable = true
                    if specialEdition == "true" {
                        if let endDate = dateFormatter.date(from: specialEditionEndDate),
                           endDate < now {
                            isAvailable = false
                        }
                    }
                    
                    let poko = Poko(
                        type: type,
                        name: name,
                        imageUrl: imageUrl,
                        selectionCount: selectionCount,
                        popular: false,
                        specialEdition: specialEdition,
                        specialEditionEndDate: specialEditionEndDate,
                        available: isAvailable,
                        id: pokoId,
                        currentPoko: currentPoko,
                        headshotUrl: pokoHeadshotUrl,
                        power: power,
                        speed: speed,
                        defense: defense,
                        originStory: backstory,
                        xpBoost: xpBoost
                    )
                    
                    result.append((poko, selectionCount))
                    
                    // Check if user owns this poko
                    if userPokoIds.contains(pokoId) {
                        userOwnedPokos.append(poko)
                    }
                }
                
                // Sort so special editions first, then alphabetical by name
                let sorted = result.sorted {
                    let aIsSpecial = $0.poko.specialEdition == "true"
                    let bIsSpecial = $1.poko.specialEdition == "true"
                    
                    if aIsSpecial && !bIsSpecial {
                        return true
                    } else if !aIsSpecial && bIsSpecial {
                        return false
                    } else {
                        return $0.poko.name
                            .localizedCaseInsensitiveCompare($1.poko.name) == .orderedAscending
                    }
                }
                
                // Top 2 by selectionCount = popular
                let top2Ids = Set(
                    result
                        .sorted { $0.rawCount > $1.rawCount }
                        .prefix(2)
                        .map { $0.poko.name }
                )
                
                self.pokoList = sorted.map { entry in
                    let updated = entry.poko
                    let isPopular = top2Ids.contains(updated.name)
                    
                    return Poko(
                        type: updated.type,
                        name: updated.name,
                        imageUrl: updated.imageUrl,
                        selectionCount: updated.selectionCount,
                        popular: isPopular,
                        specialEdition: updated.specialEdition,
                        specialEditionEndDate: updated.specialEditionEndDate,
                        available: updated.available,
                        id: updated.id,
                        currentPoko: updated.currentPoko,
                        headshotUrl: updated.headshotUrl,
                        power: updated.power,
                        speed: updated.speed,
                        defense: updated.defense,
                        originStory: updated.originStory,
                        xpBoost: updated.xpBoost
                    )
                }
                
                self.allUserPokos = userOwnedPokos
                
                // After we’ve loaded Pokos, try to resolve the user’s selected Poko.
                Task {
                    await self.updateUserSelectedPokoFromUser()
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - User-selected Poko wiring
    
    /// Looks at `UserProvider.shared.currentUser?.currentSelectedPokoId`
    /// and tries to find the matching Poko in `pokoList`.
    /// Call this after Pokos are loaded *and* the UserProvider has a user.
    private func updateUserSelectedPokoFromUser() async {
        // Read the selected poko id on the main actor (UserProvider is @MainActor)
        let selectedId: String? = await MainActor.run {
            UserProvider.shared.currentUser?.currentSelectedPokoId
        }
        
        guard let selectedId, !selectedId.isEmpty else {
            // No selection on the user → clear the cached pointer
            self.userSelectedPoko = nil
            return
        }
        
        // Just match by id in the already-loaded list
        let match = pokoList.first { $0.id == selectedId }
        self.userSelectedPoko = match
    }
}

extension Poko {
    /// Derived rarity based on flags coming from Firebase
    var rarity: PokoRarity {
        if specialEdition == "true" {
            return .legendary
        }
        if popular {
            return .rare
        }
        return .common
    }
    
    /// Convenience alias if you want a clearer name in UI
    var elementType: String {
        return type
    }
}
