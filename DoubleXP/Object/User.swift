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
    var displayName: String = "You"
    
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
    
    var _selectedAge = ""
    var selectedAge: String {
        get {
            return (_selectedAge)
        }
        set (newVal) {
            _selectedAge = newVal
        }
    }
    
    var _primaryLanguage = ""
    var primaryLanguage: String {
        get {
            return (_primaryLanguage)
        }
        set (newVal) {
            _primaryLanguage = newVal
        }
    }
    
    var _secondaryLanguage = ""
    var secondaryLanguage: String {
        get {
            return (_secondaryLanguage)
        }
        set (newVal) {
            _secondaryLanguage = newVal
        }
    }
    
    var _senderId = ""
       var senderId: String {
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
    
    var _viewedAnnouncements = [String]()
    var viewedAnnouncements:[String] {
        get {
            return (_viewedAnnouncements)
        }
        set (newVal) {
            _viewedAnnouncements = newVal
        }
    }
    
    var _competitions = [String]()
    var competitions: [String] {
        get {
            return (_competitions)
        }
        set (newVal) {
            _competitions = newVal
        }
    }
    
    var _subscriptions = [String]()
    var subscriptions: [String] {
        get {
            return (_subscriptions)
        }
        set (newVal) {
            _subscriptions = newVal
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
    
    var _twitchConnect = ""
    var twitchConnect: String {
        get {
            return (_twitchConnect)
        }
        set (newVal) {
            _twitchConnect = newVal
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
    
    var _mobile = false
    var mobile: Bool {
        get {
            return (_mobile)
        }
        set (newVal) {
            _mobile = newVal
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
    
    var _search = "true"
    var search: String {
        get {
            return (_search)
        }
        set (newVal) {
            _search = newVal
        }
    }
    
    var _notifications = "true"
    var notifications: String {
        get {
            return (_notifications)
        }
        set (newVal) {
            _notifications = newVal
        }
    }
    
    var _userLat = 0.0
    var userLat: Double {
        get {
            return (_userLat)
        }
        set (newVal) {
            _userLat = newVal
        }
    }
    
    var _userLong = 0.0
    var userLong: Double {
        get {
            return (_userLong)
        }
        set (newVal) {
            _userLong = newVal
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
    
    var _teams = [EasyTeamObj]()
    var teams: [EasyTeamObj] {
        get {
            return (_teams)
        }
        set (newVal) {
            _teams = newVal
        }
    }
    
    var _teamInvites = [TeamInviteObject]()
    var teamInvites: [TeamInviteObject] {
        get {
            return (_teamInvites)
        }
        set (newVal) {
            _teamInvites = newVal
        }
    }
    
    var _teamInviteRequests = [RequestObject]()
    var teamInviteRequests: [RequestObject] {
        get {
            return (_teamInviteRequests)
        }
        set (newVal) {
            _teamInviteRequests = newVal
        }
    }
    
    var _chatObjects = [ChatObject]()
    var chatObjects: [ChatObject] {
        get {
            return (_chatObjects)
        }
        set (newVal) {
            _chatObjects = newVal
        }
    }
    
    //current rivals that you have sent
    var _currentTempRivals = [RivalObj]()
    var currentTempRivals: [RivalObj] {
        get {
            return (_currentTempRivals)
        }
        set (newVal) {
            _currentTempRivals = newVal
        }
    }
    
    //rivals that you have received, but not responded to.
    var _tempRivals = [RivalObj]()
       var tempRivals: [RivalObj] {
           get {
               return (_tempRivals)
           }
           set (newVal) {
               _tempRivals = newVal
           }
       }
    
    var _acceptedTempRivals = [RivalObj]()
    var acceptedTempRivals: [RivalObj] {
        get {
            return (_acceptedTempRivals)
        }
        set (newVal) {
            _acceptedTempRivals = newVal
        }
    }
    
    var _rejectedTempRivals = [RivalObj]()
    var rejectedTempRivals: [RivalObj] {
        get {
            return (_rejectedTempRivals)
        }
        set (newVal) {
            _rejectedTempRivals = newVal
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
    
    func userCanSendInvites() -> Bool {
        var canSend = false
        if(!self.gamerTags.isEmpty){
            for profile in self.gamerTags{
                if(!profile.gamerTag.isEmpty){
                    canSend = true
                    break
                }
            }
        }
        
        if(!canSend){
            if(!self.gamerTag.isEmpty){
                canSend = true
            }
        }
        
        return canSend
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
        self.teams = (decoder.decodeObject(forKey: "teams") as! [EasyTeamObj])
        self.teamInvites = (decoder.decodeObject(forKey: "teamInvites") as! [TeamInviteObject])
        self.stats = (decoder.decodeObject(forKey: "stats") as! [StatObject])
        self.chatObjects = (decoder.decodeObject(forKey: "chatObjects") as! [ChatObject])
        self.sendBirdId = (decoder.decodeObject(forKey: "sendBirdId") as! String)
        self.search = (decoder.decodeObject(forKey: "search") as! String)
        self.notifications = (decoder.decodeObject(forKey: "notifications") as! String)
        self.teamInviteRequests = (decoder.decodeObject(forKey: "teamInviteRequests") as! [RequestObject])
        self.subscriptions = (decoder.decodeObject(forKey: "subscriptions") as! [String])
        self.currentTempRivals = (decoder.decodeObject(forKey: "currentTempRivals") as! [RivalObj])
        self.acceptedTempRivals = (decoder.decodeObject(forKey: "acceptedTempRivals") as! [RivalObj])
        self.rejectedTempRivals = (decoder.decodeObject(forKey: "rejectedTempRivals") as! [RivalObj])
        self.tempRivals = (decoder.decodeObject(forKey: "tempRivals") as! [RivalObj])
        self.twitchConnect = (decoder.decodeObject(forKey: "twitchConnect") as! String)
        self.viewedAnnouncements = (decoder.decodeObject(forKey: "viewedAnnouncements") as! [String])
        self.selectedAge = (decoder.decodeObject(forKey: "selectedAge") as! String)
        self.primaryLanguage = (decoder.decodeObject(forKey: "primaryLanguage") as! String)
        self.secondaryLanguage = (decoder.decodeObject(forKey: "secondaryLanguage") as! String)
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
        coder.encode(self.chatObjects, forKey: "chatObjects")
        coder.encode(self.search, forKey: "search")
        coder.encode(self.notifications, forKey: "notifications")
        coder.encode(self.teamInviteRequests, forKey: "teamInviteRequests")
        coder.encode(self.subscriptions, forKey: "subscriptions")
        coder.encode(self.currentTempRivals, forKey: "currentTempRivals")
        coder.encode(self.acceptedTempRivals, forKey: "acceptedTempRivals")
        coder.encode(self.rejectedTempRivals, forKey: "rejectedTempRivals")
        coder.encode(self.tempRivals, forKey: "tempRivals")
        coder.encode(self.twitchConnect, forKey: "twitchConnect")
        coder.encode(self.viewedAnnouncements, forKey: "viewedAnnouncements")
        coder.encode(self.selectedAge, forKey: "selectedAge")
        coder.encode(self.primaryLanguage, forKey: "primaryLanguage")
        coder.encode(self.secondaryLanguage, forKey: "secondaryLanguage")
    }
    
    struct Post: Hashable, Equatable {
        let gamertag: String
        var hashValue: Int { get { return gamertag.hashValue } }
    }

    static func ==(left:User, right:User) -> Bool {
        return left.gamerTag == right.gamerTag
    }
}


