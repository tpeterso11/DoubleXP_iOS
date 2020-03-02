//
//  NewsArticleCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import UIKit
import WebKit

class NewsArticleCell: UICollectionViewCell{
    
    @IBOutlet weak var cellWV: WKWebView!
    @IBOutlet weak var sourceImage: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var articleBack: UIImageView!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        super.awakeFromNib()
    }
}
