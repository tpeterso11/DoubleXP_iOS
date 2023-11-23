//
//  PostsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/22/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation
import Firebase

class PostsManager {
    
    func getUniversalPosts(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentUser == nil){
            return
        }
        let ref = Database.database().reference().child("Public Posts")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let postMaxCount = 10
                let maxPostsPerGame = 4
                var posts = [PostObject]()
                let userGames = appDelegate.currentUser!.games
                let randomGameArray = self.randomSelection(from: userGames, count: 5)
                var collectedSnapshots = [DataSnapshot]()
                for game in snapshot.children.shuffled() {
                    if(posts.count == postMaxCount){
                        return
                    }
                    let currentGame = game as! DataSnapshot
                    if(randomGameArray.contains(currentGame.key) || (appDelegate.currentUser!.games.isEmpty)) {
                        var currentGamePosts = [PostObject]()
                        for post in currentGame.children {
                                if(currentGamePosts.count == maxPostsPerGame){
                                    break
                                }
                                let currentObj = post as! DataSnapshot
                                let dict = currentObj.value as? [String: Any]
                                let viewUids = dict?["viewUids"] as? [String] ?? [String]()
                                if(!viewUids.contains(appDelegate.currentUser!.uId) && currentGamePosts.count < postMaxCount){
                                    let date = dict?["date"] as? String ?? ""
                                    let postId = dict?["postId"] as? String ?? ""
                                    let videoOwnerGamerTag = dict?["videoOwnerGamerTag"] as? String ?? ""
                                    let game = dict?["game"] as? String ?? ""
                                    let videoOwnerUid = dict?["videoOwnerUid"] as? String ?? ""
                                    let youtubeId = dict?["youtubeId"] as? String ?? ""
                                    let youtubeImg = dict?["youtubeImg"] as? String ?? ""
                                    let publicPost = dict?["publicPost"] as? String ?? ""
                                    let postConsole = dict?["postConsole"] as? String ?? ""
                                    let title = dict?["title"] as? String ?? ""
                                    
                                    currentGamePosts.append(PostObject(postId: postId, title: title, videoOwnerGamerTag: videoOwnerGamerTag, videoOwnerUid: videoOwnerUid, publicPost: publicPost, date: date, youtubeId: youtubeId, imgUrl: youtubeImg, postConsole: postConsole, game: game))
                                }
                            }
                            posts.append(contentsOf: currentGamePosts)
                            if(posts.count == postMaxCount) {
                                return
                            }
                        } else {
                            collectedSnapshots.append(currentGame)
                        }
                    }
                if(posts.count < postMaxCount){
                    for game in collectedSnapshots {
                        if(posts.count == postMaxCount){
                            return
                        }
                        let currentGame = game
                            var currentGamePosts = [PostObject]()
                            for post in currentGame.children {
                            let currentPost = post as! DataSnapshot
                            for post in currentGame.children {
                                if(currentGamePosts.count == maxPostsPerGame){
                                    break
                                }
                                let currentObj = post as! DataSnapshot
                                let dict = currentObj.value as? [String: Any]
                                let viewUids = dict?["viewUids"] as? [String] ?? [String]()
                                if(!viewUids.contains(appDelegate.currentUser!.uId)){
                                    let date = dict?["date"] as? String ?? ""
                                    let postId = dict?["postId"] as? String ?? ""
                                    let videoOwnerGamerTag = dict?["videoOwnerGamerTag"] as? String ?? ""
                                    let game = dict?["game"] as? String ?? ""
                                    let videoOwnerUid = dict?["videoOwnerUid"] as? String ?? ""
                                    let youtubeId = dict?["youtubeId"] as? String ?? ""
                                    let youtubeImg = dict?["youtubeImg"] as? String ?? ""
                                    let publicPost = dict?["publicPost"] as? String ?? ""
                                    let postConsole = dict?["postConsole"] as? String ?? ""
                                    let title = dict?["title"] as? String ?? ""
                                    
                                    currentGamePosts.append(PostObject(postId: postId, title: title, videoOwnerGamerTag: videoOwnerGamerTag, videoOwnerUid: videoOwnerUid, publicPost: publicPost, date: date, youtubeId: youtubeId, imgUrl: youtubeImg, postConsole: postConsole, game: game))
                                }
                            }
                        
                            if(posts.count < postMaxCount) {
                                posts.append(contentsOf: currentGamePosts)
                            } else {
                                return
                            }
                        }
                    }
                }
            }
            appDelegate.currentPreSplash?.transitionHome()
        })
    }
    
    func randomSelection(from dict: [String], count: Int) -> [String] {
        guard !dict.isEmpty else { return [] }

        var result = [String]()

        for i in 0..<count {
            let element = dict.randomElement()! //We know dictionary is not empty
            result.append(element)
        }
        return result
    }
    
    func getRandomNumber(lower: UInt32, upper: UInt32) -> UInt32{
        return arc4random_uniform(upper - lower) + lower
    }
}
