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
    
    
    func sendRequestFromProfile(currentUser: User, otherUser: User){
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
            
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM.dd.yyyy"
            let result = formatter.string(from: date)
            
            //gamerTag is the currentUsers gamertag, the one making the request.
            let otherUserfriendRequest = FriendRequestObject(gamerTag: manager.getGamerTag(user: currentUser!), date: result, uid: currentUser!.uId)
            
            pendingArray.append(otherUserfriendRequest)
            pendingRef.setValue(pendingArray)
            
            
            
            let sendingRef = Database.database().reference().child("Users").child(currentUser!.uId).child("sent_requests")
            var sendingArray = [FriendRequestObject]()
            
            if(!sentFriends.isEmpty){
                sendingArray.append(contentsOf: sentFriends)
            }
            
            let currentUserSentRequest = FriendRequestObject(gamerTag: manager.getGamerTag(user: otherUser), date: result, uid: otherUser.uId)
            sendingArray.append(currentUserSentRequest)
            sendingRef.setValue(sendingArray)
            
            self.updateLists(user: currentUser!)
        }
    }
    
    private func updateLists(user: User){
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
                            let date = Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMMM.dd.yyyy"
                            let result = formatter.string(from: date)
                            
                            let fixedRequest = FriendRequestObject(gamerTag: request, date: result, uid: user.uId)
                            
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
                        let dict = currentObj.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
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
                    let dict = currentObj.value as! [String: Any]
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let date = dict["date"] as? String ?? ""
                    let uid = dict["uid"] as? String ?? ""
                    
                    let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                    friends.append(newFriend)
                }
                user.friends = friends
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func checkListsForUser(user: User, currentUser: User) -> Bool{
        var contained = false
        
        for request in currentUser.pendingRequests{
            if(request.uid == currentUser.uId){
                contained = true
                return contained
            }
        }
        
        for request in currentUser.sentRequests{
            if(request.uid == currentUser.uId){
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
                        let dict = currentObj.value as! [String: Any]
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let date = dict["date"] as? String ?? ""
                        let uid = dict["uid"] as? String ?? ""
                        
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
                    
                    ref.child("pending_friends").setValue(pendingRequests)
                    currentUser!.pendingRequests = pendingRequests
                }
                
                //Next, let's add the current user to the OTHER user's friends.
                //var friends = value?["friends"] as? [String] ?? [String]()
                let currentFriends = value?["friends"] as? NSDictionary
                var friends = [String: FriendObject]()
                
                for friend in currentFriends!{
                    let dict = friend.value as! [String: String]
                    let newFriend = FriendObject(gamerTag: dict["gamerTag"]!, date: dict["date"]!, uid: dict["uId"]!)
                    
                    friends[newFriend.uid] = newFriend
                }
                
                var contained = false
                for friend in friends{
                    if(friend.key == currentUser!.uId){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM.dd.yyyy"
                    let result = formatter.string(from: date)
                    
                    let newFriend = FriendObject(gamerTag: manager.getGamerTag(user: currentUser!), date: result, uid: currentUser!.uId)
                    
                    friends[currentUser!.uId] = newFriend
                }
                
                ref.child("friends").setValue(friends)
                
                
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
                let delegate = UIApplication.shared.delegate as! AppDelegate!
                let currentUser = delegate?.currentUser
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
                
                ref.child("sent_requests").setValue(sentRequests)
                currentUser!.sentRequests = sentRequests
                
                
                //Next, let's add the other user to the CURRENT user's friends.
                let currentFriends = value?["friends"] as? NSDictionary
                var friends = [String: FriendObject]()
                
                for friend in currentFriends!{
                    let dict = friend.value as! [String: String]
                    let newFriend = FriendObject(gamerTag: dict["gamerTag"]!, date: dict["date"]!, uid: dict["uId"]!)
                    
                    friends[newFriend.uid] = newFriend
                }
                
                var contained = false
                for friend in friends{
                    if(friend.key == currentUser!.uId){
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM.dd.yyyy"
                    let result = formatter.string(from: date)
                    
                    let newFriend = FriendObject(gamerTag: manager.getGamerTag(user: currentUser!), date: result, uid: currentUser!.uId)
                    
                    friends[currentUser!.uId] = newFriend
                    
                    ref.child("friends").setValue(friends)
                }
                
                ref.child("friends").setValue(friends)
                
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
        let ref = Database.database().reference().child("Users").child(otherUserRequest.uid)
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
                    var pendingRequests = value?["pending_friends"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                    
                    if(!pendingRequests.isEmpty){
                        for request in pendingRequests{
                            if(request.uid == currentUserUid){
                                pendingRequests = pendingRequests.filter { $0 != request}
                                break
                            }
                        }
                    }
                    
                    ref.child("pending_friends").setValue(pendingRequests)
                    currentUser!.pendingRequests = pendingRequests
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
                
                ref.child("sent_requests").setValue(sentRequests)
                currentUser!.sentRequests = sentRequests
                
                callbacks.updateCell(indexPath: position)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}
