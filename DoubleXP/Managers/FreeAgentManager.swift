//
//  FreeAgentManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FreeAgentManager {
    func deleteProfile(faObject: FreeAgentObject, indexPath: IndexPath, currentUser: User, callbacks: FACallbacks){
        //first, lets remove the profile
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if(snapshot.exists()){
                for profile in snapshot.children{
                    let currentProfile = profile as! DataSnapshot
                    let dict = currentProfile.value as! [String: Any]
                    let game = dict["game"] as? String ?? ""
                    
                    if(game == faObject.game){
                        ref.child((profile as! DataSnapshot).key).removeValue()
                        break
                    }
                }
                
                callbacks.updateCell(indexPath: indexPath)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func cacheProfiles(profiles: [FreeAgentObject]){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.freeAgentProfiles = profiles
    }
}
