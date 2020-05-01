//
//  RecommendedUser.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class RecommendedUser: NSObject, NSCoding {

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

    init(gamerTag: String, uid: String)
    {
        super.init()
        self.gamerTag = gamerTag
        self.uid = uid
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.uid, forKey: "uid")
    }
}

