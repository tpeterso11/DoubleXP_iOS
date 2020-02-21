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
    
    
    func getTwitterHandle(developer: String) -> String{
        switch developer {
        case "2K Sports":
            return "2K"
        case "Ubisoft":
            return "ubisoft"
        case "Rockstar":
            return "rockstargames"
        default:
            return ""
        }
    }
    
    func getTwitchGameId(gameName: String) -> String{
        switch gameName{
        case "Red Dead Redemption 2":
            return "493959"
        case "NBA 2K20":
            return "513319"
        case "The Division 2":
            return "504463"
        case "Rainbow Six Siege":
            return "460630"
        default:
            return ""
        }
    }
    
    func loadTwitchStreams(team: TeamObject, callbacks: SocialMediaManagerCallback){
        var streams = [TwitchStreamObject]()
        TwitchTokenManager.shared.accessToken = token
        
        var ids = [String]()
        ids.append(getTwitchGameId(gameName: team.games[0]))
        
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
    
    func loadTweets(team: TeamObject, callbacks: SocialMediaManagerCallback){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var tweets = [TweetObject]()
        
        var gcGame: GamerConnectGame? = nil
        for game in delegate.gcGames{
           if (game.gameName == team.games[0]) {
               gcGame = game
           }
        }
       
        let parameters = ["screen_name": getTwitterHandle(developer: gcGame!.developer), "count": "10", "include_entities": "true"]
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
    
    /*
     var gameArray = [String]()
     gameArray.append("Tom Clancy's Rainbow Six: Siege")
     
     Twitch.Games.getGames(tokenManager: TwitchTokenManager.shared, gameIds: nil, gameNames: gameArray){
        switch $0 {
        case .success(let getVideosData):
            print(getVideosData.gameData.count)
           //self.videos = getVideosData.videoData
        case .failure(let data, _, _):
            print("The API call failed! Unable to get videos. Did you set an access token?")
            if let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let jsonDict = jsonObject as? [String: Any]{
                print(jsonDict)
            }
            //self.videos = [VideoData]()
        }
    }*/
    
    /*Twitch.Videos.getVideos(videoIds: nil, userId: nil, gameId: manager.getTwitchGameId(gameName: team!.games[0])) {
        switch $0 {
        case .success(let getVideosData):
            print(getVideosData.videoData.count)
           //self.videos = getVideosData.videoData
        case .failure(let data, _, _):
            print("The API call failed! Unable to get videos. Did you set an access token?")
            if let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let jsonDict = jsonObject as? [String: Any]{
                print(jsonDict)
            }
            //self.videos = [VideoData]()
        }
    }*/
}
