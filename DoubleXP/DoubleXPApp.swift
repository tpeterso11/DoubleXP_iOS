//
//  DoubleXPApp.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import FirebaseCore

@main
struct DoubleXPApp: App {
    // Bridge to your existing AppDelegate for Firebase, etc.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Hold the singleton in SwiftUI so views can observe it
    @StateObject private var reactionsManager = ReactionsManager.shared

    // Scene phase tells us active / inactive / background
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(reactionsManager)
        }
        .onChange(of: scenePhase) { newPhase in  // Remove the first underscore parameter
            if newPhase == .background {
                // App is going to the background – flush pending reactions
                if let userId = UserProvider.shared.currentUser?.uId {
                    ReactionsManager.shared.flushPendingLikes(for: userId)  // Also update method name
                }
            }
        }
    }
}
