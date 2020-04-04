//
//  MeesageQueueObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

import CoreData

class MeesageQueueObj: NSObject, NSCoding {

    var _senderId: String = ""
    var senderId: String {
        get {
            return (_senderId)
        }
        set (newVal) {
            _senderId = newVal
        }
    }
    
    var _type: String = ""
    var type: String {
        get {
            return (_type)
        }
        set (newVal) {
            _type = newVal
        }
    }

    init(senderId: String, type: String)
    {
        super.init()
        self.senderId = senderId
        self.type = type
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.senderId = (decoder.decodeObject(forKey: "senderId") as! String)
        self.type = (decoder.decodeObject(forKey: "type") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.senderId, forKey: "senderId")
        coder.encode(self.type, forKey: "type")
    }
}
