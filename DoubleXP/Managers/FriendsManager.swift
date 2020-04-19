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
        
        var otherUserTags = [String]()
        for tag in user.gamerTags{
            otherUserTags.append(tag.gamerTag)
        }
        
        for friend in currentUser.friends{
            if(otherUserTags.contains(friend.gamerTag)){
                contained = true
                break
            }
        }
        
        return contained
    }
    
    
    func sendRequestFromProfile(currentUser: User, otherUser: User, callbacks: ProfileCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let pendingFriendsArray = currentUser!.pendingRequests
        let sentFriends = currentUser!.sentRequests
        
        if(!checkListsForUser(user: otherUser, currentUser: currentUser!)){
            //first, add the current user to the OTHER users requests.
            let pendingRef = Database.database().reference().child("Users").child(otherUser.uId).child("pending_friends")
            
            var pendingArray = [FriendRequestObject]()
            
            let manager = GamerProfileManager()
            
            if(!pendingFriendsArray.isEmpty){
                pendingArray.append(contentsOf: pendingFriendsArray)
            }
            
           let formatter = DateFormatter()
            //2016-12-08 03:37:22 +0000
            //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.dateFormat = "MM-dd-yyyy"
            let now = Date()
            let dateString = formatter.string(from:now)
            
            //gamerTag is the currentUsers gamertag, the one making the request.
            let otherUserfriendRequest = FriendRequestObject(gamerTag: manager.getGamerTag(user: currentUser!), date: dateString, uid: currentUser!.uId)
            
            pendingArray.append(otherUserfriendRequest)
            
            var pendingSendList = [[String: Any]]()
            for friend in pendingArray{
                let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                pendingSendList.append(current)
            }
            pendingRef.setValue(pendingSendList)
            
            
            let sendingRef = Database.database().reference().child("Users").child(currentUser!.uId).child("sent_requests")
            var sendingArray = [FriendRequestObject]()
            
            if(!sentFriends.isEmpty){
                sendingArray.append(contentsOf: sentFriends)
            }
            
            let currentUserSentRequest = FriendRequestObject(gamerTag: manager.getGamerTag(user: otherUser), date: dateString, uid: otherUser.uId)
            sendingArray.append(currentUserSentRequest)
            
            var sendList = [[String: Any]]()
            for friend in sendingArray{
                let current = ["gamerTag": friend.gamerTag, "date": friend.date, "uid": friend.uid] as [String : String]
                sendList.append(current)
            }
            sendingRef.setValue(sendList)
            
            self.updateLists(user: currentUser!, callbacks: callbacks)
        }
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
                            if(request.uid == otherUserRequest.uid){
                                pendingRequests.remove(at: pendingRequests.index(of: request)!)
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
                let manager = GamerProfileManager()
                
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
                    let sentRequests = value?["sent_requests"] as? [String] ?? [String]()
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
                        user.sentRequests = sentArray
                    }
                }
                else{
                    var sentRequests = [FriendRequestObject]()
                    
                    let friendsArray = snapshot.childSnapshot(forPath: "sent_requests")
                    for friend in friendsArray.children{
                        let currentObj = friend as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let gamerTag = dict?["gamerTag"] as? String ?? ""
                        let date = dict?["date"] as? String ?? ""
                        let uid = dict?["uid"] as? String ?? ""
                        
                        let newFriend = FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid)
                        sentRequests.append(newFriend)
                    }
                    
                    user.sentRequests = sentRequests
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
        
        var otherUserTags = [String]()
        for tag in user.gamerTags{
            otherUserTags.append(tag.gamerTag)
        }
        
        for friend in currentUser.friends{
            if(otherUserTags.contains(friend.gamerTag)){
                contained = true
                break
            }
        }
        
        return contained
    }
    
    func acceptFriendFromRequests(position: IndexPath, otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
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
                
                self.updateCurrentUser(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks, position: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUser(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate, position: IndexPath){
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
                
                callbacks.updateCell(indexPath: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func declineRequest(position: IndexPath, otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate){
        
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
                
                
                self.updateCurrentUserRemove(otherUserRequest: otherUserRequest, currentUserUid: currentUserUid, callbacks: callbacks, position: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func updateCurrentUserRemove(otherUserRequest: FriendRequestObject, currentUserUid: String, callbacks: RequestsUpdate, position: IndexPath){
        
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
                
                callbacks.updateCell(indexPath: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}
