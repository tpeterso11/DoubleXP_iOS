//
//  PlayDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/2/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class PlayDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, RequestsUpdate {
    
    @IBOutlet weak var notificationAnim: AnimationView!
    @IBOutlet weak var gotItButton: UIButton!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var selectionHeader: UIView!
    @IBOutlet weak var selectionTable: UITableView!
    @IBOutlet weak var selectionContinue: UIButton!
    @IBOutlet weak var timeHeader: UILabel!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var timeLayout: UIView!
    @IBOutlet weak var gameLayout: UIView!
    @IBOutlet weak var mainLayout: UIView!
    @IBOutlet weak var editGame: UIView!
    @IBOutlet weak var editTime: UIView!
    @IBOutlet weak var editGameLabel: UILabel!
    @IBOutlet weak var editTimeLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var confirmationView: UIView!
    @IBOutlet weak var sendingOverlay: UIView!
    @IBOutlet weak var sendingAnimation: AnimationView!
    @IBOutlet weak var doneView: UIView!
    @IBOutlet weak var whatsnext: UIView!
    @IBOutlet weak var doneButton: UIView!
    @IBOutlet weak var errorView: UIView!
    var gamesPayload = [GamerConnectGame]()
    var selectedGame = "anything"
    var timePayload = [String]()
    var selectedTime = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showAbout()
        
        self.doneButton.layer.shadowColor = UIColor.black.cgColor
        self.doneButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.doneButton.layer.shadowRadius = 2.0
        self.doneButton.layer.shadowOpacity = 0.5
        self.doneButton.layer.masksToBounds = false
        self.doneButton.layer.shadowPath = UIBezierPath(roundedRect: self.doneButton.bounds, cornerRadius: self.whatsnext.layer.cornerRadius).cgPath
    }
    
    private func showAbout(){
        self.gotItButton.addTarget(self, action: #selector(transitionToGames), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.8, delay: 0.3, options: [], animations: {
            self.mainLayout.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.header.alpha = 1
                self.gotItButton.alpha = 1
                self.notificationAnim.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.notificationAnim.loopMode = .playOnce
                    self.notificationAnim.play()
                }
            })
        })
    }
    
    @objc private func transitionToGames(){
        gamesPayload = [GamerConnectGame]()
        if(self.selectedTime == ""){
            self.selectionContinue.addTarget(self, action: #selector(transitionToTime), for: .touchUpInside)
        } else {
            self.selectionContinue.addTarget(self, action: #selector(transitionToConfirm), for: .touchUpInside)
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.profileManager
        let currentUser = appDelegate.currentUser!
        
        if(manager.wannaPlayCachedUser != nil){
            for profile in manager.wannaPlayCachedUser!.gamerTags {
                if(currentUser.games.contains(profile.game)){
                    let game = getGCGame(profile: profile)
                    if(game != nil){
                        gamesPayload.append(getGCGame(profile: profile)!)
                    }
                }
            }
            
            if(gamesPayload.isEmpty){
                self.transitionToTime()
                return
            } else {
                self.selectionTable.dataSource = self
                self.selectionTable.delegate = self
                self.selectionTable.reloadData()
            }
            
            UIView.animate(withDuration: 0.8, animations: {
                self.mainLayout.alpha = 0
                self.confirmationView.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.gameLayout.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.8, animations: {
                        self.selectionHeader.alpha = 1
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                            self.selectionTable.alpha = 1
                            self.selectionContinue.alpha = 1
                        }, completion: nil)
                    })
                })
            })
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func transitionToTime(){
        self.selectedTime = "now."
        self.timePayload = ["now.", "5 - 10 min", "20 - 30 min", "45 - 60 min"]
        self.timePicker.delegate = self
        self.timePicker.dataSource = self
        self.finishButton.addTarget(self, action: #selector(transitionToConfirm), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.gameLayout.alpha = 0
            self.confirmationView.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.timeLayout.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, animations: {
                    self.timeHeader.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.timePicker.alpha = 1
                        self.finishButton.alpha = 1
                    }, completion: nil)
                })
            })
        })
    }
    
    @objc private func transitionToConfirm(){
        self.editGameLabel.text = self.selectedGame
        self.editTimeLabel.text = self.selectedTime
        self.sendButton.addTarget(self, action: #selector(showWork), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.8, animations: {
            self.gameLayout.alpha = 0
            self.timeLayout.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.confirmationView.alpha = 1
            }, completion: nil)
        })
    }
    
    private func sendPayload(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let profManager = appDelegate.profileManager
        
        if(profManager.wannaPlayCachedUser != nil){
            let manager = FriendsManager()
            manager.createRivalRequest(otherUser: profManager.wannaPlayCachedUser!, game: self.selectedGame, type: self.selectedTime, callbacks: self, gamerTags: profManager.wannaPlayCachedUser!.gamerTags)
        }
    }
    
    @objc private func doneClicked(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func transitionToDone(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(doneClicked))
        self.doneButton.isUserInteractionEnabled = true
        self.doneButton.addGestureRecognizer(singleTap)
    
        UIView.animate(withDuration: 0.8, animations: {
            self.sendingAnimation.pause()
            self.sendingAnimation.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.doneView.alpha = 1
            }, completion: nil)
        })
    }
    
    private func transitionToError(){
        UIView.animate(withDuration: 0.8, animations: {
            self.sendingAnimation.pause()
            self.sendingAnimation.alpha = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.errorView.alpha = 1
            }, completion: nil)
        })
    }
    
    @objc private func showWork(){
        UIView.animate(withDuration: 0.8, animations: {
            self.sendingOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.sendingAnimation.alpha = 1
                self.sendingAnimation.loopMode = .loop
                self.sendingAnimation.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendPayload()
                }
            }, completion: nil)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.gamesPayload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "game", for: indexPath) as! PlayGameCell
        let current = gamesPayload[indexPath.item]
        cell.gameName.text = current.gameName
        cell.coverLabel.text = current.gameName
        
        if(self.selectedGame == current.gameName){
            cell.cover.alpha = 1
            cell.gameName.alpha = 0
        } else {
            cell.gameName.alpha = 1
            cell.cover.alpha = 0
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = gamesPayload[indexPath.item]
        if(self.selectedGame == current.gameName){
            self.selectedGame = ""
        } else {
            self.selectedGame = current.gameName
        }
        self.selectionTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
    
    private func getGCGame(profile: GamerProfile) -> GamerConnectGame? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for game in appDelegate.gcGames {
            if(game.gameName == profile.game){
                return game
            }
        }
        return nil
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timePayload.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return timePayload[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let current = timePayload[row]
        self.selectedTime = current
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: timePayload[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func rivalRequestAlready() {
        transitionToError()
    }
    
    func rivalRequestSuccess() {
        self.transitionToDone()
    }
    
    func rivalRequestFail() {
        transitionToError()
    }
    
    func rivalResponseAccepted(indexPath: IndexPath) {
    }
    
    func rivalResponseRejected(indexPath: IndexPath) {
    }
    
    func rivalResponseFailed() {
    }
    
    func friendRemoved() {
    }
    
    func friendRemoveFail() {
        
    }
}
