//
//  GCRegistration.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/19/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import UnderLineTextField
import SPStorkController
import FirebaseDatabase
import CoreLocation
import GeoFire
import SwiftLocation

class GCRegistration: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var consoleContinue: UIButton!
    @IBOutlet weak var ageLayout: UIView!
    @IBOutlet weak var youngBox: UIView!
    @IBOutlet weak var youngCover: UIView!
    @IBOutlet weak var midBox: UIView!
    @IBOutlet weak var midCover: UIView!
    @IBOutlet weak var oldBox: UIView!
    @IBOutlet weak var oldCover: UIView!
    @IBOutlet weak var overBox: UIView!
    @IBOutlet weak var overCover: UIView!
    
    @IBOutlet weak var locationAnimationLight: AnimationView!
    @IBOutlet weak var five: UILabel!
    @IBOutlet weak var four: UILabel!
    @IBOutlet weak var three: UILabel!
    @IBOutlet weak var two: UILabel!
    @IBOutlet weak var one: UILabel!
    @IBOutlet weak var zero: UILabel!
    @IBOutlet weak var experienceSlider: UISlider!
    @IBOutlet weak var experienceBox: UIView!
    @IBOutlet weak var experienceOption: UILabel!
    @IBOutlet weak var experienceSub: UILabel!
    @IBOutlet weak var experienceView: UIView!
    @IBOutlet weak var genderSkipCover: UIView!
    @IBOutlet weak var otherGenderCover: UIView!
    @IBOutlet weak var transgenderCover: UIView!
    @IBOutlet weak var femaleCover: UIView!
    @IBOutlet weak var maleCover: UIView!
    @IBOutlet weak var genderSkip: UIView!
    @IBOutlet weak var otherGenderBox: UIView!
    @IBOutlet weak var transgenderBox: UIView!
    @IBOutlet weak var femaleBox: UIView!
    @IBOutlet weak var maleBox: UIView!
    @IBOutlet weak var genderLayout: UIView!
    @IBOutlet weak var locationAnimation: AnimationView!
    @IBOutlet weak var refuseLocation: UIButton!
    @IBOutlet weak var allowLocation: UIButton!
    @IBOutlet weak var locationLayout: UIView!
    @IBOutlet weak var secondaryPicker: UIPickerView!
    @IBOutlet weak var secondaryLanguage: UIView!
    @IBOutlet weak var primaryLanguage: UIView!
    @IBOutlet weak var languageLayout: UIView!
    @IBOutlet weak var drawer: UIView!
    @IBOutlet weak var startLayout: UIView!
    @IBOutlet weak var startProfileButton: UIButton!
    @IBOutlet weak var celebrateAnimation: AnimationView!
    @IBOutlet weak var gcContinueButton: UIButton!
    @IBOutlet weak var skipCover: UIView!
    var consoles = [String]()
    var constraint : NSLayoutConstraint?
    var selectedAge = ""
    var selectedPrimaryLanguage = ""
    var selectedSecondaryLanguage = "none"
    var currendSelectedGender = ""
    private var selectedGameNames = [String]()
    private var availableGames = [GamerConnectGame]()
    private var selectedGames = [GamerConnectGame]()
    @IBOutlet weak var primaryPicker: UIPickerView!
    @IBOutlet weak var ageSkip: UIView!
    var fallBacklanguages = ["none", "english", "chinese", "spanish", "hindi", "arabic", "bengali", "portuguese", "russian", "japanese", "lahnda"]
    var languageList = [String]()
    var secondLanguage = [String]()
    var locationLat = 0.0
    var locationLong = 0.0
    var experienceVal = 0.0
    var req: LocationRequest?
    
    //location
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.celebrateAnimation.animationSpeed = 0.6
            self.celebrateAnimation.loopMode = .playOnce
            self.celebrateAnimation.play()
        }
        
        self.startProfileButton.addTarget(self, action: #selector(startButtonClicked), for: .touchUpInside)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true"){
                list.append(game)
            }
        }
        
        
        self.languageList.append("english")
        let sortedList = delegate.languageList.sorted(by: <)
        for language in sortedList {
            if(!self.languageList.contains(language.value)){
                self.languageList.append(language.key.lowercased())
            }
        }
        
        primaryPicker.delegate = self
        primaryPicker.dataSource = self
        
        youngBox.tag = 0
        let youngTap = AgeTapGesture(target: self, action: #selector(ageButtonClicked))
        youngTap.age = "12 - 16"
        youngBox.isUserInteractionEnabled = true
        youngBox.addGestureRecognizer(youngTap)
        midBox.tag = 1
        let midTap = AgeTapGesture(target: self, action: #selector(ageButtonClicked))
        midTap.age = "17 - 24"
        midBox.isUserInteractionEnabled = true
        midBox.addGestureRecognizer(midTap)
        oldBox.tag = 2
        let oldTap = AgeTapGesture(target: self, action: #selector(ageButtonClicked))
        oldTap.age = "25 - 31"
        oldBox.isUserInteractionEnabled = true
        oldBox.addGestureRecognizer(oldTap)
        overBox.tag = 3
        let overTap = AgeTapGesture(target: self, action: #selector(ageButtonClicked))
        overTap.age = "32+"
        overBox.isUserInteractionEnabled = true
        overBox.addGestureRecognizer(overTap)
        ageSkip.tag = 4
        let skipTap = AgeTapGesture(target: self, action: #selector(ageButtonClicked))
        skipTap.age = "unidentified"
        ageSkip.isUserInteractionEnabled = true
        ageSkip.addGestureRecognizer(skipTap)
        
        let maleTap = GenderTapGesture(target: self, action: #selector(genderClicked))
        maleTap.gender = "male"
        maleBox.isUserInteractionEnabled = true
        maleBox.addGestureRecognizer(maleTap)
        
        let femaleTap = GenderTapGesture(target: self, action: #selector(genderClicked))
        femaleTap.gender = "female"
        femaleBox.isUserInteractionEnabled = true
        femaleBox.addGestureRecognizer(femaleTap)
        
        let transgenderTap = GenderTapGesture(target: self, action: #selector(genderClicked))
        transgenderTap.gender = "transgender"
        transgenderBox.isUserInteractionEnabled = true
        transgenderBox.addGestureRecognizer(transgenderTap)
        
        let otherTap = GenderTapGesture(target: self, action: #selector(genderClicked))
        otherTap.gender = "other"
        otherGenderBox.isUserInteractionEnabled = true
        otherGenderBox.addGestureRecognizer(otherTap)
        
        let skipGenderTap = GenderTapGesture(target: self, action: #selector(genderClicked))
        skipGenderTap.gender = "unidentified"
        genderSkip.isUserInteractionEnabled = true
        genderSkip.addGestureRecognizer(skipGenderTap)
        
        self.experienceOption.text = "no experience"
        self.experienceSub.text = "all of this is new to me. i am NOT a gamer. lol"
        self.experienceSlider.value = 0
        self.one.alpha = 0.05
        
        self.experienceSlider.addTarget(self, action: #selector(onExperienceChange), for: UIControl.Event.valueChanged)
    
        availableGames = list
    }
    
    @objc private func onExperienceChange(){
        self.experienceVal = Double(self.experienceSlider.value)
        if(self.experienceVal < 1){
            self.experienceOption.text = "no experience"
            self.experienceSub.text = "all of this is new to me. i am NOT a gamer. lol"
            UIView.animate(withDuration: 0.3, animations: {
                self.zero.alpha = 0
                self.one.alpha = 0.05
                self.two.alpha = 0
                self.three.alpha = 0
                self.four.alpha = 0
                self.five.alpha = 0
            }, completion: nil)
        } else if(self.experienceVal >= 1 && self.experienceVal <= 2){
            self.experienceOption.text = "a little bit"
            self.experienceSub.text = "i'll own you in mario kart!"
            UIView.animate(withDuration: 0.3, animations: {
                self.zero.alpha = 0
                self.one.alpha = 0
                self.two.alpha = 0.05
                self.three.alpha = 0
                self.four.alpha = 0
                self.five.alpha = 0
            }, completion: nil)
        } else if(self.experienceVal > 2 && self.experienceVal < 3){
            self.experienceOption.text = "some experience"
            self.experienceSub.text = "i have games that i play, but i'm not really a gamer."
            UIView.animate(withDuration: 0.3, animations: {
                self.zero.alpha = 0
                self.one.alpha = 0
                self.two.alpha = 0
                self.three.alpha = 0.05
                self.four.alpha = 0
                self.five.alpha = 0
            }, completion: nil)
        } else if(self.experienceVal >= 3 && self.experienceVal < 5){
            self.experienceOption.text = "basically a gamer"
            self.experienceSub.text = "you just don't wanna admit it."
            UIView.animate(withDuration: 0.3, animations: {
                self.zero.alpha = 0
                self.one.alpha = 0
                self.two.alpha = 0
                self.three.alpha = 0
                self.four.alpha = 0.05
                self.five.alpha = 0
            }, completion: nil)
        } else {
            self.experienceOption.text = "gamer"
            self.experienceSub.text = "i've been gaming for years."
            UIView.animate(withDuration: 0.3, animations: {
                self.zero.alpha = 0
                self.one.alpha = 0
                self.two.alpha = 0
                self.three.alpha = 0
                self.four.alpha = 0
                self.five.alpha = 0.05
            }, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.experienceBox.layer.shadowColor = UIColor.black.cgColor
        self.experienceBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.experienceBox.layer.shadowRadius = 2.0
        self.experienceBox.layer.shadowOpacity = 0.5
        self.experienceBox.layer.masksToBounds = false
        self.experienceBox.layer.shadowPath = UIBezierPath(roundedRect: self.experienceBox.layer.bounds, cornerRadius: self.experienceBox.layer.cornerRadius).cgPath
        super.viewWillAppear(animated)
    }
    
    @objc private func genderClicked(sender: GenderTapGesture){
        if(sender.gender == "male"){
            if(currendSelectedGender != "male"){
                currendSelectedGender = "male"
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 1
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            } else {
                self.currendSelectedGender = ""
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.gender == "female"){
            if(currendSelectedGender != "female"){
                currendSelectedGender = "female"
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 1
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            } else {
                self.currendSelectedGender = ""
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.gender == "transgender"){
            if(currendSelectedGender != "transgender"){
                currendSelectedGender = "transgender"
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 1
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            } else {
                self.currendSelectedGender = ""
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.gender == "other"){
            if(currendSelectedGender != "other"){
                currendSelectedGender = "other"
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 1
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            } else {
                self.currendSelectedGender = ""
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.gender == "unidentified"){
            if(currendSelectedGender != "unidentified"){
                currendSelectedGender = "unidentified"
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 1
                }, completion: nil)
            } else {
                self.currendSelectedGender = ""
                self.updateGCContinueGender()
                UIView.animate(withDuration: 0.3, animations: {
                    self.maleCover.alpha = 0
                    self.femaleCover.alpha = 0
                    self.transgenderCover.alpha = 0
                    self.otherGenderCover.alpha = 0
                    self.genderSkipCover.alpha = 0
                }, completion: nil)
            }
        }
    }
    
    @objc private func updateGCContinueGender(){
        if(!self.currendSelectedGender.isEmpty && self.gcContinueButton.alpha != 1.0){
            UIView.animate(withDuration: 0.4, animations: {
                self.gcContinueButton.alpha = 1
                self.gcContinueButton.isUserInteractionEnabled = true
                self.gcContinueButton.addTarget(self, action: #selector(self.transitionToAge), for: .touchUpInside)
            }, completion: nil)
        } else if(self.currendSelectedGender.isEmpty && self.gcContinueButton.alpha == 1.0){
            self.gcContinueButton.alpha = 0.4
            self.gcContinueButton.isUserInteractionEnabled = false
        }
    }
    
    @objc private func transitionToAge(){
        self.gcContinueButton.removeTarget(self, action: #selector(self.transitionToAge), for: .touchUpInside)
        self.updateGCContinueAge()
        UIView.animate(withDuration: 0.5, animations: {
            self.genderLayout.alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, animations: {
                   self.ageLayout.alpha = 1
                    self.genderLayout.isUserInteractionEnabled = false
                    self.ageLayout.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        let cntSlide = CGAffineTransform(translationX: 0, y: -100)
                        self.gcContinueButton.alpha = 0.4
                        self.gcContinueButton.transform = cntSlide
                    }, completion: nil)
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func ageButtonClicked(sender: AgeTapGesture){
        if(sender.age == "12 - 16"){
            if(selectedAge != "12_16"){
                selectedAge = "12_16"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 1
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "17 - 24"){
            if(selectedAge != "17_24"){
                selectedAge = "17_24"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 1
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "25 - 31"){
            if(selectedAge != "25_31"){
                selectedAge = "25_31"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 1
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "32+"){
            if(selectedAge != "32_over"){
                selectedAge = "32_over"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 1
                    self.skipCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "unidentified"){
            if(selectedAge != "unidentified"){
                selectedAge = "unidentified"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 1
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.3, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                    self.skipCover.alpha = 0
                }, completion: nil)
            }
        }
    }
    
    private func updateGCContinueAge(){
        if(!self.selectedAge.isEmpty && self.gcContinueButton.alpha != 1.0){
            UIView.animate(withDuration: 0.4, animations: {
                self.gcContinueButton.alpha = 1
                self.gcContinueButton.isUserInteractionEnabled = true
                self.gcContinueButton.addTarget(self, action: #selector(self.advanceToLanguage), for: .touchUpInside)
            }, completion: nil)
        } else if(self.selectedAge.isEmpty && self.gcContinueButton.alpha == 1.0){
            self.gcContinueButton.alpha = 0.4
            self.gcContinueButton.isUserInteractionEnabled = false
            self.gcContinueButton.addTarget(self, action: #selector(self.advanceToLanguage), for: .touchUpInside)
        }
    }
    
    @objc private func advanceToLanguage(){
        self.selectedPrimaryLanguage = "english"
        self.genderLayout.alpha = 0
        
        updateContinueGCPrimaryLang()
        UIView.animate(withDuration: 0.5, animations: {
            self.ageLayout.alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.ageLayout.alpha = 0
                UIView.animate(withDuration: 0.5, animations: {
                    self.languageLayout.alpha = 1
                    self.ageLayout.alpha = 0
                    self.ageLayout.isUserInteractionEnabled = false
                    self.languageLayout.isUserInteractionEnabled = true
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func startButtonClicked(){
        UIView.animate(withDuration: 0.5, animations: {
            self.startLayout.alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.experienceView.alpha = 1
                    self.startLayout.isUserInteractionEnabled = false
                    self.experienceView.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        let cntSlide = CGAffineTransform(translationX: 0, y: -100)
                        self.gcContinueButton.alpha = 1.0
                        self.gcContinueButton.addTarget(self, action: #selector(self.experienceNextButtonClicked), for: .touchUpInside)
                        self.gcContinueButton.transform = cntSlide
                    }, completion: nil)
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func experienceNextButtonClicked(){
        UIView.animate(withDuration: 0.5, animations: {
            self.experienceView.alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                   self.genderLayout.alpha = 1
                    self.startLayout.isUserInteractionEnabled = false
                    self.genderLayout.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        let cntSlide = CGAffineTransform(translationX: 0, y: -100)
                        self.gcContinueButton.alpha = 0.4
                        self.gcContinueButton.transform = cntSlide
                    }, completion: nil)
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    private func consolesCheckContinueButton(){
        let layoutReturn = CGAffineTransform(translationX: 0, y: 0)
        let layoutAnim2 = CGAffineTransform(translationX: 0, y: 100)
        if(consoles.isEmpty && self.consoleContinue.alpha == 1){
            UIView.animate(withDuration: 0.3, animations: {
                self.consoleContinue.alpha = 0
                self.consoleContinue.transform = layoutAnim2
            }, completion: nil)
        } else if(!consoles.isEmpty && self.consoleContinue.alpha == 0){
            UIView.animate(withDuration: 0.3, animations: {
                self.consoleContinue.alpha = 1
                self.consoleContinue.transform = layoutReturn
            }, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == self.primaryPicker){
            return languageList.count
        } else {
            return secondLanguage.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView == self.primaryPicker){
            return languageList[row]
        } else {
            return self.secondLanguage[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == self.primaryPicker){
            let current = languageList[row]
            self.selectedPrimaryLanguage = current
            updateContinueGCPrimaryLang()
        } else {
            let current = secondLanguage[row]
            self.selectedSecondaryLanguage = current
            updateContinueGCSecondaryLang()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if(pickerView == self.primaryPicker){
            return NSAttributedString(string: languageList[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(named: "darkToWhite")!])
        } else {
            return NSAttributedString(string: secondLanguage[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(named: "darkToWhite")!])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    
    private func updateContinueGCPrimaryLang(){
        if(self.selectedPrimaryLanguage == "none" || self.selectedPrimaryLanguage.isEmpty){
            self.gcContinueButton.alpha = 0.4
            self.gcContinueButton.isUserInteractionEnabled = false
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.gcContinueButton.alpha = 1
                self.gcContinueButton.isUserInteractionEnabled = true
                self.gcContinueButton.addTarget(self, action: #selector(self.advanceToSecondary), for: .touchUpInside)
            }, completion: nil)
        }
    }
    
    private func updateContinueGCSecondaryLang(){
        self.gcContinueButton.alpha = 1
        self.gcContinueButton.isUserInteractionEnabled = true
        self.gcContinueButton.addTarget(self, action: #selector(self.advanceToLocation), for: .touchUpInside)
    }
    
    @objc private func advanceToSecondary(){
        self.secondLanguage = [String]()
        self.secondLanguage.append("none")
        self.secondLanguage.append(contentsOf: languageList)
        if(secondLanguage.contains(self.selectedPrimaryLanguage)){
            self.secondLanguage.remove(at: self.secondLanguage.index(of: self.selectedPrimaryLanguage)!)
        }
        updateContinueGCSecondaryLang()
        self.secondaryPicker.delegate = self
        self.secondaryPicker.dataSource = self
        
        let layoutAnim2 = CGAffineTransform(translationX: -50, y: 0)
        UIView.animate(withDuration: 0.5, animations: {
            self.primaryLanguage.alpha = 0
            self.primaryLanguage.transform = layoutAnim2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.secondaryLanguage.alpha = 1
                    self.secondaryLanguage.transform = layoutAnim2
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func requestLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        if #available(iOS 14.0, *) {
            locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            locationManager?.desiredAccuracy = 5000
        }
        locationManager?.requestWhenInUseAuthorization()
    }
    
    @objc private func advanceToLocation(){
        let cntSlide = CGAffineTransform(translationX: 0, y: -100)
        UIView.animate(withDuration: 0.5, animations: {
            self.languageLayout.alpha = 0
            self.gcContinueButton.alpha = 0
            self.gcContinueButton.isUserInteractionEnabled = false
            self.gcContinueButton.transform = cntSlide
            UIView.animate(withDuration: 0.5, animations: {
               self.locationLayout.alpha = 1
                self.languageLayout.isUserInteractionEnabled = false
                self.locationLayout.isUserInteractionEnabled = true
                
                if self.traitCollection.userInterfaceStyle == .dark {
                    self.locationAnimation.alpha = 1
                    self.locationAnimationLight.alpha = 0
                    self.locationAnimation.play()
                } else {
                    self.locationAnimation.alpha = 0
                    self.locationAnimationLight.alpha = 1
                    self.locationAnimationLight.play()           // User Interface is Light
                }
                
                self.allowLocation.addTarget(self, action: #selector(self.requestLocation), for: .touchUpInside)
                self.refuseLocation.addTarget(self, action: #selector(self.advanceToGames), for: .touchUpInside)
            }, completion: nil)
        }, completion: nil)
    }
    
    @objc private func advanceToGames(){
        self.req?.stop()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.child("primaryLanguage").setValue(self.selectedPrimaryLanguage)
        ref.child("secondaryLanguage").setValue(self.selectedSecondaryLanguage)
        ref.child("selectedAge").setValue(self.selectedAge)
        ref.child("gender").setValue(self.currendSelectedGender)
        ref.child("gamingExperience").setValue(String(self.experienceVal))
        
        if(self.locationLat != 0.0){
            currentUser!.userLat = self.locationLat
            currentUser!.userLong = self.locationLong
            
            var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
            currentUser!.timezone = localTimeZoneAbbreviation
            ref.child("timezone").setValue(currentUser!.timezone)
            
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            geoFire.setLocation(CLLocation(latitude: self.locationLat, longitude: self.locationLong), forKey: currentUser!.uId)
        }
        
        self.performSegue(withIdentifier: "games", sender: nil)
    }
    //speed up animations between sets
    //location transition broken
    //test all UX, then test data.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            //manager.startUpdatingLocation()
            self.req = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { result in
              switch result {
                case .failure(let error):
                  debugPrint("Received error: \(error)")
                case .success(let location):
                    self.locationLat = (manager.location?.coordinate.latitude)!
                    self.locationLong = (manager.location?.coordinate.longitude)!
                    self.advanceToGames()
                    debugPrint("Location received: \(location)")
              }
            }
            self.req!.start()
        } else {
            advanceToGames()
        }
    }
}

class AgeTapGesture: UITapGestureRecognizer {
    var age = String()
}

class GenderTapGesture: UITapGestureRecognizer {
    var gender = String()
}
