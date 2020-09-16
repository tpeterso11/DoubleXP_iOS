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
    
    func getGamerTagForGame(gameName: String) -> String {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        if(user != nil){
            for gamerProfile in user!.gamerTags{
                if(gamerProfile.game == gameName){
                    return gamerProfile.gamerTag
                }
            }
        }
        
        return user?.gamerTag ?? ""
    }
    
    func getGamerTagForOtherUserForGame(gameName: String, returnedUser: User) -> String{
        for gamerProfile in returnedUser.gamerTags{
            if(gamerProfile.game == gameName){
                return gamerProfile.gamerTag
            }
        }
        
        return returnedUser.gamerTag
    }
    
    func getGamerTagForOtherUserForGameProfiles(gameName: String, array: [GamerProfile]) -> String{
        for gamerProfile in array{
            if(gamerProfile.game == gameName){
                return gamerProfile.gamerTag
            }
        }
        
        return array[0].gamerTag
    }
    
    func getGamerTag(user: User) -> String{
        if(!user.gamerTags.isEmpty){
            return (user.gamerTags[0].gamerTag)
        }
        else{
            return user.gamerTag
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
