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

class YoutubeConnect: UIViewController, SocialMediaManagerCallback, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var videoTabel: UITableView!
    @IBOutlet weak var googleBlur: UIVisualEffectView!
    @IBOutlet weak var loading: UIVisualEffectView!
    @IBOutlet weak var youtubeHeader: UILabel!
    @IBOutlet weak var youtubeSub: UILabel!
    var videoPayload = [YoutubeVideoObj]()
    var selectedPayload = [YoutubeVideoObj]()
    var selectedVideo: YoutubeVideoObj?
    var profileUser: User!
    var competitionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!profileUser.googleApiAccessToken.isEmpty){
            UIView.animate(withDuration: 0.5, animations: {
                self.loading.alpha = 1
                self.loadingAnimation.play()
            }, completion: { (finished: Bool) in
                let manager = SocialMediaManager()
                manager.getYoutubeAccess(accessToken: self.profileUser.googleApiAccessToken, callbacks: self, currentUser: self.profileUser, tryRefresh: true)
            })
        } else {
            loading.alpha = 0
            googleBlur.alpha = 1
            self.googleBlur.alpha = 1
        }
    }
    
    func handleSelection(position: Int){
        let checkVideo = self.videoPayload[position]
        for video in self.videoPayload {
            if(video.youtubeId != checkVideo.youtubeId){
                video.youtubeFavorite = "false"
            }
            if(video.youtubeId == checkVideo.youtubeId){
                video.youtubeFavorite = "true"
                self.selectedVideo = video
                
                if(!self.selectedPayload.isEmpty){
                    self.selectedPayload.removeAll()
                }
                self.selectedPayload.append(video)
            }
        }
        self.videoTabel.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.sendPayload()
        super.viewWillDisappear(true)
    }
    
    @objc func dismissModal(){
        if(self.competitionId != nil){
            self.dismiss(animated: true, completion: {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentCompetitionPage!.checkEntryEligiblity()
            })
        } else {
            self.dismiss(animated: true, completion: {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.currentProfileFrag?.dismissModal()
            })
        }
    }
    
    func onSignInComplete(result: GIDSignInResult?, didSignInFor user: GIDGoogleUser!, withError error: Error?){
        if let error = error {
            // ...AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Login - Facebook Login Fail - " + error.localizedDescription))
            
            var buttons = [PopupDialogButton]()
            let title = "google login error."
            let message = "there was an error getting you logged into google. try again, or try registering using your email."
            
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
            return
        }
        
        guard let authentication = result?.user else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken?.tokenString ?? "",
                                                       accessToken: authentication.accessToken.tokenString)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if error != nil {
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Register - Google Login Fail Firebase"))
                print(error)
            } else {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                ref.child("googleUserId").setValue(user.userID)
                if(!authentication.accessToken.tokenString.isEmpty){
                    delegate.currentUser!.googleApiAccessToken = authentication.accessToken.tokenString
                    delegate.currentUser!.googleApiRefreshToken = authentication.refreshToken.tokenString
                    ref.child("googleApiAccessToken").setValue(authentication.accessToken.tokenString)
                    ref.child("googleApiRefreshToken").setValue(authentication.refreshToken.tokenString)
                    SocialMediaManager().getYoutubeAccess(accessToken: authentication.accessToken.tokenString, callbacks: self, currentUser: self.profileUser, tryRefresh: true)
                }
            }
        }
    }
    
    @objc private func googleSignIn(){
        UIView.animate(withDuration: 0.5, animations: {
            self.loading.alpha = 1
            self.loadingAnimation.alpha = 1
            self.loadingAnimation.play()
        }, completion: { (finished: Bool) in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: self, hint: nil, additionalScopes: ["email", "https://www.googleapis.com/auth/youtube.readonly"]
            ) { result, error in
                if let token = result?.user.idToken {
                    self.onSignInComplete(result: result, didSignInFor: result?.user, withError: nil)
                    return
                }
                guard let error = error as? GIDSignInError else {
                    fatalError("No token and no GIDSignInError: \(String(describing: error))")
                }
                self.onSignInComplete(result: result, didSignInFor: nil, withError: error)
            }
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
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Youtube - Google Login Fail - " + "\(error?.localizedDescription ?? "")"))
            
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
        
        if(current.youtubeFavorite == "true" && self.competitionId == nil){
            cell.baseColorLayer.backgroundColor = #colorLiteral(red: 1, green: 0.758044064, blue: 0, alpha: 0.6969980736)
            cell.baseColorLayer.alpha = 0.6
            cell.selectedBlur.alpha = 0
            cell.favoriteStar.alpha = 1
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
        if(!self.selectedPayload.isEmpty){
            UIView.animate(withDuration: 0.5, animations: {
                self.loading.alpha = 1
                self.loadingAnimation.alpha = 1
                self.loadingAnimation.play()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    var sendUp = [[String: Any]]()
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser!
                    
                    if(self.competitionId != nil){
                        for video in self.selectedPayload {
                            let newVid = ["compId": self.competitionId!, "imgUrl": video.youtubeImg, "uid" : currentUser.uId, "voteCount": 1,
                                          "youtubeId": video.youtubeId, "voterUids": [currentUser.uId], "gamerTag": currentUser.gamerTag, "currentPosition": -1, "lastPosition": -1] as [String : Any]
                            sendUp.append(newVid)
                        }
                        Database.database().reference().child("Entries").child(self.competitionId!).child(currentUser.uId).setValue(sendUp)
                    } else {
                        currentUser.youtubeVideos = self.selectedPayload
                        for video in self.selectedPayload {
                            let newVid = ["title": video.title, "date": video.date, "videoOwnerGamerTag" : currentUser.gamerTag, "videoOwnerUid": currentUser.uId,
                                          "youtubeId": video.youtubeId, "youtubeImg": video.youtubeImg, "youtubeFavorite": video.youtubeFavorite, "downVotes": video.downVotes, "upVotes": video.upVotes] as [String : Any]
                            sendUp.append(newVid)
                        }
                        
                        Database.database().reference().child("Users").child(currentUser.uId).child("youtubeVideos").setValue(sendUp)
                        Database.database().reference().child("YoutubeSubmissions").child(currentUser.uId).setValue(sendUp)
                    }
                    
                    self.dismissModal()
                }
            })
        }
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
        return CGFloat(120)
    }
    
    func setYoutubeInfo(){
        self.videoTabel.dataSource = self
        self.videoTabel.delegate = self
        self.videoTabel.reloadData()
        
        if(self.competitionId != nil){
            self.youtubeHeader.text = "your most recent videos"
            self.youtubeSub.text = ""
        }
        
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
        if(self.competitionId == nil){
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
                                
                                self.selectedPayload.append(newVideo)
                                self.videoPayload.append(newVideo)
                            }
                        }
                    }
                }
                self.setYoutubeInfo()
            })
        } else {
            self.setYoutubeInfo()
        }
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
