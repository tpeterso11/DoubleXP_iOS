//
//  VideoMessage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/3/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import GoogleSignIn
import AuthenticationServices
import Firebase
import PopupDialog
import FBSDKLoginKit

class VideoMessage : UIViewController, GIDSignInDelegate, SocialMediaManagerCallback, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var startAnimation: AnimationView!
    @IBOutlet weak var startLayer: UIView!
    @IBOutlet weak var googleAnimation: AnimationView!
    @IBOutlet weak var googleLayout: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emptyLayout: UIView!
    @IBOutlet weak var emptyAnimation: AnimationView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var videoCarousel: UICollectionView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var recipientView: UIView!
    
    var payload = [YoutubeVideoObj]()
    let flowLayout = ZoomAndSnapFlowLayout()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser!
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        if(!user.googleApiAccessToken.isEmpty){
            self.startLayer.isHidden = false
            UIView.animate(withDuration: 0.5, animations: {
                self.startLayer.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.startAnimation.loopMode = .loop
                    self.startAnimation.play()
                }
            }, completion: { (finished: Bool) in
                let manager = SocialMediaManager()
                manager.getYoutubeAccess(accessToken: user.googleApiAccessToken, callbacks: self, currentUser: user, tryRefresh: true)
            })
            
            
        } else {
            self.googleLayout.isHidden = false
            UIView.animate(withDuration: 0.5, animations: {
                self.googleLayout.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.googleAnimation.loopMode = .loop
                    self.googleAnimation.play()
                }
            }, completion: { (finished: Bool) in
                self.startButton.addTarget(self, action: #selector(self.googleSignIn), for: .touchUpInside)
                //GIDSignIn.sharedInstance()?.scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
                //GIDSignIn.sharedInstance().signIn()
            })
        }
    
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
                delegate.currentUser!.googleApiAccessToken = authentication.accessToken
                delegate.currentUser!.googleApiRefreshToken = authentication.refreshToken
                ref.child("googleApiAccessToken").setValue(authentication.accessToken)
                ref.child("googleApiRefreshToken").setValue(authentication.refreshToken)
                SocialMediaManager().getYoutubeAccess(accessToken: authentication.accessToken, callbacks: self, currentUser: delegate.currentUser!, tryRefresh: true)
            }
        }
    }
    
    @objc private func googleSignIn(){
        GIDSignIn.sharedInstance()?.scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
        GIDSignIn.sharedInstance().signIn()
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
            //AppEvents.logEvent(AppEvents.Name(rawValue: "Youtube - Google Login Fail - " + "\(error?.localizedDescription ?? "")"))
            
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
    
    func onTweetsLoaded(tweets: [TweetObject]) {
    }
    
    func onStreamsLoaded(streams: [TwitchStreamObject]) {
    }
    
    func onChannelsLoaded(channels: [Any]) {
    }
    
    func onYoutubeSuccessful(videos: [YoutubeVideoObj]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startLayer.alpha = 0
            self.startAnimation.pause()
            self.selectionView.isHidden = false
            self.selectionView.alpha = 1
            self.payload.append(contentsOf: videos)
            
            if(self.payload.isEmpty){
                self.showEmpty()
            } else {
                self.videoCarousel.delegate = self
                self.videoCarousel.dataSource = self
                self.videoCarousel.collectionViewLayout = self.flowLayout
                self.videoCarousel.contentInsetAdjustmentBehavior = .always
                self.videoCarousel.reloadData()
            }
        }
    }
    
    func onYoutubeFail() {
        
    }
    
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection]) {
        
    }
    
    private func showEmpty(){
        UIView.animate(withDuration: 0.5, animations: {
            self.emptyLayout.alpha = 1
            self.emptyAnimation.loopMode = .playOnce
            self.emptyAnimation.play()
        }, completion: { (finished: Bool) in
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.clearAndClose))
            self.clearButton.isUserInteractionEnabled = true
            self.clearButton.addGestureRecognizer(singleTap)
        })
    }
    
    @objc private func clearAndClose(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("googleUserId").removeValue()
        ref.child("googleApiAccessToken").removeValue()
        ref.child("googleApiRefreshToken").removeValue()
        
        delegate.currentUser!.googleApiAccessToken = ""
        delegate.currentUser!.googleApiRefreshToken = ""
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "video", for: indexPath) as! VideoSelectionCell
        let current = self.payload[indexPath.item]
        cell.videoTitle.text = current.title
        
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
        cell.youtubeImg.contentMode = .scaleAspectFill
        
        cell.contentView.layer.cornerRadius = 15.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 180, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
