//
//  CompetitionFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftNotificationCenter
import UnderLineTextField
import AIFlatSwitch
import Firebase
import PopupDialog
import Lottie
import FBSDKCoreKit

class CompetitionFrag: ParentVC, UITextFieldDelegate {
    var competition: CompetitionObj!
    var timer: Timer!
    
    @IBOutlet weak var streamAnimation: LottieAnimationView!
    @IBOutlet weak var notifyView: UIView!
    @IBOutlet weak var notifyMe: AIFlatSwitch!
    @IBOutlet weak var streamLoading: UIActivityIndicatorView!
    @IBOutlet weak var competitionViewer: TestPlayer!
    @IBOutlet weak var overlayRegisterButton: UIButton!
    @IBOutlet weak var verifyCheck: AIFlatSwitch!
    @IBOutlet weak var schoolEntry: UnderLineTextField!
    @IBOutlet weak var actionTag: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var eventDesc: UILabel!
    @IBOutlet weak var sponsorName: UILabel!
    @IBOutlet weak var prizeView: UIView!
    @IBOutlet weak var sponsorView: UIView!
    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var competitionName: UILabel!
    @IBOutlet weak var competitionDate: UILabel!
    @IBOutlet weak var registerBlur: UIVisualEffectView!
    @IBOutlet weak var registerInfo: UIView!
    @IBOutlet weak var registeredOverlay: UIView!
    @IBOutlet weak var registeredConfirm: UILabel!
    @IBOutlet weak var registerSpinner: UIActivityIndicatorView!
    @IBOutlet weak var secondPrize: UILabel!
    @IBOutlet weak var thirdPrize: UILabel!
    @IBOutlet weak var grandPrize: UILabel!
    
    @IBOutlet weak var mainSponsor: UILabel!
    @IBOutlet weak var sponsorImage: UIImageView!
    @IBOutlet weak var sponsorLayout: UIView!
    var prizePayload = [String]()
    var competitionDateObj: NSDate?
    var competitionAirDateObj: NSDate?
    var postRegistration = false
    var registered = false
    var showCompLive = false
    var countdownToAir = false
    var gamerTagEntered = false
    
