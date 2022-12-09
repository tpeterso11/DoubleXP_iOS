//
//  CompEntryObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/15/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class CompEntryObject : NSObject, NSCoding {
    var _uid:String? = ""
    var uid:String {
        get {
            return (_uid)!
        }
        set (newVal) {
            _uid = newVal
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
    
    var _imgUrl:String? = ""
    var imgUrl:String {
        get {
            return (_imgUrl)!
        }
        set (newVal) {
            _imgUrl = newVal
        }
    }
    
    var _compId:String? = ""
    var compId:String {
        get {
            return (_compId)!
        }
        set (newVal) {
            _compId = newVal
        }
    }
    
    var _voteCount:Int? = 0
       var voteCount:Int {
           get {
               return (_voteCount)!
           }
           set (newVal) {
               _voteCount = newVal
           }
       }
    
    var _votersUids:[String]? = [String]()
       var votersUids:[String] {
           get {
               return (_votersUids)!
           }
           set (newVal) {
               _votersUids = newVal
           }
       }
    
    var _passUids:[String]? = [String]()
       var passUids:[String] {
           get {
               return (_passUids)!
           }
           set (newVal) {
               _passUids = newVal
           }
       }
    
    var _currentPosition:CLong? = -1
       var currentPosition:CLong {
           get {
               return (_currentPosition)!
           }
           set (newVal) {
               _currentPosition = newVal
           }
       }
    
    var _lastPosition: CLong? = -1
       var lastPosition: CLong {
           get {
               return (_lastPosition)!
           }
           set (newVal) {
               _lastPosition = newVal
           }
       }
    
    var _gamerTag: String? = ""
       var gamerTag: String {
           get {
               return (_gamerTag)!
           }
           set (newVal) {
               _gamerTag = newVal
           }
       }
    
    var _dbKey:String? = ""
    var dbKey:String {
        get {
            return (_dbKey)!
        }
        set (newVal) {
            _dbKey = newVal
        }
    }
    
    init(uid: String, youtubeId: String, imgUrl: String, compId: String, voteCount: Int, votersUids: [String], currentPosition: CLong, lastPosition: CLong, gamerTag: String, dbKey: String, passUids: [String])
    {
        super.init()
        self.uid = uid
        self.youtubeId = youtubeId
        self.imgUrl = imgUrl
        self.compId = compId
        self.voteCount = voteCount
        self.votersUids = votersUids
        self.currentPosition = currentPosition
        self.lastPosition = lastPosition
        self.gamerTag = gamerTag
        self.dbKey = dbKey
        self.passUids = passUids
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
        self.youtubeId = (decoder.decodeObject(forKey: "youtubeId") as! String)
        self.imgUrl = (decoder.decodeObject(forKey: "imgUrl") as! String)
        self.compId = (decoder.decodeObject(forKey: "compId") as! String)
        self.voteCount = (decoder.decodeObject(forKey: "voteCount") as! Int)
        self.votersUids = (decoder.decodeObject(forKey: "votersUids") as! [String])
        self.currentPosition = (decoder.decodeObject(forKey: "currentPosition") as! CLong)
        self.lastPosition = (decoder.decodeObject(forKey: "lastPosition") as! CLong)
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.dbKey = (decoder.decodeObject(forKey: "dbKey") as! String)
        self.passUids = (decoder.decodeObject(forKey: "passUids") as! [String])
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.uid, forKey: "uid")
        coder.encode(self.youtubeId, forKey: "youtubeId")
        coder.encode(self.imgUrl, forKey: "imgUrl")
        coder.encode(self.compId, forKey: "compId")
        coder.encode(self.voteCount, forKey: "voteCount")
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.lastPosition, forKey: "lastPosition")
        coder.encode(self.votersUids, forKey: "votersUids")
        coder.encode(self.currentPosition, forKey: "currentPosition")
        coder.encode(self.dbKey, forKey: "dbKey")
        coder.encode(self.passUids, forKey: "passUids")
    }
}
