//
//  TwitterHelper.swift
//  DoubleXP
//
//  Created by Johy Brahy on 5/7/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Swifter

class TwitterHelper: NSObject {
    static let shared = TwitterHelper()
    
    private var swifter: Swifter!
    
    private override init() {
        super.init()
    }
    
    func start(withConsumerKey consumerKey: String, consumerSecret: String) {
        swifter = Swifter(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }
    
    func getTimeline(screenName: String, completion: @escaping ((JSON?) ->Void)) {
        swifter.getTimeline(for: .screenName(screenName), customParam: [:], count: 10, sinceID: nil, maxID: nil, trimUser: nil, excludeReplies: nil, includeRetweets: nil, contributorDetails: nil, includeEntities: true, tweetMode: .default, success: { (json) in
            completion(json)
        }) { (error) in
            completion(nil)
        }
    }
}
