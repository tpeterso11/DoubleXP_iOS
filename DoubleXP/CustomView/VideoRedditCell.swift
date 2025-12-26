//
//  VideoRedditCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/16/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class VideoRedditCell: UICollectionViewCell {
    
    static let reuseIdentifier = "VideoRedditCell"
    
    // --- UI Elements ---
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .darkGray
        return imageView
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Gradient will be added in the initializer
        return view
    }()
    
    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold, scale: .large)
        imageView.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Add a shadow for better visibility
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 6
        imageView.layer.shadowOpacity = 0.8
        imageView.layer.shadowOffset = .zero
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subredditLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .lightText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var imageLoadTask: Task<Void, Never>?
    private let gradientLayer = CAGradientLayer()

    // --- Initialization ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the gradient layer's frame is updated on layout changes
        gradientLayer.frame = gradientView.bounds
    }
    
    // --- UI Setup ---
    private func setupGradient() {
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(playIconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subredditLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Thumbnail fills the cell
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Gradient view at the bottom
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.4),
            
            // Play icon is centered
            playIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Title label at the bottom, above subreddit
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: subredditLabel.topAnchor, constant: -4),
            
            // Subreddit label at the very bottom
            subredditLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subredditLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subredditLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    // --- Configuration ---
    public func configure(with post: RedditPost) {
        titleLabel.text = post.title
        subredditLabel.text = post.subreddit
        
        // Prefer thumbnail, but fallback to imageURL for the image
        /*let urlString = ""//post.thumbnail ?? post.imageURL
        
        guard let finalURLString = urlString, let url = URL(string: finalURLString) else {
            self.thumbnailImageView.image = UIImage(systemName: "photo.fill")
            return
        }*/
        
        imageLoadTask = Task {
            let image = await ImageCache.shared.image(for: URL(string: "")!)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.thumbnailImageView.image = image ?? UIImage(systemName: "photo.fill")
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        subredditLabel.text = nil
    }
}
