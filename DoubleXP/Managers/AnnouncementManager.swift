//
//  AnnouncementManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class AnnouncementManager {
    var announcments = [AnnouncementObj]()
    
    func shouldSeeAnnouncement(user: User, announcement: AnnouncementObj) -> Bool{
        for uid in announcement.announcementAudience {
            if(uid == "all"){
                if(user.viewedAnnouncements.contains(announcement.announcementId)){
                    if(announcement.announcementDuration == "0"){
                        return false
                    }
                }
                
                var contained = false
                for game in user.games {
                    if(announcement.announcementGames.contains(game)){
                        contained = true
                        break
                    }
                }
                if(!contained){
                    return false
                }
                
                if(announcement.announcementActive == "false"){
                    return false
                }
                
                
                return true
            }
            else {
                if(user.viewedAnnouncements.contains(announcement.announcementId)){
                    if(announcement.announcementDuration == "0"){
                        return false
                    }
                }
                
                if(!announcement.announcementAudience.contains(user.uId)){
                    return false
                }
                
                if(announcement.announcementActive == "false"){
                    return false
                }
                
                return true
            }
        }
        return false
    }
    
}
