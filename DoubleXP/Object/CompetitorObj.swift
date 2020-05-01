//
//  CompetitorObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class CompetitorObj: NSObject, NSCoding {

    var _gamerTag: String = ""
    var gamerTag: String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }
    
    var _uid: String = ""
    var uid: String {
        get {
            return (_uid)
        }
        set (newVal) {
            _uid = newVal
        }
    }
    
    var _console: String = ""
    var console: String {
        get {
            return (_console)
        }
        set (newVal) {
            _console = newVal
        }
    }
    
    var _verified: String = ""
    var verified: String {
        get {
            return (_verified)
        }
        set (newVal) {
            _verified = newVal
        }
    }
    
    var _school: String = ""
    var school: String {
        get {
            return (_school)
        }
        set (newVal) {
            _school = newVal
        }
    }
    
    var _date: String = ""
    var date: String {
        get {
            return (_date)
        }
        set (newVal) {
            _date = newVal
        }
    }

    init(gamerTag: String, uid: String, school: String, verified: String, date: String)
    {
        super.init()
        self.gamerTag = gamerTag
        self.uid = uid
        self.school = school
        self.verified = verified
        self.date = date
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
        self.school = (decoder.decodeObject(forKey: "school") as! String)
        self.verified = (decoder.decodeObject(forKey: "verified") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.school, forKey: "school")
        coder.encode(self.uid, forKey: "uid")
        coder.encode(self.verified, forKey: "verified")
        coder.encode(self.date, forKey: "date")
    }
}

