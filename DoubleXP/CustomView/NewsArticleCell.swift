//
//  NewsArticleCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import UIKit

class NewsArticleCell: UICollectionViewCell{
    
    @IBOutlet weak var articleBack: UIImageView!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
        
        super.awakeFromNib()
    }
}