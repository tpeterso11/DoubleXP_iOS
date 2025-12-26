//
//  FlippableViewManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import SwiftUI

struct FlippableViewManager {
    let post: RedditPost
    
    /*var frontViewBackgroundColor: Color {
        // Logic to determine color based on post content
        if post.videoURL != nil {
            return .blue
        } else if post.imageURL != nil {
            return .purple
        } else {
            return .gray
        }
    }
    
    var frontViewSymbolName: String {
        if post.videoURL != nil {
            return "video.fill"
        } else if post.imageURL != nil {
            return "photo.fill"
        } else {
            return "text.bubble.fill"
        }
    }
}

struct FlippablePostView_Previews: PreviewProvider {
    // 1. Create a mock of your REAL, Codable data model
    static let mockCodablePost: RedditPost = .init(
        title: "The art style in 'Hades' is just unmatched",
        url: "",
        permalink: "hades_art_style",
        author: "u/artlover",
        subreddit: "r/indiegaming",
        thumbnail: nil,
        imageURL: "some_image_url",
        videoURL: nil,
        bodyText: "Seriously, every single frame in this game could be a wallpaper. The character designs, the environments, the attack animations... it's all so cohesive and beautiful. Supergiant Games really outdid themselves. What are some other games with incredible art direction that you love?",
        score: 7200,
        commentCount: 540
    )
    
    // 2. Create the View Manager from that data
    static let mockManager = FlippableViewManager(post: mockCodablePost)
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Flippable Post Cell")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 3. Pass the manager to the view
                FlippablePostView(manager: mockManager)
                
                Text("Tap the card to see it flip!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }*/
}
