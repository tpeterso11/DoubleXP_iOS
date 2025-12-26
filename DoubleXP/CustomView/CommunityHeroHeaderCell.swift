//
//  CommunityHeroHeaderCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/14/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

class CommunityHeroHeaderCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityHeroHeaderCell"
    
    let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        // Add a subtle shadow for readability
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 3.0
        label.layer.shadowOpacity = 0.8
        label.layer.shadowOffset = CGSize(width: 2, height: 2)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(heroImageView)
        //contentView.addSubview(titleLabel)
        
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        //titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            //titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            //titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            //titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configures the cell with a pre-loaded image, used for the transition.
    func configure(with image: UIImage?) {
        heroImageView.image = image
    }
    
    /// Configures the cell by loading an image from a URL, used for standard presentation.
    func configure(with urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            heroImageView.image = nil // Or a placeholder
            return
        }
        // Use your custom image loader
        heroImageView.loadImage(from: url, placeholder: nil) // You can add a placeholder if you have one
    }
}
