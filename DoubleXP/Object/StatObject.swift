//
//  StatObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/12/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

/*private String gameName;
private String playerLevelGame;
private String playerLevelPVP;
private String killsPVP;
private String killsPVE;
private String statURL;
private String setPublic;
private String authorized;

//Siege
private String currentRank;
private String totalRankedWins;
private String totalRankedLosses;
private String totalRankedKills;
private String totalRankedDeaths;
private String mostUsedAttacker;
private String mostUsedDefender;

//The Division
private String gearScore;*/


import Foundation
import CoreData

class StatObject: NSObject, NSCoding {
    var _gameName = ""
    var gameName:String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
        }
    }
    
    var _killsPVE = ""
    var killsPVE: String {
        get {
            return (_killsPVE)
        }
        set (newVal) {
            _killsPVE = newVal
        }
    }
    
    var _killsPVP = ""
    var killsPVP: String {
        get {
            return (_killsPVP)
        }
        set (newVal) {
            _killsPVP = newVal
        }
    }
    
    var _playerLevelGame = ""
    var playerLevelGame: String {
        get {
            return (_playerLevelGame)
        }
        set (newVal) {
            _playerLevelGame = newVal
        }
    }
    
    var _playerLevelPVP = ""
    var playerLevelPVP: String {
        get {
            return (_playerLevelPVP)
        }
        set (newVal) {
            _playerLevelPVP = newVal
        }
    }
    
    var _statUrl = ""
    var statUrl: String {
        get {
            return (_statUrl)
        }
        set (newVal) {
            _statUrl = newVal
        }
    }
    
    var _setPublic = ""
    var setPublic: String {
        get {
            return (_setPublic)
        }
        set (newVal) {
            _setPublic = newVal
        }
    }
    
    var _authorized = ""
    var authorized: String {
        get {
            return (_authorized)
        }
        set (newVal) {
            _authorized = newVal
        }
    }
    
    var _currentRank = ""
    var currentRank: String {
        get {
            return (_currentRank)
        }
        set (newVal) {
            _currentRank = newVal
        }
    }
    
    var _totalRankedWins = ""
    var totalRankedWins: String {
        get {
            return (_totalRankedWins)
        }
        set (newVal) {
            _totalRankedWins = newVal
        }
    }
    
    var _totalRankedLosses = ""
    var totalRankedLosses: String {
        get {
            return (_totalRankedLosses)
        }
        set (newVal) {
            _totalRankedLosses = newVal
        }
    }
    
    var _totalRankedKills = ""
    var totalRankedKills: String {
        get {
            return (_totalRankedKills)
        }
        set (newVal) {
            _totalRankedKills = newVal
        }
    }
    
    var _totalRankedDeaths = ""
    var totalRankedDeaths: String {
        get {
            return (_totalRankedDeaths)
        }
        set (newVal) {
            _totalRankedDeaths = newVal
        }
    }
    
    var _mostUsedAttacker = ""
    var mostUsedAttacker: String {
        get {
            return (_mostUsedAttacker)
        }
        set (newVal) {
            _mostUsedAttacker = newVal
        }
    }
    
    var _mostUsedDefender = ""
    var mostUsedDefender: String {
        get {
            return (_mostUsedDefender)
        }
        set (newVal) {
            _mostUsedDefender = newVal
        }
    }
    
    var _gearScore = ""
    var gearScore: String {
        get {
            return (_gearScore)
        }
        set (newVal) {
            _gearScore = newVal
        }
    }
    
    func getItemCount()-> Int{
        var count = 0
        if(!gameName.isEmpty){
            count += 1
        }
        if(!killsPVE.isEmpty){
            count += 1
        }
        if(!killsPVP.isEmpty){
            count += 1
        }
        if(!playerLevelGame.isEmpty){
            count += 1
        }
        if(!playerLevelPVP.isEmpty){
            count += 1
        }
        if(!currentRank.isEmpty){
            count += 1
        }
        if(!totalRankedWins.isEmpty){
            count += 1
        }
        if(!totalRankedLosses.isEmpty){
            count += 1
        }
        if(!totalRankedKills.isEmpty){
            count += 1
        }
        if(!totalRankedDeaths.isEmpty){
            count += 1
        }
        if(!mostUsedAttacker.isEmpty){
            count += 1
        }
        if(!mostUsedDefender.isEmpty){
            count += 1
        }
        if(!gearScore.isEmpty){
            count += 1
        }
        
        return count
    }
    
    init(gameName: String)
    {
        super.init()
        self.gameName = gameName
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.killsPVE = (decoder.decodeObject(forKey: "killsPVE") as! String)
        self.killsPVP = (decoder.decodeObject(forKey: "killsPVP") as! String)
        self.playerLevelGame = (decoder.decodeObject(forKey: "consoles") as! String)
        self.playerLevelPVP = (decoder.decodeObject(forKey: "consoles") as! String)
        self.statUrl = (decoder.decodeObject(forKey: "statUrl") as! String)
        self.setPublic = (decoder.decodeObject(forKey: "setPublic") as! String)
        self.authorized = (decoder.decodeObject(forKey: "authorized") as! String)
        self.currentRank = (decoder.decodeObject(forKey: "currentRank") as! String)
        self.totalRankedWins = (decoder.decodeObject(forKey: "totalRankedWins") as! String)
        self.totalRankedLosses = (decoder.decodeObject(forKey: "totalRankedLosses") as! String)
        self.totalRankedKills = (decoder.decodeObject(forKey: "totalRankedKills") as! String)
        self.totalRankedDeaths = (decoder.decodeObject(forKey: "totalRankedDeaths") as! String)
        self.mostUsedAttacker = (decoder.decodeObject(forKey: "mostUsedAttacker") as! String)
        self.mostUsedDefender = (decoder.decodeObject(forKey: "mostUsedDefender") as! String)
        self.gearScore = (decoder.decodeObject(forKey: "gearScore") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.killsPVP, forKey: "killsPVP")
        coder.encode(self.killsPVE, forKey: "killsPVE")
        coder.encode(self.playerLevelGame, forKey: "playerLevelGame")
        coder.encode(self.statUrl, forKey: "statUrl")
        coder.encode(self.setPublic, forKey: "setPublic")
        coder.encode(self.authorized, forKey: "authorized")
        coder.encode(self.currentRank, forKey: "currentRank")
        coder.encode(self.totalRankedWins, forKey: "totalRankedWins")
        coder.encode(self.totalRankedLosses, forKey: "totalRankedLosses")
        coder.encode(self.totalRankedKills, forKey: "totalRankedKills")
        coder.encode(self.totalRankedDeaths, forKey: "totalRankedDeaths")
        coder.encode(self.mostUsedAttacker, forKey: "mostUsedAttacker")
        coder.encode(self.mostUsedDefender, forKey: "mostUsedDefender")
        coder.encode(self.gearScore, forKey: "gearScore")
    }
    
}
