//
//  DebugNetworkController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/7/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


#if DEBUG
import Foundation

/// Centralized knobs for simulating rough networks.
final class DebugNetworkController: ObservableObject {
    static let shared = DebugNetworkController()

    @Published var enabled: Bool = false
    @Published var baseLatencyMs: Int = 350         // fixed latency
    @Published var jitterMs: Int = 250              // ± jitter
    @Published var failureRatePct: Int = 8          // 0..100
    @Published var timeoutRatePct: Int = 4          // 0..100

    private init() {}

    /// Await an artificial delay & maybe throw errors to simulate failures/timeouts.
    func simulateHit(maybeBytes: Int? = nil) async throws {
        guard enabled else { return }

        // latency + jitter
        let base = Double(baseLatencyMs)
        let jitter = Double(Int.random(in: -jitterMs...jitterMs))
        let totalMs = max(0, base + jitter)
        try? await Task.sleep(nanoseconds: UInt64(totalMs * 1_000_000))

        // random timeout
        if Int.random(in: 0..<100) < timeoutRatePct {
            throw URLError(.timedOut)
        }
        // random failure
        if Int.random(in: 0..<100) < failureRatePct {
            throw URLError(.cannotConnectToHost)
        }
    }
}
#endif