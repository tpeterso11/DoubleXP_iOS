//
//  YoutubeConnect.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/15/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import PopupDialog
import AuthenticationServices
import FBSDKLoginKit
import Firebase
import Lottie

class YoutubeConnect: UIViewController, GIDSignInDelegate, SocialMediaManagerCallback, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var videoTabel: UITableView!
    @IBOutlet weak var clear: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var googleBlur: UIVisualEffectView!
    @IBOutlet weak var loading: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: AnimationView!
    var videoPayload = [YoutubeVideoObj]()
    var selectedPayload = [YoutubeVideoObj]()
    var selectedIds = [String]()
    var profileUser: User!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        if(!profileUser.googleApiAccessToken.isEmpty){
            UIView.animate(withDuration: 0.5, animations: {
                self.loading.alpha = 1
                self.loadingAnimation.play()
            }, completion: { (finished: Bool) in
                let manager = SocialMediaManager()
                manager.getYoutubeAccess(accessToken: self.profileUser.googleApiAccessToken, callbacks: self, currentUser: self.profileUser, tryRefresh: true)
                
                self.doneButton.addTarget(self, action: #selector(self.sendPayload), for: .touchUpInside)
                self.clear.addTarget(self, action: #selector(self.clearClicked), for: .touchUpInside)
            })
        } else {
            loading.alpha = 0
            googleBlur.alpha = 1
            signInButton.addTarget(self, action: #selector(googleSignIn), for: .touchUpInside)
            dismissButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
            self.googleBlur.alpha = 1
        }
        
        setupLongPressGesture()
    }
    
    func setupLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        self.videoTabel.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.videoTabel)
            if let indexPath = videoTabel.indexPathForRow(at: touchPoint) {
                let current = self.videoPayload[indexPath.item]
                var containedFavorite: YoutubeVideoObj? = nil
                for video in self.selectedPayload {
                    if(video.youtubeFavorite == "true"){
                        containedFavorite = video
                        break
                    }
                }
                
                //if the list is full, and there is already a favorite
                if(self.selectedPayload.count == 5 && containedFavorite != nil){
                    print(containedFavorite!.youtubeId)
                    if(containedFavorite!.youtubeId != current.youtubeId){
                        //only if the youtubeId is different, remove the old favorite completely, replace with new.
                        for video in self.selectedPayload {
                            if(video.youtubeId == containedFavorite!.youtubeId){
                                self.selectedPayload.remove(at: self.selectedPayload.index(of: video)!)
                                break
                            }
                        }
                        for video in self.videoPayload {
                            if(video.youtubeId == containedFavorite!.youtubeId){
                                video.youtubeFavorite = "false"
                                break
                            }
                        }
                        if(self.selectedIds.contains(containedFavorite!.youtubeId)){
                            self.selectedIds.remove(at: self.selectedIds.index(of: containedFavorite!.youtubeId)!)
                        }
                        current.youtubeFavorite = "true"
                        
                        if(!self.selectedIds.contains(current.youtubeId)){
                            self.selectedIds.append(current.youtubeId)
                            self.selectedPayload.append(current)
                        }
                    }
                } else if(self.selectedPayload.count == 5 && containedFavorite == nil){
                    if(containedFavorite!.youtubeId != current.youtubeId){
                        //only if the youtubeId is different, remove the first chosen vid, replace with new favorite.
                        let firstVid = self.selectedPayload[0]
                        if(self.selectedIds.contains(firstVid.youtubeId)){
                            self.selectedIds.remove(at: self.selectedIds.index(of: firstVid.youtubeId)!)
                        }
                        for video in self.selectedPayload {
                            if(video.youtubeId == firstVid.youtubeId){
                                self.selectedPayload.remove(at: self.selectedPayload.index(of: video)!)
                                break
                            }
                        }
                        current.youtubeFavorite = "true"
                        if(!self.selectedIds.contains(current.youtubeId)){
                            self.selectedIds.append(current.youtubeId)
                            self.selectedPayload.append(current)
                        }
                    }
                } else if(self.selectedPayload.count < 5) {
                    for video in self.selectedPayload {
                        if(video.youtubeFavorite == "true" && video.youtubeId != current.youtubeId){
                            video.youtubeFavorite = "false"
                        } else if(video.youtubeId == current.youtubeId && video.youtubeFavorite == "false"){
                            video.youtubeFavorite = "true"
                        }
                    }
                    if(!self.selectedIds.contains(current.youtubeId)){
                        current.youtubeFavorite = "true"
                        self.selectedIds.append(current.youtubeId)
                        self.selectedPayload.append(current)
                    }
                    
                    for video in self.videoPayload {
                        if(video.youtubeFavorite == "true" && video.youtubeId != current.youtubeId){
                            video.youtubeFavorite = "false"
                        }
                        if(video.youtubeId == current.youtubeId){
                            video.youtubeFavorite = "true"
                        }
                    }
                }
                self.videoTabel.reloadData()
            }
        }
    }
    
    func handleSelection(position: Int){
        let selectedVideo = self.videoPayload[position]
        if(selectedVideo.youtubeFavorite == "false" && !self.selectedIds.contains(selectedVideo.youtubeId) && self.selectedIds.count < 5){
            self.selectedIds.append(selectedVideo.youtubeId)
            self.selectedPayload.append(selectedVideo)
        } else if(selectedVideo.youtubeFavorite == "true"){
            selectedVideo.youtubeFavorite = "false"
        }
        else {
            if(self.selectedIds.contains(selectedVideo.youtubeId)){
                self.selectedIds.remove(at: self.selectedIds.index(of: selectedVideo.youtubeId)!)
            }
            for video in self.selectedPayload {
                if(video.youtubeId == selectedVideo.youtubeId){
                    self.selectedPayload.remove(at: self.selectedPayload.index(of: video)!)
                    break
                }
            }
        }
        self.videoTabel.reloadData()
    }
    
    @objc func clearClicked(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        ref.child("googleApiAccessToken").removeValue()
        ref.child("googleApiRefreshToken").removeValue()
        ref.child("googleUserId").removeValue()
        ref.child("youtubeVideos").removeValue()
        
        //Database.database().reference().child("YoutubeSubmissions").child(appDelegate.currentUser!.uId).removeValue()
        
        dismissModal()
    }
    
    @objc func dismissModal(){
        self.dismiss(animated: true, completion: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentProfileFrag?.dismissModal()
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
      // ...
      if let error = error {
        // ...AppEvents.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login Fail - " + error.localizedDescription))
        
        var buttons = [PopupDialogButton]()
        let title = "google login error."
        let message = "there was an error getting you logged into google. try again, or try registering using your email."
        
        let button = DefaultButton(title: "try again.") { [weak self] in
            self?.googleSignIn()
        }
        buttons.append(button)
        
        let buttonOne = CancelButton(title: "nevermind") { [weak self] in
            //
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
         return
      }

      guard let authentication = user.authentication else { return }
      let _ = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)
        if(user.userID != nil && !user.userID.isEmpty){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.child("googleUserId").setValue(user.userID)
            if(!authentication.accessToken.isEmpty){
                ref.child("googleApiAccessToken").setValue(authentication.accessToken)
                ref.child("googleApiRefreshToken").setValue(authentication.refreshToken)
                SocialMediaManager().getYoutubeAccess(accessToken: authentication.accessToken, callbacks: self, currentUser: self.profileUser, tryRefresh: true)
            }
        }
    }
    
    @objc private func googleSignIn(){
        UIView.animate(withDuration: 0.5, animations: {
            self.loading.alpha = 1
            self.loadingAnimation.alpha = 1
            self.loadingAnimation.play()
        }, completion: { (finished: Bool) in
            GIDSignIn.sharedInstance()?.scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
            GIDSignIn.sharedInstance().signIn()
        })
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        print("")
    }
    
    func loginManagerDidComplete(_ result: LoginManagerLoginResult?, _ error: Error?) {
        if let result = result, result.isCancelled {
            var buttons = [PopupDialogButton]()
            let title = "your login attempt was canceled."
            let message = "login attempt was canceled.."
            
            let button = DefaultButton(title: "try again.") { [weak self] in
                self?.googleSignIn()
                
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "i know") { [weak self] in
                //do nothing
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        } else {
            AppEvents.logEvent(AppEvents.Name(rawValue: "Youtube - Google Login Fail - " + "\(error?.localizedDescription ?? "")"))
            
            var buttons = [PopupDialogButton]()
            let title = "google login error."
            let message = "there was an error getting you logged into google. try again."
            
            let button = DefaultButton(title: "try again.") { [weak self] in
                self?.googleSignIn()
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "nevermind") { [weak self] in
            
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videoPayload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "video", for: indexPath) as! YoutubeVideoCell
        let current = self.videoPayload[indexPath.item]
        cell.title.text = current.title
        cell.videoDate.text = current.date
        
        if(current.youtubeFavorite == "true"){
            cell.baseColorLayer.backgroundColor = #colorLiteral(red: 1, green: 0.758044064, blue: 0, alpha: 0.6969980736)
            cell.baseColorLayer.alpha = 0.6
            cell.selectedBlur.alpha = 0
            cell.favoriteStar.alpha = 1
        } else if(self.selectedIds.contains(current.youtubeId)){
            cell.baseColorLayer.backgroundColor = #colorLiteral(red: 0.3333052099, green: 0.3333491981, blue: 0.3332902789, alpha: 1)
            cell.baseColorLayer.alpha = 0.6
            cell.selectedBlur.alpha = 0
            cell.favoriteStar.alpha = 0
        } else {
            cell.baseColorLayer.alpha = 0
            cell.selectedBlur.alpha = 0
            cell.favoriteStar.alpha = 0
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        
        if(cache.object(forKey: current.youtubeImg as NSString) != nil){
            cell.youtubeImg.image = cache.object(forKey: current.youtubeImg as NSString)
        } else {
            cell.youtubeImg.image = Utility.Image.placeholder
            cell.youtubeImg.moa.onSuccess = { image in
                cell.youtubeImg.image = image
                appDelegate.imageCache.setObject(image, forKey: current.youtubeImg as NSString)
                return image
            }
            cell.youtubeImg.moa.url = current.youtubeImg
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleSelection(position: indexPath.item)
    }
    
    @objc func sendPayload(){
        UIView.animate(withDuration: 0.5, animations: {
            self.loading.alpha = 1
            self.loadingAnimation.alpha = 1
            self.loadingAnimation.play()
        }, completion: { (finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                var sendUp = [[String: Any]]()
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                currentUser.youtubeVideos = self.selectedPayload
                for video in self.selectedPayload {
                    let newVid = ["title": video.title, "date": video.date, "videoOwnerGamerTag" : currentUser.gamerTag, "videoOwnerUid": currentUser.uId,
                                  "youtubeId": video.youtubeId, "youtubeImg": video.youtubeImg, "youtubeFavorite": video.youtubeFavorite, "downVotes": video.downVotes, "upVotes": video.upVotes] as [String : Any]
                    sendUp.append(newVid)
                }
                
                Database.database().reference().child("Users").child(currentUser.uId).child("youtubeVideos").setValue(sendUp)
                Database.database().reference().child("YoutubeSubmissions").child(currentUser.uId).setValue(sendUp)
                
                self.dismissModal()
            }
        })
    }
    
    func onTweetsLoaded(tweets: [TweetObject]) {
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
    }
    
    func onChannelsLoaded(channels: [Any]) {
    }
    
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection]){
        DispatchQueue.main.async {
            var buttons = [PopupDialogButton]()
            let manager = SocialMediaManager()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let title = "got a couple results back"
            let message = "for this account, we came back with a few channels to choose from. which channel would you like to use?"
            
            for channel in channels {
                let button = DefaultButton(title: channel.channelName!) { [weak self] in
                    self?.googleSignIn()
                    manager.attemptYoutubeVideos(channelId: channel.channelId!, accessToken: appDelegate.currentUser!.googleApiAccessToken, callbacks: self!, currentUser: appDelegate.currentUser!)
                }
                buttons.append(button)
            }
            
            let buttonOne = CancelButton(title: "nevermind.") { [weak self] in
                //do nothing
                self?.dismiss(animated: true, completion: nil)
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
    
    func setYoutubeInfo(){
        self.videoTabel.dataSource = self
        self.videoTabel.delegate = self
        self.videoTabel.reloadData()
        
        self.doneButton.addTarget(self, action: #selector(self.sendPayload), for: .touchUpInside)
        self.clear.addTarget(self, action: #selector(self.clearClicked), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.loading.alpha = 0
            self.googleBlur.alpha = 0
            self.loadingAnimation.pause()
        }, completion: nil)
    }
    
    func onYoutubeSuccessful(videos: [YoutubeVideoObj]) {
        DispatchQueue.main.async {
            self.videoPayload = videos
            self.updateVideos(list: videos)
        }
    }
    
    func updateVideos(list: [YoutubeVideoObj]){
        let youtubeRef = Database.database().reference().child("YoutubeSubmissions")
        youtubeRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            for user in snapshot.children {
                if((user as! DataSnapshot).key == appDelegate.currentUser!.uId){
                    for dbVideo in (user as! DataSnapshot).children {
                        var contained = false
                        for youtubeVideo in list {
                            let id = (dbVideo as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                            if(id == youtubeVideo.youtubeId){
                                contained = true
                                let youtubeFavorite = (dbVideo as! DataSnapshot).childSnapshot(forPath: "youtubeFavorite").value as? String ?? ""
                                let downVotes = (dbVideo as! DataSnapshot).childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                let upVotes = (dbVideo as! DataSnapshot).childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                youtubeVideo.youtubeFavorite = youtubeFavorite
                                youtubeVideo.downVotes = downVotes
                                youtubeVideo.upVotes = upVotes
                                
                                self.selectedPayload.append(youtubeVideo)
                                self.selectedIds.append(youtubeVideo.youtubeId)
                            }
                        }
                        if(!contained){
                            let id = (dbVideo as! DataSnapshot).childSnapshot(forPath: "youtubeId").value as? String ?? ""
                            let youtubeFavorite = (dbVideo as! DataSnapshot).childSnapshot(forPath: "youtubeFavorite").value as? String ?? ""
                            let downVotes = (dbVideo as! DataSnapshot).childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            let upVotes = (dbVideo as! DataSnapshot).childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            let img = (dbVideo as! DataSnapshot).childSnapshot(forPath: "youtubeImg").value as? String ?? ""
                            let title = (dbVideo as! DataSnapshot).childSnapshot(forPath: "title").value as? String ?? ""
                            let gamertag = (dbVideo as! DataSnapshot).childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? ""
                            let uid = (dbVideo as! DataSnapshot).childSnapshot(forPath: "videoOwnerUid").value as? String ?? ""
                            let date = (dbVideo as! DataSnapshot).childSnapshot(forPath: "videoOwnerUid").value as? String ?? ""
                            
                            let newVideo = YoutubeVideoObj(title: title, videoOwnerGamerTag: gamertag, videoOwnerUid: uid, youtubeFavorite: youtubeFavorite, date: date, youtubeId: id, imgUrl: img)
                            newVideo.downVotes = downVotes
                            newVideo.upVotes = upVotes
                            
                            self.selectedIds.append(id)
                            self.selectedPayload.append(newVideo)
                            self.videoPayload.append(newVideo)
                        }
                    }
                }
            }
            self.setYoutubeInfo()
        })
    }
    
    func onYoutubeFail() {
        DispatchQueue.main.async {
            var buttons = [PopupDialogButton]()
            let title = "soooo..."
            let message = "there was a problem getting your videos from youtube."
            
            let button = DefaultButton(title: "try again now.") { [weak self] in
                self?.googleSignIn()
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "try again later.") { [weak self] in
                //do nothing
                self?.dismiss(animated: true, completion: nil)
            }
            buttons.append(buttonOne)
            
            let popup = PopupDialog(title: title, message: message)
            popup.addButtons(buttons)

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
    }
}

class YoutubeMultiChannelSelection {
    var channelName: String?
    var channelId: String?
}
