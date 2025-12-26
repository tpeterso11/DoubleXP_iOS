//
//  ImageArticleView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ImageArticleView: View {
    let article: Article
    let namespace: Namespace.ID
    @State private var showComments = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // 1. Hero Image Container (matched geometry target)
                        ZStack(alignment: .bottom) {
                            // 🔄 Shared hero image — same matchedGeometryEffect id as in the row
                            NewsHeroImage(article: article, namespace: namespace)
                                .frame(width: geometry.size.width, height: 450)
                                .clipped()

                            // Extra gradient if you still want a stronger fade
                            LinearGradient(
                                colors: [.black, .black.opacity(0), .black.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 300)
                            .allowsHitTesting(false)

                            // Title Overlay
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Text(String(article.source.prefix(1)))
                                                .font(.caption2.bold())
                                                .foregroundStyle(.black)
                                        )

                                    Text("\(article.source) • \(relativeTimeString(for: article.publishedAt))")
                                        .font(.caption.bold())
                                        .textCase(.uppercase)
                                        .foregroundStyle(Color.zinc300)
                                }

                                Text(article.title)
                                    .font(.largeTitle.weight(.black))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(24)
                            .padding(.bottom, 24)
                        }
                        
                        // 2. Content
                        VStack(alignment: .leading, spacing: 20) {
                            Text(article.description ?? "")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(Color.zinc400)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(LoremIpsum.paragraph)
                                .font(.body)
                                .foregroundStyle(Color.zinc300)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.zinc800)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    Text("Concept Art")
                                        .foregroundStyle(Color.zinc500)
                                )
                            
                            Text(LoremIpsum.paragraph)
                                .font(.body)
                                .foregroundStyle(Color.zinc300)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
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
                    onCommentTapped: {
                        showComments = true // 2. Trigger State
                    }
                )
                .padding(.bottom, geometry.safeAreaInsets.bottom + 64 + 16)
            }.sheet(isPresented: $showComments) {
                // Pass the Article ID so the comments load for THIS specific content
                CommentsView(mediaId: article.id, mediaType: .article)
                    .presentationDetents([.fraction(0.85), .large]) // iOS 16+ nice sizing
                    .presentationDragIndicator(.visible)
            }
        }
    }
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
