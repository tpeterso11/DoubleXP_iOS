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
    var wannaPlayCachedUser: User?
    var moreOptionsCachedUser: User?
    
    func updateTempRivalsDB(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(user.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var rivals = [RivalObj]()
            if(snapshot.hasChild("currentTempRivals")){
                let pendingArray = snapshot.childSnapshot(forPath: "currentTempRivals")
                for rival in pendingArray.children{
                    let currentObj = rival as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let date = dict?["date"] as? String ?? ""
                    let tag = dict?["gamerTag"] as? String ?? ""
                    let game = dict?["game"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    let dbType = dict?["type"] as? String ?? ""
                    let id = dict?["id"] as? String ?? ""
                    
                    let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                    
                    let calendar = Calendar.current
                    if(!date.isEmpty){
                        let dbDate = self.stringToDate(date)
                        
                        if(dbDate != nil){
                            let now = NSDate()
                            let formatter = DateFormatter()
                            formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                            let future = formatter.string(from: dbDate as Date)
                            let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validRival = (now as Date).compare(.isEarlier(than: dbTimeOut))
                            
                            if(dbTimeOut != nil){
                                if(validRival){
                                    rivals.append(request)
                                }
                            }
                        }
                    }
                }
                
                delegate.currentUser!.currentTempRivals = rivals
                
                var sendList = [[String: Any]]()
                for rival in rivals{
                    let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "type": rival.type] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("currentTempRivals").setValue(sendList)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func saveChanges(bio: String, gamertag: String?){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(user.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(!bio.isEmpty){
                    ref.child("bio").setValue(bio)
                    user.bio = bio
                }
                
                if(gamertag != nil){
                    ref.child("gamerTag").setValue(gamertag)
                    user.gamerTag = gamertag!
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return formatter.date(from: str)!
    }
}
