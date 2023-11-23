//
//  CompetitionCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class CompetitionCell: UICollectionViewCell{
    @IBOutlet weak var competitionName: UILabel!
    @IBOutlet weak var topPrize: UILabel!
    @IBOutlet weak var gameName: UILabel!
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let videoPath = Bundle.main.path(forResource: "basketball", ofType: "mov"),
        let imagePath = Bundle.main.path(forResource: "null", ofType: "png") else{
            return
        }
        
        let options = VideoOptions(pathToVideo: videoPath,
                                   pathToImage: imagePath,
                                   isMuted: true,
                                   shouldLoop: true)
        let videoView = VideoBackground(frame: self.contentView.bounds, options: options)
        self.contentView.insertSubview(videoView, at: 0)
    }*/

}
