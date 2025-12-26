//
//  NewsHeroImage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct NewsHeroImage: View {
    let article: Article
    let namespace: Namespace.ID

    @Environment(\.colorScheme) private var colorScheme

    private var imageURL: URL? {
        // Prefer video thumbnail, then image
        if let thumb = article.videoThumbnailUrl, let url = URL(string: thumb) {
            return url
        }
        if let img = article.imageUrl, let url = URL(string: img) {
            return url
        }
        return nil
    }

    var body: some View {
        ZStack {
            Group {
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

                        case .failure:
                            placeholder

                        case .empty:
                            placeholder

                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .clipped()

            // Dark gradient at bottom for legibility (optional; matches your rows)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.15),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .allowsHitTesting(false)
        }
        // 🔑 This is what ties list + detail together
        .matchedGeometryEffect(
            id: "article-hero-image-\(article.id)",
            in: namespace
        )
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
    }
}
