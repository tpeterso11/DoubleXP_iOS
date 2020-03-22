//
//  TwitchChannelObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/15/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class TwitchChannelObj: NSObject, NSCoding {
    var _gameName:String = ""
    var gameName:String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
        }
    }
    
    var _developer: String = ""
    var developer: String {
        get {
            return (_developer)
        }
        set (newVal) {
            _developer = newVal
        }
    }
    
    var _developerLogoLightUrl: String = ""
    var developerLogoLightUrl: String {
        get {
            return (_developerLogoLightUrl)
        }
        set (newVal) {
            _developerLogoLightUrl = newVal
        }
    }
    
    var _developerLogoDarkUrl: String = ""
    var developerLogoDarkUrl: String {
        get {
            return (_developerLogoDarkUrl)
        }
        set (newVal) {
            _developerLogoDarkUrl = newVal
        }
    }
    
    var _gameDescription: String = ""
    var gameDescription: String {
        get {
            return (_gameDescription)
        }
        set (newVal) {
            _gameDescription = newVal
        }
    }
    
    var _imageUrlIOS: String = ""
    var imageUrlIOS: String {
        get {
            return (_imageUrlIOS)
        }
        set (newVal) {
            _imageUrlIOS = newVal
        }
    }
    
    var _twitchID: String = ""
    var twitchID: String {
        get {
            return (_twitchID)
        }
        set (newVal) {
            _twitchID = newVal
        }
    }
    
    var _isGCGame: String = ""
    var isGCGame: String {
        get {
            return (_isGCGame)
        }
        set (newVal) {
            _isGCGame = newVal
        }
    }
    
    var _gcGameName: String = ""
    var gcGameName: String {
        get {
            return (_gcGameName)
        }
        set (newVal) {
            _gcGameName = newVal
        }
    }
    
    init(gameName: String, imageUrIOS: String, twitchID: String)
    {
        super.init()
        self.gameName = gameName
        self.imageUrlIOS = imageUrIOS
        self.twitchID = twitchID
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.developer = (decoder.decodeObject(forKey: "developer") as! String)
        self.developerLogoDarkUrl = (decoder.decodeObject(forKey: "developerLogoDarkUrl") as! String)
        self.developerLogoLightUrl = (decoder.decodeObject(forKey: "developerLogoLightUrl") as! String)
        self.gameDescription = (decoder.decodeObject(forKey: "gameDescription") as! String)
        self.imageUrlIOS = (decoder.decodeObject(forKey: "imageUrlIOS") as! String)
        self.twitchID = (decoder.decodeObject(forKey: "twitchID") as! String)
        self.isGCGame = (decoder.decodeObject(forKey: "isGCGame") as! String)
        self.gcGameName = (decoder.decodeObject(forKey: "gcGameName") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.developer, forKey: "developer")
        coder.encode(self.developerLogoDarkUrl, forKey: "developerLogoDarkUrl")
        coder.encode(self.developerLogoLightUrl, forKey: "developerLogoLightUrl")
        coder.encode(self.gameDescription, forKey: "gameDescription")
        coder.encode(self.imageUrlIOS, forKey: "imageUrlIOS")
        coder.encode(self.twitchID, forKey: "twitchID")
        coder.encode(self.isGCGame, forKey: "isGCGame")
        coder.encode(self.gcGameName, forKey: "gcGameName")
    }
}
