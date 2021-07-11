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
    
    var _onlineStatus = "idle"
    var onlineStatus: String {
        get {
            return (_onlineStatus)
        }
        set (newVal) {
            _onlineStatus = newVal
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
    
    var _dailyCheck = ""
    var dailyCheck: String {
        get {
            return (_dailyCheck)
        }
        set (newVal) {
            _dailyCheck = newVal
        }
    }
    
    var _instagramConnect = ""
    var instagramConnect: String {
        get {
            return (_instagramConnect)
        }
        set (newVal) {
            _instagramConnect = newVal
        }
    }
    
    var _discordConnect = ""
    var discordConnect: String {
        get {
            return (_discordConnect)
        }
        set (newVal) {
            _discordConnect = newVal
        }
    }
    
    var _gamingExperience = ""
    var gamingExperience: String {
        get {
            return (_gamingExperience)
        }
        set (newVal) {
            _gamingExperience = newVal
        }
    }
    
    var _googleApiAccessToken = ""
    var googleApiAccessToken: String {
        get {
            return (_googleApiAccessToken)
        }
        set (newVal) {
            _googleApiAccessToken = newVal
        }
    }
    
    var _googleApiRefreshToken = ""
    var googleApiRefreshToken: String {
        get {
            return (_googleApiRefreshToken)
        }
        set (newVal) {
            _googleApiRefreshToken = newVal
        }
    }
    
    var _googleUserId = ""
    var googleUserId: String {
        get {
            return (_googleUserId)
        }
        set (newVal) {
            _googleUserId = newVal
        }
    }
    
    var _timezone = "timezone"
    var timezone: String {
        get {
            return (_timezone)
        }
        set (newVal) {
            _timezone = newVal
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
    
    var _blockList = [String]()
    var blockList: [String] {
        get {
            return (_blockList)
        }
        set (newVal) {
            _blockList = newVal
        }
    }
    
    var _userLookingFor = [String]()
    var userLookingFor: [String] {
        get {
            return (_userLookingFor)
        }
        set (newVal) {
            _userLookingFor = newVal
        }
    }
    
    var _userAbout = [String]()
    var userAbout: [String] {
        get {
            return (_userAbout)
        }
        set (newVal) {
            _userAbout = newVal
        }
    }
    
    var _badges = [BadgeObj]()
    var badges: [BadgeObj] {
        get {
            return (_badges)
        }
        set (newVal) {
            _badges = newVal
        }
    }
    
    var _restrictList = [String]()
    var restrictList: [String] {
        get {
            return (_restrictList)
        }
        set (newVal) {
            _restrictList = newVal
        }
    }
    
    var _cachedRecommendedUids = [String]()
    var cachedRecommendedUids: [String] {
        get {
            return (_cachedRecommendedUids)
        }
        set (newVal) {
            _cachedRecommendedUids = newVal
        }
    }
    
    var _reviews = [String]()
    var reviews: [String] {
        get {
            return (_reviews)
        }
        set (newVal) {
            _reviews = newVal
        }
    }
    
    var _receivedAnnouncements = [String]()
    var receivedAnnouncements: [String] {
        get {
            return (_receivedAnnouncements)
        }
        set (newVal) {
            _receivedAnnouncements = newVal
        }
    }
    
    var _recommendedGames = [String]()
    var recommendedGames: [String] {
        get {
            return (_recommendedGames)
        }
        set (newVal) {
            _recommendedGames = newVal
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
    
    var _youtubeVideos = [YoutubeVideoObj]()
    var youtubeVideos : [YoutubeVideoObj] {
        get {
            return (_youtubeVideos)
        }
        set (newVal) {
            _youtubeVideos = newVal
        }
    }
    
    var _currentOnlineAnnounement: OnlineObj?
    var currentOnlineAnnounement: OnlineObj? {
        get {
            return (_currentOnlineAnnounement)
        }
        set (newVal) {
            _currentOnlineAnnounement = newVal
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
        self.dailyCheck = (decoder.decodeObject(forKey: "dailyCheck") as! String)
        self.notifications = (decoder.decodeObject(forKey: "notifications") as! String)
        self.teamInviteRequests = (decoder.decodeObject(forKey: "teamInviteRequests") as! [RequestObject])
        self.subscriptions = (decoder.decodeObject(forKey: "subscriptions") as! [String])
        self.currentTempRivals = (decoder.decodeObject(forKey: "currentTempRivals") as! [RivalObj])
        self.acceptedTempRivals = (decoder.decodeObject(forKey: "acceptedTempRivals") as! [RivalObj])
        self.rejectedTempRivals = (decoder.decodeObject(forKey: "rejectedTempRivals") as! [RivalObj])
        self.tempRivals = (decoder.decodeObject(forKey: "tempRivals") as! [RivalObj])
        self.twitchConnect = (decoder.decodeObject(forKey: "twitchConnect") as! String)
        self.instagramConnect = (decoder.decodeObject(forKey: "instagramConnect") as! String)
        self.viewedAnnouncements = (decoder.decodeObject(forKey: "viewedAnnouncements") as! [String])
        self.userLookingFor = (decoder.decodeObject(forKey: "userLookingFor") as! [String])
        self.selectedAge = (decoder.decodeObject(forKey: "selectedAge") as! String)
        self.primaryLanguage = (decoder.decodeObject(forKey: "primaryLanguage") as! String)
        self.secondaryLanguage = (decoder.decodeObject(forKey: "secondaryLanguage") as! String)
        self.blockList = (decoder.decodeObject(forKey: "blockList") as! [String])
        self.restrictList = (decoder.decodeObject(forKey: "restrictList") as! [String])
        self.onlineStatus = (decoder.decodeObject(forKey: "onlineStatus") as! String)
        self.googleApiAccessToken = (decoder.decodeObject(forKey: "googleApiAccessToken") as! String)
        self.googleApiRefreshToken = (decoder.decodeObject(forKey: "googleApiRefreshToken") as! String)
        self.gamingExperience = (decoder.decodeObject(forKey: "gamingExperience") as! String)
        self.discordConnect = (decoder.decodeObject(forKey: "discordConnect") as! String)
        self.currentOnlineAnnounement = (decoder.decodeObject(forKey: "currentOnlineAnnounement") as! OnlineObj)
        self.reviews = (decoder.decodeObject(forKey: "reviews") as! [String])
        self.cachedRecommendedUids = (decoder.decodeObject(forKey: "cachedRecommendedUids") as! [String])
        self.receivedAnnouncements = (decoder.decodeObject(forKey: "receivedAnnouncements") as! [String])
        self.userAbout = (decoder.decodeObject(forKey: "userAbout") as! [String])
        self.recommendedGames = (decoder.decodeObject(forKey: "recommendedGames") as! [String])
        self.badges = (decoder.decodeObject(forKey: "badges") as! [BadgeObj])
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
        coder.encode(self.blockList, forKey: "blockList")
        coder.encode(self.blockList, forKey: "restrictList")
        coder.encode(self.onlineStatus, forKey: "onlineStatus")
        coder.encode(self.currentOnlineAnnounement, forKey: "currentOnlineAnnounement")
        coder.encode(self.reviews, forKey: "reviews")
        coder.encode(self.badges, forKey: "badges")
        coder.encode(self.dailyCheck, forKey: "dailyCheck")
        coder.encode(self.cachedRecommendedUids, forKey: "cachedRecommendedUserIds")
        coder.encode(self.receivedAnnouncements, forKey: "receivedAnnouncements")
        coder.encode(self.recommendedGames, forKey: "recommendedGames")
        coder.encode(self.instagramConnect, forKey: "instagramConnect")
        coder.encode(self.userLookingFor, forKey: "userLookingFor")
        coder.encode(self.discordConnect, forKey: "discordConnect")
        coder.encode(self.userAbout, forKey: "userAbout")
        coder.encode(self.gamingExperience, forKey: "gamingExperience")
        coder.encode(self.googleApiRefreshToken, forKey: "googleApiRefreshToken")
        coder.encode(self.googleApiAccessToken, forKey: "googleApiAccessToken")
    }
    
    struct Post: Hashable, Equatable {
        let gamertag: String
        var hashValue: Int { get { return gamertag.hashValue } }
    }

    static func ==(left:User, right:User) -> Bool {
        return left.gamerTag == right.gamerTag
    }
}


