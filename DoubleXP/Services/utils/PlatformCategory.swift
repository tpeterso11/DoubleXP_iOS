//
//  PlatformCategory.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/8/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

/// High-level buckets for platform UI/badges.
enum PlatformCategory: String, Codable, CaseIterable {
    case pc        // Windows/macOS/Linux/web
    case playstation
    case xbox
    case nintendo
    case mobile    // iOS/Android
    case vr
    case other

    /// Short tag you can use in the UI
    var tag: String {
        switch self {
        case .playstation: return "ps"
        case .xbox:        return "xbox"
        case .nintendo:    return "nintendo"
        case .mobile:      return "mobile"
        case .pc:          return "pc"
        case .vr:          return "vr"
        case .other:       return "other"
        }
    }
}

/// Maps RAWG platform IDs, names, or slugs into a `PlatformCategory`.
/// Use this for normalizing RAWG API data into your app categories.
struct PlatformMapper {
    static func map(id: Int? = nil, name: String? = nil, slug: String? = nil) -> PlatformCategory {
        let n = (name ?? "").lowercased()
        let s = (slug ?? "").lowercased()

        // --- RAWG platform IDs (stable/common IDs)
        let pcIDs: Set<Int>        = [4, 5, 6]                 // PC, macOS, Linux
        let playstationIDs: Set<Int> = [18, 187, 16, 15, 27, 19, 17] // PS4, PS5, PS3, PS2, PS1, Vita, PSP
        let xboxIDs: Set<Int>      = [1, 186, 14, 80]          // Xbox One, Series X|S, 360, OG
        let nintendoIDs: Set<Int>  = [7, 8, 9, 13, 10, 11, 83, 24] // Switch, 3DS, DS, Wii U, Wii, SNES, GBA
        let mobileIDs: Set<Int>    = [3, 21]                   // iOS, Android
        let webIDs: Set<Int>       = [171]                     // Web

        if let id = id {
            if pcIDs.contains(id) || webIDs.contains(id) { return .pc }
            if playstationIDs.contains(id)                { return .playstation }
            if xboxIDs.contains(id)                       { return .xbox }
            if nintendoIDs.contains(id)                   { return .nintendo }
            if mobileIDs.contains(id)                     { return .mobile }
        }

        // --- Heuristics from name/slug
        if n.contains("vr") || s.contains("vr") { return .vr }
        if n.contains("playstation") || n.contains("ps ") || s.hasPrefix("ps") { return .playstation }
        if n.contains("xbox") || s.hasPrefix("xbox") { return .xbox }
        if n.contains("nintendo") || n.contains("switch") || n.contains("wii") || n.contains("ds") { return .nintendo }
        if n.contains("ios") || n.contains("android") || n.contains("mobile") { return .mobile }
        if n.contains("pc") || n.contains("windows") || n.contains("mac") || n.contains("linux") || n.contains("web") {
            return .pc
        }

        return .other
    }
}