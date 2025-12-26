//
//  UserProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/25/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit
import Firebase
import AVKit
import FirebaseDatabaseInternal
import Combine

@MainActor
final class UserProvider: ObservableObject {
    static let shared = UserProvider()
    private init() {}

    // MARK: - Published state
    @Published private(set) var currentUser: User?
    @Published private(set) var lastError: Error?

    // (optional) keep track of current uid for reloads
    private var currentUid: String?

    // MARK: - Public API

    /// Loads the full User object from Firebase for the given UID,
    /// stores it in `currentUser`, and **does not** return it.
    func loadUser(uid: String) async -> User? {
        self.currentUid = uid
        do {
            let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                let userRef = Database.database().reference().child("Users").child(uid)
                userRef.observeSingleEvent(of: .value, with: { snap in
                    continuation.resume(returning: snap)
                }, withCancel: { error in
                    continuation.resume(throwing: error)
                })
            }

            guard let value = snapshot.value as? [String: Any] else {
                self.lastError = NSError(domain: "UserProvider", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "No user data"])
                return nil
            }

            let built = try buildUser(from: snapshot, rootDict: value)
            self.currentUser = built
            self.lastError = nil
            
            NotificationCenter.default.post(name: .userProviderDidUpdateUser, object: nil)
            return built
            
        } catch {
            self.lastError = error
            return nil
        }
    }

    /// Convenience: reloads the last loaded uid.
    func reload() async throws {
        guard let uid = currentUid else { return }
        try await loadUser(uid: uid)
    }

    /// Accessors
    func getUser() -> User? { currentUser }

    func requireUser() throws -> User {
        if let u = currentUser { return u }
        throw NSError(domain: "UserProvider", code: -2,
                      userInfo: [NSLocalizedDescriptionKey: "User not loaded"])
    }

    /// Clear user on sign-out.
    func clear() {
        currentUser = nil
        currentUid = nil
        lastError = nil
    }
    
    func fetchUser(uid: String) async -> User? {
        do {
            let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                let userRef = Database.database().reference().child("Users").child(uid)
                userRef.observeSingleEvent(of: .value, with: { snap in
                    continuation.resume(returning: snap)
                }, withCancel: { error in
                    continuation.resume(throwing: error)
                })
            }

            guard let value = snapshot.value as? [String: Any] else {
                print("🔴 UserProvider.fetchUser: no data for uid \(uid)")
                return nil
            }

            let built = try self.buildUser(from: snapshot, rootDict: value)
            return built
        } catch {
            print("🔴 UserProvider.fetchUser failed for uid \(uid): \(error)")
            return nil
        }
    }

    // MARK: - (Optional) live listener
    // If you want the user to stay in sync with DB changes, you can enable this.
    // Keep a DatabaseHandle property if you add/remove observers.
    /*
    private var liveHandle: DatabaseHandle?
    func startLiveUpdates(uid: String) {
        stopLiveUpdates()
        currentUid = uid
        let ref = Database.database().reference().child("Users").child(uid)
        liveHandle = ref.observe(.value) { [weak self] snap in
            guard let self else { return }
            guard let value = snap.value as? [String: Any] else { return }
            do {
                let u = try self.buildUser(from: snap, rootDict: value)
                self.currentUser = u
            } catch {
                self.lastError = error
            }
        }
    }
    func stopLiveUpdates() {
        if let h = liveHandle, let uid = currentUid {
            Database.database().reference().child("Users").child(uid).removeObserver(withHandle: h)
        }
        liveHandle = nil
    }
    */

    // MARK: - Build helper (your original parsing, lightly cleaned)

    private func buildUser(from snapshot: DataSnapshot, rootDict value: [String: Any]) throws -> User {
        //let delegate = UIApplication.shared.delegate as! AppDelegate
        let userRef = snapshot.ref

        let uId = snapshot.key
        let gamerTag = value["screenName"] as? String ?? ""
        let userLat = value["userLat"] as? Double ?? 0.0
        let userLong = value["userLong"] as? Double ?? 0.0

        let subscriptions = value["subscriptions"] as? [String] ?? []
        let viewedPosts = value["viewedPosts"] as? [String] ?? []
        let competitions = value["competitions"] as? [String] ?? []
        let bio = value["bio"] as? String ?? ""
        let blockList = value["blockList"] as? [String: String] ?? [:]
        let restrictList = value["restrictList"] as? [String: String] ?? [:]
        let cachedRecommendedUids = value["cachedRecommendedUids"] as? [String] ?? []
        let dailyCheck = value["dailyCheck"] as? String ?? ""
        let googleApiAccessToken = value["googleApiAccessToken"] as? String ?? ""
        let googleApiRefreshToken = value["googleApiRefreshToken"] as? String ?? ""
        let gamingExperience = value["gamingExperience"] as? String ?? "5"
        let currentSelectedPokoId = value["selectedPoko"] as? String ?? ""
        let instagramConnect = value["instagramConnect"] as? String ?? ""
        let twitterConnect = value["twitterConnect"] as? String ?? ""
        let twitchConnect = value["twitchConnect"] as? String ?? ""
        let discordConnect = value["discordConnect"] as? String ?? ""
        let tiktokConnect = value["tiktokConnect"] as? String ?? ""
        let joinedAtMillis = value["joinedAt"] as? TimeInterval ?? 0
        let tagline = value["tagline"] as? String ?? ""
        var receivedAnnouncements = value["receivedAnnouncements"] as? [String] ?? []
        let aboutMe = value["aboutMe"] as? [String] ?? []
        let reviews = value["reviews"] as? [String] ?? []
        let search = value["search"] as? String ?? ""
        let ownedPokos = value["ownedPokos"] as? [String] ?? []
        let lookingForArray = snapshot.hasChild("lookingFor")
            ? (snapshot.childSnapshot(forPath: "lookingFor").value as? [String] ?? [])
            : []
        // ensure flags exist — write under the **user node**, not root
        if search.isEmpty {
            userRef.child("search").setValue("true")
        }
        
        let videoSettingsSnapshot = snapshot.childSnapshot(forPath: "videoSettings")
        let dict = videoSettingsSnapshot.value as? [String: Any] ?? [:]

        let showcaseVideoIds = dict["showcaseVideoIds"] as? [String] ?? []
        let communities = value["communities"] as? [String] ?? []
        let highlightVideoId = dict["highlightVideoId"] as? String

        let notifications = value["notifications"] as? String ?? ""
        if notifications.isEmpty {
            userRef.child("notifications").setValue("true")
        }

        // Followers / Following / Announcements
        let followers: [FriendObject] = readFriendObjects(from: snapshot, path: "followers")
        let following: [FriendObject] = readFriendObjects(from: snapshot, path: "following")
        let followerAnnouncements: [FriendObject] = readFriendObjects(from: snapshot, path: "followerAnnouncements")

        // Twitch token bootstrapping
        let twitchToken = value["twitchAppToken"] as? String ?? ""
        /*let manager = delegate.socialMediaManager
        if twitchToken.isEmpty {
            manager.getTwitchAppToken(token: nil, uid: uId)
        } else {
            manager.getTwitchAppToken(token: twitchToken, uid: uId)
        }*/

        // Requests
        let sentRequests: [FriendRequestObject] = readFriendRequests(from: snapshot, path: "sent_requests")
        let pendingRequests: [FriendRequestObject] = readFriendRequests(from: snapshot, path: "pending_friends")

        var dbRequests = [RequestObject]()
        if snapshot.hasChild("pending_friends") {
            let teamInviteRequests = snapshot.childSnapshot(forPath: "inviteRequests")
            for invite in teamInviteRequests.children {
                guard let currentObj = invite as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }

                let status = dict["status"] as? String ?? ""
                let teamId = dict["teamId"] as? String ?? ""
                let teamName = dict["teamName"] as? String ?? ""
                let captainId = dict["captainId"] as? String ?? ""
                let gamerTag = dict["gamerTag"] as? String ?? ""
                let requestId = dict["requestId"] as? String ?? ""
                let userUid = dict["userUid"] as? String ?? ""

                let profile = currentObj.childSnapshot(forPath: "profile")
                let profileDict = profile.value as? [String: Any]
                let game = profileDict?["game"] as? String ?? ""
                let consoles = profileDict?["consoles"] as? [String] ?? []
                let profileGamerTag = profileDict?["gamerTag"] as? String ?? ""
                let competitionId = profileDict?["competitionId"] as? String ?? ""
                let userId = profileDict?["userId"] as? String ?? ""

                var questions = [FAQuestion]()
                let questionList = dict["questions"] as? [[String: Any]] ?? []
                for q in questionList {
                    questions.append(parseFAQuestion(from: q))
                }

                let result = FreeAgentObject(
                    gamerTag: profileGamerTag,
                    competitionId: competitionId,
                    consoles: consoles,
                    game: game,
                    userId: userId,
                    questions: questions
                )

                let newRequest = RequestObject(
                    status: status,
                    teamId: teamId,
                    teamName: teamName,
                    captainId: captainId,
                    requestId: requestId,
                    userUid: userUid,
                    gamerTag: gamerTag
                )
                newRequest.profile = result
                dbRequests.append(newRequest)
            }
        }

        // Friends
        let friends: [FriendObject] = readFriendObjects(from: snapshot, path: "friends")

        // Team Invites
        var currentTeamInvites = [TeamInviteObject]()
        if snapshot.hasChild("teamInvites") {
            let teamInvites = snapshot.childSnapshot(forPath: "teamInvites")
            for invite in teamInvites.children {
                guard let currentObj = invite as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let gamerTag = dict["gamerTag"] as? String ?? ""
                let date = dict["date"] as? String ?? ""
                let teamName = dict["teamName"] as? String ?? ""
                currentTeamInvites.append(TeamInviteObject(gamerTag: gamerTag, date: date, uid: uId, teamName: teamName))
            }
        }

        // Posts (receivedPosts commented out in your original)
        var myPosts = [PostObject]()
        if snapshot.hasChild("myPosts") {
            let posts = snapshot.childSnapshot(forPath: "myPosts")
            for post in posts.children {
                guard let currentObj = post as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let date = dict["date"] as? String ?? ""
                let postId = dict["postId"] as? String ?? ""
                let videoOwnerGamerTag = dict["videoOwnerGamerTag"] as? String ?? ""
                let game = dict["game"] as? String ?? ""
                let videoOwnerUid = dict["videoOwnerUid"] as? String ?? ""
                let youtubeId = dict["youtubeId"] as? String ?? ""
                let youtubeImg = dict["youtubeImg"] as? String ?? ""
                let publicPost = dict["publicPost"] as? String ?? ""
                let postConsole = dict["postConsole"] as? String ?? ""
                let title = dict["title"] as? String ?? ""
                myPosts.append(PostObject(postId: postId, title: title, videoOwnerGamerTag: videoOwnerGamerTag, videoOwnerUid: videoOwnerUid, publicPost: publicPost, date: date, youtubeId: youtubeId, imgUrl: youtubeImg, postConsole: postConsole, game: game))
            }
        }

        // Consoles
        let consoleDict = snapshot.childSnapshot(forPath: "consoles").value as? [String: Bool]
        let nintendo = consoleDict?["nintendo"] ?? false
        let ps = consoleDict?["ps"] ?? false
        let xbox = consoleDict?["xbox"] ?? false
        let pc = consoleDict?["pc"] ?? false

        // Games and GamerTags
        let games = value["games"] as? [String] ?? []
        var gamerTags = [GamerProfile]()
        if snapshot.hasChild("gamerTags") {
            let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
            for node in gamerTagsArray.children {
                guard let currentObj = node as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let currentTag = dict["gamerTag"] as? String ?? ""
                let currentGame = dict["game"] as? String ?? ""
                let console = dict["console"] as? String ?? ""
                let quizTaken = dict["quizTaken"] as? String ?? ""
                let gameId = dict["gameId"] as? String ?? ""

                if !currentTag.isEmpty, !currentGame.isEmpty, !console.isEmpty {
                    gamerTags.append(GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken, gameId: gameId))
                }
            }
        }

        // Badges
        var badges = [BadgeObj]()
        if snapshot.hasChild("badges") {
            let badgesArray = snapshot.childSnapshot(forPath: "badges")
            for node in badgesArray.children {
                guard let currentObj = node as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let name = dict["badgeName"] as? String ?? ""
                let desc = dict["badgeDesc"] as? String ?? ""
                badges.append(BadgeObj(badge: name, badgeDesc: desc))
            }
        }

        // Teams
        var teams = [EasyTeamObj]()
        if snapshot.hasChild("teams") {
            let teamsArray = snapshot.childSnapshot(forPath: "teams")
            for node in teamsArray.children {
                guard let currentObj = node as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let teamName = dict["teamName"] as? String ?? ""
                let teamId = dict["teamId"] as? String ?? ""
                let game = dict["gameName"] as? String ?? ""
                let teamCaptainId = dict["teamCaptainId"] as? String ?? ""
                let newTeam = dict["newTeam"] as? String ?? ""
                teams.append(EasyTeamObj(teamName: teamName, teamId: teamId, gameName: game, teamCaptainId: teamCaptainId, newTeam: newTeam))
            }
        }

        // Stats
        var currentStats = [StatObject]()
        if snapshot.hasChild("stats") {
            let statsArray = snapshot.childSnapshot(forPath: "stats")
            for node in statsArray.children {
                guard let currentObj = node as? DataSnapshot,
                      let dict = currentObj.value as? [String: Any] else { continue }
                let gameName = dict["gameName"] as? String ?? ""
                let playerLevelGame = dict["playerLevelGame"] as? String ?? ""
                let playerLevelPVP = dict["playerLevelPVP"] as? String ?? ""
                let killsPVP = dict["killsPVP"] as? String ?? ""
                let killsPVE = dict["killsPVE"] as? String ?? ""
                let statURL = dict["statURL"] as? String ?? ""
                let setPublic = dict["setPublic"] as? String ?? ""
                let authorized = dict["authorized"] as? String ?? ""
                let currentRank = dict["currentRank"] as? String ?? ""
                let totalRankedWins = dict["otalRankedWins"] as? String ?? ""
                let totalRankedLosses = dict["totalRankedLosses"] as? String ?? ""
                let totalRankedKills = dict["totalRankedKills"] as? String ?? ""
                let totalRankedDeaths = dict["totalRankedDeaths"] as? String ?? ""
                let mostUsedAttacker = dict["mostUsedAttacker"] as? String ?? ""
                let mostUsedDefender = dict["mostUsedDefender"] as? String ?? ""
                let gearScore = dict["gearScore"] as? String ?? ""
                let codKills = dict["codKills"] as? String ?? ""
                let codKd = dict["codKd"] as? String ?? ""
                let codLevel = dict["codLevel"] as? String ?? ""
                let codBestKills = dict["codBestKills"] as? String ?? ""
                let codWins = dict["codWins"] as? String ?? ""
                let codWlRatio = dict["codWlRatio"] as? String ?? ""
                let fortniteDuoStats = dict["fortniteDuoStats"] as? [String:String] ?? [:]
                let fortniteSoloStats = dict["fortniteSoloStats"] as? [String:String] ?? [:]
                let fortniteSquadStats = dict["fortniteSquadStats"] as? [String:String] ?? [:]
                let overwatchCasualStats = dict["overwatchCasualStats"] as? [String:String] ?? [:]
                let overwatchCompetitiveStats = dict["overwatchCompetitiveStats"] as? [String:String] ?? [:]
                let killsPerMatch = dict["killsPerMatch"] as? String ?? ""
                let matchesPlayed = dict["matchesPlayed"] as? String ?? ""
                let seasonWins = dict["seasonWins"] as? String ?? ""
                let seasonKills = dict["seasonKills"] as? String ?? ""
                let supImage = dict["supImage"] as? String ?? ""

                let s = StatObject(gameName: gameName)
                s.overwatchCasualStats = overwatchCasualStats
                s.overwatchCompetitiveStats = overwatchCompetitiveStats
                s.killsPerMatch = killsPerMatch
                s.matchesPlayed = matchesPlayed
                s.seasonWins = seasonWins
                s.seasonKills = seasonKills
                s.suppImage = supImage
                s.authorized = authorized
                s.playerLevelGame = playerLevelGame
                s.playerLevelPVP = playerLevelPVP
                s.killsPVP = killsPVP
                s.killsPVE = killsPVE
                s.statUrl = statURL
                s.setPublic = setPublic
                s.currentRank = currentRank
                s.totalRankedWins = totalRankedWins
                s.totalRankedLosses = totalRankedLosses
                s.totalRankedKills = totalRankedKills
                s.totalRankedDeaths = totalRankedDeaths
                s.mostUsedAttacker = mostUsedAttacker
                s.mostUsedDefender = mostUsedDefender
                s.gearScore = gearScore
                s.codKills = codKills
                s.codKd = codKd
                s.codLevel = codLevel
                s.codBestKills = codBestKills
                s.codWins = codWins
                s.codWlRatio = codWlRatio
                s.fortniteDuoStats = fortniteDuoStats
                s.fortniteSoloStats = fortniteSoloStats
                s.fortniteSquadStats = fortniteSquadStats
                currentStats.append(s)
            }
        }

        // Kick off invites fetch (unchanged side effect)
        AggregatedFirebaseService.shared.getUserGameInvites(uid: uId)

        // Build `User`
        let user = User(uId: uId)
        user.gamerTags = gamerTags
        user.teams = teams
        user.stats = currentStats
        user.teamInvites = currentTeamInvites
        user.games = games
        user.friends = friends
        user.pendingRequests = pendingRequests
        user.sentRequests = sentRequests
        user.gamerTag = gamerTag
        user.screenName = gamerTag
        user.messagingNotifications = (value["messagingNotifications"] as? Bool) ?? false
        user.pc = pc
        user.ps = ps
        user.xbox = xbox
        user.nintendo = nintendo
        user.bio = bio
        user.search = search
        user.notifications = notifications
        user.teamInviteRequests = dbRequests
        user.subscriptions = subscriptions
        user.competitions = competitions
        user.viewedAnnouncements = value["viewedAnnouncements"] as? [String] ?? []
        user.userLat = userLat
        user.userLong = userLong
        user.blockList = Array(blockList.keys)
        user.restrictList = Array(restrictList.keys)
        user.reviews = reviews
        user.badges = badges
        user.dailyCheck = dailyCheck
        user.userAbout = aboutMe
        user.cachedRecommendedUids = cachedRecommendedUids
        user.receivedAnnouncements = receivedAnnouncements
        user.gamingExperience = gamingExperience
        user.googleApiRefreshToken = googleApiRefreshToken
        user.googleApiAccessToken = googleApiAccessToken
        user.following = following
        user.followers = followers
        user.followerAnnouncements = followerAnnouncements
        user.viewedPosts = viewedPosts
        user.myPosts = myPosts
        user.currentSelectedPokoId = currentSelectedPokoId
        user.pokos = ownedPokos
        user.onlineStatus = "online"
        user.userLookingFor = lookingForArray
        user.twitchConnect = twitchConnect
        user.instagramConnect = instagramConnect
        user.discordConnect = discordConnect
        user.tiktokConnect = tiktokConnect
        user.tagline = tagline
        user.twitterConnect = twitterConnect
        user.spotlightVideoIds = showcaseVideoIds
        user.highlightVideoId = highlightVideoId ?? ""
        user.communities = communities

        return user
    }

    // MARK: - Parsing helpers

    private func readFriendObjects(from snapshot: DataSnapshot, path: String) -> [FriendObject] {
        guard snapshot.hasChild(path) else { return [] }
        let node = snapshot.childSnapshot(forPath: path)
        var result = [FriendObject]()
        for child in node.children {
            guard let snap = child as? DataSnapshot,
                  let dict = snap.value as? [String: Any] else { continue }
            let gamerTag = dict["gamerTag"] as? String ?? ""
            let date = dict["date"] as? String ?? ""
            let uid = dict["uid"] as? String ?? ""
            result.append(FriendObject(gamerTag: gamerTag, date: date, uid: uid))
        }
        return result
    }

    private func readFriendRequests(from snapshot: DataSnapshot, path: String) -> [FriendRequestObject] {
        guard snapshot.hasChild(path) else { return [] }
        let node = snapshot.childSnapshot(forPath: path)
        var result = [FriendRequestObject]()
        for child in node.children {
            guard let snap = child as? DataSnapshot,
                  let dict = snap.value as? [String: Any] else { continue }
            let gamerTag = dict["gamerTag"] as? String ?? ""
            let date = dict["date"] as? String ?? ""
            let uid = dict["uid"] as? String ?? ""
            result.append(FriendRequestObject(gamerTag: gamerTag, date: date, uid: uid))
        }
        return result
    }

    private func parseFAQuestion(from dict: [String: Any]) -> FAQuestion {
        let fa = FAQuestion(question: (dict["question"] as? String) ?? "")
        fa.questionNumber = (dict["questionNumber"] as? String) ?? ""
        fa.question = (dict["question"] as? String) ?? ""
        fa.option1 = (dict["option1"] as? String) ?? ""
        fa.option1Description = (dict["option1Description"] as? String) ?? ""
        fa.question1SetURL = (dict["question1SetURL"] as? String) ?? ""
        fa.option2 = (dict["option2"] as? String) ?? ""
        fa.option2Description = (dict["option2Description"] as? String) ?? ""
        fa.question2SetURL = (dict["question2SetURL"] as? String) ?? ""
        fa.option3 = (dict["option3"] as? String) ?? ""
        fa.option3Description = (dict["option3Description"] as? String) ?? ""
        fa.question3SetURL = (dict["question3SetURL"] as? String) ?? ""
        fa.option4 = (dict["option4"] as? String) ?? ""
        fa.option4Description = (dict["option4Description"] as? String) ?? ""
        fa.question4SetURL = (dict["question4SetURL"] as? String) ?? ""
        fa.option5 = (dict["option5"] as? String) ?? ""
        fa.option5Description = (dict["option5Description"] as? String) ?? ""
        fa.question5SetURL = (dict["question5SetURL"] as? String) ?? ""
        fa.option6 = (dict["option6"] as? String) ?? ""
        fa.option6Description = (dict["option6Description"] as? String) ?? ""
        fa.option7 = (dict["option7"] as? String) ?? ""
        fa.option7Description = (dict["option7Description"] as? String) ?? ""
        fa.option8 = (dict["option8"] as? String) ?? ""
        fa.option8Description = (dict["option8Description"] as? String) ?? ""
        fa.option9 = (dict["option9"] as? String) ?? ""
        fa.option9Description = (dict["option9Description"] as? String) ?? ""
        fa.option10 = (dict["option10"] as? String) ?? ""
        fa.option10Description = (dict["option10Description"] as? String) ?? ""
        fa.required = (dict["required"] as? String) ?? ""
        fa.acceptMultiple = (dict["acceptMultiple"] as? String) ?? ""
        fa.questionDescription = (dict["questionDescription"] as? String) ?? ""
        fa.teamNeedQuestion = (dict["teamNeedQuestion"] as? String) ?? "false"
        fa.optionsUrl = (dict["optionsUrl"] as? String) ?? ""
        fa.maxOptions = (dict["maxOptions"] as? String) ?? ""
        fa.answer = (dict["answer"] as? String) ?? ""
        fa.answerArray = (dict["answerArray"] as? [String]) ?? []
        return fa
    }

    // MARK: - Legacy helpers you had

    private func strings(from raw: Any?) -> [String] {
        switch raw {
        case let a as [String]: return a
        case let d as [String: Any]: return d.values.compactMap { $0 as? String }
        default: return []
        }
    }

    func stringToDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm zzz"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: str) ?? Date(timeIntervalSince1970: 0)
    }
}

// MARK: - Notification name (optional)
extension Notification.Name {
    static let userProviderDidUpdateUser = Notification.Name("userProviderDidUpdateUser")
}
