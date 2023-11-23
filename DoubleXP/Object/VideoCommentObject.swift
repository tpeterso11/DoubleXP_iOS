//
//  VideoCommentObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/29/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation

class VideoCommentObject: NSObject, NSCoding {

    var _message = ""
    var message:String {
        get {
            return (_message)
        }
        set (newVal) {
            _message = newVal
        }
    }
    
    var _commentId = ""
    var commentId:String {
        get {
            return (_commentId)
        }
        set (newVal) {
            _commentId = newVal
        }
    }

    var _senderUid = ""
    var senderUid: String {
        get {
            return (_senderUid)
        }
        set (newVal) {
            _senderUid = newVal
        }
    }
    
    var _senderGamerTag = ""
    var senderGamerTag: String {
        get {
            return (_senderGamerTag)
        }
        set (newVal) {
            _senderGamerTag = newVal
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
    
    var _upvotes = [String]()
    var upvotes: [String] {
        get {
            return (_upvotes)
        }
        set (newVal) {
            _upvotes = newVal
        }
    }
    
    var _downVotes = [String]()
    var downVotes: [String] {
        get {
            return (_downVotes)
        }
        set (newVal) {
            _downVotes = newVal
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
        self.commentId = (decoder.decodeObject(forKey: "commentId") as! String)
        self.senderUid = (decoder.decodeObject(forKey: "senderUid") as! String)
        self.senderGamerTag = (decoder.decodeObject(forKey: "senderGamerTag") as! String)
        self.timeStamp = (decoder.decodeObject(forKey: "timeStamp") as! String)
        self.upvotes = (decoder.decodeObject(forKey: "upvotes") as! [String])
        self.downVotes = (decoder.decodeObject(forKey: "downVotes") as! [String])
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.message, forKey: "message")
        coder.encode(self.timeStamp, forKey: "timeStamp")
        coder.encode(self.commentId, forKey: "commentId")
        coder.encode(self.senderUid, forKey: "senderUid")
        coder.encode(self.senderGamerTag, forKey: "senderGamerTag")
        coder.encode(self.upvotes, forKey: "upvotes")
        coder.encode(self.downVotes, forKey: "downVotes")
    }
}

