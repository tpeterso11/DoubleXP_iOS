//
//  FeaturedGameCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class FeaturedGameCell: UICollectionViewCell {
    
    static let reuseIdentifier = "FeaturedGameCell"
    
    // UI Elements remain the same...
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .darkGray
        return imageView
    }()
    
    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private let gameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hookLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let genreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // UPDATED: The task is now a modern Swift Concurrency Task
    private var imageLoadTask: Task<Void, Never>?

    // Initialization and UI setup remain the same...
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(blurView)
        blurView.contentView.addSubview(gameTitleLabel)
        blurView.contentView.addSubview(hookLabel)
        blurView.contentView.addSubview(genreLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            blurView.heightAnchor.constraint(equalToConstant: 120),
            genreLabel.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 16),
            genreLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
            genreLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            genreLabel.heightAnchor.constraint(equalToConstant: 24),
            gameTitleLabel.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 16),
            gameTitleLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16),
            gameTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: genreLabel.leadingAnchor, constant: -8),
            hookLabel.topAnchor.constraint(equalTo: gameTitleLabel.bottomAnchor, constant: 4),
            hookLabel.leadingAnchor.constraint(equalTo: gameTitleLabel.leadingAnchor),
            hookLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
            hookLabel.bottomAnchor.constraint(lessThanOrEqualTo: blurView.contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration (Updated)
    
    public func configure(with game: GamerConnectGame) {
        gameTitleLabel.text = game.gameName
        hookLabel.text = game.hook
        
        if let genre = game.categoryFilters.first {
            genreLabel.text = genre.uppercased()
            genreLabel.isHidden = false
        } else {
            genreLabel.isHidden = true
        }
        
        // UPDATED: Use the new async ImageCache with a Swift Concurrency Task
        guard let url = URL(string: game.imageUrl ?? "") else {
            self.backgroundImageView.image = UIImage(systemName: "photo.fill")
            return
        }
        
        imageLoadTask = Task { [weak self] in
            guard let self else { return }             // or: guard let self = self else { return }
            let image = await ImageCache.shared.image(for: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.backgroundImageView.image = image ?? UIImage(systemName: "photo.fill")
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // UPDATED: Cancel the Swift Concurrency Task if it's still running
        imageLoadTask?.cancel()
        
        backgroundImageView.image = nil
        gameTitleLabel.text = nil
        hookLabel.text = nil
        genreLabel.text = nil
    }
}
