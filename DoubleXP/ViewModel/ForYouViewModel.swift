//
//  ForYouViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/9/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

struct ForYouGame: Identifiable {
    let game: GamerConnectGame
    let isFeatured: Bool
    
    var id: String { game.id } // Pass through the ID
}

/// These enums represent the *layout*, not the data
/// The ViewModel will convert [ForYouGame] into [ForYouItem]
enum ForYouItemType {
    case singleHighlighted(ForYouGame)
    case doubleStandard(ForYouGame, ForYouGame)
    case singleStandard(ForYouGame) // For an odd number of non-featured games
}

struct ForYouItem: Identifiable {
    let id = UUID()
    let type: ForYouItemType
}

private extension FeedCard {
    var asForYouGame: ForYouGame {
        switch self {
        case .normal(let g):   return ForYouGame(game: g, isFeatured: false)
        case .featured(let g): return ForYouGame(game: g, isFeatured: true)
        }
    }
}

/// This class does the work of grouping your games into the correct layout
final class ForYouViewModel: ObservableObject {
    @Published var forYouItems: [ForYouItem] = []

    /// Public entry from `[FeedCard]`
    func buildFeed(from feedCards: [FeedCard], dropLastOdd: Bool = true) {
        let games = feedCards.map { $0.asForYouGame }
        buildFeedIndividual(fromForYouGames: games)
    }

    /// Public entry if callers already provide `[ForYouGame]`
    func buildFeed(from games: [ForYouGame], dropLastOdd: Bool = true) {
        buildFeedIndividual(fromForYouGames: games)
    }

    /// Core: produce individual items that will be laid out in a grid
    private func buildFeedIndividual(fromForYouGames games: [ForYouGame]) {
        var items: [ForYouItem] = []
        
        for game in games {
            if game.isFeatured {
                // Featured games get their own highlighted row
                items.append(ForYouItem(type: .singleHighlighted(game)))
            } else {
                // Standard games get individual cells (will be laid out in grid by the view)
                items.append(ForYouItem(type: .singleStandard(game)))
            }
        }
        
        self.forYouItems = items
    }
    
    // MARK: - Legacy pairing logic (keep if needed elsewhere)
    
    /// Alternative: produce only .doubleStandard and .singleHighlighted (original behavior)
    private func buildFeedPairsOnly(fromForYouGames games: [ForYouGame],
                                    dropLastOdd: Bool) {
        // 1) Collect non-featured in original order
        var nonFeatured = games.filter { !$0.isFeatured }

        // 2) Enforce even count (no singles)
        if nonFeatured.count % 2 == 1 {
            if dropLastOdd {
                _ = nonFeatured.popLast() // drop the last stray
            } else {
                // fallback if you ever want to allow a single at the very end:
                // keep it and we'll let the view show one .singleStandard
            }
        }

        // 3) Create the queue of pairs from non-featured (preserving order)
        var pairQueue: [(ForYouGame, ForYouGame)] = []
        var nfIdx = 0
        while nfIdx + 1 < nonFeatured.count {
            pairQueue.append((nonFeatured[nfIdx], nonFeatured[nfIdx + 1]))
            nfIdx += 2
        }

        // 4) Walk the original list and emit:
        //    - featured exactly where they appear
        //    - when we hit a non-featured we haven't consumed yet, emit the *next pair*
        //      (this preserves global order of non-featured while avoiding 3-ups)
        var consumedIds = Set<String>()
        var items: [ForYouItem] = []

        func nextPairIfAvailable() {
            guard !pairQueue.isEmpty else { return }
            let (a, b) = pairQueue.removeFirst()
            consumedIds.insert(a.id)
            consumedIds.insert(b.id)
            items.append(ForYouItem(type: .doubleStandard(a, b)))
        }

        for g in games {
            if g.isFeatured {
                items.append(ForYouItem(type: .singleHighlighted(g)))
            } else if !consumedIds.contains(g.id) {
                // emit the *next* pair from the queue at this position
                nextPairIfAvailable()
            }
        }

        // If anything is somehow left (e.g., the list ended with many featured),
        // append remaining pairs at the end to keep everything visible.
        while !pairQueue.isEmpty {
            let (a, b) = pairQueue.removeFirst()
            items.append(ForYouItem(type: .doubleStandard(a, b)))
        }

        self.forYouItems = items
    }
}


