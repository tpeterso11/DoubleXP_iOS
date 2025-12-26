//
//  CommunityContentCardCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/14/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class CommunityContentCardCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityContentCardCell"

    // UI Elements
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .darkGray // Placeholder
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, sourceLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStackView)
        
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 9.0/16.0),
            
            textStackView.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 8),
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("Not implemented") }
    
    func configure(with article: Article) {
        titleLabel.text = article.title
        sourceLabel.text = article.source
        
        if let urlString = article.imageUrl, let url = URL(string: urlString) {
            thumbnailImageView.loadImage(from: url, placeholder: UIImage(systemName: "photo"))
        } else {
            thumbnailImageView.image = UIImage(systemName: "photo")
        }
    }

    // ✅ New method to handle Reddit posts
    func configure(with post: RedditPost) {
        titleLabel.text = post.title
        sourceLabel.text = "r/\(post.subreddit)"
        
        if let urlString = post.thumbnail, urlString.starts(with: "http"), let url = URL(string: urlString) {
            thumbnailImageView.loadImage(from: url, placeholder: UIImage(systemName: "photo"))
        } else {
            thumbnailImageView.image = UIImage(systemName: "photo")
        }
    }
}
