//
//  Profile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import UnderLineTextField
import SPStorkController
import moa
import Firebase

class ProfileFrag: ParentVC, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, SPStorkControllerDelegate{
    @IBOutlet weak var editProfileTable: UITableView!
    
    var gcGames = [GamerConnectGame]()
    var gamesPlayed = [GamerConnectGame]()
    var payload = [String]()
    var bioIndexPath: IndexPath?
    var consoleIndexPath: IndexPath?
    var gamesIndexPath: IndexPath?
    var currentProfilePayload = [[String: String]]()
    var drawerOpen = false
    var drawerHeight: CGFloat!
    var selectedTag = ""
    
    var drawerSwitches = [UISwitch]()
    var addedName = ""
    var addedIndex: IndexPath!
    var removedName = ""
    var removedIndex: IndexPath!
    var statsAvailable = false
    var quizAvailable = false
    var cachedUidFromProfile = ""
    var uniqueTags = [String]()
    var currentAvatarImg = ""
    var currentInsta = ""
    var currentTwitch = ""
    var currentUser: User?
    var editBioProfile = false
    
    var bio = "update your profile"
    var ps: Bool!
    var xbox: Bool!
    var pc: Bool!
    var nintendo: Bool!
    
    var chosenConsole = ""
    var avatarUrl = ""
    var consoleChecked = false
    var instaEditing = false
    var basicCell: EditProfileBasicCell?
    var basicBioCell: EditProfileBioCell?
    var showBioCover = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentEditProfile = self
        gcGames = appDelegate.gcGames
        self.selectedTag = self.currentUser!.gamerTag
        self.showBioCover = self.currentUser!.bio.isEmpty
        
