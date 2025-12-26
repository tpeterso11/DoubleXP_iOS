//
//  ChallengesDebugComponents.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Challenges XP Card (Animated)
// Replace your existing xpCard with this component

struct ChallengesXPCard: View {
    @ObservedObject private var xpManager = XPManager.shared
    
    @State private var displayedXP: Int = 0
    @State private var displayedTotalXP: Int = 0
    @State private var displayedProgress: Double = 0
    @State private var displayedLevel: Int = 1
    @State private var showXPGain: Bool = false
    @State private var xpGainAmount: Int = 0
    
    @State private var lastKnownTotalXP: Int = 0
    @State private var pendingXPGain: Int = 0
    @State private var hasInitialized: Bool = false
    @State private var targetLevel: Int = 1
    
    @State private var showLevelUpBanner: Bool = false
    @State private var bannerLevel: Int = 1
    @State private var bannerTitle: String = "Rookie"
    
    private var levelInfo: LevelInfo {
        LevelInfo.info(for: displayedLevel)
    }
    
    var body: some View {
        ZStack {
            mainCard
            
            if showLevelUpBanner {
                ChallengesLevelUpBanner(
                    level: bannerLevel,
                    title: bannerTitle,
                    onDismiss: { withAnimation(.easeOut(duration: 0.3)) { showLevelUpBanner = false } }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLevelUpBanner)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onAppear { initializeIfNeeded() }
        .onChange(of: xpManager.totalXP) { newTotal in handleXPChange(newTotal: newTotal) }
    }
    
    // MARK: - Main Card
    
    private var mainCard: some View {
        VStack(spacing: 0) {
            headerRow
            progressSection
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var headerRow: some View {
        HStack {
            totalXPSection
            Spacer()
            levelSection
        }
    }
    
    private var totalXPSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL XP")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
            
            Text(displayedTotalXP.formatted())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "4ADE80"))
                .contentTransition(.numericText())
        }
    }
    
    private var levelSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("LEVEL")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
            
