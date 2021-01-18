//
//  DiscoverManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftHTTP

class DiscoverManager {
    
    func getDiscoverHomeInfo(callbacks: DiscoverCallbacks){
        HTTP.GET("http://doublexpstorage.tech/app-json/discover_home.json") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                callbacks.onFailure()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    var payload = [Int: Any]()
                    var games = [GamerConnectGame]()
                    if let featuredArray = jsonObj!.value(forKey: "Featured") as? NSArray {
                        for game in featuredArray{
                            var hook = ""
                            var gameName = ""
                            var imageUrl = ""
                            var developer = ""
                            var secondaryName = ""
                            var twitterHandle = ""
                            var twitchHandle = ""
                            var available = "true"
                            var hasQuiz = false
                            var mobileGame = ""
                            var gameType = ""
                            var releaseDate = ""
                            var gameDescription = ""
                            var ideal = ""
                            var timeCommitment = ""
                            var complexity = ""
                            var ratings = [[String: String]]()
                            var quickReviews = [[String: String]]()
                            var gameModes = [String]()
                            var statsAvailable = false
                            var teamNeeds = [String]()
                            var categoryFilters = [String]()
                            var availableConsoles = [String]()
                            var filterQuestions = [[String: Any]]()
                            if let gameDict = game as? NSDictionary {
                                hook = (gameDict.value(forKey: "hook") as? String ?? "")
                                gameName = (gameDict.value(forKey: "gameName") as? String ?? "")
                                imageUrl = (gameDict.value(forKey: "headerImageUrlXXHDPI") as? String ?? "")
                                developer = (gameDict.value(forKey: "developer") as? String ?? "")
                                statsAvailable = (gameDict.value(forKey: "statsAvailable") as? Bool ?? false)
                                teamNeeds = (gameDict.value(forKey: "teamNeeds") as? [String]) ?? [String]()
                                secondaryName = (gameDict.value(forKey: "secondaryName") as? String ?? "")
                                gameType = (gameDict.value(forKey: "gameType") as? String ?? "")
                                releaseDate = (gameDict.value(forKey: "releaseDate") as? String ?? "")
                                gameModes = (gameDict).value(forKey: "gameModes") as? [String] ?? [String]()
                                categoryFilters = (gameDict).value(forKey: "categoryFilters") as? [String] ?? [String]()
                                twitterHandle = (gameDict).value(forKey: "twitterHandle") as? String ?? ""
                                twitchHandle = (gameDict).value(forKey: "twitchHandle") as? String ?? ""
                                mobileGame = (gameDict).value(forKey: "mobileGame") as? String ?? "false"
                                available = (gameDict).value(forKey: "available") as? String ?? "true"
                                availableConsoles = (gameDict.value(forKey: "availableConsoles") as? [String]) ?? [String]()
                                gameDescription = (gameDict).value(forKey: "gameDescription") as? String ?? ""
                                ideal = (gameDict).value(forKey: "ideal") as? String ?? ""
                                timeCommitment = (gameDict).value(forKey: "timeCommitment") as? String ?? ""
                                complexity = (gameDict).value(forKey: "complexity") as? String ?? ""
                                ratings = (gameDict).value(forKey: "ratings") as? [[String: String]] ?? [[String: String]]()
                                quickReviews = (gameDict).value(forKey: "quickReviews") as? [[String: String]] ?? [[String: String]]()
                                
                                let quiz = (gameDict).value(forKey: "quiz") as? String ?? ""
                                if(quiz == "true"){
                                    hasQuiz = true
                                } else {
                                    hasQuiz = false
                                }
                                
                                let newGame  = GamerConnectGame(imageUrl: imageUrl, gameName: gameName, developer: developer, hook: hook, statsAvailable: statsAvailable, teamNeeds: teamNeeds,
                                                                twitterHandle: twitterHandle, twitchHandle: twitchHandle, available: available)
                                newGame.secondaryName = secondaryName
                                newGame.gameModes = gameModes
                                newGame.hasQuiz = hasQuiz
                                newGame.mobileGame = mobileGame
                                newGame.availablebConsoles = availableConsoles
                                newGame.categoryFilters = categoryFilters
                                newGame.gameType = gameType
                                newGame.releaseDate = releaseDate
                                newGame.ratings = ratings
                                newGame.gameDescription = gameDescription
                                newGame.ideal = ideal
                                newGame.timeCommitment = timeCommitment
                                newGame.complexity = complexity
                                newGame.quickReviews = quickReviews
                                
                                if(gameDict.value(forKey: "filterQuestions") != nil){
                                    //let test = gameDict["filterQuestions"] as? [[String: Any]] ?? [[String: Any]]()
                                    filterQuestions = (gameDict.value(forKey: "filterQuestions") as? [[String: Any]]) ?? [[String: Any]]()
                                    newGame.filterQuestions = filterQuestions
                                }
                                games.append(newGame)
                            }
                        }
                    }
                    
                    var categories = [DiscoverCategory]()
                    if let resultArray = jsonObj!.value(forKey: "Categories") as? NSArray {
                        for category in resultArray{
                            var imageUrl = ""
                            var categoryVal = ""
                            var categoryName = ""
                            
                            if let categoryDict = category as? NSDictionary {
                                imageUrl = (categoryDict.value(forKey: "headerImageUrlHDPI") as? String ?? "")
                                categoryVal = (categoryDict.value(forKey: "categoryVal") as? String ?? "")
                                categoryName = (categoryDict.value(forKey: "categoryName") as? String ?? "")
                            
                                let newCategory  = DiscoverCategory(imgUrl: imageUrl, categoryName: categoryName, categoryVal: categoryVal)
                                categories.append(newCategory)
                            }
                        }
                    }
                
                    var currentPos = 0
                    for game in games {
                        payload[currentPos] = game
                        currentPos += 1
                        payload[currentPos] = 0
                        currentPos += 1
                        break
                    }
                    for cat in categories {
                        payload[(currentPos)] = cat
                        currentPos += 1
                    }
                    
                    if(payload.isEmpty){
                        callbacks.onFailure()
                    } else {
                        callbacks.onSuccess(discoverPayload: payload)
                    }
                } else {
                    callbacks.onFailure()
                }
            }
        }
    }
}
