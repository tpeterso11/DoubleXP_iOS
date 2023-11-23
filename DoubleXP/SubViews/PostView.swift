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
import SPStorkController
import FittedSheets

class PostView: UIViewController, YTSwiftyPlayerDelegate, UISheetPresentationControllerDelegate, SPStorkControllerDelegate {
    func didDismiss() {
        //do nothing
    }
    
    
    @IBOutlet weak var postTitle: UITextView!
    @IBOutlet weak var postConsole: UIImageView!
    @IBOutlet weak var postSince: UILabel!
    @IBOutlet weak var postGamerTag: UILabel!
    @IBOutlet weak var loadingBlur: UIVisualEffectView!
    @IBOutlet weak var youtubeAnimation: LottieAnimationView!
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var shareButton: UIImageView!
    var currentPost: PostObject?
    var player: YTSwiftyPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.postTitle.text = currentPost!.title
        self.youtubeAnimation.loopMode = .loop
        self.youtubeAnimation.play()
        self.setupPlayer()
        
        if(currentPost != nil){
            self.postGamerTag.text = currentPost!.videoOwnerGamerTag
            if(!currentPost!.date.isEmpty){
                self.postSince.alpha = 1
                let milisecond = Int64(currentPost!.date)
                if(milisecond != nil){
                    let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milisecond!)/1000)
                    self.postSince.text = dateVar.timeAgoSinceDate()
                } else {
                    self.postSince.alpha = 0
                }
            } else {
                self.postSince.alpha = 0
            }
        }
        if(currentPost!.postConsole == "ps"){
            self.postConsole.image = UIImage.init(named: "ps_logo")
        } else if(currentPost!.postConsole == "xbox"){
            self.postConsole.image = UIImage.init(named: "xbox_logo")
        } else if(currentPost!.postConsole == "pc"){
            self.postConsole.image = UIImage.init(named: "pc_logo")
        } else if(currentPost!.postConsole == "nintendo"){
            self.postConsole.image = UIImage.init(named: "nintendo_logo")
        } else {
            self.postConsole.image = UIImage.init(named: "mobile_logo")
        }

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "comments") as! CommentDrawer
        vc.currentVideo = self.currentPost
        let options = SheetOptions(
            shrinkPresentingViewController: true, useInlineMode: true
        )

        let sheetController = SheetViewController(controller: vc, sizes: [.intrinsic, .percent(0.95)], options: options)
        sheetController.allowGestureThroughOverlay = true
        sheetController.dismissOnPull = false
        sheetController.gripSize = CGSize(width: 80, height: 6)

        // The color of the grip on the pull bar
        sheetController.gripColor = UIColor(named: "darkToWhite")

        // animate in
        sheetController.animateIn(to: view, in: self)
        
    }
    
    @objc func restartVideo(){
        self.player?.seek(to: 0, allowSeekAhead: true)
        self.player?.playVideo()
    }
    
    private func setupPlayer(){
        self.player = YTSwiftyPlayer(frame: CGRect(x: 0, y: -80, width: self.view.frame.width, height: self.postView.frame.height + 100), playerVars: [
            //.mute(true),
            .playsInline(true),
            .videoID(self.currentPost!.youtubeId),
            .loopVideo(false),
            .disableKeyboardControl(true),
            .autoplay(true),
            .showLoadPolicy(false),
            .showRelatedVideo(false),
            .showInfo(false),
            .showControls(VideoControlAppearance.hidden),
            .showModestbranding(false)])
        player!.delegate = self
        player!.setPlaybackQuality(YTSwiftyVideoQuality.large)
        player!.mute()
        player!.loadPlayer()
        self.player!.playVideo()
        self.player!.pauseVideo()
        self.postView.addSubview(player!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.player!.playVideo()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingBlur.alpha = 0
            }, completion: { (finished: Bool) in
                self.loadingBlur.isHidden = true
            })
        }
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        switch state {
        case YTSwiftyPlayerState.ended:
            self.restartVideo()
            break;
            default:
            break;
        }
    }
}

class VideoUpVoteGesture: UITapGestureRecognizer {
    var postId: String!
}


