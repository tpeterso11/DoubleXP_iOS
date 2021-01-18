//
//  OnlineObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/20/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//
import Foundation
import CoreData

class OnlineObj: NSObject, NSCoding {
    var _tag = ""
    var tag:String {
        get {
            return (_tag)
        }
        set (newVal) {
            _tag = newVal
        }
    }
    
    var _id = ""
    var id:String {
        get {
            return (_id)
        }
        set (newVal) {
            _id = newVal
        }
    }
    
    var _friends = [String]()
    var friends : [String] {
        get {
            return (_friends)
        }
        set (newVal) {
            _friends = newVal
        }
    }
    
    var _date = ""
    var date : String {
        get {
            return (_date)
        }
        set (newVal) {
            _date = newVal
        }
    }
    
    init(tag: String, friends: [String], date: String, id: String)
    {
        super.init()
        self.tag = tag
        self.date = date
        self.friends = friends
        self.id = id
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.tag = (decoder.decodeObject(forKey: "tag") as! String)
        self.date = (decoder.decodeObject(forKey: "date") as! String)
        self.friends = (decoder.decodeObject(forKey: "friend") as! [String])
        self.id = (decoder.decodeObject(forKey: "id") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.tag, forKey: "tag")
        coder.encode(self.date, forKey: "date")
        coder.encode(self.friends, forKey: "friends")
        coder.encode(self.id, forKey: "id")
    }
    
}
