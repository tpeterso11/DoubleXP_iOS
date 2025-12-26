//
//  VideoArticleView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import AVKit

struct VideoArticleView: View {
    let article: Article
    let namespace: Namespace.ID
    @State private var showComments = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // 1. Sticky Video Player Area
                    Color.zinc800
                        .frame(width: geometry.size.width, height: 240)
                        .overlay {
                            if let videoUrl = article.videoThumbnailUrl.flatMap({ URL(string: $0) }) ?? article.imageUrl.flatMap({ URL(string: $0) }) {
                                AsyncImage(url: videoUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: 240)
                                        .clipped()
                                } placeholder: {
                                    Color.zinc800
                                }
                            }
                        }
                        .clipped()
                        .overlay(
                            // Play Button Overlay
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                )
                        )
                        .overlay(alignment: .bottom) {
                            // Progress bar simulation
                            Rectangle()
                                .fill(Color.red)
                                .frame(height: 3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(width: 120)
                        }
                    
                    // 2. Scrollable Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Metadata
                            HStack {
                                Text("EXCLUSIVE")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(Capsule())
                                
                                Text("• \(article.source) • \(relativeTimeString(for: article.publishedAt))")
                                    .font(.caption)
                                    .foregroundStyle(Color.zinc400)
                            }
                            
                            Text(article.title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Author Row
                            HStack {
                                Circle()
                                    .fill(Color.zinc700)
                                    .frame(width: 32, height: 32)
                                    .overlay(Text(String(article.source.prefix(1))).font(.caption.bold()).foregroundStyle(.white))
                                
                                VStack(alignment: .leading) {
                                    Text(article.source)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.zinc200)
                                    Text("Senior Editor")
                                        .font(.caption)
                                        .foregroundStyle(Color.zinc500)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.bottom, 8)
                            
                            Divider().background(Color.zinc800)
                            
                            // Body Text
                            Text(article.description ?? "No content available.")
                                .font(.body)
                                .foregroundStyle(Color.zinc300)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Mock long content for scrolling
                            ForEach(0..<3) { _ in
                                Text(LoremIpsum.paragraph)
                                    .font(.body)
                                    .foregroundStyle(Color.zinc300)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 120)
                    }
                }
                
                // Fixed action bar at bottom of screen (above tab bar)
                FloatingActionBar(
                    articleID: article.id,
                    namespace: namespace,
                    articleURL: article.url,
                    // 2. PASS THE ACTION
                    onCommentTapped: {
                        showComments = true
                    }
                ).padding(.bottom, geometry.safeAreaInsets.bottom + 64 + 16)
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(mediaId: article.id, mediaType: .article)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct BottomActionBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 20) {
                Button {} label: { Image(systemName: "heart").font(.title3) }
                Button {} label: { Image(systemName: "bubble.right").font(.title3) }
            }
            Spacer()
            Button {} label: { Image(systemName: "square.and.arrow.up").font(.title3) }
        }
        .foregroundStyle(Color.zinc400)
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct LoremIpsum {
    static let paragraph = "The internet is ablaze this morning following a massive data dump that appears to originate from within Game Freak's internal servers. The files, totaling over 4 terabytes, contain concept art, source code, and design documents."
    static let longText = "The results were as chaotic as you might expect. While some actors managed to capture the essence of their co-stars' roles surprisingly well, others descended into pure parody. It serves as a reminder of just how distinct these performances are. The writing in BG3 is stellar, but the life breathed into these polygons by the cast is what truly cemented it as a GOTY contender."
}

fileprivate func relativeTimeString(for date: Date) -> String {
    let now = Date()
    let components = Calendar.current.dateComponents([.hour, .minute], from: date, to: now)
    
    if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)m ago"
    } else {
        return "Just now"
    }
}

extension Color {
    static let zinc200 = Color(red: 0.89, green: 0.89, blue: 0.91)
    static let zinc300 = Color(red: 0.83, green: 0.83, blue: 0.86)
    static let zinc400 = Color(red: 0.63, green: 0.63, blue: 0.66)
    static let zinc500 = Color(red: 0.45, green: 0.45, blue: 0.48)
    static let zinc700 = Color(red: 0.24, green: 0.24, blue: 0.26)
    static let zinc800 = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let zinc900 = Color(red: 0.10, green: 0.10, blue: 0.11)
}

