//
//  FeedStatusBar.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct FeedStatusBar: View {
    var onMessagesTap: () -> Void
    var onInvitesTap: () -> Void
    
    /// Pass this binding from parent to track if status bar should animate
    /// Set to true when the status bar is actually visible on screen
    var isVisible: Bool = true
    
    /// Height of the header above status bar (for banner positioning)
    /// Default is 280 for the carousel header
    var headerHeight: CGFloat = 280
    
    @ObservedObject private var xpManager = XPManager.shared
    
    #if DEBUG
    @ObservedObject private var abTestManager = ABTestManager.shared
    #endif
    
    // Animation states
    @State private var displayedXP: Int = 0
    @State private var displayedProgress: Double = 0
    @State private var displayedLevel: Int = 1
    @State private var showXPGain: Bool = false
    @State private var xpGainAmount: Int = 0
    
    // Tracking for deferred animations
    @State private var lastKnownTotalXP: Int = 0
    @State private var pendingXPGain: Int = 0
    @State private var hasInitialized: Bool = false
    
    // Level up queue - for handling multiple level ups or overflow
    @State private var pendingLevelUp: Bool = false
    @State private var targetLevel: Int = 1
    
    // Banner state (for inline banner variant)
    @State private var showLevelUpBanner: Bool = false
    @State private var bannerLevel: Int = 1
    @State private var bannerTitle: String = "Rookie"
    
    // For level info
    private var levelInfo: LevelInfo {
        LevelInfo.info(for: displayedLevel)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main status bar content
            VStack(spacing: 0) {
                // Debug indicator for A/B test override
                #if DEBUG
                if abTestManager.overrides[ABTest.levelUpCelebration.rawValue] != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "ant.fill")
                            .font(.system(size: 8))
                        Text("A/B Override: \(abTestManager.levelUpVariant().displayName)")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "FFD700"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "FFD700").opacity(0.15))
                    .cornerRadius(4)
                    .padding(.bottom, 6)
                }
                #endif
                
                // Main bar content
                HStack {
                    // Left side: Level badge + XP info
                    HStack(spacing: 10) {
                        // Level badge - uses displayedLevel for smooth transitions
                        Text("LV \(displayedLevel)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF4757")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Level title
                        Text(levelInfo.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: levelInfo.badgeColor))
                    }
                    
                    Spacer()
                    
                    // Right side: XP counter
                    HStack(spacing: 4) {
                        Text("\(displayedXP)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                        
                        Text("/")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("\(LevelInfo.totalXPRequired(forLevel: displayedLevel)) XP")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * displayedProgress))
                    }
                    
                    // XP Gain popup
                    if showXPGain {
                        Text("+\(xpGainAmount) XP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "4ADE80"))
                            .shadow(color: Color(hex: "4ADE80").opacity(0.5), radius: 8)
                            .position(
                                x: min(geo.size.width * displayedProgress + 30, geo.size.width - 40),
                                y: -16
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                }
                .frame(height: 4)
                .padding(.bottom, 8)
            }
            .background(Color.black)
            
            // Level Up Banner Overlay - positioned exactly over this status bar
            if showLevelUpBanner {
                LevelUpBannerInline(
                    level: bannerLevel,
                    title: bannerTitle,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLevelUpBanner = false
                        }
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLevelUpBanner)
        .onAppear {
            initializeIfNeeded()
        }
        .onChange(of: xpManager.totalXP) { newTotal in
            handleXPChange(newTotal: newTotal)
        }
        .onChange(of: isVisible) { nowVisible in
            if nowVisible {
                playPendingAnimationIfNeeded()
            }
        }
    }
    
    // MARK: - Initialization
    
    private func initializeIfNeeded() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Set initial values without animation
        displayedXP = xpManager.xpInCurrentLevel
        displayedProgress = xpManager.levelProgress
        displayedLevel = xpManager.currentLevel
        targetLevel = xpManager.currentLevel
        lastKnownTotalXP = xpManager.totalXP
        pendingXPGain = 0
    }
    
    // MARK: - XP Change Handling
    
    private func handleXPChange(newTotal: Int) {
        let gained = newTotal - lastKnownTotalXP
        
        guard gained != 0 else { return }
        
        if gained > 0 {
            // Accumulate pending XP gain
            pendingXPGain += gained
            targetLevel = xpManager.currentLevel
            
            if isVisible {
                // Play animation immediately
                playXPGainAnimation()
            }
            // If not visible, animation will play when isVisible becomes true
        } else {
            // XP decreased (unusual - maybe admin adjustment)
            // Just update silently
            displayedXP = xpManager.xpInCurrentLevel
            displayedProgress = xpManager.levelProgress
            displayedLevel = xpManager.currentLevel
            targetLevel = xpManager.currentLevel
        }
        
        lastKnownTotalXP = newTotal
    }
    
    // MARK: - Animation Playback
    
    private func playPendingAnimationIfNeeded() {
        guard pendingXPGain > 0 else { return }
        
        // Small delay to ensure view is fully visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            playXPGainAnimation()
        }
    }
    
    private func playXPGainAnimation() {
        guard pendingXPGain > 0 else { return }
        
        let gainToShow = pendingXPGain
        pendingXPGain = 0
        
        // Show the popup
        xpGainAmount = gainToShow
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showXPGain = true
        }
        
        // Check if we're leveling up
        if targetLevel > displayedLevel {
            // We need to level up - animate to 100% first
            animateLevelUp(finalLevel: targetLevel, totalXPGained: gainToShow)
        } else {
            // Normal XP gain within same level
            animateNormalXPGain()
        }
        
        // Hide popup after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showXPGain = false
            }
        }
    }
    
    private func animateNormalXPGain() {
        // Animate counter roll-up
        let startXP = displayedXP
        let endXP = xpManager.xpInCurrentLevel
        animateCounter(from: startXP, to: endXP, duration: 0.8)
        
        // Animate progress bar
        withAnimation(.easeOut(duration: 0.8)) {
            displayedProgress = xpManager.levelProgress
        }
    }
    
    private func animateLevelUp(finalLevel: Int, totalXPGained: Int) {
        let xpRequiredForCurrentLevel = LevelInfo.totalXPRequired(forLevel: displayedLevel)
        
        // Calculate duration proportional to how much bar needs to fill
        let fillDuration = 0.6 * (1.0 - displayedProgress)
        
        // Step 1: Animate counter to max for current level
        animateCounter(from: displayedXP, to: xpRequiredForCurrentLevel, duration: fillDuration)
        
        // Step 1: Fill the bar to 100%
        withAnimation(.easeOut(duration: fillDuration)) {
            displayedProgress = 1.0
        }
        
        // Step 2: When bar fills, trigger level up celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration + 0.1) {
            let newLevel = displayedLevel + 1
            let newTitle = LevelInfo.info(for: newLevel).title
            
            // Check A/B test variant
            let variant = ABTestManager.shared.levelUpVariant()
            
            if variant == .bannerDrop {
                // Show inline banner (overlays status bar perfectly)
                bannerLevel = newLevel
                bannerTitle = newTitle
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showLevelUpBanner = true
                }
                
                // Log A/B exposure
                Task {
                    await ABTestManager.shared.logExposure(for: .levelUpCelebration)
                }
                
                // Auto-dismiss banner after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showLevelUpBanner = false
                    }
                }
            } else {
                // Show full screen celebration via controller
                LevelUpCelebrationController.shared.showCelebration(
                    level: newLevel,
                    title: newTitle
                )
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Step 3: After a brief pause, reset bar and update level
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Update level
                displayedLevel = newLevel
                
                // Reset bar to 0
                withAnimation(.easeOut(duration: 0.1)) {
                    displayedProgress = 0
                    displayedXP = 0
                }
                
                // Step 4: Check if we need to continue to another level
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if displayedLevel < finalLevel {
                        // More levels to go - recurse
                        animateLevelUp(finalLevel: finalLevel, totalXPGained: 0)
                    } else {
                        // Final level reached - animate remaining XP
                        let finalXP = xpManager.xpInCurrentLevel
                        let finalProgress = xpManager.levelProgress
                        
                        animateCounter(from: 0, to: finalXP, duration: 0.5)
                        
                        withAnimation(.easeOut(duration: 0.5)) {
                            displayedProgress = finalProgress
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Counter Animation
    
    private func animateCounter(from startValue: Int, to endValue: Int, duration: Double) {
        let startTime = Date()
        let difference = endValue - startValue
        
        guard difference != 0 else {
            displayedXP = endValue
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Ease out cubic
            let eased = 1 - pow(1 - progress, 3)
            let currentValue = startValue + Int(Double(difference) * eased)
            
            DispatchQueue.main.async {
                self.displayedXP = currentValue
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.displayedXP = endValue
                }
            }
        }
    }
}

// MARK: - Inline Level Up Banner (for Banner Drop variant)

/// This banner overlays exactly on top of the FeedStatusBar
struct LevelUpBannerInline: View {
    let level: Int
    let title: String
    let onDismiss: () -> Void
    
    @State private var showShimmer: Bool = false
    
    private var levelInfo: LevelInfo {
        LevelInfo.info(for: level)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 8)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL UP!")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))
                        .tracking(1.5)
                    
                    HStack(spacing: 6) {
                        Text("Level \(level)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: levelInfo.badgeColor))
                    }
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Gold progress bar at bottom (full width, mimics completed XP bar)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
        }
        .padding(.bottom, 8)
        .background(
            ZStack {
                Color.black
                
                // Shimmer overlay
                if showShimmer {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: showShimmer ? geo.size.width * 1.5 : -geo.size.width * 0.5)
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: showShimmer
                        )
                    }
                    .clipped()
                }
            }
        )
        .onAppear {
            // Trigger shimmer after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showShimmer = true
            }
        }
    }
}

