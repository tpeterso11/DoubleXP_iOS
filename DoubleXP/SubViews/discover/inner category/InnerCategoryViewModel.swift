//
//  InnerCategoryViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/30/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

@MainActor
class InnerCategoryViewModel: ObservableObject {
    @Published var category: DiscoverPageCategory
    @Published var games: [GamerConnectGame] = []
    @Published var featuredGames: [GamerConnectGame] = [] // Games marked as featured for this category
    
    @Published var isLoading: Bool = true
    @Published var searchText: String = ""
    
    init(category: DiscoverPageCategory) {
        self.category = category
        // Initialize with what we already have passed in
        self.games = category.games
    }
    
    var filteredGames: [GamerConnectGame] {
        let base: [GamerConnectGame]

        if searchText.isEmpty {
            base = games
        } else {
            base = games.filter {
                $0.gameName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return base.sorted {
            $0.gameName.localizedCaseInsensitiveCompare($1.gameName) == .orderedAscending
        }
    }
    
    func loadFullGameDetails(featuredSlugs: [String] = []) async {
        // If the category passed in already has full games, we might just need to fetch featured
        // But often the previous screen only passes lightweight objects or just slugs.
        // Assuming `category.games` might be incomplete or we want to ensure we have full details:
        
        // 1. Extract slugs from existing list
        let slugs = category.games.map { $0.slug }
        
        // 2. Combine with any "featured slugs" passed separately
        let allSlugs = Set(slugs + featuredSlugs)
        
        if allSlugs.isEmpty {
            isLoading = false
            return
        }
        
        // 3. Fetch (Storage -> API -> Storage)
        let fullGames = await IGDBService.shared.fetchGames(bySlugs: Array(allSlugs))
        
        // 4. Populate
        withAnimation {
            self.games = fullGames
            
            // Filter featured
            if !featuredSlugs.isEmpty {
                self.featuredGames = fullGames.filter { featuredSlugs.contains($0.slug) }
            } else {
                // Default to first 3 if no specific featured slugs provided
                self.featuredGames = Array(fullGames.prefix(3))
            }
            
            self.isLoading = false
        }
    }
}
