//
//  YoutubeVideoObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/14/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class YoutubeVideoObj: NSObject, NSCoding {
    var _title:String? = ""
    var title:String {
        get {
            return (_title)!
        }
        set (newVal) {
            _title = newVal
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
    
    var _youtubeFavorite:String? = ""
    var youtubeFavorite:String {
        get {
            return (_youtubeFavorite)!
        }
        set (newVal) {
            _youtubeFavorite = newVal
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
    
    init(title: String, videoOwnerGamerTag: String, videoOwnerUid: String, youtubeFavorite: String, date: String, youtubeId: String, imgUrl: String)
    {
        super.init()
        self.title = title
        self.videoOwnerGamerTag = videoOwnerGamerTag
        self.videoOwnerUid = videoOwnerUid
        self.youtubeFavorite = youtubeFavorite
        self.date = date
        self.youtubeId = youtubeId
        self.youtubeImg = imgUrl
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.title = (decoder.decodeObject(forKey: "title") as! String)
        self.videoOwnerGamerTag = (decoder.decodeObject(forKey: "videoOwnerGamerTag") as! String)
        self.videoOwnerUid = (decoder.decodeObject(forKey: "videoOwnerUid") as! String)
        self.youtubeFavorite = (decoder.decodeObject(forKey: "youtubeFavorite") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.youtubeId = (decoder.decodeObject(forKey: "youtubeId") as! String)
        self.youtubeImg = (decoder.decodeObject(forKey: "youtubeImg") as! String)
        self.downVotes = (decoder.decodeObject(forKey: "downVotes") as! [String])
        self.upVotes = (decoder.decodeObject(forKey: "upVotes") as! [String])
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.title, forKey: "title")
        coder.encode(self.videoOwnerGamerTag, forKey: "videoOwnerGamerTag")
        coder.encode(self.videoOwnerUid, forKey: "videoOwnerUid")
        coder.encode(self.youtubeFavorite, forKey: "youtubeFavorite")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.downVotes, forKey: "downVotes")
        coder.encode(self.upVotes, forKey: "upVotes")
        coder.encode(self.youtubeId, forKey: "youtubeId")
        coder.encode(self.youtubeImg, forKey: "youtubeImg")
    }
}
