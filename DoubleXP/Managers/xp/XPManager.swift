//
//  XPManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import FirebaseDatabase
import Combine

// MARK: - XP Manager

/// Singleton responsible for managing user XP, levels, and progression
/// 
/// ## XP & Leveling System Design
///
/// ### Level Thresholds
/// We use a progressive XP curve where each level requires more XP than the last.
/// This keeps early levels achievable while making higher levels feel prestigious.
///
/// Formula: XP required for level N = baseXP * (N ^ scaleFactor)
/// - baseXP = 100 (XP to reach level 2)
/// - scaleFactor = 1.5 (how quickly XP requirements grow)
///
/// Example progression:
/// - Level 1 → 2: 100 XP
/// - Level 2 → 3: 283 XP (total: 383)
/// - Level 5 → 6: 1,118 XP (total: ~3,500)
/// - Level 10 → 11: 3,162 XP (total: ~15,000)
/// - Level 15 → 16: 5,809 XP (total: ~38,000)
/// - Level 20 → 21: 8,944 XP (total: ~75,000)
/// - Level 50 → 51: 35,355 XP (total: ~600,000)
///
/// ### XP Sources
/// - Completing challenges: 100-1000 XP (based on difficulty)
/// - Daily login: 25 XP
/// - Profile completion: 50 XP per section
/// - Social actions (adding friends, joining groups): 10-25 XP
/// - Quiz completions: 50-200 XP
/// - Achievement unlocks: 100-500 XP
///
/// ### XP Caps & Limits
/// - Daily XP cap from challenges: 2,000 XP (prevents farming)
/// - XP cooldown: Same challenge type limited to 3x per day
/// - Bonus XP events: 1.5x or 2x multipliers during special events
///
/// ### Level Rewards (Future)
/// - Level 5: Unlock custom profile themes
/// - Level 10: Unlock exclusive Poko
/// - Level 15: Unlock judge capabilities
/// - Level 20: Unlock challenge creation
/// - Level 25+: Prestige badges
///
@MainActor
final class XPManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = XPManager()
    
    // MARK: - Published Properties
    
    @Published var totalXP: Int = 0
    @Published private(set) var currentLevel: Int = 1
    @Published private(set) var xpInCurrentLevel: Int = 0
    @Published private(set) var xpRequiredForNextLevel: Int = 100
    @Published var xpToNextLevel: Int = 0
    @Published private(set) var levelProgress: Double = 0.0 // 0.0 to 1.0
    
    @Published private(set) var dailyXPEarned: Int = 0
    @Published private(set) var dailyXPCap: Int = 2000
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastUpdated: Date?
    
    // MARK: - Constants
    
    private let baseXP: Double = 100
    private let scaleFactor: Double = 1.5
    private let maxLevel: Int = 100
    
    // MARK: - Firebase
    
    private let database = Database.database().reference()
    private var xpListener: DatabaseHandle?
    private var currentUserId: String?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public API
    
    /// Load XP for a user and start observing changes
    /// Call this during app startup (PreSplashViewModel)
    func loadXP(for userId: String) async {
        currentUserId = userId
        isLoading = true
        
        do {
            // Fetch current XP
            let snapshot = try await database
                .child("Users")
                .child(userId)
                .child("xp")
                .getData()
            
            let xp = snapshot.value as? Int ?? 0
            updateXP(xp)
            
            // Start observing for live updates
            startObserving(userId: userId)
            
            // Check daily XP (reset if new day)
            await checkDailyXPReset(userId: userId)
            
            isLoading = false
            lastUpdated = Date()
            
            print("✅ [XPManager] Loaded XP: \(xp) (Level \(currentLevel))")
            
        } catch {
            print("❌ [XPManager] Failed to load XP: \(error)")
            isLoading = false
        }
    }
    
    /// Add XP to the user's total
    /// Returns the actual XP added (may be capped by daily limit)
    @discardableResult
    func addXP(_ amount: Int, source: XPSource) async -> Int {
        guard let userId = currentUserId else {
            print("❌ [XPManager] No user ID set")
            return 0
        }
        
        // Check daily cap for challenge XP
        var actualAmount = amount
        if source.countsTowardDailyCap {
            let remainingDaily = dailyXPCap - dailyXPEarned
            actualAmount = min(amount, remainingDaily)
            
            if actualAmount < amount {
                print("⚠️ [XPManager] XP capped by daily limit. Requested: \(amount), Awarded: \(actualAmount)")
            }
        }
        
        guard actualAmount > 0 else {
            print("⚠️ [XPManager] Daily XP cap reached")
            return 0
        }
        
        let newTotal = totalXP + actualAmount
        
        do {
            // Update Firebase
            try await database
                .child("Users")
                .child(userId)
                .child("xp")
                .setValue(newTotal)
            
            // Update daily XP tracking
            if source.countsTowardDailyCap {
                dailyXPEarned += actualAmount
                try await saveDailyXP(userId: userId)
            }
            
            // Log XP transaction
            try await logXPTransaction(
                userId: userId,
                amount: actualAmount,
                source: source,
                newTotal: newTotal
            )
            
            // Local update will happen via observer
            print("✅ [XPManager] Added \(actualAmount) XP from \(source.rawValue). New total: \(newTotal)")
            
            // Check for level up
            let oldLevel = currentLevel
            updateXP(newTotal)
            
            if currentLevel > oldLevel {
                NotificationCenter.default.post(
                    name: .userDidLevelUp,
                    object: nil,
                    userInfo: ["oldLevel": oldLevel, "newLevel": currentLevel]
                )
            }
            
            return actualAmount
            
        } catch {
            print("❌ [XPManager] Failed to add XP: \(error)")
            return 0
        }
    }
    
    /// Get XP required to reach a specific level (from level 1)
    func totalXPRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        
        var total = 0
        for lvl in 2...level {
            total += xpRequired(forLevel: lvl)
        }
        return total
    }
    
    /// Get XP required to go from level (n-1) to level n
    func xpRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(baseXP * pow(Double(level), scaleFactor))
    }
    
    /// Calculate level from total XP
    func level(fromTotalXP xp: Int) -> Int {
        var level = 1
        var xpAccumulated = 0
        
        while level < maxLevel {
            let nextLevelXP = xpRequired(forLevel: level + 1)
            if xpAccumulated + nextLevelXP > xp {
                break
            }
            xpAccumulated += nextLevelXP
            level += 1
        }
        
        return level
    }
    
    /// Stop observing (call on logout)
    func stopObserving() {
        if let handle = xpListener, let userId = currentUserId {
            database
                .child("Users")
                .child(userId)
                .child("xp")
                .removeObserver(withHandle: handle)
        }
        xpListener = nil
        currentUserId = nil
    }
    
    // MARK: - Private Helpers
    
    private func updateXP(_ xp: Int) {
        totalXP = xp
        currentLevel = level(fromTotalXP: xp)
        
        let xpForCurrentLevel = totalXPRequired(forLevel: currentLevel)
        let xpForNextLevel = totalXPRequired(forLevel: currentLevel + 1)
        
        xpInCurrentLevel = xp - xpForCurrentLevel
        xpRequiredForNextLevel = xpForNextLevel - xpForCurrentLevel
        xpToNextLevel = xpForNextLevel - xp
        
        levelProgress = Double(xpInCurrentLevel) / Double(xpRequiredForNextLevel)
    }
    
    private func startObserving(userId: String) {
        // Remove existing observer
        stopObserving()
        
        currentUserId = userId
        
        xpListener = database
            .child("Users")
            .child(userId)
            .child("xp")
            .observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let xp = snapshot.value as? Int {
                        self.updateXP(xp)
                        self.lastUpdated = Date()
                    }
                }
            }
    }
    
    private func checkDailyXPReset(userId: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        
        do {
            let snapshot = try await database
                .child("Users")
                .child(userId)
                .child("dailyXP")
                .getData()
            
            if let data = snapshot.value as? [String: Any],
               let lastReset = data["lastReset"] as? TimeInterval,
               lastReset >= todayTimestamp {
                // Same day, load existing daily XP
                dailyXPEarned = data["earned"] as? Int ?? 0
            } else {
                // New day, reset daily XP
                dailyXPEarned = 0
                try await saveDailyXP(userId: userId)
            }
            
        } catch {
            print("❌ [XPManager] Failed to check daily XP: \(error)")
        }
    }
    
    private func saveDailyXP(userId: String) async throws {
        let today = Calendar.current.startOfDay(for: Date())
        
        try await database
            .child("Users")
            .child(userId)
            .child("dailyXP")
            .setValue([
                "earned": dailyXPEarned,
                "lastReset": today.timeIntervalSince1970
            ])
    }
    
    private func logXPTransaction(
        userId: String,
        amount: Int,
        source: XPSource,
        newTotal: Int
    ) async throws {
        let transactionId = UUID().uuidString
        let transaction: [String: Any] = [
            "user_id": userId,
            "amount": amount,
            "source": source.rawValue,
            "new_total": newTotal,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        try await database
            .child("XPTransactions")
            .child(userId)
            .child(transactionId)
            .setValue(transaction)
    }
}