            Text("\(displayedLevel)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 6) {
            progressBar
            progressLabels
        }
        .padding(.top, 12)
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "4ADE80"), Color(hex: "22D3EE")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * displayedProgress)
                
                if showXPGain {
                    xpGainPopup(in: geo)
                }
            }
        }
        .frame(height: 6)
    }
    
    private func xpGainPopup(in geo: GeometryProxy) -> some View {
        Text("+\(xpGainAmount) XP")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(hex: "4ADE80"))
            .shadow(color: Color(hex: "4ADE80").opacity(0.5), radius: 6)
            .position(
                x: min(geo.size.width * displayedProgress + 25, geo.size.width - 35),
                y: -12
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.5).combined(with: .opacity),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
    }
    
    private var progressLabels: some View {
        HStack {
            Text(levelInfo.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: levelInfo.badgeColor))
            
            Spacer()
            
            Text("\(displayedXP) / \(LevelInfo.xpRequired(for: displayedLevel)) XP")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    // MARK: - Logic
    
    private func initializeIfNeeded() {
        guard !hasInitialized else { return }
        hasInitialized = true
        displayedXP = xpManager.xpInCurrentLevel
        displayedTotalXP = xpManager.totalXP
        displayedProgress = xpManager.levelProgress
        displayedLevel = xpManager.currentLevel
        targetLevel = xpManager.currentLevel
        lastKnownTotalXP = xpManager.totalXP
    }
    
    private func handleXPChange(newTotal: Int) {
        let gained = newTotal - lastKnownTotalXP
        guard gained > 0 else {
            displayedXP = xpManager.xpInCurrentLevel
            displayedTotalXP = xpManager.totalXP
            displayedProgress = xpManager.levelProgress
            displayedLevel = xpManager.currentLevel
            targetLevel = xpManager.currentLevel
            lastKnownTotalXP = newTotal
            return
        }
        
        pendingXPGain += gained
        targetLevel = xpManager.currentLevel
        lastKnownTotalXP = newTotal
        playXPGainAnimation()
    }
    
    private func playXPGainAnimation() {
        guard pendingXPGain > 0 else { return }
        
        let gainToShow = pendingXPGain
        pendingXPGain = 0
        
        xpGainAmount = gainToShow
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showXPGain = true
        }
        
        animateCounter(from: displayedTotalXP, to: xpManager.totalXP, duration: 0.8) { displayedTotalXP = $0 }
        
        if targetLevel > displayedLevel {
            animateLevelUp(finalLevel: targetLevel)
        } else {
            animateNormalXPGain()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { showXPGain = false }
        }
    }
    
    private func animateNormalXPGain() {
        animateCounter(from: displayedXP, to: xpManager.xpInCurrentLevel, duration: 0.8) { displayedXP = $0 }
        withAnimation(.easeOut(duration: 0.8)) {
            displayedProgress = xpManager.levelProgress
        }
    }
    
    private func animateLevelUp(finalLevel: Int) {
        let xpRequired = LevelInfo.xpRequired(for: displayedLevel)
        let fillDuration = 0.6 * (1.0 - displayedProgress)
        
        animateCounter(from: displayedXP, to: xpRequired, duration: fillDuration) { displayedXP = $0 }
        withAnimation(.easeOut(duration: fillDuration)) { displayedProgress = 1.0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration + 0.1) {
            triggerLevelUpCelebration(finalLevel: finalLevel)
        }
    }
    
    private func triggerLevelUpCelebration(finalLevel: Int) {
        let newLevel = displayedLevel + 1
        let newTitle = LevelInfo.info(for: newLevel).title
        let variant = ABTestManager.shared.levelUpVariant()
        
        if variant == .bannerDrop {
            bannerLevel = newLevel
            bannerTitle = newTitle
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showLevelUpBanner = true }
            Task { await ABTestManager.shared.logExposure(for: .levelUpCelebration) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) { showLevelUpBanner = false }
            }
        } else {
            LevelUpCelebrationController.shared.showCelebration(level: newLevel, title: newTitle)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resetBarForNewLevel(finalLevel: finalLevel)
        }
    }
    
    private func resetBarForNewLevel(finalLevel: Int) {
        displayedLevel += 1
        withAnimation(.easeOut(duration: 0.1)) {
            displayedProgress = 0
            displayedXP = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if displayedLevel < finalLevel {
                animateLevelUp(finalLevel: finalLevel)
            } else {
                animateCounter(from: 0, to: xpManager.xpInCurrentLevel, duration: 0.5) { displayedXP = $0 }
                withAnimation(.easeOut(duration: 0.5)) { displayedProgress = xpManager.levelProgress }
            }
        }
    }
    
    private func animateCounter(from startValue: Int, to endValue: Int, duration: Double, update: @escaping (Int) -> Void) {
        let startTime = Date()
        let difference = endValue - startValue
        guard difference != 0 else { update(endValue); return }
        
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            let eased = 1 - pow(1 - progress, 3)
            DispatchQueue.main.async { update(startValue + Int(Double(difference) * eased)) }
            if progress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.async { update(endValue) }
            }
        }
    }
}

// MARK: - Challenges Level Up Banner

struct ChallengesLevelUpBanner: View {
    let level: Int
    let title: String
    let onDismiss: () -> Void
    
    @State private var showShimmer: Bool = false
    
    private var levelInfo: LevelInfo { LevelInfo.info(for: level) }
    
    var body: some View {
        VStack(spacing: 0) {
            bannerContent
            progressIndicator
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "4ADE80").opacity(0.3), lineWidth: 1))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showShimmer = true } }
    }
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            iconView
            textContent
            Spacer()
            dismissButton
        }
        .padding(16)
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [Color(hex: "4ADE80"), Color(hex: "22D3EE")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .shadow(color: Color(hex: "4ADE80").opacity(0.4), radius: 8)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("LEVEL UP!")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "4ADE80"))
                .tracking(1.5)
            
            HStack(spacing: 6) {
                Text("Level \(level)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("•")
                    .foregroundColor(.white.opacity(0.3))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: levelInfo.badgeColor))
            }
        }
    }
    
    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    private var progressIndicator: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color(hex: "4ADE80"), Color(hex: "22D3EE")],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(height: 4)
    }
}

// MARK: - Challenges Debug Drawer

#if DEBUG
struct ChallengesDebugDrawer: View {
    @Binding var isPresented: Bool
    @ObservedObject private var xpManager = XPManager.shared
    @ObservedObject private var abTestManager = ABTestManager.shared
    @State private var customXPAmount: String = "250"
    
    private var levelInfo: LevelInfo { LevelInfo.info(for: xpManager.currentLevel) }
    
    var body: some View {
        ZStack {
            backdrop
            drawerContent
        }
    }
    
    private var backdrop: some View {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
            .onTapGesture { isPresented = false }
    }
    
