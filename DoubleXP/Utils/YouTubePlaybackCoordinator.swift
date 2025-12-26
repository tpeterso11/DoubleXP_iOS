//
//  YouTubePlaybackCoordinator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/12/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

final class YouTubePlaybackCoordinator {
    static let shared = YouTubePlaybackCoordinator()
    private init() {}

    private weak var currentPlayer: YouTubePlayerView?

    /// Claim "foreground" status for this player.
    /// Any previously claimed player is paused first.
    func claim(_ player: YouTubePlayerView) {
        // If it's already current, nothing to do
        if currentPlayer === player { return }

        // Pause the previous one
        currentPlayer?.pause()

        // Make this the new active player
        currentPlayer = player
    }

    /// Called when a player is no longer visible / in use.
    /// If it was the active one, pause and clear the reference.
    func resign(_ player: YouTubePlayerView) {
        guard currentPlayer === player else { return }
        currentPlayer?.pause()
        currentPlayer = nil
    }

    /// Optional global "panic button" if you ever want to pause everything.
    func pauseAll() {
        currentPlayer?.pause()
    }
}
