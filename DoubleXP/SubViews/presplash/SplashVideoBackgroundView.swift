//
//  SplashVideoBackgroundView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI
import AVKit

struct SplashVideoBackgroundView: View {
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var endObserver: Any?

    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                        if let token = endObserver {
                            NotificationCenter.default.removeObserver(token)
                        }
                    }
            } else {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            setupPlayerIfNeeded()
        }
    }

    private func setupPlayerIfNeeded() {
        guard player == nil else { return }

        guard let url = Bundle.main.url(forResource: "newSplash0421", withExtension: "mov") else {
            print("⚠️ [PreSplash] Splash video not found in bundle; skipping straight to finished.")
            onFinished()
            return
        }

        let avPlayer = AVPlayer(url: url)
        player = avPlayer

        if let item = avPlayer.currentItem {
            let token = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                onFinished()
            }
            endObserver = token
        }

        avPlayer.play()
    }
}