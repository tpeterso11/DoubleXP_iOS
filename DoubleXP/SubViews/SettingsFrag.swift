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
    @IBOutlet weak var closeText: UILabel!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var findSwitch: RAMPaperSwitch!
    @IBOutlet weak var notificationSwitch: RAMPaperSwitch!
    @IBOutlet weak var findView: UIView!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var cogs: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged), for: UIControl.Event.valueChanged)
        findSwitch.addTarget(self, action: #selector(findSwitchChanged), for: UIControl.Event.valueChanged)
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        self.closeButton.isUserInteractionEnabled = true
        self.closeButton.addGestureRecognizer(backTap)
        self.closeText.isUserInteractionEnabled = true
        self.closeText.addGestureRecognizer(backTap)
        
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.backButtonClicked(self)
    }
    
    private func animateView(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.cogs.alpha = 0.1
            
            let top = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.3, animations: {
                self.findView.alpha = 1
                self.findView.transform = top
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, animations: {
                    self.noteView.transform = top
                    self.noteView.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.closeButton.transform = top
                        self.closeText.transform = top
                        self.closeButton.alpha = 1
                        self.closeText.alpha = 1
                    }, completion: nil)
                })
            })
        }
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
