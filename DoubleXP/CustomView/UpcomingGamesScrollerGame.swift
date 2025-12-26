//
//  UpcomingGamesScrollerGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

final class UpcomingGamesScrollerGame: UICollectionViewCell {
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet private weak var releaseDatePill: UILabel!
    @IBOutlet private weak var releaseTillPill: UILabel!
    @IBOutlet private weak var genrePillOne: UILabel!
    @IBOutlet private weak var genrePillTwo: UILabel!
    @IBOutlet private weak var genrePillThree: UILabel!

    // Expose a read-only view for shared element transitions
    var gameTitleView: UILabel { gameName }

    private var currentImageURL: URL?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupShadow()
        setupImageView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep shadow path updated if the bounds change (better perf)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
    }

    private func setupShadow() {
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        // Shadow on the outer layer
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.25   // adjust intensity
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        layer.shadowRadius  = 6
    }

    private func setupImageView() {
        gameImage.layer.cornerRadius = 12
        gameImage.layer.masksToBounds = true
        gameImage.contentMode = .scaleAspectFill
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentImageURL = nil
        gameImage.image = nil
        [genrePillOne, genrePillTwo, genrePillThree].forEach { $0?.isHidden = true }
        releaseTillPill.isHidden = true
    }

    func configure(with g: UpcomingGame) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        gameName.attributedText = NSAttributedString(
            string: g.game,
            attributes: [.paragraphStyle: paragraph, .kern: -0.5] // tighten spacing
        )
        releaseDatePill.text = g.monthYearText

        if let t = g.countdownText { releaseTillPill.text = t; releaseTillPill.isHidden = false }
        else { releaseTillPill.isHidden = true }

        configureGenrePills(with: g.genre)

        guard let url = URL(string: g.gameImageUrl ?? "") else {
            gameImage.image = nil
            return
        }

        currentImageURL = url

        let placeholder = UIImage.placeholder(size: gameImage.bounds.size)
        gameImage.loadImage(from: currentImageURL, placeholder: placeholder)
        
        //self.gameImage.heroID = "gameImage_\(g.id)"
    }

    private func configureGenrePills(with genres: [String]?) {
        let pills: [UILabel] = [genrePillOne, genrePillTwo, genrePillThree]
        pills.forEach { $0.isHidden = true }
        guard let genres, !genres.isEmpty else { return }
        for (i, g) in genres.prefix(3).enumerated() {
            let pill = pills[i]
            pill.text = g.uppercased()
            pill.isHidden = false
        }
    }
}
