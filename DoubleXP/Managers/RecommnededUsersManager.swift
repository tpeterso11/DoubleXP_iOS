//
//  RecommnededUsersManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/29/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseDatabase
import GeoFire

class RecommnededUsersManager {
    var locationUsers = [User]()
    var bestMatch = [User]()
    var random = [User]()
    var fillerUsers = [User]()
    var recommendedGame: GamerConnectGame?
    var cachedGames = [String]()
    private var loadingCount = 0
    private var triedRandom = [Int]()
    private var triedBest = [Int]()
    
    func getRecommendedUsers(cachedViewedUids: [String], callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        triedRandom = [Int]()
        self.loadingCount += 1
        
        let ref = Database.database().reference().child("Users").child(currentUser.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                if(snapshot.hasChild("recommendedGames")){
                    self.cachedGames = snapshot.childSnapshot(forPath: "recommededGames").value as? [String] ?? [String]()
                    self.recommendedGame = nil
                    if(currentUser.userLat != 0.0){
                        self.buildUserCache(user: currentUser, cache: cachedViewedUids, callbacks: callbacks)
                    } else {
                        self.loadBackupUsersCache(cache: cachedViewedUids, currentUser: currentUser, callbacks: callbacks)
                    }
                } else {
                    self.recommendedGame = nil
                    if(currentUser.userLat != 0.0){
                        self.buildUserCache(user: currentUser, cache: cachedViewedUids, callbacks: callbacks)
                    } else {
                        self.loadBackupUsersCache(cache: cachedViewedUids, currentUser: currentUser, callbacks: callbacks)
                    }
                }
            }
        })
    }
    
    private func buildUserCache(user: User, cache: [String], callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        let center = CLLocation(latitude: currentUser.userLat, longitude: currentUser.userLong)
        
        let geofireRef = Database.database().reference().child("geofire")
        let geoFire = GeoFire(firebaseRef: geofireRef)
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        var ids = [String]()
        var backupIds = [String]()
        let query = geoFire.query(at: center, withRadius: 160.934)//100 miles
        query.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            if(!cache.contains(key)){
                ids.append(key)
            }
            backupIds.append(key)
        })
        query.observeReady {
            query.removeAllObservers()
            if(ids.count < 2){
                self.loadUsers(list: ids, cache: cache, user: user, intoList: self.locationUsers, callbacks: callbacks)
            } else {
                self.loadUsers(list: backupIds, cache: [String](), user: user, intoList: self.locationUsers, callbacks: callbacks)
            }
        }
    }
    
    private func loadUsers(list: [String]?, cache: [String], user: User, intoList: [User], callbacks: TodayCallbacks){
        if(list != nil){
            var newList = [String]()
            newList.append(contentsOf: list!)
            newList.shuffle()
            self.loadListUser(uid: list![0], currentList: newList, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
        } else {
            self.loadBackupUsersCache(cache: cache, currentUser: user, callbacks: callbacks)
        }
    }
    
    private func loadListUser(uid: String, currentList: [String]?, cache: [String], user: User, intoList: [User], callbacks: TodayCallbacks){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("games") && snapshot.hasChild("gamerTag") && snapshot.hasChild("gamerTags")){
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                
                var gamerTags = [GamerProfile]()
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
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
                
                var consoles = [String]()
                for profile in user.gamerTags {
                    if(!consoles.contains(profile.console)){
                        consoles.append(profile.console)
                    }
                }
                
                var containedProfile = false
                var gamerTag = ""
                for tag in gamerTags {
                    if(!tag.gamerTag.isEmpty){
                        if(user.games.contains(tag.game)){
                            if(consoles.contains(tag.console)){
                                containedProfile = true
                                gamerTag = tag.gamerTag
                                break
                            }
                        }
                    }
                }
                
                let theirGames = snapshot.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                
                if(containedProfile){
                    let newUser = User(uId: uid)
                    newUser.games = theirGames
                    newUser.gamerTag = gamerTag
                    
                    self.locationUsers.append(newUser)
                    currentArray.remove(at: currentArray.index(of: uid)!)
                    
                    if(currentArray.count > 0){
                        self.loadUsers(list: currentArray, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
                    } else if(intoList.count == 3){
                        self.handleCache(cache: cache, callbacks: callbacks)
                        return
                    } else {
                        self.loadBackupUsersCache(cache: cache, currentUser: user, callbacks: callbacks)
                    }
                } else {
                    currentArray.remove(at: currentArray.index(of: uid)!)
                    
                    if(currentArray.count > 0){
                        self.loadUsers(list: currentArray, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
                    } else if(intoList.count == 3){
                        self.handleCache(cache: cache, callbacks: callbacks)
                        return
                    } else {
                        self.loadBackupUsersCache(cache: cache, currentUser: user, callbacks: callbacks)
                    }
                }
            } else {
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                currentArray.remove(at: currentArray.index(of: uid)!)
            
                if(currentArray.count > 0){
                    self.loadUsers(list: currentArray, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
                } else if(intoList.count == 3){
                    self.handleCache(cache: cache, callbacks: callbacks)
                    return
                } else {
                    self.loadBackupUsersCache(cache: cache, currentUser: user, callbacks: callbacks)
                }
            }
        })
    }
    
    private func buildBestMatchUsers(snapshot: DataSnapshot, randoms: [Int], cache: [String], callbacks: TodayCallbacks) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        var gamesMatch = false
        var languageMatch = false
        
        if(self.triedBest.count == snapshot.childrenCount - 1){
            self.handleCache(cache: cache, callbacks: callbacks)
            return
        }
        
        for int in randoms {
            self.triedBest.append(int)
            
            let randomUserOne = (snapshot.children.allObjects[int] as! DataSnapshot)
            if(randomUserOne.hasChild("gamerTag") && randomUserOne.hasChild("games")){
                let theirGames = randomUserOne.childSnapshot(forPath: "games").value as? [String] ?? [String]()
                let gamertag = randomUserOne.childSnapshot(forPath: "gamerTag").value as? String ?? ""
                for game in currentUser.games {
                    if(theirGames.contains(game)){
                        gamesMatch = true
                        break
                    }
                }
                if(randomUserOne.hasChild("primaryLanguage")){
                    let primary = randomUserOne.childSnapshot(forPath: "primaryLanguage").value as? String ?? ""
                    if(currentUser.primaryLanguage == primary){
                        languageMatch = true
                    }
                    if(!languageMatch){
                        if(randomUserOne.hasChild("secondaryLanguage")){
                            let secondary = randomUserOne.childSnapshot(forPath: "secondaryLanguage").value as? String ?? ""
                            if(currentUser.secondaryLanguage == secondary){
                                languageMatch = true
                            }
                        }
                    }
                }
                
                var locationMatch = false
                //check timezone, just in case
                if(snapshot.hasChild(currentUser.uId) && self.locationUsers.isEmpty){
                    let currentUser = snapshot.childSnapshot(forPath: currentUser.uId)
                    if(currentUser.hasChild("timezone") && randomUserOne.hasChild("timezone")){
                        let currentTimeZone = currentUser.childSnapshot(forPath: "timezone")
                        let randomTimeZone = randomUserOne.childSnapshot(forPath: "timezone")
                        if(currentTimeZone == randomTimeZone){
                            locationMatch = true
                        }
                    }
                }
                //checks to make sure it's not the current user or a friend/pendingfriend
                let manager = FriendsManager()
                let possibleUser = self.quickCreateUser(snapshot: randomUserOne)
                let isFriendorPending = manager.checkListsForUser(user: possibleUser, currentUser: currentUser)
                let userAlreadyInListSomehow = manager.userListHasUid(list: self.random, uid: randomUserOne.key)
                let userGamertagInListSomehowToo = manager.userListHasGamerTag(list: self.random, gamertag: gamertag)
                var isCurrentUser = false
                if(randomUserOne.key == currentUser.uId){
                    isCurrentUser = true
                }
                
                if(gamesMatch && languageMatch && locationMatch && !isCurrentUser && !isFriendorPending && !userAlreadyInListSomehow && !userGamertagInListSomehowToo && !self.userIsInAnotherList(uid: randomUserOne.key) && self.bestMatch.count < 3 && !gamertag.isEmpty && !cache.contains(randomUserOne.key)){
                    self.bestMatch.append(self.quickCreateUser(snapshot: randomUserOne))
                    
                    var newArray = [Int]()
                    for currentInt in randoms {
                        if(int != currentInt){
                            newArray.append(currentInt)
                        }
                    }
                    self.buildBestMatchUsers(snapshot: snapshot, randoms: newArray, cache: cache, callbacks: callbacks)
                } else if(self.bestMatch.count < 3 && randoms.isEmpty){
                    buildBestMatchUsers(snapshot: snapshot, randoms: [self.getRandomNumber(max: snapshot.children.allObjects.count)], cache: cache, callbacks: callbacks)
                } else {
                    if(self.bestMatch.count == 3){
                        return
                    } else {
                        var newArray = [Int]()
                        for currentInt in randoms {
                            if(int != currentInt){
                                newArray.append(currentInt)
                            }
                        }
                        self.buildBestMatchUsers(snapshot: snapshot, randoms: newArray, cache: cache, callbacks: callbacks)
                        return
                    }
                }
            }
        }
    }
    
    private func buildRandomUsers(snapshot: DataSnapshot, randoms: [Int], cache: [String], callbacks: TodayCallbacks) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser!
        var gamesMatch = false
        var languageMatch = false
        
        if(self.triedRandom.count == snapshot.childrenCount - 1){
            self.handleCache(cache: cache, callbacks: callbacks)
            return
        }
        
        if(randoms.isEmpty){
            buildRandomUsers(snapshot: snapshot, randoms: self.getRandomNumbersArray(max: snapshot.children.allObjects.count), cache: cache, callbacks: callbacks)
            return
        }
        
        let int = randoms[0]
        self.triedRandom.append(int)
        
        let randomUserOne = (snapshot.children.allObjects[int] as! DataSnapshot)
        if(randomUserOne.hasChild("gamerTag") && randomUserOne.hasChild("games")){
            let theirGames = randomUserOne.childSnapshot(forPath: "games").value as? [String] ?? [String]()
            let gamertag = randomUserOne.childSnapshot(forPath: "gamerTag").value as? String ?? ""
            for game in currentUser.games {
                if(theirGames.contains(game)){
                    gamesMatch = true
                    break
                }
            }
            if(randomUserOne.hasChild("primaryLanguage")){
                let primary = randomUserOne.childSnapshot(forPath: "primaryLanguage").value as? String ?? ""
                if(currentUser.primaryLanguage == primary){
                    languageMatch = true
                }
                if(!languageMatch){
                    if(randomUserOne.hasChild("secondaryLanguage")){
                        let secondary = randomUserOne.childSnapshot(forPath: "secondaryLanguage").value as? String ?? ""
                        if(currentUser.secondaryLanguage == secondary){
                            languageMatch = true
                        }
                    }
                }
            }
            //checks to make sure it's not the current user or a friend/pendingfriend
            let manager = FriendsManager()
            let possibleUser = self.quickCreateUser(snapshot: randomUserOne)
            let isFriendorPending = manager.checkListsForUser(user: possibleUser, currentUser: currentUser)
            let userAlreadyInListSomehow = manager.userListHasUid(list: self.random, uid: randomUserOne.key)
            let userGamertagInListSomehowToo = manager.userListHasGamerTag(list: self.random, gamertag: gamertag)
            var isCurrentUser = false
            if(randomUserOne.key == currentUser.uId){
                isCurrentUser = true
            }
            
            //this is causing a loop when we get to handle cache.
            //if(gamesMatch && languageMatch && !isCurrentUser && !isFriendorPending && !userAlreadyInListSomehow && !self.userIsInAnotherList(uid:
            if(gamesMatch && !isCurrentUser && !isFriendorPending && !userAlreadyInListSomehow && !userGamertagInListSomehowToo && !self.userIsInAnotherList(uid:randomUserOne.key) && self.random.count < 3 && !gamertag.isEmpty && !cache.contains(randomUserOne.key)){
                self.random.append(self.quickCreateUser(snapshot: randomUserOne))
                
                var newArray = [Int]()
                for currentInt in randoms {
                    if(int != currentInt){
                        newArray.append(currentInt)
                    }
                }
                
                self.buildRandomUsers(snapshot: snapshot, randoms: newArray, cache: cache, callbacks: callbacks)
                return
            } else if(self.random.count < 3 && randoms.isEmpty){
                buildRandomUsers(snapshot: snapshot, randoms: [self.getRandomNumber(max: snapshot.children.allObjects.count)], cache: cache, callbacks: callbacks)
            } else {
                if(self.random.count == 3){
                    return
                } else {
                    var newArray = [Int]()
                    for currentInt in randoms {
                        if(int != currentInt){
                            newArray.append(currentInt)
                        }
                    }
                    self.buildRandomUsers(snapshot: snapshot, randoms: newArray, cache: cache, callbacks: callbacks)
                    return
                }
            }
        } else {
            var newArray = [Int]()
            for currentInt in randoms {
                if(int != currentInt){
                    newArray.append(currentInt)
                }
            }
            self.buildRandomUsers(snapshot: snapshot, randoms: newArray, cache: cache, callbacks: callbacks)
        }
    }
    
    private func userIsInAnotherList(uid: String) -> Bool {
        var contained = false
        if(!self.bestMatch.isEmpty){
            for user in self.bestMatch {
                if(user.uId == uid){
                    contained = true
                    break
                }
            }
        }
        if(!self.locationUsers.isEmpty && !contained){
            for user in self.locationUsers {
                if(user.uId == uid){
                    contained = true
                    break
                }
            }
        }
        if(!self.random.isEmpty && !contained){
            for user in self.random {
                if(user.uId == uid){
                    contained = true
                    break
                }
            }
        }
        
        return contained
    }
    
    private func getRandomNumbersArray(max: Int) -> [Int]{
        var possiblePositions = [Int]()
        let one = self.getRandomNumber(max: max)
        let two = self.getRandomNumber(max: max)
        let three = self.getRandomNumber(max: max)
        possiblePositions.append(one)
        possiblePositions.append(two)
        possiblePositions.append(three)
        
        return possiblePositions
    }
    
    private func loadBackupUsersCache(cache: [String], currentUser: User, callbacks: TodayCallbacks){
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.buildRandomUsers(snapshot: snapshot, randoms: self.getRandomNumbersArray(max: snapshot.children.allObjects.count), cache: cache, callbacks: callbacks)
            self.buildBestMatchUsers(snapshot: snapshot, randoms: self.getRandomNumbersArray(max: snapshot.children.allObjects.count), cache: cache, callbacks: callbacks)
            self.handleCache(cache: cache, callbacks: callbacks)
        })
    }
    
    private func loadUsersIntoList(uids: [String]?, cache: [String], user: User, intoList: String, callbacks: TodayCallbacks){
        if(uids != nil){
            var newList = [String]()
            newList.append(contentsOf: uids!)
            newList.shuffle()
            self.loadListUserIntoList(uid: uids![0], currentList: newList, intoList: intoList, cache: cache, user: user, callbacks: callbacks)
        } else {
            return
        }
    }
    
    private func loadListUserIntoList(uid: String, currentList: [String]?, intoList: String, cache: [String], user: User, callbacks: TodayCallbacks){
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild("games") && snapshot.hasChild("gamerTag")){
                if(intoList == "location"){
                    var contained = false
                    for user in self.locationUsers {
                        if(user.uId == snapshot.key){
                            contained = true
                        }
                    }
                    if(!contained){
                        self.locationUsers.append(self.quickCreateUser(snapshot: snapshot))
                    }
                } else if(intoList == "best"){
                    var contained = false
                    for user in self.bestMatch {
                        if(user.uId == snapshot.key){
                            contained = true
                        }
                    }
                    if(!contained){
                        self.bestMatch.append(self.quickCreateUser(snapshot: snapshot))
                    }
                } else {
                    var contained = false
                    for user in self.random {
                        if(user.uId == snapshot.key){
                            contained = true
                        }
                    }
                    if(!contained){
                        self.random.append(self.quickCreateUser(snapshot: snapshot))
                    }
                }
                var newList = [String]()
                newList.append(contentsOf: currentList!)
                newList.remove(at: newList.index(of: uid)!)
                
                if(newList.count > 0){
                    self.loadUsersIntoList(uids: newList, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
                } else {
                    self.handleCache(cache: cache, callbacks: callbacks)
                    return
                }
            } else {
                var currentArray = [String]()
                currentArray.append(contentsOf: currentList!)
                currentArray.remove(at: currentArray.index(of: uid)!)
                
                if(currentArray.count > 0){
                    self.loadUsersIntoList(uids: currentArray, cache: cache, user: user, intoList: intoList, callbacks: callbacks)
                } else {
                    self.handleCache(cache: cache, callbacks: callbacks)
                    return
                }
            }
        })
    }
    
    private func getRandomNumber(max: Int) -> Int {
        let randomInt = Int.random(in: 0..<max)
        return randomInt
    }
    
    private func quickCreateUser(snapshot: DataSnapshot) -> User{
        let user = User(uId: snapshot.key)
        if(snapshot.hasChild("gamerTag")){
            let gamerTag = snapshot.childSnapshot(forPath: "gamerTag").value as? String ?? ""
            user.gamerTag = gamerTag
        }
        return user
    }
    
    func getCachedUsers(uid: String, callbacks: TodayCallbacks){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var cache = [String]()
                if(snapshot.hasChild("currentCachedGame")){
                    self.recommendedGame = self.loadRecommendedGame(gameName: snapshot.childSnapshot(forPath: "currentCachedGame").value as! String)
                }
                if(snapshot.hasChild("cachedRecommendedUids")){
                    cache = snapshot.childSnapshot(forPath: "cachedRecommendedUids").value as? [String] ?? [String]()
                }
                var bestCache = [String]()
                var loactationCache = [String]()
                var randomCache = [String]()
                if(snapshot.hasChild("currenBestCache")){
                    self.loadingCount += 1
                    bestCache = snapshot.childSnapshot(forPath: "currenBestCache").value as? [String] ?? [String]()
                }
                if(snapshot.hasChild("currenLocationCache")){
                    self.loadingCount += 1
                    loactationCache = snapshot.childSnapshot(forPath: "currenLocationCache").value as? [String] ?? [String]()
                }
                if(snapshot.hasChild("currentRandomCache")){
                    self.loadingCount += 1
                    randomCache = snapshot.childSnapshot(forPath: "currentRandomCache").value as? [String] ?? [String]()
                }
                
                if(!bestCache.isEmpty){
                    self.loadUsersIntoList(uids: bestCache, cache: cache, user: delegate.currentUser!, intoList: "best", callbacks: callbacks)
                }
                if(!loactationCache.isEmpty){
                    self.loadUsersIntoList(uids: loactationCache, cache: cache, user: delegate.currentUser!, intoList: "location", callbacks: callbacks)
                }
                if(!randomCache.isEmpty){
                    self.loadUsersIntoList(uids: randomCache, cache: cache, user: delegate.currentUser!, intoList: "random", callbacks: callbacks)
                }
            }
        })
    }
    
    private func handleCache(cache: [String], callbacks: TodayCallbacks){
        self.loadingCount -= 1
        if(self.bestMatch.count < 3 && self.random.count < 3 && loadingCount == 0){
            //reset
            if(self.random.count == 1 && self.fillerUsers.count > 1){
                var newList = [User]()
                newList.append(contentsOf: self.fillerUsers)
                newList.shuffle()
                
                self.random.append(newList[0])
                self.random.append(newList[1])
            } else if(self.random.count == 2 && !self.fillerUsers.isEmpty){
                var newList = [User]()
                newList.append(contentsOf: self.fillerUsers)
                newList.shuffle()
                
                self.random.append(newList[0])
            }
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
            ref.child("cachedRecommendedUids").removeValue()
            ref.child("currenBestCache").removeValue()
            ref.child("currentRandomCache").removeValue()
            return
        }
        
        if(locationUsers.count < 3){
            locationUsers = [User]()
        }
        
        var sendUp = [String]()
        var currenBestCache = [String]()
        var currenLocation = [String]()
        var currentRandom = [String]()
        sendUp.append(contentsOf: cache)
        for user in self.bestMatch {
            if(!cache.contains(user.uId)){
                sendUp.append(user.uId)
            }
            if(!currenBestCache.contains(user.uId)){
                currenBestCache.append(user.uId)
            }
        }
        for user in self.locationUsers {
            if(!cache.contains(user.uId)){
                sendUp.append(user.uId)
            }
            if(!currenLocation.contains(user.uId)){
                currenLocation.append(user.uId)
            }
        }
        for user in self.random {
            if(!cache.contains(user.uId)){
                sendUp.append(user.uId)
            }
            if(!currentRandom.contains(user.uId)){
                currentRandom.append(user.uId)
            }
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("cachedRecommendedUids").setValue(sendUp)
        ref.child("currenBestCache").setValue(currenBestCache)
        ref.child("currenLocationCache").setValue(currenLocation)
        ref.child("currentRandomCache").setValue(currentRandom)
        if(delegate.currentUser!.recommendedGames.isEmpty){
            ref.child("recommendedGames").removeValue()
        } else {
            ref.child("recommendedGames").setValue(delegate.currentUser!.recommendedGames)
        }
        
        if(self.loadingCount == 0){
            callbacks.onRecommendedUsersLoaded()
        }
    }
    
    func recommendationsAvailable() -> Bool {
        if(!self.bestMatch.isEmpty || !self.locationUsers.isEmpty || !self.random.isEmpty){
            return true
        } else {
            return false
        }
    }
    
    private func loadRecommendedGame(gameName: String) -> GamerConnectGame {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        for game in delegate.gcGames {
            if(gameName == game.gameName){
                self.recommendedGame = game
                return self.recommendedGame!
            }
        }
        
        return GamerConnectGame(imageUrl: "", gameName: "", developer: "", hook: "", statsAvailable: false, teamNeeds: [String](), twitterHandle: "", twitchHandle: "", available: "")
    }
    
    func getRecommendedGame() -> GamerConnectGame {
        if(self.recommendedGame != nil){
            return self.recommendedGame!
        } else {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            var gameList = [GamerConnectGame]()
            gameList.append(contentsOf: delegate.gcGames)
            gameList.shuffle()
            for game in gameList {
                if(!delegate.currentUser!.recommendedGames.contains(game.gameName) && !delegate.currentUser!.games.contains(game.gameName)){
                    self.recommendedGame = game
                    delegate.currentUser!.recommendedGames.append(game.gameName)
                    let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                    ref.child("currentCachedGame").setValue(game.gameName)
                    return self.recommendedGame!
                }
            }
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentUser!.recommendedGames = [String]()
        var gameList = [GamerConnectGame]()
        gameList.append(contentsOf: delegate.gcGames)
        gameList.shuffle()
        for game in gameList {
            if(!delegate.currentUser!.recommendedGames.contains(game.gameName) && !delegate.currentUser!.games.contains(game.gameName)){
                self.recommendedGame = game
                let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
                ref.child("currentCachedGame").setValue(game.gameName)
                return self.recommendedGame!
            }
        }
        
        return GamerConnectGame(imageUrl: "", gameName: "", developer: "", hook: "", statsAvailable: false, teamNeeds: [String](), twitterHandle: "", twitchHandle: "", available: "")
    }
}
