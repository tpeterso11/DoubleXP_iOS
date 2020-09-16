//
//  EasyTeamObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/5/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

class EasyTeamObj: NSObject, NSCoding {

    var _gameName = ""
    var gameName:String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
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
    
    var _newTeam = ""
    var newTeam: String {
        get {
            return (_newTeam)
        }
        set (newVal) {
            _newTeam = newVal
        }
    }
    
    var _teamCaptainId = ""
    var teamCaptainId: String {
        get {
            return (_teamCaptainId)
        }
        set (newVal) {
            _teamCaptainId = newVal
        }
    }

    init(teamName: String, teamId: String, gameName: String, teamCaptainId: String, newTeam: String)
    {
        super.init()
        self.teamName = teamName
        self.teamId = teamId
        self.gameName = gameName
        self.teamCaptainId = teamCaptainId
        self.newTeam = newTeam
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.teamName = (decoder.decodeObject(forKey: "teamName") as! String)
        self.teamId = (decoder.decodeObject(forKey: "teamId") as! String)
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.teamCaptainId = (decoder.decodeObject(forKey: "teamCaptainId") as! String)
        self.newTeam = (decoder.decodeObject(forKey: "newTeam") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.teamName, forKey: "teamName")
        coder.encode(self.teamId, forKey: "teamId")
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.teamCaptainId, forKey: "teamCaptainId")
        coder.encode(self.newTeam, forKey: "newTeam")
    }
}

