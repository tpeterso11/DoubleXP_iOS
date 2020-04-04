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
import TwitterKit

class SocialMediaManager{
    var token = "053ae1qjehp1xi4oo05gxkkow6otoc"
    
    func getToken() -> String{
        return self.token
    }
    
    func loadTwitchStreams(team: TeamObject, gcGame: GamerConnectGame, callbacks: SocialMediaManagerCallback){
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
    
    func loadTweets(team: TeamObject, gcGame: GamerConnectGame, callbacks: SocialMediaManagerCallback){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var tweets = [TweetObject]()
        
        var gcGame: GamerConnectGame? = nil
        for game in delegate.gcGames{
           if (game.gameName == team.games[0]) {
               gcGame = game
           }
        }
       
        let parameters = ["screen_name": gcGame?.twitterHandle, "count": "10", "include_entities": "true"]
        var error : NSError?
        let req = TWTRAPIClient().urlRequest(withMethod: "GET", urlString: "https://api.twitter.com/1.1/statuses/user_timeline.json", parameters: parameters, error: &error)
        TWTRAPIClient().sendTwitterRequest(req, completion: { (response, data, error) in
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String : Any]]
                if response != nil {
                    print((response! as NSArray).debugDescription)
                    for tweet in response!{
                        var tweetText = ""
                        var handle = ""
                   
                        for array in tweet{
                            if(array.key == "text" && tweetText.isEmpty){
                                tweetText = array.value as! String
                        }
                       
                        if(array.key == "user" && handle.isEmpty){
                            let payload = array.value as! [String: Any]
                            for pair in payload{
                                if (pair.key == "name") {
                                    handle = "@" + (pair.value as! String)
                                }
                            }
                        }
                    }
                    let tweet = TweetObject(handle: handle, tweet: tweetText)
                    tweets.append(tweet)
                }
                    callbacks.onTweetsLoaded(tweets: tweets)
            }
         }
         catch {
           print(error.localizedDescription)
         }
       })
    }
    
    
    func getTopGames(callbacks: SocialMediaManagerCallback){
        var channels = [TwitchChannelObj]()
        
        TwitchTokenManager.shared.accessToken = token
        Twitch.Games.getTopGames(completionHandler: {
            switch $0 {
                case .success(let getGames):
                    DispatchQueue.main.async {
                        for game in getGames.gameData{
                            let obj = TwitchChannelObj(gameName: game.name, imageUrIOS: game.boxArtURLString, twitchID: game.id)
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            for gcGame in delegate.gcGames{
                                if(gcGame.gameName == game.name){
                                    obj.isGCGame = "true"
                                    obj.gcGameName = gcGame.gameName
                                }
                            }
                            channels.append(obj)
                        }
                        callbacks.onChannelsLoaded(channels: channels)
                    }
                    break;
                case .failure(_, _, _): break
                callbacks.onChannelsLoaded(channels: channels)
            }
        })
    }
    
    func getGame(){
        var channels = [TwitchChannelObj]()
        
        TwitchTokenManager.shared.accessToken = token
        Twitch.Games.getGames(gameIds: nil, gameNames: ["Call of Duty: Modern Warfare"], completionHandler: {
            switch $0 {
                case .success(let getGames):
                    DispatchQueue.main.async {
                        for game in getGames.gameData{
                            let obj = TwitchChannelObj(gameName: game.name, imageUrIOS: game.boxArtURLString, twitchID: game.id)
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            for gcGame in delegate.gcGames{
                                if(gcGame.gameName == game.name){
                                    obj.isGCGame = "true"
                                    obj.gcGameName = gcGame.gameName
                                }
                            }
                            channels.append(obj)
                        }
                        //callbacks.onChannelsLoaded(channels: channels)
                    }
                    break;
                case .failure(_, _, _): break
                //callbacks.onChannelsLoaded(channels: channels)
            }
        })
    }
    
    func getTopStreams(){
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
    
    func getChannelTopStreams(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
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
    
    func getChannelTopVideos(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
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

