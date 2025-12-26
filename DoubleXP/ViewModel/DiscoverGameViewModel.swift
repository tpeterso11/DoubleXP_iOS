//
//  DiscoverGameViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import Combine

class DiscoverGameViewModel: ObservableObject {
    @Published var game: GamerConnectGame
    @Published var igdbGame: GamerConnectGame?
    @Published var dominantColor: Color = .black
    @Published var accentColor: Color = .white
    @Published var isLoading = true
    @Published var showErrorState = false
    @Published var isFollowing = false

    init(game: GamerConnectGame) {
        self.game = game
    }

    func fetchEnrichedGameDetails() {
        isLoading = true
        showErrorState = false

        Task {
            // Replace with your actual API call
            let fetchedGame = await IGDBService.shared.fetchGameDetails(bySlug: game.slug)

            if let finalGame = fetchedGame {
                self.igdbGame = finalGame
                // Replace with your actual dominant color logic
                // self.dominantColor = await fetchDominantColor()
                // self.accentColor = dominantColor.contrastingTextColor
            } else {
                // You can add your RAWG fallback logic here if needed
                self.showErrorState = true
            }
            self.isLoading = false
        }
    }
    
    func toggleFollow() {
        isFollowing.toggle()
        // Add your logic to save the follow state
    }
}
