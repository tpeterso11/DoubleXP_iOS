//
//  GamerConnectGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class GamerConnectGame: NSObject, NSCoding {
    var _imageUrl:String? = nil
    var imageUrl:String {
        get {
            return (_imageUrl)!
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    var _gameName:String? = nil
    var gameName:String {
        get {
            return (_gameName)!
        }
        set (newVal) {
            _gameName = newVal
        }
    }
    
    var _developer:String? = nil
    var developer:String {
        get {
            return (_developer)!
        }
        set (newVal) {
            _developer = newVal
        }
    }
    
    var _hook:String? = nil
    var hook:String {
        get {
            return (_hook)!
        }
        set (newVal) {
            _hook = newVal
        }
    }
    
    var _statsAvailable:Bool? = nil
    var statsAvailable:Bool {
        get {
            return (_statsAvailable)!
        }
        set (newVal) {
            _statsAvailable = newVal
        }
    }
    
    var _teamNeeds:[String]? = nil
    var teamNeeds:[String] {
        get {
            return (_teamNeeds)!
        }
        set (newVal) {
            _teamNeeds = newVal
        }
    }
    
    var _secondaryName:String? = nil
    var secondaryName:String {
        get {
            return (_secondaryName)!
        }
        set (newVal) {
            _secondaryName = newVal
        }
    }
    
    init(imageUrl: String, gameName: String, developer: String, hook: String, statsAvailable: Bool, teamNeeds: [String])
    {
        super.init()
        self.imageUrl = imageUrl
        self.gameName = gameName
        self.developer  = developer
        self.hook = hook
        self.statsAvailable = statsAvailable
        self.teamNeeds = teamNeeds
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.developer = (decoder.decodeObject(forKey: "developer") as! String)
        self.hook = (decoder.decodeObject(forKey: "hook") as! String)
        self.statsAvailable = (decoder.decodeObject(forKey: "statsAvailable") as! Bool)
        self.teamNeeds = (decoder.decodeObject(forKey: "teamNeeds") as! [String])
        self.secondaryName = (decoder.decodeObject(forKey: "secondaryName") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.developer, forKey: "developer")
        coder.encode(self.hook, forKey: "hook")
        coder.encode(self.statsAvailable, forKey: "statsAvailable")
        coder.encode(self.teamNeeds, forKey: "teamNeeds")
        coder.encode(self.secondaryName, forKey: "secondaryName")
    }
}
