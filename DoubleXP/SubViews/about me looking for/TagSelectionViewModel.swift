//
//  TagSelectionViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/28/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import FirebaseDatabase

enum TagSelectionMode {
    case aboutMe
    case lookingFor

    var title: String {
        switch self {
        case .aboutMe: return "ABOUT ME"
        case .lookingFor: return "LOOKING FOR"
        }
    }

    var subtitle: String {
        switch self {
        case .aboutMe:
            return "Pick a few that feel like you"
        case .lookingFor:
            return "What kind of teammates are you hoping to find?"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .aboutMe: return "Save About Me"
        case .lookingFor: return "Save Looking For"
        }
    }

    var stepLabel: String {
        switch self {
        case .aboutMe: return "STEP 1 OF 2"
        case .lookingFor: return "STEP 2 OF 2"
        }
    }
}

struct TagSectionModel: Identifiable {
    let id = UUID()
    let title: String
    let caption: String?
    let tags: [String]
}

@MainActor
final class TagSelectionViewModel: ObservableObject {
    let mode: TagSelectionMode
    
    @Published var sections: [TagSectionModel] = []
    @Published var selectedTags: Set<String>
    @Published private(set) var hasChanges: Bool = false
    @Published var isSaving: Bool = false
    
    // Baseline selection we compare against to determine dirty state
    private var baselineSelection: Set<String>
    
    init(mode: TagSelectionMode, initialSelection: Set<String>) {
        self.mode = mode
        self.baselineSelection = initialSelection
        self.selectedTags = initialSelection
        
        loadMockData()
        markDirtyIfNeeded()
    }
    
    // MARK: - Mock data for now
    
    private func loadMockData() {
        switch mode {
        case .aboutMe:
            sections = [
                TagSectionModel(
                    title: "VIBE",
                    caption: "Choose tags that describe your overall energy as a player.",
                    tags: [
                        "Chill",
                        "Competitive",
                        "Social",
                        "Late Night",
                        "Tactical",
                        "Casual Sweats",
                        "Story-Driven",
                        "Achievement Hunter"
                    ]
                ),
                TagSectionModel(
                    title: "COMMUNICATION",
                    caption: "How do you like to communicate in party / squad?",
                    tags: [
                        "Mic Always On",
                        "Mic Sometimes",
                        "Text Only",
                        "Camera Friendly",
                        "Callouts Only",
                        "Quiet Focused"
                    ]
                )
            ]
        case .lookingFor:
            sections = [
                TagSectionModel(
                    title: "TEAM VIBE",
                    caption: "What kind of squad are you looking to run with?",
                    tags: [
                        "No Drama",
                        "Tryhard Nights",
                        "Just Vibes",
                        "Ranked Grind",
                        "New Player Friendly",
                        "Zero Toxicity"
                    ]
                ),
                TagSectionModel(
                    title: "COMMUNICATION",
                    caption: "How do you want your squad to communicate?",
                    tags: [
                        "Mic Required",
                        "Chill Callouts",
                        "Mostly Text",
                        "Cam Optional",
                        "Shotcaller Welcome",
                        "Low Talk, High Focus"
                    ]
                )
            ]
        }
    }
    
    // MARK: - Selection
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        markDirtyIfNeeded()
    }
    
    private func markDirtyIfNeeded() {
        hasChanges = (selectedTags != baselineSelection)
    }
    
    // MARK: - Save
    
    /// Real save: writes to `Users/{uid}` and reloads the user via UserProvider
    func saveSelections(completion: @escaping (Bool) -> Void) {
        guard !isSaving else {
            completion(false)
            return
        }
        
        guard let user = UserProvider.shared.getUser() else {
            completion(false)
            return
        }
        
        isSaving = true
        
        let uid = user.uId
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
        
        let tagsArray = Array(selectedTags).sorted()   // sorted for consistency
        let key: String = (mode == .aboutMe) ? "userAbout" : "userLookingFor"
        
        ref.updateChildValues([key: tagsArray]) { [weak self] error, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isSaving = false
                
                if let error = error {
                    print("🔴 Failed to save \(key): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // Refresh the user so everyone listening (EditProfile, UserProfile, etc.) gets updated data
                _ = await UserProvider.shared.loadUser(uid: uid)
                
                // Reset baseline so hasChanges becomes false
                self.selectedTags = Set(tagsArray)
                self.baselineSelection = self.selectedTags
                self.markDirtyIfNeeded()
                
                completion(true)
            }
        }
    }
}
