//
//  SocialMediaManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP
import Firebase
import FBSDKLoginKit
import GoogleSignIn

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
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    
                    DispatchQueue.main.async {
                        let token = jsonObj?["access_token"] as! String
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
                            var channels = [Any]()
                            let delegate = UIApplication.shared.delegate as! AppDelegate
                            let gameList = delegate.gcGames!
                            var currentIndex = 0
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
                                    
                                    if(currentIndex.isMultiple(of: 5) && currentIndex != 0){
                                        channels.append(AdObject())
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
                        var currentIndex = 0
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
                                
                                let chinese = newStream.handle.range(of: "\\p{Han}", options: .regularExpression) != nil
                                if(!chinese){
                                    streams.append(newStream)
                                }
                            }
                        }
                        callbacks.onStreamsLoaded(streams: streams)
                    }
                }
            }
        }
    }
    
    func searchStreams(searchQuery: String, callbacks: SocialMediaManagerCallback){
        HTTP.GET("https://us-central1-gameterminal-767f7.cloudfunctions.net/searchForStream?search_query=" + searchQuery + "&token=" + token) { response in
            if let err = response.error {
                return
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArray = jsonObj!.value(forKey: "data") as? NSArray {
                        var streams = [TwitchStreamObject]()
                        for stream in resultArray{
                            var isLive = ""
                            var thumbnail = ""
                            var handle = ""
                            var id = ""
                            var title = ""
                            if let gameDict = stream as? NSDictionary {
                                if((gameDict.value(forKey: "is_live") is Bool)){
                                    if((gameDict.value(forKey: "is_live") as! Bool) == false){
                                        isLive = "false"
                                    } else {
                                        isLive = "true"
                                    }
                                }
                                handle = (gameDict.value(forKey: "display_name") as? String)!
                                thumbnail = (gameDict.value(forKey: "thumbnail_url") as? String)!
                                id = (gameDict.value(forKey: "id") as? String)!
                                title = (gameDict.value(forKey: "title") as? String)!
                                
                                let newStream  = TwitchStreamObject(handle: handle)
                                newStream.id = id
                                newStream.thumbnail = thumbnail
                                newStream.title = title
                                newStream.isLive = isLive
                                
                                streams.append(newStream)
                            }
                        }
                        
                        var exactMatch = false
                        for stream in streams {
                            if(stream.handle == searchQuery){
                                exactMatch = true
                                callbacks.onStreamsLoaded(streams: [stream])
                                break
                            }
                        }
                        
                        if(!exactMatch){
                            callbacks.onStreamsLoaded(streams: streams)
                        }
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
    
    func getYoutubeAccess(accessToken: String, callbacks: SocialMediaManagerCallback, currentUser: User, tryRefresh: Bool){
        let params = ["Authorization": "Bearer " + accessToken] as [String : Any]
        HTTP.GET("https://www.googleapis.com/youtube/v3/channels?part=id&mine=true&max_results=5&key=AIzaSyAyjFRqU4u2fx7_Ik5dEiDuNbXb9F0Ykjc&access_token=" + accessToken, parameters: params) { response in
            if let err = response.error {
                if(tryRefresh){
                    self.attemptTokenRefresh(refreshToken: currentUser.googleApiRefreshToken, accessToken: currentUser.googleApiAccessToken, callbacks: callbacks, currentUser: currentUser)
                } else {
                    callbacks.onYoutubeFail()
                }
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if let resultArray = jsonObj!.value(forKey: "items") as? NSArray {
                        var channelIds = [String]()
                        var channels = [YoutubeMultiChannelSelection]()
                        for channel in resultArray{
                            if let gameDict = channel as? NSDictionary {
                                let id = (gameDict.value(forKey: "id") as? String ?? "")
                                let title = (gameDict.value(forKey: "title") as? String ?? "")
                                if(!id.isEmpty){
                                    channelIds.append(id)
                                    if(!title.isEmpty){
                                        let youtube = YoutubeMultiChannelSelection()
                                        youtube.channelId = id
                                        youtube.channelName = title
                                        channels.append(youtube)
                                    }
                                }
                            }
                        }
                        if(channelIds.count > 1){
                            callbacks.onChannelsLoaded(channels: channels)
                        } else if(!channelIds.isEmpty){
                            self.attemptYoutubeVideos(channelId: channelIds[0], accessToken: accessToken, callbacks: callbacks, currentUser: currentUser)
                        } else {
                            callbacks.onYoutubeFail()
                        }
                    }
                }
            }
        }
    }
    
    
    func attemptTokenRefresh(refreshToken: String, accessToken: String, callbacks: SocialMediaManagerCallback, currentUser: User){
        HTTP.POST("https://oauth2.googleapis.com/token?client_id=582166005754-t8kcglj0t0oqgsr4p43052rpf00vnkvg.apps.googleusercontent.com&client_secret=&refresh_token=" + refreshToken + "&grant_type=refresh_token") { response in
            if let err = response.error {
               print("error: \(err.localizedDescription)")
               callbacks.onYoutubeFail()
                
               return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    if(jsonObj!.value(forKey: "access_token") != nil){
                        let token = jsonObj!.value(forKey: "access_token") as? String ?? ""
                        Database.database().reference().child("Users").child(currentUser.uId).child("googleApiAccessToken").setValue(token)
                        self.getYoutubeAccess(accessToken: token, callbacks: callbacks, currentUser: currentUser, tryRefresh: false)
                    } else {
                        callbacks.onYoutubeFail()
                    }
                } else {
                    callbacks.onYoutubeFail()
                }
            }
        }
    }
    
    func attemptYoutubeVideos(channelId: String, accessToken: String, callbacks: SocialMediaManagerCallback, currentUser: User){
        let params = ["Authorization": "Bearer " + accessToken] as [String : Any]
        HTTP.GET("https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=" + channelId + "&key=AIzaSyAyjFRqU4u2fx7_Ik5dEiDuNbXb9F0Ykjc" + "&maxResults=50", parameters: params) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                if(!currentUser.googleApiRefreshToken.isEmpty && accessToken != currentUser.googleApiRefreshToken){
                    self.attemptYoutubeVideos(channelId: channelId, accessToken: currentUser.googleApiRefreshToken, callbacks: callbacks, currentUser: currentUser)
                } else {
                    callbacks.onYoutubeFail()
                }
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    var videoArray = [YoutubeVideoObj]()
                    if let resultArray = jsonObj!.value(forKey: "items") as? NSArray {
                        for video in resultArray{
                            if let videoDict = video as? NSDictionary {
                                var id = ""
                                var title = ""
                                var date = ""
                                var imgUrl = ""
                                
                                if let idDict = videoDict.value(forKey: "id") as? NSDictionary {
                                    id = (idDict.value(forKey: "videoId") as? String ?? "")
                                }
                                
                                if let snippetDict = videoDict.value(forKey: "snippet") as? NSDictionary {
                                    date = (snippetDict.value(forKey: "publishedAt") as? String ?? "")
                                    title = (snippetDict.value(forKey: "title") as? String ?? "")
                                    
                                    if let imgDict = snippetDict.value(forKey: "thumbnails") as? NSDictionary {
                                        if let mediumDict = imgDict.value(forKey: "default") as? NSDictionary {
                                            imgUrl = (mediumDict.value(forKey: "url") as? String ?? "")
                                        }
                                    }
                                }
                                
                                if(!id.isEmpty && !title.isEmpty && !date.isEmpty){
                                    videoArray.append(YoutubeVideoObj(title: title, videoOwnerGamerTag: currentUser.gamerTag, videoOwnerUid: currentUser.uId, youtubeFavorite: "false", date: date, youtubeId: id, imgUrl: imgUrl))
                                }
                            }
                        }
                    }
                    callbacks.onYoutubeSuccessful(videos: videoArray)
                } else {
                    callbacks.onYoutubeFail()
                }
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
    
    /*func getChannelTopVideos(currentChannel: TwitchChannelObj, callbacks: SocialMediaManagerCallback){
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
    }*/
}


