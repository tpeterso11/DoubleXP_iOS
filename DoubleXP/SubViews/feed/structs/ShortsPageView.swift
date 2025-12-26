//
//  ShortsPageView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct ShortsPageView: View {
    @StateObject private var shortsService = YouTubeShortsService.shared
    @State private var currentIndex: Int = 0
    @State private var isRefreshing: Bool = false
    @State private var currentProgress: CGFloat = 0.0
    
    private let visibleSegmentCount: Int = 5
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if shortsService.isLoading && shortsService.shorts.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else if let error = shortsService.errorMessage, !error.isEmpty, shortsService.shorts.isEmpty {
                errorView
            } else if !shortsService.shorts.isEmpty {
                ZStack(alignment: .top) {
                    // Main content
                    TabView(selection: $currentIndex) {
                        ForEach(Array(shortsService.shorts.enumerated()), id: \.element.id) { index, short in
                            ShortVideoView(
                                short: short,
                                isActive: isActive && index == currentIndex,
                                onSwipeUp: {
                                    goToNext()
                                },
                                onSwipeDown: {
                                    if currentIndex == 0 {
                                        triggerRefresh()
                                    } else {
                                        goToPrevious()
                                    }
                                },
                                onVideoEnded: {
                                    print("🎬 Video ended, advancing")
                                    goToNext()
                                },
                                onProgressUpdate: { progress in
                                    if index == currentIndex {
                                        currentProgress = progress
                                    }
                                },
                                onFollowToggle: {
                                    // Handle follow/unfollow logic here
                                    print("👤 Follow toggled for: \(short.channelTitle)")
                                }
                            )
                            .tag(index)
                            .onAppear {
                                if index == currentIndex {
                                    print("📺 Video \(index) active: \(short.title)")
                                    shortsService.markShortSeen(short)
                                    Task {
                                        await shortsService.loadMoreIfNeeded(currentShort: short)
                                    }
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Segmented Progress Bar
                    VStack {
                        SegmentedProgressBar(
                            segmentCount: min(visibleSegmentCount, shortsService.shorts.count - currentIndex),
                            currentIndex: 0,
                            currentProgress: currentProgress,
                            spacing: 4,
                            height: 3
                        )
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .zIndex(50)
                    
                    // Pull-to-refresh indicator
                    if isRefreshing {
                        VStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.5)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 60, height: 60)
                                )
                            Spacer()
                        }
                        .transition(.opacity)
                        .zIndex(100)
                    }
                }
            }
        }
        .task {
            if shortsService.shorts.isEmpty {
                await shortsService.ensureInitialPage()
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            print("📍 Index changed from \(oldValue) to \(newValue)")
            currentProgress = 0.0
        }
        .onChange(of: isActive) { oldValue, newValue in
            print("🎥 [Shorts] Active state changed: \(oldValue) -> \(newValue)")
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 12) {
            Text("Couldn't load shorts")
                .font(.headline)
                .foregroundStyle(.white)
            
            if let error = shortsService.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task { await shortsService.ensureInitialPage() }
            } label: {
                Text("Retry")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func goToNext() {
        if currentIndex < shortsService.shorts.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        }
    }
    
    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex -= 1
            }
        }
    }
    
    private func triggerRefresh() {
        guard !isRefreshing else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isRefreshing = true
        }
        
        Task {
            await shortsService.refresh()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isRefreshing = false
                    currentIndex = 0
                    currentProgress = 0.0
                }
            }
        }
    }
}

struct SegmentedProgressBar: View {
    var segmentCount: Int
    var currentIndex: Int
    var currentProgress: CGFloat
    var spacing: CGFloat = 4
    var height: CGFloat = 3
    var inactiveColor: Color = Color.white.opacity(0.3)
    var activeColor: Color = Color.white

