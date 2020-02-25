//
//  NewsObject.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class NewsObject: NSObject, NSCoding {
    var _imageUrl:String? = nil
    var imageUrl:String {
        get {
            return (_imageUrl)!
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    /*var _id:String = ""
    var id:String {
        get {
            return (_id)
        }
        set (newVal) {
            _id = newVal
        }
    }
    
    var _active:String = ""
    var active:String {
        get {
            return (_active)
        }
        set (newVal) {
            _active = newVal
        }
    }
    
    var _repeatAlarm:String = ""
    var repeatAlarm:String {
        get {
            return (_repeatAlarm)
        }
        set (newVal) {
            _repeatAlarm = newVal
        }
    }
    
    var _soundUrl: String = ""
    var soundUrl:String {
        get {
            return _soundUrl
        }
        set (newVal) {
            _soundUrl = newVal
        }
    }
    
    var _soundName: String = ""
    var soundName:String {
        get {
            return _soundName
        }
        set (newVal) {
            _soundName = newVal
        }
    }*/
    
    init(imageUrl: String)
    {
        super.init()
        self.imageUrl = imageUrl
        //self.soundUrl = url
        //self.soundName = soundName
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.imageUrl, forKey: "imageUrl")
        /*coder.encode(self.soundUrl, forKey: "soundUrl")
        coder.encode(self.soundName, forKey: "soundName")
        coder.encode(self.active, forKey: "active")
        coder.encode(self.repeatAlarm, forKey: "repeat")
        coder.encode(self.repeatAlarm, forKey: "id")*/
    }
}
