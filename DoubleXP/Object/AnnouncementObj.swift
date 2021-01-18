//
//  AnnouncementObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class AnnouncementObj: NSObject, NSCoding {
    var _announcementTitle = ""
    var announcementTitle:String {
        get {
            return (_announcementTitle)
        }
        set (newVal) {
            _announcementTitle = newVal
        }
    }
    
    var _announcementGames = [String]()
    var announcementGames : [String] {
        get {
            return (_announcementGames)
        }
        set (newVal) {
            _announcementGames = newVal
        }
    }
    
    var _announcementMessage = ""
    var announcementMessage:String {
        get {
            return (_announcementMessage)
        }
        set (newVal) {
            _announcementMessage = newVal
        }
    }
    
    var _announcementAudience = [String]()
    var announcementAudience:[String] {
        get {
            return (_announcementAudience)
        }
        set (newVal) {
            _announcementAudience = newVal
        }
    }
    
    var _announcementDuration = ""
    var announcementDuration:String {
        get {
            return (_announcementDuration)
        }
        set (newVal) {
            _announcementDuration = newVal
        }
    }
    
    var _announcementActive = ""
    var announcementActive:String {
        get {
            return (_announcementActive)
        }
        set (newVal) {
            _announcementActive = newVal
        }
    }
    
    var _announcementId = ""
    var announcementId:String {
        get {
            return (_announcementId)
        }
        set (newVal) {
            _announcementId = newVal
        }
    }
    
    var _announcementSender = ""
    var announcementSender:String {
        get {
            return (_announcementSender)
        }
        set (newVal) {
            _announcementSender = newVal
        }
    }
    
    var _announcementDetails = ""
    var announcementDetails:String {
        get {
            return (_announcementDetails)
        }
        set (newVal) {
            _announcementDetails = newVal
        }
    }
    
    init(announcementId: String, announcementTitle: String, announcementMessage: String, announcementActive: String, announcementGames: [String],
         announcementDuration: String, announcementAudience: [String], announcementSender:String, announcementDetails:String)
    {
        super.init()
        self.announcementTitle = announcementTitle
        self.announcementMessage = announcementMessage
        self.announcementActive = announcementActive
        self.announcementGames = announcementGames
        self.announcementDuration = announcementDuration
        self.announcementAudience = announcementAudience
        self.announcementId = announcementId
        self.announcementSender = announcementSender
        self.announcementDetails = announcementDetails
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.announcementTitle = (decoder.decodeObject(forKey: "announcementTitle") as! String)
        self.announcementMessage = (decoder.decodeObject(forKey: "announcementMessage") as! String)
        self.announcementActive = (decoder.decodeObject(forKey: "announcementActive") as! String)
        self.announcementGames = (decoder.decodeObject(forKey: "announcementGames") as! [String])
        self.announcementAudience = (decoder.decodeObject(forKey: "announcementGames") as! [String])
        self.announcementDuration = (decoder.decodeObject(forKey: "announcementDuration") as! String)
        self.announcementId = (decoder.decodeObject(forKey: "announcementId") as! String)
        self.announcementSender = (decoder.decodeObject(forKey: "announcementSender") as! String)
        self.announcementDetails = (decoder.decodeObject(forKey: "announcementDetails") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.announcementTitle, forKey: "announcementTitle")
        coder.encode(self.announcementMessage, forKey: "announcementMessage")
        coder.encode(self.announcementActive, forKey: "announcementActive")
        coder.encode(self.announcementGames, forKey: "announcementGames")
        coder.encode(self.announcementAudience, forKey: "announcementAudience")
        coder.encode(self.announcementDuration, forKey: "announcementDuration")
        coder.encode(self.announcementId, forKey: "announcementId")
        coder.encode(self.announcementSender, forKey: "announcementSender")
        coder.encode(self.announcementDetails, forKey: "announcementDetails")
    }
    
}

