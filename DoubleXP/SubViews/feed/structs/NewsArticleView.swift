//
//  NewsArticleView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct NewsArticleView: View {
    let article: Article
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                
                ZStack(alignment: .top) {
                    switch article.cellKind {
                    case .video:
                        VideoArticleView(article: article, namespace: namespace)
                    case .image:
                        ImageArticleView(article: article, namespace: namespace)
                    case .text:
                        TextArticleView(article: article, namespace: namespace)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.zinc900)
                .clipShape(RoundedRectangle(cornerRadius: dragOffset.height > 0 ? 20 : 0))
                .offset(y: max(0, dragOffset.height))
                .scaleEffect(1.0 - (max(0, dragOffset.height) / 1000.0))
                .shadow(radius: 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                self.dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 150 {
                                onDismiss()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    self.dragOffset = .zero
                                }
                            }
                        }
                )
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .background(Color.black.opacity(0.4).clipShape(Circle()))
                }
                .padding(.top, geo.safeAreaInsets.top + 16)
                .padding(.trailing, 20)
                .opacity(dragOffset.height > 20 ? 0 : 1)
                .animation(.easeOut(duration: 0.1), value: dragOffset.height)
            }
            .ignoresSafeArea()
        }
    }
}
