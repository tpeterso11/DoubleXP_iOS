//
//  LevelUpCelebrations.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

class LevelUpCelebrationController: ObservableObject {
    static let shared = LevelUpCelebrationController()
    
    @Published var isPresented: Bool = false {
        didSet {
            print("🎊 [LevelUpCelebrationController] isPresented changed: \(oldValue) → \(isPresented)")
        }
    }
    @Published var newLevel: Int = 1
    @Published var levelTitle: String = "Rookie"
    
    private var notificationObserver: NSObjectProtocol?
    
    private init() {
        print("🎊 [LevelUpCelebrationController] Initializing...")
        
        // Listen for level up notifications
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .userDidLevelUp,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleLevelUp(notification)
        }
        
        print("🎊 [LevelUpCelebrationController] Registered for .userDidLevelUp notifications")
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleLevelUp(_ notification: Notification) {
        print("🎊 [LevelUpCelebrationController] ========================================")
        print("🎊 [LevelUpCelebrationController] Received level up notification!")
        print("🎊 [LevelUpCelebrationController] userInfo: \(notification.userInfo ?? [:])")
        
        // XPManager sends "newLevel" in userInfo
        guard let userInfo = notification.userInfo,
              let newLevel = userInfo["newLevel"] as? Int else {
            print("❌ [LevelUpCelebrationController] Missing newLevel in userInfo!")
            return
        }
        
        print("🎊 [LevelUpCelebrationController] Level up to \(newLevel)!")
        
        // Ensure we're on main thread
        DispatchQueue.main.async {
            self.showCelebration(
                level: newLevel,
                title: LevelInfo.info(for: newLevel).title
            )
        }
    }
    
    /// Direct method to show celebration (can be called from XPManager or debug)
    /// Respects A/B test variant - will show Full Screen or Banner based on assignment
    func showCelebration(level: Int, title: String) {
        print("🎉 [LevelUpCelebrationController] ========================================")
        print("🎉 [LevelUpCelebrationController] showCelebration called")
        print("🎉 [LevelUpCelebrationController] Level: \(level), Title: \(title)")
        print("🎉 [LevelUpCelebrationController] Current isPresented: \(isPresented)")
        //print("🎉 [LevelUpCelebrationController] A/B Variant: \(ABTestManager.shared.levelUpVariant().displayName)")
        
        self.newLevel = level
        self.levelTitle = title
        
        // Small delay to let the progress bar finish animating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            print("🎉 [LevelUpCelebrationController] Setting isPresented = true")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.isPresented = true
            }
            print("🎉 [LevelUpCelebrationController] isPresented is now: \(self.isPresented)")
        }
        
        // Log exposure for A/B test
        Task {
            await ABTestManager.shared.logExposure(for: .levelUpCelebration)
        }
    }
    
    func dismiss() {
        print("🎉 [LevelUpCelebrationController] dismiss() called")
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
        
        // Log conversion (user saw and dismissed the celebration)
        Task {
            await ABTestManager.shared.logConversion(
                for: .levelUpCelebration,
                eventName: "dismissed",
                metadata: ["level": newLevel]
            )
        }
    }
}

// MARK: - Level Up Celebration Overlay

/// Add this as an overlay on your root view
/// Note: Banner variant is now handled inline by FeedStatusBar for precise positioning
struct LevelUpCelebrationOverlay: View {
    @StateObject private var controller = LevelUpCelebrationController.shared
    @ObservedObject private var abManager = ABTestManager.shared
    
    var body: some View {
        ZStack {
            // Only show full screen variant here
            // Banner variant is handled by FeedStatusBar inline
            if controller.isPresented && abManager.levelUpVariant() == .fullScreen {
                let _ = print("🎨 [LevelUpCelebrationOverlay] Rendering Full Screen for Level \(controller.newLevel)")
                
                LevelUpFullScreenView(
                    level: controller.newLevel,
                    title: controller.levelTitle,
                    onDismiss: { controller.dismiss() }
                )
                .transition(.opacity)
                .zIndex(9999)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: controller.isPresented)
        .onAppear {
            print("🎨 [LevelUpCelebrationOverlay] onAppear - controller.isPresented = \(controller.isPresented)")
        }
    }
}

// MARK: - Variant A: Full Screen Takeover

struct LevelUpFullScreenView: View {
    let level: Int
    let title: String
    let onDismiss: () -> Void
    
