//
//  BadgeObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

class BadgeObj: NSObject, NSCoding {

    var _badgeName = ""
    var badgeName:String {
        get {
            return (_badgeName)
        }
        set (newVal) {
            _badgeName = newVal
        }
    }
    
    var _badgeDesc = ""
    var badgeDesc:String {
        get {
            return (_badgeDesc)
        }
        set (newVal) {
            _badgeDesc = newVal
        }
    }

    init(badge: String, badgeDesc: String)
    {
        super.init()
        self.badgeName = badge
        self.badgeDesc = badgeDesc
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.badgeName = (decoder.decodeObject(forKey: "badgeName") as! String)
        self.badgeDesc = (decoder.decodeObject(forKey: "badgeDesc") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.badgeName, forKey: "badgeName")
        coder.encode(self.badgeDesc, forKey: "badgeDesc")
    }
}
