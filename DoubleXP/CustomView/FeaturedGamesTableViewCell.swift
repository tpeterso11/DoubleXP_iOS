//
//  FeaturedGamesTableViewCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

final class FeaturedGamesAdapter: NSObject,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegateFlowLayout,
                                  UICollectionViewDataSourcePrefetching {

    private(set) var items: [GamerConnectGame]
    var onSelect: ((GamerConnectGame, UICollectionViewCell) -> Void)?
    private var prefetchTasks: [IndexPath: Task<Void, Never>] = [:]

    init(items: [GamerConnectGame] = []) {
        self.items = items
        super.init()
    }

    func attach(to cv: UICollectionView) {
        cv.dataSource = self
        cv.delegate = self
        cv.prefetchDataSource = self
        cv.decelerationRate = .fast
    }

    func detach(from cv: UICollectionView) {
        cv.dataSource = nil
        cv.delegate = nil
        cv.prefetchDataSource = nil
        // cancel any outstanding prefetches
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }

    func update(_ newItems: [GamerConnectGame], in collectionView: UICollectionView) {
        self.items = newItems
        collectionView.reloadData()
    }

    // MARK: DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeaturedGameCell.reuseIdentifier,
            for: indexPath
        ) as! FeaturedGameCell
        let game = items[indexPath.item]
        cell.configure(with: game)
        return cell
    }

    // MARK: FlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Match your previous look (insets 20+20, spacing 20)
        let w = max(collectionView.bounds.width - 60, 120)
        let h = max(collectionView.bounds.height - 20, 120)
        return CGSize(width: w, height: h)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 20 }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }

    // MARK: Prefetch
    func collectionView(_ cv: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.item < items.count,
                  let url = URL(string: items[indexPath.item].imageUrl ?? "") else { continue }

            let task = Task {
                _ = await ImageCache.shared.image(for: url)
            }
            prefetchTasks[indexPath] = task
        }
    }

    func collectionView(_ cv: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            prefetchTasks[indexPath]?.cancel()
            prefetchTasks.removeValue(forKey: indexPath)
        }
    }

    // MARK: Selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < items.count,
              let cell = collectionView.cellForItem(at: indexPath) else { return }
        onSelect?(items[indexPath.item], cell)
    }
}

final class FeaturedGamesTableViewCell: UITableViewCell {

    static let reuseIdentifier = "FeaturedGamesTableViewCell"
    private var collectionHeight: NSLayoutConstraint!

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        // Safe default so early layout passes don’t query zero size
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 60, height: 200)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let adapter = FeaturedGamesAdapter()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(collectionView)
        contentView.backgroundColor = UIColor(named: "whiteBackToDarkGrey")
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        collectionView.register(FeaturedGameCell.self,
        forCellWithReuseIdentifier: FeaturedGameCell.reuseIdentifier)
        collectionHeight = collectionView.heightAnchor.constraint(equalToConstant: 240) // desired height
        collectionHeight.isActive = true

        adapter.attach(to: collectionView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        // no-op; adapter holds state
    }

    deinit {
        adapter.detach(from: collectionView)
    }

    // External API — mirrors your TrendingGamesScroller usage
    func configure(with games: [GamerConnectGame],
                   onSelect: ((GamerConnectGame, UICollectionViewCell) -> Void)? = nil) {
        adapter.onSelect = onSelect
        adapter.update(games, in: collectionView)
        // ensure layout has sane size after first data load
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let w = max(collectionView.bounds.width - 60, 120)
            let h = max(collectionView.bounds.height - 20, 120)
            flow.itemSize = CGSize(width: w, height: h)
        }
    }
}
