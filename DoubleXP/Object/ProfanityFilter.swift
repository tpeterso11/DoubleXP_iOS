//
//  ProfanityFilter.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

class ProfanityFilter: NSObject {

    static let sharedInstance = ProfanityFilter()
    private override init() {}

    // Customize as needed
    private let dirtyWords = "\\b(fuck|fucker|mother fucker|motherfucker|shit|fag|faggot|cunt|nigger|nigga)\\b"

    // Courtesy of Martin R
    // https://stackoverflow.com/users/1187415/martin-r
    private func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex, options: [.caseInsensitive])
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    public func cleanUp(_ string: String) -> String {
        let dirtyWords = matches(for: self.dirtyWords, in: string)

        if dirtyWords.count == 0 {
            return string
        } else {
            var newString = string

            dirtyWords.forEach({ dirtyWord in
                let newWord = "#&%@!#"
                newString = newString.replacingOccurrences(of: dirtyWord, with: newWord, options: [.caseInsensitive])
            })

            return newString
        }
    }
}
