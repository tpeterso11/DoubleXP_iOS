//
//  GameStorageManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

class GameStorageManager {
    static let shared = GameStorageManager()
    
    private let storageKey = "GamerConnect_CachedGames"
    private var memoryCache: [String: GamerConnectGame] = [:] // Keyed by ID
    private let queue = DispatchQueue(label: "com.gamerconnect.storage", attributes: .concurrent)
    
    private init() {
        loadFromDisk()
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try JSONDecoder().decode([String: GamerConnectGame].self, from: data)
                memoryCache = decoded
            } catch {
                print("⚠️ Failed to load cached games: \(error)")
            }
        }
    }
    
    private func saveToDisk() {
        queue.async(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(self.memoryCache)
                UserDefaults.standard.set(data, forKey: self.storageKey)
            } catch {
                print("⚠️ Failed to save games to cache: \(error)")
            }
        }
    }
    
    // MARK: - Public API
    
    func getGame(id: String) -> GamerConnectGame? {
        queue.sync {
            return memoryCache[id]
        }
    }
    
    // O(n) lookup for slugs
    func getGame(slug: String) -> GamerConnectGame? {
        queue.sync {
            return memoryCache.values.first { $0.slug.lowercased() == slug.lowercased() }
        }
    }
    
    // Get all games for local search/filtering
    func getAllGames() -> [GamerConnectGame] {
        queue.sync {
            return Array(memoryCache.values)
        }
    }
    
    func save(games: [GamerConnectGame]) {
        guard !games.isEmpty else { return }
        queue.async(flags: .barrier) {
            for game in games {
                self.memoryCache[game.id] = game
            }
            self.saveToDisk()
        }
    }
    
    func save(game: GamerConnectGame) {
        save(games: [game])
    }
    
    func getAllCachedIDs() -> [String] {
        queue.sync {
            return Array(memoryCache.keys)
        }
    }
    
    func resolveGame(from item: GameItem) -> GamerConnectGame? {
            // Explicitly tell Swift this closure returns GamerConnectGame?
            let result: GamerConnectGame? = queue.sync { () -> GamerConnectGame? in
                // 1) Try by ID (fastest + most reliable)
                let trimmedId = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedId.isEmpty, let byId = memoryCache[trimmedId] {
                    return byId
                }
                
                // 2) Try by slug if we have one
                let trimmedSlug = item.slug
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                
                if !trimmedSlug.isEmpty {
                    if let bySlug = memoryCache.values.first(where: { game in
                        game.slug
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() == trimmedSlug
                    }) {
                        return bySlug
                    }
                }
                
                // 3) Last-resort: try by name (not guaranteed unique)
                let trimmedName = item.name
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                
                if !trimmedName.isEmpty {
                    if let byName = memoryCache.values.first(where: { game in
                        game.gameName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() == trimmedName
                    }) {
                        return byName
                    }
                }
                
                // Nothing matched
                return nil
            }
            
            return result
        }
    
    func buildGamesBySlug(from games: [GamerConnectGame]) -> [String: GamerConnectGame] {
            var result: [String: GamerConnectGame] = [:]
            for game in games {
                let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !slug.isEmpty else { continue }
                // Only keep the first occurrence (or use last with `result[slug] = game`)
                if result[slug] == nil {
                    result[slug] = game
                }
            }
            return result
        }
        
        /// Build a dictionary of games by ID, keeping the first occurrence of duplicates
        func buildGamesById(from games: [GamerConnectGame]) -> [String: GamerConnectGame] {
            var result: [String: GamerConnectGame] = [:]
            for game in games {
                let id = game.id.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty else { continue }
                if result[id] == nil {
                    result[id] = game
                }
            }
            return result
        }
        
        // MARK: - Deduplication
        
        /// Remove duplicate games from an array (keeps first occurrence by ID)
        func deduplicate(games: [GamerConnectGame]) -> [GamerConnectGame] {
            var seen = Set<String>()
            return games.filter { game in
                let id = game.id.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty, !seen.contains(id) else { return false }
                seen.insert(id)
                return true
            }
        }
        
        /// Remove duplicate games by slug (keeps first occurrence)
        func deduplicateBySlug(games: [GamerConnectGame]) -> [GamerConnectGame] {
            var seen = Set<String>()
            return games.filter { game in
                let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !slug.isEmpty, !seen.contains(slug) else { return false }
                seen.insert(slug)
                return true
            }
        }
        
        /// Save games with automatic deduplication
        func saveDeduped(games: [GamerConnectGame]) {
            let uniqueGames = deduplicate(games: games)
            save(games: uniqueGames)
        }
        
        // MARK: - Cache Cleanup
        
        /// Prune duplicate games from the cache
        /// Call this periodically or when you suspect duplicates exist
        func pruneDuplicatesFromCache() {
            let allGames = getAllGames()
            let uniqueGames = deduplicate(games: allGames)
            
            let removedCount = allGames.count - uniqueGames.count
            if removedCount > 0 {
                print("🧹 [GameStorage] Pruned \(removedCount) duplicate games from cache")
                
                // Clear and re-save (this depends on your implementation)
                // If you have a clearAll() method, use it first
                // clearAllGames()
                save(games: uniqueGames)
            }
        }
}

extension Array where Element == GamerConnectGame {
    
    /// Convert to dictionary by slug (safe, no crash on duplicates)
    func toDictionaryBySlug() -> [String: GamerConnectGame] {
        var result: [String: GamerConnectGame] = [:]
        for game in self {
            let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !slug.isEmpty else { continue }
            if result[slug] == nil {
                result[slug] = game
            }
        }
        return result
    }
    
    /// Convert to dictionary by ID (safe, no crash on duplicates)
    func toDictionaryById() -> [String: GamerConnectGame] {
        var result: [String: GamerConnectGame] = [:]
        for game in self {
            let id = game.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty else { continue }
            if result[id] == nil {
                result[id] = game
            }
        }
        return result
    }
    
    /// Remove duplicates by ID (keeps first occurrence)
    func deduplicated() -> [GamerConnectGame] {
        var seen = Set<String>()
        return filter { game in
            let id = game.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, !seen.contains(id) else { return false }
            seen.insert(id)
            return true
        }
    }
    
    /// Remove duplicates by slug (keeps first occurrence)
    func deduplicatedBySlug() -> [GamerConnectGame] {
        var seen = Set<String>()
        return filter { game in
            let slug = game.slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !slug.isEmpty, !seen.contains(slug) else { return false }
            seen.insert(slug)
            return true
        }
    }
}
