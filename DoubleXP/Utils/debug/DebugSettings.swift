//
//  DebugSettings.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/7/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation
import Combine

enum FirebaseDatabaseEnvironment: String, CaseIterable {
    case production = "prod"
    case development = "dev"
    
    var displayName: String {
        switch self {
        case .production: return "Production"
        case .development: return "Development"
        }
    }
    
    var shortName: String {
        switch self {
        case .production: return "PROD"
        case .development: return "DEV"
        }
    }
    
    var baseURL: String {
        switch self {
        case .production:
            return "https://gameterminal-767f7.firebaseio.com"
        case .development:
            return "https://gameterminal-767f7-51e0e.firebaseio.com"
        }
    }
    
    var color: String {
        switch self {
        case .production: return "EF4444" // Red
        case .development: return "22C55E" // Green
        }
    }
}

@MainActor
final class DebugSettings: ObservableObject {
    static let shared = DebugSettings()
    
    // MARK: - Game API Toggles
    
    /// When ON, uses hardcoded mock data instead of real API calls
    @Published var mockGameAPI: Bool {
        didSet { persist("dbg.mockGameAPI", value: mockGameAPI) }
    }
    
    /// When ON, uses cached API responses instead of making new network calls
    @Published var useCachedGameResponses: Bool {
        didSet { persist("dbg.useCachedGameResponses", value: useCachedGameResponses) }
    }
    
    /// When ON, automatically caches real API responses for later use
    @Published var cacheGameResponses: Bool {
        didSet { persist("dbg.cacheGameResponses", value: cacheGameResponses) }
    }
    
    // MARK: - Feed Data Toggles
    
    @Published var mockFeedHeader: Bool {
        didSet { persist("dbg.mockFeedHeader", value: mockFeedHeader) }
    }
    
    /// Feed data source: "live", "cached", "mock"
    @Published var feedDataSource: String {
        didSet { persist("dbg.feedDataSource", value: feedDataSource) }
    }
    
    /// Header data source: "live", "cached", "mock"
    @Published var headerDataSource: String {
        didSet { persist("dbg.headerDataSource", value: headerDataSource) }
    }
    
    /// When ON, automatically caches feed API responses for later use
    @Published var cacheFeedResponses: Bool {
        didSet { persist("dbg.cacheFeedResponses", value: cacheFeedResponses) }
    }
    
    // MARK: - Gaming Experience Override
    
    /// When ON, uses the debug gaming experience value instead of the database value
    @Published var overrideGamingExperience: Bool {
        didSet { persist("dbg.overrideGamingExperience", value: overrideGamingExperience) }
    }
    
    /// Debug gaming experience value (1-5)
    @Published var debugGamingExperience: Int {
        didSet {
            // Clamp to valid range
            let clamped = max(1, min(5, debugGamingExperience))
            if clamped != debugGamingExperience {
                debugGamingExperience = clamped
            }
            persistInt("dbg.debugGamingExperience", value: clamped)
        }
    }
    
    /// Returns the effective gaming experience value to use
    /// - If debug override is enabled, returns the debug value
    /// - Otherwise, returns the database value from UserProvider
    var effectiveGamingExperience: String {
        #if DEBUG
        if overrideGamingExperience {
            return String(debugGamingExperience)
        }
        #endif
        // Return database value (or default "5" if not available)
        return UserProvider.shared.currentUser?.gamingExperience ?? "1"
    }
    
    /// Returns the effective gaming experience as an Int
    var effectiveGamingExperienceInt: Int {
        return Int(effectiveGamingExperience) ?? 5
    }
    
    /// Returns info about current gaming experience source for display
    var gamingExperienceSourceInfo: String {
        #if DEBUG
        if overrideGamingExperience {
            return "Debug: \(debugGamingExperience)"
        }
        #endif
        let dbValue = UserProvider.shared.currentUser?.gamingExperience ?? "1"
        return "Database: \(dbValue)"
    }
    
    // MARK: - Network Simulation
    
    @Published var networkSimEnabled: Bool {
        didSet { persist("dbg.networkSimEnabled", value: networkSimEnabled) }
    }
    
    @Published var networkLatencyMs: Int {
        didSet { persistInt("dbg.networkLatencyMs", value: networkLatencyMs) }
    }
    
    @Published var networkJitterMs: Int {
        didSet { persistInt("dbg.networkJitterMs", value: networkJitterMs) }
    }
    
    @Published var networkFailurePct: Int {
        didSet { persistInt("dbg.networkFailurePct", value: networkFailurePct) }
    }
    
