//
//  EditProfileViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/27/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class EditProfileViewModel: ObservableObject {
    // Loading state
    @Published var isLoading: Bool = true
    @Published var error: String?

    // Saving state
    @Published var isSaving: Bool = false

    // Basic info
    @Published var displayName: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var handle: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var tagline: String = "" {
        didSet {
            let maxLength = 500
            if tagline.count > maxLength {
                tagline = String(tagline.prefix(maxLength))
            }
            markDirtyIfNeeded()
        }
    }
    @Published var bio: String = "" {
        didSet {
            let maxCharacters = 280
            if bio.count > maxCharacters {
                bio = String(bio.prefix(maxCharacters))
            }

            let maxLines = 6
            let lines = bio.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            if lines.count > maxLines {
                let limited = lines.prefix(maxLines)
                bio = limited.joined(separator: "\n")
            }

            markDirtyIfNeeded()
        }
    }

    // Socials
    @Published var discord: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var twitter: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var instagram: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var tiktok: String = "" {
        didSet { markDirtyIfNeeded() }
    }
    @Published var twitch: String = "" {
        didSet { markDirtyIfNeeded() }
    }

    // Google - simplified to just track connection status
    @Published var isGoogleConnected: Bool = false
    @Published var googleEmail: String = ""
    @Published var videoCount: Int = 0  // Just for display purposes
    
    // Google connection observer
    private var googleConnectionCancellable: AnyCancellable?

    // Counts
    @Published var gamesCount: Int = 0
    @Published var aboutMeCount: Int = 0
    @Published var lookingForCount: Int = 0

    // Navigation states
    @Published var showPokoSelector: Bool = false
    @Published var showPokoGallery: Bool = false
    @Published var showGamesEditor: Bool = false
    @Published var showAboutMeEditor: Bool = false
    @Published var showLookingForEditor: Bool = false

    // Poko image
    @Published var pokoImage: UIImage?
    @Published var isLoadingPokoImage: Bool = false
    
    //@Published var selectedGameIds: [String] = []
    @Published var selectedGameSlugs: [String] = []
    @Published var selectedGames: [GamerConnectGame] = []
    private var pokoUpdateObserver: NSObjectProtocol?
    private var pendingGamesList = [String]()

    // Dirty tracking
    @Published private(set) var hasChanges: Bool = false

    private struct FormState: Equatable {
        let displayName: String
        let handle: String
        let tagline: String
        let bio: String
        let discord: String
        let twitter: String
        let instagram: String
        let tiktok: String
        let twitch: String
    }

    private var initialState: FormState?
    private var isInitializing: Bool = false
    private var didLoadOnce = false

    // Listen for user updates
    private var userUpdateObserver: NSObjectProtocol?

    // MARK: - Init / Deinit

    init() {
        setupObservers()
        setupGoogleConnectionObserver()
    }
    
    private func setupObservers() {
        userUpdateObserver = NotificationCenter.default.addObserver(
            forName: .userProviderDidUpdateUser,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                guard let updatedUser = UserProvider.shared.getUser() else { return }
                self.updateCounts(from: updatedUser)
            }
        }
        
        pokoUpdateObserver = NotificationCenter.default.addObserver(
            forName: .userPokoDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self = self else { return }
                if let poko = notification.userInfo?["poko"] as? Poko {
                    self.updatePokoImage(from: poko)
                } else {
                    self.loadPokoImage()
                }
            }
        }
    }
    
    /// Subscribe to Google connection state changes from YouTubeRequestManager
    private func setupGoogleConnectionObserver() {
        googleConnectionCancellable = YouTubeRequestManager.shared.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .connected(let email):
                    self.isGoogleConnected = true
                    self.googleEmail = email
                    print("📱 [EditProfile] Google connected: \(email)")
                    // Fetch video count for display
                    Task {
                        await self.fetchVideoCount()
                    }
                    
                case .disconnected:
                    self.isGoogleConnected = false
                    self.googleEmail = ""
                    self.videoCount = 0
                    print("📱 [EditProfile] Google disconnected")
                    
                case .connecting:
                    print("📱 [EditProfile] Google connecting...")
                    
                case .error(let message):
                    print("📱 [EditProfile] Google error: \(message)")
                }
            }
    }

    deinit {
        if let observer = userUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let pokoObserver = pokoUpdateObserver {
            NotificationCenter.default.removeObserver(pokoObserver)
        }
        googleConnectionCancellable?.cancel()
    }

    // MARK: - Public

    func load() {
        guard !didLoadOnce else { return }
        didLoadOnce = true

        isLoading = true
        error = nil

        if let user = UserProvider.shared.getUser() {
            apply(user: user)
            loadPokoImage()
            checkGoogleConnectionStatus()
            isLoading = false
        } else {
            Task {
                do {
                    try await UserProvider.shared.reload()
                    if let reloaded = UserProvider.shared.getUser() {
                        await MainActor.run {
                            self.apply(user: reloaded)
                            self.loadPokoImage()
                            self.checkGoogleConnectionStatus()
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            self.error = "Unable to load user"
                            self.isLoading = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    /// Check and restore Google connection status on load
    private func checkGoogleConnectionStatus() {
        Task {
            await YouTubeRequestManager.shared.restorePreviousSignIn()
            
            // Sync state after restore
            let state = YouTubeRequestManager.shared.connectionState
            if case .connected(let email) = state {
                self.isGoogleConnected = true
                self.googleEmail = email
                await fetchVideoCount()
            }
        }
    }
    
    /// Fetch video count for display in the Google section
    private func fetchVideoCount() async {
        guard let uid = UserProvider.shared.getUser()?.uId else { return }
        
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)
            .child("videoSettings")
        
        do {
            let snapshot = try await ref.getData()
            
            guard let data = snapshot.value as? [String: Any] else {
                self.videoCount = 0
                return
            }
            
            var count = 0
            if data["highlightVideoId"] as? String != nil {
                count += 1
            }
            if let showcaseIds = data["showcaseVideoIds"] as? [String] {
                count += showcaseIds.count
            }
            
            self.videoCount = count
            print("📱 [EditProfile] Video count: \(count)")
            
        } catch {
            print("📱 [EditProfile] Error fetching video count: \(error)")
            self.videoCount = 0
        }
    }
    
    /// Refresh Google data (called when returning from video manager)
    func refreshGoogleData() async {
        guard isGoogleConnected else { return }
        await fetchVideoCount()
    }

    /// Save fields back to Firebase "Users" for the current user.
    func saveProfile(completion: ((Bool) -> Void)? = nil) {
        guard !isSaving else { return }

        guard let user = UserProvider.shared.getUser() else {
            error = "User not loaded"
            completion?(false)
            return
        }

        isSaving = true
        error = nil

        let uid = user.uId
        let ref = Database.database().reference()
            .child("Users")
            .child(uid)

        var updates: [String: Any] = [:]

        // Trim whitespace before saving
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTagline = tagline.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDiscord = discord.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstagram = instagram.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTwitch = twitch.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTwitter = twitter.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTikTok = tiktok.trimmingCharacters(in: .whitespacesAndNewlines)

        updates["screenName"] = trimmedDisplayName
        updates["gamerTag"] = trimmedDisplayName

        updates["bio"] = trimmedBio
        if !trimmedTagline.isEmpty {
            updates["tagline"] = trimmedTagline
        } else {
            let joinedDate = Date(timeIntervalSince1970: user.joinedAt / 1000.0)
            let memberSinceString = memberSinceFormatter.string(from: joinedDate)
            updates["tagline"] = "Member since \(memberSinceString)"
        }

        updates["discordConnect"] = trimmedDiscord
        updates["instagramConnect"] = trimmedInstagram
        updates["twitchConnect"] = trimmedTwitch
        updates["twitterConnect"] = trimmedTwitter
        updates["tiktokConnect"] = trimmedTikTok
        updates["games"] = self.pendingGamesList

        ref.updateChildValues(updates) { [weak self] error, _ in
            guard let self = self else { return }

            Task { @MainActor in
                self.isSaving = false

                if let error = error {
                    self.error = error.localizedDescription
                    completion?(false)
                    return
                }

                _ = await UserProvider.shared.loadUser(uid: uid)

                // 🔹 Tell everyone the user object changed
                NotificationCenter.default.post(name: .userProviderDidUpdateUser, object: nil)

                let snapshot = self.currentFormState()
                self.initialState = snapshot
                self.hasChanges = false

                completion?(true)
            }
        }
    }

    private let memberSinceFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        df.locale = .current
        return df
    }()

    // MARK: - Private helpers

    private func apply(user: User) {
        isInitializing = true

        self.displayName = user.screenName
        self.handle = user.screenName
        self.bio = user.bio
        self.tagline = user.tagline

        self.discord = user.discordConnect
        self.instagram = user.instagramConnect
        self.twitch = user.twitchConnect
        self.twitter = ""
        self.tiktok = ""

        // Check Google connection from tokens stored in Firebase
        self.isGoogleConnected = !user.googleApiAccessToken.isEmpty || !user.googleApiRefreshToken.isEmpty
        self.googleEmail = ""

        self.gamesCount = user.games.count
        self.aboutMeCount = user.userAbout.count
        self.lookingForCount = user.userLookingFor.count

        let snapshot = currentFormState()
        self.initialState = snapshot
        self.hasChanges = false

        isInitializing = false
    }

    private func currentFormState() -> FormState {
        FormState(
            displayName: displayName,
            handle: handle,
            tagline: tagline,
            bio: bio,
            discord: discord,
            twitter: twitter,
            instagram: instagram,
            tiktok: tiktok,
            twitch: twitch
        )
    }

    private func markDirtyIfNeeded() {
        if isInitializing { return }
        guard let initial = initialState else {
            hasChanges = true
            return
        }
        hasChanges = (currentFormState() != initial)
    }

    private func updateCounts(from user: User) {
        self.gamesCount = user.games.count
        self.aboutMeCount = user.userAbout.count
        self.lookingForCount = user.userLookingFor.count
    }

    private func loadPokoImage() {
        guard
            let poko = PokoProvider.shared.userSelectedPoko,
            let url = URL(string: poko.headshotUrl)
        else { return }

        isLoadingPokoImage = true

        Task {
            let img = await ImageCache.shared.image(for: url)
            await MainActor.run {
                self.pokoImage = img
                self.isLoadingPokoImage = false
            }
        }
    }
    
    func updateSelectedGames(_ games: [GamerConnectGame]) {
        // Get the user's existing games (stored as [String] – slugs or names)
        guard let currentUser = UserProvider.shared.currentUser else { return }
        let currentGames = currentUser.games  // [String]

        // Normalize existing keys (e.g. slug/string)
        var existingKeys = Set(currentGames.map { $0.lowercased() })

        // Start with what they already have
        var mergedGames = currentGames

        // Add only new, non-duplicate games from the `games` parameter
        for game in games {
            let key = game.slug.lowercased()    // or game.gameName.lowercased() if that’s what you store
            if !existingKeys.contains(key) {
                mergedGames.append(game.slug)   // store the slug in user.games
                existingKeys.insert(key)
            }
        }

        // Update local state based on the merged list
        self.gamesCount = mergedGames.count
        self.pendingGamesList = mergedGames
        self.hasChanges = true
    }
    
    func updatePokoImage(from poko: Poko) {
        guard let url = URL(string: poko.headshotUrl) else { return }
        
        isLoadingPokoImage = true
        
        Task {
            let img = await ImageCache.shared.image(for: url)
            await MainActor.run {
                self.pokoImage = img
                self.isLoadingPokoImage = false
            }
        }
    }
}

// MARK: - Global helper

func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

extension Notification.Name {
    static let userPokoDidChange = Notification.Name("userPokoDidChange")
}
