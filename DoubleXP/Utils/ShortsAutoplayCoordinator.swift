//
//  ShortsAutoplayCoordinator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/16/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

final class ShortsAutoplayCoordinator {
    weak var collectionView: UICollectionView?
    /// current playing indexPath (if any)
    private(set) var playingIndexPath: IndexPath?

    /// How much of a cell must be visible before it’s eligible to play (0...1).
    private let playThreshold: CGFloat = 0.6

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    /// Call on didScroll / endDecelerating / endDragging / after reloads.
    func updatePlayback() {
        guard let cv = collectionView else { return }

        // Find all visible Shorts cells and compute visibility ratios.
        let candidates: [(IndexPath, ShortsCell, CGFloat)] = cv.visibleCells.compactMap { cell in
            guard let ip = cv.indexPath(for: cell), let shortCell = cell as? ShortsCell else { return nil }
            let r = visibleRatio(for: shortCell, in: cv)
            return (ip, shortCell, r)
        }

        // If no shorts visible → pause anything currently playing.
        guard let best = candidates.max(by: { $0.2 < $1.2 }), best.2 >= playThreshold else {
            pauseCurrent()
            return
        }

        // If a different cell should play, switch.
        if best.0 != playingIndexPath {
            // Pause previous
            if let ip = playingIndexPath,
               let prevCell = cv.cellForItem(at: ip) as? ShortsCell {
                prevCell.pausePlayback()
            }
            // Start new
            best.1.startPlayback()
            playingIndexPath = best.0
        }
    }

    /// Pause if the currently playing cell scrolled offscreen (call from didEndDisplaying).
    func didEndDisplaying(indexPath: IndexPath) {
        if indexPath == playingIndexPath {
            playingIndexPath = nil
        }
    }

    /// Explicitly pause everything.
    func pauseCurrent() {
        guard let cv = collectionView, let ip = playingIndexPath,
              let cell = cv.cellForItem(at: ip) as? ShortsCell else {
            playingIndexPath = nil
            return
        }
        cell.pausePlayback()
        playingIndexPath = nil
    }

    /// Autoplay the very first visible Shorts cell (used on first appearance).
    func autoplayFirstVisibleIfNeeded() {
        guard playingIndexPath == nil, let cv = collectionView else { return }
        let firstShortVisible = cv.visibleCells
            .compactMap { cv.indexPath(for: $0) }
            .sorted()
            .first { ip in
                (cv.cellForItem(at: ip) as? ShortsCell) != nil
            }
        if let ip = firstShortVisible,
           let cell = cv.cellForItem(at: ip) as? ShortsCell {
            cell.startPlayback()
            playingIndexPath = ip
        }
    }

    // MARK: - Helpers

    private func visibleRatio(for cell: UICollectionViewCell, in collectionView: UICollectionView) -> CGFloat {
        let cellFrame = collectionView.convert(cell.bounds, from: cell)
        let intersection = cellFrame.intersection(collectionView.bounds)
        guard !intersection.isNull, cellFrame.height > 0, cellFrame.width > 0 else { return 0 }
        let visibleArea = intersection.width * intersection.height
        let totalArea   = cellFrame.width * cellFrame.height
        return max(0, min(1, visibleArea / totalArea))
    }
}
