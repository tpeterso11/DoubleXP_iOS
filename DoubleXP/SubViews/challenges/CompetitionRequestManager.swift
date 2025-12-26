//
//  CompetitionRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import FirebaseDatabase

// MARK: - Competition Request Manager

/// Handles all Firebase operations for competitions
final class CompetitionRequestManager {
    
    // MARK: - Singleton
    
    static let shared = CompetitionRequestManager()
    
    // MARK: - Properties
    
    private let database = Database.database().reference()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Fetch Competitions
    
    /// Fetch all active competitions
    func fetchCompetitions() async throws -> [Competition] {
        let snapshot = try await database
            .child("Competitions")
            .getData()
        
        guard snapshot.exists(),
              let value = snapshot.value as? [String: Any] else {
            return []
        }
        
        var competitions: [Competition] = []
        
        for (competitionId, competitionData) in value {
            guard let competitionDict = competitionData as? [String: Any] else { continue }
            
            do {
                // Add ID to dictionary if not present
                var mutableDict = competitionDict
                if mutableDict["id"] == nil {
                    mutableDict["id"] = competitionId
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: mutableDict)
                let decoder = JSONDecoder()
                let competition = try decoder.decode(Competition.self, from: jsonData)
                
                // Only include active, non-expired competitions
                if competition.isActive && !competition.isExpired {
                    competitions.append(competition)
                }
                
            } catch {
                print("❌ [Competitions] Failed to decode \(competitionId): \(error)")
            }
        }
        
        // Sort: Featured first, then sponsored, then by end date
        return competitions.sorted { comp1, comp2 in
            if comp1.tier != comp2.tier {
                return comp1.tier.sortOrder < comp2.tier.sortOrder
            }
            return comp1.endsAt < comp2.endsAt // Ending sooner first
        }
    }
    
    /// Fetch competitions filtered by user's games
    func fetchCompetitionsForUser(userGames: [String]) async throws -> [Competition] {
        let allCompetitions = try await fetchCompetitions()
        
        return allCompetitions.filter { competition in
            // If no game slug required, show to everyone
            guard let requiredSlug = competition.gameSlug, !requiredSlug.isEmpty else {
                return true
            }
            
            // Check if user has the required game
            let normalizedRequired = normalizeSlug(requiredSlug)
            return userGames.contains { normalizeSlug($0) == normalizedRequired }
        }
    }
    
    /// Fetch a single competition by ID
    func fetchCompetition(id: String) async throws -> Competition? {
        let snapshot = try await database
            .child("Competitions")
            .child(id)
            .getData()
        
        guard snapshot.exists(),
              var competitionDict = snapshot.value as? [String: Any] else {
            return nil
        }
        
        // Add ID if not present
        if competitionDict["id"] == nil {
            competitionDict["id"] = id
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: competitionDict)
        return try JSONDecoder().decode(Competition.self, from: jsonData)
    }
    
    // MARK: - User Entries
    
    /// Fetch all entries for a user across all competitions
    func fetchUserEntries(userId: String) async throws -> [CompetitionEntry] {
        let snapshot = try await database
            .child("CompetitionEntries")
            .child(userId)
            .getData()
        
        guard snapshot.exists(),
              let value = snapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        var entries: [CompetitionEntry] = []
        
        for (entryId, entryData) in value {
            do {
                var mutableDict = entryData
                if mutableDict["id"] == nil {
                    mutableDict["id"] = entryId
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: mutableDict)
                let entry = try JSONDecoder().decode(CompetitionEntry.self, from: jsonData)
                entries.append(entry)
                
            } catch {
                print("❌ [Entries] Failed to decode \(entryId): \(error)")
            }
        }
        
        // Sort by submission date (newest first)
        return entries.sorted { $0.submittedAt > $1.submittedAt }
    }
    
    /// Fetch entries for a specific competition by user
    func fetchUserEntriesForCompetition(userId: String, competitionId: String) async throws -> [CompetitionEntry] {
        let allEntries = try await fetchUserEntries(userId: userId)
        return allEntries.filter { $0.competitionId == competitionId }
    }
    
    /// Get quick summary of user's participation in a competition
    func fetchUserCompetitionSummary(userId: String, competitionId: String) async throws -> UserCompetitionSummary {
        let entries = try await fetchUserEntriesForCompetition(userId: userId, competitionId: competitionId)
        
        let latestEntry = entries.first // Already sorted newest first
        let hasWon = entries.contains { $0.status == .approved }
        
        return UserCompetitionSummary(
            competitionId: competitionId,
            userId: userId,
            attemptsUsed: entries.count,
            latestEntryId: latestEntry?.id,
            latestStatus: latestEntry?.status,
            hasWon: hasWon
        )
    }
    
