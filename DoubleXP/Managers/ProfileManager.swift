//
//  ProfileManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/2/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ProfileManage {
    func saveChanges(bio: String, games: [String], ps: Bool, pc: Bool, xBox: Bool, nintendo: Bool, profiles: [[String: String]], callbacks: CurrentProfileCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(user.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(!bio.isEmpty){
                    ref.child("Bio").setValue(bio)
                }
                
                if(!profiles.isEmpty){
                    if(!(profiles[0]["gamerTag"]!.isEmpty)){
                        if(snapshot.hasChild("gamerTag")){
                            let value = snapshot.value as? NSDictionary
                            let gamerTag = value?["gamerTag"] as? String ?? ""
                            
                            if(gamerTag.isEmpty || gamerTag == "undefined"){
                                ref.child("gamerTag").setValue(profiles[0]["gamerTag"]!)
                            }
                        }
                    }
                }
                
                ref.child("gamerTags").setValue(profiles)
                
                ref.child("games").setValue(games)
                
                let consoleDict = ["ps": ps, "xbox": xBox, "pc": pc, "nintendo": nintendo]
                ref.child("consoles").setValue(consoleDict)
                
                callbacks.changesComplete()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}
