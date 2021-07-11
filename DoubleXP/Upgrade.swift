//
//  Upgrade.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog
import FirebaseDatabase
import SwiftNotificationCenter
import SPStorkController
import Lottie

class Upgrade: UIViewController, UITableViewDelegate, UITableViewDataSource, StatsManagerCallbacks, SPStorkControllerDelegate {
    var extra = ""
    var payload = [GamerConnectGame: GamerProfile]()
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var header: UILabel!
    //@IBOutlet weak var sub: UILabel!
    @IBOutlet weak var lookingForButton: UIButton!
    @IBOutlet weak var animation: AnimationView!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var quizQuestion: UIImageView!
    @IBOutlet weak var addGamesButton: UIButton!
    var currentGameName = ""
    
    override func viewDidLoad() {
        if(extra.isEmpty){
            return
        }
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentUpgradeController = self
        self.updateButton.addTarget(self, action: #selector(launchUpdate), for: .touchUpInside)
        self.lookingForButton.addTarget(self, action: #selector(launchLookingFor), for: .touchUpInside)
        self.addGamesButton.addTarget(self, action: #selector(launchGames), for: .touchUpInside)
        
        if(delegate.currentUser!.userLookingFor.isEmpty){
            self.lookingForButton.setTitle("tell us what you're looking for", for: .normal)
            self.lookingForButton.borderColor = UIColor.init(named: "greenToDarker")
        } else {
            self.lookingForButton.setTitle("update what you're looking for", for: .normal)
            self.lookingForButton.borderColor = UIColor.init(named: "dark")
        }
        
        if(delegate.currentUser!.userAbout.isEmpty){
            self.updateButton.setTitle("tell us about you", for: .normal)
            self.updateButton.borderColor = UIColor.init(named: "greenToDarker")
        } else {
            self.updateButton.setTitle("update us about you", for: .normal)
            self.updateButton.borderColor = UIColor.init(named: "dark")
        }
        
        let whyTap = UITapGestureRecognizer(target: self, action: #selector(self.showWhyQuiz))
        self.quizQuestion.isUserInteractionEnabled = true
        self.quizQuestion.addGestureRecognizer(whyTap)
        /*if(extra == "stats"){
            let profiles = delegate.currentUser!.gamerTags
            for profile in profiles {
                for game in delegate.gcGames {
                    if(game.statsAvailable && profile.game == game.gameName){
                        payload[game] = profile
                    }
                }
            }
            let aniation = Animation.named("stats_ios")
            self.animation.animation = aniation
            self.animation.loopMode = .playOnce
            
            self.header.text = "import stats"
            self.sub.text = "import your stats from the games below and let everyone know good you are."
        }*/
        if(extra == "quiz"){
            let profiles = delegate.currentUser!.gamerTags
            for profile in profiles {
                for game in delegate.gcGames {
                    if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                        payload[game] = profile
                    }
                }
            }
            self.header.text = "build your gamer profile"
            //self.sub.text = "everybody is different."
            animation.loopMode = .loop
        }
        table.delegate = self
        table.dataSource = self
        table.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showView()
        }
    }
    
    private func showView(){
        animation.play()
        let top = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.5, animations: {
            self.table.transform = top
            self.table.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                if self.traitCollection.userInterfaceStyle == .light {
                    self.animation.alpha = 0.4
                    } else {
                        self.animation.alpha = 0.2
                    }
                self.animation.transform = top
            }, completion: nil)
        })
    }
    
    func dismissModal(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.payload = [GamerConnectGame: GamerProfile]()
        let profiles = delegate.currentUser!.gamerTags
        for profile in profiles {
            for game in delegate.gcGames {
                if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                    payload[game] = profile
                }
            }
        }
        
        self.table.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    @objc private func launchGames(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gameSelection") as! GameSelection
        currentViewController.returning = true
        currentViewController.modalPopped = true
        currentViewController.upgradeFrag = self
        
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
    
    @objc private func showWhyQuiz(){
        let title = "the gameplay quiz"
        let message = "we use the answers you provide to help other users find you, and to help us develop more and more ways to connect you to other users.\n\n not seeing the game you want to take a quiz for?\n\n we use the games you add to your profile to determine which ones to show. just add it to your games!"

        let popup = PopupDialog(title: title, message: message)
        let buttonOne = CancelButton(title: "ohhhhhhhh.") {
            print("dang it.")
        }
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.titleTextAlignment = .center
        dialogAppearance.titleFont = .boldSystemFont(ofSize: 22)
        dialogAppearance.messageTextAlignment = .center

        popup.addButtons([buttonOne])//, buttonTwo, buttonThree])
        self.present(popup, animated: true, completion: nil)
    }
    
    @objc private func launchUpdate(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "aboutYou") as! AboutYouDrawer
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.usersSelected = delegate.currentUser!.userAbout
        currentViewController.upgrade = self
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func launchLookingFor(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "looking") as! LookingFor
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.usersSelected = delegate.currentUser!.userLookingFor
        currentViewController.upgrade = self
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func updateButtons(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLookingFor.isEmpty){
            self.lookingForButton.setTitle("tell us what you're looking for", for: .normal)
            self.lookingForButton.borderColor = UIColor.init(named: "greenToDarker")
        } else {
            self.lookingForButton.setTitle("update what you're looking for", for: .normal)
            self.lookingForButton.borderColor = UIColor.init(named: "dark")
        }
        
        if(delegate.currentUser!.userAbout.isEmpty){
            self.updateButton.setTitle("tell us about you", for: .normal)
            self.updateButton.borderColor = UIColor.init(named: "greenToDarker")
        } else {
            self.updateButton.titleLabel?.text = "update us about you"
            self.updateButton.borderColor = UIColor.init(named: "dark")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! UpgradeCell
        let current = Array(payload.keys)[indexPath.item]
        cell.gameName.text = current.gameName
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: current.imageUrl as NSString) != nil){
            cell.gameBack.image = cache.object(forKey: current.imageUrl as NSString)
        } else {
            cell.gameBack.image = Utility.Image.placeholder
            cell.gameBack.moa.onSuccess = { image in
                cell.gameBack.image = image
                appDelegate.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                return image
            }
            cell.gameBack.moa.url = current.imageUrl
        }
        
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        if(self.extra != "stats"){
            cell.statsButton.alpha = 0
            
            let removeTap = UpgradeCellTapGesture(target: self, action: #selector(removeQuiz))
            removeTap.game = current
            cell.isUserInteractionEnabled = true
            cell.remove.addGestureRecognizer(removeTap)
        } else {
            cell.statsButton.alpha = 1
            
            let cellTap = UpgradeCellTapGesture(target: self, action: #selector(importStats))
            cellTap.game = current
            cell.isUserInteractionEnabled = true
            cell.statsButton.addGestureRecognizer(cellTap)
            
            let removeTap = UpgradeCellTapGesture(target: self, action: #selector(removeStats))
            removeTap.game = current
            cell.isUserInteractionEnabled = true
            cell.remove.addGestureRecognizer(removeTap)
        }
        
        let currentProfile = payload[current]
        if(currentProfile?.console == "ps"){
            cell.console.text = "PlayStation"
        }
        if(currentProfile?.console == "xbox"){
            cell.console.text = "xBox"
        }
        if(currentProfile?.console == "pc"){
            cell.console.text = "PC"
        }
        if(currentProfile?.console == "nintendo"){
            cell.console.text = "Nintendo"
        }
        if(currentProfile?.console == "mobile"){
            cell.console.text = "Mobile"
        }
        
        let currentUser = appDelegate.currentUser!
        if(extra == "stats"){
            var contained = false
            if(currentUser.stats.isEmpty){
                cell.cover.alpha = 0
            } else {
                for stat in currentUser.stats {
                    if(current.gameName == stat.gameName){
                        contained = true
                        break
                    }
                }
                if(contained){
                    cell.cover.alpha = 1
                } else {
                    cell.cover.alpha = 0
                }
            }
        } else {
            if(currentUser.gamerTags.isEmpty){
                cell.cover.alpha = 0
            } else {
                for tag in currentUser.gamerTags {
                    if(tag.game == current.gameName){
                        if(tag.quizTaken == "true"){
                            cell.cover.alpha = 1
                        } else {
                            cell.cover.alpha = 0
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //add popup if multiple consoles
        let current = Array(payload.keys)[indexPath.item]
        self.currentGameName = current.gameName
        if(self.extra == "quiz"){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faQuiz") as! FAQuiz
            currentViewController.pageName = "FA Quiz"
            
            var chosenGame: GamerConnectGame?
            for game in appDelegate.gcGames {
                if(game.gameName == self.currentGameName){
                    chosenGame = game
                }
            }
            if(chosenGame != nil){
                let interviewManager = appDelegate.interviewManager
                interviewManager.currentGCGame = chosenGame
                currentViewController.gcGame = chosenGame!
                currentViewController.user = appDelegate.currentUser!
                
                appDelegate.interviewManager.currentGCGame = chosenGame
                appDelegate.currentFrag = currentViewController.pageName ?? "FA Quiz"
                
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
        }
    }
    
    @objc func didDismissStorkBySwipe(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.payload = [GamerConnectGame: GamerProfile]()
        let profiles = delegate.currentUser!.gamerTags
        for profile in profiles {
            for game in delegate.gcGames {
                if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                    payload[game] = profile
                }
            }
        }
        
        self.table.reloadData()
    }
    
    @objc func didDismissStorkByTap() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.payload = [GamerConnectGame: GamerProfile]()
        let profiles = delegate.currentUser!.gamerTags
        for profile in profiles {
            for game in delegate.gcGames {
                if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                    payload[game] = profile
                }
            }
        }
        
        self.table.reloadData()
    }
    
    @objc private func importStats(sender: UpgradeCellTapGesture){
        let currentProfile = payload[sender.game]!
        let manager = StatsManager()
        manager.getStats(callbacks: self, gameName: currentProfile.game, console: currentProfile.console, gamerTag: currentProfile.gamerTag)
    }
    
    @objc private func removeStats(sender: UpgradeCellTapGesture){
        let currentProfile = payload[sender.game]!
        let manager = StatsManager()
        manager.removeStatsForGame(gamename: currentProfile.game)
    }
    
    @objc private func removeQuiz(sender: UpgradeCellTapGesture){
        let currentProfile = payload[sender.game]!
        //remove local
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for profile in delegate.currentUser!.gamerTags {
            if(profile.game == currentProfile.game){
                profile.quizTaken = "false"
                break
            }
        }
        //remove online GT
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var gamerTags = [GamerProfile]()
                if(snapshot.hasChild("gamerTags")){
                    let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        if(currentProfile.game == currentGame){
                            if(dict?["filterQuestions"] as? [[String: Any]] != nil){
                                ref.child("gamerTags").child(currentObj.key).child("filterQuestions").removeValue()
                            }
                        }
                        
                        if(currentTag != "" && currentGame != "" && console != ""){
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                    }
                    for tag in gamerTags {
                        if(tag.game == currentProfile.game){
                            tag.quizTaken = "false"
                            tag.filterQuestions = [[String: Any]]()
                            break
                        }
                    }
                    var sendUp = [[String: String]]()
                    for profile in gamerTags {
                        let currentProfile = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console, "quizTaken": "false"]
                        sendUp.append(currentProfile)
                    }
                    ref.child("gamerTags").setValue(sendUp)
                    
                    self.removeFAQuiz(game: currentProfile.game)
                }
            } else {
                self.onFailure(gameName: currentProfile.game)
            }
        })
    }
    
    private func removeFAQuiz(game: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Free Agents V2").child(delegate.currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for profile in snapshot.children {
                    let currentObj = profile as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    if(currentObj.hasChild("game")){
                        let gameName = currentObj.childSnapshot(forPath: "game").value as? String ?? ""
                        if(gameName == game){
                            ref.child(currentObj.key).removeValue()
                            self.onSuccess(gameName: game)
                        }
                    }
                }
            } else {
                self.onFailure(gameName: game)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(120)
    }
    
    func onSuccess(gameName: String) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.payload = [GamerConnectGame: GamerProfile]()
        let profiles = delegate.currentUser!.gamerTags
        for profile in profiles {
            for game in delegate.gcGames {
                if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                    payload[game] = profile
                }
            }
        }
        
        self.table.reloadData()
    }
    
    func onFailure(gameName: String) {
        showError(gameName: gameName)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.payload = [GamerConnectGame: GamerProfile]()
        let profiles = delegate.currentUser!.gamerTags
        for profile in profiles {
            for game in delegate.gcGames {
                if(!game.quizUrl.isEmpty && profile.game == game.gameName){
                    payload[game] = profile
                }
            }
        }
        
        self.table.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "quiz"){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            var chosenGame: GamerConnectGame?
            for game in delegate.gcGames {
                if(game.gameName == self.currentGameName){
                    chosenGame = game
                }
            }
            if(chosenGame != nil){
                let interviewManager = delegate.interviewManager
                interviewManager.currentGCGame = chosenGame
                
                let svc = segue.destination as! FAQuiz
                svc.gcGame = chosenGame!
                svc.user = delegate.currentUser!
            }
        }
    }
    
    private func showError(gameName: String){
        let title = "error"
        let message = "sorry, there was an issue getting the stats for "+gameName

        let popup = PopupDialog(title: title, message: message)
        let buttonOne = CancelButton(title: "cancel.") {
            print("dang it.")
        }

        // This button will not the dismiss the dialog
        let buttonTwo = DefaultButton(title: "ADMIRE CAR", dismissOnTap: false) {
            print("What a beauty!")
        }

        let buttonThree = DefaultButton(title: "BUY CAR", height: 60) {
            print("Ah, maybe next time :)")
        }
        popup.addButtons([buttonOne])//, buttonTwo, buttonThree])
        self.present(popup, animated: true, completion: nil)
    }
}

protocol ModalHandler {
  func handleModalDismissed()
}

class UpgradeCellTapGesture: UITapGestureRecognizer {
    var game: GamerConnectGame!
}

extension UIViewController: UIAdaptivePresentationControllerDelegate {
        public func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
            if #available(iOS 13, *) {
                //Call viewWillAppear only in iOS 13
                viewWillAppear(true)
            }
        }
    }
