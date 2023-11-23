//
//  PlayModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/13/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import YoutubeKit
import youtube_ios_player_helper
import AVKit
import Lottie

class PlayModal: UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate, YTSwiftyPlayerDelegate {
    @IBOutlet weak var playTable: UITableView!
    var payload = [String]()
    var compPayload = [CompetitionObj]()
    private var player: AVPlayer!
    
    @IBOutlet weak var introPlayHeaderAnimation: LottieAnimationView!
    @IBOutlet weak var playIntroBlur: UIVisualEffectView!
    @IBOutlet weak var introDismissButton: UIButton!
    @IBOutlet weak var introBottom: UIView!
    @IBOutlet weak var introHeaderOne: UILabel!
    @IBOutlet weak var introDividerOne: UIView!
    @IBOutlet weak var introHeaderTwo: UILabel!
    override func viewWillAppear(_ animated: Bool) {
        self.introPlayHeaderAnimation.contentMode = .scaleAspectFill
        self.introPlayHeaderAnimation.clipsToBounds = true
        self.introPlayHeaderAnimation.currentFrame = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        compPayload.append(contentsOf: delegate.competitions)
        
        payload.append("video")
        payload.append("comps")
        payload.append("instructions")
        
        playTable.dataSource = self
        playTable.delegate = self
        
        let preferences = UserDefaults.standard

        let currentLevelKey = "playIntroBlur"
        if preferences.object(forKey: currentLevelKey) == nil {
            showIntroBlur()
        }
    }
    
