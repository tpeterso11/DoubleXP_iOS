//
//  FlipModifier.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct FlipModifier: ViewModifier {
    let isFlipped: Bool
    let rotation: Double
    
    func body(content: Content) -> some View {
        content
            // The opacity ensures the back is hidden until it's mostly flipped over
            .opacity(isFlipped ? (rotation == -180 ? 1 : 0) : (rotation == 0 ? 1 : 0))
            .rotation3DEffect(
                .degrees(isFlipped ? rotation + 180 : rotation),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
    }
}
