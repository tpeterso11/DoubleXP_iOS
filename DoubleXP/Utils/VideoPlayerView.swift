//
//  VideoPlayerView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    private var avLayer: AVPlayerLayer? {
        return layer as? AVPlayerLayer
    }

    func configure(with url: URL, autoplay: Bool = true) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        avLayer?.player = player
        avLayer?.videoGravity = .resizeAspectFill
        if autoplay {
            player?.play()
        }
    }

    func prepare(url: URL, completion: ((TimeInterval?) -> Void)? = nil) {
        let start = Date()
        let asset = AVAsset(url: url)
        let keys = ["playable"]

        asset.loadValuesAsynchronously(forKeys: keys) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "playable", error: &error)

            DispatchQueue.main.async {
                if status == .loaded {
                    let item = AVPlayerItem(asset: asset)
                    self.player = AVPlayer(playerItem: item)
                    self.avLayer?.player = self.player
                    self.avLayer?.videoGravity = .resizeAspectFill

                    let elapsed = Date().timeIntervalSince(start)
                    print("✅ AVPlayer prepared in \(elapsed)s")
                    completion?(elapsed)
                } else {
                    print("❌ Failed to prepare AVPlayer:", error?.localizedDescription ?? "Unknown")
                    completion?(nil)
                }
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func cleanup() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}
