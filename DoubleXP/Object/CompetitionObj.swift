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
    
    var _compDescription: String = ""
    var compDescription: String {
        get {
            return (_compDescription)
        }
        set (newVal) {
            _compDescription = newVal
        }
    }
    
    var _emergencyShowLiveStream: String = ""
    var emergencyShowLiveStream: String {
        get {
            return (_emergencyShowLiveStream)
        }
        set (newVal) {
            _emergencyShowLiveStream = newVal
        }
    }
    
    var _emergencyShowRegistrationOver: String = ""
    var emergencyShowRegistrationOver: String {
        get {
            return (_emergencyShowRegistrationOver)
        }
        set (newVal) {
            _emergencyShowRegistrationOver = newVal
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
    
    var _topPrizeType: String = ""
    var topPrizeType: String {
        get {
            return (_topPrizeType)
        }
        set (newVal) {
            _topPrizeType = newVal
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
    
    var _expired: String = ""
    var expired: String {
        get {
            return (_expired)
        }
        set (newVal) {
            _expired = newVal
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
    
    var _headerImgUrl: String = ""
    var headerImgUrl: String {
        get {
            return (_headerImgUrl)
        }
        set (newVal) {
            _headerImgUrl = newVal
        }
    }
    
    var _promoImgUrl: String = ""
    var promoImgUrl: String {
        get {
            return (_promoImgUrl)
        }
        set (newVal) {
            _promoImgUrl = newVal
        }
    }
    
    var _competitionTopic: String = ""
    var competitionTopic: String {
        get {
            return (_competitionTopic)
        }
        set (newVal) {
            _competitionTopic = newVal
        }
    }
    
    var _rundown: [String] = [String]()
    var rundown: [String] {
        get {
            return (_rundown)
        }
        set (newVal) {
            _rundown = newVal
        }
    }
    
    var _sponsorUrl:String? = ""
    var sponsorUrl:String {
        get {
            return (_sponsorUrl)!
        }
        set (newVal) {
            _sponsorUrl = newVal
        }
    }
    
    var _rulesUrl:String? = ""
    var rulesUrl:String {
        get {
            return (_rulesUrl)!
        }
        set (newVal) {
            _rulesUrl = newVal
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
        self.emergencyShowLiveStream = (decoder.decodeObject(forKey: "emergencyShowLiveStream") as! String)
        self.emergencyShowRegistrationOver = (decoder.decodeObject(forKey: "emergencyShowRegistrationOver") as! String)
        self.topPrize = (decoder.decodeObject(forKey: "topPrize") as! String)
        self.topPrizeType = (decoder.decodeObject(forKey: "topPrizeType") as! String)
        self.twitchChannelId = (decoder.decodeObject(forKey: "twitchChannelId") as! String)
        self.competitionStartMillis = (decoder.decodeObject(forKey: "competitionStartMillis") as! String)
        self.secondPrize = (decoder.decodeObject(forKey: "secondPrize") as! String)
        self.thirdPrize = (decoder.decodeObject(forKey: "thirdPrize") as! String)
        self.competitionDateString = (decoder.decodeObject(forKey: "competitionDateString") as! String)
        self.competitionAirDate = (decoder.decodeObject(forKey: "competitionAirDate") as! String)
        self.registrationDeadlineMillis = (decoder.decodeObject(forKey: "registrationDeadlineMillis") as! String)
        self.headerImgUrl = (decoder.decodeObject(forKey: "headerImgUrl") as! String)
        self.promoImgUrl = (decoder.decodeObject(forKey: "promoImgUrl") as! String)
        self.competitionTopic = (decoder.decodeObject(forKey: "competitionTopic") as! String)
        self.compDescription = (decoder.decodeObject(forKey: "compDescription") as! String)
        self.rundown = (decoder.decodeObject(forKey: "rundown") as! [String])
        self.rulesUrl = (decoder.decodeObject(forKey: "rulesUrl") as! String)
        self.sponsorUrl = (decoder.decodeObject(forKey: "sponsorUrl") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.competitionName, forKey: "competitionName")
        coder.encode(self.competitionId, forKey: "competitionId")
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.mainSponsor, forKey: "mainSponsor")
        coder.encode(self.subscriptionId, forKey: "subscriptionId")
        coder.encode(self.emergencyShowLiveStream, forKey: "emergencyShowLiveStream")
        coder.encode(self.emergencyShowRegistrationOver, forKey: "emergencyShowRegistrationOver")
        coder.encode(self.topPrize, forKey: "topPrize")
        coder.encode(self.topPrizeType, forKey: "topPrizeType")
        coder.encode(self.twitchChannelId, forKey: "twitchChannelId")
        coder.encode(self.competitionStartMillis, forKey: "competitionStartMillis")
        coder.encode(self.secondPrize, forKey: "secondPrize")
        coder.encode(self.thirdPrize, forKey: "thirdPrize")
        coder.encode(self.competitionDateString, forKey: "competitionDateString")
        coder.encode(self.competitionAirDate, forKey: "competitionAirDate")
        coder.encode(self.competitionAirDateString, forKey: "competitionAirDateString")
        coder.encode(self.registrationDeadlineMillis, forKey: "registrationDeadlineMillis")
        coder.encode(self.headerImgUrl, forKey: "headerImgUrl")
        coder.encode(self.promoImgUrl, forKey: "promoImgUrl")
        coder.encode(self.competitionTopic, forKey: "competitionTopic")
        coder.encode(self.compDescription, forKey: "compDescription")
        coder.encode(self.rundown, forKey: "rundown")
        coder.encode(self.rulesUrl, forKey: "rulesUrl")
        coder.encode(self.sponsorUrl, forKey: "sponsorUrl")
    }
}

