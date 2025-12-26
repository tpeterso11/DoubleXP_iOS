//
//  FeedErrorView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import SwiftUI

// MARK: - Feed Error View

struct FeedErrorView: View {
    let message: String
    var onRetry: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon with animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Oops! Something went wrong")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 40)
            }
            
            // Retry button
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Try Again")
                        .font(.body.weight(.semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Secondary action
            Button {
                // Could navigate to settings or help
            } label: {
                Text("Check connection settings")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackgroundColor)
        .onAppear {
            isAnimating = true
        }
    }
}