    private func showIntroBlur(){
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.playIntroBlur.alpha = 1
            
            let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissIntroBlur))
            self.playIntroBlur.isUserInteractionEnabled = true
            self.playIntroBlur.addGestureRecognizer(backTap)
            
            self.introDismissButton.addTarget(self, action: #selector(self.dismissIntroBlur), for: .touchUpInside)
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                //self.introPlayHeaderAnimation.clipsToBounds
                self.introPlayHeaderAnimation.play()
                let top = CGAffineTransform(translationX: 0, y: 50)
                UIView.transition(with: self.introPlayHeaderAnimation, duration: 0.5, options: [.transitionFlipFromTop], animations: {
                    self.introPlayHeaderAnimation.transform = top
                    self.introPlayHeaderAnimation.alpha = 1
                    }, completion: {_ in
                    //show text
                    UIView.transition(with: self.introHeaderOne, duration: 0.5, options: [.curveLinear],
                         animations: {
                            self.introHeaderOne.alpha = 1
                            self.introDividerOne.alpha = 1
                            self.introHeaderTwo.alpha = 1
                           }, completion: {_ in
                            UIView.animate(withDuration: 0.8, animations: {
                                self.introBottom.alpha = 1
                                self.introDismissButton.alpha = 1
                            }, completion: { (finished: Bool) in
                                
                            })
                        })
                })
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func launchCompPage(currentComp: CompetitionObj){
        self.player.pause()
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "compPage") as! CompetitionPageV2
        currentViewController.currentComp = currentComp
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchFeaturedCompPage(){
        self.player.pause()
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "compPage") as! CompetitionPageV2
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var featuredComp: CompetitionObj? = nil
        for comp in self.compPayload {
            if(comp.competitionId == delegate.playHeaderCompId){
                featuredComp = comp
                break
            }
        }
        currentViewController.currentComp = featuredComp
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        if(current == "video"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "video", for: indexPath) as! PlayVideoHeader
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let videoURL = URL(string: delegate.playHeaderUrl)
            if(videoURL != nil){
                self.player = AVPlayer(url: videoURL!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = CGRect(x: 0, y: 0, width: self.view.window!.bounds.width, height: cell.bounds.height)
                playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                cell.videoPlayer.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            
            if(!delegate.playHeaderCompId.isEmpty){
                cell.moreInfoButton.alpha = 1.0
                cell.moreInfoButton.isUserInteractionEnabled = true
                cell.moreInfoButton.addTarget(self, action: #selector(launchFeaturedCompPage), for: .touchUpInside)
            } else {
                cell.moreInfoButton.alpha = 0.0
                cell.moreInfoButton.isUserInteractionEnabled = false
            }
            
            var compTitle = ""
            var topPrize = ""
            var topPrizeType = ""
            for comp in delegate.competitions {
                if(comp.competitionId == delegate.playHeaderCompId){
                    compTitle = comp.competitionName
                    topPrize = comp.topPrize
                    topPrizeType = comp.topPrizeType
                    break
                }
            }
            cell.compName.text = compTitle
            
            if(!topPrize.isEmpty && !topPrizeType.isEmpty){
                cell.winningsLabel.isHidden = false
                cell.winningsLabel.text = "win " + topPrize + " " + topPrizeType
            } else {
                cell.winningsLabel.isHidden = true
            }
            
            return cell
        }
        else if(current == "instructions"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "instructions", for: indexPath) as! CompInstructions
            
            /*cell.findBox.layer.cornerRadius = 10.0
            cell.findBox.layer.borderWidth = 1.0
            cell.findBox.layer.borderColor = UIColor.clear.cgColor
            cell.findBox.layer.masksToBounds = true
            cell.findBox.layer.shadowColor = UIColor.black.cgColor
            cell.findBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.findBox.layer.shadowRadius = 2.0
            cell.findBox.layer.shadowOpacity = 0.5
            cell.findBox.layer.masksToBounds = false
            cell.findBox.layer.shadowPath = UIBezierPath(roundedRect: cell.findBox.bounds, cornerRadius: cell.findBox.layer.cornerRadius).cgPath
            
            cell.playBox.layer.cornerRadius = 10.0
            cell.playBox.layer.borderWidth = 1.0
            cell.playBox.layer.borderColor = UIColor.clear.cgColor
            cell.playBox.layer.masksToBounds = true
            cell.playBox.layer.shadowColor = UIColor.black.cgColor
            cell.playBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.playBox.layer.shadowRadius = 2.0
            cell.playBox.layer.shadowOpacity = 0.5
            cell.playBox.layer.masksToBounds = false
            cell.playBox.layer.shadowPath = UIBezierPath(roundedRect: cell.playBox.bounds, cornerRadius: cell.playBox.layer.cornerRadius).cgPath
            
            cell.uploadBox.layer.cornerRadius = 10.0
            cell.uploadBox.layer.borderWidth = 1.0
            cell.uploadBox.layer.borderColor = UIColor.clear.cgColor
            cell.uploadBox.layer.masksToBounds = true
            cell.uploadBox.layer.shadowColor = UIColor.black.cgColor
            cell.uploadBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.uploadBox.layer.shadowRadius = 2.0
            cell.uploadBox.layer.shadowOpacity = 0.5
            cell.uploadBox.layer.masksToBounds = false
            cell.uploadBox.layer.shadowPath = UIBezierPath(roundedRect: cell.uploadBox.bounds, cornerRadius: cell.uploadBox.layer.cornerRadius).cgPath*/
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "comps", for: indexPath) as! PlayHeaderCell
            if self.traitCollection.userInterfaceStyle == .dark {
                cell.compBg.image = #imageLiteral(resourceName: "beard_dude.jpg")
            } else {
                cell.compBg.image = #imageLiteral(resourceName: "we_did_it.jpg")
            }
            
            cell.setList(list: self.compPayload, modal: self)
            
            return cell
        }
    }
    
    
    @objc private func dismissIntroBlur(){
        UIView.animate(withDuration: 0.8, delay: 0.0, options:[], animations: {
            self.playIntroBlur.alpha = 0
        }, completion: { (finished: Bool) in
            let preferences = UserDefaults.standard
            let currentLevelKey = "playIntroBlur"
            preferences.set(true, forKey: currentLevelKey)
        })
    }
}
