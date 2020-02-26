//
//  MediaCache.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class MediaCache {
    var reviewsCache = [NewsObject]()
    var newsCache = [NewsObject]()
    var twitchCache = [TwitchStreamObject]()
    
    func setNewsCache(payload: [NewsObject]){
        self.newsCache = [NewsObject]()
        self.newsCache.append(contentsOf: payload)
    }
    
    func setReviewsCache(payload: [NewsObject]){
        self.reviewsCache = [NewsObject]()
        self.reviewsCache.append(contentsOf: payload)
    }
}
