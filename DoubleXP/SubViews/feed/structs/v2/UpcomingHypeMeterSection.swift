//
//  UpcomingHypeMeterSection.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Upcoming Hype Meter Section

struct UpcomingHypeMeterSection: View {
    let games: [GamerConnectGame]
    let namespace: Namespace.ID
    var onGameTapped: (GamerConnectGame) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Upcoming")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                Button {
                    // See all action
                } label: {
                    Text("See All →")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            
            // Hype Cards
            VStack(spacing: 12) {
                ForEach(Array(games.prefix(3).enumerated()), id: \.element.id) { index, game in
                    HypeGameCard(
                        game: game,
                        rank: index + 1,
                        hypePercentage: calculateHypePercentage(for: game),
                        namespace: namespace,
                        onTap: { onGameTapped(game) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    /// Calculate hype percentage relative to max in the list
    private func calculateHypePercentage(for game: GamerConnectGame) -> Double {
        // 1. Get the current game's hype count (safely unwrap to 0 if nil)
        let currentHype = Double(game.hypeCount ?? 0)
        
        // 2. Find the highest hype count in the entire list to define "100%"
        //    We search for the max instead of just using games.first
        //    so this logic holds up even if you sort the list by "Release Date" later.
        let maxHype = games.compactMap { Double($0.hypeCount ?? 0) }.max() ?? 1.0
        
        // 3. Safety check to avoid dividing by zero
        guard maxHype > 0 else { return 0.0 }
        
        // 4. Calculate the raw percentage
        let percentage = (currentHype / maxHype) * 100.0
        
        // 5. UX Polish: Clamp results
        //    If a game has hypes but is very low compared to GTA VI,
        //    we force a minimum 5% width so the bar is at least visible.
        if currentHype > 0 {
            return max(5.0, min(100.0, percentage))
        }
        
        return 0.0
    }
}

// MARK: - Hype Game Card

struct HypeGameCard: View {
    let game: GamerConnectGame
    let rank: Int
    let hypePercentage: Double
    let namespace: Namespace.ID
    var onTap: () -> Void
    
    @State private var isNotifyActive: Bool = false
    @State private var isWishlistActive: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover image with rank badge
            ZStack(alignment: .topLeading) {
                if let url = game.bestImageURL {
                    CachedAsyncImageView(url: url)
                        .frame(width: 80, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1a1a"))
                        .frame(width: 80, height: 105)
                }
                
                // Rank badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
                .offset(x: -6, y: -6)
            }
            
            // Game info
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(game.gameName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Release info
                HStack(spacing: 4) {
                    Text(formattedReleaseDate)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if let developer = game.developer, !developer.isEmpty {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                        Text(developer)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                // Hype meter
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Community Hype")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Spacer()
                        
                        Text("\(Int(hypePercentage))%")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * (hypePercentage / 100))
                                .shadow(color: Color(hex: "FF6B6B").opacity(0.5), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 6)
                }
                
                // Waiting count
                Text(waitingCountText)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                
                // Footer buttons
                HStack(spacing: 0) {
                    // Notify Me button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isNotifyActive.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isNotifyActive ? "bell.fill" : "bell")
                                .font(.system(size: 11))
                            Text("Notify Me")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(isNotifyActive ? Color(hex: "FF6B6B") : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 20)
                    
                    // Wishlist button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isWishlistActive.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isWishlistActive ? "heart.fill" : "heart")
                                .font(.system(size: 11))
                            Text("Wishlist")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(isWishlistActive ? Color(hex: "FF6B6B") : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    // MARK: - Computed Properties
    
    private var formattedReleaseDate: String {
        // Try to parse releaseDate if available
        if let releaseDateStr = game.releaseDate, !releaseDateStr.isEmpty {
            // Parse "YYYY-MM-DD" format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: releaseDateStr) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "MMM yyyy"
                return outputFormatter.string(from: date)
            }
            return releaseDateStr
        }
        return "TBA"
    }
    
    private var waitingCountText: String {
        // Simulate waiting count based on hype percentage
        let baseCount = Int(hypePercentage * 1000)
        return "\(formatCount(baseCount)) waiting"
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.0fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
