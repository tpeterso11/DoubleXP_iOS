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
        HTTP.GET("http://www.gamespot.com/api/reviews/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&format=json&limit=20&sort=publish_date:desc") { response in
        if let err = response.error {
            DispatchQueue.main.async {
                callbacks.onMediaReceived()
            }
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                
                if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                    self.gamespotReviews = [NewsObject]()

                    for game in resultArray{
                        var articleTitle = ""
                        var articleSub = ""
                        var gameName = ""
                        var author = ""
                        var headerImageUrl = ""
                        var videoUrl = ""
                        var type = ""
                        var storyText = ""
                        
                        if let gameDict = game as? NSDictionary {
                            articleTitle = (gameDict.value(forKey: "title") as? String ?? "")
                            gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                            articleSub = (gameDict.value(forKey: "deck") as? String ?? "")
                            author = (gameDict.value(forKey: "authors") as? String ?? "")
                            headerImageUrl = (gameDict.value(forKey: "image") as? NSDictionary)?.value(forKey: "original") as? String ?? ""
                            videoUrl = (gameDict.value(forKey: "videos_api_url") as? String ?? "")
                            storyText = (gameDict.value(forKey: "body") as? String ?? "")
                            type = "review"
                            
                            let newObject = NewsObject(title: articleTitle, author: author, storyText: storyText, imageUrl: headerImageUrl)
                            newObject.subTitle = articleSub
                            newObject.videoUrl = videoUrl
                            newObject.type = type
                            
                            self.gamespotReviews.append(newObject)
                            }
                        }
                    }
                
                self.getGameSpotNews(callbacks: callbacks)
                }
            }
        }
    }
    
    func getGameSpotNews(callbacks: MediaCallbacks){
        HTTP.GET("http://www.gamespot.com/api/articles/?api_key=6e61e45d268953e5164c5c434c36ee6607b82f1c&format=json&limit=10&sort=publish_date:desc") { response in
        if let err = response.error {
            DispatchQueue.main.async {
                callbacks.onMediaReceived()
            }
            print("error: \(err.localizedDescription)")
            return //also notify app of failure as needed
        }
        else{
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                
                if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                    for game in resultArray{
                        var articleTitle = ""
                        var articleSub = ""
                        var gameName = ""
                        var author = ""
                        var headerImageUrl = ""
                        var videoUrl = ""
                        var type = ""
                        var storyText = ""
                        
                        if let gameDict = game as? NSDictionary {
                            articleTitle = (gameDict.value(forKey: "title") as? String ?? "")
                            gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                            articleSub = (gameDict.value(forKey: "deck") as? String ?? "")
                            author = (gameDict.value(forKey: "authors") as? String ?? "")
                            headerImageUrl = (gameDict.value(forKey: "image") as? NSDictionary)?.value(forKey: "original") as? String ?? ""
                            videoUrl = (gameDict.value(forKey: "videos_api_url") as? String ?? "")
                            storyText = (gameDict.value(forKey: "body") as? String ?? "")
                            type = "news"
                            
                            //let images = (gameDict.value(forKey: "body") as? NSDictionary
                                
                            //val images = article.getJSONObject("image")
                            //currentNews.imageUrl = images.getString("original")
                            
                            let newObject = NewsObject(title: articleTitle, author: author, storyText: storyText, imageUrl: headerImageUrl)
                            newObject.subTitle = articleSub
                            newObject.videoUrl = videoUrl
                            newObject.type = type
                            
                            self.news.append(newObject)
                            }
                        }
                    }
                self.getDXPReviews(callbacks: callbacks)
                }
            }
        }
    }
    
    func getDXPReviews(callbacks: MediaCallbacks){
    HTTP.GET("http://doublexpstorage.tech/app-json/dxp_reviews.json") { response in
    if let err = response.error {
        DispatchQueue.main.async {
            callbacks.onMediaReceived()
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
                            
                            self.dxpReviews.append(newObject)
                        }
                    }
            DispatchQueue.main.async {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let cache = delegate.mediaCache
                
                self.reviews = [NewsObject]()
                self.reviews.append(contentsOf: self.dxpReviews)
                self.reviews.append(contentsOf: self.gamespotReviews)
                
                cache.setNewsCache(payload: self.news)
                cache.setReviewsCache(payload: self.reviews)
                callbacks.onMediaReceived()
            }
                }
            }
        }
    }
}
