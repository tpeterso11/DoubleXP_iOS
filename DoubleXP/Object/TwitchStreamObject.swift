//
//  TwitchStreamObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class TwitchStreamObject: NSObject, NSCoding {
    var _handle:String? = nil
    var handle:String {
        get {
            return (_handle)!
        }
        set (newVal) {
            _handle = newVal
        }
    }
    
    var _thumbnail:String? = nil
    var thumbnail:String {
        get {
            return (_thumbnail)!
        }
        set (newVal) {
            _thumbnail = newVal
        }
    }
    
    var _startedAt:String? = nil
    var startedAt:String {
        get {
            return (_startedAt)!
        }
        set (newVal) {
            _startedAt = newVal
        }
    }
    
    var _id:String? = nil
    var id:String {
       get {
           return (_id)!
       }
       set (newVal) {
           _id = newVal
       }
    }
    
    var _title:String? = nil
    var title:String {
       get {
           return (_title)!
       }
       set (newVal) {
           _title = newVal
       }
    }
    
    var _userId:String? = nil
    var userId:String {
       get {
           return (_userId)!
       }
       set (newVal) {
           _userId = newVal
       }
    }
    
    var _type:String? = nil
    var type:String {
       get {
           return (_type)!
       }
       set (newVal) {
           _type = newVal
       }
    }
    
    var _viewerCount: Int = 0
    var viewerCount: Int {
       get {
           return (_viewerCount)
       }
       set (newVal) {
           _viewerCount = newVal
       }
    }
    
    init(handle: String)
    {
        super.init()
        self.handle = handle
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.handle = (decoder.decodeObject(forKey: "handle") as! String)
        self.startedAt = (decoder.decodeObject(forKey: "startedAt") as! String)
        self.thumbnail = (decoder.decodeObject(forKey: "thumbnail") as! String)
        self.id = (decoder.decodeObject(forKey: "id") as! String)
        self.title = (decoder.decodeObject(forKey: "title") as! String)
        self.userId = (decoder.decodeObject(forKey: "userId") as! String)
        self.type = (decoder.decodeObject(forKey: "type") as! String)
        self.viewerCount = (decoder.decodeObject(forKey: "viewerCount") as! Int)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.handle, forKey: "handle")
        coder.encode(self.startedAt, forKey: "startedAt")
        coder.encode(self.id, forKey: "id")
        coder.encode(self.title, forKey: "title")
        coder.encode(self.userId, forKey: "userId")
        coder.encode(self.type, forKey: "type")
        coder.encode(self.viewerCount, forKey: "viewerCount")
    }
}
