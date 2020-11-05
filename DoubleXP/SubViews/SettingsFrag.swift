//
//  SettingsFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/30/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import RAMPaperSwitch
import Firebase

class SettingsFrag: ParentVC{
    @IBOutlet weak var findSwitch: RAMPaperSwitch!
    @IBOutlet weak var notificationSwitch: RAMPaperSwitch!
    @IBOutlet weak var findView: UIView!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var cogs: UIImageView!
    @IBOutlet weak var mainView: UIView!
    //@IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged), for: UIControl.Event.valueChanged)
        findSwitch.addTarget(self, action: #selector(findSwitchChanged), for: UIControl.Event.valueChanged)
        //closeButton.addTarget(self, action: #selector(backButtonClicked), for: UIControl.Event.valueChanged)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentUser!.notifications == "true"){
            self.notificationSwitch.setOn(true, animated: false)
        }
        if(appDelegate.currentUser!.search == "true"){
            self.findSwitch.setOn(true, animated: false)
        }
        
        animateView()
    }
    
    @objc func backButtonClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func animateView(){
        UIView.animate(withDuration: 0.3, animations: {
            self.mainView.alpha = 1
        }, completion: nil)
    }
    
    @objc func notificationSwitchChanged(noteSwitch: UISwitch) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        
        if(noteSwitch.isOn){
            ref.child("notifications").setValue("true")
        }
        else{
            ref.child("notifications").setValue("false")
        }
    }
    
    @objc func findSwitchChanged(noteSwitch: UISwitch) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
           
        let ref = Database.database().reference().child("Users").child(appDelegate.currentUser!.uId)
        if(noteSwitch.isOn){
            ref.child("search").setValue("true")
        }
        else{
            ref.child("search").setValue("false")
        }
    }
}
