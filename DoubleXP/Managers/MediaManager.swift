//
//  MediaManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP

class MediaManager {
    var gamespotReviews = [NewsObject]()
    var reviews = [NewsObject]()
    var dxpReviews = [NewsObject]()
    var news = [NewsObject]()
    //http://www.gamespot.com/api/articles/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&format=json&limit=50&sort=publish_date:desc
    
    
    func getReviews(callbacks: MediaCallbacks){
        HTTP.GET("http://www.gamespot.com/api/reviews/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&format=json&limit=50&sort=publish_date:desc") { response in
        if let err = response.error {
            DispatchQueue.main.async {
                callbacks.onMediaReceived(category: "error")
            }
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                
                if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                    self.gamespotReviews = [NewsObject]()

                    for game in resultArray{
                        var add = false
                        var articleTitle = ""
                        var articleSub = ""
                        var gameName = ""
                        var author = ""
                        var headerImageUrl = ""
                        var videoUrl = ""
                        var type = ""
                        var source = "gs"
                        var storyText = ""
                        
                        if let gameDict = game as? NSDictionary {
                            articleTitle = (gameDict.value(forKey: "title") as? String ?? "")
                            gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                            articleSub = (gameDict.value(forKey: "deck") as? String ?? "")
                            author = (gameDict.value(forKey: "authors") as? String ?? "")
                            headerImageUrl = (gameDict.value(forKey: "image") as? NSDictionary)?.value(forKey: "original") as? String ?? ""
                            videoUrl = (gameDict.value(forKey: "videos_api_url") as? String ?? "")
                            storyText = (gameDict.value(forKey: "body") as? String ?? "")
                            
                            if(gameDict.value(forKey: "game") != nil){
                                add = true
                            }
                            type = "review"

                                if(add){
                                    let newObject = NewsObject(title: articleTitle, author: author, storyText: storyText, imageUrl: headerImageUrl)
                                    newObject.subTitle = articleSub
                                    newObject.videoUrl = videoUrl
                                    newObject.type = type
                                    newObject.source = source
                                    
                                    self.gamespotReviews.append(newObject)
                                }
                            }
                        }
                    }
                    self.getDXPReviews(callbacks: callbacks)
                }
            }
        }
    }
    
    func getGameSpotNews(callbacks: MediaCallbacks){
        HTTP.GET("http://www.gamespot.com/api/articles/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&format=json&limit=50&sort=publish_date:desc") { response in
        if let err = response.error {
            DispatchQueue.main.async {
                callbacks.onMediaReceived(category: "error")
            }
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                
                if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                    for game in resultArray{
                        var isGame = false
                        var videoPresent = false
                        var add = false
                        var articleTitle = ""
                        var articleSub = ""
                        var gameName = ""
                        var author = ""
                        var headerImageUrl = ""
                        var videoUrl = ""
                        var type = ""
                        var source = "gs"
                        var storyText = ""
                        var categories = [String]()
                        
                        if let gameDict = game as? NSDictionary {
                            articleTitle = (gameDict.value(forKey: "title") as? String ?? "")
                            gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                            articleSub = (gameDict.value(forKey: "deck") as? String ?? "")
                            author = (gameDict.value(forKey: "authors") as? String ?? "")
                            headerImageUrl = (gameDict.value(forKey: "image") as? NSDictionary)?.value(forKey: "original") as? String ?? ""
                            //videoUrl = (gameDict.value(forKey: "videos_api_url") as? String ?? "")
                            
                            let originalUrl = (gameDict.value(forKey: "videos_api_url") as? String ?? "")
                            if(!originalUrl.isEmpty){
                                videoPresent = true
                                let first = "https://www.gamespot.com/api/videos/"
                                let index = originalUrl.index(after: originalUrl.index(of: "?")!)
                                let last = originalUrl.substring(from: index)
                                let format = "&format=json"
                                let key = "?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&"
                                videoUrl = first + key + last + format
                                
                                //https://www.gamespot.com/api/videos/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&filter=id%3A6451708&format=json
                                print(videoUrl)
                            }
                            else{
                                videoUrl = ""
                            }
                            /*val originalUrl = article.getString("videos_api_url").replace("\\", "");
                            val first = "https://www.gamespot.com/api/videos/"
                            val index = originalUrl.indexOf("?")
                            val last = originalUrl.substringAfter("?")
                            val format = "&format=json"
                            val newUrl = first + GAMESPOT_KEY + last + format
                            currentNews.videoUrl = newUrl*/
                            
                            
                            storyText = (gameDict.value(forKey: "body") as? String ?? "")
                            
                            if let cats = gameDict.value(forKey: "categories") as? NSArray {
                                for cat in cats where cat is [String: Any] { // loop over all responses
                                    if((cat as! [String: Any]).keys.contains("name")){
                                        categories.append((cat as! [String: Any])["name"] as? String ?? "0")
                                }
                              }
                            }
                            
                            type = "news"
                            
                            if(categories.contains("Games")){
                                isGame = true
                            }
                            
                            if(isGame){
                                add = true
                            }
                            
                            //let images = (gameDict.value(forKey: "body") as? NSDictionary
                                
                            //val images = article.getJSONObject("image")
                            //currentNews.imageUrl = images.getString("original")
                                if(add){
                                    let newObject = NewsObject(title: articleTitle, author: author, storyText: storyText, imageUrl: headerImageUrl)
                                    newObject.subTitle = articleSub
                                    newObject.videoUrl = videoUrl
                                    newObject.type = type
                                    newObject.source = source
                                    
                                    self.news.append(newObject)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let cache = delegate.mediaCache
                        cache.setNewsCache(payload: self.news)
                        
                        callbacks.onMediaReceived(category: "news")
                    }
                }
            }
        }
    }
    
    func downloadVideo(title: String, url: String, callbacks: MediaCallbacks){
       HTTP.GET(url) { response in
        if let err = response.error {
            DispatchQueue.main.async {
                callbacks.onMediaReceived(category: "error")
            }
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                self.dxpReviews = [NewsObject]()
                
                for game in jsonObj{
                    if(game.key == "results"){
                        if let gameDict = game.value as? NSArray {
                            print("made it")
                            for child in gameDict{
                                let current = child as? [String: Any]
                                let url = (current!["high_url"] as? String ?? "")
                                callbacks.onVideoLoaded(url: url)
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
    
    
    func getDXPReviews(callbacks: MediaCallbacks){
    HTTP.GET("http://doublexpstorage.tech/app-json/dxp_reviews.json") { response in
    if let err = response.error {
        DispatchQueue.main.async {
            callbacks.onMediaReceived(category: "error")
        }
        print("error: \(err.localizedDescription)")
        return //also notify app of failure as needed
    }
    else{
        if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [[String: Any]] {
            self.dxpReviews = [NewsObject]()
            
            for game in jsonObj{
                        var articleTitle = ""
                        var articleSub = ""
                        var gameName = ""
                        var author = ""
                        var headerImageUrl = ""
                        var videoUrl = ""
                        var type = ""
                        var storyText = ""
                        var source = "dxp"
                
                    
                        if let gameDict = game as? NSDictionary {
                            articleTitle = (gameDict.value(forKey: "articleTitle") as? String ?? "")
                            gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                            articleSub = (gameDict.value(forKey: "articleSub") as? String ?? "")
                            author = (gameDict.value(forKey: "author") as? String ?? "")
                            headerImageUrl = (gameDict.value(forKey: "headerImageUrl") as? String ?? "")
                            videoUrl = (gameDict.value(forKey: "videoUrl") as? String ?? "")
                            type = (gameDict.value(forKey: "type") as? String ?? "")
                            storyText = (gameDict.value(forKey: "storyText") as? String ?? "")
                            
                            let newObject = NewsObject(title: articleTitle, author: author, storyText: storyText, imageUrl: headerImageUrl)
                            newObject.subTitle = articleSub
                            newObject.videoUrl = videoUrl
                            newObject.type = type
                            newObject.source = source
                            
                            self.dxpReviews.append(newObject)
                        }
                    }
            DispatchQueue.main.async {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let cache = delegate.mediaCache
                
                self.reviews = [NewsObject]()
                self.reviews.append(contentsOf: self.dxpReviews)
                self.reviews.append(contentsOf: self.gamespotReviews)
                
                cache.setReviewsCache(payload: self.reviews)
                callbacks.onMediaReceived(category: "reviews")
            }
                }
            }
        }
    }
}

extension Dictionary where Value: Equatable {
  func containsValue(value : Value) -> Bool {
    return self.contains { $0.1 == value }
  }
}
