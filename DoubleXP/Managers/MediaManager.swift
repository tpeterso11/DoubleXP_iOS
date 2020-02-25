//
//  MediaManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP

class MediaManager{
    
    func getMedia(){
        HTTP.GET("http://doublexpstorage.tech/app-json/dxp_reviews.json") { response in
        if let err = response.error {
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                
                if let resultArray = jsonObj!.value(forKey: "Games") as? NSArray {
                    for game in resultArray{
                        var hook = ""
                        var gameName = ""
                        var imageUrl = ""
                        var developer = ""
                        var secondaryName = ""
                        var statsAvailable = false
                        var teamNeeds = [String]()
                        if let gameDict = game as? NSDictionary {
                            hook = (gameDict.value(forKey: "hook") as? String)!
                            gameName = (gameDict.value(forKey: "gameName") as? String)!
                            imageUrl = (gameDict.value(forKey: "headerImageUrlXXHDPI") as? String)!
                            developer = (gameDict.value(forKey: "developer") as? String)!
                            statsAvailable = (gameDict.value(forKey: "statsAvailable") as? Bool)!
                            teamNeeds = (gameDict.value(forKey: "teamNeeds") as? [String]) ?? [String]()
                            secondaryName = (gameDict.value(forKey: "secondaryName") as? String ?? "")
                            
                            let newGame  = GamerConnectGame(imageUrl: imageUrl, gameName: gameName, developer: developer, hook: hook, statsAvailable: statsAvailable, teamNeeds: teamNeeds)
                            newGame.secondaryName = secondaryName
                            self.games.append(newGame)
                            }
                        }
                    }
                }
            }
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.gcGames = self.games
                
                let uId = UserDefaults.standard.string(forKey: "userId")
                if(uId != nil){
                    if(!uId!.isEmpty){
                        self.downloadDBRef(uid: uId!)
                        //self.performSegue(withIdentifier: "newLogin", sender: nil)
                    }
                    else{
                        self.performSegue(withIdentifier: "newLogin", sender: nil)
                    }
                }
                else{
                    self.performSegue(withIdentifier: "newLogin", sender: nil)
                }
            }
        }
    }
}
