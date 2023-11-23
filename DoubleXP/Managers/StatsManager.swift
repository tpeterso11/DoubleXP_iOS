//
//  StatsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import Firebase
import SwiftHTTP
import FBSDKCoreKit

class StatsManager {
    var callbacks: StatsManagerCallbacks?
    var currentGameName: String?
    
    func removeStatsForGame(gamename: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        //remove local
        for stat in user!.stats {
            if(stat.gameName == gamename){
                user!.stats.remove(at: user!.stats.index(of: stat)!)
            }
        }
        //remove db
        let ref = Database.database().reference().child("Users").child(user!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var currentStats = [StatObject]()
            if(snapshot.hasChild("stats")){
                let statsArray = snapshot.childSnapshot(forPath: "stats")
                for statObj in statsArray.children {
                    let currentObj = statObj as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gameName = dict?["gameName"] as? String ?? ""
                    let playerLevelGame = dict?["playerLevelGame"] as? String ?? ""
                    let playerLevelPVP = dict?["playerLevelPVP"] as? String ?? ""
                    let killsPVP = dict?["killsPVP"] as? String ?? ""
                    let killsPVE = dict?["killsPVE"] as? String ?? ""
                    let statURL = dict?["statURL"] as? String ?? ""
                    let setPublic = dict?["setPublic"] as? String ?? ""
                    let authorized = dict?["authorized"] as? String ?? ""
                    let currentRank = dict?["currentRank"] as? String ?? ""
                    let totalRankedWins = dict?["otalRankedWins"] as? String ?? ""
                    let totalRankedLosses = dict?["totalRankedLosses"] as? String ?? ""
                    let totalRankedKills = dict?["totalRankedKills"] as? String ?? ""
                    let totalRankedDeaths = dict?["totalRankedDeaths"] as? String ?? ""
                    let mostUsedAttacker = dict?["mostUsedAttacker"] as? String ?? ""
                    let mostUsedDefender = dict?["mostUsedDefender"] as? String ?? ""
                    let gearScore = dict?["gearScore"] as? String ?? ""
                    let codKills = dict?["codKills"] as? String ?? ""
                    let codKd = dict?["codKd"] as? String ?? ""
                    let codLevel = dict?["codLevel"] as? String ?? ""
                    let codBestKills = dict?["codBestKills"] as? String ?? ""
                    let codWins = dict?["codWins"] as? String ?? ""
                    let codWlRatio = dict?["codWlRatio"] as? String ?? ""
                    let fortniteDuoStats = dict?["fortniteDuoStats"] as? [String:String] ?? [String: String]()
                    let fortniteSoloStats = dict?["fortniteSoloStats"] as? [String:String] ?? [String: String]()
                    let fortniteSquadStats = dict?["fortniteSquadStats"] as? [String:String] ?? [String: String]()
                    let overwatchCasualStats = dict?["overwatchCasualStats"] as? [String:String] ?? [String: String]()
                    let overwatchCompetitiveStats = dict?["overwatchCompetitiveStats"] as? [String:String] ?? [String: String]()
                    let killsPerMatch = dict?["killsPerMatch"] as? String ?? ""
                    let matchesPlayed = dict?["matchesPlayed"] as? String ?? ""
                    let seasonWins = dict?["seasonWins"] as? String ?? ""
                    let seasonKills = dict?["seasonKills"] as? String ?? ""
                    let supImage = dict?["supImage"] as? String ?? ""
                    
                    let currentStat = StatObject(gameName: gameName)
                    currentStat.overwatchCasualStats = overwatchCasualStats
                    currentStat.overwatchCompetitiveStats = overwatchCompetitiveStats
                    currentStat.killsPerMatch = killsPerMatch
                    currentStat.matchesPlayed = matchesPlayed
                    currentStat.seasonWins = seasonWins
                    currentStat.seasonKills = seasonKills
                    currentStat.suppImage = supImage
                    currentStat.authorized = authorized
                    currentStat.playerLevelGame = playerLevelGame
                    currentStat.playerLevelPVP = playerLevelPVP
                    currentStat.killsPVP = killsPVP
                    currentStat.killsPVE = killsPVE
                    currentStat.statUrl = statURL
                    currentStat.setPublic = setPublic
                    currentStat.authorized = authorized
                    currentStat.currentRank = currentRank
                    currentStat.totalRankedWins = totalRankedWins
                    currentStat.totalRankedLosses = totalRankedLosses
                    currentStat.totalRankedKills = totalRankedKills
                    currentStat.totalRankedDeaths = totalRankedDeaths
                    currentStat.mostUsedAttacker = mostUsedAttacker
                    currentStat.mostUsedDefender = mostUsedDefender
                    currentStat.gearScore = gearScore
                    currentStat.codKills = codKills
                    currentStat.codKd = codKd
                    currentStat.codLevel = codLevel
                    currentStat.codBestKills = codBestKills
                    currentStat.codWins = codWins
                    currentStat.codWlRatio = codWlRatio
                    currentStat.fortniteDuoStats = fortniteDuoStats
                    currentStat.fortniteSoloStats = fortniteSoloStats
                    currentStat.fortniteSquadStats = fortniteSquadStats
                    
                    currentStats.append(currentStat)
                }
                
                for stat in currentStats {
                    if(stat.gameName == gamename){
                        currentStats.remove(at: currentStats.index(of: stat)!)
                        break
                    }
                }
                
                var sendUp = [[String: Any]]()
                for stat in currentStats {
                    let current = ["gameName": stat.gameName, "killsPVE": stat.killsPVE, "killsPVP": stat.killsPVP, "playerLevelGame": stat.playerLevelGame, "playerLevelPVP": stat.playerLevelPVP, "statUrl": stat.statUrl, "setPublic": stat.setPublic, "authorized": stat.authorized, "currentRank": stat.currentRank, "totalRankedWins": stat.totalRankedWins, "totalRankedLosses": stat.totalRankedLosses, "totalRankedKills": stat.totalRankedKills, "totalRankedDeaths": stat.totalRankedLosses, "mostUsedAttacker": stat.mostUsedAttacker, "mostUsedDefender": stat.mostUsedDefender, "gearScore": stat.gearScore,"codLevel": stat.codLevel, "codBestKills": stat.codBestKills, "codKills": stat.codKills, "codWlRatio": stat.codWlRatio, "codWins": stat.codWins, "codKd": stat.codKd, "fortniteSoloStats": stat.fortniteSoloStats, "fortniteDuoStats": stat.fortniteDuoStats, "fortniteSquadStats": stat.fortniteSquadStats, "overwatchCasualStats" : stat.overwatchCasualStats, "overwatchCompetitiveStats": stat.overwatchCompetitiveStats, "killsPerMatch": stat.killsPerMatch, "matchesPlayed" : stat.matchesPlayed, "seasonWins" : stat.seasonWins, "seasonKills" : stat.seasonKills, "supImage": stat.suppImage] as [String : Any]
                    sendUp.append(current)
                }
                
                ref.child("stats").setValue(sendUp)
                self.callbacks!.onSuccess(gameName: self.currentGameName!)
            } else {
                self.callbacks?.onSuccess(gameName: gamename)
            }
        })
    }
    
    func getStats(callbacks: StatsManagerCallbacks, gameName: String, console: String, gamerTag: String){
        self.callbacks = callbacks
        self.currentGameName = gameName
        
        if(gameName == "The Division 2"){
            getDivisionStats(gamerTag: gamerTag, console: console)
        }
        else if(gameName == "Rainbow Six Siege"){
            getRainbowSixStats(gamerTag: gamerTag, console: console)
        }
        else if(gameName == "Call Of Duty Modern Warfare"){
            getCODStats(gamerTag: gamerTag, console: console)
        }
        else if(gameName == "Fortnite"){
            getFortnitePlayerId(gamertag: gamerTag)
        }
        else if(gameName == "Apex Legends"){
            getApexLegendsStats(gamerTag: gamerTag, console: console)
        }
        else if(gameName == "Overwatch"){
            getOverwatchStats(gamerTag: gamerTag, console: console)
        }
        else if(gameName == "PlayerUnknown's Battlegrounds"){
            getPubgStats(gamerTag: gamerTag)
        }
        else {
            callbacks.onFailure(gameName: gameName)
        }
    }
    
    func getApexLegendsStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "origin"
        }
        if(!userConsole.isEmpty){
            let url = "https://public-api.tracker.gg/v2/apex/standard/profile/"+userConsole+"/"+gamerTag
            getApexLegendsProfileStats(url: url)
        }
    }
    
    func getOverwatchStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "battlenet"
        }
        
        if(!userConsole.isEmpty){
            let url = "https://public-api.tracker.gg/v2/overwatch/standard/profile/"+userConsole+"/"+gamerTag
            getOverwatchProfileStats(url: url)
        }
    }
    
    func getDivisionStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "uplay"
        }
        
        if(!userConsole.isEmpty){
            let url = "https://thedivisiontab.com/api/search.php?name="+gamerTag+"&platform="+userConsole
            getDivisionPlayerId(url: url)
        }
    }
    
    func getPubgStats(gamerTag: String){
        self.currentGameName = "PlayerUnknown's Battlegrounds"
        let url = "https://api.pubg.com/shards/steam/players?filter[playerNames]="+gamerTag
        getPubgPlayerId(url: url)
    }
    
    func getPubgPlayerId(url: String){
        let key = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI4MzI0NDFkMC0wZTJmLTAxMzktYjQzZC00ZGM1NzI4MWEwMmMiLCJpc3MiOiJnYW1lbG9ja2VyIiwiaWF0IjoxNjA1OTY3MDg5LCJwdWIiOiJibHVlaG9sZSIsInRpdGxlIjoicHViZyIsImFwcCI6ImRvdWJsZXhwIn0.EX06EJUnzhD8_-SfqNCfldP51AM4LbUyK0-d-luFufg"
        
        HTTP.GET(url, headers: ["Authorization": key,"accept": "application/json"]) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg PlayerID Error" + url))
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    let data = jsonObj?["data"] as? [[String: Any]] ?? [[String: Any]]()
                
                    for obj in data {
                        let id = obj["id"] as? String ?? ""
                        print(id)
                        
                        if(id.isEmpty){
                            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg no Id"))
                            self.callbacks!.onFailure(gameName: self.currentGameName!)
                        } else {
                            self.getPubgCurrentSeason(id: id)
                        }
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg Wrong Payload"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getPubgCurrentSeason(id: String){
        let url = "https://api.pubg.com/shards/steam/players/"+id+"/seasons/lifetime?filter[gamepad]=false"
        let key = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI4MzI0NDFkMC0wZTJmLTAxMzktYjQzZC00ZGM1NzI4MWEwMmMiLCJpc3MiOiJnYW1lbG9ja2VyIiwiaWF0IjoxNjA1OTY3MDg5LCJwdWIiOiJibHVlaG9sZSIsInRpdGxlIjoicHViZyIsImFwcCI6ImRvdWJsZXhwIn0.EX06EJUnzhD8_-SfqNCfldP51AM4LbUyK0-d-luFufg"
        
        HTTP.GET(url, headers: ["Authorization": key,"accept": "application/json"]) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg PlayerID Error" + url))
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    let data = jsonObj?["data"] as? [String: Any] ?? [String: Any]()
                    print(data)
                    let newStat = StatObject(gameName: self.currentGameName!)
                    let attributes = data["attributes"] as? [String: Any] ?? [String: Any]()
                    if(!attributes.isEmpty){
                        let gameModes = attributes["gameModeStats"] as? [String: Any] ?? [String: Any]()
                        if(!gameModes.isEmpty){
                            let duoStats = gameModes["duo"] as? [String: Any] ?? [String: Any]()
                    
                            let duoAssists = duoStats["assists"] as? Double ?? 0.0
                            let duoKills = duoStats["kills"] as? Double ?? 0.0
                            let duoHeadshotKills = duoStats["headshotKills"] as? Double ?? 0.0
                            let duoWins = duoStats["wins"] as? Double ?? 0.0
                            let duoRevives = duoStats["revives"] as? Double ?? 0.0
                            
                            let duoStatsObj = ["assists": duoAssists, "headshot kills": duoHeadshotKills, "kills": duoKills, "wins": duoWins, "revives": duoRevives]
                            
                            newStat.fortniteDuoStats = duoStatsObj
                            
                            let soloStats = gameModes["solo"] as? [String: Any] ?? [String: Any]()
                    
                            let soloAssists = soloStats["assists"] as? Double ?? 0.0
                            let soloKills = soloStats["kills"] as? Double ?? 0.0
                            let soloHeadshotKills = soloStats["headshotKills"] as? Double ?? 0.0
                            let soloWins = soloStats["wins"] as? Double ?? 0.0
                            let soloRevives = soloStats["revives"] as? Double ?? 0.0
                            let soloStatsObj = ["assists": soloAssists, "headshot kills": soloHeadshotKills, "kills": soloKills, "wins": soloWins, "revives": soloRevives]
                            
                            newStat.fortniteSoloStats = soloStatsObj
                        
                            
                            let squadStats = gameModes["squad"] as? [String: Any] ?? [String: Any]()
                            let squadAssists = squadStats["assists"] as? Double ?? 0.0
                            let squadKills = squadStats["kills"] as? Double ?? 0.0
                            let squadHeadshotKills = squadStats["headshotKills"] as? Double ?? 0.0
                            let squadWins = squadStats["wins"] as? Double ?? 0.0
                            let squadRevives = squadStats["revives"] as? Double ?? 0.0
                            
                            let squadStatsObj = ["assists": squadAssists, "headshot kills": squadHeadshotKills, "kills": squadKills, "wins": squadWins, "revives": squadRevives]
                            
                            newStat.fortniteSquadStats = squadStatsObj
                            
                            self.saveAndProceed(statObj: newStat)
                        }
                        else {
                            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg no Id"))
                            self.callbacks!.onFailure(gameName: self.currentGameName!)
                        }
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Pubg Wrong Payload"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    func getRainbowSixStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "uplay"
        }
        if(!userConsole.isEmpty){
            let url =
                "https://r6tab.com/api/search.php?platform="+userConsole+"&search="+gamerTag
            getSiegePlayerId(url: url)
        }
    }
    
    private func getApexLegendsProfileStats(url: String){
        HTTP.GET(url, headers: ["TRN-Api-Key": "7fa6a9d9-6fbc-4350-adf3-79bfe45a303c"]) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    let newStatObj = StatObject(gameName: "Apex Legends")
                    let data = jsonObj["data"] as? [String: Any] ?? [String: Any]()
                    let segments = data["segments"] as? [[String: Any]] ?? [[String: Any]]()
                    for array in segments{
                        let meta = array["metadata"] as? [String: Any] ?? [String: Any]()
                        if(meta["name"] as? String ?? "" == "Lifetime"){
                            let stats = array["stats"] as? [String: Any] ?? [String: Any]()
                            let levelStats = stats["level"] as? [String: Any] ?? [String: Any]()
                            newStatObj.playerLevelPVP = levelStats["displayValue"] as? String ?? ""
                            
                            let killStats = stats["kills"] as? [String: Any] ?? [String: Any]()
                            newStatObj.killsPVP = killStats["displayValue"] as? String ?? ""
                            
                            let kpmStats = stats["killsPerMatch"] as? [String: Any] ?? [String: Any]()
                            newStatObj.killsPerMatch = kpmStats["displayValue"] as? String ?? ""
                            
                            let matchesStats = stats["matchesPlayed"] as? [String: Any] ?? [String: Any]()
                            newStatObj.matchesPlayed = matchesStats["displayValue"] as? String ?? ""
                            
                            let seasonWinsStats = stats["seasonWins"] as? [String: Any] ?? [String: Any]()
                            newStatObj.seasonWins = seasonWinsStats["displayValue"] as? String ?? ""
                            
                            let seasonKillsStats = stats["seasonKills"] as? [String: Any] ?? [String: Any]()
                            newStatObj.seasonKills = seasonKillsStats["displayValue"] as? String ?? ""
                        }
                        else if(meta["isActive"] as? Bool == true){
                            newStatObj.suppImage = meta["tallImageUrl"] as? String ?? ""
                            break
                        }
                    }
                    newStatObj.statUrl = url
                    newStatObj.setPublic = "true"
                    newStatObj.authorized = "true"
                    
                    self.saveAndProceed(statObj: newStatObj)
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Overwatch Stats Received"))
                }
                else{
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getDivisionPlayerId(url: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                //self.callbacks!.onFailure(gameName: self.currentGameName!)
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Error" + url))
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                        
                        if let resultObj = resultArray[0] as? NSObject{
                            let statObj = StatObject(gameName: "The Division 2")
                            statObj._killsPVP = "\((resultObj.value(forKey: "kills_pvp") as? Int) ?? 0)"
                            statObj._killsPVE = "\((resultObj.value(forKey: "kills_npc") as? Int) ?? 0)"
                            statObj._playerLevelGame = "\((resultObj.value(forKey: "level_pve") as? Int) ?? 0)"
                            statObj._playerLevelPVP = "\((resultObj.value(forKey: "level_dz") as? Int) ?? 0)"
                            statObj._statUrl = url
                            statObj._setPublic = "true"
                            statObj._authorized = "true"
                            
                            let pid = (resultObj.value(forKey: "pid") as? String)!
                            if(!pid.isEmpty){
                                self.getDivisionExtendedStats(pid: pid, statObj: statObj)
                            }
                            else{
                                self.saveAndProceed(statObj: statObj)
                            }
                        }
                        else{
                            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Empty Payload" + url))
                            self.callbacks!.onFailure(gameName: self.currentGameName!)
                        }
                    }
                    else{
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID No Payload" + url))
                        self.callbacks!.onFailure(gameName: self.currentGameName!)
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID No Response" + url))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getSiegePlayerId(url: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                        
                        if let resultObj = resultArray[0] as? NSObject{
                            let statObj = StatObject(gameName: "Rainbow Six Siege")
                            statObj._currentRank = "\((resultObj.value(forKey: "p_currentrank") as? Int) ?? 0)"
                            statObj._playerLevelPVP = "\((resultObj.value(forKey: "p_level") as? Int) ?? 0)"
                            statObj._statUrl = url
                            statObj._setPublic = "true"
                            statObj._authorized = "true"
                            
                            let pid = (resultObj.value(forKey: "p_id") as? String)!
                            if(!pid.isEmpty){
                                self.getSiegeExtendedStats(pid: pid, statObj: statObj)
                            }
                            else{
                                self.saveAndProceed(statObj: statObj)
                            }
                        }
                    }
                    else{
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Empty Payload" + url))
                        self.callbacks!.onFailure(gameName: self.currentGameName!)
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Failed " + url))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getDivisionExtendedStats(pid: String, statObj: StatObject){
        let url = "https://thedivisiontab.com/api/player.php?pid="+pid
        
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats Failed"))
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    let playerFound = jsonObj!.value(forKey: "playerfound") as? Bool ?? false
                    if(!playerFound){
                        self.saveAndProceed(statObj: statObj)
                    }
                    else{
                        statObj._authorized = "true"
                        statObj._setPublic = "true"
                        statObj._killsPVP = "\((jsonObj!.value(forKey: "kills_pvp") as? Int) ?? 0)"
                        statObj._killsPVE = "\((jsonObj!.value(forKey: "kills_npc") as? Int) ?? 0)"
                        statObj._playerLevelGame = "\((jsonObj!.value(forKey: "level_pve") as? Int) ?? 0)"
                        statObj._playerLevelPVP = "\((jsonObj!.value(forKey: "level_dz") as? Int) ?? 0)"
                        statObj._gearScore = "\((jsonObj!.value(forKey: "gearscore") as? Int) ?? 0)"
                        statObj._statUrl = url
                        
                        self.saveAndProceed(statObj: statObj)
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats Received"))
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats No Payload" + url))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getSiegeExtendedStats(pid: String, statObj: StatObject){
        let url = "https://r6tab.com/api/player.php?p_id="+pid
        
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Siege Extended Stats Failed"))
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    let playerFound = jsonObj!.value(forKey: "playerfound") as? Bool ?? false
                    if(!playerFound){
                        self.saveAndProceed(statObj: statObj)
                    }
                    else{
                        statObj._authorized = "true"
                        statObj._setPublic = "true"
                        statObj._currentRank = "\((jsonObj!.value(forKey: "p_currentrank") as? Int) ?? 0)"
                        statObj._killsPVP = "\((jsonObj!.value(forKey: "p_level") as? Int) ?? 0)"
                        statObj._mostUsedAttacker = (jsonObj!.value(forKey: "favattacker") as? String)!
                        statObj._mostUsedDefender = (jsonObj!.value(forKey: "favdefender") as? String)!
                        statObj._statUrl = url
                        
                        self.saveAndProceed(statObj: statObj)
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Siege Extended Stats Received"))
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Seige Extended Stats No Response" + url))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getCODStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "uplay"
        }
        HTTP.GET("https://my.callofduty.com/api/papi-client/stats/cod/v1/title/mw/platform/" + userConsole + "/gamer/" + gamerTag + "/profile/type/mp") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    print(jsonObj.count)
                    
                    //we need to find a way to let users see their own stats. maybe in the menu.
                    var kd = 0.0
                    var wins = 0.0
                    var wlRatio = 0.0
                    var kills = 0.0
                    var bestKills = 0.0
                    
                    if let layerOne = jsonObj["data"] as? [String: Any] {
                        let level = layerOne["level"] as? Float ?? 0.0
                        if let lifetime = layerOne["lifetime"] as? [String: Any]{
                            if let any = lifetime["all"] as? [String: Any]{
                                if let properties = any["properties"] as? [String: Any]{
                                    kd = properties["kdRatio"] as? Double ?? 0.0
                                    wins = properties["wins"] as? Double ?? 0.0
                                    wlRatio = properties["wlRatio"] as? Double ?? 0.0
                                    kills = properties["kills"] as? Double ?? 0.0
                                    bestKills = properties["bestKills"] as? Double ?? 0.0
                                }
                            }
                        }
                        let statObject = StatObject(gameName: "Call Of Duty Modern Warfare")
                        statObject.codKd = String(kd)
                        statObject.codWins = String(wins)
                        statObject.codWlRatio = String(wlRatio)
                        statObject.codKills = String(kills)
                        statObject.codBestKills = String(bestKills)
                        statObject.codLevel = String(level)
                        
                        self.saveAndProceed(statObj: statObject)
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - COD Stats Received"))
                    }
                    else{
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - COD Stats No Payload"))
                        self.callbacks!.onFailure(gameName: self.currentGameName!)
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - COD No Response"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getFortnitePlayerId(gamertag: String){
        HTTP.GET("https://fortniteapi.io/lookup?username="+gamertag, headers: ["authorization": "2192fa37-951e6ed9-15f5d6d5-f1080fcf"]) { response in
            if let err = response.error {
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    let available = jsonObj["result"] as! Bool
                    if(available){
                        let id = jsonObj["account_id"] as? String ?? ""
                        
                        if(!id.isEmpty){
                            self.getFortniteStats(playerId: id)
                        } else {
                            AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite no Id"))
                            self.callbacks!.onFailure(gameName: self.currentGameName!)
                        }
                    }
                    else{
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite no Id"))
                        self.callbacks!.onFailure(gameName: self.currentGameName!)
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite Wrong Payload"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func getFortniteStats(playerId: String){
        let url = "https://fortniteapi.io/stats?account="+playerId
        HTTP.GET(url, headers: ["authorization": "2192fa37-951e6ed9-15f5d6d5-f1080fcf"]) { response in
            if let err = response.error {
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite Stats Error"))
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    let available = jsonObj["result"] as! Bool
                    if(available){
                        let account = jsonObj["account"] as? [String: Any] ?? [String: Any]()
                        let playerLevel = account["level"] as? Int ?? -1
                        
                        let globalStats = jsonObj["global_stats"] as? [String: Any] ?? [String: Any]()
                        
                        //duo
                        let duoStats = globalStats["duo"] as? [String: Any] ?? [String: Any]()
                        let duoKd = duoStats["kd"] as? Double ?? 0.0
                        let duoWinRate = duoStats["winrate"] as? Double ?? 0.0
                        let duoKills = duoStats["kills"] as? Double ?? 0.0
                        let duoMatchesPlayed = duoStats["matchesplayed"] as? Double ?? 0.0
                        
                        let duoStatsObj = ["kd": self.convertToUsableString(float:duoKd), "win rate": self.convertToUsableString(float:duoWinRate), "kills": self.convertToUsableString(float: duoKills), "matches played": self.convertToUsableString(float: duoMatchesPlayed)]
                        
                        
                        //solo
                        let soloStats = globalStats["solo"] as? [String: Any] ?? [String: Any]()
                        let soloKd = soloStats["kd"] as? Double ?? 0.0
                        let soloWinRate = soloStats["winrate"] as? Double ?? 0.0
                        let soloKills = soloStats["kills"] as? Double ?? 0.0
                        let soloMatchesPlayed = soloStats["matchesplayed"] as? Double ?? 0.0
                        let soloStatsObj = ["kd": self.convertToUsableString(float: soloKd), "win rate": self.convertToUsableString(float: soloWinRate), "kills": self.convertToUsableString(float: soloKills), "matches played": self.convertToUsableString(float: soloMatchesPlayed)]
                        //solo
                        let squadStats = globalStats["squad"] as? [String: Any] ?? [String: Any]()
                        let squadKd = squadStats["kd"] as? Double ?? 0.0
                        let squadWinRate = squadStats["winrate"] as? Double ?? 0.0
                        let squadKills = squadStats["kills"] as? Double ?? 0.0
                        let squadMatchesPlayed = squadStats["matchesplayed"] as? Double ?? 0.0
                        let squadStatsObj = ["kd": self.convertToUsableString(float: squadKd), "win rate": self.convertToUsableString(float: squadWinRate), "kills": self.convertToUsableString(float: squadKills), "matches played": self.convertToUsableString(float: squadMatchesPlayed)]
                        
                        let statObj = StatObject(gameName: "Fortnite")
                        statObj.playerLevelPVP = String(playerLevel)
                        statObj.fortniteDuoStats = duoStatsObj
                        statObj.fortniteSoloStats = soloStatsObj
                        statObj.fortniteSquadStats = squadStatsObj
                        statObj.statUrl = url
                        statObj.setPublic = "true"
                        statObj.authorized = "true"
                        
                        self.saveAndProceed(statObj: statObj)
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - COD Stats Received"))
                    }
                    else{
                        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite Not Available"))
                        self.callbacks!.onFailure(gameName: self.currentGameName!)
                    }
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Fortnite Wrong Payload"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    private func convertToUsableString(float: Double) -> String{
        let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        
            let convert = float
            if let formattedString = formatter.string(for: convert) {
                return formattedString
            } else {
                return ""
        }
    }
    
    private func getOverwatchProfileStats(url: String){
        HTTP.GET(url, headers: ["TRN-Api-Key": "7fa6a9d9-6fbc-4350-adf3-79bfe45a303c"]) { response in
            if let err = response.error {
                AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Overwatch Profile Stats Error"))
                self.callbacks!.onFailure(gameName: self.currentGameName!)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    let newStatObj = StatObject(gameName: "Overwatch")
                    let data = jsonObj["data"] as? [String: Any] ?? [String: Any]()
                    let segments = data["segments"] as? [[String: Any]] ?? [[String: Any]]()
                    for array in segments{
                        let meta = array["metadata"] as? [String: Any] ?? [String: Any]()
                        if(meta["name"] as? String ?? "" == "Casual"){
                            var casual = [String: String]()
                            
                            let stats = array["stats"] as? [String: Any] ?? [String: Any]()
                            let wins = stats["wins"] as? [String: Any] ?? [String: Any]()
                            let winsVal = wins["displayValue"] as? String ?? ""
                            if(!winsVal.isEmpty){
                                casual["Wins"] = winsVal
                            }
                            
                            let matchesStats = stats["matchesPlayed"] as? [String: Any] ?? [String: Any]()
                            let matchesPlayedVal = matchesStats["displayValue"] as? String ?? ""
                            if(!matchesPlayedVal.isEmpty){
                                casual["Matches Played"] = matchesPlayedVal
                            }
                            
                            let goldMedals = stats["goldMedals"] as? [String: Any] ?? [String: Any]()
                            let goldMedalVal = goldMedals["displayValue"] as? String ?? ""
                            if(!goldMedalVal.isEmpty){
                                casual["Gold Medals"] = goldMedalVal
                            }
                            
                            let silverMedals = stats["silverMedals"] as? [String: Any] ?? [String: Any]()
                            let silverMedalsVal = silverMedals["displayValue"] as? String ?? ""
                            if(!silverMedalsVal.isEmpty){
                                casual["Silver Medals"] = silverMedalsVal
                            }
                            
                            let bronzeMedals = stats["bronzeMedals"] as? [String: Any] ?? [String: Any]()
                            let bronzeMedalsVal = bronzeMedals["displayValue"] as? String ?? ""
                            if(!bronzeMedalsVal.isEmpty){
                                casual["Bronze Medals"] = bronzeMedalsVal
                            }
                            
                            let multiKills = stats["multiKills"] as? [String: Any] ?? [String: Any]()
                            let multiKillsVal = multiKills["displayValue"] as? String ?? ""
                            if(!multiKillsVal.isEmpty){
                                casual["Multi Kills"] = multiKillsVal
                            }
                            
                            let soloKills = stats["soloKills"] as? [String: Any] ?? [String: Any]()
                            let soloKillsVal = soloKills["displayValue"] as? String ?? ""
                            if(!soloKillsVal.isEmpty){
                                casual["Solo Kills"] = soloKillsVal
                            }
                            
                            let objectiveKills = stats["objectiveKills"] as? [String: Any] ?? [String: Any]()
                            let objectiveKillsVal = objectiveKills["displayValue"] as? String ?? ""
                            if(!objectiveKillsVal.isEmpty){
                                casual["Objective Kills"] = objectiveKillsVal
                            }
                            
                            let finalBlows = stats["finalBlows"] as? [String: Any] ?? [String: Any]()
                            let finalBlowsVal = finalBlows["displayValue"] as? String ?? ""
                            if(!finalBlowsVal.isEmpty){
                                casual["Final Blows"] = finalBlowsVal
                            }
                            
                            let damageDone = stats["damageDone"] as? [String: Any] ?? [String: Any]()
                            let damageDoneVal = damageDone["displayValue"] as? String ?? ""
                            if(!damageDoneVal.isEmpty){
                                casual["Damage Done"] = damageDoneVal
                            }
                            
                            let healingDone = stats["healingDone"] as? [String: Any] ?? [String: Any]()
                            let healingDoneVal = healingDone["displayValue"] as? String ?? ""
                            if(!healingDoneVal.isEmpty){
                                casual["Healing Done"] = healingDoneVal
                            }
                            
                            let eliminations = stats["eliminations"] as? [String: Any] ?? [String: Any]()
                            let eliminationsVal = eliminations["displayValue"] as? String ?? ""
                            if(!eliminationsVal.isEmpty){
                                casual["Eliminations"] = eliminationsVal
                            }
                            
                            let kd = stats["kd"] as? [String: Any] ?? [String: Any]()
                            let kdVal = kd["displayValue"] as? String ?? ""
                            if(!kdVal.isEmpty){
                                casual["KD"] = kdVal
                            }
                            
                            let defensiveAssists = stats["defensiveAssists"] as? [String: Any] ?? [String: Any]()
                            let defensiveAssistsVal = defensiveAssists["displayValue"] as? String ?? ""
                            if(!defensiveAssistsVal.isEmpty){
                                casual["Defensive Assists"] = defensiveAssistsVal
                            }
                            
                            let offensiveAssists = stats["offensiveAssists"] as? [String: Any] ?? [String: Any]()
                            let offensiveAssistsVal = offensiveAssists["displayValue"] as? String ?? ""
                            if(!offensiveAssistsVal.isEmpty){
                                casual["Offensive Assists"] = offensiveAssistsVal
                            }
                            
                            newStatObj.overwatchCasualStats = casual
                        }
                        else if(meta["name"] as? String ?? "" == "Competitive"){
                            var competitive = [String: String]()
                            
                            let stats = array["stats"] as? [String: Any] ?? [String: Any]()
                            let wins = stats["wins"] as? [String: Any] ?? [String: Any]()
                            let winsVal = wins["displayValue"] as? String ?? ""
                            if(!winsVal.isEmpty){
                                competitive["Wins"] = winsVal
                            }
                            
                            let matchesStats = stats["matchesPlayed"] as? [String: Any] ?? [String: Any]()
                            let matchesPlayedVal = matchesStats["displayValue"] as? String ?? ""
                            if(!matchesPlayedVal.isEmpty){
                                competitive["Matches Played"] = matchesPlayedVal
                            }
                            
                            let goldMedals = stats["goldMedals"] as? [String: Any] ?? [String: Any]()
                            let goldMedalVal = goldMedals["displayValue"] as? String ?? ""
                            if(!goldMedalVal.isEmpty){
                                competitive["Gold Medals"] = goldMedalVal
                            }
                            
                            let silverMedals = stats["silverMedals"] as? [String: Any] ?? [String: Any]()
                            let silverMedalsVal = silverMedals["displayValue"] as? String ?? ""
                            if(!silverMedalsVal.isEmpty){
                                competitive["Silver Medals"] = silverMedalsVal
                            }
                            
                            let bronzeMedals = stats["bronzeMedals"] as? [String: Any] ?? [String: Any]()
                            let bronzeMedalsVal = bronzeMedals["displayValue"] as? String ?? ""
                            if(!bronzeMedalsVal.isEmpty){
                                competitive["Bronze Medals"] = bronzeMedalsVal
                            }
                            
                            let multiKills = stats["multiKills"] as? [String: Any] ?? [String: Any]()
                            let multiKillsVal = multiKills["displayValue"] as? String ?? ""
                            if(!multiKillsVal.isEmpty){
                                competitive["Multi Kills"] = multiKillsVal
                            }
                            
                            let soloKills = stats["soloKills"] as? [String: Any] ?? [String: Any]()
                            let soloKillsVal = soloKills["displayValue"] as? String ?? ""
                            if(!soloKillsVal.isEmpty){
                                competitive["Solo Kills"] = soloKillsVal
                            }
                            
                            let objectiveKills = stats["objectiveKills"] as? [String: Any] ?? [String: Any]()
                            let objectiveKillsVal = objectiveKills["displayValue"] as? String ?? ""
                            if(!objectiveKillsVal.isEmpty){
                                competitive["Objective Kills"] = objectiveKillsVal
                            }
                            
                            let finalBlows = stats["finalBlows"] as? [String: Any] ?? [String: Any]()
                            let finalBlowsVal = finalBlows["displayValue"] as? String ?? ""
                            if(!finalBlowsVal.isEmpty){
                                competitive["Final Blows"] = finalBlowsVal
                            }
                            
                            let damageDone = stats["damageDone"] as? [String: Any] ?? [String: Any]()
                            let damageDoneVal = damageDone["displayValue"] as? String ?? ""
                            if(!damageDoneVal.isEmpty){
                                competitive["Damage Done"] = damageDoneVal
                            }
                            
                            let healingDone = stats["healingDone"] as? [String: Any] ?? [String: Any]()
                            let healingDoneVal = healingDone["displayValue"] as? String ?? ""
                            if(!healingDoneVal.isEmpty){
                                competitive["Healing Done"] = healingDoneVal
                            }
                            
                            let eliminations = stats["eliminations"] as? [String: Any] ?? [String: Any]()
                            let eliminationsVal = eliminations["displayValue"] as? String ?? ""
                            if(!eliminationsVal.isEmpty){
                                competitive["Eliminations"] = eliminationsVal
                            }
                            
                            let kd = stats["kd"] as? [String: Any] ?? [String: Any]()
                            let kdVal = kd["displayValue"] as? String ?? ""
                            if(!kdVal.isEmpty){
                                competitive["KD"] = kdVal
                            }
                            
                            let defensiveAssists = stats["defensiveAssists"] as? [String: Any] ?? [String: Any]()
                            let defensiveAssistsVal = defensiveAssists["displayValue"] as? String ?? ""
                            if(!defensiveAssistsVal.isEmpty){
                                competitive["Defensive Assists"] = defensiveAssistsVal
                            }
                            
                            let offensiveAssists = stats["offensiveAssists"] as? [String: Any] ?? [String: Any]()
                            let offensiveAssistsVal = offensiveAssists["displayValue"] as? String ?? ""
                            if(!offensiveAssistsVal.isEmpty){
                                competitive["Offensive Assists"] = offensiveAssistsVal
                            }
                            
                            newStatObj.overwatchCompetitiveStats = competitive
                            break
                        }
                    }
                    newStatObj.statUrl = url
                    newStatObj.setPublic = "true"
                    newStatObj.authorized = "true"
                    
                    self.saveAndProceed(statObj: newStatObj)
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Overwatch Stats Received"))
                }
                else{
                    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "GC Register - Overwatch Profile Stats Incorrect Payload"))
                    self.callbacks!.onFailure(gameName: self.currentGameName!)
                }
            }
        }
    }
    
    
    private func saveAndProceed(statObj: StatObject){
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.currentUser

            let current = ["gameName": statObj.gameName, "killsPVE": statObj.killsPVE, "killsPVP": statObj.killsPVP, "playerLevelGame": statObj.playerLevelGame, "playerLevelPVP": statObj.playerLevelPVP, "statUrl": statObj.statUrl, "setPublic": statObj.setPublic, "authorized": statObj.authorized, "currentRank": statObj.currentRank, "totalRankedWins": statObj.totalRankedWins, "totalRankedLosses": statObj.totalRankedLosses, "totalRankedKills": statObj.totalRankedKills, "totalRankedDeaths": statObj.totalRankedLosses, "mostUsedAttacker": statObj.mostUsedAttacker, "mostUsedDefender": statObj.mostUsedDefender, "gearScore": statObj.gearScore,
                "codLevel": statObj.codLevel, "codBestKills": statObj.codBestKills, "codKills": statObj.codKills,
                "codWlRatio": statObj.codWlRatio, "codWins": statObj.codWins, "codKd": statObj.codKd, "fortniteSoloStats": statObj.fortniteSoloStats, "fortniteDuoStats": statObj.fortniteDuoStats, "fortniteSquadStats": statObj.fortniteSquadStats, "overwatchCasualStats" : statObj.overwatchCasualStats, "overwatchCompetitiveStats": statObj.overwatchCompetitiveStats, "killsPerMatch": statObj.killsPerMatch, "matchesPlayed" : statObj.matchesPlayed,
                "seasonWins" : statObj.seasonWins, "seasonKills" : statObj.seasonKills, "supImage": statObj.suppImage] as [String : Any]
            
            user?.stats.append(statObj)
            self.zipItUp(statObj: statObj, payload: current)
        }
    }
    
    private func zipItUp(statObj: StatObject, payload: [String: Any]){
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.currentUser
            
            let ref = Database.database().reference().child("Users").child((user?.uId)!)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    var currentStats = [StatObject]()
                    if(snapshot.hasChild("stats")){
                        let statsArray = snapshot.childSnapshot(forPath: "stats")
                        for statObj in statsArray.children {
                            let currentObj = statObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gameName = dict?["gameName"] as? String ?? ""
                            let playerLevelGame = dict?["playerLevelGame"] as? String ?? ""
                            let playerLevelPVP = dict?["playerLevelPVP"] as? String ?? ""
                            let killsPVP = dict?["killsPVP"] as? String ?? ""
                            let killsPVE = dict?["killsPVE"] as? String ?? ""
                            let statURL = dict?["statURL"] as? String ?? ""
                            let setPublic = dict?["setPublic"] as? String ?? ""
                            let authorized = dict?["authorized"] as? String ?? ""
                            let currentRank = dict?["currentRank"] as? String ?? ""
                            let totalRankedWins = dict?["otalRankedWins"] as? String ?? ""
                            let totalRankedLosses = dict?["totalRankedLosses"] as? String ?? ""
                            let totalRankedKills = dict?["totalRankedKills"] as? String ?? ""
                            let totalRankedDeaths = dict?["totalRankedDeaths"] as? String ?? ""
                            let mostUsedAttacker = dict?["mostUsedAttacker"] as? String ?? ""
                            let mostUsedDefender = dict?["mostUsedDefender"] as? String ?? ""
                            let gearScore = dict?["gearScore"] as? String ?? ""
                            let codKills = dict?["codKills"] as? String ?? ""
                            let codKd = dict?["codKd"] as? String ?? ""
                            let codLevel = dict?["codLevel"] as? String ?? ""
                            let codBestKills = dict?["codBestKills"] as? String ?? ""
                            let codWins = dict?["codWins"] as? String ?? ""
                            let codWlRatio = dict?["codWlRatio"] as? String ?? ""
                            let fortniteDuoStats = dict?["fortniteDuoStats"] as? [String:String] ?? [String: String]()
                            let fortniteSoloStats = dict?["fortniteSoloStats"] as? [String:String] ?? [String: String]()
                            let fortniteSquadStats = dict?["fortniteSquadStats"] as? [String:String] ?? [String: String]()
                            let overwatchCasualStats = dict?["overwatchCasualStats"] as? [String:String] ?? [String: String]()
                            let overwatchCompetitiveStats = dict?["overwatchCompetitiveStats"] as? [String:String] ?? [String: String]()
                            let killsPerMatch = dict?["killsPerMatch"] as? String ?? ""
                            let matchesPlayed = dict?["matchesPlayed"] as? String ?? ""
                            let seasonWins = dict?["seasonWins"] as? String ?? ""
                            let seasonKills = dict?["seasonKills"] as? String ?? ""
                            let supImage = dict?["supImage"] as? String ?? ""
                            
                            let currentStat = StatObject(gameName: gameName)
                            currentStat.overwatchCasualStats = overwatchCasualStats
                            currentStat.overwatchCompetitiveStats = overwatchCompetitiveStats
                            currentStat.killsPerMatch = killsPerMatch
                            currentStat.matchesPlayed = matchesPlayed
                            currentStat.seasonWins = seasonWins
                            currentStat.seasonKills = seasonKills
                            currentStat.suppImage = supImage
                            currentStat.authorized = authorized
                            currentStat.playerLevelGame = playerLevelGame
                            currentStat.playerLevelPVP = playerLevelPVP
                            currentStat.killsPVP = killsPVP
                            currentStat.killsPVE = killsPVE
                            currentStat.statUrl = statURL
                            currentStat.setPublic = setPublic
                            currentStat.authorized = authorized
                            currentStat.currentRank = currentRank
                            currentStat.totalRankedWins = totalRankedWins
                            currentStat.totalRankedLosses = totalRankedLosses
                            currentStat.totalRankedKills = totalRankedKills
                            currentStat.totalRankedDeaths = totalRankedDeaths
                            currentStat.mostUsedAttacker = mostUsedAttacker
                            currentStat.mostUsedDefender = mostUsedDefender
                            currentStat.gearScore = gearScore
                            currentStat.codKills = codKills
                            currentStat.codKd = codKd
                            currentStat.codLevel = codLevel
                            currentStat.codBestKills = codBestKills
                            currentStat.codWins = codWins
                            currentStat.codWlRatio = codWlRatio
                            currentStat.fortniteDuoStats = fortniteDuoStats
                            currentStat.fortniteSoloStats = fortniteSoloStats
                            currentStat.fortniteSquadStats = fortniteSquadStats
                            
                            currentStats.append(currentStat)
                        }
                        
                        if(!currentStats.isEmpty){
                            for stat in currentStats {
                                if(stat.gameName == statObj.gameName){
                                    currentStats.remove(at: currentStats.index(of: stat)!)
                                    break
                                }
                            }
                            
                            var sendUp = [[String: Any]]()
                            sendUp.append(payload)
                            for stat in currentStats {
                                let current = ["gameName": stat.gameName, "killsPVE": stat.killsPVE, "killsPVP": stat.killsPVP, "playerLevelGame": stat.playerLevelGame, "playerLevelPVP": stat.playerLevelPVP, "statUrl": stat.statUrl, "setPublic": stat.setPublic, "authorized": stat.authorized, "currentRank": stat.currentRank, "totalRankedWins": stat.totalRankedWins, "totalRankedLosses": stat.totalRankedLosses, "totalRankedKills": stat.totalRankedKills, "totalRankedDeaths": stat.totalRankedLosses, "mostUsedAttacker": stat.mostUsedAttacker, "mostUsedDefender": stat.mostUsedDefender, "gearScore": stat.gearScore,"codLevel": stat.codLevel, "codBestKills": stat.codBestKills, "codKills": stat.codKills, "codWlRatio": stat.codWlRatio, "codWins": stat.codWins, "codKd": stat.codKd, "fortniteSoloStats": stat.fortniteSoloStats, "fortniteDuoStats": stat.fortniteDuoStats, "fortniteSquadStats": stat.fortniteSquadStats, "overwatchCasualStats" : stat.overwatchCasualStats, "overwatchCompetitiveStats": stat.overwatchCompetitiveStats, "killsPerMatch": stat.killsPerMatch, "matchesPlayed" : stat.matchesPlayed, "seasonWins" : stat.seasonWins, "seasonKills" : stat.seasonKills, "supImage": statObj.suppImage] as [String : Any]
                                sendUp.append(current)
                            }
                            
                            ref.child("stats").setValue(sendUp)
                            self.callbacks!.onSuccess(gameName: self.currentGameName!)
                        } else {
                            var sendUp = [[String: Any]]()
                            sendUp.append(payload)
                            ref.child("stats").setValue(sendUp)
                            self.callbacks!.onSuccess(gameName: self.currentGameName!)
                        }
                    } else {
                        var sendUp = [[String: Any]]()
                        sendUp.append(payload)
                        ref.child("stats").setValue(sendUp)
                        self.callbacks!.onSuccess(gameName: self.currentGameName!)
                    }
                }
            })
        }
    }
}
