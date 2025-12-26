//
//  JSONCacheManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

class JSONCacheManager<T: Codable> {
    private let baseFileName: String
    private let cacheValidity: TimeInterval = 3600 // 1 hour

    init(cacheFileName: String) {
        self.baseFileName = cacheFileName
    }

    // MARK: - Public

    func save(_ objects: [T]) {
        save(objects, key: baseFileName)
    }

    func load() -> [T]? {
        return load(key: baseFileName)
    }

    func save(_ objects: [T], key: String) {
        let wrapper = CacheWrapper(timestamp: Date(), items: objects)
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: cacheURL(for: key), options: .atomic)
        } catch {
            print("❌ JSONCacheManager save error for key [\(key)]:", error)
        }
    }

    func load(key: String) -> [T]? {
        do {
            let data = try Data(contentsOf: cacheURL(for: key))
            let wrapper = try JSONDecoder().decode(CacheWrapper.self, from: data)

            if Date().timeIntervalSince(wrapper.timestamp) < cacheValidity {
                return wrapper.items
            } else {
                try FileManager.default.removeItem(at: cacheURL(for: key))
                return nil
            }
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func cacheURL(for key: String) -> URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("\(key).json")
    }

    private struct CacheWrapper: Codable {
        let timestamp: Date
        let items: [T]
    }
}
