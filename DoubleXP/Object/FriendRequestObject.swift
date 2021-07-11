//
//  FriendRequestObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/18/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class FriendRequestObject: GenericRequestObject, NSCoding {
    var _gamerTag = ""
    var gamerTag:String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }
    
    var _date = ""
    var date: String {
        get {
            return (_date)
        }
        set (newVal) {
            _date = newVal
        }
    }
    
    var _uid = ""
    var uid: String {
        get {
            return (_uid)
        }
        set (newVal) {
            _uid = newVal
        }
    }
    
    var _youtubeConnect = ""
    var youtubeConnect: String {
        get {
            return (_youtubeConnect)
        }
        set (newVal) {
            _youtubeConnect = newVal
        }
    }
    
    var _twitchConnect = ""
    var twitchConnect: String {
        get {
            return (_twitchConnect)
        }
        set (newVal) {
            _twitchConnect = newVal
        }
    }
    
    var _discordConnect = ""
    var discordConnect: String {
        get {
            return (_discordConnect)
        }
        set (newVal) {
            _discordConnect = newVal
        }
    }
    
    var _instagramConnect = ""
    var instagramConnect: String {
        get {
            return (_instagramConnect)
        }
        set (newVal) {
            _instagramConnect = newVal
        }
    }
    
    init(gamerTag: String, date: String, uid: String)
    {
        super.init()
        self.gamerTag = gamerTag
        self.date = date
        self.uid = uid
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.instagramConnect = (decoder.decodeObject(forKey: "instagramConnect") as! String)
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
        self.discordConnect = (decoder.decodeObject(forKey: "discordConnect") as! String)
        self.twitchConnect = (decoder.decodeObject(forKey: "twitchConnect") as! String)
        self.youtubeConnect = (decoder.decodeObject(forKey: "youtubeConnect") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.uid, forKey: "uid")
        coder.encode(self.instagramConnect, forKey: "instagramConnect")
        coder.encode(self.discordConnect, forKey: "discordConnect")
        coder.encode(self.twitchConnect, forKey: "twitchConnect")
        coder.encode(self.youtubeConnect, forKey: "youtubeConnect")
    }
    
}
