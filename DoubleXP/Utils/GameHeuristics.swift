//
//  GameHeuristics.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation

enum GameComplexityTier: String, Codable {
    case beginner
    case intermediate
    case hardcore
    
    var label: String {
        switch self {
        case .beginner:     return "Easy"
        case .intermediate: return "Mid"
        case .hardcore:     return "Complex"
        }
    }
}

enum GameTimeBucket: String, Codable {
    case pickUpAndGo       // 1
    case shortSessions     // 2
    case weekendRun        // 3
    case bigCommitment     // 4
    case epicJourney       // 5
    
    var label: String {
        switch self {
        case .pickUpAndGo:   return "Hop in"
        case .shortSessions: return "Mini sesh"
        case .weekendRun:    return "Wknd sesh"
        case .bigCommitment: return "Grind"
        case .epicJourney:   return "Epic journey"
        }
    }
}

struct GameComplexityResult {
    let score: Double   // 1–5
    let tier: GameComplexityTier
    var label: String { tier.label }
}

struct GameTimeResult {
    let score: Double   // 1–5
    let bucket: GameTimeBucket
    var label: String { bucket.label }
}

enum GameHeuristics {
    
    // MARK: - Public API
    
    static func computeComplexity(for game: IGDBGame) -> GameComplexityResult {
        let base = baseComplexity(from: game.genres)
        var score = base
        
        score += complexityModifiers(fromModes: game.game_modes,
                                     perspectives: game.player_perspectives,
                                     themes: game.themes)
        
        // Age-rating cap for clearly kid-friendly stuff + simple genres
        if isFamilyFriendly(game), base <= 3.0 {
            score = min(score, 3.0)
        }
        
        score = clamp(score, min: 1.0, max: 5.0)
        
        let tier: GameComplexityTier
        switch score {
        case ..<2.3:
            tier = .beginner
        case 2.3..<3.7:
            tier = .intermediate
        default:
            tier = .hardcore
        }
        
        return GameComplexityResult(score: score, tier: tier)
    }
    
    static func computeTimeCommitment(for game: IGDBGame) -> GameTimeResult {
        let base = baseTime(from: game.genres)
        var score = base
        
        score += timeModifiers(fromModes: game.game_modes,
                               themes: game.themes)
        
        score = clamp(score, min: 1.0, max: 5.0)
        
        let bucket: GameTimeBucket
        switch score {
        case ..<1.8:
            bucket = .pickUpAndGo
        case 1.8..<2.6:
            bucket = .shortSessions
        case 2.6..<3.4:
            bucket = .weekendRun
        case 3.4..<4.2:
            bucket = .bigCommitment
        default:
            bucket = .epicJourney
        }
        
        return GameTimeResult(score: score, bucket: bucket)
    }
    
    // MARK: - Base Complexity (by genre)
    
    private static func baseComplexity(from genres: [Genre]?) -> Double {
        guard let genres, !genres.isEmpty else {
            return 2.5 // middle if unknown
        }
        
        let scores = genres.compactMap { genre -> Double? in
            guard let name = genre.name?.lowercased() else { return nil }
            return complexityGenreBase[name]
        }
        
        // If we didn’t match anything, be neutral-ish
        guard let maxScore = scores.max() else { return 2.5 }
        return maxScore
    }
    
    /// Rough mapping from genre name → base complexity [1–5]
    private static let complexityGenreBase: [String: Double] = [
        // Low complexity / casual-ish
        "arcade": 2.0,
        "platform": 2.2,
        "platformer": 2.2,
        "puzzle": 2.0,
        "sport": 2.1,
        "sports": 2.1,
        "racing": 2.3,
        "quiz/trivia": 1.8,
        "card & board game": 2.2,
        "pinball": 1.8,
        "party": 1.8,
        "music": 2.0,
        
        // Medium
        "adventure": 2.7,
        "visual novel": 2.5,
        "fighting": 2.9,
        "shooter": 3.0,
        "hack and slash/beat 'em up": 3.0,
        "indie": 2.5,
        
        // High complexity
        "role-playing (rpg)": 4.2,
        "role-playing": 4.2,
        "tactical": 4.3,
        "strategy": 4.0,
        "turn-based strategy": 4.1,
        "real time strategy (rts)": 4.1,
        "simulator": 3.8,
        "simulation": 3.8,
        "city builder": 4.0,
        "moba": 4.3,
        "grand strategy": 4.5,
        "4x": 4.6
    ]
    
    // MARK: - Complexity Modifiers
    
