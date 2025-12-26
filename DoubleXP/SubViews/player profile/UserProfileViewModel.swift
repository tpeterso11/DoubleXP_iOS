//
//  UserProfileViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI
import FirebaseDatabase

// MARK: - UserProfileViewModel

@MainActor
class UserProfileViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var userProfile: UserProfile?
    @Published var isLoading: Bool = true
    @Published var isFollowing: Bool = false
    @Published var isOnline: Bool = false
    @Published var error: String?
    private var userUpdateObserver: NSObjectProtocol?
    
    // MARK: - Private State
    private var uid: String = ""
    private var userForProfile: User?
    private var profilePayload: [FreeAgentObject] = []
    
    // Store API data for use in buildUserProfile
    private var cachedQuizData: QuizData?
    private var cachedProximityData: ProximityData?
    
    // MARK: - Dependencies
    private let friendsManager = FriendsManager()
    
    // MARK: - Computed Properties
    var isOwnProfile: Bool {
        guard let current = UserProvider.shared.currentUser else { return false }
        return uid == current.uId
    }
    
    // MARK: - Initialization
    init(uid: String? = nil) {
        if let uid = uid {
            self.uid = uid
        } else {
            self.uid = ""
        }
        
        userUpdateObserver = NotificationCenter.default.addObserver(
            forName: .userProviderDidUpdateUser,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let updatedUser = UserProvider.shared.getUser() else { return }
                
                if updatedUser.uId == self.uid {
                    await self.buildUserProfile(
                        from: updatedUser,
                        quizData: self.cachedQuizData,
                        proximityData: self.cachedProximityData
                    )
                }
            }
        }
    }
    
    deinit {
        if let observer = userUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    func loadProfile() async {
        guard !uid.isEmpty else {
            error = "No user ID provided"
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        let requestManager = UserProfileRequestManager.shared
        let currentUserId = UserProvider.shared.currentUser?.uId
        
        do {
            // Fetch complete profile data from API
            let profileResponse = try await requestManager.fetchUserProfile(
                userId: uid,
                currentUserId: currentUserId,
                maxDistanceMiles: 100
            )
            
            // Convert API UserData to your User object
            let user = convertAPIUserToLocalUser(profileResponse.user)
            self.userForProfile = user
            
            // Cache quiz and proximity data for later use
            self.cachedQuizData = profileResponse.quizzes
            self.cachedProximityData = profileResponse.proximity
            
            // Load Free Agent profiles (still from Firebase - separate concern)
            self.loadProfiles(user: user)
            
            // Log partial failures if any
            if let errors = profileResponse.errors, !errors.notes.isEmpty {
                print("⚠️ [UserProfile] Partial data loaded: \(errors.notes.joined(separator: ", "))")
            }
            
        } catch UserProfileError.userNotFound {
            self.error = "User not found"
            self.isLoading = false
            print("❌ [UserProfile] User not found: \(uid)")
            
        } catch {
            self.error = "Failed to load profile: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ [UserProfile] Load failed: \(error)")
        }
    }
    
    func followUser() {
        guard let currentUser = UserProvider.shared.currentUser,
              let otherUser = userForProfile else { return }
        
        isLoading = true
        // follow logic here…
    }
    
    func openMessaging() {
        guard let userForProfile = userForProfile else { return }
        // AppDelegate.shared.currentLanding?.navigateToMessaging(...)
    }
    
    // MARK: - Convert API UserData to Local User Object
    
    private func convertAPIUserToLocalUser(_ apiUser: UserData) -> User {
        let user = User(uId: apiUser.uId)
        
        // Core identity
        user.screenName = apiUser.screenName
        user.gamerTag = apiUser.gamerTag
        user.bio = apiUser.bio
        user.tagline = apiUser.tagline
        user.joinedAt = apiUser.joinedAt
        
        // Profile details
        user.selectedAge = apiUser.selectedAge
        user.primaryLanguage = apiUser.primaryLanguage
        user.secondaryLanguage = apiUser.secondaryLanguage
        user.gamingExperience = apiUser.gamingExperience
        user.timezone = apiUser.timezone
        
        // Platform flags
        user.ps = apiUser.ps
        user.xbox = apiUser.xbox
        user.pc = apiUser.pc
        user.mobile = apiUser.mobile
        user.nintendo = apiUser.nintendo
        
        // Social connections
        user.twitchConnect = apiUser.twitchConnect
        user.instagramConnect = apiUser.instagramConnect
        user.discordConnect = apiUser.discordConnect
        user.tiktokConnect = apiUser.tiktokConnect
        user.twitterConnect = apiUser.twitterConnect
        
        // Settings
        user.onlineStatus = apiUser.onlineStatus
        user.search = apiUser.search
        user.notifications = apiUser.notifications
        user.messagingNotifications = apiUser.messagingNotifications
        
        // Collections
        user.games = apiUser.games
        user.pokos = apiUser.pokos
        user.communities = apiUser.communities ?? []
        user.userLookingFor = apiUser.userLookingFor
        user.userAbout = apiUser.userAbout
        user.blockList = apiUser.blockList ?? []
        user.restrictList = apiUser.restrictList ?? []
        
        // Social connections (convert string arrays to objects if needed)
        /*user.followers = (apiUser.followers ?? []).map { followerId in
            let friend = FriendObject()
            friend.friendId = followerId
            return friend
        }
        user.following = (apiUser.following ?? []).map { followingId in
            let friend = FriendObject()
            friend.friendId = followingId
            return friend
        }*/
        
        // Content
        user.highlightVideoId = apiUser.highlightVideoId ?? ""
        user.spotlightVideoIds = apiUser.spotlightVideoIds ?? []
        
        // Location (optional)
        if let lat = apiUser.userLat, let long = apiUser.userLong {
            user.userLat = lat
            user.userLong = long
        }
        
        return user
    }
    
    // MARK: - Private Methods - Data Loading
    
    private func loadProfiles(user: User) {
        let ref = Database.database().reference()
            .child("Free Agents V2")
            .child(user.uId)
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            self.profilePayload.removeAll()
            
            if snapshot.exists() {
                for profile in snapshot.children {
                    if let currentProfile = profile as? DataSnapshot,
                       let dict = currentProfile.value as? [String: Any] {
                        
                        let game = dict["game"] as? String ?? ""
                        let consoles = dict["consoles"] as? [String] ?? []
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let competitionId = dict["competitionId"] as? String ?? ""
                        let userId = dict["userId"] as? String ?? ""
                        
                        var questions: [FAQuestion] = []
                        if let questionList = dict["questions"] as? [[String: Any]] {
                            for questionDict in questionList {
                                let faQuestion = self.parseQuestion(from: questionDict)
                                questions.append(faQuestion)
                            }
                        }
                        
                        let result = FreeAgentObject(
                            gamerTag: gamerTag,
                            competitionId: competitionId,
                            consoles: consoles,
                            game: game,
                            userId: userId,
                            questions: questions
                        )
                        self.profilePayload.append(result)
                    }
                }
            }
            
            Task { @MainActor in
                await self.buildUserProfile(
                    from: user,
                    quizData: self.cachedQuizData,
                    proximityData: self.cachedProximityData
                )
            }
        }
    }
    
    private func parseQuestion(from dict: [String: Any]) -> FAQuestion {
        let questionString = dict["question"] as? String ?? ""
        let faQuestion = FAQuestion(question: questionString)
        
        faQuestion.questionNumber = dict["questionNumber"] as? String ?? ""
        faQuestion.option1 = dict["option1"] as? String ?? ""
        faQuestion.option2 = dict["option2"] as? String ?? ""
        faQuestion.option3 = dict["option3"] as? String ?? ""
        faQuestion.option4 = dict["option4"] as? String ?? ""
        faQuestion.option5 = dict["option5"] as? String ?? ""
        faQuestion.required = dict["required"] as? String ?? ""
        faQuestion.questionDescription = dict["questionDescription"] as? String ?? ""
        faQuestion.answer = dict["answer"] as? String ?? ""
        faQuestion.answerArray = dict["answerArray"] as? [String] ?? []
        
        return faQuestion
    }
    
    private let memberSinceFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        df.locale = .current
        return df
    }()
    
    // MARK: - Games hydration helper
    
    func buildGameItems(for user: User) async -> [GameItem] {
        let cachedGames = GameStorageManager.shared.getAllGames()
        let gamesBySlug = cachedGames.toDictionaryBySlug()
        let gamesByName = cachedGames.toDictionaryById()
        
        func resolveCachedGame(for key: String) -> GamerConnectGame? {
            let k = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return gamesBySlug[k] ?? gamesByName[k]
        }
        
        var remoteResolved: [String: GamerConnectGame] = [:]
        var items: [GameItem] = []
        items.reserveCapacity(user.games.count)
        
        for rawKey in user.games {
            let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let keyLower = key.lowercased()
            
            if let localGame = resolveCachedGame(for: key) {
                items.append(
                    GameItem(
                        id: localGame.id,
                        name: localGame.gameName,
                        coverImage: localGame.imageUrl ?? "",
                        slug: localGame.slug
                    )
                )
                continue
            }
            
            if let cachedRemote = remoteResolved[keyLower] {
                items.append(
                    GameItem(
                        id: cachedRemote.id,
                        name: cachedRemote.gameName,
                        coverImage: cachedRemote.imageUrl ?? "",
                        slug: cachedRemote.slug
                    )
                )
                continue
            }
            
            do {
                let remoteGames = try await GameRequestManager.shared.searchGamesFromAPI(slug: key)
                if let first = remoteGames.first {
                    remoteResolved[keyLower] = first
                    GameStorageManager.shared.save(game: first)
                    items.append(
                        GameItem(
                            id: first.id,
                            name: first.gameName,
                            coverImage: first.imageUrl ?? "",
                            slug: first.slug
                        )
                    )
                } else {
                    items.append(
                        GameItem(
                            id: "",
                            name: key,
                            coverImage: "",
                            slug: ""
                        )
                    )
                }
            } catch {
                print("⚠️ [buildGameItems] searchGamesFromAPI failed for '\(key)': \(error)")
                items.append(
                    GameItem(
                        id: "",
                        name: key,
                        coverImage: "",
                        slug: ""
                    )
                )
            }
        }
        
        return items
    }
    
    // MARK: - Build UserProfile for SwiftUI View
    
    func buildUserProfile(from user: User, quizData: QuizData? = nil, proximityData: ProximityData? = nil) async {
        let loggedInUser = UserProvider.shared.currentUser
        
        let isFollowingUser: Bool
        if let current = loggedInUser {
            isFollowingUser = friendsManager.isFollower(user: user, currentUser: current)
        } else {
            isFollowingUser = false
        }
        self.isFollowing = isFollowingUser
        
        self.isOnline = user.onlineStatus == "online"
        
        var socials: [SocialLink] = []
        if !user.discordConnect.isEmpty {
            socials.append(SocialLink(platform: .discord, handle: user.discordConnect))
        }
        if !user.twitchConnect.isEmpty {
            socials.append(SocialLink(platform: .twitch, handle: user.twitchConnect))
        }
        if !user.instagramConnect.isEmpty {
            socials.append(SocialLink(platform: .instagram, handle: user.instagramConnect))
        }
        if !user.tiktokConnect.isEmpty {
            socials.append(SocialLink(platform: .tiktok, handle: user.tiktokConnect))
        }
        if !user.twitterConnect.isEmpty {
            socials.append(SocialLink(platform: .twitter, handle: user.twitterConnect))
        }
     
        var aboutMeTags: [AboutMeTag] = []
        for about in user.userAbout {
            let isMatch = loggedInUser?.userAbout.contains(about) ?? false
            aboutMeTags.append(AboutMeTag(text: about, isMatch: isMatch))
        }
        
        let badges: [Badge] = user.badges.enumerated().map { index, badgeObj in
            let tier: BadgeTier = {
                switch index % 4 {
                case 0: return .gold
                case 1: return .silver
                case 2: return .bronze
                default: return .special
                }
            }()
            return Badge(
                emoji: badgeObj.badgeName ?? "🏆",
                name: badgeObj.badgeDesc ?? "",
                tier: tier
            )
        }
        
        let cachedGames = GameStorageManager.shared.getAllGames()
        let gamesBySlug = cachedGames.toDictionaryBySlug()
        let gamesByName = cachedGames.toDictionaryById()
        
        func resolveGame(for key: String) -> GamerConnectGame? {
            let k = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return gamesBySlug[k] ?? gamesByName[k]
        }
        
        // Build all game items
        let allGameItems = await buildGameItems(for: user)
        
        // Date formatter for "YYYY-MM-DD" format
        let releaseDateFormatter = ISO8601DateFormatter()
        releaseDateFormatter.formatOptions = [.withFullDate]
        
        // Separate released vs upcoming/wishlist games
        let releasedGames = allGameItems.filter { item in
            if let fullGame = resolveGame(for: item.slug.isEmpty ? item.name : item.slug) {
                if let releaseDateString = fullGame.releaseDate,
                   !releaseDateString.isEmpty,
                   let releaseDate = releaseDateFormatter.date(from: releaseDateString) {
                    return releaseDate <= Date()
                }
                return true
            }
            return true
        }
        
        let wishlistGames = allGameItems.filter { item in
            if let fullGame = resolveGame(for: item.slug.isEmpty ? item.name : item.slug) {
                if let releaseDateString = fullGame.releaseDate,
                   !releaseDateString.isEmpty,
                   let releaseDate = releaseDateFormatter.date(from: releaseDateString) {
                    return releaseDate > Date()
                }
            }
            return false
        }
        
        let communities: [ProfileCommunity] = (user.communities ?? []).compactMap { key -> ProfileCommunity? in
            guard let fullGame = resolveGame(for: key) else {
                return nil
            }

            return ProfileCommunity(
                id: fullGame.slug,
                name: fullGame.gameName,
                imageUrl: fullGame.imageUrl,
                memberCount: 0,
                gameSlug: fullGame.slug,
                gameName: fullGame.gameName,
                role: .member
            )
        }
        
        let recentUploads: [ContentItem] = user.posts.prefix(6).map { post in
            ContentItem(
                thumbnailImage: post.youtubeImg ?? "",
                isVideo: !(post.youtubeId ?? "").isEmpty
            )
        }
        
        let commonGames: [GameItem]
        if let current = loggedInUser {
            let commonKeys = Set(user.games).intersection(Set(current.games))
            commonGames = commonKeys.map { key in
                if let fullGame = resolveGame(for: key) {
                    return GameItem(
                        id: fullGame.id,
                        name: fullGame.gameName,
                        coverImage: fullGame.imageUrl ?? "",
                        slug: fullGame.slug
                    )
                } else {
                    return GameItem(
                        id: "",
                        name: key,
                        coverImage: "",
                        slug: ""
                    )
                }
            }
        } else {
            commonGames = []
        }
        
        let headerVideoURL: String? = user.youtubeVideos
            .first(where: { $0.youtubeFavorite == "true" })?.youtubeId
            ?? user.youtubeVideos.first?.youtubeId
        
        let tagline: String
        if !user.tagline.isEmpty {
            tagline = user.tagline
        } else {
            let joinedDate = Date(timeIntervalSince1970: user.joinedAt / 1000.0)
            let memberSinceString = memberSinceFormatter.string(from: joinedDate)
            tagline = "Member since \(memberSinceString)"
        }
        
        // Build quiz items from API data if available
        var quizItems: [ProfileQuizItem] = []
        if let quizData = quizData {
            for completion in quizData.completions {
                if let quizDetail = quizData.quizDetails[completion.quizId] {
                    let profileQuizItem = completion.toProfileQuizItem(with: quizDetail)
                    quizItems.append(profileQuizItem)
                }
            }
            quizItems.sort { $0.completedDate > $1.completedDate }
        }
        
        // Get proximity distance from API data
        let proximityDistance = proximityData?.distanceMiles
        
        let profile = UserProfile(
            id: user.uId,
            username: user.screenName,
            handle: tagline,
            isOnline: isOnline,
            headerImageURL: nil,
            headerVideoURL: headerVideoURL,
            pokoAvatar: PokoProvider.shared.userSelectedPoko?.headshotUrl ?? "",
            pokoName: PokoProvider.shared.userSelectedPoko?.name ?? "",
            bio: user.bio.isEmpty ? nil : user.bio,
            followerCount: user.followers.count,
            followingCount: user.following.count,
            gamesCount: user.games.count,
            isOwnProfile: isOwnProfile,
            isFollowing: isFollowingUser,
            socials: socials,
            lookingFor: user.userLookingFor,
            aboutMe: aboutMeTags,
            badges: badges,
            games: releasedGames,
            wishlistGames: wishlistGames,
            pokos: PokoProvider.shared.allUserPokos,
            recentUploads: recentUploads,
            commonGames: commonGames,
            communities: communities,
            highlightedVideo: user.highlightVideoId,
            quizzes: quizItems,
            proximityDistance: proximityDistance
        )
        
        self.userProfile = profile
        self.isLoading = false
    }
}
