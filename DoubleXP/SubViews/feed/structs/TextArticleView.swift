//
//  TextArticleView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct TextArticleView: View {
    let article: Article
    let namespace: Namespace.ID
    @State private var showComments = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 100)
                        
                        VStack(alignment: .leading, spacing: 24) {
                            Text("OPINION")
                                .font(.caption.bold())
                                .tracking(2)
                                .foregroundStyle(Color.zinc300)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.zinc700, lineWidth: 1)
                                )
                            
                            Text(article.title)
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 40, height: 40)
                                    .overlay(Text(String(article.source.prefix(1))).font(.headline).foregroundStyle(.white))
                                
                                VStack(alignment: .leading) {
                                    Text(article.source)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("Nov 14 • 4 min read")
                                        .font(.caption)
                                        .foregroundStyle(Color.zinc500)
                                }
                            }
                            .padding(.bottom, 16)
                            .padding(.top, 8)
                            
                            Divider().background(Color.zinc800)
                            
                            VStack(alignment: .leading, spacing: 24) {
                                Text(article.description ?? "")
                                    .font(.title3.italic())
                                    .foregroundStyle(Color.zinc200)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                HStack(spacing: 16) {
                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: 4)
                                    Text("It was absolute chaos in the booth. I don't think I've ever heard a warlock patron sound quite so... British.")
                                        .font(.body.italic())
                                        .foregroundStyle(Color.zinc400)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 8)
                                
                                Text(LoremIpsum.longText)
                                    .font(.system(.body, design: .serif))
                                    .foregroundStyle(Color.zinc300)
                                    .lineSpacing(8)
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
