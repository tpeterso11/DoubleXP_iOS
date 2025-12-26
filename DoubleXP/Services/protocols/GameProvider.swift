//
//  NewsProvider 2.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/20/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


protocol GameProvider {
    func fetchGames(range: GameDateRange, forceRefresh: Bool, cacheKeyOverride: String?)
}
