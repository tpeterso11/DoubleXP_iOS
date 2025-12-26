//
//  PokoSelectionView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct PokoSelectionView: View {
    @StateObject private var viewModel: PokoSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation state for bobbing
    @State private var isAnimating = false
    
    init(isOnboarding: Bool = false, onSelectionConfirmed: ((Poko) -> Void)? = nil) {
        let vm = PokoSelectionViewModel(isOnboarding: isOnboarding)
        vm.onSelectionConfirmed = onSelectionConfirmed
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Scanlines effect
            ScanlinesOverlay()
            
            VStack(spacing: 0) {
                // Header with navigation
                headerView
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Player 1 box (only if selected)
                            if viewModel.selectedPoko != nil {
                                player1Box
                            }
                            
                            // Character display
                            characterDisplay
                            
                            // Character grid
                            characterGrid
                        }
                    }
                    
                    // Bottom hint (only if no selection yet)
                    if viewModel.selectedPoko == nil {
                        selectHint
                    } else {
                        readyIndicator
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadPokos()
        }
        .onAppear {
            // Start bobbing animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            
            VStack(spacing: 4) {
                Text("SELECT FIGHTER")
                    .font(.system(size: 22, weight: .black))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FF6B6B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("CHOOSE YOUR POKO")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(6)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.top, 50)
            
            // Back button (non-onboarding only)
            if !viewModel.isOnboarding {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
            }
            
            // Continue button (onboarding only, when selected)
            if viewModel.isOnboarding && viewModel.hasNewSelection {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.commitSelectionIfNeeded()
                    }) {
                        HStack(spacing: 6) {
                            Text("Continue")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "4ADE80"))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
            }
            
            // Coin counter
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("🪙")
                        .font(.system(size: 12))
                    Text("\(viewModel.userCoins.formatted())")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, viewModel.isOnboarding && viewModel.selectedPoko != nil ? 90 : 50)
        }
        .frame(height: 100)
    }
    
    // MARK: - Player 1 Box
    
    private var player1Box: some View {
        VStack(spacing: 8) {
            Text("PLAYER 1")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))
            
            if let poko = viewModel.selectedPoko {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1a1a2e"), Color(hex: "2d2d4e")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "3B82F6"), lineWidth: 3)
                        )
                        .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 15)
                    
                    // Poko image
                    AsyncImage(url: URL(string: poko.headshotUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        case .failure(_):
                            Text("🎮")
                                .font(.system(size: 42))
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Text(poko.name.uppercased())
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: "3B82F6").opacity(0.08), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - Character Display
    
    private var characterDisplay: some View {
        VStack(spacing: 0) {
            if let poko = viewModel.viewingPoko {
                // Character art with bobbing animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [poko.rarity.color.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    // Ring pulse
                    Circle()
                        .stroke(Color(hex: "FFD700").opacity(0.6), lineWidth: 2)
                        .frame(width: 126, height: 126)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .opacity(isAnimating ? 1.0 : 0.6)
                    
                    // Main avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [poko.rarity.color, poko.rarity.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: poko.rarity.color.opacity(0.5), radius: 30)
                        .shadow(color: poko.rarity.color.opacity(0.3), radius: 50)
                        .overlay(
                            AsyncImage(url: URL(string: poko.headshotUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                case .failure(_):
                                    Text("🎮")
                                        .font(.system(size: 60))
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        )
                        .offset(y: isAnimating ? -4 : 0) // Bobbing effect
                }
                .padding(.top, 16)
                
                // Character info
                VStack(spacing: 4) {
                    Text(poko.name.uppercased())
                        .font(.system(size: 24, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: poko.rarity.color.opacity(0.5), radius: 10)
                    
                    Text("\(poko.rarity.stars) \(poko.rarity.rawValue) \(poko.elementType.capitalized)")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Color(hex: "FFD700"))
                }
                .padding(.top, 12)
                
                // Stats - CENTERED
                HStack(spacing: 14) {
                    StatBar(label: "PWR", value: poko.power)
                    StatBar(label: "SPD", value: poko.speed)
                    StatBar(label: "DEF", value: poko.defense)
                }
                .frame(maxWidth: 300)
                .padding(.top, 12)
                .frame(maxWidth: .infinity) // Center the stats container
                
                // Collapsible backstory
                VStack(spacing: 6) {
                    Button(action: { viewModel.toggleBackstory() }) {
                        HStack(spacing: 6) {
                            Text("Origin Story")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .rotationEffect(.degrees(viewModel.isBackstoryExpanded ? 180 : 0))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    if viewModel.isBackstoryExpanded {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(poko.originStory.isEmpty ? defaultOriginStory(for: poko) : poko.originStory)
                                .font(.system(size: 12))
                                .lineSpacing(4)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(12)
                        .frame(maxWidth: 340)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.top, 10)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isBackstoryExpanded)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private func defaultOriginStory(for poko: Poko) -> String {
        let boost = poko.xpBoost > 0 ? " This companion brings +\(poko.xpBoost)% XP boost in competitive matches." : ""
        return "A \(poko.rarity.rawValue.lowercased()) \(poko.elementType.lowercased()) type Poko known for its unique abilities.\(boost)"
    }
    
    // MARK: - Character Grid
    
    private var characterGrid: some View {
        VStack(spacing: 0) {
            // Grid header
            HStack {
                Text("CHOOSE CHARACTER")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                // Filters
                HStack(spacing: 6) {
                    ForEach(PokoFilterOption.allCases, id: \.self) { filter in
                        Button(action: { viewModel.currentFilter = filter }) {
                            Text(filter.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    viewModel.currentFilter == filter
                                        ? Color(hex: "FF6B6B")
                                        : Color.white.opacity(0.06)
                                )
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
            
            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(viewModel.filteredPokos, id: \.id) { poko in
                    PokoGridCell(
                        poko: poko,
                        isSelected: viewModel.isSelected(poko),
                        isViewing: viewModel.isViewing(poko),
                        isOwned: viewModel.isOwned(poko),
                        isFeatured: viewModel.isFeatured(poko),
                        isLocked: viewModel.isLocked(poko),
                        isPopular: poko.popular
                    ) {
                        viewModel.selectPoko(poko)
                    }
                }
                
                // Random button
                Button(action: { viewModel.selectRandomPoko() }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "06B6D4")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "3B82F6"), lineWidth: 2)
                            )
                        
                        Text("🎲")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Bottom Elements
    
    private var selectHint: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Text("👆")
                    .font(.system(size: 12))
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 1.0 : 0.5)
            
            Text("Tap a Poko to select")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 16)
        .padding(.bottom, 16)
    }
    
    private var updateButton: some View {
        Button(action: {
            if viewModel.hasNewSelection {
                viewModel.commitSelectionIfNeeded()
                dismiss()
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(viewModel.hasNewSelection ? Color(hex: "4ADE80") : Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: viewModel.hasNewSelection ? "checkmark" : "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(viewModel.hasNewSelection ? .black : .white.opacity(0.4))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("UPDATE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2)
                        .foregroundColor(viewModel.hasNewSelection ? Color(hex: "4ADE80") : .white.opacity(0.3))
                    
                    Text("tap here to update your poko")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                viewModel.hasNewSelection
                    ? Color(hex: "4ADE80").opacity(0.1)
                    : Color.white.opacity(0.03)
            )
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        viewModel.hasNewSelection
                            ? Color(hex: "4ADE80").opacity(0.3)
                            : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .disabled(!viewModel.hasNewSelection)
        .opacity(viewModel.hasNewSelection ? 1.0 : 0.4)
        .padding(.vertical, 16)
        .padding(.bottom, 16)
    }
    
    private var readyIndicator: some View {
        Group {
            if viewModel.isOnboarding {
                EmptyView()
            } else {
                updateButton
            }
        }
    }
    
    // MARK: - Loading / Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading Pokos...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await viewModel.loadPokos() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(hex: "FF6B6B"))
            .cornerRadius(8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stat Bar Component

struct StatBar: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FFD700")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Poko Grid Cell

struct PokoGridCell: View {
    let poko: Poko
    let isSelected: Bool
    let isViewing: Bool
    let isOwned: Bool
    let isFeatured: Bool
    let isLocked: Bool
    let isPopular: Bool
    let action: () -> Void
    
    var borderColor: Color {
        if isSelected {
            return Color(hex: "3B82F6") // Blue for selected
        } else if isViewing {
            return Color(hex: "FFD700") // Gold for viewing
        } else if isFeatured {
            return Color(hex: "FF6B6B")
        } else {
            return poko.rarity.color.opacity(0.5)
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "2d2d4e")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .shadow(
                        color: (isSelected || isViewing) ? borderColor.opacity(0.4) : .clear,
                        radius: (isSelected || isViewing) ? 8 : 0
                    )
                
                if isLocked {
                    // Locked overlay
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                    
                    Text("🔒")
                        .font(.system(size: 14))
                } else {
                    // Poko image
                    AsyncImage(url: URL(string: poko.headshotUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(6)
                        case .failure(_):
                            Text("🎮")
                                .font(.system(size: 24))
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.6)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Featured star
                if isFeatured && !isLocked {
                    VStack {
                        HStack {
                            Text("⭐")
                                .font(.system(size: 9))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(2)
                }
                
                // Popular badge
                if isPopular && !isLocked {
                    VStack {
                        HStack {
                            Spacer()
                            Text("HOT")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(hex: "FF6B6B"))
                                .cornerRadius(4)
                                .offset(x: 4, y: -4)
                        }
                        Spacer()
                    }
                }
                
                // Owned indicator
                if isOwned && !isLocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "4ADE80"))
                                    .frame(width: 14, height: 14)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isLocked ? 0.4 : 1.0)
        .disabled(isLocked)
    }
}

// MARK: - Scanlines Overlay

struct ScanlinesOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                for y in stride(from: 0, to: geo.size.height, by: 2) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
