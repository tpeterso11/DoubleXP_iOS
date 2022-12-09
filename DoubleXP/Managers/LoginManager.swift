//
//  LoginManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class LoginHelper{
    
    func getFeedInfo(uid: String?, activity: PreSplashActivity) {
        self.getFeaturedGame(uid: uid, activity: activity)
    }
    
    func getFeaturedGame(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Feed")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("featuredGame")){
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.feedFeaturedGame = snapshot.childSnapshot(forPath: "featuredGame").value as? String ?? ""
                    self.getFeedCta(uid: uid, activity: activity)
                } else {
                    self.getFeedCta(uid: uid, activity: activity)
                }
            } else {
                self.getFeedCta(uid: uid, activity: activity)
            }
        })
    }
    
    func getFeedCta(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Feed")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("cta")){
                    var title = ""
                    var sub = ""
                    var imgDark = ""
                    var buttonText = ""
                    var imgLight = ""
                    let cta = snapshot.childSnapshot(forPath: "cta")
                    if(cta.hasChild("title")){
                        title = cta.childSnapshot(forPath: "title").value as? String ?? ""
                    }
                    if(cta.hasChild("sub")){
                        sub = cta.childSnapshot(forPath: "sub").value as? String ?? ""
                    }
                    if(cta.hasChild("buttonText")){
                        buttonText = cta.childSnapshot(forPath: "buttonText").value as? String ?? ""
                    }
                    if(cta.hasChild("imgDarkXXHDPI")){
                        imgDark = cta.childSnapshot(forPath: "imgDarkXXHDPI").value as? String ?? ""
                    }
                    if(cta.hasChild("imgLightXXHDPI")){
                        imgLight = cta.childSnapshot(forPath: "imgLightXXHDPI").value as? String ?? ""
                    }
                    if(!title.isEmpty && !sub.isEmpty && !imgDark.isEmpty && !imgLight.isEmpty && !buttonText.isEmpty){
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.currentCta = CTAObject(title: title, sub: sub, lightUrl: imgLight, darkUrl: imgDark, buttonText: buttonText)
                    }
                    self.getCompetitions(uid: uid, activity: activity)
                } else {
                    self.getCompetitions(uid: uid, activity: activity)
                }
            } else {
                self.getCompetitions(uid: uid, activity: activity)
            }
        })
    }
    
    func getCompetitions(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Competitions")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var displayCompetitions = [CompetitionObj]()
                
                for competition in snapshot.children{
                    let currentObj = competition as? DataSnapshot
                    let dict = currentObj?.value as? [String: Any]
                    
                    let competitonName = dict?["competitionName"] as? String ?? ""
                    let competitionId = dict?["competitionId"] as? String ?? ""
                    let gameName = dict?["gameName"] as? String ?? ""
                    let mainSponsor = dict?["sponsor"] as? String ?? ""
                    let sponsorUrl = dict?["sponsorUrl"] as? String ?? ""
                    let rulesUrl = dict?["rulesUrl"] as? String ?? ""
                    let topPrize = dict?["topPrize"] as? String ?? ""
                    let topPrizeType = dict?["topPrizeType"] as? String ?? ""
                    let expired = dict?["expired"] as? String ?? ""
                    let secondPrize = dict?["secondPrize"] as? String ?? ""
                    let thirdPrize = dict?["thirdPrize"] as? String ?? ""
                    let competitionDate = dict?["competitionDate"] as? String ?? ""
                    let competitionAirDate = dict?["competitionAirDate"] as? String ?? ""
                    let competitionAirDateString = dict?["competitionAirDateString"] as? String ?? ""
                    let emergencyShowRegistrationOver = dict?["emergencyShowRegistrationOver"] as? String ?? ""
                    let emergencyShowLiveStream = dict?["emergencyShowLiveStream"] as? String ?? ""
                    let competitionDateString = dict?["competitionDateString"] as? String ?? ""
                    let registrationDeadlineMillis = dict?["registrationDeadlineMillis"] as? CLong ?? 0
                    let twitchChannelId = dict?["twitchChannelId"] as? String ?? ""
                    let gcName = dict?["gcName"] as? String ?? ""
                    let subscriptionId = dict?["subscriptionId"] as? String ?? ""
                    let promoImg = dict?["promoUrlxxhdpi"] as? String ?? ""
                    let headerImg = dict?["headerImageUrlXXHDPI"] as? String ?? ""
                    let compTopic = dict?["competitionTopic"] as? String ?? ""
                    let compDescription = dict?["description"] as? String ?? ""
                    let rundown = dict?["rundown"] as? [String] ?? [String]()
                    
                    /*var competitors = [CompetitorObj]()
                    let competitorArray = competition.childSnapshot(forPath: "competitors")
                    for competitor in competitorArray.children{
                        let currentObj = competitor as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newCompetitor = CompetitorObj(gamerTag: gamerTag, uid: uid)
                        competitors.append(newCompetitor)
                    }*/
                    
                    let newCompetition = CompetitionObj(competitionName: competitonName, competitionId: competitionId, gameName: gameName, mainSponsor: mainSponsor)
                    newCompetition.topPrize = topPrize
                    newCompetition.secondPrize = secondPrize
                    newCompetition.thirdPrize = thirdPrize
                    newCompetition.registrationDeadlineMillis = String(registrationDeadlineMillis)
                    newCompetition.twitchChannelId = twitchChannelId
                    newCompetition.competitionDate = competitionDate
                    newCompetition.competitionDateString = competitionDateString
                    newCompetition.competitionAirDate = competitionAirDate
                    newCompetition.competitionAirDateString = competitionAirDateString
                    newCompetition.gcName = gcName
                    newCompetition.subscriptionId = subscriptionId
                    newCompetition.emergencyShowLiveStream = emergencyShowLiveStream
                    newCompetition.emergencyShowRegistrationOver = emergencyShowRegistrationOver
                    newCompetition.expired = expired
                    newCompetition.promoImgUrl = promoImg
                    newCompetition.headerImgUrl = headerImg
                    newCompetition.competitionTopic = compTopic
                    newCompetition.topPrizeType = topPrizeType
                    newCompetition.compDescription = compDescription
                    newCompetition.rundown = rundown
                    newCompetition.sponsorUrl = sponsorUrl
                    newCompetition.rulesUrl = rulesUrl
                    
                    if(expired != "true"){
                        displayCompetitions.append(newCompetition)
                    }
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.competitions = displayCompetitions
                
                self.getAnnouncements(uid: uid, activity: activity)
            }
            else{
                self.getAnnouncements(uid: uid, activity: activity)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            
            self.getAnnouncements(uid: uid, activity: activity)
        }
    }
    
    func getAnnouncements(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Announcements")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var announcements = [AnnouncementObj]()
                for announcement in snapshot.children {
                    var games = [String]()
                    var active = "false"
                    var title = ""
                    var message = ""
                    var duration = ""
                    var id = ""
                    var sender = ""
                    var details = ""
                    var audience = [String]()
                    
                    let current = announcement as! DataSnapshot
                    id = current.key
                    
                    if(current.hasChild("games")){
                        let gameList = current.childSnapshot(forPath: "games")
                        for game in gameList.children {
                            games.append((game as! DataSnapshot).value as? String ?? "")
                        }
                    }
                    
                    if(current.hasChild("active")){
                        active = current.childSnapshot(forPath: "active").value as! String
                    }
                    
                    if(current.hasChild("title")){
                        title = current.childSnapshot(forPath: "title").value as! String
                    }
                    
                    if(current.hasChild("message")){
                        message = current.childSnapshot(forPath: "message").value as! String
                    }
                    
                    if(current.hasChild("sender")){
                        sender = current.childSnapshot(forPath: "sender").value as! String
                    }
                    
                    if(current.hasChild("details")){
                        details = current.childSnapshot(forPath: "details").value as! String
                    }
                    
                    if(current.hasChild("audience")){
                        if(current.childSnapshot(forPath: "audience").value is String){
                            audience = [current.childSnapshot(forPath: "audience").value as! String]
                        } else {
                            audience = current.childSnapshot(forPath: "audience").value as! [String]
                        }
                    }
                    
                    if(current.hasChild("duration")){
                        duration = current.childSnapshot(forPath: "duration").value as! String
                    }
                    
                    if(!games.isEmpty && active == "true" && !title.isEmpty && !message.isEmpty){
                        let newAnnouncement = AnnouncementObj(announcementId: id, announcementTitle: title, announcementMessage: message, announcementActive: active, announcementGames: games, announcementDuration: duration, announcementAudience: audience, announcementSender: sender, announcementDetails: details)
                        
                        announcements.append(newAnnouncement)
                    }
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.announcementManager.announcments.append(contentsOf: announcements)
                
                self.getUpcomingGames(uid: uid, activity: activity)
            } else {
                let announcements = [AnnouncementObj]()
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.announcementManager.announcments.append(contentsOf: announcements)
                
                self.getUpcomingGames(uid: uid, activity: activity)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            
            self.getUpcomingGames(uid: uid, activity: activity)
        }
    }
    
    func getEpisodes(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Media")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var displayEpisodes = [EpisodeObj]()
                
                for episode in snapshot.children{
                    let currentObj = episode as? DataSnapshot
                    let dict = currentObj?.value as? [String: Any]
                    
                    let episodeName = dict?["name"] as? String ?? ""
                    let mediaId = dict?["mediaId"] as? String ?? ""
                    let sub = dict?["sub"] as? String ?? ""
                    let featuring = dict?["featuring"] as? String ?? ""
                    let imageUrl = dict?["imageUrlXXHDPI"] as? String ?? ""
                    let mediaType = dict?["mediaType"] as? String ?? ""
                    let url = dict?["url"] as? String ?? ""
                    
                    let newEpisode = EpisodeObj(mediaId: mediaId, name: episodeName, imageUrl: imageUrl, mediaType: mediaType, sub: sub, url: url, featuring: featuring)
                    
                    displayEpisodes.append(newEpisode)
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.episodes = displayEpisodes
                
                activity.onFeedCompleted(uid: uid ?? "")
            } else {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let displayEpisodes = [EpisodeObj]()
                delegate.episodes = displayEpisodes
                
                activity.onFeedCompleted(uid: uid ?? "")
            }
        }) { (error) in
            print(error.localizedDescription)
            activity.onFeedCompleted(uid: uid ?? "")
        }
    }
    
    func getUpcomingGames(uid: String?, activity: PreSplashActivity){
        let ref = Database.database().reference().child("Upcoming Games")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var upcoming = [UpcomingGame]()
                for upGame in snapshot.children {
                    var game = ""
                    var trailerUrls = [String: String]()
                    var gameImageUrl = ""
                    var blurb = ""
                    var releaseDate = ""
                    var id = ""
                    var developer = ""
                    var releaseDateMillis = ""
                    var description = ""
                    var releaseDateProper = ""
                    var consoles = [String]()
                    
                    let current = upGame as! DataSnapshot
                    id = current.key
                    
                    if(current.hasChild("trailerUrls")){
                        trailerUrls = current.childSnapshot(forPath: "trailerUrls").value as? [String: String] ?? [String: String]()
                    }
                    
                    if(current.hasChild("game")){
                        game = current.childSnapshot(forPath: "game").value as! String
                    }
                    
                    if(current.hasChild("gameImageXXHDPI")){
                        gameImageUrl = current.childSnapshot(forPath: "gameImageXXHDPI").value as! String
                    }
                    
                    if(current.hasChild("blurb")){
                        blurb = current.childSnapshot(forPath: "blurb").value as! String
                    }
                    
                    if(current.hasChild("releaseDate")){
                        releaseDate = current.childSnapshot(forPath: "releaseDate").value as! String
                    }
                    
                    if(current.hasChild("releaseDateMillis")){
                        releaseDateMillis = current.childSnapshot(forPath: "releaseDateMillis").value as! String
                    }
                    
                    if(current.hasChild("developer")){
                        developer = current.childSnapshot(forPath: "developer").value as! String
                    }
                    
                    if(current.hasChild("description")){
                        description = current.childSnapshot(forPath: "description").value as! String
                    }
                    
                    if(current.hasChild("releaseDateProp")){
                        releaseDateProper = current.childSnapshot(forPath: "releaseDateProp").value as! String
                    }
                    
                    if(current.hasChild("consoles")){
                        consoles = current.childSnapshot(forPath: "consoles").value as? [String] ?? [String]()
                    }
                    
                    if(!game.isEmpty && !gameImageUrl.isEmpty && !developer.isEmpty){
                        let upcomingGame = UpcomingGame(id: id, game: game, blurb: blurb, releaseDateMillis: releaseDateMillis, releaseDate: releaseDate, trailerUrls: trailerUrls, gameImageUrl: gameImageUrl, gameDesc: description, releaseDateProper: releaseDateProper)
                        upcomingGame.consoles = consoles
                        upcomingGame.developer = developer
                        upcoming.append(upcomingGame)
                    }
                }
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.upcomingGames.append(contentsOf: upcoming)
                
                self.getEpisodes(uid: uid, activity: activity)
            } else {
                let upcoming = [UpcomingGame]()
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.upcomingGames.append(contentsOf: upcoming)
                
                self.getEpisodes(uid: uid, activity: activity)
            }
        }) { (error) in
            print(error.localizedDescription)
            
            self.getEpisodes(uid: uid, activity: activity)
        }
    }
}

