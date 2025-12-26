//
//  PreSplashVideoView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import AVKit

struct PreSplashVideoView: UIViewRepresentable {
    let onFinished: () -> Void

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(onFinished: onFinished)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // Nothing to update for this simple pre-splash; video just plays once.
    }

    // MARK: - Inner UIView that hosts AVPlayerLayer

    final class PlayerContainerView: UIView {
        private var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        private var endObserver: Any?

        func configure(onFinished: @escaping () -> Void) {
            // Avoid double configuration in case SwiftUI recreates things
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            player?.pause()
            player = nil

            guard let url = Bundle.main.url(forResource: "newSplash0421", withExtension: "mov") else {
                print("🔴 PreSplashVideoView: Could not find newSplash0421.mov in bundle")
                return
            }

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill   // fill screen nicely
            layer.frame = bounds
            layer.needsDisplayOnBoundsChange = true
            self.layer.addSublayer(layer)
            self.playerLayer = layer

            // Observe end of playback
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                print("🎬 PreSplashVideoView: playback finished, calling onFinished")
                onFinished()
            }

            player.play()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }

        deinit {
            if let endObserver = endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }
}
