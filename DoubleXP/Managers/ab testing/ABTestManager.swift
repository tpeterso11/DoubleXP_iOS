//
//  ABTestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseDatabase
import SwiftUI

// MARK: - A/B Test Definitions

/// Define all A/B tests in your app here
enum ABTest: String, CaseIterable {
    case levelUpCelebration = "level_up_celebration"
    case onboardingFlow = "onboarding_flow"
    case feedLayout = "feed_layout"
    // Add more tests as needed
    
    /// Default variant if assignment fails
    var defaultVariant: String {
        switch self {
        case .levelUpCelebration: return LevelUpVariant.fullScreen.rawValue
        case .onboardingFlow: return "control"
        case .feedLayout: return "control"
        }
    }
    
    /// All possible variants for this test
    var variants: [String] {
        switch self {
        case .levelUpCelebration:
            return LevelUpVariant.allCases.map { $0.rawValue }
        case .onboardingFlow:
            return ["control", "streamlined", "gamified"]
        case .feedLayout:
            return ["control", "compact", "immersive"]
        }
    }
    
    /// Weight distribution for random assignment (must sum to 1.0)
    /// Format: [variant: weight]
    var variantWeights: [String: Double] {
        switch self {
        case .levelUpCelebration:
            return [
                LevelUpVariant.fullScreen.rawValue: 0.5,
                LevelUpVariant.bannerDrop.rawValue: 0.5
            ]
        case .onboardingFlow:
            return ["control": 0.34, "streamlined": 0.33, "gamified": 0.33]
        case .feedLayout:
            return ["control": 0.5, "compact": 0.25, "immersive": 0.25]
        }
    }
}

// MARK: - Level Up Celebration Variants

enum LevelUpVariant: String, CaseIterable {
    case fullScreen = "full_screen"      // Group A
    case bannerDrop = "banner_drop"      // Group B
    
    var displayName: String {
        switch self {
        case .fullScreen: return "Full Screen Takeover"
        case .bannerDrop: return "Banner Drop"
        }
    }
}

// MARK: - A/B Test Assignment

struct ABTestAssignment: Codable {
    let testId: String
    let variant: String
    let assignedAt: TimeInterval
    let source: AssignmentSource
    
    enum AssignmentSource: String, Codable {
        case random = "random"           // Assigned randomly at registration
        case override = "override"       // Admin override
        case migration = "migration"     // Migrated from old system
    }
}

// MARK: - A/B Test Manager