// MARK: - Global XP Animation Overlay

/// Use this as an overlay on your root view to show XP gains anywhere in the app
struct XPGainOverlay: View {
    @ObservedObject private var xpManager = XPManager.shared
    @StateObject private var coordinator = XPAnimationCoordinator.shared
    
    var body: some View {
        ZStack {
            if coordinator.showToast {
                VStack {
                    XPRewardToast(
                        amount: coordinator.pendingAmount,
                        source: coordinator.pendingSource,
                        isPresented: $coordinator.showToast
                    )
                    .padding(.top, 100)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.showToast)
    }
}

// MARK: - XP Animation Coordinator

/// Coordinates XP animations across the app
/// Use this to trigger XP toasts from anywhere
@MainActor
class XPAnimationCoordinator: ObservableObject {
    static let shared = XPAnimationCoordinator()
    
    @Published var showToast: Bool = false
    @Published var pendingAmount: Int = 0
    @Published var pendingSource: String = ""
    
    private init() {
        // Listen for XP changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleXPChange),
            name: .userXPDidChange,
            object: nil
        )
    }
    
    @objc private func handleXPChange(_ notification: Notification) {
        // This can be used for app-wide XP notifications
        // For now, the FeedStatusBar handles its own animations
    }
    
    /// Call this to show an XP toast from anywhere
    func showXPGain(amount: Int, source: String) {
        pendingAmount = amount
        pendingSource = source
        showToast = true
    }
}

// MARK: - XP Reward Toast

struct XPRewardToast: View {
    let amount: Int
    let source: String
    @Binding var isPresented: Bool
    
    @State private var displayedAmount: Int = 0
    @State private var showContent: Bool = false
    
    var body: some View {
        if isPresented {
            VStack(spacing: 6) {
                // XP Amount with counter roll-up
                HStack(spacing: 4) {
                    Text("+")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(Color(hex: "4ADE80"))
                    
                    Text("\(displayedAmount)")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text("XP")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "4ADE80"))
                }
                
                // Source label
                Text(source)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1A1A2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "4ADE80").opacity(0.5), Color(hex: "4ADE80").opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color(hex: "4ADE80").opacity(0.3), radius: 20)
            )
            .scaleEffect(showContent ? 1 : 0.7)
            .opacity(showContent ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showContent = true
                }
                
                animateToastCounter()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func animateToastCounter() {
        let duration: Double = 0.6
        let startTime = Date()
        
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            let eased = 1 - pow(1 - progress, 3)
            
            DispatchQueue.main.async {
                self.displayedAmount = Int(Double(amount) * eased)
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.displayedAmount = amount
                }
            }
        }
    }
}