    @State private var segments: [SegmentModel] = []
    @State private var droppingSegmentId: UUID? = nil

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(segments) { segment in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(inactiveColor)

                        Capsule()
                            .fill(activeColor)
                            .frame(
                                width: calculateFillWidth(
                                    for: segment,
                                    totalWidth: geometry.size.width
                                )
                            )
                            .animation(.linear(duration: 0.1), value: currentProgress)
                            .animation(.linear(duration: 0.1), value: segment.videoIndex)
                    }
                    .opacity(droppingSegmentId == segment.id ? 0 : 1)
                    .offset(y: droppingSegmentId == segment.id ? 30 : 0)
                    .scaleEffect(droppingSegmentId == segment.id ? 0.8 : 1.0)
                    .animation(.easeOut(duration: 0.5), value: droppingSegmentId)
                }
                .frame(height: height)
            }
        }
        .onAppear {
            #if DEBUG
            print("🟢 [SegmentedProgressBar] onAppear - segmentCount=\(segmentCount), currentIndex=\(currentIndex), currentProgress=\(currentProgress)")
            #endif
            initializeSegments()
        }
        .onChange(of: currentProgress) { oldValue, newValue in
            let threshold: CGFloat = 0.99

            #if DEBUG
            let oldStr = String(format: "%.3f", oldValue)
            let newStr = String(format: "%.3f", newValue)
            print("📈 [SegmentedProgressBar] currentProgress changed \(oldStr) → \(newStr), currentIndex=\(currentIndex)")
            #endif

            // When we cross 99% progress, try to drop the first segment
            if newValue >= threshold && oldValue < threshold {
                #if DEBUG
                print("✅ [SegmentedProgressBar] Progress crossed threshold (\(threshold)) → triggerSegmentDrop()")
                #endif
                triggerSegmentDrop()
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            #if DEBUG
            print("🎬 [SegmentedProgressBar] currentIndex changed \(oldValue) → \(newValue)")
            #endif

            if newValue == 0 {
                #if DEBUG
                print("🔄 [SegmentedProgressBar] currentIndex reset to 0 → re-initialize segments")
                #endif
                initializeSegments()
                droppingSegmentId = nil
            } else {
                #if DEBUG
                print("➡️ [SegmentedProgressBar] currentIndex moved forward to \(newValue)")
                #endif
            }
        }
        .onChange(of: droppingSegmentId) { oldValue, newValue in
            #if DEBUG
            print("💧 [SegmentedProgressBar] droppingSegmentId changed \(String(describing: oldValue)) → \(String(describing: newValue))")
            #endif
        }
    }

    // MARK: - Setup

    private func initializeSegments() {
        #if DEBUG
        print("🧩 [SegmentedProgressBar] initializeSegments() called")
        print("    - incoming segmentCount = \(segmentCount)")
        print("    - currentIndex         = \(currentIndex)")
        #endif

        segments.removeAll()

        for index in 0..<segmentCount {
            let seg = SegmentModel(videoIndex: index)
            segments.append(seg)
            #if DEBUG
            print("    ▶️ created segment [\(index)] id=\(seg.id) videoIndex=\(seg.videoIndex)")
            #endif
        }

        logSegments("After initializeSegments()")
    }

    // MARK: - Fill logic

    private func calculateFillWidth(for segment: SegmentModel, totalWidth: CGFloat) -> CGFloat {
        // Normal case: segment corresponds to currentIndex
        if segment.videoIndex == currentIndex {
            let clampedProgress = max(0, min(1, currentProgress))
            let w = totalWidth * clampedProgress
            #if DEBUG
            print("🧮 [SegmentedProgressBar] fillWidth (ACTIVE) for segment videoIndex=\(segment.videoIndex), currentIndex=\(currentIndex), progress=\(clampedProgress), width=\(w)")
            #endif
            return w
        }

        // Past segments are full
        if segment.videoIndex < currentIndex {
            #if DEBUG
            print("🧮 [SegmentedProgressBar] fillWidth (PAST/FULL) for segment videoIndex=\(segment.videoIndex), currentIndex=\(currentIndex), width=\(totalWidth)")
            #endif
            return totalWidth
        }

        // Fallback: if currentIndex is not in visible segments, treat first as active
        if !segments.contains(where: { $0.videoIndex == currentIndex }) {
            if let first = segments.first, first.id == segment.id {
                let clampedProgress = max(0, min(1, currentProgress))
                let w = totalWidth * clampedProgress
                #if DEBUG
                print("🧮 [SegmentedProgressBar] fillWidth (FALLBACK ACTIVE FIRST) for segment videoIndex=\(segment.videoIndex), currentIndex=\(currentIndex), progress=\(clampedProgress), width=\(w)")
                #endif
                return w
            }
        }

        // Future segments start empty
        #if DEBUG
        print("🧮 [SegmentedProgressBar] fillWidth (FUTURE/EMPTY) for segment videoIndex=\(segment.videoIndex), currentIndex=\(currentIndex), width=0")
        #endif
        return 0
    }

    // MARK: - Drop / slide behavior

    private func triggerSegmentDrop() {
        guard let firstSegment = segments.first else {
            #if DEBUG
            print("⚠️ [SegmentedProgressBar] triggerSegmentDrop() called but segments is EMPTY")
            #endif
            return
        }

        #if DEBUG
        print("💧 [SegmentedProgressBar] triggerSegmentDrop() starting")
        print("    - currentIndex              = \(currentIndex)")
        print("    - firstSegment.videoIndex   = \(firstSegment.videoIndex)")
        print("    - firstSegment.id           = \(firstSegment.id)")
        logSegments("Before drop animation")
        #endif

        // Small delay so 100% is visible first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            #if DEBUG
            print("⏱ [SegmentedProgressBar] Starting drop animation for id=\(firstSegment.id)")
            #endif

            withAnimation(.easeOut(duration: 0.5)) {
                droppingSegmentId = firstSegment.id
            }

            // After drop animation completes, remove it and append new one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                #if DEBUG
                print("🗑 [SegmentedProgressBar] Removing first segment and appending new one")
                #endif

                withAnimation(.easeInOut(duration: 0.4)) {
                    if !segments.isEmpty {
                        let removed = segments.removeFirst()
                        #if DEBUG
                        print("    🔻 removed segment id=\(removed.id) videoIndex=\(removed.videoIndex)")
                        #endif
                    } else {
                        #if DEBUG
                        print("    ⚠️ segments already empty when trying to removeFirst()")
                        #endif
                    }

                    let newVideoIndex = (segments.last?.videoIndex ?? currentIndex) + 1
                    let newSegment = SegmentModel(videoIndex: newVideoIndex)
                    segments.append(newSegment)

                    #if DEBUG
                    print("    ➕ appended new segment id=\(newSegment.id) videoIndex=\(newSegment.videoIndex)")
                    logSegments("After removing first and appending new")
                    #endif
                }

                // Clear dropping state a bit after the shift
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    #if DEBUG
                    print("♻️ [SegmentedProgressBar] Clearing droppingSegmentId")
                    #endif
                    droppingSegmentId = nil
                }
            }
        }
    }

    // MARK: - Logging helper

    private func logSegments(_ label: String) {
        #if DEBUG
        print("🔍 [SegmentedProgressBar] \(label)")
        print("    segments.count = \(segments.count)")
        for (idx, seg) in segments.enumerated() {
            print("    [\(idx)] id=\(seg.id) videoIndex=\(seg.videoIndex)")
        }
        #endif
    }
}

struct SegmentModel: Identifiable {
    let id = UUID()
    let videoIndex: Int
}