    var registerWithGamerTag = ""
    var registerSchool = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sponsorName.text = competition.mainSponsor
        competitionName.text = competition.competitionName
        competitionDate.text = competition.competitionDateString
        secondPrize.text = competition.secondPrize
        thirdPrize.text = competition.thirdPrize
        grandPrize.text = competition.topPrize
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + competition.competitionId + " viewed"))
        addEmergencyLiveRef()
        addEmergencyRegOverRef()
        figureRegistered()
        fixUI()
    }
    
    private func fixUI(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for tag in delegate.currentUser!.gamerTags{
            if(tag.game == competition.gcName){
                self.registerWithGamerTag = tag.gamerTag
                break
            }
        }
        
        handleActionButton()
        animateView()
    }
    
    private func figureRegistered(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for competitionId in delegate.currentUser!.competitions{
            if(competitionId == competition.competitionId){
                self.registered = true
                break
            }
        }
    }
    
    private func animateView(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let top1 = CGAffineTransform(translationX: 0, y: -20)
            let top2 = CGAffineTransform(translationX: 0, y: -10)
            UIView.animate(withDuration: 0.8, animations: {
                self.competitionDate.alpha = 1
                self.competitionDate.transform = top1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.actionButton.alpha = 1
                    self.actionButton.transform = top2
                    self.prizeView.transform = top2
                    self.prizeView.alpha = 1
                    self.sponsorLayout.transform = top1
                    self.sponsorLayout.alpha = 1
                    
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.sponsorClicked))
                    self.sponsorLayout.isUserInteractionEnabled = true
                    self.sponsorLayout.addGestureRecognizer(singleTap)
                }, completion: nil)
            })
        }
    }
    
    @objc func sponsorClicked(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentLanding!.navigateToSponsor()
    }
    
    private func handleActionButton(){
        if(self.registerWithGamerTag.isEmpty){
            competitionAirDateObj = stringToDate(competition.competitionAirDate) as NSDate
            competitionDateObj = stringToDate(competition.competitionDate) as NSDate
            
            if(self.competitionDateObj != nil){
            //if we can get it
            if(self.competitionDateObj!.isLessThanDate(dateToCompare: NSDate())){
                //if registration day has passed.
                self.postRegistration = true
                
                //look for the date that we show it live.
                competitionAirDateObj = stringToDate(competition.competitionAirDate) as NSDate
                    if(competitionAirDateObj != nil){
                        //if we can get it
                        if(Calendar.current.isDate(competitionAirDateObj! as Date, inSameDayAs:Date())){
                            //if it is the day of the event.
                            if(competitionAirDateObj!.isLessThanDate(dateToCompare: NSDate())){
                                self.countdownLabel.text = ""
                                self.actionTag.text = "stream it live"
                                self.showCompLive = true
                                
                                self.countdownLabel.isHidden = true
                                self.streamAnimation.isHidden = false
                                self.streamAnimation.loopMode = .playOnce
                                self.streamAnimation.play()
                                
                                self.actionButton.backgroundColor = UIColor(named: "greenToDarker")
                                
                                let actionTap = UITapGestureRecognizer(target: self, action: #selector(actionClicked))
                                self.actionButton.isUserInteractionEnabled = true
                                self.actionButton.addGestureRecognizer(actionTap)
                            }
                            else{
                                countdownToAir = true
                                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                                
                                self.actionTag.text = "tune in today!"
                                self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                                self.countdownLabel.text = ""
                            }
                        }
                        else if(competitionAirDateObj!.isLessThanDate(dateToCompare: NSDate())){
                            //if the day has passed.
                            self.actionTag.text = "event expired."
                            self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                            self.countdownLabel.text = ""
                        }
                        else{
                            self.actionTag.text = "streaming soon"
                            self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                            
                            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                        }
                    }
                    else{
                        self.actionTag.text = "registration closed."
                        self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                        self.countdownLabel.text = ""
                        self.streamAnimation.isHidden = true
                    }
                }
                else if(self.competitionDateObj!.isGreaterThanDate(dateToCompare: NSDate())){
                    timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                    
                    self.actionTag.text = "update info"
                    self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                    
                    let actionTap = UITapGestureRecognizer(target: self, action: #selector(actionClicked))
                    self.actionButton.isUserInteractionEnabled = true
                    self.actionButton.addGestureRecognizer(actionTap)
                }
                else{
                    self.actionTag.text = "registration closed."
                    self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                    self.countdownLabel.text = ""
                    self.streamAnimation.isHidden = true
                }
            }
        }
        else{
            //get competition registration date
            competitionDateObj = stringToDate(competition.competitionDate) as NSDate
            
            if(self.competitionDateObj != nil){
                //if we can get it
                if(self.competitionDateObj!.isLessThanDate(dateToCompare: NSDate())){
                    //if registration day has passed.
                    self.postRegistration = true
                    
                    //look for the date that we show it live.
                    competitionAirDateObj = stringToDate(competition.competitionAirDate) as NSDate
                    if(competitionAirDateObj != nil){
                        //if we can get it
                        if(Calendar.current.isDate(competitionAirDateObj! as Date, inSameDayAs:Date())){
                            //if it is the day of the event.
                            if(competitionAirDateObj!.isLessThanDate(dateToCompare: NSDate())){
                                self.countdownLabel.text = ""
                                self.actionTag.text = "stream it live"
                                self.showCompLive = true
                                
                                self.countdownLabel.isHidden = true
                                self.streamAnimation.isHidden = false
                                self.streamAnimation.loopMode = .playOnce
                                self.streamAnimation.play()
                                
                                self.actionButton.backgroundColor = UIColor(named: "greenToDarker")
                                
                                let actionTap = UITapGestureRecognizer(target: self, action: #selector(actionClicked))
                                self.actionButton.isUserInteractionEnabled = true
                                self.actionButton.addGestureRecognizer(actionTap)
                            }
                            else{
                                countdownToAir = true
                                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                                
                                self.actionTag.text = "tune in today!"
                                self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                                self.countdownLabel.text = ""
                            }
                        }
                        else if(competitionAirDateObj!.isLessThanDate(dateToCompare: NSDate())){
                            //if the day has passed.
                            self.actionTag.text = "event expired."
                            self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                            self.countdownLabel.text = ""
                        }
                        else{
                            self.actionTag.text = "streaming soon"
                            self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                            
                            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                        }
                    }
                    else{
                        self.actionTag.text = "registration closed."
                        self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                        self.countdownLabel.text = ""
                    }
                }
                else{
                    competitionDateObj = stringToDate(competition.competitionDate) as NSDate
                    timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTime), userInfo: nil, repeats: true)
                    
                    if(self.registered){
                        self.actionTag.alpha = 0
                        self.notifyView.alpha = 1
                        
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let currentUser = delegate.currentUser!
                        
                        if(currentUser.subscriptions.contains(competition.subscriptionId)){
                            self.notifyMe.setSelected(true, animated: false)
                        }
                        else{
                            self.notifyMe.setSelected(false, animated: false)
                        }
                        
                        self.notifyMe.addTarget(self, action: #selector(notifySwitchChanged), for: UIControl.Event.valueChanged)
                        
                        
                        self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
                    }
                    else{
                        self.actionTag.text = "register"
                        self.actionButton.backgroundColor = UIColor(named: "greenToDarker")
                        
                        let actionTap = UITapGestureRecognizer(target: self, action: #selector(actionClicked))
                        self.actionButton.isUserInteractionEnabled = true
                        self.actionButton.addGestureRecognizer(actionTap)
                    }
                }
            }
            else{
                self.actionButton.isHidden = true
            }
        }
        
        if(competition.emergencyShowRegistrationOver == "true" && competition.emergencyShowLiveStream != "true"){
            forceShowNotify()
        } else if(competition.emergencyShowLiveStream == "true"){
            showLive()
        }
    }
    
    private func forceShowNotify(){
        self.actionTag.alpha = 0
        self.notifyView.alpha = 1
        self.streamAnimation.isHidden = true
        self.countdownLabel.isHidden = true
        self.actionTag.text = ""
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        if(currentUser.subscriptions.contains(competition.subscriptionId)){
            self.notifyMe.setSelected(true, animated: false)
        }
        else{
            self.notifyMe.setSelected(false, animated: false)
        }
        
        self.notifyMe.addTarget(self, action: #selector(notifySwitchChanged), for: UIControl.Event.valueChanged)
        
        
        self.actionButton.backgroundColor = UIColor(named: "darkOpacity")
    }
    
    private func showLive(){
        self.notifyView.alpha = 0
        self.actionTag.alpha = 1
        
        self.countdownLabel.text = ""
        self.actionTag.text = "stream it live"
        self.showCompLive = true
        
        self.countdownLabel.isHidden = true
        self.streamAnimation.isHidden = false
        self.streamAnimation.loopMode = .playOnce
        self.streamAnimation.play()
        
        self.actionButton.backgroundColor = UIColor(named: "greenToDarker")
        
        let actionTap = UITapGestureRecognizer(target: self, action: #selector(actionClicked))
        self.actionButton.isUserInteractionEnabled = true
        self.actionButton.addGestureRecognizer(actionTap)
    }
    
    private func addEmergencyLiveRef(){
        let newFriendRef = Database.database().reference().child("Competitions").child(competition.competitionId).child("emergencyShowLiveStream")
        newFriendRef.observe(.value, with: { (snapshot) in
            if(snapshot.value as? String == "true"){
                self.showLive()
                
                self.competition.emergencyShowRegistrationOver = "false"
                self.competition.emergencyShowLiveStream = "true"
            }
        })
    }
    
    private func addEmergencyRegOverRef(){
        let newFriendRef = Database.database().reference().child("Competitions").child(competition.competitionId).child("emergencyShowRegistrationOver")
        newFriendRef.observe(.value, with: { (snapshot) in
            if(snapshot.value as? String == "true"){
                self.forceShowNotify()
                
                self.competition.emergencyShowRegistrationOver = "true"
                self.competition.emergencyShowLiveStream = "false"
            }
        })
    }
    
    @objc func actionClicked(_ sender: AnyObject?) {
        if(self.showCompLive){
            self.streamLoading.alpha = 1
            self.streamLoading.startAnimating()
            
            NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeKeyNotification,
                object: self.view.window,
                queue: nil
            ) { notification in
                print("Video stopped")
                //self.twitchPlayer.isHidden = true
                self.competitionViewer.setChannel(to: "")
                self.streamLoading.stopAnimating()
                self.streamLoading.alpha = 0
                //UIView.animate(withDuration: 0.8) {
                //    self.twitchPlayerOverlay.alpha = 0
                //}
            }
            
            competitionViewer.configuration.allowsInlineMediaPlayback = true
            competitionViewer.configuration.mediaTypesRequiringUserActionForPlayback = []
            competitionViewer.setChannel(to: competition.twitchChannelId)
            
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + competition.competitionId + " streamed live"))
        }
        else{
            if(self.registerWithGamerTag.isEmpty){
                var buttons = [PopupDialogButton]()
                let title = "it's easy."
                let message = "just go to your profile, tap 2K, enter your info."
                
                let button = DefaultButton(title: "got it.") { [weak self] in
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentLanding!.navigateToCurrentUserProfile()
                    
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
            }
            else{
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + competition.competitionId + " registration view shown"))
                let delegate = UIApplication.shared.delegate as! AppDelegate
                for tag in delegate.currentUser!.gamerTags{
                    if(tag.game == competition.gcName){
                        self.registerWithGamerTag = tag.gamerTag
                        break
                    }
                }
                
                schoolEntry.delegate = self
                schoolEntry.returnKeyType = .done
                
                self.verifyCheck.addTarget(self, action: #selector(verifySwitchChanged), for: UIControl.Event.valueChanged)
                
                if(self.verifyCheck.isSelected){
                    self.verifyCheck.setSelected(false, animated: true)
                }
                
                checkNextButton()
                
                //call to DB
                let top = CGAffineTransform(translationX: 0, y: 20)
                UIView.animate(withDuration: 0.8, animations: {
                    self.registerBlur.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        self.registerInfo.transform = top
                        self.registerInfo.alpha = 1
                    }, completion: nil)
                })
            }
        }
    }
    
    @objc func verifySwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func notifySwitchChanged(stationSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                var subscriptions = value?["subscriptions"] as? [String] ?? [String]()
                
                if(stationSwitch.isSelected){
                    if(!subscriptions.contains(self.competition.subscriptionId)){
                        subscriptions.append(self.competition.subscriptionId)
                        ref.child("subscriptions").setValue(subscriptions)
                    }
                    
                    currentUser.subscriptions.append(self.competition.subscriptionId)
                    
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " notify selected"))
                    
                    //Firebase
                    Messaging.messaging().subscribe(toTopic: self.competition.subscriptionId) { error in
                      print("Subscribed to topic")
                    }
                }
                else{
                    if(subscriptions.contains(self.competition.subscriptionId)){
                        subscriptions.remove(at: subscriptions.index(of: self.competition.subscriptionId)!)
                        ref.child("subscriptions").setValue(subscriptions)
                    }
                    
                    if(currentUser.subscriptions.contains(self.competition.subscriptionId)){
                        currentUser.subscriptions.remove(at: currentUser.subscriptions.index(of: self.competition.subscriptionId)!)
                    }
                    
                    Messaging.messaging().unsubscribe(fromTopic: self.competition.subscriptionId) { error in
                      print("Unsubscribed from topic")
                    }
                    
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " notify unselected"))
                }
            }
        }) { (error) in
            self.updateUser()
            print(error.localizedDescription)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text?.count ?? 0 > 5){
            self.gamerTagEntered = true
            checkNextButton()
        }
    }
    
    private func checkNextButton(){
        if(verifyCheck.isSelected){
            self.overlayRegisterButton.alpha = 1
            self.overlayRegisterButton.isUserInteractionEnabled = true
            
            let registerTap = UITapGestureRecognizer(target: self, action: #selector(registerClicked))
            self.overlayRegisterButton.isUserInteractionEnabled = true
            self.overlayRegisterButton.addGestureRecognizer(registerTap)
        }
        else{
            self.overlayRegisterButton.alpha = 0.3
            self.overlayRegisterButton.isUserInteractionEnabled = false
        }
    }
    
    @objc func registerClicked(_ sender: AnyObject?) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " sending registration"))
        if(self.schoolEntry.text != nil){
            self.registerSchool = self.schoolEntry.text!
        }
        
        self.registeredOverlay.backgroundColor = UIColor(named: "darkOpacity")
        
        UIView.animate(withDuration: 0.8, animations: {
            self.registeredOverlay.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.registerSpinner.startAnimating()
                
                let ref = Database.database().reference().child("Competitions").child(self.competition.competitionId)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.exists()){
                        var competitors = [CompetitorObj]()
                        let competitorList = snapshot.childSnapshot(forPath: "competitors")
                        for invite in competitorList.children{
                            let currentObj = invite as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            let school = dict?["school"] as? String ?? ""
                            let verified = dict?["verified"] as? String ?? "true"
                            
                            let newComp = CompetitorObj(gamerTag: gamerTag, uid: uid, school: school, verified: verified, date: date)
                            competitors.append(newComp)
                        }
                        
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        var contained = false
                        
                        for entry in competitors{
                            if(entry.uid == delegate.currentUser!.uId){
                                contained = true
                                break
                            }
                        }
                        
                        if(!contained){
                            let currentUser = delegate.currentUser!
                            var gTag: GamerProfile? = nil
                            
                            for tag in currentUser.gamerTags{
                                if(tag.game == self.competition.gcName){
                                    gTag = tag
                                    break
                                }
                            }
                            
                            if(gTag != nil){
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMMM.dd.yyyy"
                                let result = formatter.string(from: date)
                                
                                
                                let competitor = CompetitorObj(gamerTag: gTag!.gamerTag, uid: currentUser.uId, school: self.registerSchool, verified: "true", date: result)
                                
                                competitors.append(competitor)
                            }
                        }
                        
                        var outList = [[String: String]]()
                        for comp in competitors{
                            let temp = ["gamerTag": comp.gamerTag, "uid": comp.uid, "school": comp.school, "verified": comp.verified, "date": comp.date]
                            
                            outList.append(temp)
                        }
                        
                        ref.child("competitors").setValue(outList)
                        
                        self.updateUser()
                        
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " successful registration"))
                    }
                    
                }) { (error) in
                    self.updateUser()
                    
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " registration error"))
                    print(error.localizedDescription)
                }
            }, completion: nil)
        })
    }
    
    private func updateUser(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                
                var competitions = value?["competitions"] as? [String] ?? [String]()
                competitions.append(self.competition.competitionId)
                
                ref.child("competitions").setValue(competitions)
                
                currentUser.competitions.append(self.competition.competitionId)
                
                if(!self.registerSchool.isEmpty){
                    ref.child("schoolRepresentation").setValue(self.registerSchool)
                }
                
                self.dismissOverlay()
            }
            else{
                self.dismissOverlay()
            }
        })
        { (error) in
            self.dismissOverlay()
            print(error.localizedDescription)
        }
    }
    
    private func dismissOverlay(){
        figureRegistered()
        handleActionButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIView.animate(withDuration: 0.5, animations: {
                self.registerSpinner.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    UIView.transition(with: self.registeredOverlay, duration: 0.3, options: .curveEaseInOut, animations: {
                        self.registeredOverlay.backgroundColor = UIColor(named: "greenAlpha")
                    }, completion: nil)
                    self.registeredConfirm.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
                         self.registerInfo.alpha = 0
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
                             self.registerBlur.alpha = 0
                        }, completion: nil)
                    })
                })
            })
        }
    }
    
    @objc func UpdateTime() {
        let userCalendar = Calendar.current
        // Set Current Date
        let date = Date()
        let components = userCalendar.dateComponents([.hour, .minute, .month, .year, .day, .second], from: date)
        let currentDate = userCalendar.date(from: components)!
        
        
        var eventDateComponents = DateComponents()
        if(!self.postRegistration){
            eventDateComponents = userCalendar.dateComponents([.hour, .minute, .month, .year, .day, .second], from: competitionDateObj! as Date)
        }
        else{
            eventDateComponents = userCalendar.dateComponents([.hour, .minute, .month, .year, .day, .second], from: competitionAirDateObj! as Date)
        }
        
        // Set Event Date
        /*if(!self.postRegistration){
            var eventDateComponents = DateComponents()
            eventDateComponents.year = 2020
            eventDateComponents.month = 06
            eventDateComponents.day = 01
            eventDateComponents.hour = 00
            eventDateComponents.minute = 00
            eventDateComponents.second = 00
            eventDateComponents.timeZone = TimeZone(abbreviation: "GMT")
        }*/
        
        // Convert eventDateComponents to the user's calendar
        let eventDate = userCalendar.date(from: eventDateComponents)!
        
        if(self.countdownToAir){
            endEvent(currentdate: currentDate, eventdate: eventDate)
        }
        else{
            // Change the seconds to days, hours, minutes and seconds
            let timeLeft = userCalendar.dateComponents([.day, .hour, .minute, .second], from: currentDate, to: eventDate)
            
            // Display Countdown
            countdownLabel.text = "\(timeLeft.day!)d \(timeLeft.hour!)h \(timeLeft.minute!)m \(timeLeft.second!)s"
            
            // Show diffrent text when the event has passed
            endEvent(currentdate: currentDate, eventdate: eventDate)
        }
    }
    
    func endEvent(currentdate: Date, eventdate: Date) {
        if currentdate >= eventdate {
            // Stop Timer
            timer.invalidate()
            
            handleActionButton()
            
            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Competition " + self.competition.competitionId + " user on page when timer ends."))
        }
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="yyyy.MM.dd hh:mm aaa"
        return formatter.date(from: str)!
    }
    
    func dateFromMilliseconds(ms: NSNumber) -> NSDate {
        return NSDate(timeIntervalSince1970:Double(truncating: ms) / 1000.0)
    }
}

extension NSDate {

    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false

        //Compare Values
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedDescending {
            isGreater = true
        }

        //Return Result
        return isGreater
    }

    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false

        //Compare Values
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedAscending {
            isLess = true
        }

        //Return Result
        return isLess
    }

    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false

        //Compare Values
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedSame {
            isEqualTo = true
        }

        //Return Result
        return isEqualTo
    }

    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.addingTimeInterval(secondsInDays)

        //Return Result
        return dateWithDaysAdded
    }

    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.addingTimeInterval(secondsInHours)

        //Return Result
        return dateWithHoursAdded
    }
}