    @State private var showContent: Bool = false
    @State private var showRays: Bool = false
    @State private var particles: [ParticleData] = []
    
    private var levelInfo: LevelInfo {
        LevelInfo.info(for: level)
    }
    
    var body: some View {
        ZStack {
            // Dark backdrop
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Rotating rays
            if showRays {
                RotatingRaysView()
                    .opacity(0.3)
            }
            
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
            
            // Main content
            VStack(spacing: 8) {
                Text("LEVEL UP!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
                    .tracking(4)
                
                Text("\(level)")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FF8E53"), Color(hex: "FF6B6B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 30)
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("You're climbing the ranks!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 4)
                
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 16)
                }
                .padding(.top, 32)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                showRays = true
            }
            
            // Burst particles
            createParticleBurst()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func createParticleBurst() {
        let colors: [Color] = [
            Color(hex: "FFD700"),
            Color(hex: "FF8E53"),
            Color(hex: "FF6B6B"),
            Color(hex: "4ADE80"),
            Color(hex: "22D3EE")
        ]
        
        for i in 0..<20 {
            let angle = Double(i) / 20.0 * .pi * 2
            let distance: CGFloat = 150 + CGFloat.random(in: 0...50)
            let particle = ParticleData(
                id: UUID(),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                offset: .zero,
                opacity: 1
            )
            particles.append(particle)
            
            // Animate particle outward
            withAnimation(.easeOut(duration: 0.8).delay(Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance
                    )
                    particles[index].opacity = 0
                }
            }
        }
        
        // Clean up particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            particles.removeAll()
        }
    }
}

// MARK: - Variant B: Banner Drop

struct LevelUpBannerView: View {
    let level: Int
    let title: String
    let onDismiss: () -> Void
    
    @State private var showShimmer: Bool = false
    @State private var isVisible: Bool = false
    
    private var levelInfo: LevelInfo {
        LevelInfo.info(for: level)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            
            VStack {
                // Spacer to push banner down below safe area
                // Position it where the status bar would be (below the header/carousel)
                // Adjust this value based on your header height
                Spacer()
                    .frame(height: safeAreaTop + 280) // Safe area + approximate header height
                
                // Banner content
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FF8E53")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 12)
                            
                            Text("⬆️")
                                .font(.system(size: 24))
                        }
                        
                        // Text
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LEVEL UP!")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "FFD700"))
                                .tracking(2)
                            
                            HStack(spacing: 8) {
                                Text("Level \(level)")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: levelInfo.badgeColor))
                            }
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    
                    // Gold progress bar at bottom (mimics the XP bar)
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
                .background(
                    ZStack {
                        // Background
                        Color.black
                        
                        // Shimmer
                        if showShimmer {
                            ShimmerOverlay()
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
                .offset(y: isVisible ? 0 : -120)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            showShimmer = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct RotatingRaysView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            Canvas { context, size in
                for i in 0..<12 {
                    let angle = Double(i) * (.pi * 2 / 12) + rotation
                    
                    var path = Path()
                    path.move(to: center)
                    
                    let endX = center.x + cos(angle) * 400
                    let endY = center.y + sin(angle) * 400
                    let spread: Double = .pi / 24
                    
                    let leftX = center.x + cos(angle - spread) * 400
                    let leftY = center.y + sin(angle - spread) * 400
                    let rightX = center.x + cos(angle + spread) * 400
                    let rightY = center.y + sin(angle + spread) * 400
                    
                    path.addLine(to: CGPoint(x: leftX, y: leftY))
                    path.addLine(to: CGPoint(x: rightX, y: rightY))
                    path.closeSubpath()
                    
                    context.fill(
                        path,
                        with: .color(Color(hex: "FFD700").opacity(0.1))
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = .pi * 2
            }
        }
    }
}

struct ShimmerOverlay: View {
    @State private var offset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(hex: "FFD700").opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * 0.5)
                .offset(x: offset * geo.size.width * 1.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                offset = 1
            }
        }
    }
}

struct ParticleData: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}