    private var drawerContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                handle
                header
                scrollContent
            }
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1a1a2e")))
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
        }
    }
    
    private var handle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver")
                .foregroundColor(.yellow)
            Text("Debug Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button { isPresented = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ChallengesXPTestingSection(
                    xpManager: xpManager,
                    levelInfo: levelInfo,
                    customXPAmount: $customXPAmount,
                    isPresented: $isPresented
                )
                
                ChallengesABTestingSection(
                    abTestManager: abTestManager
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - XP Testing Section

struct ChallengesXPTestingSection: View {
    @ObservedObject var xpManager: XPManager
    let levelInfo: LevelInfo
    @Binding var customXPAmount: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle
            statusCard
            customXPInput
            quickAddButtons
            levelUpButton
            celebrationPreview
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private var sectionTitle: some View {
        Text("XP & Level Testing")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
    }
    
    private var statusCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(xpManager.currentLevel)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(levelInfo.title)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: levelInfo.badgeColor))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(xpManager.xpInCurrentLevel) / \(xpManager.xpRequiredForNextLevel)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(Int(xpManager.levelProgress * 100))% to next")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var customXPInput: some View {
        HStack(spacing: 8) {
            TextField("Amount", text: $customXPAmount)
                .keyboardType(.numberPad)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .frame(width: 100)
            
            Button { addCustomXP() } label: {
                Text("Add XP")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "4ADE80"))
                    .cornerRadius(8)
            }
        }
    }
    
    private var quickAddButtons: some View {
        HStack(spacing: 6) {
            ForEach([10, 25, 50, 100, 500], id: \.self) { amount in
                quickAddButton(amount: amount)
            }
        }
    }
    
    private func quickAddButton(amount: Int) -> some View {
        Button { addXP(amount) } label: {
            Text("+\(amount)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    private var levelUpButton: some View {
        let xpNeeded = xpManager.xpRequiredForNextLevel - xpManager.xpInCurrentLevel
        return Button { addXP(xpNeeded) } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Level Up (+\(xpNeeded) XP)")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
        }
    }
    
    private var celebrationPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Celebration Preview")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            
            HStack(spacing: 8) {
                previewButton(label: "Current Level", icon: "party.popper.fill") {
                    showCelebration(level: xpManager.currentLevel)
                }
                
                previewButton(label: "Next Level", icon: "sparkles") {
                    showCelebration(level: xpManager.currentLevel + 1)
                }
            }
        }
    }
    
    private func previewButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.4))
            .cornerRadius(8)
        }
    }
    
    private func addCustomXP() {
        if let amount = Int(customXPAmount) {
            addXP(amount)
        }
    }
    
    private func addXP(_ amount: Int) {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task { await xpManager.addXP(amount, source: .other) }
        }
    }
    
    private func showCelebration(level: Int) {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let title = LevelInfo.info(for: level).title
            LevelUpCelebrationController.shared.showCelebration(level: level, title: title)
        }
    }
}

// MARK: - A/B Testing Section

struct ChallengesABTestingSection: View {
    @ObservedObject var abTestManager: ABTestManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            currentVariantDisplay
            variantButtons
            clearOverrideButton
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("A/B Test: Level Up Celebration")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if abTestManager.overrides[ABTest.levelUpCelebration.rawValue] != nil {
                overrideBadge
            }
        }
    }
    
    private var overrideBadge: some View {
        Text("OVERRIDE")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var currentVariantDisplay: some View {
        HStack {
            Text("Current Variant:")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            Text(abTestManager.levelUpVariant().displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "4ADE80"))
        }
    }
    
    private var variantButtons: some View {
        HStack(spacing: 8) {
            ForEach(LevelUpVariant.allCases, id: \.self) { variant in
                variantButton(variant: variant)
            }
        }
    }
    
    private func variantButton(variant: LevelUpVariant) -> some View {
        let isSelected = abTestManager.levelUpVariant() == variant
        return Button {
            abTestManager.setLocalOverride(for: .levelUpCelebration, variant: variant.rawValue)
        } label: {
            Text(variant.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "4ADE80") : Color.white.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var clearOverrideButton: some View {
        if abTestManager.overrides[ABTest.levelUpCelebration.rawValue] != nil {
            Button {
                abTestManager.setLocalOverride(for: .levelUpCelebration, variant: nil)
            } label: {
                Text("Clear Override")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    }
}
#endif