    /// Fetch summaries for all competitions user has entered
    func fetchAllUserCompetitionSummaries(userId: String) async throws -> [String: UserCompetitionSummary] {
        let entries = try await fetchUserEntries(userId: userId)
        
        // Group by competition ID
        var summaries: [String: UserCompetitionSummary] = [:]
        var entriesByCompetition: [String: [CompetitionEntry]] = [:]
        
        for entry in entries {
            entriesByCompetition[entry.competitionId, default: []].append(entry)
        }
        
        for (competitionId, competitionEntries) in entriesByCompetition {
            let latestEntry = competitionEntries.sorted { $0.submittedAt > $1.submittedAt }.first
            let hasWon = competitionEntries.contains { $0.status == .approved }
            
            summaries[competitionId] = UserCompetitionSummary(
                competitionId: competitionId,
                userId: userId,
                attemptsUsed: competitionEntries.count,
                latestEntryId: latestEntry?.id,
                latestStatus: latestEntry?.status,
                hasWon: hasWon
            )
        }
        
        return summaries
    }
    
    // MARK: - Submit Entry
    
    /// Submit a new entry for a competition
    func submitEntry(
        competitionId: String,
        userId: String,
        submissionUrl: String,
        submissionType: SubmissionType,
        caption: String?
    ) async throws -> CompetitionEntry {
        // First check attempt count
        let existingEntries = try await fetchUserEntriesForCompetition(
            userId: userId,
            competitionId: competitionId
        )
        
        guard existingEntries.count < 3 else {
            throw CompetitionError.maxAttemptsReached
        }
        
        // Check if already won
        if existingEntries.contains(where: { $0.status == .approved }) {
            throw CompetitionError.alreadyWon
        }
        
        let entryId = UUID().uuidString
        let attemptNumber = existingEntries.count + 1
        
        let entryData: [String: Any] = [
            "id": entryId,
            "competition_id": competitionId,
            "user_id": userId,
            "attempt_number": attemptNumber,
            "submission_url": submissionUrl,
            "submission_type": submissionType.rawValue,
            "caption": caption ?? "",
            "status": EntryStatus.pending.rawValue,
            "submitted_at": Date().timeIntervalSince1970
        ]
        
        // Save to Firebase
        try await database
            .child("CompetitionEntries")
            .child(userId)
            .child(entryId)
            .setValue(entryData)
        
        // Also index by competition for admin/judge queries
        try await database
            .child("CompetitionEntriesByCompetition")
            .child(competitionId)
            .child(entryId)
            .setValue([
                "user_id": userId,
                "status": EntryStatus.pending.rawValue,
                "submitted_at": Date().timeIntervalSince1970
            ])
        
        // Increment total entries on competition
        try await database
            .child("Competitions")
            .child(competitionId)
            .child("total_entries")
            .runTransactionBlock { currentData in
                let current = currentData.value as? Int ?? 0
                currentData.value = current + 1
                return .success(withValue: currentData)
            }
        
        print("✅ [Competitions] Submitted entry \(entryId) for competition \(competitionId)")
        
        return CompetitionEntry(
            id: entryId,
            competitionId: competitionId,
            userId: userId,
            attemptNumber: attemptNumber,
            submissionUrl: submissionUrl,
            submissionType: submissionType,
            caption: caption,
            status: .pending,
            submittedAt: Date().timeIntervalSince1970,
            reviewedAt: nil,
            reviewedBy: nil,
            xpAwarded: nil
        )
    }
    
    /// Delete/withdraw an entry (only if still pending)
    func withdrawEntry(entryId: String, userId: String, competitionId: String) async throws {
        // Verify entry exists and is pending
        let snapshot = try await database
            .child("CompetitionEntries")
            .child(userId)
            .child(entryId)
            .getData()
        
        guard snapshot.exists(),
              let data = snapshot.value as? [String: Any],
              let statusRaw = data["status"] as? String,
              let status = EntryStatus(rawValue: statusRaw),
              status == .pending else {
            throw CompetitionError.cannotWithdraw
        }
        
        // Delete from user's entries
        try await database
            .child("CompetitionEntries")
            .child(userId)
            .child(entryId)
            .removeValue()
        
        // Delete from competition index
        try await database
            .child("CompetitionEntriesByCompetition")
            .child(competitionId)
            .child(entryId)
            .removeValue()
        
        // Decrement total entries
        try await database
            .child("Competitions")
            .child(competitionId)
            .child("total_entries")
            .runTransactionBlock { currentData in
                let current = currentData.value as? Int ?? 0
                currentData.value = max(0, current - 1)
                return .success(withValue: currentData)
            }
        
        print("✅ [Competitions] Withdrew entry \(entryId)")
    }
    
    // MARK: - Helpers
    
    private func normalizeSlug(_ slug: String) -> String {
        return slug
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Competition Tier Sort Order

extension CompetitionTier {
    var sortOrder: Int {
        switch self {
        case .featured: return 0
        case .sponsored: return 1
        case .regular: return 2
        }
    }
}

// MARK: - Competition Errors

enum CompetitionError: LocalizedError {
    case maxAttemptsReached
    case alreadyWon
    case cannotWithdraw
    case competitionNotFound
    case competitionEnded
    
    var errorDescription: String? {
        switch self {
        case .maxAttemptsReached:
            return "You've reached the maximum number of attempts (3) for this challenge."
        case .alreadyWon:
            return "You've already won this challenge!"
        case .cannotWithdraw:
            return "You can only withdraw entries that are still pending review."
        case .competitionNotFound:
            return "This challenge could not be found."
        case .competitionEnded:
            return "This challenge has ended."
        }
    }
}
