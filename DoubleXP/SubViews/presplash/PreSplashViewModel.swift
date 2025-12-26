//
//  PreSplashViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI
import AVKit

@MainActor
final class PreSplashViewModel: ObservableObject {

    // Published state for the UI
    @Published var isBlockingForData: Bool = false

    // Internal flags
    private var videoFinished: Bool = false
    private var dataLoaded: Bool = false
    private var isReturningUser: Bool = false

    // Completion callback back to RootView
    private var completion: ((Bool) -> Void)?

    // Polling / timing
    private var pollTask: Task<Void, Never>?
    private var startTime: Date = Date()

    /// Approximate max length of the splash video (seconds).
    private let videoSoftTimeout: TimeInterval = 10.0

    /// Hard timeout for startup data (seconds).
    private let dataHardTimeout: TimeInterval = 30.0

    // MARK: - Public API

    /// Entry point from the view. Stores the completion and kicks off data work + polling.
    func start(onFinished: @escaping (Bool) -> Void) {
        completion = onFinished
        startTime = Date()
        startPolling()

        if let userId = UserDefaults.standard.string(forKey: "userId"),
           !userId.isEmpty {
            // Returning user – we need startup data.
            isReturningUser = true
            Task {
                await loadAllStartupData(uid: userId)
            }
        } else {
            // New user – no data dependency.
            isReturningUser = false
            dataLoaded = true
            checkReady()
        }
    }

    /// Called by the video layer once playback hits the end (happy path).
    func markVideoFinished() {
        videoFinished = true
        checkReady()
    }

    // MARK: - Private helpers

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while let self = self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    self.pollTick()
                }
            }
        }
    }

    private func pollTick() {
        let elapsed = Date().timeIntervalSince(startTime)

        if !videoFinished && elapsed >= videoSoftTimeout {
            print("⏰ PreSplash: videoSoftTimeout reached, forcing videoFinished = true")
            videoFinished = true
        }

        if isReturningUser && !dataLoaded && elapsed >= dataHardTimeout {
            print("⏰ PreSplash: dataHardTimeout reached, treating data as loaded")
            dataLoaded = true
        }

        checkReady()
    }

    private func loadAllStartupData(uid: String) async {
        // Load user first - returns nil if failed
        guard let user = await UserProvider.shared.loadUser(uid: uid) else {
            print("❌ No user, cannot continue")
            return
        }
        
        // Also set on AppDelegate if needed
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            await MainActor.run {
                appDelegate.currentUser = user
            }
        }
        
        print("✅ User loaded: \(user.gamerTag), has \(user.pokos.count) pokos")
        
        // Load everything else in parallel - INCLUDING XP
        await withTaskGroup(of: Void.self) { group in
            // Existing startup tasks
            group.addTask { await GameAPIService.shared.fetchStartupGames() }
            group.addTask { await NewsAPIService.shared.ensureInitialPage() }
            group.addTask { await LanguageProvider.shared.fetchLanguages() }
            group.addTask { await PokoProvider.shared.loadPokos() }
            group.addTask { await ABTestManager.shared.loadAssignments(for: user.uId) }
            
            // ✅ NEW: Load XP data on startup
            // XPManager will:
            // 1. Fetch current XP from Firebase
            // 2. Calculate current level
            // 3. Start observing for live updates
            // 4. Check/reset daily XP cap
            group.addTask {
                await XPManager.shared.loadXP(for: uid)
            }
        }

        dataLoaded = true
        isBlockingForData = false
        checkReady()
    }

    private func checkReady() {
        if isReturningUser {
            if videoFinished && !dataLoaded {
                if !isBlockingForData {
                    print("⏳ PreSplash: video finished, waiting on data → show spinner")
                }
                isBlockingForData = true
                return
            }

            if videoFinished && dataLoaded {
                print("✅ PreSplash: video + data ready. Proceeding to feed.")
                completeIfNeeded()
                return
            }
        } else {
            if videoFinished {
                print("✅ PreSplash: new user video finished. Proceeding to login.")
                completeIfNeeded()
                return
            }
        }
    }

    private func completeIfNeeded() {
        guard let completion = completion else { return }
        self.completion = nil
        pollTask?.cancel()
        pollTask = nil
        isBlockingForData = false
        completion(isReturningUser)
    }
}









































































































































































