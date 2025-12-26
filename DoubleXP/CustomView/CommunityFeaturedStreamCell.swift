//
//  CommunityFeaturedStreamCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/14/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

// MARK: - Featured Stream Cell (Unified Design)
class CommunityFeaturedStreamCell: UICollectionViewCell {
    /*static let reuseIdentifier = "CommunityFeaturedStreamCell"

    // MARK: - UI Elements
    
    // Left Side: Video Player and Overlays
    private let playerView = TwitchPlayerView()

    private let liveIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.layer.masksToBounds = true
        return label
    }()

    private lazy var fullscreenButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(fullscreenButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let streamerImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15 // Adjusted size
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 1.5
        return imageView
    }()

    private let streamerNameLabel = UILabel.createLabel(size: 14, weight: .bold, color: .white)

    // Right Side: Metadata and Actions
    private let metadataContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Darker background
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    private let streamTitleLabel = UILabel.createLabel(size: 17, weight: .bold, color: .white)
    private let gameNameLabel = UILabel.createLabel(size: 15, weight: .regular, color: .lightGray)
    private let viewerCountLabel = UILabel.createLabel(size: 14, weight: .medium, color: .lightGray)
    
    // Placeholder for reaction buttons
    private lazy var actionsStackView: UIStackView = {
        let heartButton = UIButton.createActionButton(systemName: "heart")
        let menuButton = UIButton.createActionButton(systemName: "line.3.horizontal")
        let stack = UIStackView(arrangedSubviews: [heartButton, UIView(), menuButton])
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle & Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        // Crucial for performance: shut down the web view to release resources.
        playerView.shutdown()
        streamTitleLabel.text = nil
        streamerNameLabel.text = nil
        gameNameLabel.text = nil
        viewerCountLabel.text = nil
        streamerImageView.image = nil
    }

    func configure(with stream: LiveStream) {
        streamTitleLabel.text = stream.streamTitle
        streamerNameLabel.text = stream.userName
        gameNameLabel.text = stream.gameName
        viewerCountLabel.text = "● \(stream.viewerCount.formatted()) watching"
        
        // --- Configure the Twitch Player ---
        // IMPORTANT: Replace with your actual parent URL.
        guard let parentURL = URL(string: "https://www.your-app-domain.com") else { return }

        var config = TwitchPlayerView.Configuration(
            content: .channel(name: stream.channelName),
            parentURL: parentURL
        )
        config.isMuted = true // Mute by default for autoplay in a feed
        config.autoplay = true // We will control playback manually
        config.allowsFullScreen = true

        playerView.playerConfiguration = config
        playerView.isUserInteractionEnabled = false
    }
    
    // MARK: - Public Playback Controls
    
    /// Call this from your view controller when the cell becomes visible.
    public func startPlayback() {
        Task { @MainActor in
            try? await playerView.play()
        }
    }
    
    /// Call this from your view controller when the cell scrolls out of view.
    public func stopPlayback() {
        Task { @MainActor in
            try? await playerView.pause()
        }
    }

    // MARK: - Layout Setup

    private func setupLayout() {
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        // --- Create element stacks ---
        let streamerInfoStack = UIStackView(arrangedSubviews: [streamerImageView, streamerNameLabel])
        streamerInfoStack.spacing = 8
        streamerInfoStack.alignment = .center
        
        let metadataStack = UIStackView(arrangedSubviews: [streamTitleLabel, gameNameLabel, viewerCountLabel])
        metadataStack.axis = .vertical
        metadataStack.spacing = 6
        metadataStack.alignment = .leading

        // --- Add subviews ---
        [playerView, metadataContainerView, liveIndicatorLabel, fullscreenButton, streamerInfoStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        [metadataStack, actionsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            metadataContainerView.addSubview($0)
        }
        
        // --- Activate constraints ---
        let playerWidthMultiplier: CGFloat = 0.6

        NSLayoutConstraint.activate([
            // Player View
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: playerWidthMultiplier),

            // Metadata Container (Right side)
            metadataContainerView.leadingAnchor.constraint(equalTo: playerView.trailingAnchor),
            metadataContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            metadataContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            metadataContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // --- Player Overlays ---
            liveIndicatorLabel.topAnchor.constraint(equalTo: playerView.topAnchor, constant: 12),
            liveIndicatorLabel.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: 12),
            liveIndicatorLabel.widthAnchor.constraint(equalToConstant: 40),
            
            fullscreenButton.topAnchor.constraint(equalTo: playerView.topAnchor, constant: 12),
            fullscreenButton.trailingAnchor.constraint(equalTo: playerView.trailingAnchor, constant: -12),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 30),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 30),

            streamerInfoStack.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: 12),
            streamerInfoStack.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -12),
            streamerInfoStack.trailingAnchor.constraint(lessThanOrEqualTo: playerView.trailingAnchor, constant: -12),
            
            streamerImageView.widthAnchor.constraint(equalToConstant: 30),
            streamerImageView.heightAnchor.constraint(equalToConstant: 30),

            // --- Metadata Contents ---
            metadataStack.topAnchor.constraint(equalTo: metadataContainerView.topAnchor, constant: 16),
            metadataStack.leadingAnchor.constraint(equalTo: metadataContainerView.leadingAnchor, constant: 16),
            metadataStack.trailingAnchor.constraint(equalTo: metadataContainerView.trailingAnchor, constant: -16),
            
            actionsStackView.bottomAnchor.constraint(equalTo: metadataContainerView.bottomAnchor, constant: -16),
            actionsStackView.leadingAnchor.constraint(equalTo: metadataContainerView.leadingAnchor, constant: 16),
            actionsStackView.trailingAnchor.constraint(equalTo: metadataContainerView.trailingAnchor, constant: -16)
        ])
    }

    @objc private func fullscreenButtonTapped() {
        // The Twitch iFrame handles the fullscreen transition itself.
        // If you need to coordinate this with your app's UI, you'd add delegate callbacks here.
        print("Fullscreen tapped. The webview should handle this.")
    }
}

// MARK: - Helpers (for cleaner code)

extension UIButton {
    static func createActionButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .lightGray
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        return button
    }*/
}
