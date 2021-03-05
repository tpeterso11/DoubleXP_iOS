//
//  SocialConnectModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/28/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class SocialConnectModal : UIViewController, UITextFieldDelegate {
    @IBOutlet weak var connectHeader: UILabel!
    @IBOutlet weak var connectSub: UILabel!
    @IBOutlet weak var socialEntry: UITextField!
    @IBOutlet weak var socialSubmit: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var thingType = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(thingType.isEmpty){
            self.dismiss(animated: true, completion: nil)
            return
        }
        if(thingType == "twitch"){
            connectHeader.text = "connect twitch"
            connectSub.text = "all we need is your account id, and we can add twitch to your profile."
            socialEntry.placeholder = "account id"
        } else if(thingType == "discord") {
            connectHeader.text = "connect discord"
            connectSub.text = "all we need is your handle, and we can add your discord to your profile."
            socialEntry.placeholder = "handle"
        }  else {
            connectHeader.text = "connect instagram"
            connectSub.text = "all we need is your username, and we can add insta to your profile."
            socialEntry.placeholder = "username"
        }
        
        //let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        //tap.cancelsTouchesInView = false
        //view.addGestureRecognizer(tap)
        self.socialEntry.delegate = self
        self.socialEntry.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        self.cancelButton.addTarget(self, action: #selector(closeIt), for: .touchUpInside)
    }
    
    @objc func sendPayload(){
        if(socialEntry.text != nil){
            if(!self.socialEntry.text!.isEmpty){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
                if(thingType == "twitch"){
                    ref.child("twitchConnect").setValue(socialEntry.text!)
                    appDelegate.currentUser!.twitchConnect = socialEntry.text!
                }
                if(thingType == "discord"){
                    ref.child("discordConnect").setValue(socialEntry.text!)
                    appDelegate.currentUser!.discordConnect = socialEntry.text!
                }
                if(thingType == "instagram"){
                    ref.child("instagramConnect").setValue(socialEntry.text!)
                    appDelegate.currentUser!.instagramConnect = socialEntry.text!
                }
                appDelegate.currentProfileFrag?.dismissModal()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func closeIt(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentProfileFrag?.dismissModal()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(self.socialEntry.text!.count > 3){
            self.socialSubmit.alpha = 1
            self.socialSubmit.addTarget(self, action: #selector(sendPayload), for: .touchUpInside)
            self.socialSubmit.isUserInteractionEnabled = true
        } else {
            self.socialSubmit.alpha = 0.3
            self.socialSubmit.isUserInteractionEnabled = false
        }
    }
    
}