    @Published var networkTimeoutPct: Int {
        didSet { persistInt("dbg.networkTimeoutPct", value: networkTimeoutPct) }
    }
    
    // MARK: - Static Helpers
    
    static var isDebugRuntime: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Cache Keys
    
    private let viewedGamesKey = "GamerConnect_ViewedGameIDs"
    private let cachedGamesResponseKey = "dbg.cachedGamesResponse"
    private let cachedSearchResponseKey = "dbg.cachedSearchResponse"
    private let cachedGenresResponseKey = "dbg.cachedGenresResponse"
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted values with defaults
        self.mockGameAPI = Self.load("dbg.mockGameAPI", default: false)
        self.useCachedGameResponses = Self.load("dbg.useCachedGameResponses", default: false)
        self.cacheGameResponses = Self.load("dbg.cacheGameResponses", default: true)
        self.mockFeedHeader = Self.load("dbg.mockFeedHeader", default: false)
        self.feedDataSource = Self.loadString("dbg.feedDataSource", default: "live")
        self.headerDataSource = Self.loadString("dbg.headerDataSource", default: "mock")
        self.cacheFeedResponses = Self.load("dbg.cacheFeedResponses", default: true)
        self.overrideGamingExperience = Self.load("dbg.overrideGamingExperience", default: false)
        self.debugGamingExperience = Self.loadInt("dbg.debugGamingExperience", default: 3)
        self.networkSimEnabled = Self.load("dbg.networkSimEnabled", default: false)
        self.networkLatencyMs = Self.loadInt("dbg.networkLatencyMs", default: 0)
        self.networkJitterMs = Self.loadInt("dbg.networkJitterMs", default: 0)
        self.networkFailurePct = Self.loadInt("dbg.networkFailurePct", default: 0)
        self.networkTimeoutPct = Self.loadInt("dbg.networkTimeoutPct", default: 0)
    }
    
    // MARK: - Viewed Games Cache (for Game Selection)
    
    /// Clears the "viewed games" cache used by GameSelectionViewModel
    func clearViewedGamesCache() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: viewedGamesKey)
        print("🗑️ [DebugSettings] Cleared viewed games cache")
        #endif
    }
    
    /// Returns count of viewed games in cache
    var viewedGamesCount: Int {
        let ids = UserDefaults.standard.array(forKey: viewedGamesKey) as? [String] ?? []
        return ids.count
    }
    
    // MARK: - API Response Cache
    
    /// Caches a games-by-genre response
    func cacheGamesResponse(_ games: [GamerConnectGame], for genre: String) {
        #if DEBUG
        guard cacheGameResponses else { return }
        
        do {
            let data = try JSONEncoder().encode(games)
            let key = "\(cachedGamesResponseKey)_\(genre)"
            UserDefaults.standard.set(data, forKey: key)
            print("💾 [DebugSettings] Cached \(games.count) games for genre: \(genre)")
        } catch {
            print("❌ [DebugSettings] Failed to cache games: \(error)")
        }
        #endif
    }
    
    /// Retrieves cached games-by-genre response
    func getCachedGamesResponse(for genre: String) -> [GamerConnectGame]? {
        #if DEBUG
        let key = "\(cachedGamesResponseKey)_\(genre)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        do {
            let games = try JSONDecoder().decode([GamerConnectGame].self, from: data)
            print("📦 [DebugSettings] Loaded \(games.count) cached games for genre: \(genre)")
            return games
        } catch {
            print("❌ [DebugSettings] Failed to decode cached games: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Caches a search response
    func cacheSearchResponse(_ games: [GamerConnectGame], for query: String) {
        #if DEBUG
        guard cacheGameResponses else { return }
        
        do {
            let data = try JSONEncoder().encode(games)
            let key = "\(cachedSearchResponseKey)_\(query.lowercased())"
            UserDefaults.standard.set(data, forKey: key)
            print("💾 [DebugSettings] Cached \(games.count) games for search: \(query)")
        } catch {
            print("❌ [DebugSettings] Failed to cache search: \(error)")
        }
        #endif
    }
    
    /// Retrieves cached search response
    func getCachedSearchResponse(for query: String) -> [GamerConnectGame]? {
        #if DEBUG
        let key = "\(cachedSearchResponseKey)_\(query.lowercased())"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        do {
            let games = try JSONDecoder().decode([GamerConnectGame].self, from: data)
            print("📦 [DebugSettings] Loaded \(games.count) cached games for search: \(query)")
            return games
        } catch {
            print("❌ [DebugSettings] Failed to decode cached search: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Caches all-genres response
    func cacheAllGenresResponse(_ categories: [String: [GamerConnectGame]]) {
        #if DEBUG
        guard cacheGameResponses else { return }
        
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: cachedGenresResponseKey)
            let totalGames = categories.values.reduce(0) { $0 + $1.count }
            print("💾 [DebugSettings] Cached \(totalGames) games across \(categories.count) genres")
        } catch {
            print("❌ [DebugSettings] Failed to cache genres: \(error)")
        }
        #endif
    }
    
    /// Retrieves cached all-genres response
    func getCachedAllGenresResponse() -> [String: [GamerConnectGame]]? {
        #if DEBUG
        guard let data = UserDefaults.standard.data(forKey: cachedGenresResponseKey) else { return nil }
        
        do {
            let categories = try JSONDecoder().decode([String: [GamerConnectGame]].self, from: data)
            let totalGames = categories.values.reduce(0) { $0 + $1.count }
            print("📦 [DebugSettings] Loaded \(totalGames) cached games across \(categories.count) genres")
            return categories
        } catch {
            print("❌ [DebugSettings] Failed to decode cached genres: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Clears all cached API responses
    func clearAPIResponseCache() {
        #if DEBUG
        // Clear genre caches
        for genre in ["all", "fps", "battle-royale", "rpg", "sports", "moba", "racing"] {
            UserDefaults.standard.removeObject(forKey: "\(cachedGamesResponseKey)_\(genre)")
        }
        
        // Clear all-genres cache
        UserDefaults.standard.removeObject(forKey: cachedGenresResponseKey)
        
        // Note: We don't clear search caches as there could be many keys
        // A more robust solution would use a separate cache storage
        
        print("🗑️ [DebugSettings] Cleared API response cache")
        #endif
    }
    
    /// Returns approximate size of cached data
    var cachedResponsesInfo: String {
        #if DEBUG
        var genres: [String] = []
        for genre in ["all", "fps", "battle-royale", "rpg", "sports", "moba", "racing"] {
            if UserDefaults.standard.data(forKey: "\(cachedGamesResponseKey)_\(genre)") != nil {
                genres.append(genre)
            }
        }
        
        if genres.isEmpty {
            return "No cached responses"
        }
        return "\(genres.count) genres cached"
        #else
        return "N/A"
        #endif
    }
    
    // MARK: - Reset All
    
    func resetAll() {
        #if DEBUG
        let keys = [
            "dbg.mockGameAPI",
            "dbg.useCachedGameResponses",
            "dbg.cacheGameResponses",
            "dbg.mockFeedHeader",
            "dbg.feedDataSource",
            "dbg.headerDataSource",
            "dbg.cacheFeedResponses",
            "dbg.overrideGamingExperience",
            "dbg.debugGamingExperience",
            "dbg.networkSimEnabled",
            "dbg.networkLatencyMs",
            "dbg.networkJitterMs",
            "dbg.networkFailurePct",
            "dbg.networkTimeoutPct"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Restore defaults
        self.mockGameAPI = false
        self.useCachedGameResponses = false
        self.cacheGameResponses = true
        self.mockFeedHeader = false
        self.feedDataSource = "live"
        self.headerDataSource = "mock"
        self.cacheFeedResponses = true
        self.overrideGamingExperience = false
        self.debugGamingExperience = 3
        self.networkSimEnabled = false
        self.networkLatencyMs = 0
        self.networkJitterMs = 0
        self.networkFailurePct = 0
        self.networkTimeoutPct = 0
        
        print("🔄 [DebugSettings] Reset all debug flags to defaults")
        #endif
    }
    
    // MARK: - Persistence Helpers
    
    private func persist(_ key: String, value: Bool) {
        #if DEBUG
        UserDefaults.standard.set(value, forKey: key)
        #endif
    }
    
    private func persist(_ key: String, value: String) {
        #if DEBUG
        UserDefaults.standard.set(value, forKey: key)
        #endif
    }
    
    private func persistInt(_ key: String, value: Int) {
        #if DEBUG
        UserDefaults.standard.set(value, forKey: key)
        #endif
    }
    
    private static func load(_ key: String, default def: Bool) -> Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: key) == nil {
            return def
        }
        return UserDefaults.standard.bool(forKey: key)
        #else
        return def
        #endif
    }
    
    private static func loadString(_ key: String, default def: String) -> String {
        #if DEBUG
        return UserDefaults.standard.string(forKey: key) ?? def
        #else
        return def
        #endif
    }
    
    private static func loadInt(_ key: String, default def: Int) -> Int {
        #if DEBUG
        if UserDefaults.standard.object(forKey: key) == nil {
            return def
        }
        return UserDefaults.standard.integer(forKey: key)
        #else
        return def
        #endif
    }
}
