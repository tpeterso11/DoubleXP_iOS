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
import YoutubeKit

class VideoMessage : UIViewController, SocialMediaManagerCallback, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, YTSwiftyPlayerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var googleAnimation: LottieAnimationView!
    @IBOutlet weak var googleLayout: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emptyLayout: UIView!
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var videoCarousel: UICollectionView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var recipientView: UIView!
    @IBOutlet weak var playerShell: UIView!
    @IBOutlet weak var playerLoadingCover: UIView!
    @IBOutlet weak var emptyAnimation: LottieAnimationView!
    @IBOutlet weak var videosLoadingAnimation: LottieAnimationView!
    @IBOutlet weak var videosLoadingCover: UIView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var helpLayout: UIView!
    @IBOutlet weak var loadingBlur: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    @IBOutlet weak var loadingSub: UILabel!
    @IBOutlet weak var loadingTitle: UILabel!
    @IBOutlet weak var firstPostSub: UILabel!
    @IBOutlet weak var firstPostHeader: UILabel!
    @IBOutlet weak var firstPostFinishBlur: UIVisualEffectView!
    @IBOutlet weak var firstFinishAnimation: LottieAnimationView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var info: UIImageView!
    @IBOutlet weak var publicButtonLabel: UILabel!
    @IBOutlet weak var privateButtonLabel: UILabel!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var gameShell: UIView!
    @IBOutlet weak var tabletopOption: UIView!
    @IBOutlet weak var mobileOption: UIView!
    @IBOutlet weak var psOption: UIView!
    @IBOutlet weak var pcOption: UIView!
    @IBOutlet weak var xboxOption: UIView!
    @IBOutlet weak var recipientsShell: UIView!
    @IBOutlet weak var privateButton: UIView!
    @IBOutlet weak var publicButton: UIView!
    @IBOutlet weak var chooseConsoleTag: UILabel!
    @IBOutlet weak var stepThreeAnimation: LottieAnimationView!
    @IBOutlet weak var stepThreeLabel: UILabel!
    @IBOutlet weak var stepThreeView: UIView!
    @IBOutlet weak var helpHeader: UILabel!
    @IBOutlet weak var nintendoHelp: UIImageView!
    @IBOutlet weak var xboxHelp: UIImageView!
    @IBOutlet weak var psHelp: UIImageView!
    @IBOutlet weak var stepTwoAnimation: LottieAnimationView!
    @IBOutlet weak var stepTwoLabel: UILabel!
    @IBOutlet weak var stepTwoView: UIView!
    @IBOutlet weak var stepOneAnimation: LottieAnimationView!
    @IBOutlet weak var stepOneLabel: UILabel!
    @IBOutlet weak var stepOneView: UIView!
    @IBOutlet weak var consoleInstructions: UIView!
    @IBOutlet weak var playerLoadingAnimation: LottieAnimationView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var gameChoiceCollection: UICollectionView!
    var payload = [YoutubeVideoObj]()
    var gamePayload = [GamerConnectGame]()
    let flowLayout = UICollectionViewFlowLayout()
    var currentSelection: YoutubeVideoObj?
    var player: YTSwiftyPlayer!
    var selectedGame: String?
    var currentMessageScope = "public"
    var selectedConsole = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser!
        
        self.loadingAnimation.loopMode = .loop
        self.loadingAnimation.play()
        if(!user.googleApiAccessToken.isEmpty){
            if(user.myPosts.isEmpty){
                self.loadingTitle.text = "let's make your first post"
            }
            self.continueButton.addTarget(self, action: #selector(self.progressNextStep), for: .touchUpInside)
            self.videosLoadingAnimation.loopMode = .loop
            self.videosLoadingAnimation.play()
            self.showLoading {
                let manager = SocialMediaManager()
                manager.getYoutubeAccess(accessToken: user.googleApiAccessToken, callbacks: self, currentUser: user, tryRefresh: true)
            }
        } else {
            self.googleLayout.isHidden = false
            self.helpLayout.isHidden = false
            UIView.animate(withDuration: 0.5, animations: {
                self.googleLayout.alpha = 1
                self.showHelpLayout()
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                    self.loadingBlur.alpha = 0
                }, completion: { (finished: Bool) in
                    self.loginButton.addTarget(self, action: #selector(self.googleSignIn), for: .touchUpInside)
                })
            })
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.handlePostButton()
    }
    
    @objc private func handleMessageScope(sender: ScopeTapGesture){
        if(sender.button == "public" && currentMessageScope != "public"){
            self.currentMessageScope = "public"
            self.publicButton.backgroundColor = UIColor(named: "stayWhite")
            self.publicButton.layer.borderWidth = 1
            self.publicButton.layer.borderColor = UIColor(named: "greenToDarker")?.cgColor
            self.publicButtonLabel.textColor = UIColor(named: "greenToDarker")
            self.privateButton.backgroundColor = .lightGray
            self.privateButton.layer.borderWidth = 0
            self.privateButtonLabel.textColor = UIColor(named: "stayWhite")
        } else if(sender.button == "private" && currentMessageScope != "private"){
            self.currentMessageScope = "private"
            self.privateButton.backgroundColor = UIColor(named: "stayWhite")
            self.privateButton.layer.borderColor = UIColor(named: "greenToDarker")?.cgColor
            self.privateButton.layer.borderWidth = 1
            self.privateButtonLabel.textColor = UIColor(named: "greenToDarker")
            self.publicButton.backgroundColor = .lightGray
            self.publicButton.layer.borderWidth = 0
            self.publicButtonLabel.textColor = UIColor(named: "stayWhite")
        }
    }
    
    func showLoading(afterLoadingAction: @escaping () -> Void){
        if(self.googleLayout.alpha == 1 && self.helpLayout.alpha == 1){
            self.loadingBlur.isHidden = false
            self.loadingTitle.isHidden = true
            self.loadingSub.isHidden = true
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingBlur.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    afterLoadingAction()
                }
            })
        } else if(self.playerLoadingCover.alpha == 1){
            self.playerLoadingAnimation.loopMode = .loop
            self.playerLoadingAnimation.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                afterLoadingAction()
            }
        } else {
            self.playerLoadingCover.isHidden = false
            UIView.animate(withDuration: 0.8, animations: {
                self.playerLoadingCover.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.playerLoadingAnimation.loopMode = .loop
                    self.playerLoadingAnimation.play()
                }
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    afterLoadingAction()
                }
            })
        }
    }
    
    private func showEmptyLayout(){
        self.emptyLayout.isHidden = false
        self.helpLayout.isHidden = false
    }
    
    func onSignInComplete(result: GIDSignInResult?, didSignInFor user: GIDGoogleUser!, withError error: Error?){
        if let error = error {
            var buttons = [PopupDialogButton]()
            let title = "google login error."
            let message = "there was an error getting you logged into google. try again, or try registering using your email."
            
            let button = DefaultButton(title: "try again.") { [weak self] in
                self?.googleSignIn()
                
            }
            buttons.append(button)
            
            let buttonOne = CancelButton(title: "nevermind") { [weak self] in
                //do nothing
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
        if(user.userID != nil && !user.userID!.isEmpty){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.child("googleUserId").setValue(user.userID)
            if(!authentication.accessToken.tokenString.isEmpty){
                delegate.currentUser!.googleApiAccessToken = authentication.accessToken.tokenString
                delegate.currentUser!.googleApiRefreshToken = authentication.refreshToken.tokenString
                ref.child("googleApiAccessToken").setValue(authentication.accessToken.tokenString)
                ref.child("googleApiRefreshToken").setValue(authentication.refreshToken.tokenString)
                
                if(delegate.currentUser!.myPosts.isEmpty){
                    self.loadingTitle.text = "let's make your first post"
                }
                self.continueButton.addTarget(self, action: #selector(self.progressNextStep), for: .touchUpInside)
                self.loadingAnimation.loopMode = .loop
                self.loadingAnimation.play()
                self.videosLoadingAnimation.loopMode = .loop
                self.videosLoadingAnimation.play()
                
                let manager = SocialMediaManager()
                manager.getYoutubeAccess(accessToken: authentication.accessToken.tokenString, callbacks: self, currentUser: delegate.currentUser!, tryRefresh: true)
            }
        }
    }
    
    @objc private func googleSignIn(){
        showLoading {
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
        }
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
            //AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Youtube - Google Login Fail - " + "\(error?.localizedDescription ?? "")"))
            
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
        self.payload.append(contentsOf: videos)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if(self.googleLayout.alpha == 1){
                UIView.animate(withDuration: 0.5, animations: {
                    self.googleLayout.alpha = 0
                    self.helpLayout.alpha = 0
                }, completion: { (finished: Bool) in
                    
                })
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.selectionView.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.selectionView.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                        self.loadingBlur.alpha = 0
                    }, completion: { (finished: Bool) in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.hideLoading()
                            self.hideVideoLoading()
                        }
                    })
                })
                
                self.messageTextView.delegate = self
                
                let publicTap = ScopeTapGesture(target: self, action: #selector(self.handleMessageScope))
                publicTap.button = "public"
                self.publicButton.isUserInteractionEnabled = true
                self.publicButton.addGestureRecognizer(publicTap)
                
                let privateTap = ScopeTapGesture(target: self, action: #selector(self.handleMessageScope))
                privateTap.button = "private"
                self.privateButton.isUserInteractionEnabled = true
                self.privateButton.addGestureRecognizer(privateTap)
                
                let infoTap = UITapGestureRecognizer(target: self, action: #selector(self.showScopeInfoDialog))
                self.info.isUserInteractionEnabled = true
                self.info.addGestureRecognizer(infoTap)
                
                self.startButton.addTarget(self, action: #selector(self.stepBack), for: .touchUpInside)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                for game in delegate.gcGames {
                    if(delegate.currentUser!.games.contains(game.gameName)){
                        self.gamePayload.append(game)
                    }
                }
                
                if(self.payload.isEmpty){
                    self.showEmpty()
                    self.hideLoading()
                    self.hideVideoLoading()
                } else {
                    self.setPreviewVideo(video: videos[0])
                    
                    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
                    layout.itemSize = CGSizeMake(80, 80)
                    // Setting the space between cells
                    layout.minimumInteritemSpacing = 1
                    layout.minimumLineSpacing = 5
                    self.videoCarousel.collectionViewLayout = layout
                    self.videoCarousel.delegate = self
                    self.videoCarousel.dataSource = self
                    self.videoCarousel.reloadData()
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.selectionView.alpha = 1
                    }, completion: { (finished: Bool) in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.hideLoading()
                            self.hideVideoLoading()
                        }
                    })
                }
            }
        }
    }
    
    @objc func stepBack(){
        if(self.recipientView.alpha == 1){
            self.recipientView.alpha = 0
            self.selectionView.alpha = 1
            self.player.playVideo()
        }
    }
    
    private func setPreviewVideo(video: YoutubeVideoObj){
        self.currentSelection = video
        self.player = YTSwiftyPlayer(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.playerShell.bounds.height), playerVars: [
            //.mute(true),
            .playsInline(true),
            .videoID(video.youtubeId),
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
        self.playerShell.addSubview(player)
        player.pauseVideo()
        player.playVideo()
    }
    
    func onYoutubeFail() {
        
    }
    
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection]) {
        
    }
    
    private func showEmpty(){
        self.emptyAnimation.loopMode = .playOnce
        self.emptyAnimation.play()
        UIView.animate(withDuration: 0.5, animations: {
            self.emptyLayout.alpha = 1
            self.showHelpLayout()
        }, completion: { (finished: Bool) in
            self.selectionView.isHidden = true
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.clearAndClose))
            self.clearButton.isUserInteractionEnabled = true
            self.clearButton.addGestureRecognizer(singleTap)
        })
    }
    
    private func showHelpLayout(){
        self.helpLayout.alpha = 1
        
        let psTap = ConsoleTapGesture(target: self, action: #selector(self.showConsoleInstructions))
        psTap.console = "ps"
        self.psHelp.isUserInteractionEnabled = true
        self.psHelp.addGestureRecognizer(psTap)
        
        let xboxTap = ConsoleTapGesture(target: self, action: #selector(self.showConsoleInstructions))
        xboxTap.console = "xbox"
        self.xboxHelp.isUserInteractionEnabled = true
        self.xboxHelp.addGestureRecognizer(xboxTap)
        
        let nintendoTap = ConsoleTapGesture(target: self, action: #selector(self.showConsoleInstructions))
        nintendoTap.console = "nintendo"
        self.nintendoHelp.isUserInteractionEnabled = true
        self.nintendoHelp.addGestureRecognizer(nintendoTap)
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
        if(collectionView == self.videoCarousel){
            return self.payload.count
        } else {
            return self.gamePayload.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == self.videoCarousel){
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
            
            if(current.youtubeId == self.currentSelection?.youtubeId){
                cell.videoSelectedCover.isHidden = false
            } else {
                cell.videoSelectedCover.isHidden = true
            }
            
            cell.contentView.layer.cornerRadius = 15.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! CreatePostGameOption
            let current = gamePayload[indexPath.item]
            cell.option.text = current.gameName
            cell.coverOptionLabel.text = current.gameName
            
            if(self.selectedGame == current.gameName){
                cell.cover.alpha = 1
            } else {
                cell.cover.alpha = 0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == self.videoCarousel){
            return CGSize(width: 80, height: 80)
        } else {
            return CGSize(width: collectionView.frame.size.width - 40, height: 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.videoCarousel){
            let current = self.payload[indexPath.item]
            self.currentSelection = current
            self.videoCarousel.reloadData()
            showLoading {
                self.player.loadVideo(videoID: current.youtubeId)
                self.player.playVideo()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.hideLoading()
                }
            }
        } else {
            let current = self.gamePayload[indexPath.item]
            if(selectedGame == current.gameName){
                selectedGame = ""
            } else {
                selectedGame = current.gameName
            }
            self.gameChoiceCollection.reloadData()
        }
    }
    
    private func handlePostButton(){
        if(!self.selectedConsole.isEmpty && !self.messageTextView.text.isEmpty){
            self.previewButton.alpha = 1
            self.previewButton.isUserInteractionEnabled = true
        } else {
            self.previewButton.alpha = 0.3
            self.previewButton.isUserInteractionEnabled = false
        }
    }

    private func hideLoading(){
        UIView.animate(withDuration: 0.8, animations: {
            self.playerLoadingCover.alpha = 0
        }, completion: { (finished: Bool) in
            self.playerLoadingCover.isHidden = true
        })
    }
    
    private func hideVideoLoading(){
        UIView.animate(withDuration: 0.8, animations: {
            self.videosLoadingCover.alpha = 0
        }, completion: { (finished: Bool) in
            self.videosLoadingCover.isHidden = true
        })
    }
    
    @objc private func showConsoleInstructions(sender: ConsoleTapGesture){
        self.stepThreeLabel.text = "tap share, and select youtube."
       if(sender.console == "ps"){
            self.consoleInstructions.isHidden = false
           self.stepTwoView.isHidden = false
           self.stepThreeView.isHidden = false
            self.stepOneLabel.text = "press record button on left of touch pad, select record video."
            self.stepOneAnimation.loopMode = .repeat(3)
            UIView.animate(withDuration: 0.8, animations: {
                self.chooseConsoleTag.alpha = 0
                self.psHelp.alpha = 0
                self.xboxHelp.alpha = 0
                self.nintendoHelp.alpha = 0
                self.helpHeader.text = "connecting on playstation"
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
                    self.consoleInstructions.alpha = 1
                }, completion: { (finished: Bool) in
                    self.stepOneAnimation.play()
                    UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
                        self.stepTwoView.alpha = 1
                    }, completion: { (finished: Bool) in
                        self.stepTwoAnimation.loopMode = .playOnce
                        self.stepTwoAnimation.play(fromFrame: 0, toFrame: 68, completion: { Bool in
                            UIView.animate(withDuration: 0.8, animations: {
                                self.stepThreeView.alpha = 1
                            }, completion: { (finished: Bool) in
                                self.stepThreeAnimation.loopMode = .playOnce
                                self.stepThreeAnimation.play()
                            })
                        })
                    })
                })
            })
       } else if(sender.console == "xbox"){
            self.consoleInstructions.isHidden = false
           self.stepTwoView.isHidden = false
           self.stepThreeView.isHidden = false
            self.stepOneLabel.text = "press xbox button -> capture & share -> allow game captures -> 'Record what happened'."
            self.stepOneAnimation.loopMode = .repeat(3)
            UIView.animate(withDuration: 0.8, animations: {
                self.chooseConsoleTag.alpha = 0
                self.helpHeader.text = "connecting on your xbox"
                self.consoleInstructions.alpha = 1
            }, completion: { (finished: Bool) in
                self.stepOneAnimation.play()
                UIView.animate(withDuration: 0.8, animations: {
                    self.stepTwoView.alpha = 1
                }, completion: { (finished: Bool) in
                    self.stepTwoAnimation.loopMode = .playOnce
                    self.stepTwoAnimation.play(fromFrame: 0, toFrame: 68, completion: { Bool in
                        UIView.animate(withDuration: 0.8, animations: {
                            self.stepThreeView.alpha = 1
                        }, completion: { (finished: Bool) in
                            self.stepThreeAnimation.loopMode = .playOnce
                            self.stepThreeAnimation.play()
                        })
                    })
                })
            })
        } else {
            self.consoleInstructions.isHidden = false
            self.stepTwoView.isHidden = false
            self.stepThreeView.isHidden = false
            self.stepOneLabel.text = "i don't know how to do it on nintendo but we'll figure it out soon.....hopefully."
            self.stepOneAnimation.loopMode = .repeat(3)
            UIView.animate(withDuration: 0.8, animations: {
                self.chooseConsoleTag.alpha = 0
                self.helpHeader.text = "connecting on nintendo switch"
                self.consoleInstructions.alpha = 1
            }, completion: { (finished: Bool) in
                self.stepOneAnimation.play()
                UIView.animate(withDuration: 0.8, animations: {
                    self.stepTwoView.alpha = 1
                }, completion: { (finished: Bool) in
                    self.stepTwoAnimation.loopMode = .playOnce
                    self.stepTwoAnimation.play(fromFrame: 0, toFrame: 68, completion: { Bool in
                        UIView.animate(withDuration: 0.8, animations: {
                            self.stepThreeView.alpha = 1
                        }, completion: { (finished: Bool) in
                            self.stepThreeAnimation.loopMode = .playOnce
                            self.stepThreeAnimation.play()
                        })
                    })
                })
            })
        }
    }
    
    @objc private func progressNextStep(){
        self.gameChoiceCollection.delegate = self
        self.gameChoiceCollection.dataSource = self
        self.player.pauseVideo()
        self.selectionView.alpha = 0
        self.recipientView.alpha = 1
        let psTap = ConsoleTapGesture(target: self, action: #selector(self.selectConsoleForPost))
        psTap.console = "ps"
        self.psOption.isUserInteractionEnabled = true
        self.psOption.addGestureRecognizer(psTap)
        
        let xboxTap = ConsoleTapGesture(target: self, action: #selector(self.selectConsoleForPost))
        xboxTap.console = "xbox"
        self.xboxOption.isUserInteractionEnabled = true
        self.xboxOption.addGestureRecognizer(xboxTap)
        
        let mobileTap = ConsoleTapGesture(target: self, action: #selector(self.selectConsoleForPost))
        mobileTap.console = "mobile"
        self.mobileOption.isUserInteractionEnabled = true
        self.mobileOption.addGestureRecognizer(mobileTap)
        
        let pcTap = ConsoleTapGesture(target: self, action: #selector(self.selectConsoleForPost))
        pcTap.console = "pc"
        self.pcOption.isUserInteractionEnabled = true
        self.pcOption.addGestureRecognizer(pcTap)
        
        let tabletopTap = ConsoleTapGesture(target: self, action: #selector(self.selectConsoleForPost))
        tabletopTap.console = "nintendo"
        self.tabletopOption.isUserInteractionEnabled = true
        self.tabletopOption.addGestureRecognizer(tabletopTap)
        
        self.previewButton.addTarget(self, action: #selector(self.postVideo), for: .touchUpInside)
    }
    
    @objc private func selectConsoleForPost(sender: ConsoleTapGesture){
        if(sender.console == "ps"){
            self.selectedConsole = "ps"
            self.psOption.borderWidth = 1.5
            self.psOption.borderColor = .green
            self.xboxOption.borderWidth = 0
            self.xboxOption.borderColor = .clear
            self.tabletopOption.borderWidth = 0
            self.tabletopOption.borderColor = .clear
            self.pcOption.borderWidth = 0
            self.pcOption.borderColor = .clear
            self.mobileOption.borderWidth = 0
            self.mobileOption.borderColor = .clear
        } else if(sender.console == "xbox"){
            self.selectedConsole = "xbox"
            self.psOption.borderWidth = 0
            self.psOption.borderColor = .clear
            self.xboxOption.borderWidth = 1.5
            self.xboxOption.borderColor = .green
            self.tabletopOption.borderWidth = 0
            self.tabletopOption.borderColor = .clear
            self.pcOption.borderWidth = 0
            self.pcOption.borderColor = .clear
            self.mobileOption.borderWidth = 0
            self.mobileOption.borderColor = .clear
        } else if(sender.console == "pc"){
            self.selectedConsole = "pc"
            self.psOption.borderWidth = 0
            self.psOption.borderColor = .clear
            self.xboxOption.borderWidth = 0
            self.xboxOption.borderColor = .clear
            self.tabletopOption.borderWidth = 0
            self.tabletopOption.borderColor = .clear
            self.pcOption.borderWidth = 1.5
            self.pcOption.borderColor = .green
            self.mobileOption.borderWidth = 0
            self.mobileOption.borderColor = .clear
        } else if(sender.console == "nintendo"){
            self.selectedConsole = "nintendo"
            self.psOption.borderWidth = 0
            self.psOption.borderColor = .clear
            self.xboxOption.borderWidth = 0
            self.xboxOption.borderColor = .clear
            self.tabletopOption.borderWidth = 1.5
            self.tabletopOption.borderColor = .green
            self.pcOption.borderWidth = 0
            self.pcOption.borderColor = .clear
            self.mobileOption.borderWidth = 0
            self.mobileOption.borderColor = .clear
        } else {
            self.selectedConsole = "mobile"
            self.psOption.borderWidth = 0
            self.psOption.borderColor = .clear
            self.xboxOption.borderWidth = 0
            self.xboxOption.borderColor = .clear
            self.tabletopOption.borderWidth = 0
            self.tabletopOption.borderColor = .clear
            self.pcOption.borderWidth = 0
            self.pcOption.borderColor = .clear
            self.mobileOption.borderWidth = 1.5
            self.mobileOption.borderColor = .green
        }
        self.handlePostButton()
    }
    
    @objc func showScopeInfoDialog(){
        var buttons = [PopupDialogButton]()
        let title = "who do you want to see your posts?"
        let message = "public posts will be available for all to see. show the world how awesome you are. or keep it private, and only visible to you and whoever else you choose."
        
        let buttonOne = CancelButton(title: "ohhh. i gotcha.") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    @objc private func postVideo(){
        if(!self.messageTextView.text.isEmpty){
            self.loadingTitle.isHidden = true
            self.loadingSub.isHidden = true
            self.loadingTitle.text = "creating your post..."
            self.loadingSub.text = "your video is dope, by the way..."
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingBlur.alpha = 1
                self.loadingAnimation.play()
            }, completion: { (finished: Bool) in
                var showFirst = false
                if(self.currentSelection != nil){
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        var sendUp = [[String: Any]]()
                        let date = String(self.getCurrentMillis())
                        let postId = self.randomAlphaNumericString(length: 10)
                        let newVid = ["date": date, "postId": postId, "videoOwnerUid" : delegate.currentUser!.uId, "videoOwnerGamerTag" : delegate.currentUser!.gamerTag, "youtubeId": self.currentSelection!.youtubeId,
                                      "game": self.selectedGame ?? "", "youtubeImg": self.currentSelection!.youtubeImg, "publicPost": String(self.currentMessageScope == "public"), "postConsole": self.selectedConsole, "title": self.messageTextView.text] as [String : Any]
                        sendUp.append(newVid)
                        
                        if(!delegate.currentUser!.followers.isEmpty){
                            let videoHelper = VideoHelper()
                            for follower in delegate.currentUser!.followers {
                                videoHelper.addPostToFollowers(followerUid: follower.uid, postObj: newVid)
                            }
                        }
                        
                        let post = PostObject(postId: postId, title: self.messageTextView.text, videoOwnerGamerTag: delegate.currentUser!.gamerTag, videoOwnerUid: delegate.currentUser!.uId, publicPost: String(self.currentMessageScope == "public"), date: date, youtubeId: self.currentSelection!.youtubeId, imgUrl: self.currentSelection!.youtubeImg, postConsole: self.selectedConsole, game: self.selectedGame ?? "")
                        delegate.currentUser!.myPosts.append(post)
                        
                        let posts = snapshot.childSnapshot(forPath: "myPosts")
                        if(posts.exists()){
                            if(self.selectedGame != nil && !self.selectedGame!.isEmpty){
                                if(posts.hasChild(self.selectedGame!)){
                                    let gameRef = posts.childSnapshot(forPath: self.selectedGame!)
                                    for post in gameRef.children {
                                        let currentPost = post as? DataSnapshot
                                        if(currentPost != nil){
                                            let alreadyVid = ["date": currentPost!.childSnapshot(forPath: "date").value as? String ?? "", "postId": currentPost!.childSnapshot(forPath: "postId").value as? String ?? "", "videoOwnerGamerTag" : currentPost!.childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? "", "youtubeId": currentPost!.childSnapshot(forPath: "youtubeId").value as? String ?? "",
                                                              "game": currentPost!.childSnapshot(forPath: "game").value as? String ?? "", "youtubeImg": currentPost!.childSnapshot(forPath: "youtubeImg").value as? String ?? "", "publicPost": currentPost!.childSnapshot(forPath: "publicPost").value as? String ?? "", "postConsole": currentPost!.childSnapshot(forPath: "postConsole").value as? String ?? "", "title": currentPost!.childSnapshot(forPath: "title").value as? String ?? ""] as [String : Any]
                                            sendUp.append(alreadyVid)
                                        }
                                    }
                                    ref.child(self.selectedGame!).setValue(sendUp)
                                } else {
                                    ref.child(self.selectedGame!).setValue(sendUp)
                                }
                            } else {
                                if(posts.hasChild("other")){
                                    let otherRef = posts.childSnapshot(forPath: "other")
                                    for post in otherRef.children {
                                        let currentPost = post as? DataSnapshot
                                        if(currentPost != nil){
                                            let alreadyVid = ["date": currentPost!.childSnapshot(forPath: "date").value as? String ?? "", "postId": currentPost!.childSnapshot(forPath: "postId").value as? String ?? "", "videoOwnerGamerTag" : currentPost!.childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? "", "youtubeId": currentPost!.childSnapshot(forPath: "youtubeId").value as? String ?? "",
                                                              "game": currentPost!.childSnapshot(forPath: "game").value as? String ?? "", "youtubeImg": currentPost!.childSnapshot(forPath: "youtubeImg").value as? String ?? "", "publicPost": currentPost!.childSnapshot(forPath: "publicPost").value as? String ?? "", "postConsole": currentPost!.childSnapshot(forPath: "postConsole").value as? String ?? "", "title": currentPost!.childSnapshot(forPath: "title").value as? String ?? ""] as [String : Any]
                                            sendUp.append(alreadyVid)
                                        }
                                    }
                                    ref.child("other").setValue(sendUp)
                                } else {
                                    ref.child("other").setValue(sendUp)
                                }
                            }
                        } else {
                            if(self.selectedGame != nil && !self.selectedGame!.isEmpty){
                                ref.child("myPosts").child(self.selectedGame!).setValue(sendUp)
                            } else {
                                ref.child("myPosts").child("other").setValue(sendUp)
                            }
                            showFirst = true
                        }
                        
                        if(self.currentMessageScope == "public"){
                            var saveDestination = "other"
                            if(self.selectedGame != nil && !self.selectedGame!.isEmpty){
                                saveDestination = self.selectedGame!
                            }
                            
                            let ref = Database.database().reference().child("Public Posts").child(saveDestination)
                            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                                var sendUp = [[String: Any]]()
                                let date = String(CACurrentMediaTime().truncatingRemainder(dividingBy: 1))
                                let postId = self.randomAlphaNumericString(length: 10)
                                let newVid = ["date": date, "postId": postId, "videoOwnerUid" : delegate.currentUser!.uId, "videoOwnerGamerTag" : delegate.currentUser!.gamerTag, "youtubeId": self.currentSelection!.youtubeId,
                                              "game": self.selectedGame ?? "", "youtubeImg": self.currentSelection!.youtubeImg, "publicPost": String(self.currentMessageScope == "public"), "postConsole": self.selectedConsole, "title": self.messageTextView.text] as [String : Any]
                                sendUp.append(newVid)
                                
                                if(snapshot.exists()){
                                    for post in snapshot.children {
                                        let currentPost = post as? DataSnapshot
                                        if(currentPost != nil){
                                            let alreadyVid = ["date": currentPost!.childSnapshot(forPath: "date").value as? String ?? "", "postId": currentPost!.childSnapshot(forPath: "postId").value as? String ?? "", "videoOwnerGamerTag" : currentPost!.childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? "", "youtubeId": currentPost!.childSnapshot(forPath: "youtubeId").value as? String ?? "",
                                                              "game": currentPost!.childSnapshot(forPath: "game").value as? String ?? "", "youtubeImg": currentPost!.childSnapshot(forPath: "youtubeImg").value as? String ?? "", "publicPost": currentPost!.childSnapshot(forPath: "publicPost").value as? String ?? "", "postConsole": currentPost!.childSnapshot(forPath: "postConsole").value as? String ?? "", "title": currentPost!.childSnapshot(forPath: "title").value as? String ?? ""] as [String : Any]
                                            sendUp.append(alreadyVid)
                                        }
                                    }
                                    ref.setValue(sendUp)
                                } else {
                                    ref.setValue(sendUp)
                                }
                            })
                        }
                        
                        if(showFirst){
                            UIView.animate(withDuration: 0.8, animations: {
                                self.firstPostFinishBlur.alpha = 1
                            }, completion: { (finished: Bool) in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.firstFinishAnimation.play()
                                    UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
                                        self.firstPostHeader.alpha = 1
                                    }, completion: { (finished: Bool) in
                                        UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
                                            self.firstPostSub.alpha = 1
                                        }, completion: { (finished: Bool) in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                self.dismiss(animated: true)
                                            }
                                        })
                                    })
                                }
                            })
                        } else {
                            self.dismiss(animated: true)
                        }
                    })
                }
            })
        }
        
    }
    
    private func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(UInt32(allowedChars.count)))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
    
    private func getCurrentMillis()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}

class ScopeTapGesture: UITapGestureRecognizer {
    var button: String?
}

class ConsoleTapGesture: UITapGestureRecognizer {
    var console: String?
}
