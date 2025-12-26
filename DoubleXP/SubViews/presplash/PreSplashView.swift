//
//  PreSplashView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI
import AVKit

struct PreSplashView: View {

    @StateObject private var viewModel = PreSplashViewModel()
    let onFinished: (_ isReturningUser: Bool) -> Void

    var body: some View {
        ZStack {
            // Full-screen video
            PreSplashVideoView {
                viewModel.markVideoFinished()
            }
            .ignoresSafeArea()

            // Spinner overlay
            VStack {
                Spacer()
                if viewModel.isBlockingForData {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.6)
                        Text("Loading your feed…")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.start(onFinished: onFinished)
        }
    }
}
