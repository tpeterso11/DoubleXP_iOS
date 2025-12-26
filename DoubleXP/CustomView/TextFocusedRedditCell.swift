//
//  TextFocusedRedditCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/16/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class TextFocusedRedditCell: UICollectionViewCell {

    static let reuseIdentifier = "TextFocusedRedditCell"
    
    // --- UI Elements ---
    private let subredditLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // --- Initialization ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // --- UI Setup ---
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        contentView.addSubview(subredditLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Subreddit Label
            subredditLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            subredditLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subredditLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Title Label
            titleLabel.topAnchor.constraint(equalTo: subredditLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: subredditLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: subredditLabel.trailingAnchor),
            
            // Author Label
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            authorLabel.leadingAnchor.constraint(equalTo: subredditLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: subredditLabel.trailingAnchor)
        ])
    }

    // --- Configuration ---
    public func configure(with post: RedditPost) {
        subredditLabel.text = post.subreddit
        titleLabel.text = post.title
        authorLabel.text = "Posted by \(post.author)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        subredditLabel.text = nil
        titleLabel.text = nil
        authorLabel.text = nil
    }
}
