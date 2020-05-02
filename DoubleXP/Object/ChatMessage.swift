//
//  ChatMessage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/7/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SendBirdSDK

class ChatMessage: NSObject, NSCoding {

    var _message = ""
    var message:String {
        get {
            return (_message)
        }
        set (newVal) {
            _message = newVal
        }
    }
    
    var _recipientId = ""
    var recipientId:String {
        get {
            return (_recipientId)
        }
        set (newVal) {
            _recipientId = newVal
        }
    }

    var _sender = SBDSender()
    var sender: SBDSender{
        get {
            return (_sender)
        }
        set (newVal) {
            _sender = newVal
        }
    }
    
    var _data = ""
    var data: String {
        get {
            return (_data)
        }
        set (newVal) {
            _data = newVal
        }
    }

    var _timeStamp = ""
    var timeStamp: String {
        get {
            return (_timeStamp)
        }
        set (newVal) {
            _timeStamp = newVal
        }
    }
    
    var _timeStampMillis: Int64?
    var timeStampMillis: Int64? {
        get {
            return (_timeStampMillis)
        }
        set (newVal) {
            _timeStampMillis = newVal
        }
    }
    
    var _type = ""
    var type: String {
        get {
            return (_type)
        }
        set (newVal) {
            _type = newVal
        }
    }
    
    var _mentionedUsers = [User]()
    var mentionedUsers: [User] {
        get {
            return (_mentionedUsers)
        }
        set (newVal) {
            _mentionedUsers = newVal
        }
    }
    
    var _senderString = ""
    var senderString: String {
        get {
            return (_senderString)
        }
        set (newVal) {
            _senderString = newVal
        }
    }

    init(message: String, timeStamp: String)
    {
        super.init()
        self.message = message
        self.timeStamp = timeStamp
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.message = (decoder.decodeObject(forKey: "message") as! String)
        self.timeStamp = (decoder.decodeObject(forKey: "timeStamp") as! String)
        self.sender = (decoder.decodeObject(forKey: "sender") as! SBDSender)
        self.data = (decoder.decodeObject(forKey: "data") as! String)
        self.mentionedUsers = (decoder.decodeObject(forKey: "mentionedUsers") as! [User])
        self.senderString = (decoder.decodeObject(forKey: "senderString") as! String)
        self.type = (decoder.decodeObject(forKey: "type") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.message, forKey: "message")
        coder.encode(self.timeStamp, forKey: "timeStamp")
        coder.encode(self.sender, forKey: "sender")
        coder.encode(self.data, forKey: "data")
        coder.encode(self.mentionedUsers, forKey: "mentionedUsers")
        coder.encode(self.senderString, forKey: "senderString")
        coder.encode(self.type, forKey: "type")
    }
}
