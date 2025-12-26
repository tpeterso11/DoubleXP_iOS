//
//  ShortsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 7/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import UIKit

final class ShortsCell: UICollectionViewCell {

    static let reuseIdentifier = "ShortsCell"

    // Data
    private var short: YouTubeShort?
    private var imageLoadTask: Task<Void, Never>?

    // Containers
    private let headerBar = UIView()
    private let footerBar = UIView()
    private let videoContainer = UIView()

    // Video / image
    private let youtubePlayerView: YouTubePlayerView = {
        let v = YouTubePlayerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .darkGray
        return iv
    }()
    private let playButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)
        b.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.9
        b.layer.shadowRadius = 10
        b.layer.shadowOffset = .zero
        return b
    }()

    // Header meta
    private let avatarView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let subredditLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.9)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Footer reactions + progress
    private let progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.translatesAutoresizingMaskIntoConstraints = false
        p.progressTintColor = .white
        p.trackTintColor = .white.withAlphaComponent(0.25)
        p.progress = 0
        return p
    }()

    private lazy var likeButton: UIButton    = reaction("hand.thumbsup.fill", "5")
    private lazy var dislikeButton: UIButton = reaction("hand.thumbsdown.fill", "2")
    private lazy var fireButton: UIButton    = reaction("flame.fill", "9", color: .systemOrange)

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
        buildConstraints()
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        hookProgress()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: Configure
    public func configure(with short: YouTubeShort) {
        self.short = short
        subredditLabel.text = "r/GamingShorts"
        titleLabel.text = short.title

        resetToThumbnail()

        if let url = short.thumbnailUrl {
            imageLoadTask?.cancel()
            imageLoadTask = Task {
                let image = await ImageCache.shared.image(for: url)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.thumbnailImageView.image = image }
            }
        } else {
            thumbnailImageView.image = UIImage(systemName: "photo")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        stopPlayback()
        thumbnailImageView.image = nil
        titleLabel.text = nil
    }

    // MARK: Playback
    public func startPlayback() {
        guard let id = short?.videoId else { return }
        youtubePlayerView.isHidden = false
        thumbnailImageView.isHidden = true
        playButton.isHidden = true
        youtubePlayerView.load(videoID: id, shouldAutoplay: true)
    }
    public func stopPlayback() {
        youtubePlayerView.pause()
        resetToThumbnail()
    }
    public func pausePlayback() {
        youtubePlayerView.pause()
    }
    @objc private func didTapPlay() { startPlayback() }

    // MARK: Private
    private func resetToThumbnail() {
        youtubePlayerView.isHidden = true
        thumbnailImageView.isHidden = false
        playButton.isHidden = false
        progressView.progress = 0
    }

    private func hookProgress() {
        youtubePlayerView.progressUpdateHandler = { [weak self] p in
            DispatchQueue.main.async { self?.progressView.setProgress(p, animated: true) }
        }
    }

    private func reaction(_ sys: String, _ text: String, color: UIColor? = nil) -> UIButton {
        var cfg = UIButton.Configuration.plain()
        cfg.imagePadding = 6
        cfg.contentInsets = .zero
        // icon
        let imgCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        cfg.image = UIImage(systemName: sys, withConfiguration: imgCfg)
        // title (force white regardless of icon tint)
        cfg.attributedTitle = AttributedString(text, attributes: .init([
            .font : UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor : UIColor.white
        ]))

        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        // tint only affects the SF Symbol (image)
        b.tintColor = color ?? .white
        return b
    }
    
    private func buildUI() {
        contentView.backgroundColor = .clear

        // Card styling
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .black

        // Bars
        [headerBar, footerBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.85)
            contentView.addSubview($0)
        }

        // Video container
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(videoContainer)
        videoContainer.addSubview(thumbnailImageView)
        videoContainer.addSubview(youtubePlayerView)
        contentView.addSubview(playButton)

        // Header contents
        headerBar.addSubview(avatarView)
        headerBar.addSubview(subredditLabel)
        headerBar.addSubview(titleLabel)

        // Footer contents
        footerBar.addSubview(progressView)
        let reactionsStack = UIStackView(arrangedSubviews: [fireButton, likeButton, dislikeButton])
        reactionsStack.axis = .horizontal
        reactionsStack.spacing = 14
        reactionsStack.alignment = .center
        reactionsStack.translatesAutoresizingMaskIntoConstraints = false
        footerBar.addSubview(reactionsStack)

        // Avatar look
        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
    }

    private func buildConstraints() {
        NSLayoutConstraint.activate([
            // Header bar
            headerBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 72),

            // Footer bar
            footerBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            footerBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerBar.heightAnchor.constraint(equalToConstant: 72),

            // Video takes the space between the bars
            videoContainer.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            videoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainer.bottomAnchor.constraint(equalTo: footerBar.topAnchor),

            thumbnailImageView.topAnchor.constraint(equalTo: videoContainer.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: videoContainer.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: videoContainer.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor),

            youtubePlayerView.topAnchor.constraint(equalTo: videoContainer.topAnchor),
            youtubePlayerView.leadingAnchor.constraint(equalTo: videoContainer.leadingAnchor),
            youtubePlayerView.trailingAnchor.constraint(equalTo: videoContainer.trailingAnchor),
            youtubePlayerView.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor),

            playButton.centerXAnchor.constraint(equalTo: videoContainer.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: videoContainer.centerYAnchor),

            // Header content
            avatarView.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 12),
            avatarView.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor, constant: -8),
            avatarView.widthAnchor.constraint(equalToConstant: 28),
            avatarView.heightAnchor.constraint(equalToConstant: 28),

            subredditLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            subredditLabel.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -12),
            subredditLabel.topAnchor.constraint(equalTo: headerBar.topAnchor, constant: 8),

            titleLabel.leadingAnchor.constraint(equalTo: subredditLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: subredditLabel.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: subredditLabel.bottomAnchor, constant: 2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerBar.bottomAnchor, constant: -8),

            // Footer content
            progressView.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor, constant: -12),
            progressView.topAnchor.constraint(equalTo: footerBar.topAnchor, constant: 8),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            // Reactions aligned left
            likeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            dislikeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            fireButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
        ])

        // Reactions stack pinned left/bottom inside footer
        if let reactionsStack = footerBar.subviews.first(where: { $0 is UIStackView }) {
            NSLayoutConstraint.activate([
                reactionsStack.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor, constant: 12),
                reactionsStack.bottomAnchor.constraint(equalTo: footerBar.bottomAnchor, constant: -12)
            ])
        }
    }
}