    private static func complexityModifiers(
        fromModes modes: [GameMode]?,
        perspectives: [PlayerPerspective]?,
        themes: [Theme]?
    ) -> Double {
        var delta: Double = 0.0
        
        let modeNames = modes?.compactMap { $0.name?.lowercased() } ?? []
        let perspectiveNames = perspectives?.compactMap { $0.name?.lowercased() } ?? []
        let themeNames = themes?.compactMap { $0.name?.lowercased() } ?? []
        
        // Modes: MMO / heavy online
        if modeNames.contains(where: { $0.contains("massively multiplayer") || $0.contains("mmo") }) {
            delta += 0.6
        } else if modeNames.contains(where: { $0.contains("battle royale") ||
                                              $0.contains("multiplayer") ||
                                              $0.contains("co-op") ||
                                              $0.contains("co-operative") }) {
            delta += 0.3
        }
        
        // Perspective: isometric / top-down / VR
        if perspectiveNames.contains(where: { $0.contains("isometric") || $0.contains("top-down") }) {
            delta += 0.2
        }
        if perspectiveNames.contains(where: { $0.contains("virtual reality") || $0 == "vr" }) {
            delta += 0.2
        }
        
        // Themes: sandbox / survival / roguelike
        if themeNames.contains(where: { $0.contains("sandbox") ||
                                        $0.contains("open world") ||
                                        $0.contains("survival") ||
                                        $0.contains("roguelike") }) {
            delta += 0.3
        }
        
        return delta
    }
    
    // MARK: - Base Time (by genre)
    
    private static func baseTime(from genres: [Genre]?) -> Double {
        guard let genres, !genres.isEmpty else {
            return 2.5
        }
        
        let scores = genres.compactMap { genre -> Double? in
            guard let name = genre.name?.lowercased() else { return nil }
            return timeGenreBase[name]
        }
        
        guard let maxScore = scores.max() else { return 2.5 }
        return maxScore
    }
    
    /// Rough mapping from genre name → base time [1–5]
    private static let timeGenreBase: [String: Double] = [
        // Short / session-based
        "arcade": 1.5,
        "puzzle": 1.7,
        "sport": 1.8,
        "sports": 1.8,
        "racing": 2.0,
        "fighting": 1.9,
        "music": 1.7,
        "party": 1.5,
        "quiz/trivia": 1.5,
        "card & board game": 1.8,
        "pinball": 1.5,
        
        // Medium
        "adventure": 2.8,
        "platform": 2.5,
        "platformer": 2.5,
        "shooter": 2.7,
        "hack and slash/beat 'em up": 2.8,
        "indie": 2.5,
        "visual novel": 3.0,
        
        // Long
        "role-playing (rpg)": 4.2,
        "role-playing": 4.2,
        "tactical": 4.0,
        "strategy": 4.0,
        "turn-based strategy": 4.2,
        "real time strategy (rts)": 4.1,
        "simulator": 3.8,
        "simulation": 3.8,
        "city builder": 4.1,
        "grand strategy": 4.6,
        "4x": 4.7,
        "moba": 4.3
    ]
    
    // MARK: - Time Modifiers
    
    private static func timeModifiers(
        fromModes modes: [GameMode]?,
        themes: [Theme]?
    ) -> Double {
        var delta: Double = 0.0
        
        let modeNames = modes?.compactMap { $0.name?.lowercased() } ?? []
        let themeNames = themes?.compactMap { $0.name?.lowercased() } ?? []
        
        let hasMMO = modeNames.contains(where: { $0.contains("massively multiplayer") || $0.contains("mmo") })
        let hasMultiplayer = modeNames.contains(where: { $0.contains("multiplayer") ||
                                                         $0.contains("battle royale") ||
                                                         $0.contains("co-op") ||
                                                         $0.contains("co-operative") })
        
        if hasMMO {
            delta += 1.0
        } else if hasMultiplayer {
            delta += 0.5
        } else if isPureSinglePlayer(modes: modeNames) {
            delta -= 0.3
        }
        
        // Sandbox / open world / survival / roguelike feel like longer commitments
        if themeNames.contains(where: { $0.contains("sandbox") ||
                                        $0.contains("open world") ||
                                        $0.contains("survival") ||
                                        $0.contains("roguelike") }) {
            delta += 0.5
        }
        
        return delta
    }
    
    private static func isPureSinglePlayer(modes: [String]) -> Bool {
        guard !modes.isEmpty else { return false }
        
        let hasSingle = modes.contains { $0.contains("single") }
        let hasAnyMulti = modes.contains {
            $0.contains("multiplayer") ||
            $0.contains("co-op") ||
            $0.contains("co-operative") ||
            $0.contains("online") ||
            $0.contains("battle royale") ||
            $0.contains("massively multiplayer") ||
            $0.contains("mmo")
        }
        
        return hasSingle && !hasAnyMulti
    }
    
    // MARK: - Age rating helper
    
    private static func isFamilyFriendly(_ game: IGDBGame) -> Bool {
        guard let ratings = game.age_ratings else { return false }
        
        for rating in ratings {
            guard let category = rating.category,
                  let value = rating.rating else { continue }
            
            switch category {
            case 1: // ESRB
                // 6 = E, 7 = E10+
                if value == 6 || value == 7 { return true }
            case 2: // PEGI
                // 1 = 3, 2 = 7
                if value == 1 || value == 2 { return true }
            default:
                continue
            }
        }
        
        return false
    }
    
    // MARK: - Utility
    
    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
