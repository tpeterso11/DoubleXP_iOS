//
//  CircularRatingView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct CircularRatingView: View {
    /// 0–10 score (from IGDB etc.)
    let score: Double?
    /// Short label under the score ("IGDB", "USER", etc.)
    let label: String

    private var clampedScore: Double {
        guard let score = score else { return 0 }
        return min(max(score, 0), 10)
    }

    /// 0–1 progress used for the arc
    private var progress: CGFloat {
        CGFloat(clampedScore / 10.0)
    }

    private var scoreText: String {
        guard let score = score else { return "–" }
        return String(format: "%.1f", score)
    }

    /// Optionally tint based on the score (you can tweak thresholds/colors)
    private var ringColor: Color {
        switch clampedScore {
        case 0..<5:   return Color.red
        case 5..<7.5: return Color.orange
        default:      return Color.green
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )

            // Foreground progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // start at top

            // Center content (score + tiny label at bottom)
            VStack(spacing: 2) {
                Text(scoreText)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.primary)

                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: 42, height: 42) // tweak as needed
    }
}
