//
//  SearchManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseDatabase
import GeoFire

class SearchManager {
    var ageFilters = [String]()
    var langaugeFilters = [String]()
    var advancedFilters = [[String: String]]() //question : answer
    var returnedUsers = [User]()
    var currentGameSearch = ""
    var currentUser: User!
    var currentSelectedConsoles = [String]()
    var questionMatches = [String]()
    var timezoneFilter = false
    var locationFilter = "none"
    
    func resetFilters(){
        timezoneFilter = false
        locationFilter = "none"
        langaugeFilters = [String]()
        advancedFilters = [[String: String]]()
        questionMatches = [String]()
        ageFilters = [String]()
    }
    
    func searchWithLocation(callbacks: SearchManagerCallbacks){
        if(locationFilter == "none" || locationFilter == "timezone"){
            self.searchWithFilters(callbacks: callbacks)
            return
        }
        let center = CLLocation(latitude: currentUser.userLat, longitude: currentUser.userLong)
        
        let geofireRef = Database.database().reference().child("geofire")
        let geoFire = GeoFire(firebaseRef: geofireRef)
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        var ids = [String]()
        let query = geoFire.query(at: center, withRadius: convertLocation(filter: locationFilter))
        query.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            ids.append(key)
        })
        query.observeReady {
            query.removeAllObservers()
            self.loadUsers(list: ids, callbacks: callbacks)
        }
    }
    
    private func convertLocation(filter: String) -> Double {
        if(locationFilter == "fifty_miles"){
            return 80.4672
        } else if(locationFilter == "hundred_miles"){
            return 160.934
        } else {
            return 1609.34
        }
    }
    
    private func loadUsers(list: [String]?, callbacks: SearchManagerCallbacks){
        if(list != nil){
            var newList = [String]()
            newList.append(contentsOf: list!)
            newList.shuffle()
            self.loadListUser(uid: list![0], currentList: newList, callbacks: callbacks)
        } else {
            callbacks.onFailure()
        }
    }
    
    private func loadListUser(uid: String, currentList: [String]?, callbacks: SearchManagerCallbacks){
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for uid in currentList! {
                if(!snapshot.hasChild(uid)){
                    continue
                }
                let value = snapshot.childSnapshot(forPath: uid).value as? NSDictionary
                if(snapshot.childSnapshot(forPath: uid).hasChild("games") && snapshot.childSnapshot(forPath: uid).hasChild("gamerTags")){
                    var currentArray = [String]()
                    currentArray.append(contentsOf: currentList!)
                    
                    var gamerTags = [GamerProfile]()
                    let gamerTagsArray = snapshot.childSnapshot(forPath: uid).childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        
                        if(currentTag != "" && currentGame != "" && console != ""){
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                    }
                    
                    var containedProfile = false
                    var gamerTag = ""
                    for tag in gamerTags {
                        if(!tag.gamerTag.isEmpty){
                            if(tag.game == self.currentGameSearch){
                                if(self.currentSelectedConsoles.contains(tag.console)){
                                    containedProfile = true
                                    gamerTag = tag.gamerTag
                                    break
                                }
                            }
                        }
                    }
                    
                    if(containedProfile){
                        //basic filters
                        let ageFiltersAvailable = !self.ageFilters.isEmpty // if not empty, we have something to look at.
                        var ageMatch = self.ageFilters.isEmpty //if false, then we need to look and update.
                        if(ageFiltersAvailable){
                            let selectedAge = value?["selectedAge"] as? String ?? ""
                            for filter in self.ageFilters {
                                if(selectedAge == filter){
                                    ageMatch = true
                                }
                            }
                        }
                        
                        let languageFiltersAvailable = !self.langaugeFilters.isEmpty
                        var languageMatch = self.langaugeFilters.isEmpty
                        if(languageFiltersAvailable){
                            let primary = value?["primaryLanguage"] as? String ?? ""
                            for language in self.langaugeFilters {
                                if(language == primary){
                                    languageMatch = true
                                }
                            }
                            if(!languageMatch){
                                let secondary = value?["secondaryLanguage"] as? String ?? ""
                                for language in self.langaugeFilters {
                                    if(language == secondary){
                                        languageMatch = true
                                    }
                                }
                            }
                        }
                        
                        let advancedFiltersAvailable = !self.advancedFilters.isEmpty
                        var advancedMatch = self.advancedFilters.isEmpty
                        if(advancedFiltersAvailable){
                            if(snapshot.childSnapshot(forPath: uid).hasChild("gamerTags")){
                                let gamerTagsArray = snapshot.childSnapshot(forPath: uid).childSnapshot(forPath: "gamerTags")
                                for gamerTagObj in gamerTagsArray.children {
                                    if((gamerTagObj as! DataSnapshot).hasChild("filterQuestions")){
                                        let list = (gamerTagObj as! DataSnapshot).childSnapshot(forPath: "filterQuestions")
                                        for filter in self.advancedFilters{
                                            let filterKey = Array(filter.keys)[0]
                                            for filterQuestion in list.children {
                                                let hadToDefineItToMakeItWork = filterQuestion as! DataSnapshot
                                                let question = hadToDefineItToMakeItWork.key
                                                if(filterKey == hadToDefineItToMakeItWork.key){
                                                    let thisValue = hadToDefineItToMakeItWork.value as? [String] ?? [""]
                                                    if(thisValue.contains((filter[filterKey]) ?? "")){
                                                        advancedMatch = true
                                                        self.questionMatches.append(filterKey)
                                                        break
                                                    } else {
                                                        if(!self.questionMatches.contains(filterKey)){
                                                            advancedMatch = false
                                                        }
                                                        break
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let timezoneSearch = (self.locationFilter == "timezone")
                        var currentTimezone = ""
                        var timezoneMatch = true
                        if(timezoneSearch){
                            if(snapshot.childSnapshot(forPath: uid).hasChild("timezone")){
                                currentTimezone = snapshot.childSnapshot(forPath: uid).childSnapshot(forPath: "timezone").value as? String ?? ""
                                timezoneMatch = currentTimezone == delegate.currentUser!.timezone
                            } else {
                                timezoneMatch = false
                            }
                        }
                        
                        if(ageMatch && languageMatch && advancedMatch && timezoneMatch){
                            let uId = snapshot.childSnapshot(forPath: uid).key
                            let bio = value?["bio"] as? String ?? ""
                            let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                            
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
                            
                            let games = value?["games"] as? [String] ?? [String]()
                            var gamerTags = [GamerProfile]()
                            let gamerTagsArray = snapshot.childSnapshot(forPath: uid).childSnapshot(forPath: "gamerTags")
                            for gamerTagObj in gamerTagsArray.children {
                                let currentObj = gamerTagObj as! DataSnapshot
                                let dict = currentObj.value as? [String: Any]
                                let currentTag = dict?["gamerTag"] as? String ?? ""
                                let currentGame = dict?["game"] as? String ?? ""
                                let console = dict?["console"] as? String ?? ""
                                let quizTaken = dict?["quizTaken"] as? String ?? ""
                                
                                let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                                gamerTags.append(currentGamerTagObj)
                            }
                            
                            let consoleArray = snapshot.childSnapshot(forPath: uid).childSnapshot(forPath: "consoles")
                            let dict = consoleArray.value as? [String: Bool]
                            let nintendo = dict?["nintendo"] ?? false
                            let ps = dict?["ps"] ?? false
                            let xbox = dict?["xbox"] ?? false
                            let pc = dict?["pc"] ?? false
                            
                            let returnedUser = User(uId: uId)
                            returnedUser.gamerTags = gamerTags
                            returnedUser.games = games
                            returnedUser.friends = friends
                            returnedUser.sentRequests = sentRequests
                            returnedUser.gamerTag = gamerTag
                            returnedUser.pc = pc
                            returnedUser.ps = ps
                            returnedUser.xbox = xbox
                            returnedUser.nintendo = nintendo
                            returnedUser.bio = bio
                            
                            //if the returned user plays the game being searched AND the returned users gamertag
                            //does not equal the current users gamertag, then add to list.
                            let manager = FriendsManager()
                            if(self.currentUser.uId != returnedUser.uId &&
                                !manager.isInFriendList(user: returnedUser, currentUser: self.currentUser) &&
                                !manager.isBlocked(user: returnedUser, currentUser: self.currentUser)){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                        }
                    }
                }
            }
            callbacks.onSuccess(returnedUsers: self.returnedUsers)
        })
    }
    
    func searchWithFilters(callbacks: SearchManagerCallbacks){
        self.returnedUsers = [User]()
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                
                let search = value?["search"] as? String ?? "true"
                var gamerTags = [GamerProfile]()
                if((user as! DataSnapshot).hasChild("gamerTags")){
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        
                        if(currentTag != "" && currentGame != "" && console != ""){
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                    }
                }
                
                var containedProfile = false
                var gamerTag = ""
                for tag in gamerTags {
                    if(!tag.gamerTag.isEmpty){
                        if(tag.game == self.currentGameSearch){
                            if(self.currentSelectedConsoles.contains(tag.console)){
                                containedProfile = true
                                gamerTag = tag.gamerTag
                                break
                            }
                        }
                    }
                }
                if(!containedProfile){
                    //legacy users
                    let games = value?["games"] as? [String] ?? [String]()
                    if(games.contains(self.currentGameSearch)){
                        let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                        let dict = consoleArray.value as? [String: Bool]
                        let nintendo = dict?["nintendo"] ?? false
                        let ps = dict?["ps"] ?? false
                        let xbox = dict?["xbox"] ?? false
                        let pc = dict?["pc"] ?? false
                        let mobile = dict?["mobile"] ?? false
                        
                        if(self.currentSelectedConsoles.contains("ps") && ps){
                            containedProfile = true
                        } else if(self.currentSelectedConsoles.contains("xbox") && xbox){
                            containedProfile = true
                        } else if(self.currentSelectedConsoles.contains("pc") && pc){
                            containedProfile = true
                        } else if(self.currentSelectedConsoles.contains("nintendo") && nintendo){
                            containedProfile = true
                        } else if(self.currentSelectedConsoles.contains("mobile") && mobile){
                            containedProfile = true
                        }
                    }
                }
                
                //make users that did not enter a gamertag are not searchable BARE MINIMUM
                if(search == "true" && containedProfile && !gamerTag.isEmpty){
                    //basic filters
                    let ageFiltersAvailable = !self.ageFilters.isEmpty // if not empty, we have something to look at.
                    var ageMatch = self.ageFilters.isEmpty //if false, then we need to look and update.
                    if(ageFiltersAvailable){
                        let selectedAge = value?["selectedAge"] as? String ?? ""
                        if(self.ageFilters.contains(selectedAge)){
                            ageMatch = true
                        }
                    }
                    
                    let languageFiltersAvailable = !self.langaugeFilters.isEmpty
                    var languageMatch = self.langaugeFilters.isEmpty
                    if(languageFiltersAvailable){
                        let primary = value?["primaryLanguage"] as? String ?? ""
                        if(self.langaugeFilters.contains(primary)){
                            languageMatch = true
                        }
                        if(!languageMatch){
                            let secondary = value?["secondaryLanguage"] as? String ?? ""
                            if(self.langaugeFilters.contains(secondary)){
                                languageMatch = true
                            }
                        }
                    }
                    
                    let advancedFiltersAvailable = !self.advancedFilters.isEmpty
                    var advancedMatch = self.advancedFilters.isEmpty
                    if(advancedFiltersAvailable){
                        if((user as! DataSnapshot).hasChild("gamerTags")){
                            let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                            for gamerTagObj in gamerTagsArray.children {
                                if((gamerTagObj as! DataSnapshot).hasChild("filterQuestions")){
                                    let list = (gamerTagObj as! DataSnapshot).childSnapshot(forPath: "filterQuestions")
                                    for filter in self.advancedFilters{
                                        let filterKey = Array(filter.keys)[0]
                                        for filterQuestion in list.children {
                                            let hadToDefineItToMakeItWork = filterQuestion as! DataSnapshot
                                            let question = hadToDefineItToMakeItWork.key
                                            if(filterKey == hadToDefineItToMakeItWork.key){
                                                let thisValue = hadToDefineItToMakeItWork.value as? [String] ?? [""]
                                                if(thisValue.contains((filter[filterKey]) ?? "")){
                                                    advancedMatch = true
                                                    self.questionMatches.append(filterKey)
                                                    break
                                                } else {
                                                    if(!self.questionMatches.contains(filterKey)){
                                                        advancedMatch = false
                                                    }
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let timezoneSearch = (self.locationFilter == "timezone")
                    var currentTimezone = ""
                    var timezoneMatch = true
                    if(timezoneSearch){
                        if((user as! DataSnapshot).hasChild("timezone")){
                            currentTimezone = (user as! DataSnapshot).childSnapshot(forPath: "timezone").value as? String ?? ""
                            timezoneMatch = currentTimezone == delegate.currentUser!.timezone
                        } else {
                            timezoneMatch = false
                        }
                    }
                    
                    if(ageMatch && languageMatch && advancedMatch && timezoneMatch){
                        let uId = (user as! DataSnapshot).key
                        let bio = value?["bio"] as? String ?? ""
                        let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                        
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
                        
                        let games = value?["games"] as? [String] ?? [String]()
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                        let dict = consoleArray.value as? [String: Bool]
                        let nintendo = dict?["nintendo"] ?? false
                        let ps = dict?["ps"] ?? false
                        let xbox = dict?["xbox"] ?? false
                        let pc = dict?["pc"] ?? false
                        
                        let returnedUser = User(uId: uId)
                        returnedUser.gamerTags = gamerTags
                        returnedUser.games = games
                        returnedUser.friends = friends
                        returnedUser.sentRequests = sentRequests
                        returnedUser.gamerTag = gamerTag
                        returnedUser.pc = pc
                        returnedUser.ps = ps
                        returnedUser.xbox = xbox
                        returnedUser.nintendo = nintendo
                        returnedUser.bio = bio
                        
                        //if the returned user plays the game being searched AND the returned users gamertag
                        //does not equal the current users gamertag, then add to list.
                        let manager = FriendsManager()
                        if(self.currentUser.uId != returnedUser.uId &&
                            !manager.isInFriendList(user: returnedUser, currentUser: self.currentUser) && !manager.isBlocked(user: returnedUser, currentUser: self.currentUser)){
                            self.addUserToList(returnedUser: returnedUser)
                        }
                    }
                }
            }
            callbacks.onSuccess(returnedUsers: self.returnedUsers)
        })
    }
    
    func searchForUser(searchTag: String, callbacks: SearchManagerCallbacks){
        self.returnedUsers = [User]()
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            var containedProfile = false
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                
                let search = value?["search"] as? String ?? "true"
                var gamerTags = [GamerProfile]()
                if((user as! DataSnapshot).hasChild("gamerTags")){
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        
                        if(currentTag != "" && currentGame != "" && console != ""){
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                    }
                }
            
                for tag in gamerTags {
                    if(tag.gamerTag.caseInsensitiveCompare(searchTag) == .orderedSame){
                        containedProfile = true
                        break
                    }
                }
                if(containedProfile && (search == "true")){
                    let uId = (user as! DataSnapshot).key
                    let bio = value?["bio"] as? String ?? ""
                    let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                    
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
                    
                    let games = value?["games"] as? [String] ?? [String]()
                    var gamerTags = [GamerProfile]()
                    let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                    for gamerTagObj in gamerTagsArray.children {
                        let currentObj = gamerTagObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let currentTag = dict?["gamerTag"] as? String ?? ""
                        let currentGame = dict?["game"] as? String ?? ""
                        let console = dict?["console"] as? String ?? ""
                        let quizTaken = dict?["quizTaken"] as? String ?? ""
                        
                        let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                        gamerTags.append(currentGamerTagObj)
                    }
                    
                    let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                    let dict = consoleArray.value as? [String: Bool]
                    let nintendo = dict?["nintendo"] ?? false
                    let ps = dict?["ps"] ?? false
                    let xbox = dict?["xbox"] ?? false
                    let pc = dict?["pc"] ?? false
                    
                    let returnedUser = User(uId: uId)
                    returnedUser.gamerTags = gamerTags
                    returnedUser.games = games
                    returnedUser.friends = friends
                    returnedUser.sentRequests = sentRequests
                    returnedUser.gamerTag = searchTag
                    returnedUser.pc = pc
                    returnedUser.ps = ps
                    returnedUser.xbox = xbox
                    returnedUser.nintendo = nintendo
                    returnedUser.bio = bio
                    
                    self.returnedUsers.append(returnedUser)
                    callbacks.onSuccess(returnedUsers: self.returnedUsers)
                    return
                }
            }
            if(!containedProfile){
                callbacks.onFailure()
            }
        })
    }
    
    private func addUserToList(returnedUser: User){
        var contained = false
        let manager = GamerProfileManager()
        
        for user in returnedUsers{
            if(manager.getGamerTagForOtherUserForGame(gameName: self.currentGameSearch, returnedUser: user) == manager.getGamerTagForOtherUserForGame(gameName: self.currentGameSearch, returnedUser: returnedUser)){
                
                contained = true
                break
            }
        }
        
        if(!contained){
            self.returnedUsers.append(returnedUser)
        }
    }
}
