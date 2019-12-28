//
//  RequestObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/14/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation

class RequestObject: NSObject, NSCoding {

    var _status = ""
    var status:String {
        get {
            return (_status)
        }
        set (newVal) {
            _status = newVal
        }
    }

    var _teamId = ""
    var teamId: String {
        get {
            return (_teamId)
        }
        set (newVal) {
            _teamId = newVal
        }
    }
    
    var _teamName = ""
    var teamName: String {
        get {
            return (_teamName)
        }
        set (newVal) {
            _teamName = newVal
        }
    }

    var _captainId = ""
    var captainId: String {
        get {
            return (_captainId)
        }
        set (newVal) {
            _captainId = newVal
        }
    }
    
    var _requestId = ""
    var requestId: String {
        get {
            return (_requestId)
        }
        set (newVal) {
            _requestId = newVal
        }
    }
    
    var _profile = FreeAgentObject(gamerTag: "", competitionId: "", consoles: [String](), game: "", userId: "", questions: [[String]]())
    var profile: FreeAgentObject {
        get {
            return (_profile)
        }
        set (newVal) {
            _profile = newVal
        }
    }
    
    init(status: String, teamId: String, teamName: String, captainId: String, requestId: String)
    {
        super.init()
        self.status = status
        self.teamId = teamId
        self.captainId = captainId
        self.teamName = teamName
        self.requestId = requestId
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.status = (decoder.decodeObject(forKey: "status") as! String)
        self.teamId = (decoder.decodeObject(forKey: "teamId") as! String)
        self.teamName = (decoder.decodeObject(forKey: "teamName") as! String)
        self.captainId = (decoder.decodeObject(forKey: "captainId") as! String)
        self.requestId = (decoder.decodeObject(forKey: "requestId") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.status, forKey: "status")
        coder.encode(self.teamId, forKey: "teamId")
        coder.encode(self.captainId, forKey: "captainId")
        coder.encode(self.teamName, forKey: "teamName")
        coder.encode(self.requestId, forKey: "requestId")
    }
}


