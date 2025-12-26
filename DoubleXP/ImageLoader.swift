//
//  ImageLoader.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 1/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit
import CryptoKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let session: URLSession

    // The actor protects this dictionary automatically.
    private var runningTasks = [URL: Task<UIImage, Error>]()

    // The NSLock is no longer needed.
    // private let lock = NSLock()

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: cfg)
        
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }

    // MARK: - Main Public Function

    func image(for url: URL) async -> UIImage? {
        if let cachedImage = memoryCache.object(forKey: url.absoluteString as NSString) {
            return cachedImage
        }
        
        if let diskImage = await imageFromDisk(for: url) {
            memoryCache.setObject(diskImage, forKey: url.absoluteString as NSString)
            return diskImage
        }
        
        if let existingTask = runningTasks[url] {
            // This is the block we fixed before. Let's simplify the return.
            return try? await existingTask.value
        }
        
        // ✅ MODIFICATION 1: The Task now returns a non-optional UIImage.
        let task = Task<UIImage, Error> {
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            return image
        }
        
        runningTasks[url] = task
        
        // ✅ MODIFICATION 2: Use a do-catch block to handle the result cleanly.
        do {
            // If the task succeeds, `finalImage` is a non-optional UIImage.
            let finalImage = try await task.value
            
            // Cache the successful result.
            memoryCache.setObject(finalImage, forKey: url.absoluteString as NSString)
            await saveImageToDisk(finalImage, for: url)
            
            // Clean up and return the image.
            runningTasks.removeValue(forKey: url)
            return finalImage
        } catch {
            // If the task fails for any reason (bad data, network error),
            // clean up and return nil.
            runningTasks.removeValue(forKey: url)
            return nil
        }
    }

    // MARK: - Preloading
    
    func preload(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    // This is already async, so the function should be too
                    _ = await self.image(for: url)
                }
            }
        }
    }

    // MARK: - Disk Cache Helpers
    
    private func diskPath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8)).description
        return diskCacheURL.appendingPathComponent(hash)
    }

    private func imageFromDisk(for url: URL) async -> UIImage? {
        let path = diskPath(for: url)
        return await Task(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: path) else { return nil }
            return UIImage(data: data)
        }.value
    }

    private func saveImageToDisk(_ image: UIImage, for url: URL) async {
        let path = diskPath(for: url)
        await Task(priority: .background) {
            let data = image.jpegData(compressionQuality: 0.8)
            try? data?.write(to: path)
        }.value
    }
    
    
}


