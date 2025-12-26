//
//  ImageDominantRedditCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/16/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class ImageDominantRedditCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ImageDominantRedditCell"
    private let container = UIView()
    private let titleLabel = UILabel()
    private let imageView = UIImageView()

    // Keep references so we don’t add/remove constraints repeatedly.
    private var mediaAspectConstraint: NSLayoutConstraint!
    private var mediaZeroHeightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true

        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        container.addSubview(titleLabel)
        container.addSubview(imageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -14)
        ])

        // 16:9 height (stable) and an alternative zero-height constraint.
        mediaAspectConstraint = imageView.heightAnchor.constraint(
            equalTo: imageView.widthAnchor, multiplier: 9.0/16.0
        )
        mediaZeroHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)

        mediaAspectConstraint.isActive = true   // default: show media
        mediaZeroHeightConstraint.isActive = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        // Reset to visible-media state so reused cells don’t keep zero height.
        mediaZeroHeightConstraint.isActive = false
        mediaAspectConstraint.isActive = true
        imageView.isHidden = false
    }

    func configure(with post: RedditPost) {
        titleLabel.text = post.title

        /*if let urlString = post.imageURL, let url = URL(string: urlString) {
            // Show media area at 16:9
            mediaZeroHeightConstraint.isActive = false
            mediaAspectConstraint.isActive = true
            imageView.isHidden = false

            Task {
                let img = await ImageCache.shared.image(for: url)
                await MainActor.run { self.imageView.image = img }
            }
        } else {
            // No media → collapse cleanly (no self-sizing).
            mediaAspectConstraint.isActive = false
            mediaZeroHeightConstraint.isActive = true
            imageView.isHidden = true
        }*/
    }
}
