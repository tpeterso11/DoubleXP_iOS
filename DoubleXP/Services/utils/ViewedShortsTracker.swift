//
//  ViewedShortsTracker.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/12/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

class ViewedShortsTracker {
    static let shared = ViewedShortsTracker()
    private let key = "viewedShorts"
    private var viewed: Set<String>

    private init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            viewed = Set(saved)
        } else {
            viewed = []
        }
    }

    func markViewed(_ id: String) {
        viewed.insert(id)
        save()
    }

    func isViewed(_ id: String) -> Bool {
        viewed.contains(id)
    }

    func allViewedIDs() -> Set<String> {
        viewed
    }

    func save() {
        UserDefaults.standard.set(Array(viewed), forKey: key)
    }
}
