//
//  LanguageProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

struct LanguageEntry: Codable {
    let alpha2: String
    let english: String
}

class LanguageProvider {
    static let shared = LanguageProvider() // 👈 Singleton instance
    private init() {}
    private let csvURL = URL(string: "https://datahub-next-new.vercel.app/core/language-codes/_r/-/data/language-codes.csv")!
    private let cache = JSONCacheManager<LanguageEntry>(cacheFileName: "language-codes")
    private(set) var inMemory: [LanguageEntry] = []

    func fetchLanguages() async {
        //if let cached = cache.load() {
        //    self.inMemory = cached
        //    return
        //}

        URLSession.shared.dataTask(with: csvURL) { data, _, error in
            guard let data = data,
                  let csvString = String(data: data, encoding: .utf8),
                  error == nil else {
                print("❌ Failed fetching languages:", error?.localizedDescription ?? "Unknown error")
                return
            }

            let rows = csvString.components(separatedBy: .newlines)
            guard let headerRow = rows.first else {
                print("❌ No CSV header found")
                return
            }

            let headers = headerRow.components(separatedBy: ",").map {
                $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard let alpha2Index = headers.firstIndex(where: { $0.lowercased() == "alpha2" }),
                  let englishIndex = headers.firstIndex(where: { $0.lowercased() == "english" }) else {
                print("❌ Required headers not found")
                return
            }

            let entries: [LanguageEntry] = rows
                .dropFirst()
                .compactMap { row in
                    let columns = row.components(separatedBy: ",").map {
                        $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    guard columns.count > max(alpha2Index, englishIndex) else { return nil }
                    let alpha2 = columns[alpha2Index]
                    let english = columns[englishIndex]
                    guard !alpha2.isEmpty, !english.isEmpty else { return nil }
                    return LanguageEntry(alpha2: alpha2, english: english)
                }
                .sorted { a, b in
                    if a.english == "English" { return true }
                    if b.english == "English" { return false }
                    return a.english < b.english
                }

            DispatchQueue.main.async {
                self.inMemory = entries
                self.cache.save(entries)
            }
        }.resume()
    }

    func getLanguageNames() -> [String] {
        return inMemory.map { $0.english }
    }
}
