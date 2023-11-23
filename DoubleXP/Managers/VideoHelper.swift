//
//  VideoHelper.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/3/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation
import Firebase

class VideoHelper {
    func getCurrentVideoComments(currentPostId: String, videoOwnerUid: String, videoHelperCallback: VideoHelperCallbacks){
        let videoCommentsRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        videoCommentsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for postCategory in snapshot.children {
                    for post in (postCategory as! DataSnapshot).children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(currentPostId == postId){
                            let upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            let downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            var commentObjs = [VideoCommentObject]()
                            let comments = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            if(comments?.exists() == true){
                                for comment in comments!.children {
                                    let message = (comment as? DataSnapshot)?.childSnapshot(forPath: "message").value as? String ?? ""
                                    let timeStamp = (comment as? DataSnapshot)?.childSnapshot(forPath: "timeStamp").value as? String ?? ""
                                    let newVideoComment = VideoCommentObject(message: message, timeStamp: timeStamp)
                                    let commentId = (comment as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    let senderUid = (comment as? DataSnapshot)?.childSnapshot(forPath: "senderUid").value as? String ?? ""
                                    let senderGamerTag = (comment as? DataSnapshot)?.childSnapshot(forPath: "senderGamerTag").value as? String ?? ""
                                    let upVotes = (comment as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                    let downVotes = (comment as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                    newVideoComment.commentId = commentId
                                    newVideoComment.senderUid = senderUid
                                    newVideoComment.upvotes = upVotes
                                    newVideoComment.downVotes = downVotes
                                    newVideoComment.senderGamerTag = senderGamerTag
                                    commentObjs.append(newVideoComment)
                                }
                                videoHelperCallback.getCommentsSuccessful(comments: commentObjs, upVotes: upVotes, downVotes: downVotes)
                                break
                            } else {
                                videoHelperCallback.getCommentsSuccessful(comments: [VideoCommentObject](), upVotes: upVotes, downVotes: downVotes)
                            }
                        }
                    }
                }
            }
        })
    }
    
    func addCommentPublicPost(postingUserId: String, postingGamerTag: String, currentPostId: String, postVideoGame: String?, videoOwnerUid: String, commentText: String, callback: VideoHelperCallbacks){
        let publicPostRef = Database.database().reference().child("Public Posts").child(videoOwnerUid)
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                let commentId = self.randomAlphaNumericString(length: 10)
                                var comments = (post as? DataSnapshot)?.childSnapshot(forPath: "comments").value as? [[String: String]] ?? [[String: String]]()
                                let newComment = ["message": commentText, "commentId": commentId,
                                                  "senderUid": postingUserId, "senderGamerTag": "", "timeStamp": String(Date().millisecondsSince1970)
                                ]
                                comments.append(newComment)
                                publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").setValue(comments)
                                self.addCommentPrivatePost(postingUserId: postingUserId, postingGamerTag: postingGamerTag, currentPostId: currentPostId, postVideoGame: postVideoGame, videoOwnerUid: videoOwnerUid, commentText: commentText, commentId: commentId, callback: callback)
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(currentPostId == postId){
                            let commentId = self.randomAlphaNumericString(length: 10)
                            var comments = (post as? DataSnapshot)?.childSnapshot(forPath: "comments").value as? [[String: String]] ?? [[String: String]]()
                            let newComment = ["message": commentText, "commentId": commentId,
                                              "senderUid": postingUserId, "senderGamerTag": postingGamerTag, "timeStamp": String(Date().millisecondsSince1970)
                            ]
                            comments.append(newComment)
                            publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").setValue(comments)
                            
                            self.addCommentPrivatePost(postingUserId: postingUserId, postingGamerTag: postingGamerTag, currentPostId: currentPostId, postVideoGame: postVideoGame, videoOwnerUid: videoOwnerUid, commentText: commentText, commentId: commentId, callback: callback)
                            break
                        }
                    }
                }
            }
        })
    }
    
    func addCommentPrivatePost(postingUserId: String, postingGamerTag: String, currentPostId: String, postVideoGame: String?, videoOwnerUid: String, commentText: String, commentId: String?, callback: VideoHelperCallbacks){
        let privatePostRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        privatePostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        var posts = [[String: Any]]()
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let date = (post as? DataSnapshot)?.childSnapshot(forPath: "date").value as? String ?? ""
                            let game = (post as? DataSnapshot)?.childSnapshot(forPath: "game").value as? String ?? ""
                            let postConsole = (post as? DataSnapshot)?.childSnapshot(forPath: "postConsole").value as? String ?? ""
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            let publicPost = (post as? DataSnapshot)?.childSnapshot(forPath: "publicPost").value as? String ?? ""
                            let title = (post as? DataSnapshot)?.childSnapshot(forPath: "title").value as? String ?? ""
                            let videoOwnerGamerTag = (post as? DataSnapshot)?.childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? ""
                            let videoOwnerUid = (post as? DataSnapshot)?.childSnapshot(forPath: "videoOwnerUid").value as? String ?? ""
                            let youtubeId = (post as? DataSnapshot)?.childSnapshot(forPath: "youtubeId").value as? String ?? ""
                            let youtubeImg = (post as? DataSnapshot)?.childSnapshot(forPath: "youtubeImg").value as? String ?? ""
                            var comments = (post as? DataSnapshot)?.childSnapshot(forPath: "comments").value as? [[String: Any]] ?? [[String: Any]]()
                            let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            let newId = self.randomAlphaNumericString(length: 10)
                            let currentTimeStamp = String(Date().millisecondsSince1970)
                            var usableId = newId
                            if(commentId != nil){
                                usableId = commentId!
                            }
                            if(currentPostId == postId){
                                let newComment = ["message": commentText, "commentId": usableId,
                                                  "senderUid": postingUserId, "senderGamerTag": postingGamerTag, "timeStamp": currentTimeStamp
                                ]
                                comments.append(newComment)
                                
                                var commentObjs = [VideoCommentObject]()
                                if(commentsSnapshot?.exists() == true){
                                    for commentObj in commentsSnapshot!.children {
                                        let message = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "message").value as? String ?? ""
                                        let timeStamp = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "timeStamp").value as? String ?? ""
                                        var newVideoComment = VideoCommentObject(message: message, timeStamp: timeStamp)
                                        let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                        let senderUid = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "senderUid").value as? String ?? ""
                                        let senderGamerTag = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "senderGamerTag").value as? String ?? ""
                                        newVideoComment.commentId = commentId
                                        newVideoComment.senderUid = senderUid
                                        newVideoComment.senderGamerTag = senderGamerTag
                                        commentObjs.append(newVideoComment)
                                    }
                                }
                                let newCommentObj = VideoCommentObject(message: commentText, timeStamp: currentTimeStamp)
                                newCommentObj.senderUid = postingUserId
                                newCommentObj.senderGamerTag = postingGamerTag
                                newCommentObj.commentId = newId
                                commentObjs.append(newCommentObj)
                                callback.onCommentPosted(comments: commentObjs)
                            }
                            posts.append(["date": date, "game": game, "postConsole": postConsole, "postId": postId, "publicPost": publicPost,
                                          "title": title, "videoOwnerGamerTag": videoOwnerGamerTag, "videoOwnerUid": videoOwnerUid, "youtubeId": youtubeId,
                                          "youtubeImg": youtubeImg, "comments": comments
                            ])
                        }
                        privatePostRef.child(postVideoGame!).setValue(posts)
                    }
                } else if(snapshot.hasChild("other")){
                    var posts = [[String: Any]]()
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let date = (post as? DataSnapshot)?.childSnapshot(forPath: "date").value as? String ?? ""
                        let game = (post as? DataSnapshot)?.childSnapshot(forPath: "game").value as? String ?? ""
                        let postConsole = (post as? DataSnapshot)?.childSnapshot(forPath: "postConsole").value as? String ?? ""
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        let publicPost = (post as? DataSnapshot)?.childSnapshot(forPath: "publicPost").value as? String ?? ""
                        let title = (post as? DataSnapshot)?.childSnapshot(forPath: "title").value as? String ?? ""
                        let videoOwnerGamerTag = (post as? DataSnapshot)?.childSnapshot(forPath: "videoOwnerGamerTag").value as? String ?? ""
                        let videoOwnerUid = (post as? DataSnapshot)?.childSnapshot(forPath: "videoOwnerUid").value as? String ?? ""
                        let youtubeId = (post as? DataSnapshot)?.childSnapshot(forPath: "youtubeId").value as? String ?? ""
                        let youtubeImg = (post as? DataSnapshot)?.childSnapshot(forPath: "youtubeImg").value as? String ?? ""
                        var comments = (post as? DataSnapshot)?.childSnapshot(forPath: "comments").value as? [[String: Any]] ?? [[String: Any]]()
                        let newId = self.randomAlphaNumericString(length: 10)
                        let currentTimeStamp = String(Date().millisecondsSince1970)
                        let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                        var usableId = newId
                        if(commentId != nil){
                            usableId = commentId!
                        }
                        if(currentPostId == postId){
                            let newComment = ["message": commentText, "commentId": usableId,
                                              "senderUid": postingUserId, "senderGamerTag": postingGamerTag, "timeStamp": currentTimeStamp
                            ]
                            comments.append(newComment)
                            
                            var commentObjs = [VideoCommentObject]()
                            if(commentsSnapshot?.exists() == true){
                                for commentObj in commentsSnapshot!.children {
                                    let message = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "message").value as? String ?? ""
                                    let timeStamp = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "timeStamp").value as? String ?? ""
                                    var newVideoComment = VideoCommentObject(message: message, timeStamp: timeStamp)
                                    let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    let senderUid = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "senderUid").value as? String ?? ""
                                    let senderGamerTag = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "senderGamerTag").value as? String ?? ""
                                    newVideoComment.commentId = commentId
                                    newVideoComment.senderUid = senderUid
                                    newVideoComment.senderGamerTag = senderGamerTag
                                    commentObjs.append(newVideoComment)
                                }
                            }
                            let newCommentObj = VideoCommentObject(message: commentText, timeStamp: currentTimeStamp)
                            newCommentObj.senderUid = postingUserId
                            newCommentObj.senderGamerTag = postingGamerTag
                            newCommentObj.commentId = newId
                            commentObjs.append(newCommentObj)
                            callback.onCommentPosted(comments: commentObjs)
                        }
                        posts.append(["date": date, "game": game, "postConsole": postConsole, "postId": postId, "publicPost": publicPost,
                                      "title": title, "videoOwnerGamerTag": videoOwnerGamerTag, "videoOwnerUid": videoOwnerUid, "youtubeId": youtubeId,
                                      "youtubeImg": youtubeImg, "comments": comments
                        ])
                    }
                    privatePostRef.child("other").setValue(posts)
                }
            }
        })
    }
    
    func addUpVotePublicPostComment(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?, currentCommentId: String){
        let publicPostRef = Database.database().reference().child("Public Posts").child(videoOwnerUid)
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                                if(commentsSnapshot?.exists() == true){
                                    for commentObj in commentsSnapshot!.children {
                                        let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                        if(commentId == currentCommentId){
                                            var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                            var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                            
                                            if(downVotes.contains(currentUserUid)){
                                                downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                                if(downVotes.isEmpty){
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").removeValue()
                                                } else {
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                                }
                                            }
                                            if(!upVotes.contains(currentUserUid)){
                                                upVotes.append(currentUserUid)
                                            }
                                            publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                            break
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            if(commentsSnapshot?.exists() == true){
                                for commentObj in commentsSnapshot!.children {
                                    let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    if(commentId == currentCommentId){
                                        var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                        var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                        
                                        if(downVotes.contains(currentUserUid)){
                                            downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                            if(downVotes.isEmpty){
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").removeValue()
                                            } else {
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                            }
                                        }
                                        if(!upVotes.contains(currentUserUid)){
                                            upVotes.append(currentUserUid)
                                        }
                                        publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                        break
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
            self.addUpVotePrivatePostComment(currentUserUid: currentUserUid, videoOwnerUid: videoOwnerUid, currentPostId: currentPostId, postVideoGame: postVideoGame, currentCommentId: currentCommentId)
        })
    }
    
    func addUpVotePrivatePostComment(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?, currentCommentId: String){
        let publicPostRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                                if(commentsSnapshot?.exists() == true){
                                    for commentObj in commentsSnapshot!.children {
                                        let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                        if(commentId == currentCommentId){
                                            var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                            var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                            
                                            if(downVotes.contains(currentUserUid)){
                                                downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                                if(downVotes.isEmpty){
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").removeValue()
                                                } else {
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                                }
                                            }
                                            if(!upVotes.contains(currentUserUid)){
                                                upVotes.append(currentUserUid)
                                            }
                                            publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                            break
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            if(commentsSnapshot?.exists() == true){
                                for commentObj in commentsSnapshot!.children {
                                    let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    if(commentId == currentCommentId){
                                        var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                        var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                        
                                        if(downVotes.contains(currentUserUid)){
                                            downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                            if(downVotes.isEmpty){
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").removeValue()
                                            } else {
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                            }
                                        }
                                        if(!upVotes.contains(currentUserUid)){
                                            upVotes.append(currentUserUid)
                                        }
                                        publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                        break
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        })
    }
    
    func addDownVotePublicPostComment(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?, currentCommentId: String){
        let publicPostRef = Database.database().reference().child("Public Posts").child(videoOwnerUid)
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                                if(commentsSnapshot?.exists() == true){
                                    for commentObj in commentsSnapshot!.children {
                                        let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                        if(commentId == currentCommentId){
                                            var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                            var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                            
                                            if(upVotes.contains(currentUserUid)){
                                                upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                                if(upVotes.isEmpty){
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").removeValue()
                                                } else {
                                                    publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                                }
                                            }
                                            if(!downVotes.contains(currentUserUid)){
                                                downVotes.append(currentUserUid)
                                            }
                                            publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                            break
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            if(commentsSnapshot?.exists() == true){
                                for commentObj in commentsSnapshot!.children {
                                    let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    if(commentId == currentCommentId){
                                        var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                        var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                        
                                        if(upVotes.contains(currentUserUid)){
                                            upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                            if(upVotes.isEmpty){
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").removeValue()
                                            } else {
                                                publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                            }
                                        }
                                        if(!downVotes.contains(currentUserUid)){
                                            downVotes.append(currentUserUid)
                                        }
                                        publicPostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                        break
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
            self.addDownVotePrivatePostComment(currentUserUid: currentUserUid, videoOwnerUid: videoOwnerUid, currentPostId: currentPostId, postVideoGame: postVideoGame, currentCommentId: currentCommentId)
        })
    }
    
    func addDownVotePrivatePostComment(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?, currentCommentId: String){
        let privatePostRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        privatePostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                                if(commentsSnapshot?.exists() == true){
                                    for commentObj in commentsSnapshot!.children {
                                        let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                        if(commentId == currentCommentId){
                                            var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                            var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                            
                                            if(upVotes.contains(currentUserUid)){
                                                upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                                if(upVotes.isEmpty){
                                                    privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").removeValue()
                                                } else {
                                                    privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                                }
                                            }
                                            if(!downVotes.contains(currentUserUid)){
                                                downVotes.append(currentUserUid)
                                            }
                                            privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                            break
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            let commentsSnapshot = (post as? DataSnapshot)?.childSnapshot(forPath: "comments")
                            if(commentsSnapshot?.exists() == true){
                                for commentObj in commentsSnapshot!.children {
                                    let commentId = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "commentId").value as? String ?? ""
                                    if(commentId == currentCommentId){
                                        var upVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                        var downVotes = (commentObj as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                        
                                        if(upVotes.contains(currentUserUid)){
                                            upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                            if(upVotes.isEmpty){
                                                privatePostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").removeValue()
                                            } else {
                                                privatePostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                            }
                                        }
                                        if(!downVotes.contains(currentUserUid)){
                                            downVotes.append(currentUserUid)
                                        }
                                        privatePostRef.child("other").child((post as! DataSnapshot).key).child("comments").child((commentObj as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                        break
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        })
    }
    
    func addUpVotePublicPost(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?){
        let publicPostRef = Database.database().reference().child("Public Posts").child(videoOwnerUid)
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                
                                if(downVotes.contains(currentUserUid)){
                                    downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                    if(downVotes.isEmpty){
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").removeValue()
                                    } else {
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                    }
                                }
                                if(!upVotes.contains(currentUserUid)){
                                    upVotes.append(currentUserUid)
                                }
                                publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            
                            if(downVotes.contains(currentUserUid)){
                                downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                if(downVotes.isEmpty){
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").removeValue()
                                } else {
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                }
                            }
                            if(!upVotes.contains(currentUserUid)){
                                upVotes.append(currentUserUid)
                            }
                            publicPostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                            break
                        }
                    }
                }
            }
            self.addUpVotePrivatePost(currentUserUid: currentUserUid, videoOwnerUid: videoOwnerUid, currentPostId: currentPostId, postVideoGame: postVideoGame)
        })
    }
    
    func addUpVotePrivatePost(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?){
        let publicPostRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                
                                if(downVotes.contains(currentUserUid)){
                                    downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                    if(downVotes.isEmpty){
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").removeValue()
                                    } else {
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                    }
                                }
                                if(!upVotes.contains(currentUserUid)){
                                    upVotes.append(currentUserUid)
                                }
                                publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            
                            if(downVotes.contains(currentUserUid)){
                                downVotes.remove(at: downVotes.firstIndex(of: currentUserUid)!)
                                if(downVotes.isEmpty){
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").removeValue()
                                } else {
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                }
                            }
                            if(!upVotes.contains(currentUserUid)){
                                upVotes.append(currentUserUid)
                            }
                            publicPostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                            break
                        }
                    }
                }
            }
        })
    }
    
    func addDownVotePublicPost(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?){
        let publicPostRef = Database.database().reference().child("Public Posts").child(videoOwnerUid)
        publicPostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                
                                if(upVotes.contains(currentUserUid)){
                                    upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                    if(upVotes.isEmpty){
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").removeValue()
                                    } else {
                                        publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                    }
                                }
                                if(!downVotes.contains(currentUserUid)){
                                    downVotes.append(currentUserUid)
                                }
                                publicPostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            
                            if(upVotes.contains(currentUserUid)){
                                upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                if(upVotes.isEmpty){
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").removeValue()
                                } else {
                                    publicPostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                }
                            }
                            if(!downVotes.contains(currentUserUid)){
                                downVotes.append(currentUserUid)
                            }
                            publicPostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                            break
                        }
                    }
                }
            }
            self.addDownVotePrivatePost(currentUserUid: currentUserUid, videoOwnerUid: videoOwnerUid, currentPostId: currentPostId, postVideoGame: postVideoGame)
        })
    }
    
    func addDownVotePrivatePost(currentUserUid: String, videoOwnerUid: String, currentPostId: String, postVideoGame: String?){
        let privatePostRef = Database.database().reference().child("Users").child(videoOwnerUid).child("myPosts")
        privatePostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(postVideoGame != nil && !postVideoGame!.isEmpty){
                    if(snapshot.hasChild(postVideoGame!)){
                        for post in snapshot.childSnapshot(forPath: postVideoGame!).children {
                            let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                            if(postId == currentPostId){
                                var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                                var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                                
                                if(upVotes.contains(currentUserUid)){
                                    upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                    if(upVotes.isEmpty){
                                        privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").removeValue()
                                    } else {
                                        privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                    }
                                }
                                if(!downVotes.contains(currentUserUid)){
                                    downVotes.append(currentUserUid)
                                }
                                privatePostRef.child(postVideoGame!).child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                                break
                            }
                        }
                    }
                } else if(snapshot.hasChild("other")){
                    for post in snapshot.childSnapshot(forPath: "other").children {
                        let postId = (post as? DataSnapshot)?.childSnapshot(forPath: "postId").value as? String ?? ""
                        if(postId == currentPostId){
                            var upVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "upVotes").value as? [String] ?? [String]()
                            var downVotes = (post as? DataSnapshot)?.childSnapshot(forPath: "downVotes").value as? [String] ?? [String]()
                            
                            if(upVotes.contains(currentUserUid)){
                                upVotes.remove(at: upVotes.firstIndex(of: currentUserUid)!)
                                if(upVotes.isEmpty){
                                    privatePostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").removeValue()
                                } else {
                                    privatePostRef.child("other").child((post as! DataSnapshot).key).child("upVotes").setValue(upVotes)
                                }
                            }
                            if(!downVotes.contains(currentUserUid)){
                                downVotes.append(currentUserUid)
                            }
                            privatePostRef.child("other").child((post as! DataSnapshot).key).child("downVotes").setValue(downVotes)
                            break
                        }
                    }
                }
            }
        })
    }
    
    func addPostToFollowers(followerUid: String, postObj: [String: Any]){
        let privatePostRef = Database.database().reference().child("Users").child(followerUid).child("receivedPosts")
        privatePostRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var posts = snapshot.value as? [[String: Any]] ?? [[String: Any]]()
                posts.append(postObj)
                privatePostRef.setValue(posts)
            } else {
                privatePostRef.setValue([postObj])
            }
        })
    }
    
    private func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(UInt32(allowedChars.characters.count)))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
}

protocol VideoHelperCallbacks: class {
    func getCommentsSuccessful(comments: [VideoCommentObject], upVotes: [String], downVotes: [String])
    func onCommentPosted(comments: [VideoCommentObject])
}
