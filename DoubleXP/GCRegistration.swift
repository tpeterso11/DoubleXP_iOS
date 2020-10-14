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
    var consoles = [String]()
    var constraint : NSLayoutConstraint?
    var selectedAge = ""
    var selectedPrimaryLanguage = ""
    var selectedSecondaryLanguage = ""
    private var selectedGameNames = [String]()
    private var availableGames = [GamerConnectGame]()
    private var selectedGames = [GamerConnectGame]()
    @IBOutlet weak var primaryPicker: UIPickerView!
    var languages = ["none", "english", "chinese", "spanish", "hindi", "arabic", "bengali", "portuguese", "russian", "japanese", "lahnda"]
    var secondLanguage = [String]()
    var locationLat = 0.0
    var locationLong = 0.0
    
    //location
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.celebrateAnimation.animationSpeed = 0.6
        self.celebrateAnimation.loopMode = .playOnce
        self.celebrateAnimation.play()
        
        self.startProfileButton.addTarget(self, action: #selector(startButtonClicked), for: .touchUpInside)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true"){
                list.append(game)
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
        
    
        availableGames = list
    }
    
    @objc private func ageButtonClicked(sender: AgeTapGesture){
        if(sender.age == "12 - 16"){
            if(selectedAge != "12 - 16"){
                selectedAge = "12 - 16"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 1
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "17 - 24"){
            if(selectedAge != "17 - 24"){
                selectedAge = "17 - 24"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 1
                    self.overCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "25 - 31"){
            if(selectedAge != "25 - 31"){
                selectedAge = "25 - 31"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 1
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
                }, completion: nil)
            }
        }
        if(sender.age == "32+"){
            if(selectedAge != "32+"){
                selectedAge = "32+"
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 1
                }, completion: nil)
            } else {
                self.selectedAge = ""
                self.updateGCContinueAge()
                UIView.animate(withDuration: 0.5, animations: {
                    self.youngCover.alpha = 0
                    self.oldCover.alpha = 0
                    self.midCover.alpha = 0
                    self.overCover.alpha = 0
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
        }
    }
    
    @objc private func advanceToLanguage(){
        updateContinueGCPrimaryLang()
        let layoutAnim = CGAffineTransform(translationX: 0, y: -10)
        let layoutAnim2 = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.8, animations: {
            self.ageLayout.alpha = 0
            self.ageLayout.transform = layoutAnim
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.languageLayout.alpha = 1
                    self.languageLayout.transform = layoutAnim2
                    self.ageLayout.isUserInteractionEnabled = false
                    self.languageLayout.isUserInteractionEnabled = true
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func startButtonClicked(){
        let layoutAnim = CGAffineTransform(translationX: -50, y: 0)
        let layoutAnim2 = CGAffineTransform(translationX: -50, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.startLayout.alpha = 0
            self.startLayout.transform = layoutAnim
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                   self.ageLayout.alpha = 1
                   self.ageLayout.transform = layoutAnim2
                    self.startLayout.isUserInteractionEnabled = false
                    self.ageLayout.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        let cntSlide = CGAffineTransform(translationX: 0, y: -70)
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
            return languages.count
        } else {
            return secondLanguage.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView == self.primaryPicker){
            return languages[row]
        } else {
            return self.secondLanguage[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == self.primaryPicker){
            let current = languages[row]
            self.selectedPrimaryLanguage = current
            updateContinueGCPrimaryLang()
        } else {
            let current = languages[row]
            self.selectedSecondaryLanguage = current
            updateContinueGCSecondaryLang()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: languages[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    private func updateContinueGCPrimaryLang(){
        if(self.selectedPrimaryLanguage == "none" || self.selectedPrimaryLanguage.isEmpty){
            self.gcContinueButton.alpha = 0.4
            self.gcContinueButton.isUserInteractionEnabled = false
        } else {
            UIView.animate(withDuration: 0.4, animations: {
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
        self.secondLanguage = languages
        if(secondLanguage.contains(self.selectedPrimaryLanguage)){
            self.secondLanguage.remove(at: secondLanguage.index(of: self.selectedPrimaryLanguage)!)
        }
        self.secondaryPicker.delegate = self
        self.secondaryPicker.dataSource = self
        
        let layoutAnim2 = CGAffineTransform(translationX: -50, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
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
        locationManager?.requestWhenInUseAuthorization()
    }
    
    @objc private func advanceToLocation(){
        let layoutOut = CGAffineTransform(translationX: -50, y: 0)
        UIView.animate(withDuration: 0.8, animations: {
            self.languageLayout.alpha = 0
            self.languageLayout.transform = layoutOut
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                   self.locationLayout.alpha = 1
                   self.locationLayout.transform = layoutOut
                    self.languageLayout.isUserInteractionEnabled = false
                    self.locationLayout.isUserInteractionEnabled = true
                    self.locationAnimation.play()
                    
                    self.allowLocation.addTarget(self, action: #selector(self.requestLocation), for: .touchUpInside)
                    self.refuseLocation.addTarget(self, action: #selector(self.advanceToGames), for: .touchUpInside)
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    @objc private func advanceToGames(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.child("primaryLanguage").setValue(self.selectedPrimaryLanguage)
        ref.child("secondaryLanguage").setValue(self.selectedSecondaryLanguage)
        ref.child("selectedAge").setValue(self.selectedAge)
        
        if(self.locationLat != 0.0){
            currentUser!.userLat = self.locationLat
            currentUser!.userLong = self.locationLong
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            geoFire.setLocation(CLLocation(latitude: self.locationLat, longitude: self.locationLong), forKey: currentUser!.uId)
        }
        
        self.performSegue(withIdentifier: "games", sender: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.locationLat = (manager.location?.coordinate.latitude)!
            self.locationLong = (manager.location?.coordinate.longitude)!
            
            advanceToGames()
        } else {
            advanceToGames()
        }
    }
}

class AgeTapGesture: UITapGestureRecognizer {
    var age = String()
}
