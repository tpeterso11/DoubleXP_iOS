//
//  TeammateObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/29/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation

class TeammateObject: NSObject, NSCoding {

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
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.uid, forKey: "uid")
    }
}
