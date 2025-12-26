//
//  ServiceHelper.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/19/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

func fetchWithRetry(url: URL, maxAttempts: Int = 3, delay: TimeInterval = 1.0, completion: @escaping (Data?) -> Void) {
    var attempts = 0

    func attempt() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                completion(data)
            } else {
                attempts += 1
                if attempts < maxAttempts {
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        attempt()
                    }
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }

    attempt()
}
