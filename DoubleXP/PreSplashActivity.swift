//
//  PreSplashActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/4/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import Lottie
import SwiftUI

// MARK: — Your streamlined splash VC
class PreSplashActivity: UIViewController {

    // --- Outlets ---
    @IBOutlet weak var adminBlur: UIView!
    @IBOutlet weak var splashLogo: UIImageView!
    @IBOutlet weak var videoBlur: UIVisualEffectView!
    @IBOutlet weak var videoBack: UIView!
    
    // --- UI Elements & Player ---
    private let player = DoubleXPVideoPlayer()
    private let spinner = UIActivityIndicatorView(style: .large)

    // --- State Management ---
    private var isVideoFinished = false
    private var isDataLoaded = false
    private var isReturningUser = false
    
    // --- Services ---
    private var newsApiService = NewsAPIService.shared
    private var apiService = GameAPIService.shared
    
    // Polling timer for resilience
    private var pollingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpinner()
        
        // 1. Determine if the user is new or returning.
        if let uId = UserDefaults.standard.string(forKey: "userId"), !uId.isEmpty {
            print("👤 User is returning.")
            isReturningUser = true
            // 2. For returning users, start all data loads immediately in parallel.
            Task {
                await loadAllStartupData(uid: uId)
                // This task will set isDataLoaded = true when complete.
            }
        } else {
            print("👤 User is new.")
            isReturningUser = false
            // For new users, data is "done" immediately.
            isDataLoaded = true
        }

        // 3. Start playing the video.
        playSplashVideo()
        
        // 4. Start polling to check conditions every few seconds.
        startPolling()
    }
    
    private func setupSpinner() {
        spinner.center = self.view.center
        spinner.color = .white
        spinner.hidesWhenStopped = true
        self.view.addSubview(spinner)
    }

    private func playSplashVideo() {
        player.playVideoBackground(
            in: self.videoBack,
            fileName: "newSplash0421",
            fileType: "mov"
        ) { [weak self] in
            guard let self = self else { return }
            print("🎥 Video playback finished.")
            self.isVideoFinished = true
            // Immediately check conditions now that the video is done.
            self.checkAndProceed()
        }
    }
    
    private func startPolling() {
        pollingTimer?.invalidate() // Stop any previous timer.
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            print("⏰ Polling timer fired. Checking conditions...")
            self?.checkAndProceed()
        }
    }

    private func loadAllStartupData(uid: String) async {
        print("⏳ Starting all startup data tasks in parallel...")

        await withTaskGroup(of: Void.self) { group in
            // Add a task to fetch games
            group.addTask {
                await GameAPIService.shared.fetchStartupGames()
                print("Finished fetching games.")
            }
            
            /*group.addTask {
                await GameAPIService.shared.fetchFeaturedGames()
                print("Finished fetching featured games.")
            }*/

            // Add a task to fetch news
            group.addTask {
                await NewsAPIService.shared.ensureInitialPage()
                print("Finished fetching news.")
            }
            
            group.addTask {
                await LanguageProvider.shared.fetchLanguages()
            }
            
            group.addTask {
                await self.loadCurrentUser(uid: uid)
            }
            // Add other startup tasks here...
            // group.addTask { await ShortsAPIService.shared.fetchShortsFeed() }
        }
        
        print("🎉 All startup data has been loaded.")
        // This marks the data loading as complete.
        self.isDataLoaded = true
        // Immediately check conditions now that data is loaded.
        checkAndProceed()
    }
    
    private func loadCurrentUser(uid: String) async {
        do {
            // 1. Await the async function to get the user object.
            let user = try await UserProvider.shared.loadUser(uid: uid)
            
            // 2. Once successful, update the AppDelegate on the main thread.
            await MainActor.run {
                (UIApplication.shared.delegate as? AppDelegate)?.currentUser = UserProvider.shared.currentUser
            }
        } catch {
            // 3. If loadUser throws an error, catch it here.
            print("⚠️ Failed to load user:", error)
        }
    }
    
    /// The single source of truth for deciding what to do next.
    private func checkAndProceed() {
        // --- Logic for Returning Users ---
        if isReturningUser {
            // Condition 1: Video is done, but data is still loading. Show spinner.
            if isVideoFinished && !isDataLoaded {
                print("⏳ Video finished, waiting for data. Showing spinner.")
                spinner.startAnimating()
                return
            }
            
            // Condition 2: Both video and data are finished. Navigate to the feed.
            if isVideoFinished && isDataLoaded {
                print("✅ Video and data finished. Navigating to Feed.")
                pollingTimer?.invalidate() // Stop polling.
                spinner.stopAnimating()
                transitionToFeed()
            }
            // If neither condition is met (e.g., video not done), the function simply exits
            // and waits for the next check (either from a completion handler or the timer).
            
        // --- Logic for New Users ---
        } else {
            // New users only need to wait for the video.
            if isVideoFinished {
                print("✅ New user video finished. Navigating to Login.")
                pollingTimer?.invalidate() // Stop polling.
                transitionToLogin()
            }
        }
    }
    
    // MARK: - Navigation
    
    private func transitionToFeed() {
        // 1. Create your new *RootView*.
        //    RootView handles creating the namespace, coordinator, and FeedView.
        let rootView = RootView() // 👈 THIS IS THE ONLY CHANGE
        
        // 2. Wrap *RootView* in a UIHostingController
        let hostingController = UIHostingController(rootView: rootView)
        
        // 3. Call your updated switchRoot method with the hosting controller instance
        DispatchQueue.main.async {
            UIApplication.switchRoot(
                to: hostingController, // 👈 Pass the hosting controller for RootView
                animationType: .push,
                animationSubtype: .fromRight
            )
        }
    }
    
    private func transitionToLogin() {
        DispatchQueue.main.async {
            UIApplication.switchRoot(
                to: LoginController.self,
                storyboardId: "login",
                animationType: .push,
                animationSubtype: .fromRight
            )
        }
    }
}

extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

/// Helper to await a single Firebase snapshot
extension DatabaseReference {
    func getDataOnce() async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { cont in
            self.observeSingleEvent(of: .value, with: { snap in
                cont.resume(returning: snap)
            }, withCancel: { err in
                cont.resume(throwing: err)
            })
        }
    }
}

extension UIApplication {
    
    // Updated helper to accept any UIViewController instance
    static func switchRoot(
        to newRoot: UIViewController,
        animationType: CATransitionType = .fade,
        animationSubtype: CATransitionSubtype? = nil
    ) {
        // Find the active window scene and its key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("⚠️ Could not find the key window to switch root view controller.")
            return
        }

        // Create and configure the transition animation
        let transition = CATransition()
        transition.duration = 0.35
        transition.type = animationType
        transition.subtype = animationSubtype
        
        // Add the animation to the window's layer
        window.layer.add(transition, forKey: kCATransition)
        
        // Set the new root view controller
        window.rootViewController = newRoot
    }
}
