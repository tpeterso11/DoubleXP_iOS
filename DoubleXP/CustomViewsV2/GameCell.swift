//
//  GameCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/25/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Kingfisher

class GameCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var check: UIImageView!
    @IBOutlet weak var selectedCover: UIView!
    
    func configure(with game: GamerConnectGame) {
        nameLabel.text = game.gameName
        typeLabel.text = game.gameType

        if let url = URL(string: game.imageUrl ?? "") {
            self.imageView.kf.setImage(with: url)
        } else {
            imageView.image = UIImage(named: "placeholder") // Fallback
        }
    }
}
