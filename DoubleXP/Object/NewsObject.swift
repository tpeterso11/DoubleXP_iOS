//
//  NewsObject.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class NewsObject: NSObject, NSCoding {
    var _title:String? = ""
    var title:String {
        get {
            return (_title)!
        }
        set (newVal) {
            _title = newVal
        }
    }
    
    var _type:String? = ""
    var type:String {
        get {
            return (_type)!
        }
        set (newVal) {
            _type = newVal
        }
    }
    
    var _subTitle:String? = ""
    var subTitle:String {
        get {
            return (_subTitle)!
        }
        set (newVal) {
            _subTitle = newVal
        }
    }
    
    var _author:String? = ""
    var author:String {
        get {
            return (_author)!
        }
        set (newVal) {
            _author = newVal
        }
    }
    
    var _storyText:String? = ""
       var storyText:String {
           get {
               return (_storyText)!
           }
           set (newVal) {
               _storyText = newVal
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
    
    var _likes: Int = 0
    var likes: Int {
        get {
            return (_likes)
        }
        set (newVal) {
            _likes = newVal
        }
    }
    
    var _dislikes: Int = 0
    var dislikes: Int {
        get {
            return (_dislikes)
        }
        set (newVal) {
            _dislikes = newVal
        }
    }
    
    var _videoUrl:String? = ""
    var videoUrl:String {
        get {
            return (_videoUrl)!
        }
        set (newVal) {
            _videoUrl = newVal
        }
    }
    
    var _imageUrl:String? = ""
    var imageUrl:String {
        get {
            return (_imageUrl)!
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    var _source:String? = ""
       var source:String {
           get {
               return (_source)!
           }
           set (newVal) {
               _source = newVal
           }
       }
    
    var _image: UIImage? = nil
    var image: UIImage {
        get {
            return (_image)!
        }
        set (newVal) {
            _image = newVal
        }
    }
    
    var _imageAdded: Bool = false
    var imageAdded: Bool {
        get {
            return (_imageAdded)
        }
        set (newVal) {
            _imageAdded = newVal
        }
    }
    
    var _uid:String? = ""
       var uid:String {
           get {
               return (_uid)!
           }
           set (newVal) {
               _uid = newVal
           }
       }
    
    init(title: String, author: String, storyText: String, imageUrl: String?)
    {
        super.init()
        self.title = title
        self.author = author
        self.storyText = storyText
        self.imageUrl = imageUrl ?? ""
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.title = (decoder.decodeObject(forKey: "title") as! String)
        self.author = (decoder.decodeObject(forKey: "author") as! String)
        self.storyText = (decoder.decodeObject(forKey: "storyText") as! String)
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.subTitle = (decoder.decodeObject(forKey: "subTitle") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.likes = (decoder.decodeObject(forKey: "likes") as! Int)
        self.dislikes = (decoder.decodeObject(forKey: "dislikes") as! Int)
        self.videoUrl = (decoder.decodeObject(forKey: "videoUrl") as! String)
        self.source = (decoder.decodeObject(forKey: "source") as! String)
        self.type = (decoder.decodeObject(forKey: "type") as! String)
        self.image = (decoder.decodeObject(forKey: "image") as! UIImage)
        self.imageAdded = (decoder.decodeObject(forKey: "imageAdded") as! Bool)
        self.uid = (decoder.decodeObject(forKey: "uid") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.author, forKey: "author")
        coder.encode(self.storyText, forKey: "storyText")
        coder.encode(self.title, forKey: "title")
        coder.encode(self.subTitle, forKey: "subTitle")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.likes, forKey: "likes")
        coder.encode(self.dislikes, forKey: "dislikes")
        coder.encode(self.videoUrl, forKey: "videoUrl")
        coder.encode(self.source, forKey: "source")
        coder.encode(self.source, forKey: "type")
        coder.encode(self.source, forKey: "image")
        coder.encode(self.source, forKey: "imageAdded")
        coder.encode(self.source, forKey: "uid")
    }
}
