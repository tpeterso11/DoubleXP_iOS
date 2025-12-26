//
//  YouTubeShortsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


final class YouTubeShortsManager {
    static let shared = YouTubeShortsManager()
    private init() {} // Prevents external instantiation

    /*private let provider = YouTubeShortsProvider()
    private(set) var lastFetchedShorts: [Short] = []

    func fetchGeneralShorts() {
        provider.fetchGeneralShorts { shorts in
            self.lastFetchedShorts = shorts
        }
    }

    func fetchShorts(forGames games: [String]) {
        provider.fetchShorts(forGames: games) { shorts in
            self.lastFetchedShorts = shorts
        }
    }*/
}
