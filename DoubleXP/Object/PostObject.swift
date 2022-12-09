//
//  PostObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/11/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class PostObject: NSObject, NSCoding {
    var _title:String? = ""
    var title:String {
        get {
            return (_title)!
        }
        set (newVal) {
            _title = newVal
        }
    }
    
    var _postId:String? = ""
    var postId:String {
        get {
            return (_postId)!
        }
        set (newVal) {
            _postId = newVal
        }
    }
    
    var _videoOwnerGamerTag:String? = ""
    var videoOwnerGamerTag:String {
        get {
            return (_videoOwnerGamerTag)!
        }
        set (newVal) {
            _videoOwnerGamerTag = newVal
        }
    }
    
    var _videoOwnerUid:String? = ""
    var videoOwnerUid:String {
        get {
            return (_videoOwnerUid)!
        }
        set (newVal) {
            _videoOwnerUid = newVal
        }
    }
    
    var _publicPost:String? = "" //boolean true/ false
    var publicPost:String {
        get {
            return (_publicPost)!
        }
        set (newVal) {
            _publicPost = newVal
        }
    }
    
    var _youtubeId:String? = ""
       var youtubeId:String {
           get {
               return (_youtubeId)!
           }
           set (newVal) {
               _youtubeId = newVal
           }
       }
    
    var _youtubeImg:String? = ""
       var youtubeImg:String {
           get {
               return (_youtubeImg)!
           }
           set (newVal) {
               _youtubeImg = newVal
           }
       }
    
    var _date:String? = ""
       var date:String {
           get {
               return (_date)!
           }
           set (newVal) {
               _date = newVal
           }
       }
    
    var _game:String? = ""
       var game:String {
           get {
               return (_game)!
           }
           set (newVal) {
               _game = newVal
           }
       }
    
    var _upVotes: [String]? = [String]()
       var upVotes: [String] {
           get {
               return (_upVotes)!
           }
           set (newVal) {
               _upVotes = newVal
           }
       }
    
    var _downVotes: [String]? = [String]()
       var downVotes: [String] {
           get {
               return (_downVotes)!
           }
           set (newVal) {
               _downVotes = newVal
           }
       }
    
    var _recipientIds: [String]? = [String]()
       var recipientIds: [String] {
           get {
               return (_recipientIds)!
           }
           set (newVal) {
               _recipientIds = newVal
           }
       }
    
    var _postConsole:String? = ""
       var postConsole:String {
           get {
               return (_postConsole)!
           }
           set (newVal) {
               _postConsole = newVal
           }
       }
    
    init(title: String, videoOwnerGamerTag: String, videoOwnerUid: String, publicPost: String, date: String, youtubeId: String, imgUrl: String, postConsole: String, game: String)
    {
        super.init()
        self.title = title
        self.videoOwnerGamerTag = videoOwnerGamerTag
        self.videoOwnerUid = videoOwnerUid
        self.publicPost = publicPost
        self.date = date
        self.youtubeId = youtubeId
        self.youtubeImg = imgUrl
        self.postConsole = postConsole
        self.game = game
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.title = (decoder.decodeObject(forKey: "title") as! String)
        self.videoOwnerGamerTag = (decoder.decodeObject(forKey: "videoOwnerGamerTag") as! String)
        self.videoOwnerUid = (decoder.decodeObject(forKey: "videoOwnerUid") as! String)
        self.publicPost = (decoder.decodeObject(forKey: "publicPost") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.youtubeId = (decoder.decodeObject(forKey: "youtubeId") as! String)
        self.youtubeImg = (decoder.decodeObject(forKey: "youtubeImg") as! String)
        self.downVotes = (decoder.decodeObject(forKey: "downVotes") as! [String])
        self.upVotes = (decoder.decodeObject(forKey: "upVotes") as! [String])
        self.recipientIds = (decoder.decodeObject(forKey: "recipientIds") as! [String])
        self.postConsole = (decoder.decodeObject(forKey: "postConsole") as! String)
        self.game = (decoder.decodeObject(forKey: "game") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.title, forKey: "title")
        coder.encode(self.videoOwnerGamerTag, forKey: "videoOwnerGamerTag")
        coder.encode(self.videoOwnerUid, forKey: "videoOwnerUid")
        coder.encode(self.publicPost, forKey: "publicPost")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.downVotes, forKey: "downVotes")
        coder.encode(self.upVotes, forKey: "upVotes")
        coder.encode(self.youtubeId, forKey: "youtubeId")
        coder.encode(self.youtubeImg, forKey: "youtubeImg")
        coder.encode(self.recipientIds, forKey: "recipientIds")
        coder.encode(self.postConsole, forKey: "postConsole")
        coder.encode(self.game, forKey: "game")
    }
}
