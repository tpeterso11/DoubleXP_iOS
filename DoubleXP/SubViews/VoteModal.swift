//
//  VoteModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/17/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import YoutubeKit
import youtube_ios_player_helper
import Lottie
import AVFoundation

import Firebase

class VoteModal: UIViewController, YTSwiftyPlayerDelegate {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var youtubePlayer: UIView!
    var compId: String?
    var payload = [CompEntryObject]()
    private var player: YTSwiftyPlayer!
    @IBOutlet weak var gamertag: UILabel!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var passButton: UIButton!
    var currentEntry: CompEntryObject?
    var maxEntriesReached = false
    var currentIds = [String]()
    
    @IBOutlet weak var testTvAnimation: LottieAnimationView!
    
    @IBOutlet weak var successAnimation: LottieAnimationView!
    @IBOutlet weak var passAnimation: LottieAnimationView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyDismiss: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.successAnimation.alpha = 0
        self.passAnimation.alpha = 0
        self.testTvAnimation.alpha = 1
        self.testTvAnimation.loopMode = .loop
        self.testTvAnimation.play()
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.getEntries()
        }
    }
    
    private func getEntries(){
        let ref = Database.database().reference().child("Entries").child(compId!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                //var passBucket = [CompEntryObject]()
                for user in snapshot.children {
                    let videoArray = snapshot.childSnapshot(forPath: (user as! DataSnapshot).key)
                    for video in videoArray.children {
                            let currentVid = video as! DataSnapshot
                            let dict = currentVid.value as! [String: Any]
                            let uid = dict["uid"] as? String ?? ""
                            print(uid)
                            let gamerTag = dict["gamerTag"] as? String ?? ""
                            let youtubeId = dict["youtubeId"] as? String ?? ""
                            let imgUrl = dict["imgUrl"] as? String ?? ""
                            let compId = dict["compId"] as? String ?? ""
                            let votersUids = dict["votersUids"] as? [String] ?? [String]()
                            let passUids = dict["passUids"] as? [String] ?? [String]()
                            let voteCount = dict["voteCount"] as? CLong ?? -1
                            let currentPosition = dict["currentPosition"] as? CLong ?? -1
                            let lastPostion = dict["lastPostion"] as? CLong ?? -1
                            print(passUids)
                        let newEntry = CompEntryObject(uid: uid, youtubeId: youtubeId, imgUrl: imgUrl, compId: compId, voteCount: voteCount, votersUids: votersUids, currentPosition: currentPosition, lastPosition: lastPostion, gamerTag: gamerTag, dbKey: currentVid.key, passUids: passUids)
                        
                        if(!votersUids.contains(appDelegate.currentUser!.uId) && !passUids.contains(appDelegate.currentUser!.uId) && newEntry.uid != appDelegate.currentUser!.uId && self.payload.count < 20){
                            self.payload.append(newEntry)
                            self.currentIds.append(newEntry.youtubeId)
                        }
                        
                        if(self.payload.count == 20){
                            self.maxEntriesReached = true
                            break
                        }
                    }
                }

                if(!self.payload.isEmpty){
                    self.setupYoutubePlayer()
                    self.setupInitialUI()
                } else {
                    UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                        self.emptyView.alpha = 1
                        self.emptyDismiss.addTarget(self, action: #selector(self.dismissClicked), for: .touchUpInside)
                        self.status.alpha = 0
                    }, completion: nil)
                }
            }
        })
    }
    
    private func setupYoutubePlayer(){
        self.gamertag.text = self.payload[0].gamerTag
        self.currentEntry = self.payload[0]
        self.player = YTSwiftyPlayer(frame: CGRect(x: -200, y: -150, width: self.view.bounds.width + 400, height: self.youtubePlayer.bounds.height + 400), playerVars: [
            //.mute(true),
            .playsInline(true),
            .videoID(self.currentEntry?.youtubeId ?? ""),
            .loopVideo(true),
            .disableKeyboardControl(true),
            .autoplay(true),
            .showLoadPolicy(false),
            .showRelatedVideo(false),
            .showInfo(false),
            .showControls(VideoControlAppearance.hidden),
            .showModestbranding(false)])
        player.delegate = self
        player.setPlaybackQuality(YTSwiftyVideoQuality.small)
        player.mute()
        player.loadPlayer()
        player.autoplay = true
        self.youtubePlayer.addSubview(player)
        player.pauseVideo()
        player.playVideo()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                self.testTvAnimation.alpha = 0.0
                self.testTvAnimation.pause()
            }, completion: nil)
        }
    }
    
    private func setupInitialUI(){
        if(self.payload.count > 1){
            self.passButton.alpha = 1
            self.passButton.isUserInteractionEnabled = true
            self.passButton.addTarget(self, action: #selector(pass), for: .touchUpInside)
        } else {
            self.passButton.alpha = 0.5
            self.passButton.isUserInteractionEnabled = false
        }
        
        self.voteButton.addTarget(self, action: #selector(vote), for: .touchUpInside)
    }
    
    @objc private func vote(){
        Vibration.success.vibrate()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
            self.status.text = "yeah.that one is dope. next..."
            self.passButton.isUserInteractionEnabled = false
            self.voteButton.isUserInteractionEnabled = false
            self.passButton.alpha = 0.3
            self.voteButton.alpha = 0.3
            self.successAnimation.alpha = 1.0
            self.successAnimation.play()
        }, completion: { (finished: Bool) in
            if(self.currentEntry != nil){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let ref = Database.database().reference().child("Entries").child(self.compId!).child(self.currentEntry!.uid)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.exists()){
                        let entry = snapshot.childSnapshot(forPath: "0")
                        if(entry != nil){
                            if(entry.hasChild("voterUids")){
                                var uids = entry.childSnapshot(forPath: "voterUids").value as? [String] ?? [String]()
                                if(!uids.contains(appDelegate.currentUser!.uId)){
                                    uids.append(appDelegate.currentUser!.uId)
                                }
                                ref.child(entry.key).child("voterUids").setValue(uids)
                            } else {
                                ref.child(entry.key).child("voterUids").setValue([appDelegate.currentUser!.uId])
                            }
                            if(entry.hasChild("voteCount")){
                                var count = entry.childSnapshot(forPath: "voteCount").value as? Int ?? 0
                                count += 1
                                ref.child(entry.key).child("voteCount").setValue(count)
                            }
                            if(entry.hasChild("viewedUids")){
                                var uids = entry.childSnapshot(forPath: "viewedUids").value as? [String] ?? [String]()
                                if(!uids.contains(appDelegate.currentUser!.uId)){
                                    uids.append(appDelegate.currentUser!.uId)
                                    ref.child(entry.key).child("viewedUids").setValue(uids)
                                }
                            } else {
                                ref.child(entry.key).child("viewedUids").setValue([appDelegate.currentUser!.uId])
                            }
                        }
                        self.proceedToNextVideo(type: "vote")
                    }
                })
            } else {
                self.proceedToNextVideo(type: "vote")
            }
        })
    }
    
    @objc private func pass(){
        Vibration.warning.vibrate()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
            self.status.text = "meh. ok, next up..."
            self.passAnimation.alpha = 1.0
            self.passButton.isUserInteractionEnabled = false
            self.voteButton.isUserInteractionEnabled = false
            self.passButton.alpha = 0.3
            self.voteButton.alpha = 0.3
            self.passAnimation.play()
        }, completion: { (finished: Bool) in
            if(self.currentEntry != nil){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let ref = Database.database().reference().child("Entries").child(self.compId!).child(self.currentEntry!.uid)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.exists()){
                            let entry = snapshot.childSnapshot(forPath: "0")
                        if(entry != nil){
                            if(entry.hasChild("passUids")){
                                var uids = entry.childSnapshot(forPath: "passUids").value as? [String] ?? [String]()
                                if(!uids.contains(appDelegate.currentUser!.uId)){
                                    uids.append(appDelegate.currentUser!.uId)
                                }
                                ref.child(entry.key).child("passUids").setValue(uids)
                            } else {
                                ref.child(entry.key).child("passUids").setValue([appDelegate.currentUser!.uId])
                            }
                        }
                        self.proceedToNextVideo(type: "pass")
                    }
                })
            }  else {
                self.proceedToNextVideo(type: "pass")
            }
        })
    }
    
    private func proceedToNextVideo(type: String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                self.youtubePlayer.alpha = 0.0
            }, completion: { (finished: Bool) in
                if(self.payload.count > 1) {
                    self.payload.remove(at: 0)
                    self.currentEntry = self.payload[0]
                    
                    if(self.payload.count < 10 && !self.maxEntriesReached){
                        self.attemptListRefresh()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                        self.player.loadVideo(videoID: self.payload[0].youtubeId)
                        self.player.playVideo()
                        self.gamertag.text = self.payload[0].gamerTag
                        self.youtubePlayer.alpha = 1.0
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                            if(type == "pass"){
                                self.passAnimation.alpha = 0.0
                                self.passAnimation.pause()
                            } else if(type == "vote"){
                                self.successAnimation.alpha = 0.0
                                self.successAnimation.pause()
                            } else {
                                self.testTvAnimation.alpha = 0.0
                                self.testTvAnimation.pause()
                            }
                            self.status.text = "now playing"
                            self.passButton.alpha = 1.0
                            self.voteButton.alpha = 1.0
                            self.passButton.isUserInteractionEnabled = true
                            self.voteButton.isUserInteractionEnabled = true
                        }, completion: nil)
                    })
                } else {
                    self.player.clearVideo()
                    self.youtubePlayer.alpha = 0
                    UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut, animations: { () -> Void in
                        self.emptyView.alpha = 1
                        self.emptyDismiss.addTarget(self, action: #selector(self.dismissClicked), for: .touchUpInside)
                        self.status.alpha = 0
                    }, completion: nil)
                }
            })
        }
    }
    
    @objc private func dismissClicked(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentCompetitionPage?.checkEntries()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func attemptListRefresh(){
        let ref = Database.database().reference().child("Entries").child(compId!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                for user in snapshot.children {
                    let videoArray = snapshot.childSnapshot(forPath: (user as! DataSnapshot).key)
                    for video in videoArray.children {
                            let currentVid = video as! DataSnapshot
                            let dict = currentVid.value as! [String: Any]
                            let uid = dict["uid"] as? String ?? ""
                            let gamerTag = dict["gamerTag"] as? String ?? ""
                            let youtubeId = dict["youtubeId"] as? String ?? ""
                            let imgUrl = dict["imgUrl"] as? String ?? ""
                            let compId = dict["compId"] as? String ?? ""
                            let votersUids = dict["votersUids"] as? [String] ?? [String]()
                            let passUids = dict["passUids"] as? [String] ?? [String]()
                            let voteCount = dict["voteCount"] as? CLong ?? -1
                            let currentPosition = dict["currentPosition"] as? CLong ?? -1
                            let lastPostion = dict["lastPostion"] as? CLong ?? -1
                        
                        let newEntry = CompEntryObject(uid: uid, youtubeId: youtubeId, imgUrl: imgUrl, compId: compId, voteCount: voteCount, votersUids: votersUids, currentPosition: currentPosition, lastPosition: lastPostion, gamerTag: gamerTag, dbKey: currentVid.key, passUids: passUids)
                        
                        if(!votersUids.contains(appDelegate.currentUser!.uId) && newEntry.uid != appDelegate.currentUser!.uId && !passUids.contains(appDelegate.currentUser!.uId) && !self.currentIds.contains(newEntry.youtubeId) &&
                            !self.currentIds.contains(youtubeId) && self.payload.count < 20){
                            self.payload.append(newEntry)
                        }
                        
                        if(self.payload.count == 20){
                            self.maxEntriesReached = true
                            break
                        }
                    }
                }
            }
        })
    }
}

enum Vibration {
        case error
        case success
        case warning
        case light
        case medium
        case heavy
        @available(iOS 13.0, *)
        case soft
        @available(iOS 13.0, *)
        case rigid
        case selection
        case oldSchool

        public func vibrate() {
            switch self {
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .soft:
                if #available(iOS 13.0, *) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            case .rigid:
                if #available(iOS 13.0, *) {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            case .selection:
                UISelectionFeedbackGenerator().selectionChanged()
            case .oldSchool:
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }
