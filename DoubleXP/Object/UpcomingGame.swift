//
//  UpcomingGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/14/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

/// Immutable, codable, diffable.
struct UpcomingGame: Codable, Hashable, Identifiable, Sendable {
    // Core identity
    let id: String

    // Required fields
    let game: String
    let developer: String
    let gameImageUrl: String?

    // Optional/aux fields
    let blurb: String?
    let trailerUrls: [String: String]?
    let releaseDateMillis: String?
    let releaseDate: String?
    let releaseDateProper: String?
    let gameDesc: String?
    let consoles: [String]?
    let genre: [String]?
    let slug: String

    // MARK: - Explicit designated initializer (replaces lost memberwise init)
    init(
        id: String,
        game: String,
        developer: String,
        gameImageUrl: String,
        blurb: String? = nil,
        trailerUrls: [String: String]? = nil,
        releaseDateMillis: String? = nil,
        releaseDate: String? = nil,
        releaseDateProper: String? = nil,
        gameDesc: String? = nil,
        consoles: [String]? = nil,
        genre: [String]? = nil,
        slug: String? = nil
    ) {
        self.id = id
        self.game = game
        self.developer = developer
        self.gameImageUrl = gameImageUrl
        self.blurb = blurb
        self.trailerUrls = trailerUrls
        self.releaseDate = releaseDate
        self.releaseDateMillis = releaseDateMillis
        self.releaseDateProper = releaseDateProper
        self.gameDesc = gameDesc
        self.consoles = consoles
        self.genre = genre
        self.slug = slug ?? ""
    }

    // MARK: - Computed helpers

    var countdownText: String? {
        guard let msStr = releaseDateMillis, let ms = Int64(msStr) else { return nil }
        return countdownLabel(from: ms)
    }

    var monthYearText: String? {
        guard let msStr = releaseDateMillis, let ms = Int64(msStr) else { return nil }
        return releaseMonthYear(from: ms)
    }

    var releaseDateMsDate: Date? {
        guard let msStr = releaseDateMillis, let ms = Double(msStr) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }

    var releaseDisplay: String? {
        if let d = releaseDateMsDate {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            return fmt.string(from: d)
        }
        if let prop = releaseDateProper, !prop.isEmpty { return prop }
        if let plain = releaseDate, !plain.isEmpty { return plain }
        return nil
    }

    var primaryTrailerURL: URL? {
        guard let trailers = trailerUrls else { return nil }
        if let s = trailers["official"], let u = URL(string: s) { return u }
        if let s = trailers["youtube"], let u = URL(string: s) { return u }
        if let s = trailers.values.first, let u = URL(string: s) { return u }
        return nil
    }

    // MARK: - Firebase dict initializer

    init?(id: String, dict: [String: Any]) {
        guard
            let game = dict["game"] as? String, !game.isEmpty,
            let developer = dict["developer"] as? String, !developer.isEmpty,
            let gameImageUrl = (dict["gameImageXXHDPI"] as? String) ?? (dict["gameImageUrl"] as? String),
            !gameImageUrl.isEmpty
        else { return nil }

        self.id = id
        self.game = game
        self.developer = developer
        self.gameImageUrl = gameImageUrl

        self.blurb = dict["blurb"] as? String
        self.trailerUrls = dict["trailerUrls"] as? [String: String]
        self.releaseDateMillis = dict["releaseDateMillis"] as? String
        self.releaseDate = dict["releaseDate"] as? String
        self.releaseDateProper = dict["releaseDateProp"] as? String
        self.gameDesc = (dict["description"] as? String) ?? (dict["gameDesc"] as? String)
        self.consoles = dict["consoles"] as? [String]
        self.genre = dict["genre"] as? [String]
        self.slug = dict["slug"] as? String ?? ""
    }

    // MARK: - Formatting helpers

    func countdownLabel(from releaseDateMs: Int64, now: Date = Date()) -> String? {
        let releaseDate = Date(timeIntervalSince1970: TimeInterval(releaseDateMs) / 1000.0)
        let remaining = Int(releaseDate.timeIntervalSince(now)) // seconds
        if remaining <= 0 { return "Out now" }

        let day  = 86_400
        let hour = 3_600
        let min  = 60

        let days    = remaining / day
        let hours   = (remaining % day) / hour
        let minutes = (remaining % hour) / min

        if days >= 1 {
            if days > 15 { return nil }
            return days == 1 ? "1 day" : "\(days) days"
        }
        if hours >= 1 {
            if hours > 11 { return "1 day" }
            return hours == 1 ? "1 hr" : "\(hours) hr"
        }
        if minutes >= 30 { return "\(minutes) min" }
        return "Soon"
    }

    func releaseMonthYear(from releaseDateMs: Int64) -> String? {
        let d = Date(timeIntervalSince1970: TimeInterval(releaseDateMs) / 1000.0)
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: d).uppercased()
    }
}

extension UpcomingGame {
    init(gc: GamerConnectGame, releaseDateMillis: String?) {
        self.init(
            id: gc.id,
            game: gc.gameName,
            developer: gc.developer ?? "",
            gameImageUrl: gc.imageUrl ?? "",
            blurb: gc.hook,
            trailerUrls: nil,
            releaseDateMillis: releaseDateMillis,
            releaseDate: gc.releaseDate,
            releaseDateProper: nil,
            gameDesc: gc.gameDescription,
            consoles: gc.availableConsoles,
            genre: gc.categoryFilters,
            slug: gc.slug
        )
    }
}

extension Array where Element == GamerConnectGame {
    func asUpcomingGames(prefetchImages: Bool = true) -> [UpcomingGame] {
        let ups = map { UpcomingGame(gc: $0, releaseDateMillis: dateStringToMillis($0.releaseDate)) }
        
        if prefetchImages {
            let urls = ups.compactMap { URL(string: $0.gameImageUrl ?? "") }
            
            // ✅ Wrap the call to the actor in a Task
            Task {
                await ImageCache.shared.preload(urls: urls)
            }
        }
        
        return ups
    }
    
    func dateStringToMillis(_ dateStr: String?) -> String? {
        if(dateStr == nil){
            return nil
        }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)  // ensure consistency
        fmt.dateFormat = "yyyy-MM-dd"

        guard let date = fmt.date(from: dateStr!) else { return nil }
        let ms = Int64(date.timeIntervalSince1970 * 1000)
        return String(ms)
    }
}
