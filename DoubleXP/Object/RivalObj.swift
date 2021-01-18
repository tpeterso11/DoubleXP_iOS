//
//  RivalObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class RivalObj: NSObject, NSCoding {
    var _gamerTag = ""
    var gamerTag:String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }
    
    var _game = ""
    var game:String {
        get {
            return (_game)
        }
        set (newVal) {
            _game = newVal
        }
    }
    
    var _type = "" //use for time-frame until I feel like fixing.
    var type:String {
        get {
            return (_type)
        }
        set (newVal) {
            _type = newVal
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
    
    var _id = ""
    var id: String {
        get {
            return (_id)
        }
        set (newVal) {
            _id = newVal
        }
    }
    
    init(gamerTag: String, date: String, game: String, uid: String, type: String, id: String)
    {
        super.init()
        self.gamerTag = gamerTag
        self.date = date
        self.game = game
        self.uid = uid
        self.type = type
        self.id = id
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.game = (decoder.decodeObject(forKey: "game") as! String)
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
        self.type = (decoder.decodeObject(forKey: "type") as! String)
        self.id = (decoder.decodeObject(forKey: "id") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.uid, forKey: "uid")
        coder.encode(self.game, forKey: "game")
        coder.encode(self.type, forKey: "type")
        coder.encode(self.id, forKey: "id")
    }
    
}
