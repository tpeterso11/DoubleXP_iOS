//
//  TransitionCoordinator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/13/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

enum TransitionDestination: Equatable {
    case none
    case gameDetail(GamerConnectGame)
    case gamePopup(GamerConnectGame)
}

/// Global transition coordinator managing matched geometry transitions
class TransitionCoordinator: ObservableObject {
    
    @Published var selectedGame: GamerConnectGame? = nil
    @Published var destination: TransitionDestination = .none
    
    // Track if we're mid-transition to prevent visual glitches
    @Published private(set) var isTransitioning: Bool = false
    
    // Animation configuration
    private let transitionDuration: Double = 0.6
    private let springResponse: Double = 0.6
    private let springDamping: Double = 0.75
    
    /// Present a new destination with smooth transition
    func present(destination: TransitionDestination) {
        let game: GamerConnectGame?
        switch destination {
        case .gameDetail(let g), .gamePopup(let g):
            game = g
        case .none:
            game = nil
        }
        
        guard let game = game else {
            self.destination = .none
            return
        }
        
        // Set game AND start transition in same update cycle
        self.selectedGame = game
        self.isTransitioning = true
        
        // NO DELAY - animate immediately
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            self.destination = destination
        }
        
        // Clear transitioning flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            self.isTransitioning = false
        }
    }
    
    /// Dismiss current destination and return to source
    func dismiss() {
        // Mark as transitioning
        isTransitioning = true
        
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            self.destination = .none
        }
        
        // Clear after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            // Only clear if no new transition started
            if self.destination == .none {
                self.selectedGame = nil
            }
            self.isTransitioning = false
        }
    }
}
