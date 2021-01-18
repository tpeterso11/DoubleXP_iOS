//
//  FAQuizComplete.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/23/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import SwiftNotificationCenter
import FBSDKCoreKit
import SPStorkController

class FAQuizComplete: ParentVC {
    @IBOutlet weak var finish: UIButton!
    @IBOutlet weak var logo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageName = "FAQuiz Complete"
        
        finish.layer.shadowColor = UIColor.black.cgColor
        finish.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        finish.layer.shadowRadius = 2.0
        finish.layer.shadowOpacity = 0.5
        finish.layer.masksToBounds = false
        finish.layer.shadowPath = UIBezierPath(roundedRect: finish.bounds, cornerRadius: finish.layer.cornerRadius).cgPath
        finish.addTarget(self, action: #selector(finishClicked), for: .touchUpInside)
    }
    
    private func saveQuizTaken(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        for profile in currentUser.gamerTags {
            if(profile.game == appDelegate.interviewManager.currentGCGame.gameName){
                profile.quizTaken = "true"
                
                let ref = Database.database().reference().child("Users").child(currentUser.uId)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.hasChild("gamerTags")){
                        let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentGame = dict?["game"] as? String ?? ""
                            if(currentGame == profile.game){
                                ref.child("gamerTags").child(currentObj.key).child("quizTaken").setValue("true")
                                
                                appDelegate.currentUpgradeController?.dismissModal()
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @objc func finishClicked(_ sender: AnyObject?) {
        saveQuizTaken()
    }
}
