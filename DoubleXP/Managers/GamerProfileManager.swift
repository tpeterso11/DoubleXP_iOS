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
    
    func getGamerTagForGame(gameName: String) -> String{
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
}
