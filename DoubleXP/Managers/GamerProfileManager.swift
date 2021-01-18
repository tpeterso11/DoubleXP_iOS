//
//  GamerProfileManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class GamerProfileManager{
    
    func getGamerTag(user: User) -> String{
        if(!user.gamerTag.isEmpty){
            return user.gamerTag
        } else if(!user.gamerTags.isEmpty){
            return (user.gamerTags[0].gamerTag)
        } else{
            return ""
        }
    }
    
    func getAllTags(user: User) -> [String]{
        var tags = [String]()
        
        for profile in user.gamerTags{
            tags.append(profile.gamerTag)
        }
        
        return tags
    }
    
    func currentUserHasGamertagAvailable() -> Bool {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        if(user != nil){
            for gamerProfile in user!.gamerTags{
                if(!gamerProfile.gamerTag.isEmpty){
                    return true
                }
            }
        }
        
        return !user!.gamerTag.isEmpty
    }
    
    func gamertagBelongsToUser(gamerTag: String) -> Bool {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        if(user != nil){
            for gamerProfile in user!.gamerTags{
                if(gamerProfile.gamerTag == gamerTag){
                    return true
                }
            }
        }
        
        return user!.gamerTag == gamerTag
    }
}
