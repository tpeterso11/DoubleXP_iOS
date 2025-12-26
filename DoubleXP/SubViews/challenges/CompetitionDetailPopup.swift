//
//  CompetitionDetailPopup.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

// MARK: - Competition Detail Popup

struct CompetitionDetailPopup: View {
    let competition: Competition
    let summary: UserCompetitionSummary?
    let onClose: () -> Void
    let onEnter: () -> Void
    
    @State private var showRules: Bool = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            // Popup Content
            VStack(spacing: 0) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    // Image
                    AsyncImage(url: URL(string: competition.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Rectangle()
                                .fill(Color(hex: "2d2d4e"))
                        @unknown default:
                            Rectangle()
                                .fill(Color(hex: "2d2d4e"))
                        }
                    }
                    .frame(height: 180)
                    .clipped()
                    
                    // Gradient
                    LinearGradient(
                        colors: [.clear, Color(hex: "1a1a2e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Close Button
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(16)
                    
                    // Badge
                    if competition.isFeatured || competition.isSponsored {
                        VStack {
                            Spacer()
                            HStack {
                                tierBadge
                                    .padding(16)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(height: 180)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Type & Time
                        HStack {
                            Text(competition.type.displayName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundColor(Color(hex: "FF6B6B"))
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(competition.timeRemaining)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 20)
                        
                        // Title
                        Text(competition.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        // XP Reward
                        HStack(spacing: 6) {
                            Text("⚡")
                                .font(.system(size: 16))
                            Text("+\(competition.xpReward) XP")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "4ADE80"))
                        }
                        .padding(.top, 12)
                        
                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.vertical, 20)
                        
                        // Extended Description
                        Text("About this Challenge")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        Text(competition.extendedDescription.isEmpty ? competition.description : competition.extendedDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                            .padding(.top, 8)
                        
                        // Submission Type
                        HStack(spacing: 12) {
                            InfoChip(icon: "photo", text: competition.submissionType.displayName)
                            InfoChip(icon: "arrow.counterclockwise", text: "Max \(competition.maxAttempts) tries")
                            InfoChip(icon: "person.2", text: "\(competition.totalEntries) entries")
                        }
                        .padding(.top, 16)
                        
                        // Rules Section
                        rulesSection
                            .padding(.top, 20)
                        
                        // User Entry Status
                        if let summary = summary {
                            userEntrySection(summary)
                                .padding(.top, 20)
                        }
                        
                        // Sponsor Info
                        if competition.isSponsored, let sponsorName = competition.sponsorName {
                            sponsorSection(name: sponsorName, logoUrl: competition.sponsorLogoUrl)
                                .padding(.top, 20)
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action Button
                actionButton
                    .padding(20)
            }
            .background(Color(hex: "1a1a2e"))
            .cornerRadius(24)
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
        }
    }
    
    // MARK: - Tier Badge
    
    private var tierBadge: some View {
        HStack(spacing: 4) {
            Text(competition.isFeatured ? "⭐" : "💎")
                .font(.system(size: 12))
            
            Text(competition.isFeatured ? "FEATURED" : "SPONSORED")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(competition.isFeatured ? .black : Color(hex: "00D2FF"))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            competition.isFeatured
                ? AnyView(LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .leading, endPoint: .trailing))
                : AnyView(Color(hex: "00D2FF").opacity(0.2))
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(competition.isSponsored ? Color(hex: "00D2FF").opacity(0.4) : .clear, lineWidth: 1)
        )
    }
    
    // MARK: - Rules Section
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { showRules.toggle() } }) {
                HStack {
                    Text("📋 Rules & Requirements")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: showRules ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showRules {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(competition.rules.enumerated()), id: \.offset) { index, rule in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "FF6B6B"))
                                .frame(width: 20, alignment: .leading)
                            
                            Text(rule)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - User Entry Section
    
    private func userEntrySection(_ summary: UserCompetitionSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Entry")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            HStack {
                // Attempts
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attempts Used")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<competition.maxAttempts, id: \.self) { index in
                            Circle()
                                .fill(index < summary.attemptsUsed ? Color(hex: "FF6B6B") : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                        
                        Text("\(summary.attemptsUsed)/\(competition.maxAttempts)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Status
                if let status = summary.latestStatus {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Status")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(status.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: status.color))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: status.color).opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Sponsor Section
    
    private func sponsorSection(name: String, logoUrl: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sponsored by")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 12) {
                if let logoUrl = logoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                }
                
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "00D2FF").opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "00D2FF").opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: onEnter) {
            HStack(spacing: 8) {
                if let summary = summary {
                    if summary.hasWon {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Challenge Complete!")
                    } else if summary.canSubmit {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                        Text("Submit Another Entry")
                    } else {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                        Text("Awaiting Review")
                    }
                } else {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16))
                    Text("Enter Challenge")
                }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(buttonTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(buttonBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(summary?.hasWon == true || (summary != nil && !summary!.canSubmit))
    }
    
    private var buttonTextColor: Color {
        if let summary = summary {
            if summary.hasWon {
                return Color(hex: "4ADE80")
            } else if !summary.canSubmit {
                return .white.opacity(0.5)
            }
        }
        return .white
    }
    
    private var buttonBackground: some View {
        Group {
            if let summary = summary {
                if summary.hasWon {
                    Color(hex: "4ADE80").opacity(0.15)
                } else if !summary.canSubmit {
                    Color.white.opacity(0.1)
                } else {
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            } else {
                LinearGradient(
                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}

// MARK: - Info Chip

struct InfoChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}
