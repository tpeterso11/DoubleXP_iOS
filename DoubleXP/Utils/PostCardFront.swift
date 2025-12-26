//
//  PostCardFront.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct PostCardFront: View {
    let manager: FlippableViewManager
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            //PlaceholderImageView(symbolName: manager.frontViewSymbolName, color: manager.frontViewBackgroundColor)

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(manager.post.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Text(manager.post.subreddit ?? "")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding()
        }
        .cornerRadius(12)
        .clipped()
    }
}
