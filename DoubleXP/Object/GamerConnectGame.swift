//
//  GamerConnectGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class GamerConnectGame: NSObject, NSCoding {
    var _imageUrl:String? = nil
    var imageUrl:String {
        get {
            return (_imageUrl)!
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    var _twitchGameId:String = ""
    var twitchGameId:String {
        get {
            return (_twitchGameId)
        }
        set (newVal) {
            _twitchGameId = newVal
        }
    }
    
    var _gameName:String = ""
    var gameName:String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
        }
    }
    
    var _developer = ""
    var developer:String {
        get {
            return (_developer)
        }
        set (newVal) {
            _developer = newVal
        }
    }
    
    var _hook:String? = nil
    var hook:String {
        get {
            return (_hook)!
        }
        set (newVal) {
            _hook = newVal
        }
    }
    
    var _mobileGame:String = ""
    var mobileGame :String {
        get {
            return (_mobileGame)
        }
        set (newVal) {
            _mobileGame = newVal
        }
    }
    
    var _hasQuiz: Bool = false
    var hasQuiz:Bool {
        get {
            return (_hasQuiz)
        }
        set (newVal) {
            _hasQuiz = newVal
        }
    }
    
    var _twitterHandle:String? = nil
    var twitterHandle:String {
        get {
            return (_twitterHandle)!
        }
        set (newVal) {
            _twitterHandle = newVal
        }
    }
    
    var _twitchHandle:String? = nil
    var twitchHandle:String {
        get {
            return (_twitchHandle)!
        }
        set (newVal) {
            _twitchHandle = newVal
        }
    }
    
    var _available:String = ""
    var available:String {
        get {
            return (_available)
        }
        set (newVal) {
            _available = newVal
        }
    }
    
    var _statsAvailable:Bool? = nil
    var statsAvailable:Bool {
        get {
            return (_statsAvailable)!
        }
        set (newVal) {
            _statsAvailable = newVal
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
    
    var _availablebConsoles = [String]()
    var availablebConsoles: [String] {
        get {
            return (_availablebConsoles)
        }
        set (newVal) {
            _availablebConsoles = newVal
        }
    }
    
    var _gameModes:[String]? = nil
    var gameModes:[String] {
        get {
            return (_gameModes)!
        }
        set (newVal) {
            _gameModes = newVal
        }
    }
    
    var _secondaryName:String = ""
    var secondaryName:String {
        get {
            return (_secondaryName)
        }
        set (newVal) {
            _secondaryName = newVal
        }
    }
    
    var _releaseDate:String = ""
    var releaseDate:String {
        get {
            return (_releaseDate)
        }
        set (newVal) {
            _releaseDate = newVal
        }
    }
    
    var _gameType:String = ""
    var gameType:String {
        get {
            return (_gameType)
        }
        set (newVal) {
            _gameType = newVal
        }
    }
    
    var _cachedImage: UIImage? = nil
    var cachedImage: UIImage {
        get {
            return (_cachedImage) ?? UIImage()
        }
        set (newVal) {
            _cachedImage = newVal
        }
    }
    
    var _stats: StatObject? = nil
    var stats: StatObject? {
        get {
            return (_stats)!
        }
        set (newVal) {
            _stats = newVal
        }
    }
    
    var _filterQuestions = [[String: Any]]()
    var filterQuestions: [[String: Any]] {
        get {
            return (_filterQuestions)
        }
        set (newVal) {
            _filterQuestions = newVal
        }
    }
    
    var _lookingFor = [String]()
    var lookingFor: [String] {
        get {
            return (_lookingFor)
        }
        set (newVal) {
            _lookingFor = newVal
        }
    }
    
    var _categoryFilters = [String]()
    var categoryFilters: [String] {
        get {
            return (_categoryFilters)
        }
        set (newVal) {
            _categoryFilters = newVal
        }
    }
    
    var _ratings = [[String: String]]()
    var ratings: [[String: String]] {
        get {
            return (_ratings)
        }
        set (newVal) {
            _ratings = newVal
        }
    }
    
    var _quickReviews = [[String: String]]()
    var quickReviews: [[String: String]] {
        get {
            return (_quickReviews)
        }
        set (newVal) {
            _quickReviews = newVal
        }
    }
    
    var _gameDescription:String = ""
    var gameDescription:String {
        get {
            return (_gameDescription)
        }
        set (newVal) {
            _gameDescription = newVal
        }
    }
    
    var _alternateImageUrl:String = ""
    var alternateImageUrl:String {
        get {
            return (_alternateImageUrl)
        }
        set (newVal) {
            _alternateImageUrl = newVal
        }
    }
    
    var _ideal:String = ""
    var ideal:String {
        get {
            return (_ideal)
        }
        set (newVal) {
            _ideal = newVal
        }
    }
    
    var _timeCommitment:String = ""
    var timeCommitment:String {
        get {
            return (_timeCommitment)
        }
        set (newVal) {
            _timeCommitment = newVal
        }
    }
    
    var _complexity:String = ""
    var complexity:String {
        get {
            return (_complexity)
        }
        set (newVal) {
            _complexity = newVal
        }
    }
    
    init(imageUrl: String, gameName: String, developer: String, hook: String, statsAvailable: Bool, teamNeeds: [String],
         twitterHandle: String, twitchHandle: String, available: String)
    {
        super.init()
        self.imageUrl = imageUrl
        self.gameName = gameName
        self.developer  = developer
        self.hook = hook
        self.statsAvailable = statsAvailable
        self.teamNeeds = teamNeeds
        self.twitterHandle = twitterHandle
        self.twitchHandle = twitchHandle
        self.available = available
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.developer = (decoder.decodeObject(forKey: "developer") as! String)
        self.hook = (decoder.decodeObject(forKey: "hook") as! String)
        self.statsAvailable = (decoder.decodeObject(forKey: "statsAvailable") as! Bool)
        self.teamNeeds = (decoder.decodeObject(forKey: "teamNeeds") as! [String])
        self.secondaryName = (decoder.decodeObject(forKey: "secondaryName") as! String)
        self.gameModes = (decoder.decodeObject(forKey: "gameModes") as! [String])
        self.twitterHandle = (decoder.decodeObject(forKey: "twitterHandle") as! String)
        self.twitchHandle = (decoder.decodeObject(forKey: "twitchHandle") as! String)
        self.twitchGameId = (decoder.decodeObject(forKey: "twitchGameId") as! String)
        self.hasQuiz = (decoder.decodeObject(forKey: "hasQuiz") as! Bool)
        self.mobileGame = (decoder.decodeObject(forKey: "mobileGame") as! String)
        self.available = (decoder.decodeObject(forKey: "available") as! String)
        self.availablebConsoles = (decoder.decodeObject(forKey: "availableConsoles") as! [String])
        self.categoryFilters = (decoder.decodeObject(forKey: "categoryFilters") as! [String])
        self.lookingFor = (decoder.decodeObject(forKey: "lookingFor") as! [String])
        self.releaseDate = (decoder.decodeObject(forKey: "releaseDate") as! String)
        self.gameDescription = (decoder.decodeObject(forKey: "gameDescription") as! String)
        self.ideal = (decoder.decodeObject(forKey: "ideal") as! String)
        self.timeCommitment = (decoder.decodeObject(forKey: "timeCommitment") as! String)
        self.complexity = (decoder.decodeObject(forKey: "complexity") as! String)
        self.ratings = (decoder.decodeObject(forKey: "ratings") as! [[String: String]])
        self.quickReviews = (decoder.decodeObject(forKey: "quickReviews") as! [[String: String]])
        self.alternateImageUrl = (decoder.decodeObject(forKey: "alternateImageUrl") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.developer, forKey: "developer")
        coder.encode(self.hook, forKey: "hook")
        coder.encode(self.statsAvailable, forKey: "statsAvailable")
        coder.encode(self.teamNeeds, forKey: "teamNeeds")
        coder.encode(self.secondaryName, forKey: "secondaryName")
        coder.encode(self.gameModes, forKey: "gameModes")
        coder.encode(self.twitterHandle, forKey: "twitterHandle")
        coder.encode(self.twitchHandle, forKey: "twitchHandle")
        coder.encode(self.twitchGameId, forKey: "twitchGameId")
        coder.encode(self.hasQuiz, forKey: "hasQuiz")
        coder.encode(self.mobileGame, forKey: "mobileGame")
        coder.encode(self.available, forKey: "available")
        coder.encode(self.availablebConsoles, forKey: "avaliableConsoles")
        coder.encode(self.categoryFilters, forKey: "categoryFilters")
        coder.encode(self.releaseDate, forKey: "releaseDate")
        coder.encode(self.ratings, forKey: "ratings")
        coder.encode(self.gameDescription, forKey: "gameDescription")
        coder.encode(self.ideal, forKey: "ideal")
        coder.encode(self.timeCommitment, forKey: "timeCommitment")
        coder.encode(self.complexity, forKey: "complexity")
        coder.encode(self.ratings, forKey: "ratings")
        coder.encode(self.quickReviews, forKey: "quickReviews")
        coder.encode(self.alternateImageUrl, forKey: "alternateImageUrl")
        coder.encode(self.lookingFor, forKey: "lookingFor")
    }
}
