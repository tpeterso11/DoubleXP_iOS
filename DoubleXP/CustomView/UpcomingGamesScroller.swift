//
//  UpcomingGamesScroller.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class UpcomingGamesScroller:UITableViewCell {
    
    @IBOutlet weak var games: UICollectionView!
    var adapter: UpcomingGamesAdapter?
}

final class UpcomingGamesAdapter: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                  UICollectionViewDataSourcePrefetching  {
    private(set) var items: [UpcomingGame]
    var onSelect: ((UpcomingGame, UICollectionViewCell) -> Void)?
    private var prefetchTasks = [IndexPath: Task<Void, Never>]()

    init(items: [UpcomingGame]) {
        self.items = items
        super.init()
    }
    
    func attach(to cv: UICollectionView) {
        cv.prefetchDataSource = self
        cv.decelerationRate = .fast   // quicker flick feel
    }

    func update(_ newItems: [UpcomingGame], in collectionView: UICollectionView) {
        self.items = newItems
        collectionView.reloadData()
    }

    // MARK: DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "game", for: indexPath) as! UpcomingGamesScrollerGame
        cell.configure(with: items[indexPath.item])
        return cell
    }

    // MARK: FlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Fill the height, keep a nice card width
        //let h = collectionView.bounds.height
        //let w = max(150, min(260, h * 0.75 + 80))  // tune to taste
        return CGSize(width: 150, height: 200)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 12 }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ cv: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { idx -> URL? in
            URL(string: items[idx.item].gameImageUrl ?? "")
        }
        for indexPath in indexPaths {
            guard let url = URL(string: items[indexPath.item].gameImageUrl ?? "") else { continue }
            
            // ✅ Create a new Task that calls the actor's method.
            // The Task itself becomes the cancellable handle.
            let task = Task {
                // The 'await' is now safely inside an asynchronous context.
                _ = await ImageCache.shared.image(for: url)
            }
            
            // Store the handle.
            prefetchTasks[indexPath] = task
        }
    }
    
    func collectionView(_ cv: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let task = prefetchTasks[indexPath] {
                // Find the task, cancel it, and remove it from our tracking dictionary.
                task.cancel()
                prefetchTasks.removeValue(forKey: indexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game = items[indexPath.item]
        // Get the cell that was tapped
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        
        // Pass both the game and the cell back to the controller
        onSelect?(game, cell)
    }
}