// MARK: - XP Source

enum XPSource: String {
    case challengeCompletion = "challenge_completion"
    case dailyLogin = "daily_login"
    case profileCompletion = "profile_completion"
    case socialAction = "social_action"
    case quizCompletion = "quiz_completion"
    case achievement = "achievement"
    case bonus = "bonus"
    case admin = "admin" // Manual adjustment by admin
    
    var countsTowardDailyCap: Bool {
        switch self {
        case .challengeCompletion:
            return true
        default:
            return false
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userDidLevelUp = Notification.Name("userDidLevelUp")
    static let userXPDidChange = Notification.Name("userXPDidChange")
}

// MARK: - Level Info Helper

struct LevelInfo {
    let level: Int
    let title: String
    let badgeColor: String
    
    static func info(for level: Int) -> LevelInfo {
        let title: String
        let color: String
        
        switch level {
        case 1...4:
            title = "Rookie"
            color = "808080" // Gray
        case 5...9:
            title = "Challenger"
            color = "4ADE80" // Green
        case 10...14:
            title = "Competitor"
            color = "22D3EE" // Cyan
        case 15...19:
            title = "Veteran"
            color = "A855F7" // Purple
        case 20...29:
            title = "Elite"
            color = "FF6B6B" // Red
        case 30...49:
            title = "Master"
            color = "FFD700" // Gold
        case 50...74:
            title = "Grandmaster"
            color = "FF8E53" // Orange
        case 75...99:
            title = "Legend"
            color = "FF4757" // Hot Red
        case 100:
            title = "Mythic"
            color = "FFFFFF" // White/Rainbow
        default:
            title = "Unknown"
            color = "808080"
        }
        
        return LevelInfo(
            level: level,
            title: title,
            badgeColor: color
        )
    }
    
    /// Get total XP required - must be called from MainActor context
    @MainActor
    static func totalXPRequired(forLevel level: Int) -> Int {
        return XPManager.shared.totalXPRequired(forLevel: level)
    }
}
