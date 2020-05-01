//
//  CompetitionObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class CompetitionObj: NSObject, NSCoding {

    var _competitionName: String = ""
    var competitionName: String {
        get {
            return (_competitionName)
        }
        set (newVal) {
            _competitionName = newVal
        }
    }
    
    var _competitionId: String = ""
    var competitionId: String {
        get {
            return (_competitionId)
        }
        set (newVal) {
            _competitionId = newVal
        }
    }
    
    var _gameName: String = ""
    var gameName: String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
        }
    }
    
    var _mainSponsor: String = ""
    var mainSponsor: String {
        get {
            return (_mainSponsor)
        }
        set (newVal) {
            _mainSponsor = newVal
        }
    }
    
    var _sponsorIcons: [String] = [String]()
    var sponsorIcons: [String] {
        get {
            return (_sponsorIcons)
        }
        set (newVal) {
            _sponsorIcons = newVal
        }
    }
    
    var _topPrize: String = ""
    var topPrize: String {
        get {
            return (_topPrize)
        }
        set (newVal) {
            _topPrize = newVal
        }
    }
    
    var _secondPrize: String = ""
    var secondPrize: String {
        get {
            return (_secondPrize)
        }
        set (newVal) {
            _secondPrize = newVal
        }
    }
    
    var _thirdPrize: String = ""
    var thirdPrize: String {
        get {
            return (_thirdPrize)
        }
        set (newVal) {
            _thirdPrize = newVal
        }
    }
    
    var _gcName: String = ""
    var gcName: String {
        get {
            return (_gcName)
        }
        set (newVal) {
            _gcName = newVal
        }
    }
    
    var _subscriptionId: String = ""
    var subscriptionId: String {
        get {
            return (_subscriptionId)
        }
        set (newVal) {
            _subscriptionId = newVal
        }
    }
    
    var _competitionDate: String = ""
    var competitionDate: String {
        get {
            return (_competitionDate)
        }
        set (newVal) {
            _competitionDate = newVal
        }
    }
    
    var _competitionDateString: String = ""
    var competitionDateString: String {
        get {
            return (_competitionDateString)
        }
        set (newVal) {
            _competitionDateString = newVal
        }
    }
    
    var _competitionAirDate: String = ""
    var competitionAirDate: String {
        get {
            return (_competitionAirDate)
        }
        set (newVal) {
            _competitionAirDate = newVal
        }
    }
    
    var _competitionAirDateString: String = ""
    var competitionAirDateString: String {
        get {
            return (_competitionAirDateString)
        }
        set (newVal) {
            _competitionAirDateString = newVal
        }
    }
    
    var _registrationDeadlineMillis: String = ""
    var registrationDeadlineMillis: String {
        get {
            return (_registrationDeadlineMillis)
        }
        set (newVal) {
            _registrationDeadlineMillis = newVal
        }
    }
    
    var _competitionStartMillis: String = ""
    var competitionStartMillis: String {
        get {
            return (_competitionStartMillis)
        }
        set (newVal) {
            _competitionStartMillis = newVal
        }
    }
    
    var _twitchChannelId: String = ""
    var twitchChannelId: String {
        get {
            return (_twitchChannelId)
        }
        set (newVal) {
            _twitchChannelId = newVal
        }
    }
    
    var _videoPlayed: Bool = false
    var videoPlayed: Bool {
        get {
            return (_videoPlayed)
        }
        set (newVal) {
            _videoPlayed = newVal
        }
    }
    
    var _competitors: [CompetitorObj] = [CompetitorObj]()
    var competitors: [CompetitorObj] {
        get {
            return (_competitors)
        }
        set (newVal) {
            _competitors = newVal
        }
    }
    
    var _isTeamCompetition: String = ""
    var isTeamCompetition: String {
        get {
            return (_isTeamCompetition)
        }
        set (newVal) {
            _isTeamCompetition = newVal
        }
    }

    init(competitionName: String, competitionId: String, gameName: String, mainSponsor: String)
    {
        super.init()
        self.competitionName = competitionName
        self.competitionId = competitionId
        self.gameName = gameName
        self.mainSponsor = mainSponsor
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.competitionName = (decoder.decodeObject(forKey: "competitionName") as! String)
        self.competitionId = (decoder.decodeObject(forKey: "competitionId") as! String)
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.mainSponsor = (decoder.decodeObject(forKey: "mainSponsor") as! String)
        self.subscriptionId = (decoder.decodeObject(forKey: "subscriptionId") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.competitionName, forKey: "competitionName")
        coder.encode(self.competitionId, forKey: "competitionId")
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.mainSponsor, forKey: "mainSponsor")
        coder.encode(self.subscriptionId, forKey: "subscriptionId")
    }
}

