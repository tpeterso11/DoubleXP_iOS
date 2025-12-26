//
//  RawgGameProvider.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/20/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import Kingfisher
import Fuse

enum GameDateRange: CustomStringConvertible {
    case allPastToNow
    case upcomingOneYear
    case upcomingFiveYears

    var description: String {
        switch self {
        case .allPastToNow: return "allPastToNow"
        case .upcomingOneYear: return "upcomingOneYear"
        case .upcomingFiveYears: return "upcomingFiveYears"
        }
    }
}

struct RawgResponse: Decodable {
    let results: [RawgGame]
}

// MARK: - Provider
final class RawgGameProvider {
    static let shared = RawgGameProvider()

    private let apiKey   = "aa33f3f588c640ae9b8d88972cc2f5b7"
    private let pageSize = 40
    private let maxGames = 500
    private var seenGameIDs: Set<Int> = []
    
    // Updated to use GamerConnectGame directly
    var upcomingGames = [GamerConnectGame]()
    var trendingGames = [GamerConnectGame]()
    
    private let storageKey = "GamerConnect_CachedGames"
    private var memoryCache: [String: GamerConnectGame] = [:]
    
    private let useMockData = true
    private let storage = GameStorageManager.shared
    private let queue = DispatchQueue(label: "com.gamerconnect.storage", attributes: .concurrent)

    private init() {}

    // MARK: - Public

    func fetchGames(
        range: GameDateRange = .allPastToNow,
        completion: (() -> Void)? = nil
    ) {
        seenGameIDs.removeAll()

        let today = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let dateRange: String = {
            switch range {
            case .allPastToNow:
                return "2020-01-01,\(fmt.string(from: today))"
            case .upcomingOneYear:
                let end = Calendar.current.date(byAdding: .year, value: 1, to: today)!
                return "\(fmt.string(from: today)),\(fmt.string(from: end))"
            case .upcomingFiveYears:
                let end = Calendar.current.date(byAdding: .year, value: 5, to: today)!
                return "\(fmt.string(from: today)),\(fmt.string(from: end))"
            }
        }()

        fetchPage(currentPage: 1, dateRange: dateRange, completion: completion)
    }
    
    func getAllGames() -> [GamerConnectGame] {
        queue.sync {
            return Array(memoryCache.values)
        }
    }

    /// Local + API search, returns GamerConnectGame models
    func searchGames(query: String) async throws -> [GamerConnectGame] {
        var results: [GamerConnectGame] = []

        // 1) Local (Storage Manager)
        let localGames = storage.getAllGames()
        
        // Simple case-insensitive search since Fuse is removed
        let localMatches = localGames.filter {
            $0.gameName.localizedCaseInsensitiveContains(query)
        }
        
        results.append(contentsOf: localMatches)

        // 2) API
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://api.rawg.io/api/games?key=\(apiKey)&search=\(encoded)&page_size=30")
        else { return results }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(RawgResponse.self, from: data)

        // Map to GamerConnectGame
        let apiGames = decoded.results.map { $0.asGamerConnectGame() }

        // Save new ones to storage
        let existingIDs = Set(localGames.map { $0.id })
        let apiNew = apiGames.filter { !existingIDs.contains($0.id) }
        storage.save(games: apiNew)

        // Continue with de-dupe
        results.append(contentsOf: apiGames)

        var seenIDs = Set<String>()
        let dedupByID = results.filter { seenIDs.insert($0.id).inserted }

        return dedupByID
    }

    /// Recently released (past N days)
    func recentUpcomingGames(days: Int = 30) -> [GamerConnectGame] {
        let games = storage.getAllGames()
        let now = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? .distantPast
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        return games.filter { game in
            guard let releaseStr = game.releaseDate,
                  let d = fmt.date(from: releaseStr) else { return false }
            return d <= now && d >= cutoff
        }
    }

    /// Upcoming (next N days)
    func upcomingWithin(days: Int = 60) -> [GamerConnectGame] {
        let games = storage.getAllGames()
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        return games.filter { game in
            guard let releaseStr = game.releaseDate,
                  let d = fmt.date(from: releaseStr) else { return false }
            return d > now && d <= end
        }
    }

    // MARK: - Paging

    private func fetchPage(currentPage: Int, dateRange: String, completion: (() -> Void)?) {
        let urlString = "https://api.rawg.io/api/games?key=\(apiKey)&dates=\(dateRange)&ordering=-added,-released&page_size=\(pageSize)&page=\(currentPage)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid RAWG URL")
            completion?()
            return
        }

        // Standard URLSession fetch
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ No RAWG data returned")
                completion?()
                return
            }

            do {
                let decoded = try JSONDecoder().decode(RawgResponse.self, from: data)
                
                for item in decoded.results {
                    guard self.seenGameIDs.insert(item.id).inserted else { continue }

                    // Base model from RAWG LIST row
                    let gc = item.asGamerConnectGame()

                    // Persist shell immediately using new storage
                    self.storage.save(game: gc)
                }

                let total = self.seenGameIDs.count
                if decoded.results.count < self.pageSize || total >= self.maxGames {
                    print("✅ Finished fetching RAWG games: \(total)")
                    completion?()
                } else {
                    self.fetchPage(currentPage: currentPage + 1, dateRange: dateRange, completion: completion)
                }
            } catch {
                print("❌ RAWG decoding failed:", error.localizedDescription)
                completion?()
            }
        }
        task.resume()
    }
}

