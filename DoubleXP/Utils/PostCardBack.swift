//
//  PostCardBack.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct PostCardBack: View {
    let manager: FlippableViewManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(manager.post.title)
                .font(.title3)
                .fontWeight(.bold)
            
            Text("\(manager.post.subreddit) • by \(manager.post.author)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
                
            /*if let bodyText = manager.post.bodyText, !bodyText.isEmpty {
                ScrollView {
                    Text(bodyText)
                        .font(.body)
                }
            } else {
                // Provide a fallback view if there's no text
                VStack {
                    Spacer()
                    Text("No additional text for this post.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }*/
            
            Spacer()

            HStack(spacing: 16) {
                //PostMetadataView(iconName: "arrow.up", text: "\(manager.post.score / 1000)k")
                //PostMetadataView(iconName: "text.bubble", text: "\(manager.post.commentCount)")
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
