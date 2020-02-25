//
//  TeamObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class TeamObject: NSObject, NSCoding {
    var _teamName:String? = nil
    var teamName:String {
        get {
            return (_teamName)!
        }
        set (newVal) {
            _teamName = newVal
        }
    }
    
    var _teamId:String? = nil
    var teamId:String {
        get {
            return (_teamId)!
        }
        set (newVal) {
            _teamId = newVal
        }
    }
    
    var _games:[String]? = nil
    var games:[String] {
        get {
            return (_games)!
        }
        set (newVal) {
            _games = newVal
        }
    }
    
    var _consoles:[String]? = nil
    var consoles:[String] {
        get {
            return (_consoles)!
        }
        set (newVal) {
            _consoles = newVal
        }
    }
    
    var _teammateTags:[String]? = nil
    var teammateTags:[String] {
        get {
            return (_teammateTags)!
        }
        set (newVal) {
            _teammateTags = newVal
        }
    }
    
    var _teammateIds:[String]? = nil
    var teammateIds:[String] {
        get {
            return (_teammateIds)!
        }
        set (newVal) {
            _teammateIds = newVal
        }
    }
    
    var _teammates:[TeammateObject]? = nil
       var teammates:[TeammateObject] {
           get {
               return (_teammates)!
           }
           set (newVal) {
               _teammates = newVal
           }
       }
    
    var _requests:[RequestObject]? = [RequestObject]()
    var requests:[RequestObject] {
        get {
            return (_requests)!
        }
        set (newVal) {
            _requests = newVal
        }
    }
    
    var _teamCaptain: String? = nil
    var teamCaptain: String {
        get {
            return (_teamCaptain)!
        }
        set (newVal) {
            _teamCaptain = newVal
        }
    }
    
    var _teamInvites:[TeamInviteObject]? = nil
    var teamInvites:[TeamInviteObject] {
        get {
            return (_teamInvites)!
        }
        set (newVal) {
            _teamInvites = newVal
        }
    }
    
    var _teamChat:String? = nil
    var teamChat:String {
        get {
            return (_teamChat)!
        }
        set (newVal) {
            _teamChat = newVal
        }
    }
    
    var _teamInviteTags:[String]? = nil
    var teamInviteTags:[String] {
        get {
            return (_teamInviteTags)!
        }
        set (newVal) {
            _teamInviteTags = newVal
        }
    }
    
    var _teamNeeds:[String]? = nil
    var teamNeeds:[String] {
        get {
            return (_teamNeeds)!
        }
        set (newVal) {
            _teamNeeds = newVal
        }
    }
    
    var _selectedTeamNeeds:[String]? = nil
    var selectedTeamNeeds:[String] {
        get {
            return (_selectedTeamNeeds)!
        }
        set (newVal) {
            _selectedTeamNeeds = newVal
        }
    }
    
    var _imageUrl:String? = nil
    var imageUrl:String {
        get {
            return (_imageUrl)!
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    init(teamName: String, teamId: String, games: [String], consoles: [String], teammateTags: [String], teammateIds: [String],
         teamCaptain: String, teamInvites: [TeamInviteObject], teamChat: String, teamInviteTags: [String], teamNeeds: [String], selectedTeamNeeds: [String], imageUrl: String)
    {
        super.init()
        self.teamName = teamName
        self.teamId = teamId
        self.games = games
        self.consoles = consoles
        self.teammateTags = teammateTags
        self.teammateIds = teammateIds
        self.teamNeeds = teamNeeds
        self.teamInviteTags = teamInviteTags
        self.teamChat = teamChat
        self.teamInvites = teamInvites
        self.teamCaptain = teamCaptain
        self.selectedTeamNeeds = selectedTeamNeeds
        self.imageUrl = imageUrl
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.teamName = (decoder.decodeObject(forKey: "teamName") as! String)
        self.teamId = (decoder.decodeObject(forKey: "teamId") as! String)
        self.games = (decoder.decodeObject(forKey: "games") as! [String])
        self.consoles = (decoder.decodeObject(forKey: "consoles") as! [String])
        self.teammateTags = (decoder.decodeObject(forKey: "teammateTags") as! [String])
        self.teammateIds = (decoder.decodeObject(forKey: "teammateIds") as! [String])
        self.teamNeeds = (decoder.decodeObject(forKey: "teamNeeds") as! [String])
        self.teamInviteTags = (decoder.decodeObject(forKey: "teamInviteTags") as! [String])
        self.teamInvites = (decoder.decodeObject(forKey: "teamInvites") as! [TeamInviteObject])
        self.teamCaptain = (decoder.decodeObject(forKey: "teamCaptain") as! String)
        self.teamChat = (decoder.decodeObject(forKey: "teamChat") as! String)
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.selectedTeamNeeds = (decoder.decodeObject(forKey: "selectedTeamNeeds") as! [String])
        self.teammates = (decoder.decodeObject(forKey: "teammates") as! [TeammateObject])
        self.requests = (decoder.decodeObject(forKey: "requests") as! [RequestObject])
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.teamName, forKey: "teamName")
        coder.encode(self.teamId, forKey: "teamId")
        coder.encode(self.games, forKey: "games")
        coder.encode(self.consoles, forKey: "consoles")
        coder.encode(self.teammateTags, forKey: "teammateTags")
        coder.encode(self.teammateIds, forKey: "teammateIds")
        coder.encode(self.teamNeeds, forKey: "teamNeeds")
        coder.encode(self.teamInviteTags, forKey: "teamInviteTags")
        coder.encode(self.teamInvites, forKey: "teamInvites")
        coder.encode(self.teamCaptain, forKey: "teamCaptain")
        coder.encode(self.teamChat, forKey: "teamChat")
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.selectedTeamNeeds, forKey: "selectedTeamNeeds")
        coder.encode(self.teammates, forKey: "teammates")
        coder.encode(self.requests, forKey: "requests")
    }
    
}
