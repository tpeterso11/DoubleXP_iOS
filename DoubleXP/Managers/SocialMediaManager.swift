//
//  SocialMediaManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftTwitch
import SwiftHTTP
import Firebase
import FBSDKLoginKit

class SocialMediaManager{
    var token = ""
    
    func getToken() -> String{
        return self.token
    }
    
    func setToken(token: String){
        self.token = token
    }
    
    func getTwitchAppToken(token: String?, uid: String){
        if(token != nil){
            validateToken(token: token!, uid: uid)
        } else{
            getTwitchToken(uid: uid)
        }
    }
    
    private func getTwitchToken(uid: String){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/initTwitch") { response in
            if let err = response.error {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let manager = appDelegate.socialMediaManager
                manager.setToken(token: "")
                return
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    DispatchQueue.main.async {
                        let token = jsonObj["access_token"] as! String
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let manager = appDelegate.socialMediaManager
                        manager.setToken(token: token)
                        
                        let ref = Database.database().reference().child("Users").child(uid)
                        ref.child("twitchAppToken").setValue(token)
                    }
                }
                else{
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let manager = appDelegate.socialMediaManager
                    manager.setToken(token: "")
                }
            }
        }
    }
    
    private func validateToken(token: String, uid: String){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/validateToken?token=" + token) { response in
            if let err = response.error {
                self.getTwitchToken(uid: uid)
                return
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    let status = jsonObj["message"] as? String ?? ""
                    if(!status.isEmpty){
                        if(status == "missing authorization token"){
                            //AppEvents.logEvent(AppEvents.Name(rawValue: "tokens missing for validation"))
                        } else if(status == "invalid access token") {
                            //AppEvents.logEvent(AppEvents.Name(rawValue: "invalid access tokens being sent"))
                        }
                        let ref = Database.database().reference().child("Users").child(uid)
                        ref.child("twitchAppToken").removeValue()
                        
                        self.getTwitchToken(uid: uid)
                    } else {
                         DispatchQueue.main.async {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            let manager = appDelegate.socialMediaManager
                            manager.token = token
                        }
                    }
                }
                else{
                    self.getTwitchToken(uid: uid)
                }
            }
        }
    }
    
    func getTwitchGames(callbacks: SocialMediaManagerCallback){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/getGames?token=" + token) { response in
            if let err = response.error {
                var channels = [TwitchChannelObj]()
                let delegate = UIApplication.shared.delegate as! AppDelegate
                channels.append(contentsOf: delegate.twitchChannels)
                callbacks.onChannelsLoaded(channels: channels)
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                        DispatchQueue.main.async {
                            var channels = [TwitchChannelObj]()
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            let gameList = delegate.gcGames!
                            
                            for game in resultArray{
                                if let gameDict = game as? NSDictionary {
                                        let name = (gameDict.value(forKey: "name") as? String ?? "")
                                        let imageUrlIOS = (gameDict.value(forKey: "box_art_url") as? String ?? "")
                                        let twitchId = (gameDict.value(forKey: "id") as? String ?? "")
                                        
                                        let obj = TwitchChannelObj(gameName: name, imageUrIOS: imageUrlIOS, twitchID: twitchId)
                                        for gcGame in gameList {
                                            if(gcGame.gameName == obj.gameName){
                                                obj.isGCGame = "true"
                                                obj.gcGameName = gcGame.gameName
                                                gcGame.twitchGameId = obj.twitchID
                                            }
                                        }
                                    channels.append(obj)
                                }
                            }
                            
                            delegate.gcGames = gameList
                            callbacks.onChannelsLoaded(channels: channels)
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            var channels = [TwitchChannelObj]()
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            channels.append(contentsOf: delegate.twitchChannels)
                            callbacks.onChannelsLoaded(channels: channels)
                        }
                    }
                }
            }
        }
    }
    
    func loadTwitchStreams2DotOhTeam(team: TeamObject, gcGame: GamerConnectGame, callbacks: SocialMediaManagerCallback){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/getStreamsTeam?token=" + token + "&game_id=" + gcGame.twitchHandle) { response in
            if let err = response.error {
                return
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                        var streams = [TwitchStreamObject]()
                        for stream in resultArray{
                            var startedAt = ""
                            var thumbnail = ""
                            var handle = ""
                            var id = ""
                            var title = ""
                            var userId = ""
                            var type = ""
                            var viewerCount = 0
                            if let gameDict = stream as? NSDictionary {
                                startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                handle = (gameDict.value(forKey: "user_name") as? String)!
                                thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                id = (gameDict.value(forKey: "id") as? String)!
                                title = (gameDict.value(forKey: "title") as? String)!
                                userId = (gameDict.value(forKey: "user_id") as? String)!
                                type = (gameDict.value(forKey: "type") as? String)!
                                viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                
                                let newStream  = TwitchStreamObject(handle: handle)
                                newStream.id = id
                                newStream.thumbnail = thumbnail
                                newStream.title = title
                                newStream.userId = userId
                                newStream.type = type
                                newStream.startedAt = startedAt
                                newStream.viewerCount = viewerCount
                                
                                streams.append(newStream)
                            }
                        }
                        callbacks.onStreamsLoaded(streams: streams)
                    }
                }
            }
        }
    }
    
    func checkTwitchStream(twitchId: String, callbacks: SocialMediaManagerCallback){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/checkTwitchStream?token=" + token + "&twitch_login=" + twitchId) { response in
            if let err = response.error {
                AppEvents.logEvent(AppEvents.Name(rawValue: "Check Stream - Error"))
                callbacks.onStreamsLoaded(streams: [TwitchStreamObject]())
                return
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                        if(resultArray.count == 0){
                            callbacks.onStreamsLoaded(streams: [TwitchStreamObject]())
                        } else {
                            var streams = [TwitchStreamObject]()
                            for stream in resultArray{
                                var startedAt = ""
                                var thumbnail = ""
                                var handle = ""
                                var id = ""
                                var title = ""
                                var userId = ""
                                var type = ""
                                var viewerCount = 0
                                if let gameDict = stream as? NSDictionary {
                                    startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                    handle = (gameDict.value(forKey: "user_name") as? String)!
                                    thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                    id = (gameDict.value(forKey: "id") as? String)!
                                    title = (gameDict.value(forKey: "title") as? String)!
                                    userId = (gameDict.value(forKey: "user_id") as? String)!
                                    type = (gameDict.value(forKey: "type") as? String)!
                                    viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                    
                                    let newStream  = TwitchStreamObject(handle: handle)
                                    newStream.id = id
                                    newStream.thumbnail = thumbnail
                                    newStream.title = title
                                    newStream.userId = userId
                                    newStream.type = type
                                    newStream.startedAt = startedAt
                                    newStream.viewerCount = viewerCount
                                    
                                    streams.append(newStream)
                                }
                            }
                            callbacks.onStreamsLoaded(streams: streams)
                        }
                    } else {
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Check Stream - No Data"))
                        callbacks.onStreamsLoaded(streams: [TwitchStreamObject]())
                    }
                } else {
                    AppEvents.logEvent(AppEvents.Name(rawValue: "Check Stream - Bad payload"))
                    callbacks.onStreamsLoaded(streams: [TwitchStreamObject]())
                }
            }
        }
    }
    
    func loadTwitchStreams2DotOhChannel(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/getStreamsChannel?game_id=" + currentChannel.twitchID + "&token=" + token) { response in
            if let err = response.error {
                return
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                        var streams = [TwitchStreamObject]()
                        for stream in resultArray{
                            var startedAt = ""
                            var thumbnail = ""
                            var handle = ""
                            var id = ""
                            var title = ""
                            var userId = ""
                            var type = ""
                            var viewerCount = 0
                            if let gameDict = stream as? NSDictionary {
                                startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                handle = (gameDict.value(forKey: "user_name") as? String)!
                                thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                id = (gameDict.value(forKey: "id") as? String)!
                                title = (gameDict.value(forKey: "title") as? String)!
                                userId = (gameDict.value(forKey: "user_id") as? String)!
                                type = (gameDict.value(forKey: "type") as? String)!
                                viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                
                                let newStream  = TwitchStreamObject(handle: handle)
                                newStream.id = id
                                newStream.thumbnail = thumbnail
                                newStream.title = title
                                newStream.userId = userId
                                newStream.type = type
                                newStream.startedAt = startedAt
                                newStream.viewerCount = viewerCount
                                
                                streams.append(newStream)
                            }
                        }
                        callbacks.onStreamsLoaded(streams: streams)
                    }
                }
            }
        }
    }

    
    /*func loadTwitchStreams(team: TeamObject, gcGame: GamerConnectGame, callbacks: SocialMediaManagerCallback){
        if(!token.isEmpty){
            var streams = [TwitchStreamObject]()
            TwitchTokenManager.shared.accessToken = token
            
            var ids = [String]()
            ids.append(gcGame.twitchHandle)
            
            Twitch.Streams.getStreams(tokenManager: TwitchTokenManager.shared, after: nil, before: nil, communityIds: nil, first: 5, gameIds: ids, languages: nil, userIds: nil, userNames: nil){
                switch $0 {
                case .success(let getStreamsData):
                    print(getStreamsData)
                //self.videos = getVideosData.videoData
                case .failure(let data, _, _):
                    print("The API call failed! Unable to get videos. Did you set an access token?")
                    if let data = data{
                        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
                            
                            if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                                for stream in resultArray{
                                    var startedAt = ""
                                    var thumbnail = ""
                                    var handle = ""
                                    var id = ""
                                    var title = ""
                                    var userId = ""
                                    var type = ""
                                    var viewerCount = 0
                                    if let gameDict = stream as? NSDictionary {
                                        startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                        handle = (gameDict.value(forKey: "user_name") as? String)!
                                        thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                        id = (gameDict.value(forKey: "id") as? String)!
                                        title = (gameDict.value(forKey: "title") as? String)!
                                        userId = (gameDict.value(forKey: "user_id") as? String)!
                                        type = (gameDict.value(forKey: "type") as? String)!
                                        viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                        
                                        let newStream  = TwitchStreamObject(handle: handle)
                                        newStream.id = id
                                        newStream.thumbnail = thumbnail
                                        newStream.title = title
                                        newStream.userId = userId
                                        newStream.type = type
                                        newStream.startedAt = startedAt
                                        newStream.viewerCount = viewerCount
                                        
                                        streams.append(newStream)
                                    }
                                }
                                callbacks.onStreamsLoaded(streams: streams)
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    func loadTweets(team: TeamObject, gcGame: GamerConnectGame, callbacks: SocialMediaManagerCallback){
        var tweets = [TweetObject]()
        TwitterHelper.shared.getTimeline(screenName: gcGame.twitterHandle) { (json) in
            if let tweetJSONs = json?.array {
                for tweetJSON in tweetJSONs {
                    var tweetText = ""
                    var handle = ""
                    
                    let tweetObject = tweetJSON.object ?? [:]
                    for array in tweetObject {
                        if (array.key == "text" && tweetText.isEmpty) {
                            tweetText = array.value.string!
                        }
                        
                        if (array.key == "user" && handle.isEmpty) {
                            let payloadObject = array.value.object!
                            for pair in payloadObject {
                                if (pair.key == "name") {
                                    handle = "@" + (pair.value.string!)
                                }
                            }
                        }
                    }
                    
                    let tweet = TweetObject(handle: handle, tweet: tweetText)
                    tweets.append(tweet)
                }
                
                callbacks.onTweetsLoaded(tweets: tweets)
            } else {
                callbacks.onTweetsLoaded(tweets: [])
            }
        }
    }
    
    /*func getTopStreams(){
        if(!token.isEmpty){
            var streams = [TwitchStreamObject]()
            TwitchTokenManager.shared.accessToken = token
            Twitch.Streams.getStreams(tokenManager: TwitchTokenManager.shared, after: nil, before: nil, communityIds: nil, first: 50, gameIds: nil, languages: nil, userIds: nil, userNames: nil){
                switch $0 {
                case .success(let getStreamsData):
                    print(getStreamsData)
                //self.videos = getVideosData.videoData
                case .failure(let data, _, _):
                    print("The API call failed! Unable to get videos. Did you set an access token?")
                    if let data = data{
                        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
                            
                            if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                                for stream in resultArray{
                                    var startedAt = ""
                                    var thumbnail = ""
                                    var handle = ""
                                    var id = ""
                                    var title = ""
                                    var userId = ""
                                    var type = ""
                                    var viewerCount = 0
                                    if let gameDict = stream as? NSDictionary {
                                        startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                        handle = (gameDict.value(forKey: "user_name") as? String)!
                                        thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                        id = (gameDict.value(forKey: "id") as? String)!
                                        title = (gameDict.value(forKey: "title") as? String)!
                                        userId = (gameDict.value(forKey: "user_id") as? String)!
                                        type = (gameDict.value(forKey: "type") as? String)!
                                        viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                        
                                        let newStream  = TwitchStreamObject(handle: handle)
                                        newStream.id = id
                                        newStream.thumbnail = thumbnail
                                        newStream.title = title
                                        newStream.userId = userId
                                        newStream.type = type
                                        newStream.startedAt = startedAt
                                        newStream.viewerCount = viewerCount
                                        
                                        streams.append(newStream)
                                    }
                                }
                                //callbacks.onStreamsLoaded(streams: streams)
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    /*func getChannelTopStreams(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
        if(!token.isEmpty){
            var streams = [TwitchStreamObject]()
            TwitchTokenManager.shared.accessToken = token
            
            Twitch.Streams.getStreams(tokenManager: TwitchTokenManager.shared, after: nil, before: nil, communityIds: nil, first: 20, gameIds: [currentChannel.twitchID], languages: nil, userIds: nil, userNames: nil){
                switch $0 {
                case .success(let getStreamsData):
                    print(getStreamsData)
                //self.videos = getVideosData.videoData
                case .failure(let data, _, _):
                    print("The API call failed! Unable to get videos. Did you set an access token?")
                    if let data = data{
                        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
                            
                            if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                                for stream in resultArray{
                                    var startedAt = ""
                                    var thumbnail = ""
                                    var handle = ""
                                    var id = ""
                                    var title = ""
                                    var userId = ""
                                    var type = ""
                                    var viewerCount = 0
                                    if let gameDict = stream as? NSDictionary {
                                        startedAt = (gameDict.value(forKey: "started_at") as? String)!
                                        handle = (gameDict.value(forKey: "user_name") as? String)!
                                        thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                        id = (gameDict.value(forKey: "id") as? String)!
                                        title = (gameDict.value(forKey: "title") as? String)!
                                        userId = (gameDict.value(forKey: "user_id") as? String)!
                                        type = (gameDict.value(forKey: "type") as? String)!
                                        viewerCount = ((gameDict.value(forKey: "viewer_count") as? Int)!)
                                        
                                        let newStream  = TwitchStreamObject(handle: handle)
                                        newStream.id = id
                                        newStream.thumbnail = thumbnail
                                        newStream.title = title
                                        newStream.userId = userId
                                        newStream.type = type
                                        newStream.startedAt = startedAt
                                        newStream.viewerCount = viewerCount
                                        
                                        streams.append(newStream)
                                    }
                                }
                                callbacks.onStreamsLoaded(streams: streams)
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    func getChannelTopVideos(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
        if(!token.isEmpty){
            var streams = [TwitchStreamObject]()
            TwitchTokenManager.shared.accessToken = token
            
            Twitch.Videos.getVideos(tokenManager: TwitchTokenManager.shared, videoIds: nil, userId: nil, gameId: currentChannel.twitchID, after: nil, before: nil, first: nil, language: nil, period: Twitch.Videos.Period.day, sortType: nil, videoType: nil, completionHandler: {
                switch $0 {
                case .success(let getStreamsData):
                    print(getStreamsData)
                    for video in getStreamsData.videoData{
                        let newStream  = TwitchStreamObject(handle: video.id)
                        newStream.id = video.id
                        newStream.thumbnail = video.thumbnailURLString
                        newStream.title = video.title
                        newStream.userId = video.ownerId
                        newStream.viewerCount = video.viewCount
                        
                        streams.append(newStream)
                    }
                    callbacks.onStreamsLoaded(streams: streams)
                    break;
                case .failure(_, _, _):
                    callbacks.onStreamsLoaded(streams: streams)
                    break;
                }
            })
        }
    }
}


