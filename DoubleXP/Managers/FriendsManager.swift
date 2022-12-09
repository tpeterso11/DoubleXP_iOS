//
//  FriendsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FriendsManager{
    func isInFriendList(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for friend in currentUser.friends{
            if(friend.uid == user.uId){
                contained = true
            }
        }
        
        return contained
    }
    
    func isAFollower(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for friend in currentUser.followers {
            if(friend.uid == user.uId){
                contained = true
            }
        }
        
        return contained
    }
    
    func isBlocked(user: User, currentUser: User) -> Bool{
        if(user.blockList.contains(currentUser.uId) || currentUser.blockList.contains(user.uId)){
            return true
        } else {
            return false
        }
    }
    
    func isFollowing(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for friend in user.following {
            if(friend.uid == currentUser.uId){
                contained = true
            }
        }
        
        return contained
    }
    
    func isFollower(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for friend in user.followers {
            if(friend.uid == currentUser.uId){
                contained = true
            }
        }
        
        return contained
    }
    
    
    func sendRequestFromProfile(currentUser: User, otherUser: User, callbacks: ProfileCallbacks){
        //check this. request is being sent to current user AND other user. Bad.
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        if(!checkListsForUser(user: otherUser, currentUser: currentUser!)){
            //first, add the current user to the OTHER users requests.
            let pendingRef = Database.database().reference().child("Users").child(otherUser.uId).child("pending_friends")
            pendingRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if(snapshot.exists()){
                    var requests = [FriendRequestObject]()
                    for request in snapshot.children {
                        let currentRequest = (request as! DataSnapshot)
                        var uid = ""
                        var gamertag = ""
                        var date = ""
                        if(currentRequest.hasChild("uid")){
                            uid = currentRequest.childSnapshot(forPath: "uid").value as? String ?? ""
                        }
                        if(currentRequest.hasChild("gamerTag")){
                            gamertag = currentRequest.childSnapshot(forPath: "gamerTag").value as? String ?? ""
                        }
                        if(currentRequest.hasChild("date")){
                            date = currentRequest.childSnapshot(forPath: "date").value as? String ?? ""
                        }
                        if(!uid.isEmpty && !gamertag.isEmpty && !date.isEmpty){
                            requests.append(FriendRequestObject(gamerTag: gamertag, date: date, uid: uid))
                        }
                    }
                    
                    let formatter = DateFormatter()
                     //2016-12-08 03:37:22 +0000
                     //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                     formatter.dateFormat = "MM-dd-yyyy"
                     let now = Date()
                     let dateString = formatter.string(from:now)
                     
                     //gamerTag is the currentUsers gamertag, the one making the request.
                     let otherUserfriendRequest = FriendRequestObject(gamerTag: currentUser!.gamerTag, date: dateString, uid: currentUser!.uId)
                    requests.append(otherUserfriendRequest)
                    
                    var pendingSendList = [[String: Any]]()
                    for friend in requests {
                        let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                        pendingSendList.append(current)
                    }
                    pendingRef.setValue(pendingSendList)
                } else {
                    var requests = [FriendRequestObject]()
                    let formatter = DateFormatter()
                     //2016-12-08 03:37:22 +0000
                     //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                     formatter.dateFormat = "MM-dd-yyyy"
                     let now = Date()
                     let dateString = formatter.string(from:now)
                     
                     //gamerTag is the currentUsers gamertag, the one making the request.
                     let otherUserfriendRequest = FriendRequestObject(gamerTag: currentUser!.gamerTag, date: dateString, uid: currentUser!.uId)
                    requests.append(otherUserfriendRequest)
                    
                    var pendingSendList = [[String: Any]]()
                    for friend in requests {
                        let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                        pendingSendList.append(current)
                    }
                    pendingRef.setValue(pendingSendList)
                }
                
                self.updateSendingReference(otherUser: otherUser, currentUser: currentUser!, callbacks: callbacks)
            })
        }
    }
    
    private func updateSendingReference(otherUser: User, currentUser: User, callbacks: ProfileCallbacks){
        let sendingRef = Database.database().reference().child("Users").child(currentUser.uId).child("sent_requests")
        sendingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var sendingArray = [FriendRequestObject]()
                for request in snapshot.children {
                    let currentRequest = (request as! DataSnapshot)
                    var uid = ""
                    var gamertag = ""
                    var date = ""
                    if(currentRequest.hasChild("uid")){
                        uid = currentRequest.childSnapshot(forPath: "uid").value as? String ?? ""
                    }
                    if(currentRequest.hasChild("gamertag")){
                        gamertag = currentRequest.childSnapshot(forPath: "gamertag").value as? String ?? ""
                    }
                    if(currentRequest.hasChild("date")){
                        date = currentRequest.childSnapshot(forPath: "date").value as? String ?? ""
                    }
                    if(!uid.isEmpty && !gamertag.isEmpty && !date.isEmpty){
                        sendingArray.append(FriendRequestObject(gamerTag: gamertag, date: date, uid: uid))
                    }
                }
                
                let formatter = DateFormatter()
                //2016-12-08 03:37:22 +0000
                //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let currentUserSentRequest = FriendRequestObject(gamerTag: otherUser.gamerTag, date: dateString, uid: otherUser.uId)
                sendingArray.append(currentUserSentRequest)
                
                var sendList = [[String: Any]]()
                for friend in sendingArray{
                    let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                    sendList.append(current)
                }
                sendingRef.setValue(sendList)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.currentUser!.sentRequests = sendingArray
                
                self.updateLists(user: delegate.currentUser!, callbacks: callbacks)
            } else {
                var sendingArray = [FriendRequestObject]()
                let formatter = DateFormatter()
                //2016-12-08 03:37:22 +0000
                //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let currentUserSentRequest = FriendRequestObject(gamerTag: otherUser.gamerTag, date: dateString, uid: otherUser.uId)
                sendingArray.append(currentUserSentRequest)
                
                var sendList = [[String: Any]]()
                for friend in sendingArray{
                    let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                    sendList.append(current)
                }
                sendingRef.setValue(sendList)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.currentUser!.sentRequests = sendingArray
                
                self.updateLists(user: delegate.currentUser!, callbacks: callbacks)
            }
        })
    }
    
    func acceptFriendFromProfile(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: ProfileCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let manager = GamerProfileManager()
        
        //Us First
        //First, lets remove the friend request
        let ref = Database.database().reference().child("Users").child(currentUserUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                if(value?["pending_friends"] is [String]){
                    var pendingRequests = value?["pending_friends"] as? [String] ?? [String]()
                    if(!pendingRequests.isEmpty){
                        for request in pendingRequests{
                            if(request == manager.getGamerTag(user: currentUser!)){
                                pendingRequests = pendingRequests.filter { $0 != manager.getGamerTag(user: currentUser!)}
                            }
                        }
                        
                        ref.child("pending_friends").setValue(pendingRequests)
                    }
                }
                else{
                    var pendingRequests = [FriendRequestObject]()
                    let friendsArray = snapshot.childSnapshot(forPath: "pending_friends")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        pendingRequests.append(newFriend)
                    }
                    
                    if(!pendingRequests.isEmpty){
                        for request in pendingRequests{
                            if(request.uid == currentUserUid){
                                pendingRequests.remove(at: pendingRequests.index(of: request)!)
                            }
                            if(request.uid == otherUserRequest.uid){
                                pendingRequests.remove(at: pendingRequests.index(of: request)!)
                                break
                            }
                        }
                    }
                    
                    var pendingSendList = [[String: Any]]()
                        for friend in pendingRequests{
                            let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                            if(friend.uid != otherUserRequest.uid && friend.uid != currentUserUid){
                                pendingSendList.append(current)
                            }
                    }
                    
                    ref.child("pending_friends").setValue(pendingSendList)
                    currentUser!.pendingRequests = pendingRequests
                }
                
                //Next, let's add the current user to the OTHER user's friends.
                //var friends = value?["friends"] as? [String] ?? [String]()
                let currentFriends = value?["friends"] as? NSDictionary
                var friends = [String: FriendObject]()
                var contained = false
                if(currentFriends != nil){
                    for friend in currentFriends!{
                        let dict = friend.value as? [String: String]
                        let newFriend = FriendObject(gamerTag: dict?["gamerTag"] ?? "", date: dict?["date"] ?? "", uid: dict?["uId"] ?? "")
                        
                        friends[newFriend.uid] = newFriend
                    }
                    
                    for friend in friends{
                        if(friend.key == otherUserRequest.uid){
                            contained = true
                            break
                        }
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    //2016-12-08 03:37:22 +0000
                    //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    
                    let newFriend = FriendObject(gamerTag: otherUserRequest.gamerTag, date: dateString, uid: otherUserRequest.uid)
                    
                    friends[otherUserRequest.uid] = newFriend
                    
                    var sendList = [[String: Any]]()
                    for teammate in friends{
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("friends").setValue(sendList)
                }
                
                self.updateCurrentUserProfile(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUserProfile(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: ProfileCallbacks){
        //Other User
        //First, lets remove the sent request
        let ref = Database.database().reference().child("Users").child(otherUserRequest.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                let manager = GamerProfileManager()
                
                let value = snapshot.value as? NSDictionary
                var tempArray = [FriendRequestObject]()
                let requestsArray = snapshot.childSnapshot(forPath: "sent_requests")
                for request in requestsArray.children{
                    let currentObj = request as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    tempArray.append(newFriend)
                }
                
                for request in tempArray{
                    if(request.uid == currentUserUid){
                        tempArray.remove(at: tempArray.index(of: request)!)
                        break
                    }
                }
                
                var sendList = [[String: Any]]()
                for request in tempArray{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("sent_requests").setValue(sendList)
                
                
                //Next, let's add the other user to the CURRENT user's friends.
                let currentFriends = value?["friends"] as? NSDictionary
                var contained = false
                var friends = [String: FriendObject]()
                if(currentFriends != nil){
                    for friend in currentFriends!{
                        let dict = friend.value as? [String: String]
                        let newFriend = FriendObject(gamerTag: dict?["gamerTag"] ?? "", date: dict?["date"] ?? "", uid: dict?["uId"] ?? "")
                        
                        friends[newFriend.uid] = newFriend
                    }
                    
                    for friend in friends{
                        if(friend.key == currentUser!.uId){
                            contained = true
                            break
                        }
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    //2016-12-08 03:37:22 +0000
                    //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    
                    let newFriend = FriendObject(gamerTag: manager.getGamerTag(user: currentUser!), date: dateString, uid: currentUser!.uId)
                    
                    friends[currentUser!.uId] = newFriend
                    
                    var sendList = [[String: Any]]()
                    for friend in friends{
                        let current = ["gamerTag": friend.value.gamerTag, "date": friend.value.date, "uid": friend.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("friends").setValue(sendList)
                }
                
                callbacks.onFriendAdded()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func declineRequestFromProfile(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: ProfileCallbacks){
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let manager = GamerProfileManager()
        
        //Other User First
        //First, lets remove the friend request
        let ref = Database.database().reference().child("Users").child(otherUserRequest.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var pendingRequests = [FriendRequestObject]()
                if(snapshot.hasChild("pending_friends")){
                let friendsArray = snapshot.childSnapshot(forPath: "pending_friends")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        pendingRequests.append(newFriend)
                    }
                    
                    if(!pendingRequests.isEmpty){
                        for request in pendingRequests{
                            if(request.uid == currentUserUid){
                                pendingRequests = pendingRequests.filter { $0 != request}
                                break
                            }
                        }
                    }
                    
                    var pendingSendList = [[String: Any]]()
                        for friend in pendingRequests{
                            let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                            pendingSendList.append(current)
                    }
                    
                    ref.child("pending_friends").setValue(pendingSendList)
                    currentUser!.pendingRequests = pendingRequests
                }
                self.updateCurrentUserRemoveProfile(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks)
            }
            else{
                self.updateCurrentUserRemoveProfile(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUserRemoveProfile(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: ProfileCallbacks){
        
        let ref = Database.database().reference().child("Users").child(currentUserUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
                var tempArray = [FriendRequestObject]()
                let requestsArray = snapshot.childSnapshot(forPath: "sent_requests")
                for request in requestsArray.children{
                    let currentObj = request as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    tempArray.append(newFriend)
                }
                
                for request in tempArray{
                    if(request.uid == otherUserRequest.uid){
                        tempArray.remove(at: tempArray.index(of: request)!)
                        break
                    }
                }
                
                var sendList = [[String: Any]]()
                for request in tempArray{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("sent_requests").setValue(sendList)
                currentUser!.sentRequests = tempArray
                
                callbacks.onFriendDeclined()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateLists(user: User, callbacks: ProfileCallbacks){
        //updates the current lists for the current user.
        let sendingRef = Database.database().reference().child("Users").child(user.uId).child("sent_requests")
        let friendsRef = Database.database().reference().child("Users").child(user.uId).child("friends")
        
        sendingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                if(value?["sent_requests"] is [String]){
                    var sentArray = [FriendRequestObject]()
                    let sentRequests = snapshot.value as? [String] ?? [String]()
                    if(!sentRequests.isEmpty){
                        for request in sentRequests{
                            let formatter = DateFormatter()
                            //2016-12-08 03:37:22 +0000
                            //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                            formatter.dateFormat = "MM-dd-yyyy"
                            let now = Date()
                            let dateString = formatter.string(from:now)
                            
                            let fixedRequest = FriendRequestObject(gamerTag: request, date: dateString, uid: user.uId)
                            
                            sentArray.append(fixedRequest)
                        }
                        
                        sendingRef.setValue(sentArray)
                        
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let currentUser = delegate.currentUser
                        currentUser!.sentRequests = sentArray
                    }
                }
                else{
                    var sentRequests = [FriendRequestObject]()
                    for friend in snapshot.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        sentRequests.append(newFriend)
                    }
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = delegate.currentUser
                    currentUser!.sentRequests = sentRequests
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        friendsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var friends = [FriendObject]()
                let friendsArray = snapshot.childSnapshot(forPath: "friends")
                for friend in friendsArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                    friends.append(newFriend)
                }
                user.friends = friends
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        callbacks.onFriendRequested()
    }
    
    func checkListsForUser(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for request in currentUser.pendingRequests{
            if(request.uid == user.uId){
                contained = true
                return contained
            }
        }
        
        for request in currentUser.sentRequests{
            if(request.uid == user.uId){
                contained = true
                return contained
            }
        }
        
        for friend in currentUser.friends{
            if(friend.uid == user.uId){
                contained = true
                break
            }
        }
        
        return contained
    }
    
    func acceptFriendFromRequests(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let manager = GamerProfileManager()
        
        //Other User First
        //First, lets remove the friend request
        let ref = Database.database().reference().child("Users").child(otherUserRequest.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                //first, remove sent request
                var tempArray = [FriendRequestObject]()
                let requestsArray = snapshot.childSnapshot(forPath: "sent_requests")
                for request in requestsArray.children{
                    let currentObj = request as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    tempArray.append(newFriend)
                }
                
                for request in tempArray{
                    if(request.uid == currentUserUid){
                        tempArray.remove(at: tempArray.index(of: request)!)
                        break
                    }
                }
                
                var reqSendList = [[String: Any]]()
                for request in tempArray{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                    reqSendList.append(current)
                }
                
                ref.child("sent_requests").setValue(reqSendList)
                
                let value = snapshot.value as? NSDictionary
                
                //Next, let's add the current user to the OTHER user's friends.
                //var friends = value?["friends"] as? [String] ?? [String]()
                let currentFriends = value?["friends"] as? NSDictionary
                var friends = [String: FriendObject]()
                
                if(currentFriends != nil){
                    for friend in currentFriends!{
                        let dict = friend.value as? [String: String]
                        let newFriend = FriendObject(gamerTag: dict?["gamerTag"] ?? "", date: dict?["date"] ?? "", uid: dict?["uId"] ?? "")
                        
                        friends[newFriend.uid] = newFriend
                    }
                }
                
                var contained = false
                for friend in friends{
                    if(friend.key == currentUser!.uId){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    //2016-12-08 03:37:22 +0000
                    //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    
                    let newFriend = FriendObject(gamerTag: manager.getGamerTag(user: currentUser!), date: dateString, uid: currentUser!.uId)
                    
                    friends[currentUser!.uId] = newFriend
                }
                
                var sendList = [[String: Any]]()
                for teammate in friends{
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("friends").setValue(sendList)
                
                self.updateCurrentUser(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUser(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
        //Now Current User
        //First, lets remove the sent request
        let ref = Database.database().reference().child("Users").child(currentUserUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                let manager = GamerProfileManager()
                
                let value = snapshot.value as? NSDictionary
                var pendingRequests = [FriendRequestObject]()
                let friendsArray = snapshot.childSnapshot(forPath: "pending_friends")
                for friend in friendsArray.children{
                    let currentObj = friend as! DataSnapshot
                    let dict = currentObj.value as? [String: Any]
                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                    let date = dict?["date"] as? String ?? ""
                    let uid = dict?["uid"] as? String ?? ""
                    
                    let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                    pendingRequests.append(newFriend)
                }
                
                
                if(!pendingRequests.isEmpty){
                    for request in pendingRequests{
                        if(request.uid == otherUserRequest.uid){
                            pendingRequests.remove(at: pendingRequests.index(of: request)!)
                            break
                        }
                    }
                }
                
                var pendingSendList = [[String: Any]]()
                for request in pendingRequests{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                    pendingSendList.append(current)
                }
                
                ref.child("pending_friends").setValue(pendingSendList)
                currentUser!.pendingRequests = pendingRequests
                
                //Next, let's add the other user to the CURRENT user's friends.
                let currentFriends = value?["friends"] as? NSDictionary
                var friends = [String: FriendObject]()
                
                if(currentFriends != nil){
                    for friend in currentFriends!{
                        let dict = friend.value as? [String: String]
                        let newFriend = FriendObject(gamerTag: dict?["gamerTag"] ?? "", date: dict?["date"] ?? "", uid: dict?["uId"] ?? "")
                        
                        friends[newFriend.uid] = newFriend
                    }
                }
                
                var contained = false
                for friend in friends{
                    if(friend.key == otherUserRequest.uid){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    //if the friend is not already there, add. Then send.
                    let formatter = DateFormatter()
                    //2016-12-08 03:37:22 +0000
                    //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    
                    let newFriend = FriendObject(gamerTag: otherUserRequest.gamerTag, date: dateString, uid: otherUserRequest.uid)
                    
                    friends[otherUserRequest.uid] = newFriend
                    
                    var sendList = [[String: Any]]()
                    for friend in friends{
                        let current = ["gamerTag": friend.value.gamerTag, "date": friend.value.date, "uid": friend.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("friends").setValue(sendList)
                }
                else{
                    //else, just send the list as it is.
                    var sendList = [[String: Any]]()
                    for friend in friends{
                        let current = ["gamerTag": friend.value.gamerTag, "date": friend.value.date, "uid": friend.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("friends").setValue(friends)
                }
                
                callbacks.updateCell()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func declineRequest(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        let manager = GamerProfileManager()
        
        //Other User First
        //First, lets remove the friend request
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                if(value?["pending_friends"] is [String]){
                    var pendingRequests = value?["pending_friends"] as? [String] ?? [String]()
                    if(!pendingRequests.isEmpty){
                        for request in pendingRequests{
                            if(request == manager.getGamerTag(user: currentUser!)){
                                pendingRequests = pendingRequests.filter { $0 != manager.getGamerTag(user: currentUser!)}
                            }
                        }
                        
                        ref.child("pending_friends").setValue(pendingRequests)
                    }
                }
                else{
                    let pendingArray = snapshot.childSnapshot(forPath: "pending_friends")
                    var tempList = [FriendRequestObject]()
                    for friend in pendingArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let request = FriendRequestObject(gamerTag: tag, date: date, uid: uid)
                        tempList.append(request)
                    }
                    
                    for request in tempList{
                        if(request.uid == otherUserRequest.uid){
                            tempList.remove(at: tempList.index(of: request)!)
                            break
                        }
                    }
                    
                    var sendList = [[String: Any]]()
                    for request in tempList{
                        let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("pending_friends").setValue(sendList)
                    currentUser!.pendingRequests = tempList
                }
                
                
                self.updateCurrentUserRemove(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUserRemove(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
        
        let ref = Database.database().reference().child("Users").child(currentUserUid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                let manager = GamerProfileManager()
                
                let value = snapshot.value as? NSDictionary
                var sentRequests = value?["sent_requests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                
                if(!sentRequests.isEmpty){
                    for request in sentRequests{
                        if(request.uid == otherUserRequest.uid){
                            sentRequests = sentRequests.filter { $0 != request}
                            break
                        }
                    }
                }
                
                var sendList = [[String: Any]]()
                for request in sentRequests{
                    let current = ["gamerTag": request.gamerTag, "date": request.date, "uid": request.uid] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("sent_requests").setValue(sendList)
                currentUser!.sentRequests = sentRequests
                
                callbacks.updateCell()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func createRivalRequest(otherUser: User, game: String, type: String, callbacks: RequestsUpdate, gamerTags: [GamerProfile]){
        //send request
        let ref = Database.database().reference().child("Users").child(otherUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
                var rivals = [RivalObj]()
                if(snapshot.hasChild("tempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "tempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        
                        let dbDate = self.stringToDate(date)
                        
                        if(dbDate != nil){
                            let now = NSDate()
                            let formatter = DateFormatter()
                            formatter.timeZone = TimeZone(abbreviation: "UTC")
                            formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                            let future = formatter.string(from: now as Date)
                            let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validRival = dbDate.compare(.isEarlier(than: dbFuture))
                            
                            if(dbFuture != nil){
                                if(validRival){
                                    rivals.append(request)
                                }
                            }
                        }
                    }
                }
                
                let manager = GamerProfileManager()
                var contained = false
                for rival in rivals{
                    if(rival.gamerTag == currentUser!.gamerTag){
                        contained = true
                        callbacks.rivalRequestAlready()
                        return
                    }
                }
                
                if(!contained){
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    let result = formatter.string(from: date)
                    
                    let currentRival = RivalObj(gamerTag: currentUser!.gamerTag, date: result, game: game, uid: currentUser!.uId, type: type, id: self.createTempId())
                    
                    rivals.append(currentRival)
                    
                    var sendList = [[String: Any]]()
                    for rival in rivals{
                        let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "type": rival.type, "id": rival.id] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("tempRivals").setValue(sendList)
                    
                    self.updateCurrentUserRivals(currentUser: currentUser!, otherUser: otherUser, game: game, type: type, callbacks: callbacks, gamerTags: gamerTags, dateString: result)
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.rivalRequestFail()
        }
    }
    
    func createOnlineAnnouncement(friends: [String], callbacks: RequestsUpdate){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let announcementId = createTempId()
        //send request
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var tokens = [String]()
                for friend in friends {
                    let currentSnapshot = snapshot.childSnapshot(forPath: friend)
                    if(currentSnapshot != nil){
                        if(currentSnapshot.hasChild("fcmToken")){
                            let tag = currentSnapshot.childSnapshot(forPath: "fcmToken").value as? String ?? ""
                            if(!tokens.contains(tag)){
                                tokens.append(currentSnapshot.childSnapshot(forPath: "fcmToken").value as? String ?? "")
                            }
                        }
                        if(currentSnapshot.hasChild("receivedAnnouncements")){
                            var array = currentSnapshot.childSnapshot(forPath: "receivedAnnouncements").value as? [String] ?? [String]()
                            if(!array.contains(currentUser.uId)){
                                array.append(currentUser.uId)
                                ref.child(currentSnapshot.key).child("receivedAnnouncements").setValue(array)
                            }
                        } else {
                            var array = [String]()
                            array.append(currentUser.uId)
                            ref.child(currentSnapshot.key).child("receivedAnnouncements").setValue(array)
                        }
                    }
                }
                
                let currentUserSnapshot = snapshot.childSnapshot(forPath: currentUser.uId)
                var announcements = [OnlineObj]()
                if(currentUserSnapshot.hasChild("onlineAnnouncements")){
                    let onlineAnnouncements = currentUserSnapshot.childSnapshot(forPath: "onlineAnnouncements")
                    for announce in onlineAnnouncements.children{
                        let currentObj = announce as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["tag"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        let friends = dict?["friends"] as? [String] ?? [String]()
                        
                        let request = OnlineObj(tag: tag, friends: friends, date: date, id: id)
                        
                        let dbDate = self.stringToDate(date)
                        
                        if(dbDate != nil){
                            let now = NSDate()
                            let formatter = DateFormatter()
                            formatter.timeZone = TimeZone(abbreviation: "UTC")
                            formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                            let future = formatter.string(from: now as Date)
                            let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validAnnouncement = dbDate.compare(.isEarlier(than: dbFuture))
                            
                            if(dbFuture != nil){
                                if(validAnnouncement){
                                    announcements.append(request)
                                }
                            }
                        }
                    }
                }
                
                if(announcements.isEmpty){
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    let result = formatter.string(from: date)
                    
                    let newObj = ["tag": currentUser.gamerTag, "friends": tokens, "id": announcementId, "date": result] as [String : Any]
                    let ref = Database.database().reference().child("Users").child(currentUser.uId)
                    ref.child("onlineAnnouncements").child(announcementId).setValue(newObj)
                    
                    callbacks.onlineAnnounceSent()
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.onlineAnnounceFail()
        }
    }
    
    func createStreamingAnnouncement(friends: [String], callbacks: RequestsUpdate){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let announcementId = createTempId()
        //send request
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var tokens = [String]()
                for friend in friends {
                    let currentSnapshot = snapshot.childSnapshot(forPath: friend)
                    if(currentSnapshot != nil){
                        if(currentSnapshot.hasChild("fcmToken")){
                            let tag = currentSnapshot.childSnapshot(forPath: "fcmToken").value as? String ?? ""
                            if(!tokens.contains(tag)){
                                tokens.append(currentSnapshot.childSnapshot(forPath: "fcmToken").value as? String ?? "")
                            }
                        }
                        if(currentSnapshot.hasChild("receivedAnnouncements")){
                            var array = currentSnapshot.childSnapshot(forPath: "receivedAnnouncements").value as? [String] ?? [String]()
                            if(!array.contains(currentUser.uId)){
                                array.append(currentUser.uId)
                                ref.child(currentSnapshot.key).child("receivedAnnouncements").setValue(array)
                            }
                        } else {
                            var array = [String]()
                            array.append(currentUser.uId)
                            ref.child(currentSnapshot.key).child("receivedAnnouncements").setValue(array)
                        }
                    }
                }
                
                let currentUserSnapshot = snapshot.childSnapshot(forPath: currentUser.uId)
                var announcements = [OnlineObj]()
                if(currentUserSnapshot.hasChild("onlineAnnouncements")){
                    let onlineAnnouncements = currentUserSnapshot.childSnapshot(forPath: "onlineAnnouncements")
                    for announce in onlineAnnouncements.children{
                        let currentObj = announce as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["tag"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        let friends = dict?["friends"] as? [String] ?? [String]()
                        
                        let request = OnlineObj(tag: tag, friends: friends, date: date, id: id)
                        
                        let dbDate = self.stringToDate(date)
                        
                        if(dbDate != nil){
                            let now = NSDate()
                            let formatter = DateFormatter()
                            formatter.timeZone = TimeZone(abbreviation: "UTC")
                            formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                            let future = formatter.string(from: now as Date)
                            let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validAnnouncement = dbDate.compare(.isEarlier(than: dbFuture))
                            
                            if(dbFuture != nil){
                                if(validAnnouncement){
                                    announcements.append(request)
                                }
                            }
                        }
                    }
                }
                
                if(announcements.isEmpty){
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    let result = formatter.string(from: date)
                    
                    let newObj = ["tag": currentUser.gamerTag, "friends": tokens, "id": announcementId, "date": result] as [String : Any]
                    let ref = Database.database().reference().child("Users").child(currentUser.uId)
                    ref.child("onlineAnnouncements").child(announcementId).setValue(newObj)
                    
                    callbacks.onlineAnnounceSent()
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.onlineAnnounceFail()
        }
    }
    
    private func createTempId() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in letters.randomElement()! })
    }
    
    private func updateCurrentUserRivals(currentUser: User, otherUser: User, game: String, type: String, callbacks: RequestsUpdate, gamerTags: [GamerProfile], dateString: String){
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                
                let newRival = RivalObj(gamerTag: currentUser!.gamerTag, date: dateString, game: game, uid: otherUser.uId, type: type, id: self.createTempId())
                currentUser!.currentTempRivals.append(newRival)
                
                var rivals = [RivalObj]()
                if(snapshot.hasChild("currentTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "currentTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        
                        let dbDate = self.stringToDate(date)
                        if(dbDate != nil){
                            let now = NSDate()
                            let formatter = DateFormatter()
                            formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                            formatter.timeZone = TimeZone(abbreviation: "UTC")
                            let future = formatter.string(from: now as Date)
                            let dbFuture = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                            
                            let validRival = dbDate.compare(.isEarlier(than: dbFuture))
                            
                            if(dbFuture != nil){
                                if(validRival){
                                    rivals.append(request)
                                }
                            }
                        }
                    }
                }
                
                var contained = false
                for rival in rivals{
                    if(rival.gamerTag == otherUser.gamerTag){
                        contained = true
                        return
                    }
                }
                
                if(!contained){
                    rivals.append(newRival)
                    
                    var sendList = [[String: Any]]()
                    for rival in rivals{
                        let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "type": rival.type, "id": rival.id] as [String : String]
                        sendList.append(current)
                    }
                    
                    ref.child("currentTempRivals").setValue(sendList)
                    
                    callbacks.rivalRequestSuccess()
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.rivalRequestFail()
        }
    }
    
    func acceptPlayRequest(rival: RivalObj, callbacks: RequestsUpdate){
        //update other user
        let ref = Database.database().reference().child("Users").child(rival.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                let tag = currentUser!.gamerTag
                
                var tempRivals = [RivalObj]()
                if(snapshot.hasChild("tempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "tempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        tempRivals.append(request)
                    }
                }
                
                for tempRival in tempRivals{
                    if(tempRival.id == rival.id){
                        tempRivals.remove(at: tempRivals.index(of: tempRival)!)
                    }
                }
                
                var sendArray = [[String: String]]()
                for rival in tempRivals{
                    var newMap = [String: String]()
                    newMap["gamerTag"] = rival.gamerTag
                    newMap["game"] = rival.game
                    newMap["uid"] = rival.uid
                    newMap["type"] = rival.type
                    newMap["date"] = rival.date
                    newMap["id"] = rival.id
                    
                    sendArray.append(newMap)
                }
                ref.child("tempRivals").setValue(sendArray)
                
                var rivals = [RivalObj]()
                if(snapshot.hasChild("acceptedTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "acceptedTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        rivals.append(request)
                    }
                }
                
                let newRival = RivalObj(gamerTag: tag, date: rival.date, game: rival.game, uid: currentUser!.uId, type: rival.type, id: self.createTempId())
                rivals.append(newRival)
                    
                var sendList = [[String: Any]]()
                for rival in rivals{
                    let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "id": rival.id] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("acceptedTempRivals").setValue(sendList)
                
                self.updateAcceptRejectCurrentUser(rival: rival, callbacks: callbacks, accepted: true)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.rivalResponseFailed()
        }
    }
    
    func rejectPlayRequest(rival: RivalObj, callbacks: RequestsUpdate){
        //update other user
        let ref = Database.database().reference().child("Users").child(rival.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = delegate.currentUser
                let tag = currentUser!.gamerTag
                
                var rivals = [RivalObj]()
                if(snapshot.hasChild("rejectedTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "rejectedTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        rivals.append(request)
                    }
                }
                
                var tempRivals = [RivalObj]()
                if(snapshot.hasChild("tempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "tempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        tempRivals.append(request)
                    }
                }
                
                for tempRival in tempRivals{
                    if(tempRival.id == rival.id){
                        tempRivals.remove(at: tempRivals.index(of: tempRival)!)
                    }
                }
                
                var sendArray = [[String: String]]()
                for rival in tempRivals{
                    var newMap = [String: String]()
                    newMap["gamerTag"] = rival.gamerTag
                    newMap["game"] = rival.game
                    newMap["uid"] = rival.uid
                    newMap["type"] = rival.type
                    newMap["date"] = rival.date
                    newMap["id"] = rival.id
                    
                    sendArray.append(newMap)
                }
                ref.child("tempRivals").setValue(sendArray)
                
                let newRival = RivalObj(gamerTag: tag, date: rival.date, game: rival.game, uid: currentUser!.uId, type: rival.type, id: self.createTempId())
                rivals.append(newRival)
                    
                var sendList = [[String: Any]]()
                for rival in rivals{
                    let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "id": rival.id] as [String : String]
                    sendList.append(current)
                }
                
                ref.child("rejectedTempRivals").setValue(sendList)
                
                self.updateAcceptRejectCurrentUser(rival: rival, callbacks: callbacks, accepted: false)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.rivalResponseFailed()
        }
    }
    
    private func updateAcceptRejectCurrentUser(rival: RivalObj, callbacks: RequestsUpdate, accepted: Bool){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var currentTempRivals = [RivalObj]()
                if(snapshot.hasChild("currentTempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "currentTempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        currentTempRivals.append(request)
                    }
                }
                
                for tempRival in currentTempRivals{
                    if(tempRival.uid == rival.uid){
                        currentTempRivals.remove(at: currentTempRivals.index(of: tempRival)!)
                    }
                }
                
                delegate.currentUser!.tempRivals = currentTempRivals
                
                var sendArray = [[String: String]]()
                for rival in currentTempRivals{
                    var newMap = [String: String]()
                    newMap["gamerTag"] = rival.gamerTag
                    newMap["game"] = rival.game
                    newMap["uid"] = rival.uid
                    newMap["type"] = rival.type
                    newMap["date"] = rival.date
                    newMap["id"] = rival.id
                    
                    sendArray.append(newMap)
                }
                ref.child("currentTempRivals").setValue(sendArray)
                
                
                var tempRivals = [RivalObj]()
                if(snapshot.hasChild("tempRivals")){
                    let pendingArray = snapshot.childSnapshot(forPath: "tempRivals")
                    for rival in pendingArray.children{
                        let currentObj = rival as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let date = dict?["date"] as? String ?? ""
                        let tag = dict?["gamerTag"] as? String ?? ""
                        let game = dict?["game"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        let dbType = dict?["type"] as? String ?? ""
                        let id = dict?["id"] as? String ?? ""
                        
                        let request = RivalObj(gamerTag: tag, date: date, game: game, uid: uid, type: dbType, id: id)
                        tempRivals.append(request)
                    }
                }
                
                for tempRival in tempRivals{
                    if(tempRival.uid == rival.uid){
                        tempRivals.remove(at: tempRivals.index(of: tempRival)!)
                    }
                }
                
                var sendList = [[String: Any]]()
                for rival in tempRivals {
                    let current = ["gamerTag": rival.gamerTag, "date": rival.date, "uid": rival.uid, "game": rival.game, "id": rival.id] as [String : String]
                    sendList.append(current)
                }
                
                if(!sendList.isEmpty){
                    ref.child("tempRivals").setValue(sendList)
                } else {
                    ref.child("tempRivals").removeValue()
                }
                
                if(accepted){
                    callbacks.rivalResponseAccepted()
                }
                else{
                    callbacks.rivalResponseRejected()
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.rivalResponseFailed()
        }
    }
    
    func removeFriend(otherUser: User, callbacks: RequestsUpdate ){
        //removed CURRENT user from OTHER user
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let otherUserSnapshot = snapshot.childSnapshot(forPath: otherUser.uId)
            if(otherUserSnapshot.exists()){
                if(otherUserSnapshot.hasChild("friends")){
                    let friendsList = otherUserSnapshot.childSnapshot(forPath: "friends")
                    for friend in friendsList.children {
                        if((friend as! DataSnapshot).hasChild("uid")){
                            let dbUid = (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? ""
                            if(dbUid == currentUser.uId){
                                ref.child(otherUser.uId).child("friends").child((friend as! DataSnapshot).key).removeValue()
                                break
                            }
                        }
                    }
                }
            }
            
            let currentUserSnapshot = snapshot.childSnapshot(forPath: currentUser.uId)
            if(currentUserSnapshot.exists()){
                if(currentUserSnapshot.hasChild("friends")){
                    let friendsList = currentUserSnapshot.childSnapshot(forPath: "friends")
                    for friend in friendsList.children {
                        if((friend as! DataSnapshot).hasChild("uid")){
                            let dbUid = (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? ""
                            if(dbUid == otherUser.uId){
                                ref.child(currentUser.uId).child("friends").child((friend as! DataSnapshot).key).removeValue()
                                break
                            }
                        }
                    }
                }
            }
            
            callbacks.friendRemoved()
            
        }) { (error) in
            print(error.localizedDescription)
            callbacks.friendRemoveFail()
        }
    }
    
    func clearAllAnnouncements(callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("receivedAnnouncements")){
                    ref.child("receivedAnnouncements").removeValue()
                }
                if(snapshot.hasChild("acceptedTempRivals")){
                    ref.child("acceptedTempRivals").removeValue()
                }
                if(snapshot.hasChild("rejectedTempRivals")){
                    ref.child("rejectedTempRivals").removeValue()
                }
                
                delegate.currentUser!.acceptedTempRivals = [RivalObj]()
                delegate.currentUser!.rejectedTempRivals = [RivalObj]()
                delegate.currentUser!.receivedAnnouncements = [String]()
                callbacks.onSuccess()
            }
        })
    }
    
    func cleanReceivedOnlineAnnouncements(announcementUid: String, callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("receivedAnnouncements")){
                    var receivedAnnouncements = snapshot.childSnapshot(forPath: "receivedAnnouncements").value as? [String] ?? [String]()
                    if(receivedAnnouncements.contains(announcementUid)){
                        receivedAnnouncements.remove(at: receivedAnnouncements.index(of: announcementUid)!)
                    }
                    
                    ref.child("receivedAnnouncements").setValue(receivedAnnouncements)
                    delegate.currentUser!.receivedAnnouncements = receivedAnnouncements
                    callbacks.onSuccess()
                }
            }
        })
    }
    
    func cleanRivals(rivalId: String, callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("acceptedTempRivals")){
                    let acceptedRivals = snapshot.childSnapshot(forPath: "acceptedTempRivals")
                    for rival in acceptedRivals.children {
                        let current = (rival as! DataSnapshot)
                        if(current.hasChild("id")){
                            let currentId = current.childSnapshot(forPath: "id").value as? String ?? ""
                            if(rivalId == currentId){
                                ref.child("acceptedTempRivals").child(current.key).removeValue()
                                
                                for rival in currentUser.acceptedTempRivals {
                                    if(rival.id == rivalId){
                                        delegate.currentUser!.acceptedTempRivals.remove(at: delegate.currentUser!.acceptedTempRivals.index(of: rival)!)
                                        break
                                    }
                                }
                            }
                            callbacks.onSuccess()
                        }
                    }
                }
                
                if(snapshot.hasChild("rejectedTempRivals")){
                    let acceptedRivals = snapshot.childSnapshot(forPath: "rejectedTempRivals")
                    for rival in acceptedRivals.children {
                        let current = (rival as! DataSnapshot)
                        if(current.hasChild("id")){
                            let currentId = current.childSnapshot(forPath: "id").value as? String ?? ""
                            if(rivalId == currentId){
                                ref.child("rejectedTempRivals").child(current.key).removeValue()
                                
                                for rival in currentUser.rejectedTempRivals {
                                    if(rival.id == rivalId){
                                        delegate.currentUser!.rejectedTempRivals.remove(at: delegate.currentUser!.rejectedTempRivals.index(of: rival)!)
                                        break
                                    }
                                }
                            }
                        }
                        callbacks.onSuccess()
                    }
                }
            }
        })
    }
    
    func cleanFollowers(uid: String, callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("followerAnnouncements")){
                    let announcements = snapshot.childSnapshot(forPath: "followerAnnouncements")
                    for follower in announcements.children {
                        let current = (follower as! DataSnapshot)
                        if(current.hasChild("uid")){
                            let currentId = current.childSnapshot(forPath: "uid").value as? String ?? ""
                            if(uid == currentId){
                                ref.child("followerAnnouncements").child(current.key).removeValue()
                                
                                for followerObj in currentUser.followerAnnouncements {
                                    if(followerObj.uid == uid){
                                        delegate.currentUser!.followerAnnouncements.remove(at: delegate.currentUser!.followerAnnouncements.index(of: followerObj)!)
                                        break
                                    }
                                }
                            }
                            callbacks.onSuccess()
                        }
                    }
                }
            }
        })
    }
    
    func userListHasUid(list: [User], uid: String) -> Bool {
        var contained = false
        for user in list {
            if(user.uId == uid){
                contained = true
                break
            }
        }
        return contained
    }
    
    func userListHasGamerTag(list: [User], gamertag: String) -> Bool {
        var contained = false
        for user in list {
            if(user.gamerTag == gamertag){
                contained = true
                break
            }
        }
        return contained
    }
    
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: str)!
    }
    
    func checkOnlineAnnouncements(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("onlineAnnouncements")){
                let announcements = snapshot.childSnapshot(forPath: "onlineAnnouncements")
                for online in announcements.children
                {
                    let current = (online as? DataSnapshot)
                    if(current != nil){
                        if(current!.hasChild("date")){
                            let date = current!.childSnapshot(forPath: "date").value as? String ?? ""
                            let dbDate = self.stringToDate(date)
                            
                            if(dbDate != nil){
                                let now = NSDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat="MM-dd-yyyy HH:mm zzz"
                                formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                                let future = formatter.string(from: dbDate as Date)
                                let dbTimeOut = self.stringToDate(future).addingTimeInterval(20.0 * 60.0)
                                
                                let validAnnounments = (now as Date).compare(.isEarlier(than: dbTimeOut))
                                
                                if(dbTimeOut != nil){
                                    if(!validAnnounments){
                                        let ref = Database.database().reference().child("Users").child(currentUser.uId)
                                        ref.child("onlineAnnouncements").removeValue()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func followUser(otherUserId: String, otherUserTag: String, currentUser: User, callbacks: RequestsUpdate){
        //add current user to other user's followers first.
        let ref = Database.database().reference().child("Users").child(otherUserId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("followers")){
                var friends = [String: FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "followers").children{
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == currentUser.uId){
                        contained = true
                        break
                    } else {
                        friends[newFriend.uid] = newFriend
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    friends[currentUser.uId] = FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)
                    
                    var sendList = [[String: Any]]()
                    for teammate in friends {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("followers").setValue(sendList)
                }
                
                if(snapshot.hasChild("followerAnnouncements")){
                    var followers = [String: FriendObject]()
                    var contained = false
                    for friend in snapshot.childSnapshot(forPath: "followerAnnouncements").children{
                        let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                        
                        if(newFriend.uid == currentUser.uId){
                            contained = true
                            break
                        } else {
                            followers[newFriend.uid] = newFriend
                        }
                    }
                    
                    if(!contained){
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM-dd-yyyy"
                        let now = Date()
                        let dateString = formatter.string(from:now)
                        followers[currentUser.uId] = FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)
                        
                        var sendList = [[String: Any]]()
                        for teammate in followers {
                            let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                            sendList.append(current)
                        }
                        ref.child("followerAnnouncements").setValue(sendList)
                    }
                    self.finishFollowing(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    let followers = [currentUser.uId: FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)]
                    var sendList = [[String: Any]]()
                    for teammate in followers {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("followerAnnouncements").setValue(sendList)
                    self.finishFollowing(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let followers = [currentUser.uId: FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)]
                var sendList = [[String: Any]]()
                for teammate in followers {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("followers").setValue(sendList)
                
                if(snapshot.hasChild("followerAnnouncements")){
                    var followers = [String: FriendObject]()
                    var contained = false
                    for friend in snapshot.childSnapshot(forPath: "followerAnnouncements").children{
                        let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                        
                        if(newFriend.uid == currentUser.uId){
                            contained = true
                            break
                        } else {
                            followers[newFriend.uid] = newFriend
                        }
                    }
                    
                    if(!contained){
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM-dd-yyyy"
                        let now = Date()
                        let dateString = formatter.string(from:now)
                        followers[currentUser.uId] = FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)
                        
                        var sendList = [[String: Any]]()
                        for teammate in followers {
                            let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                            sendList.append(current)
                        }
                        ref.child("followerAnnouncements").setValue(sendList)
                    }
                    self.finishFollowing(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    let followers = [currentUser.uId: FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)]
                    var sendList = [[String: Any]]()
                    for teammate in followers {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("followerAnnouncements").setValue(sendList)
                    self.finishFollowing(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
                }
            }
        })
    }
    
    func finishFollowing(otherUserId: String, otherUserTag: String, currentUser: User, callbacks: RequestsUpdate){
        //finish by editing the current user's following
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("following")){
                var following = [String: FriendObject]()
                var simpleFollowingList = [FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "following").children {
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == currentUser.uId){
                        contained = true
                        break
                    } else {
                        following[newFriend.uid] = newFriend
                        simpleFollowingList.append(newFriend)
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    following[currentUser.uId] = FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)
                    simpleFollowingList.append(FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId))
                    
                    var sendList = [[String: Any]]()
                    for teammate in following {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("following").setValue(sendList)
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser!
                    currentUser.following = simpleFollowingList
                    callbacks.onFollowSuccess()
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let following = [currentUser.uId: FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)]
                var sendList = [[String: Any]]()
                for teammate in following {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("following").setValue(sendList)
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                currentUser.following = [FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)]
                
                callbacks.onFollowSuccess()
            }
        })
    }
    
    
    
    func followBack(otherUserId: String, otherUserTag: String, currentUser: User, callbacks: RequestsUpdate){
        //add current user to other user's followers first.
        let ref = Database.database().reference().child("Users").child(otherUserId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("followers")){
                var friends = [String: FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "followers").children {
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == currentUser.uId){
                        contained = true
                        break
                    } else {
                        friends[newFriend.uid] = newFriend
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    friends[currentUser.uId] = FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)
                    
                    var sendList = [[String: Any]]()
                    for teammate in friends {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("followers").setValue(sendList)
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let followers = [currentUser.uId: FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)]
                var sendList = [[String: Any]]()
                for teammate in followers {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("followers").setValue(sendList)
            }
            
            
            if(snapshot.hasChild("friends")){
                var friends = [String: FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "friends").children {
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == currentUser.uId){
                        contained = true
                        break
                    } else {
                        friends[newFriend.uid] = newFriend
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    friends[currentUser.uId] = FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)
                    
                    var sendList = [[String: Any]]()
                    for teammate in friends {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("friends").setValue(sendList)
                    self.finishFollowBack(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let followers = [currentUser.uId: FriendObject(gamerTag: currentUser.gamerTag, date: dateString, uid: currentUser.uId)]
                var sendList = [[String: Any]]()
                for teammate in followers {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("friends").setValue(sendList)
                self.finishFollowBack(otherUserId: otherUserId, otherUserTag: otherUserTag, currentUser: currentUser, callbacks: callbacks)
            }
            
        })
    }
    
    private func finishFollowBack(otherUserId: String, otherUserTag: String, currentUser: User, callbacks: RequestsUpdate){
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("following")){
                var following = [String: FriendObject]()
                var simpleFollowingList = [FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "following").children {
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == currentUser.uId){
                        contained = true
                        break
                    } else {
                        following[newFriend.uid] = newFriend
                        simpleFollowingList.append(newFriend)
                    }
                }
                
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    following[currentUser.uId] = FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)
                    simpleFollowingList.append(FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId))
                    
                    var sendList = [[String: Any]]()
                    for teammate in following {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("following").setValue(sendList)
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser!
                    currentUser.following = simpleFollowingList
                    callbacks.onFollowSuccess()
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let following = [currentUser.uId: FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)]
                var sendList = [[String: Any]]()
                for teammate in following {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("following").setValue(sendList)
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                currentUser.following = [FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)]
            }
            if(snapshot.hasChild("friends")){
                var friends = [String: FriendObject]()
                var simpleFriendsList = [FriendObject]()
                var contained = false
                for friend in snapshot.childSnapshot(forPath: "friends").children {
                    let newFriend = FriendObject(gamerTag: (friend as! DataSnapshot).childSnapshot(forPath: "gamerTag").value as? String ?? "", date: (friend as! DataSnapshot).childSnapshot(forPath: "date").value as? String ?? "", uid: (friend as! DataSnapshot).childSnapshot(forPath: "uid").value as? String ?? "")
                    
                    if(newFriend.uid == otherUserId){
                        contained = true
                        break
                    } else {
                        friends[newFriend.uid] = newFriend
                        simpleFriendsList.append(newFriend)
                    }
                }
                if(!contained){
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    let now = Date()
                    let dateString = formatter.string(from:now)
                    simpleFriendsList.append(FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId))
                    friends[currentUser.uId] = FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)
                    
                    var sendList = [[String: Any]]()
                    for teammate in friends {
                        let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                        sendList.append(current)
                    }
                    ref.child("friends").setValue(sendList)
                    callbacks.onFollowBackSuccess()
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                currentUser.friends = simpleFriendsList
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                let now = Date()
                let dateString = formatter.string(from:now)
                let followers = [currentUser.uId: FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId)]
                var sendList = [[String: Any]]()
                for teammate in followers {
                    let current = ["gamerTag": teammate.value.gamerTag, "date": teammate.value.date, "uid": teammate.value.uid] as [String : String]
                    sendList.append(current)
                }
                ref.child("friends").setValue(sendList)
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser!
                currentUser.friends.append(FriendObject(gamerTag: otherUserTag, date: dateString, uid: otherUserId))
                callbacks.onFollowBackSuccess()
            }
        })
    }
}

extension Date {
var millisecondsSince1970:Int64 {
       return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
       //RESOLVED CRASH HERE
   }
    
    
}
