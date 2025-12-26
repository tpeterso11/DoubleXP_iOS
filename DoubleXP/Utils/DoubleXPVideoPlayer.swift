//
//  DoubleXPVideoPlayer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/23/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit
import AVFoundation

class DoubleXPVideoPlayer {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var cacheTTL: TimeInterval = 3600 // 1 hour
    private var cleanupTimers: [URL: DispatchSourceTimer] = [:]
    private var endHandler: (() -> Void)?
    private var videoEnded = false
    private var endObserver: Any?

    deinit {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public API

    func playLocalVideo(
        in container: UIView,
        fileName: String,
        fileType: String = "mov",
        loop: Bool = false,
        videoGravity: AVLayerVideoGravity? = nil
    ) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else { return }
        let item = AVPlayerItem(url: url)
        prepareAndPlay(item: item,
                       in: container,
                       videoGravity: videoGravity,
                       loop: loop)
    }

    /// Plays a video as a background layer inside the given view.
        /// - Parameters:
        ///   - hostView: The view whose bounds the video should fill.
        ///   - fileName: The video resource name (without extension).
        ///   - fileType: The file extension (e.g., "mov", "mp4").
        ///   - videoGravity: How the video content should scale inside the layer.
        ///   - shouldLoop: If true, the video will replay when it reaches the end.
        ///   - completion: Called when a *non-looping* video finishes.
        func playVideoBackground(
            in hostView: UIView,
            fileName: String,
            fileType: String,
            videoGravity: AVLayerVideoGravity = .resizeAspectFill,
            shouldLoop: Bool = false,
            completion: (() -> Void)? = nil
        ) {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
                print("❌ Could not find splash video \(fileName).\(fileType)")
                completion?()
                return
            }

            // Clean up any previous player/layer/observer
            if let observer = endObserver {
                NotificationCenter.default.removeObserver(observer)
                endObserver = nil
            }

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player

            let layer = AVPlayerLayer(player: player)
            layer.frame = hostView.bounds
            layer.videoGravity = videoGravity

            hostView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            hostView.layer.addSublayer(layer)
            hostView.layer.masksToBounds = true
            self.playerLayer = layer

            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Keep the layer in sync with bounds changes
            layer.needsDisplayOnBoundsChange = true

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }

                if shouldLoop {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    completion?()
                    self.player?.pause()
                }
            }

            player.play()
        }

    private func handleVideoEnd(loop: Bool) {
        videoEnded = true
        if !loop {
            tryTransitionIfReady()
        }
    }

    @objc private func appDidBecomeActive() {
        tryTransitionIfReady()
    }

    private func tryTransitionIfReady() {
        guard videoEnded else { return }
        videoEnded = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        DispatchQueue.main.async { [weak self] in
            self?.endHandler?()
        }
    }

    func streamVideo(
        from remoteURL: URL,
        into container: UIView,
        loop: Bool = false,
        videoGravity: AVLayerVideoGravity? = nil
    ) {
        let item = AVPlayerItem(url: remoteURL)
        prepareAndPlay(item: item,
                       in: container,
                       videoGravity: videoGravity,
                       loop: loop)
    }

    @discardableResult
    func preloadVideo(from remoteURL: URL) async -> Bool {
        let cacheURL = videoCacheURL(for: remoteURL)
        if let attrs = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
           let modified = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) < cacheTTL {
            return true
        }

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            try? FileManager.default.removeItem(at: cacheURL)
            try FileManager.default.copyItem(at: tempURL, to: cacheURL)
            scheduleCleanup(for: cacheURL)
            return true
        } catch {
            print("❌ Failed to preload video: \(error)")
            return false
        }
    }

    private func scheduleCleanup(for fileURL: URL) {
        cleanupTimers[fileURL]?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + cacheTTL)
        timer.setEventHandler { [weak self] in
            try? FileManager.default.removeItem(at: fileURL)
            self?.cleanupTimers[fileURL]?.cancel()
            self?.cleanupTimers.removeValue(forKey: fileURL)
        }
        timer.resume()
        cleanupTimers[fileURL] = timer
    }

    func playCachedVideo(
        from remoteURL: URL,
        into container: UIView,
        loop: Bool = false,
        videoGravity: AVLayerVideoGravity? = nil,
        delayBeforePlay: TimeInterval = 0
    ) async {
        let cacheURL = videoCacheURL(for: remoteURL)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            let item = AVPlayerItem(url: cacheURL)
            prepareAndPlay(item: item,
                           in: container,
                           videoGravity: videoGravity,
                           loop: loop,
                           delayBeforePlay: delayBeforePlay)
        } else {
            let success = await preloadVideo(from: remoteURL)
            if success {
                await playCachedVideo(from: remoteURL,
                                      into: container,
                                      loop: loop,
                                      videoGravity: videoGravity,
                                      delayBeforePlay: delayBeforePlay)
            } else {
                print("❌ Could not cache video from \(remoteURL)")
            }
        }
    }

    // MARK: - Core Playback Setup

    private func prepareAndPlay(
        item: AVPlayerItem,
        in container: UIView,
        videoGravity: AVLayerVideoGravity?,
        loop: Bool,
        onEnd: (() -> Void)? = nil,
        delayBeforePlay: TimeInterval = 0
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.playerLayer?.removeFromSuperlayer()
            NotificationCenter.default.removeObserver(self)

            self.player = AVPlayer(playerItem: item)
            self.player?.isMuted = true

            let layer = AVPlayerLayer(player: self.player)
            layer.videoGravity = videoGravity ?? .resizeAspect
            layer.frame = container.bounds
            container.layer.insertSublayer(layer, at: 0)
            self.playerLayer = layer

            if let onEnd = onEnd {
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { _ in
                    onEnd()
                    if loop {
                        item.seek(to: .zero, completionHandler: { _ in
                            self.player?.seek(to: CMTime(seconds: 0.1, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                self.player?.play()
                            }
                        })
                        self.player?.play()
                    }
                }
            } else if loop {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.loopVideo(_:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: item
                )
            }
            
            let previewTime = CMTime(seconds: 0.1, preferredTimescale: 600)
            self.player?.seek(to: previewTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { [weak self] _ in 
                guard let self = self else { return }

                if delayBeforePlay > 0 {
                    self.player?.rate = 0

                    DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforePlay) {
                        self.player?.play()
                    }
                } else {
                    self.player?.play()
                }
            })

            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                layer.frame = container.bounds
            }
        }
    }

    private func videoCacheURL(for remoteURL: URL) -> URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(remoteURL.lastPathComponent)
    }

    @objc private func loopVideo(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero)
        player?.play()
    }

    func cleanExpiredCache() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for file in files {
            if let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
               let modified = attrs.contentModificationDate,
               Date().timeIntervalSince(modified) >= cacheTTL {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
