//
//  FeedLoadingSkeletonView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Feed Loading Skeleton View

struct FeedLoadingSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Carousel/Header Skeleton
            headerSkeleton
            
            // Section Strip Skeleton
            sectionStripSkeleton
            
            // Status Bar Skeleton
            statusBarSkeleton
            
            // Feed Content Skeleton
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // For You Section Skeleton
                    forYouSectionSkeleton
                    
                    // Upcoming Section Skeleton
                    upcomingSectionSkeleton
                }
                .padding(.bottom, 64)
            }
        }
        .background(Color.appBackgroundColor)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Header Skeleton
    
    private var headerSkeleton: some View {
        ZStack(alignment: .bottomLeading) {
            // Background shimmer
            FeedShimmerView()
                .frame(height: 280)
            
            // Gradient overlay
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.3), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 180)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 12) {
                // Badge
                FeedShimmerView()
                    .frame(width: 100, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Title
                FeedShimmerView()
                    .frame(width: 220, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Subtitle
                FeedShimmerView()
                    .frame(width: 160, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Buttons
                HStack(spacing: 12) {
                    FeedShimmerView()
                        .frame(width: 100, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    FeedShimmerView()
                        .frame(width: 100, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
                
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        FeedShimmerView()
                            .frame(width: i == 0 ? 24 : 8, height: 8)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Section Strip Skeleton
    
    private var sectionStripSkeleton: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                FeedShimmerView()
                    .frame(width: i == 0 ? 80 : 70, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Status Bar Skeleton
    
    private var statusBarSkeleton: some View {
        HStack {
            // Hearts
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    FeedShimmerView()
                        .frame(width: 14, height: 12)
                        .clipShape(HeartShape())
                }
            }
            
            // Level text
            FeedShimmerView()
                .frame(width: 140, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Spacer()
            
            // Icons
            HStack(spacing: 16) {
                FeedShimmerView()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                
                FeedShimmerView()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(hex: "FF6B6B").opacity(0.08), Color(hex: "9333EA").opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - For You Section Skeleton
    
    private var forYouSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                FeedShimmerView()
                    .frame(width: 80, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                FeedShimmerView()
                    .frame(width: 60, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 20)
            
            // Featured hero card
            FeedShimmerView()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)
            
            // Story indicators
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    FeedShimmerView()
                        .frame(width: i == 0 ? 32 : 32, height: 4)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            
            // "Based on your games" label
            FeedShimmerView()
                .frame(width: 140, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            // Horizontal scroll cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            FeedShimmerView()
                                .frame(width: 100, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            FeedShimmerView()
                                .frame(width: 80, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            FeedShimmerView()
                                .frame(width: 60, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Upcoming Section Skeleton
    
    private var upcomingSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                FeedShimmerView()
                    .frame(width: 100, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                FeedShimmerView()
                    .frame(width: 60, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 20)
            
            // Hype cards
            VStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in
                    hypeCardSkeleton
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var hypeCardSkeleton: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Cover with rank badge
                ZStack(alignment: .topLeading) {
                    FeedShimmerView()
                        .frame(width: 80, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    FeedShimmerView()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .offset(x: -6, y: -6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    FeedShimmerView()
                        .frame(width: 140, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // Release info
                    FeedShimmerView()
                        .frame(width: 120, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // Hype meter
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            FeedShimmerView()
                                .frame(width: 80, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            Spacer()
                            
                            FeedShimmerView()
                                .frame(width: 30, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        FeedShimmerView()
                            .frame(height: 6)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    
                    // Waiting count
                    FeedShimmerView()
                        .frame(width: 90, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
            }
            .padding(14)
            
            // Footer buttons
            HStack(spacing: 0) {
                FeedShimmerView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 1, height: 44)
                
                FeedShimmerView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Shimmer View

struct FeedShimmerView: View {
    @State private var startPoint = UnitPoint(x: -1, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.12),
                Color.white.opacity(0.05)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                startPoint = UnitPoint(x: 1, y: 0.5)
                endPoint = UnitPoint(x: 2, y: 0.5)
            }
        }
    }
}

// MARK: - Heart Shape for Skeleton

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.15, y: 0))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.85, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.35))
        path.closeSubpath()
        
        return path
    }
}