//
//  User.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//
import Foundation
import CoreData

class User: NSObject, NSCoding {
    var _gamerTags = [GamerProfile]()
    var gamerTags:[GamerProfile] {
        get {
            return (_gamerTags)
        }
        set (newVal) {
            _gamerTags = newVal
        }
    }
    
    var _friends = [FriendObject]()
    var friends:[FriendObject] {
        get {
            return (_friends)
        }
        set (newVal) {
            _friends = newVal
        }
    }
    
    var _uId = ""
    var uId: String {
        get {
            return (_uId)
        }
        set (newVal) {
            _uId = newVal
        }
    }
    
    var _gamerTag = ""
    var gamerTag: String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }
    
    var _games = [String]()
    var games:[String] {
        get {
            return (_games)
        }
        set (newVal) {
            _games = newVal
        }
    }
    
    var _lastLogin = ""
    var lastLogin: String {
        get {
            return (_lastLogin)
        }
        set (newVal) {
            _lastLogin = newVal
        }
    }
    
    var _bio = ""
    var bio: String {
        get {
            return (_bio)
        }
        set (newVal) {
            _bio = newVal
        }
    }
    
    var _sendBirdId = ""
    var sendBirdId: String {
        get {
            return (_sendBirdId)
        }
        set (newVal) {
            _sendBirdId = newVal
        }
    }
    
    var _messagingNotifications = false
    var messagingNotifications: Bool {
        get {
            return (_messagingNotifications)
        }
        set (newVal) {
            _messagingNotifications = newVal
        }
    }
    
    var _ps = false
    var ps: Bool {
        get {
            return (_ps)
        }
        set (newVal) {
            _ps = newVal
        }
    }
    
    var _pc = false
    var pc: Bool {
        get {
            return (_pc)
        }
        set (newVal) {
            _pc = newVal
        }
    }
    
    var _xbox = false
    var xbox: Bool {
        get {
            return (_xbox)
        }
        set (newVal) {
            _xbox = newVal
        }
    }
    
    var _nintendo = false
    var nintendo: Bool {
        get {
            return (_nintendo)
        }
        set (newVal) {
            _nintendo = newVal
        }
    }
    
    var _sentRequests = [FriendRequestObject]()
    var sentRequests: [FriendRequestObject] {
        get {
            return (_sentRequests)
        }
        set (newVal) {
            _sentRequests = newVal
        }
    }
    
    var _pendingRequests = [FriendRequestObject]()
    var pendingRequests: [FriendRequestObject] {
        get {
            return (_pendingRequests)
        }
        set (newVal) {
            _pendingRequests = newVal
        }
    }
    
    var _teams = [TeamObject]()
    var teams: [TeamObject] {
        get {
            return (_teams)
        }
        set (newVal) {
            _teams = newVal
        }
    }
    
    var _teamInvites = [TeamObject]()
    var teamInvites: [TeamObject] {
        get {
            return (_teamInvites)
        }
        set (newVal) {
            _teamInvites = newVal
        }
    }
    
    var _stats = [StatObject]()
    var stats: [StatObject] {
        get {
            return (_stats)
        }
        set (newVal) {
            _stats = newVal
        }
    }
    
    
    func getConsoleString() -> String{
        var buildString = ""
        if(self.ps){
            buildString.append("PS,")
        }
        if(self.xbox){
            buildString.append("XBox,")
        }
        if(self.nintendo){
            buildString.append("Nintendo,")
        }
        if(self.pc){
            buildString.append("PC,")
        }
        
        return String(buildString.dropLast())
    }
    
    func getConsoleArray() -> [String]{
        var array = [String]()
        if(self.ps){
            array.append("PS")
        }
        if(self.xbox){
            array.append("XBox")
        }
        if(self.nintendo){
            array.append("Switch")
        }
        if(self.pc){
            array.append("PC")
        }
        
        return array
    }
    
    init(uId: String)
    {
        super.init()
        self.uId = uId
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.bio = (decoder.decodeObject(forKey: "bio") as! String)
        self.gamerTags = (decoder.decodeObject(forKey: "gamerTags") as! [GamerProfile])
        self.friends = (decoder.decodeObject(forKey: "friends") as! [FriendObject])
        self.games = (decoder.decodeObject(forKey: "games") as! [String])
        self.messagingNotifications = (decoder.decodeObject(forKey: "messagingNotifications") as! Bool)
        self.sentRequests = (decoder.decodeObject(forKey: "sentRequests") as! [FriendRequestObject])
        self.pendingRequests = (decoder.decodeObject(forKey: "pendingRequests") as! [FriendRequestObject])
        self.teams = (decoder.decodeObject(forKey: "teams") as! [TeamObject])
        self.teamInvites = (decoder.decodeObject(forKey: "teamInvites") as! [TeamObject])
        self.stats = (decoder.decodeObject(forKey: "stats") as! [StatObject])
        self.sendBirdId = (decoder.decodeObject(forKey: "sendBirdId") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.gamerTags, forKey: "gamerTags")
        coder.encode(self.friends, forKey: "friends")
        coder.encode(self.games, forKey: "games")
        coder.encode(self.messagingNotifications, forKey: "messagingNotifications")
        coder.encode(self.sentRequests, forKey: "sentRequests")
        coder.encode(self.pendingRequests, forKey: "pendingRequests")
        coder.encode(self.teams, forKey: "teams")
        coder.encode(self.teamInvites, forKey: "teamInvites")
        coder.encode(self.stats, forKey: "stats")
        coder.encode(self.bio, forKey: "bio")
        coder.encode(self.sendBirdId, forKey: "sendBirdId")
    }
}