@MainActor
class ABTestManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ABTestManager()
    
    // MARK: - Published State
    
    @Published private(set) var assignments: [String: ABTestAssignment] = [:]
    @Published private(set) var overrides: [String: String] = [:]  // testId: forcedVariant
    @Published private(set) var isLoaded: Bool = false
    
    // MARK: - Firebase
    
    private let database = Database.database().reference()
    private var currentUserId: String?
    
    // MARK: - Local Cache
    
    private let cacheKey = "ab_test_assignments"
    private let overrideCacheKey = "ab_test_overrides"
    
    // MARK: - Init
    
    private init() {
        loadLocalOverrides()
    }
    
    // MARK: - Public API
    
    /// Load A/B test assignments for a user (call after login/registration)
    func loadAssignments(for userId: String) async {
        currentUserId = userId
        
        do {
            let snapshot = try await database
                .child("Users")
                .child(userId)
                .child("ab_tests")
                .getData()
            
            if let data = snapshot.value as? [String: [String: Any]] {
                var loaded: [String: ABTestAssignment] = [:]
                
                for (testId, values) in data {
                    if let variant = values["variant"] as? String,
                       let assignedAt = values["assigned_at"] as? TimeInterval,
                       let sourceRaw = values["source"] as? String,
                       let source = ABTestAssignment.AssignmentSource(rawValue: sourceRaw) {
                        loaded[testId] = ABTestAssignment(
                            testId: testId,
                            variant: variant,
                            assignedAt: assignedAt,
                            source: source
                        )
                    }
                }
                
                assignments = loaded
                cacheAssignments()
                
                print("✅ [ABTestManager] Loaded \(loaded.count) test assignments")
                
                // Check for missing tests and assign them (handles new tests added after user registered)
                await assignMissingTests(userId: userId, existingAssignments: loaded)
                
            } else {
                // No assignments yet - this is an existing user, auto-assign them
                print("ℹ️ [ABTestManager] No A/B test assignments found - auto-assigning existing user")
                let _ = await assignNewUser(userId: userId)
            }
            
            // Load global overrides from Firebase
            await loadGlobalOverrides()
            
            isLoaded = true
            
        } catch {
            print("❌ [ABTestManager] Failed to load assignments: \(error)")
            // Fall back to cached assignments
            loadCachedAssignments()
            isLoaded = true
        }
    }
    
    /// Assign user to all active A/B tests (call during registration)
    func assignNewUser(userId: String) async -> [String: String] {
        currentUserId = userId
        var newAssignments: [String: String] = [:]
        
        for test in ABTest.allCases {
            let variant = selectVariant(for: test)
            let assignment = ABTestAssignment(
                testId: test.rawValue,
                variant: variant,
                assignedAt: Date().timeIntervalSince1970,
                source: .random
            )
            
            // Save to Firebase
            do {
                try await saveAssignment(assignment, for: userId)
                assignments[test.rawValue] = assignment
                newAssignments[test.rawValue] = variant
                
                print("✅ [ABTestManager] Assigned \(userId) to \(test.rawValue): \(variant)")
            } catch {
                print("❌ [ABTestManager] Failed to assign \(test.rawValue): \(error)")
            }
        }
        
        // Log assignment event for analytics
        await logAssignmentEvent(userId: userId, assignments: newAssignments)
        
        cacheAssignments()
        isLoaded = true
        
        return newAssignments
    }
    
    /// Get the variant for a specific test
    func variant(for test: ABTest) -> String {
        // Check local override first (for testing)
        if let localOverride = overrides[test.rawValue] {
            print("🔧 [ABTestManager] Using local override for \(test.rawValue): \(localOverride)")
            return localOverride
        }
        
        // Check assignment
        if let assignment = assignments[test.rawValue] {
            return assignment.variant
        }
        
        // Fall back to default
        print("⚠️ [ABTestManager] No assignment for \(test.rawValue), using default")
        return test.defaultVariant
    }
    
    /// Get typed variant for Level Up test
    func levelUpVariant() -> LevelUpVariant {
        let variantString = variant(for: .levelUpCelebration)
        return LevelUpVariant(rawValue: variantString) ?? .fullScreen
    }
    
    /// Set a local override (for testing/debugging)
    func setLocalOverride(for test: ABTest, variant: String?) {
        if let variant = variant {
            overrides[test.rawValue] = variant
            print("🔧 [ABTestManager] Set local override: \(test.rawValue) = \(variant)")
        } else {
            overrides.removeValue(forKey: test.rawValue)
            print("🔧 [ABTestManager] Cleared local override for \(test.rawValue)")
        }
        saveLocalOverrides()
        objectWillChange.send()
    }
    
    /// Clear all local overrides
    func clearAllOverrides() {
        overrides.removeAll()
        saveLocalOverrides()
        objectWillChange.send()
        print("🔧 [ABTestManager] Cleared all local overrides")
    }
    
    /// Check if user has a specific variant
    func isInVariant(_ variant: String, for test: ABTest) -> Bool {
        return self.variant(for: test) == variant
    }
    
    /// Log an event for a specific test (for analytics)
    func logExposure(for test: ABTest) async {
        guard let userId = currentUserId else { return }
        
        let exposureData: [String: Any] = [
            "test_id": test.rawValue,
            "variant": variant(for: test),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let exposureId = UUID().uuidString
            try await database
                .child("ABTestExposures")
                .child(userId)
                .child(exposureId)
                .setValue(exposureData)
            
            print("📊 [ABTestManager] Logged exposure for \(test.rawValue)")
        } catch {
            print("❌ [ABTestManager] Failed to log exposure: \(error)")
        }
    }
    
    /// Log a conversion event for a test
    func logConversion(for test: ABTest, eventName: String, metadata: [String: Any]? = nil) async {
        guard let userId = currentUserId else { return }
        
        var conversionData: [String: Any] = [
            "test_id": test.rawValue,
            "variant": variant(for: test),
            "event": eventName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let metadata = metadata {
            conversionData["metadata"] = metadata
        }
        
        do {
            let conversionId = UUID().uuidString
            try await database
                .child("ABTestConversions")
                .child(userId)
                .child(conversionId)
                .setValue(conversionData)
            
            print("📊 [ABTestManager] Logged conversion for \(test.rawValue): \(eventName)")
        } catch {
            print("❌ [ABTestManager] Failed to log conversion: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Select a variant based on weights
    private func selectVariant(for test: ABTest) -> String {
        let weights = test.variantWeights
        let random = Double.random(in: 0..<1)
        
        var cumulative: Double = 0
        for (variant, weight) in weights.sorted(by: { $0.key < $1.key }) {
            cumulative += weight
            if random < cumulative {
                return variant
            }
        }
        
        return test.defaultVariant
    }
    
    /// Assign any missing tests for an existing user (handles new tests added after registration)
    private func assignMissingTests(userId: String, existingAssignments: [String: ABTestAssignment]) async {
        var newAssignments: [String: String] = [:]
        
        for test in ABTest.allCases {
            // Skip if already assigned
            if existingAssignments[test.rawValue] != nil {
                continue
            }
            
            // Assign this missing test
            let variant = selectVariant(for: test)
            let assignment = ABTestAssignment(
                testId: test.rawValue,
                variant: variant,
                assignedAt: Date().timeIntervalSince1970,
                source: .migration  // Mark as migration since user already existed
            )
            
            do {
                try await saveAssignment(assignment, for: userId)
                assignments[test.rawValue] = assignment
                newAssignments[test.rawValue] = variant
                
                print("✅ [ABTestManager] Auto-assigned missing test \(test.rawValue): \(variant)")
            } catch {
                print("❌ [ABTestManager] Failed to assign missing test \(test.rawValue): \(error)")
            }
        }
        
        if !newAssignments.isEmpty {
            // Log the new assignments
            await logAssignmentEvent(userId: userId, assignments: newAssignments)
            cacheAssignments()
            
            print("✅ [ABTestManager] Assigned \(newAssignments.count) missing tests for existing user")
        }
    }
    
    /// Save assignment to Firebase
    private func saveAssignment(_ assignment: ABTestAssignment, for userId: String) async throws {
        let data: [String: Any] = [
            "variant": assignment.variant,
            "assigned_at": assignment.assignedAt,
            "source": assignment.source.rawValue
        ]
        
        try await database
            .child("Users")
            .child(userId)
            .child("ab_tests")
            .child(assignment.testId)
            .setValue(data)
    }
    
    /// Load global overrides (admin can force variants for all users)
    private func loadGlobalOverrides() async {
        do {
            let snapshot = try await database
                .child("ABTestConfig")
                .child("global_overrides")
                .getData()
            
            if let data = snapshot.value as? [String: String] {
                // Merge global overrides (local overrides take precedence)
                for (testId, variant) in data {
                    if overrides[testId] == nil {
                        overrides[testId] = variant
                    }
                }
                print("ℹ️ [ABTestManager] Loaded \(data.count) global overrides")
            }
        } catch {
            print("⚠️ [ABTestManager] Failed to load global overrides: \(error)")
        }
    }
    
    /// Log assignment event for analytics
    private func logAssignmentEvent(userId: String, assignments: [String: String]) async {
        let eventData: [String: Any] = [
            "user_id": userId,
            "assignments": assignments,
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        do {
            try await database
                .child("ABTestAssignmentLogs")
                .childByAutoId()
                .setValue(eventData)
        } catch {
            print("⚠️ [ABTestManager] Failed to log assignment event: \(error)")
        }
    }
    
    // MARK: - Local Cache
    
    private func cacheAssignments() {
        if let data = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    private func loadCachedAssignments() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: ABTestAssignment].self, from: data) {
            assignments = cached
            print("📦 [ABTestManager] Loaded cached assignments")
        }
    }
    
    private func saveLocalOverrides() {
        UserDefaults.standard.set(overrides, forKey: overrideCacheKey)
    }
    
    private func loadLocalOverrides() {
        if let cached = UserDefaults.standard.dictionary(forKey: overrideCacheKey) as? [String: String] {
            overrides = cached
        }
    }
}

// MARK: - SwiftUI Environment

private struct ABTestManagerKey: EnvironmentKey {
    static let defaultValue = ABTestManager.shared
}

extension EnvironmentValues {
    var abTestManager: ABTestManager {
        get { self[ABTestManagerKey.self] }
        set { self[ABTestManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Modifier for A/B Testing

struct ABTestModifier<VariantA: View, VariantB: View>: View {
    let test: ABTest
    let variantAKey: String
    let variantA: () -> VariantA
    let variantB: () -> VariantB
    
    @ObservedObject private var manager = ABTestManager.shared
    
    init(
        test: ABTest,
        variantAKey: String,
        @ViewBuilder variantA: @escaping () -> VariantA,
        @ViewBuilder variantB: @escaping () -> VariantB
    ) {
        self.test = test
        self.variantAKey = variantAKey
        self.variantA = variantA
        self.variantB = variantB
    }
    
    var body: some View {
        Group {
            if manager.variant(for: test) == variantAKey {
                variantA()
            } else {
                variantB()
            }
        }
        .task {
            await manager.logExposure(for: test)
        }
    }
}

// MARK: - Convenience View Extension

extension View {
    /// A/B test between two views
    @ViewBuilder
    func abTest<VariantB: View>(
        _ test: ABTest,
        variantAKey: String,
        @ViewBuilder variantB: @escaping () -> VariantB
    ) -> some View {
        ABTestModifier(
            test: test,
            variantAKey: variantAKey,
            variantA: { self },
            variantB: variantB
        )
    }
}

// MARK: - Debug View for A/B Tests

#if DEBUG
struct ABTestDebugView: View {
    @ObservedObject private var manager = ABTestManager.shared
    @State private var selectedTest: ABTest = .levelUpCelebration
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Assignments") {
                    ForEach(ABTest.allCases, id: \.rawValue) { test in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text(manager.variant(for: test))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if manager.overrides[test.rawValue] != nil {
                                Text("Override")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Section("Override Test") {
                    Picker("Test", selection: $selectedTest) {
                        ForEach(ABTest.allCases, id: \.rawValue) { test in
                            Text(test.rawValue).tag(test)
                        }
                    }
                    
                    ForEach(selectedTest.variants, id: \.self) { variant in
                        Button {
                            manager.setLocalOverride(for: selectedTest, variant: variant)
                        } label: {
                            HStack {
                                Text(variant)
                                Spacer()
                                if manager.variant(for: selectedTest) == variant {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    Button("Clear Override", role: .destructive) {
                        manager.setLocalOverride(for: selectedTest, variant: nil)
                    }
                }
                
                Section {
                    Button("Clear All Overrides", role: .destructive) {
                        manager.clearAllOverrides()
                    }
                }
            }
            .navigationTitle("A/B Tests")
        }
    }
}
#endif
