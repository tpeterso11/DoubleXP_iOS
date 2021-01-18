//
//  EpisodeObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class EpisodeObj: NSObject, NSCoding {
    var _name = ""
    var name:String {
        get {
            return (_name)
        }
        set (newVal) {
            _name = newVal
        }
    }
    
    var _imageUrl = ""
    var imageUrl : String {
        get {
            return (_imageUrl)
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    var _mediaType = ""
    var mediaType:String {
        get {
            return (_mediaType)
        }
        set (newVal) {
            _mediaType = newVal
        }
    }
    
    var _sub = ""
    var sub: String {
        get {
            return (_sub)
        }
        set (newVal) {
            _sub = newVal
        }
    }
    
    var _url = ""
    var url:String {
        get {
            return (_url)
        }
        set (newVal) {
            _url = newVal
        }
    }
    
    var _featuring = ""
       var featuring:String {
           get {
               return (_featuring)
           }
           set (newVal) {
               _featuring = newVal
           }
    }
    
    var _mediaId = ""
    var mediaId:String {
        get {
            return (_mediaId)
        }
        set (newVal) {
            _mediaId = newVal
        }
    }
    
    init(mediaId: String, name: String, imageUrl: String, mediaType: String, sub: String, url: String,
         featuring: String)
    {
        super.init()
        self.mediaId = mediaId
        self.name = name
        self.imageUrl = imageUrl
        self.mediaType = mediaType
        self.sub = sub
        self.url = url
        self.featuring = featuring
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.mediaId = (decoder.decodeObject(forKey: "mediaId") as! String)
        self.name = (decoder.decodeObject(forKey: "name") as! String)
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.mediaType = (decoder.decodeObject(forKey: "mediaType") as! String)
        self.sub = (decoder.decodeObject(forKey: "sub") as! String)
        self.url = (decoder.decodeObject(forKey: "url") as! String)
        self.featuring = (decoder.decodeObject(forKey: "featuring") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.mediaId, forKey: "mediaId")
        coder.encode(self.name, forKey: "name")
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.mediaType, forKey: "mediaType")
        coder.encode(self.sub, forKey: "sub")
        coder.encode(self.url, forKey: "url")
        coder.encode(self.featuring, forKey: "featuring")
    }
    
}