        for profile in currentUser!.gamerTags{
            if(!self.uniqueTags.contains(profile.gamerTag)){
                self.uniqueTags.append(profile.gamerTag)
            }
            let current = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console]
            currentProfilePayload.append(current)
        }
        
        for game in gcGames{
            if(currentUser!.games.contains(game.gameName)){
                gamesPlayed.append(game)
            }
        }
        
        let games = currentUser!.games
        for game in appDelegate.gcGames {
            if(!game.quizUrl.isEmpty && games.contains(game.gameName)){
                self.quizAvailable = true
                break
            }
        }
        setup()
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "User Profile"))
    }
    
    private func setup(){
        self.payload = [String]()
        //payload.append("avatar")
        self.payload.append("basic")
        self.payload.append("bio")
        self.payload.append("search")
        self.payload.append("youtube")
        self.payload.append("social")

        self.bio = self.currentUser!.bio
        
        editProfileTable.dataSource = self
        editProfileTable.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    @objc func instaTextFieldDidChange(_ textField: UITextField) {
        if(!self.currentInsta.isEmpty && textField.text!.isEmpty){
            self.instaEditing = textField.isEditing
            self.currentInsta = textField.text ?? ""
            self.editProfileTable.reloadData()
            return
        } else if(self.currentInsta.isEmpty && !textField.text!.isEmpty) {
            self.instaEditing = textField.isEditing
            self.currentInsta = textField.text ?? ""
            self.editProfileTable.reloadData()
            return
        }
        self.instaEditing = textField.isEditing
        self.currentInsta = textField.text ?? ""
    }
    
    @objc func twitchTextFieldDidChange(_ textField: UITextField) {
        self.currentTwitch = textField.text ?? ""
        self.editProfileTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        if(current == "avatar"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "avatar", for: indexPath) as! EditProfileAvatarCell
            if(!self.currentAvatarImg.isEmpty){
                cell.avatarImg.isHidden = false
                cell.avatarImg.downloaded(from: self.currentAvatarImg)
            } else {
                cell.avatarImg.isHidden = true
            }
            let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.launchAvatar))
            cell.button.isUserInteractionEnabled = true
            cell.button.addGestureRecognizer(avatarTap)
            return cell
        } else if(current == "bio"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "bio", for: indexPath) as! EditProfileBioCell
            self.basicBioCell = cell
            cell.bioTV.text = self.bio
            cell.bioTV.delegate = self
            
            if(self.showBioCover){
                self.showBioCover = true
                cell.bioCover.isHidden = false
                
                let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.handleBioCover))
                cell.bioCover.isUserInteractionEnabled = true
                cell.bioCover.addGestureRecognizer(avatarTap)
            } else {
                self.showBioCover = false
                cell.bioCover.isHidden = true
            }
            cell.bioTV.delegate = self
            return cell
        } else if(current == "basic"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath) as! EditProfileBasicCell
            self.basicCell = cell
            if(cell.gamertagField.text!.count > 0){
                cell.gamertagSaveButton.alpha = 1.0
            } else {
                let attrString = NSAttributedString(string: self.currentUser!.gamerTag, attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray])
                cell.gamertagField.attributedPlaceholder = attrString
                cell.gamertagField.addTarget(self, action: #selector(gamerTageTextFieldDidChange), for: UIControl.Event.editingChanged)
                cell.gamertagSaveButton.alpha = 0.3
            }
            let gamesTap = UITapGestureRecognizer(target: self, action: #selector(self.launchGames))
            cell.manageGamesButton.isUserInteractionEnabled = true
            cell.manageGamesButton.addGestureRecognizer(gamesTap)
            return cell
        } else if(current == "search"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! EditProfileSearchCell
            let lookingTap = UITapGestureRecognizer(target: self, action: #selector(launchLookingFor))
            cell.lookingForButton.isUserInteractionEnabled = true
            cell.lookingForButton.addGestureRecognizer(lookingTap)
            
            if(self.currentUser!.search == "true"){
                cell.searchActiveButton.backgroundColor = .systemGreen
                cell.enabledText.text = "enabled"
            } else {
                cell.searchActiveButton.backgroundColor = .systemRed
                cell.enabledText.text = "disabled"
            }
            let enabledTap = UITapGestureRecognizer(target: self, action: #selector(updateSearch))
            cell.searchActiveButton.isUserInteractionEnabled = true
            cell.searchActiveButton.addGestureRecognizer(enabledTap)
            
            return cell
        } else if(current == "youtube"){
            let cell = tableView.dequeueReusableCell(withIdentifier: "youtube", for: indexPath) as! EditProfileYoutubeCell
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if(!self.currentUser!.googleApiAccessToken.isEmpty){
                cell.connectBlur.isHidden = true
                if(!self.currentUser!.youtubeVideos.isEmpty){
                    for video in self.currentUser!.youtubeVideos {
                        if(video.youtubeFavorite == "true"){
                            cell.xIcon.isHidden = true
                            cell.noVideoLabel.isHidden = true
                            
                            let cache = appDelegate.imageCache
                            if(cache.object(forKey: video.youtubeImg as NSString) != nil){
                                cell.headerVideoImg.image = cache.object(forKey: video.youtubeImg as NSString)
                            } else {
                                cell.headerVideoImg.moa.onSuccess = { image in
                                    cell.headerVideoImg.image = image
                                    appDelegate.imageCache.setObject(image, forKey: video.youtubeImg as NSString)
                                    return image
                                }
                                cell.headerVideoImg.moa.url = video.youtubeImg
                            }
                            break
                        }
                    }
                    let manageTap = UITapGestureRecognizer(target: self, action: #selector(self.manageYoutube))
                    cell.manageButton.isUserInteractionEnabled = true
                    cell.manageButton.addGestureRecognizer(manageTap)
                } else {
                    cell.xIcon.isHidden = false
                    cell.noVideoLabel.isHidden = false
                    cell.headerVideoImg.isHidden = true
                    cell.manageButton.isUserInteractionEnabled = false
                }
            } else {
                cell.connectBlur.isHidden = false
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "social", for: indexPath) as! EditProfileSocialCell
            if(!self.currentUser!.instagramConnect.isEmpty){
                if(!currentInsta.isEmpty){
                    cell.instagramField.text = currentInsta
                } else {
                    let attrString = NSAttributedString(string: self.currentUser!.instagramConnect, attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray])
                    cell.instagramField.attributedPlaceholder = attrString
                }
            } else {
                let attrString = NSAttributedString(string: "@yourname", attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray])
                cell.instagramField.attributedPlaceholder = attrString
            }
            if(!cell.instagramField.text!.isEmpty == true) {
                cell.instagramSave.alpha = 1
            } else {
                cell.instagramSave.alpha = 0.3
            }
            if(self.instaEditing){
                cell.instagramField.becomeFirstResponder()
            }
            
            if(!self.currentUser!.twitchConnect.isEmpty){
                if(!currentTwitch.isEmpty){
                    cell.twitchField.text = currentTwitch
                } else {
                    let attrString = NSAttributedString(string: self.currentUser!.twitchConnect, attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray])
                    cell.twitchField.attributedPlaceholder = attrString
                }
            } else {
                let attrString = NSAttributedString(string: "@yourname", attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray])
                cell.twitchField.attributedPlaceholder = attrString
            }
            if(cell.twitchField.text?.isEmpty == true) {
                cell.twitchSave.alpha = 0.3
            } else {
                cell.twitchSave.alpha = 1
            }
            cell.instagramField.addTarget(self, action: #selector(instaTextFieldDidChange(_:)), for: .editingChanged)
            cell.instagramField.delegate = self
            cell.twitchField.addTarget(self, action: #selector(twitchTextFieldDidChange(_:)), for: .editingChanged)
            return cell
        }
    }
    
    @objc private func manageYoutube(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "youtube") as! YoutubeConnect
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.profileUser = self.currentUser!
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchGames(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gameSelection") as! GameSelection
        currentViewController.returning = true
        currentViewController.modalPopped = true
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.textColor == UIColor.lightGray {
            textField.text = nil
            textField.textColor = UIColor(named: "darkToWhite")
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            var placeholder = ""
            if(!self.bio.isEmpty){
                placeholder = self.bio
            } else {
                placeholder = "insert a quick bio"
            }
            textField.text = placeholder
            textField.textColor = UIColor.lightGray
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func bioTapped(){
        if(!self.editBioProfile){
            self.editBioProfile = true
        } else {
            self.editBioProfile = false
        }
        self.editProfileTable.reloadData()
    }
    
    @objc private func updateSearch(){
        if(self.currentUser!.search == "true"){
            self.currentUser!.search = "false"
            self.editProfileTable.reloadData()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
            ref.child("searchActive").setValue("false")
            appDelegate.currentUser!.search = "false"
        } else {
            self.currentUser!.search = "true"
            self.editProfileTable.reloadData()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
            ref.child("searchActive").setValue("true")
            appDelegate.currentUser!.search = "true"
        }
    }
    
    @objc private func handleBioCover(){
        self.showBioCover = !self.showBioCover
        self.editProfileTable.reloadData()
    }
    
    @objc func cancelButtonClicked(_ sender: AnyObject?) {
        if(!self.cachedUidFromProfile.isEmpty){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentProfileFrag?.dismissModal()
            self.dismiss(animated: true, completion: nil)
            return
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentLanding!.navigateToHome()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if (segue.identifier == "return") {
            if let destination = segue.destination as? PlayerProfile {
                destination.uid = self.cachedUidFromProfile
            }
        }
    }
    
    @objc private func launchLookingFor(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "looking") as! LookingFor
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.usersSelected = delegate.currentUser!.userLookingFor
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc func launchAvatar(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "avatar") as! AvatarViewController
        
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
    
    func updateAvatar(url: String){
        let start = url.index(url.startIndex, offsetBy: 30)
        let end = url.index(url.endIndex, offsetBy: 0)
        let range = start..<end

        let mySubstring = url[range]
        let twoDee = mySubstring.replacingOccurrences(of: ".glb", with: ".png", options: .literal, range: nil)
        let fullUrl = "https://models.readyplayer.me/" + twoDee
        
        self.avatarUrl = fullUrl
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        let userRef = Database.database().reference().child("Users").child(currentUser!.uId)
        userRef.child("avatarUrl").setValue(fullUrl)
        
        //self.editProfileTable.beginUpdates()
        //self.editProfileTable.reloadSections(NSIndexSet(index: 0) as IndexSet, with: UITableView.RowAnimation.none)
        //self.editProfileTable.endUpdates()
        self.currentAvatarImg = url
        let url = URL(string: url)!
        
        self.editProfileTable.reloadData()
    }
    
    func textViewDidChange(_ textView: UITextView) { //Handle the text changes here
        if(textView == self.basicBioCell?.bioTV){
            if(textView.text?.count ?? 0 > 1){
                self.basicBioCell?.saveButton.alpha = 1.0
                self.basicBioCell?.bioCover.isHidden = true
                //self.editProfileTable.reloadData()
            } else if(textView.text?.count == 0){
                self.basicBioCell?.saveButton.alpha = 0.3
                self.basicBioCell?.bioCover.isHidden = false
            }
        }
    }
    
    @objc func bioTextFieldDidChange(_ textField: UITextField) {
        if(textField.text?.count ?? 0 > 1){
            self.basicBioCell?.saveButton.alpha = 1.0
            self.basicBioCell?.bioCover.isHidden = true
            //self.editProfileTable.reloadData()
        } else if(textField.text?.count == 0){
            self.basicBioCell?.saveButton.alpha = 0.3
            self.basicBioCell?.bioCover.isHidden = false
        }
    }
    
    @objc func gamerTageTextFieldDidChange(_ textField: UITextField) {
        if(textField.text?.count ?? 0 > 1){
            self.basicCell?.gamertagSaveButton.alpha = 1.0
            //self.editProfileTable.reloadData()
        } else if(textField.text?.count == 0){
            self.basicCell?.gamertagSaveButton.alpha = 0.3
        }
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
