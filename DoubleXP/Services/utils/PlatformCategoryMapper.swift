//
//  PlatformCategoryMapper.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/8/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

enum PlatformCategoryMapper {
    /// Map RAWG platform display names to your coarse categories
    static func mapPlatformNameToCategory(_ name: String) -> String? {
        let l = name.lowercased()

        if l.contains("playstation") || l.contains("ps") { return "ps" }
        if l.contains("xbox")                              { return "xbox" }
        if l.contains("switch") || l.contains("nintendo")
            || l.contains("wii") || l.contains("ds")      { return "nintendo" }
        if l.contains("ios") || l.contains("android")
            || l.contains("mobile")                       { return "mobile" }
        if l.contains("pc") || l.contains("windows")
            || l.contains("mac") || l.contains("linux")
            || l.contains("web")                          { return "pc" }
        if l.contains("board") || l.contains("tabletop")  { return "tabletop" }
        return nil
    }
}