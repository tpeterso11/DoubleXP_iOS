//
//  FeedNewsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/5/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import AVKit
import Foundation
import UIKit

class FeedNewsCell: UITableViewCell {
    
    @IBOutlet weak var newsSourceLabel: UILabel!
    @IBOutlet weak var newsImage: UIImageView!
    @IBOutlet weak var ytPlayer: YouTubePlayerView!
    private var hasStartedPlaying = false
    
    func configure(with article: Article, shouldAutoplay: Bool = false) {
        if article.isVideo, let url = article.videoUrl {
            //ytPlayer.load(videoURL: url, shouldAutoplay: shouldAutoplay)
        }
    }
    
    func playIfVisible() {
        guard !hasStartedPlaying else { return }
        ytPlayer.play()
        hasStartedPlaying = true
    }

    func pauseIfNotVisible() {
        ytPlayer.pause()
    }
}