// MARK: - Extras

// MARK: - Helpers
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] { Array(Set(self)) }
}

// MARK: - Core Data helpers
extension GameEntity {
    var normalizedReleaseDate: Date? { self.releaseDate }

    public var id: String {
        gameId ?? objectID.uriRepresentation().absoluteString
    }
}

// MARK: - Detail model for enrichment
struct RawgGameDetail: Decodable {
    struct ParentPlatformWrap: Decodable { let platform: Platform
        struct Platform: Decodable { let name: String }
    }
    struct PlatformWrap: Decodable { let platform: Platform
        struct Platform: Decodable { let name: String }
    }
    struct Dev: Decodable { let name: String }
    struct Genre: Decodable { let name: String }
    
    struct Rating: Decodable {
        let title: String
        let count: Int
    }
    struct Tag: Decodable {
        let name: String
    }
    
    let playtime: Int?
    let ratings: [Rating]?
    let tags: [Tag]?

    let id: Int
    let name: String
    let released: String?
    let background_image: String?
    let parent_platforms: [ParentPlatformWrap]?
    let platforms: [PlatformWrap]?
    let developers: [Dev]?
    let genres: [Genre]?
    let description_raw: String?
    let slug: String
    // present but unused here; harmless to keep
    let added: Int?
    let ratings_count: Int?
    let metacritic: Int?
}

// MARK: - Enrichment (unchanged)
extension RawgGameProvider {
    func enrichFromRawgDetail(_ game: inout GamerConnectGame) async {
        guard let rawgID = Int(game.id) else { return }
        guard let url = URL(string: "https://api.rawg.io/api/games/\(rawgID)?key=\(apiKey)") else { return }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            let detail = try JSONDecoder().decode(RawgGameDetail.self, from: data)

            if game.availableConsoles.isEmpty {
                let names: [String] =
                    (detail.platforms?.map { $0.platform.name } ?? [])
                    + (detail.parent_platforms?.map { $0.platform.name } ?? [])
                let mapped = names.compactMap(PlatformCategoryMapper.mapPlatformNameToCategory).removingDuplicates()
                if !mapped.isEmpty { game.availableConsoles = mapped }
            }
            game.slug = detail.slug
            if game.categoryFilters.isEmpty {
                let gs = (detail.genres ?? []).map { $0.name }
                if !gs.isEmpty { game.categoryFilters = gs }
            }

            if ((game.developer?.isEmpty) != nil), let dev = detail.developers?.first?.name {
                game.developer = dev
            }
            
            if let score = detail.metacritic {
                game.metacriticScore = score
            }

            if game.releaseDate == nil, let r = detail.released, !r.isEmpty {
                game.releaseDate = r
            }

            if game.gameDescription.isEmpty, let desc = detail.description_raw {
                game.gameDescription = desc
            }
            
            if let hours = detail.playtime, hours > 0 {
                game.timeCommitment = self.determineTimeCommitment(fromPlaytime: hours)
            }
            
            if let tags = detail.tags {
                game.complexity = self.determineComplexity(fromTags: tags)
            }
            
            if let ratings = detail.ratings {
                // Converts the array of ratings into a simple [String: Int] dictionary
                game.ratingsBreakdown = Dictionary(uniqueKeysWithValues: ratings.map { ($0.title, $0.count) })
            }
        } catch {
            // ignore; we'll try next time
        }
    }
}

private extension RawgGameProvider {
    func determineTimeCommitment(fromPlaytime hours: Int) -> String {
        switch hours {
        case 0...1:
            return "Pick-up & Play"
        case 2...12:
            return "A Weekend Game"
        case 13...40:
            return "A Solid Adventure"
        case 41...100:
            return "An Epic Journey"
        default:
            return "100+ Hours"
        }
    }

    func determineComplexity(fromTags tags: [RawgGameDetail.Tag]) -> String {
        let tagSet = Set(tags.map { $0.name.lowercased() })

        if tagSet.contains("souls-like") || tagSet.contains("difficult") {
            return "Challenging"
        } else if tagSet.contains("casual") || tagSet.contains("family-friendly") || tagSet.contains("relaxing") {
            return "Easy to Learn"
        } else {
            return "Average"
        }
    }
}
