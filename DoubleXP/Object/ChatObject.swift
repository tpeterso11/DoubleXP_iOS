//
//  ChatObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/7/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation

class ChatObject: NSObject, NSCoding {

    var _chatUrl = ""
    var chatUrl:String {
        get {
            return (_chatUrl)
        }
        set (newVal) {
            _chatUrl = newVal
        }
    }

    var _otherUser = ""
    var otherUser: String {
        get {
            return (_otherUser)
        }
        set (newVal) {
            _otherUser = newVal
        }
    }
    
    var _otherUserId = ""
    var otherUserId: String {
        get {
            return (_otherUserId)
        }
        set (newVal) {
            _otherUserId = newVal
        }
    }

    init(chatUrl: String, otherUser: String)
    {
        super.init()
        self.chatUrl = chatUrl
        self.otherUser = otherUser
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.chatUrl = (decoder.decodeObject(forKey: "chatUrl") as! String)
        self.otherUser = (decoder.decodeObject(forKey: "otherUser") as! String)
        self.otherUserId = (decoder.decodeObject(forKey: "otherUserId") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.chatUrl, forKey: "chatUrl")
        coder.encode(self.otherUser, forKey: "otherUser")
        coder.encode(self.otherUser, forKey: "otherUserId")
    }
}

