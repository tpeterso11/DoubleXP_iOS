//
//  PostView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import YoutubeKit
import youtube_ios_player_helper

class PostView: UIViewController, YTSwiftyPlayerDelegate {
    
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var loadingBlur: UIVisualEffectView!
    @IBOutlet weak var youtubeAnimation: AnimationView!
    @IBOutlet weak var fireAnimation: AnimationView!
    @IBOutlet weak var postView: UIView!
    var currentPost: PostObject?
    var player: YTSwiftyPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.postTitle.text = currentPost!.title
        self.youtubeAnimation.loopMode = .loop
        self.youtubeAnimation.play()
        self.setupPlayer()
        //self.fireAnimation.currentFrame = 0
    }
    
    private func setupPlayer(){
        self.player = YTSwiftyPlayer(frame: CGRect(x: -75, y: -50, width: self.postView.bounds.width + 150, height: self.postView.bounds.height + 50), playerVars: [
            .mute(true),
            .playsInline(true),
            .videoID(self.currentPost!.youtubeId),
            .loopVideo(true),
            .disableKeyboardControl(true),
            .autoplay(true),
            .showLoadPolicy(false),
            .showRelatedVideo(false),
            .showInfo(false),
            .showControls(VideoControlAppearance.hidden),
            .showModestbranding(false)])
        player!.delegate = self
        player!.setPlaybackQuality(YTSwiftyVideoQuality.small)
        player!.mute()
        player!.loadPlayer()
        player!.autoplay = false
        self.postView.addSubview(player!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.player!.playVideo()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingBlur.alpha = 0
            }, completion: { (finished: Bool) in
                
            })
        }
    }
}
