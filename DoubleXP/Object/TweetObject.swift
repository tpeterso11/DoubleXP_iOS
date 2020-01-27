//
//  TweetObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class TweetObject: NSObject, NSCoding {
    var _handle:String? = nil
    var handle:String {
        get {
            return (_handle)!
        }
        set (newVal) {
            _handle = newVal
        }
    }
    
    var _tweet:String? = nil
    var tweet:String {
        get {
            return (_tweet)!
        }
        set (newVal) {
            _tweet = newVal
        }
    }
    
    var _url:String? = nil
    var url:String {
        get {
            return (_url)!
        }
        set (newVal) {
            _url = newVal
        }
    }
    
    init(handle: String, tweet: String)
    {
        super.init()
        self.handle = handle
        self.tweet = tweet
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.handle = (decoder.decodeObject(forKey: "handle") as! String)
        self.tweet = (decoder.decodeObject(forKey: "tweet") as! String)
        self.url = (decoder.decodeObject(forKey: "url") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.handle, forKey: "handle")
        coder.encode(self.tweet, forKey: "tweet")
        coder.encode(self.url, forKey: "url")
    }
}
