//
//  GoogleConnectionDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

// MARK: - Google Connection Drawer

struct GoogleConnectionDrawer: View {
    @Binding var isPresented: Bool
    @ObservedObject private var youtubeManager = YouTubeRequestManager.shared
    
    @State private var connectionState: DrawerConnectionState = .idle
    @State private var errorMessage: String?
    
    var onConnectionSuccess: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if connectionState != .connecting {
                        isPresented = false
                    }
                }
            
            // Drawer
            VStack(spacing: 0) {
                Spacer()
                
                drawerContent
                    .background(Color(hex: "0D0D0D"))
                    .cornerRadius(32, corners: [.topLeft, .topRight])
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.opacity)
    }
    
    // MARK: - Drawer Content
    
    private var drawerContent: some View {
        ZStack {
            // Blue glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "4285F4").opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(y: -100)
                .blur(radius: 20)
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                // Content based on state
                switch connectionState {
                case .idle:
                    idleContent
                case .connecting:
                    connectingContent
                case .success:
                    successContent
                case .error:
                    errorContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Idle State (Main Content)
    
    private var idleContent: some View {
        VStack(spacing: 0) {
            // Logo Row
            HStack(spacing: 16) {
                // App Logo
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("🎮")
                            .font(.system(size: 24))
                    )
                    .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 12, y: 4)
                
                // Connect Icon
                Text("⟷")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
                
                // Google Logo
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .overlay(
                        GoogleLogo()
                            .frame(width: 28, height: 28)
                    )
                    .shadow(color: Color.white.opacity(0.15), radius: 12, y: 4)
            }
            .padding(.bottom, 24)
            
            // Title
            HStack(spacing: 0) {
                Text("Connect to ")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Google")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "4285F4"),
                                Color(hex: "34A853"),
                                Color(hex: "FBBC05"),
                                Color(hex: "EA4335")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.bottom, 8)
            
            // Subtitle
            Text("Link your account to unlock video challenges, profile showcases, and more")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 28)
            
            // Benefits Strip
            benefitsStrip
                .padding(.bottom, 28)
            
            // Connect Button
            connectButton
            
            // Footer
            footer
                .padding(.top, 20)
        }
    }
    
    private var benefitsStrip: some View {
        GoogleDrawerFlowLayout(spacing: 8) {
            BenefitChip(emoji: "🏆", text: "Challenges")
            BenefitChip(emoji: "📺", text: "Showcase")
            BenefitChip(emoji: "✨", text: "Posts")
            BenefitChip(emoji: "⚡", text: "Bonus XP")
        }
    }
    
    private var connectButton: some View {
        Button(action: initiateConnection) {
            HStack(spacing: 12) {
                GoogleLogo()
                    .frame(width: 22, height: 22)
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "1a1a2e"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.white.opacity(0.2), radius: 16, y: 8)
        }
        .buttonStyle(GoogleDrawerScaleButtonStyle())
    }
    
    private var footer: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Text("Skip for now")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12))
                Text("Secure connection")
                    .font(.system(size: 11))
            }
            .foregroundColor(.white.opacity(0.3))
        }
        .padding(.top, 16)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Connecting State
    
    private var connectingContent: some View {
        VStack(spacing: 24) {
            // Animated loader
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "4285F4"), Color(hex: "34A853")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .modifier(RotatingModifier())
            }
            
            Text("Connecting to Google...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Please complete the sign-in in the popup")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Success State
    
    private var successContent: some View {
        VStack(spacing: 24) {
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color(hex: "4ADE80").opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color(hex: "4ADE80"))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Connected!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your Google account has been linked successfully")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Button(action: {
                onConnectionSuccess?()
                isPresented = false
            }) {
                Text("Continue")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "4ADE80"))
                    .cornerRadius(14)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Error State
    
    private var errorContent: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color(hex: "FF6B6B").opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color(hex: "FF6B6B"))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Connection Failed")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(errorMessage ?? "Something went wrong. Please try again.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: { isPresented = false }) {
                    Text("Close")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(14)
                }
                
                Button(action: initiateConnection) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "FF6B6B"))
                        .cornerRadius(14)
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func initiateConnection() {
        connectionState = .connecting
        
        // Get the presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            connectionState = .error
            errorMessage = "Unable to present sign-in"
            return
        }
        
        // Find the topmost presented controller
        var topController = viewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        Task {
            do {
                try await YouTubeRequestManager.shared.signIn(presenting: topController)
                
                await MainActor.run {
                    connectionState = .success
                }
                
                // Auto-close after brief delay
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    onConnectionSuccess?()
                    isPresented = false
                }
                
            } catch {
                await MainActor.run {
                    connectionState = .error
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Drawer Connection State

private enum DrawerConnectionState {
    case idle
    case connecting
    case success
    case error
}

// MARK: - Benefit Chip

struct BenefitChip: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 14))
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Google Logo

struct GoogleLogo: View {
    var body: some View {
        Image("google_logo") // Use your asset, or fallback to this SVG-like representation
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// If you don't have a google logo asset, use this alternative:
struct GoogleLogoFallback: View {
    var body: some View {
        ZStack {
            // Blue
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color(hex: "4285F4"), lineWidth: 3)
            // Green
            Circle()
                .trim(from: 0.25, to: 0.5)
                .stroke(Color(hex: "34A853"), lineWidth: 3)
            // Yellow
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color(hex: "FBBC05"), lineWidth: 3)
            // Red
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color(hex: "EA4335"), lineWidth: 3)
        }
        .rotationEffect(.degrees(-90))
    }
}

// MARK: - Flow Layout (for benefit chips)

struct GoogleDrawerFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Rotating Modifier

struct RotatingModifier: ViewModifier {
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Scale Button Style

struct GoogleDrawerScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
