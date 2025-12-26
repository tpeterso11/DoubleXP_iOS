//
//  RAWGCoreDataManager 2.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/21/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import CoreData

final class RAWGCoreDataManager {
    static let shared = RAWGCoreDataManager()
    private init() {}

    // MARK: - Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RAWGModel")
        container.loadPersistentStores { _, error in
            if let error = error { print("❌ Failed to load Core Data stack:", error) }
        }
        // Recommended: merge policy avoids “multiple changes” conflicts on upserts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    // Optional background context if you start doing heavier writes later
    lazy var bgContext: NSManagedObjectContext = {
        let ctx = persistentContainer.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }()

    // MARK: - Save

    func saveContext() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { print("❌ Core Data save error:", error) }
    }

    // MARK: - Upsert a single game

    func saveGame(_ game: GamerConnectGame) {
        guard !game.id.isEmpty,
              !game.gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              ((game.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) == nil)
        else {
            print("⚠️ Skipping game due to missing display data (ID, name, or image)")
            return
        }

        context.perform {
            let fetchRequest: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
            fetchRequest.fetchLimit = 2
            fetchRequest.predicate = NSPredicate(format: "gameId == %@", game.id)

            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            fmt.dateFormat = "yyyy-MM-dd"

            do {
                let results = try self.context.fetch(fetchRequest)
                let entity = results.first ?? GameEntity(context: self.context)

                entity.gameId    = game.id
                entity.name      = game.gameName
                entity.imageUrl  = game.imageUrl
                entity.developer = game.developer
                entity.hook      = game.hook
                entity.available = game.available

                if let rd = game.releaseDate, let d = fmt.date(from: rd) {
                    entity.releaseDate = d
                } else {
                    if let rd = game.releaseDate, !rd.isEmpty {
                        print("⚠️ Could not parse release date: \(rd)")
                    }
                    entity.releaseDate = nil
                }

                entity.genres = game.categoryFilters.isEmpty ? nil : game.categoryFilters.joined(separator: ", ")

                // Clean dupes (rare)
                if results.count > 1 {
                    for extra in results.dropFirst() { self.context.delete(extra) }
                }

                try self.context.save()
            } catch {
                print("❌ Error saving game entity:", error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch

    func fetchGames() -> [GameEntity] {
        let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
        do { return try context.fetch(request) }
        catch { print("❌ Fetch error:", error); return [] }
    }

    func fetchGamerConnectGames() -> [GamerConnectGame] {
        let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"

        do {
            let results = try context.fetch(request)
            return results.compactMap { entity in
                guard let id = entity.gameId, !id.isEmpty else {
                    print("⚠️ Skipping entity with nil or empty gameId")
                    return nil
                }
                var game = GamerConnectGame(
                    id: id,
                    imageUrl: entity.imageUrl ?? "",
                    gameName: entity.name ?? "Untitled Game",
                    developer: entity.developer ?? "",
                    hook: entity.hook,
                    statsAvailable: false,
                    teamNeeds: [],
                    twitterHandle: nil,
                    twitchHandle: nil,
                    available: entity.available ?? "no",
                    availableConsoles: [],
                    gameModes: [],
                    secondaryName: nil,
                    releaseDate: entity.releaseDate.map { df.string(from: $0) },
                    gameType: nil,
                    categoryFilters: (entity.genres?
                        .components(separatedBy: ", ")
                        .filter { !$0.isEmpty }) ?? [],
                    lookingFor: [],
                    ratings: [],
                    quickReviews: [],
                    gameDescription: "",
                    alternateImageUrl: entity.imageUrl,
                    ideal: nil,
                    quizUrl: nil,
                    timeCommitment: nil,
                    complexity: nil
                )
                game.twitchGameId = id
                return game
            }
        } catch {
            print("❌ Fetch error:", error.localizedDescription)
            return []
        }
    }

    // Convenience: fetch a single entity by RAWG id
    func fetchGameEntity(rawgID: String) -> GameEntity? {
        let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "gameId == %@", rawgID)
        do { return try context.fetch(request).first }
        catch { print("❌ Fetch by id error:", error); return nil }
    }

    // MARK: - HOT metadata

    /// Single update. Safe if called frequently.
    func setHot(rawgID: String, score: Double, isHot: Bool, reason: String) {
        context.perform {
            let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "gameId == %@", rawgID)

            do {
                guard let e = try self.context.fetch(request).first else {
                    // Don’t create a new row here; hot only applies to known games
                    print("⚠️ setHot: no entity for gameId \(rawgID)")
                    return
                }
                e.hotScore     = score
                e.isHot        = isHot
                e.hotReason    = reason
                e.hotUpdatedAt = Date()
                try self.context.save()
            } catch {
                print("❌ setHot save error:", error.localizedDescription)
            }
        }
    }

    /// Batch update for many games in one save() call (preferred).
    func setHotMany(_ entries: [(rawgID: String, score: Double, isHot: Bool, reason: String)]) {
        guard !entries.isEmpty else { return }
        let ids = entries.map { $0.rawgID }

        context.perform {
            let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
            request.predicate = NSPredicate(format: "gameId IN %@", ids)

            do {
                let map = Dictionary(uniqueKeysWithValues: entries.map { ($0.rawgID, $0) })
                let rows = try self.context.fetch(request)

                for e in rows {
                    guard let id = e.gameId, let upd = map[id] else { continue }
                    e.hotScore     = upd.score
                    e.isHot        = upd.isHot
                    e.hotReason    = upd.reason
                    e.hotUpdatedAt = Date()
                }
                try self.context.save()

                // Optional: warn on ids that didn’t match
                let found = Set(rows.compactMap { $0.gameId })
                let missing = Set(ids).subtracting(found)
                if !missing.isEmpty {
                    print("⚠️ setHotMany: \(missing.count) ids not found (skipped)")
                }
            } catch {
                print("❌ setHotMany error:", error.localizedDescription)
            }
        }
    }

    /// Read hot metadata for a given gameId.
    func hotMeta(for rawgID: String) -> (score: Double, isHot: Bool, reason: String?, updatedAt: Date?)? {
        guard let e = fetchGameEntity(rawgID: rawgID) else { return nil }
        return (e.hotScore, e.isHot, e.hotReason, e.hotUpdatedAt)
    }

    /// Fetch hot games as entities, ordered by score desc.
    func fetchHotEntities(minScore: Double = 70, limit: Int = 50) -> [GameEntity] {
        let request: NSFetchRequest<GameEntity> = GameEntity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isHot == YES"),
            NSPredicate(format: "hotScore >= %f", minScore)
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "hotScore", ascending: false)]
        request.fetchLimit = limit
        do { return try context.fetch(request) }
        catch { print("❌ fetchHotEntities error:", error); return [] }
    }

    /// Fetch hot games as `GamerConnectGame`s (ready for UI).
    func fetchHotGamerConnectGames(minScore: Double = 70, limit: Int = 50) -> [GamerConnectGame] {
        return fetchHotEntities(minScore: minScore, limit: limit).compactMap { e in
            guard let id = e.gameId, let name = e.name else { return nil }
            var g = GamerConnectGame(
                id: id,
                imageUrl: e.imageUrl ?? "",
                gameName: name,
                developer: e.developer ?? "",
                hook: e.hook,
                statsAvailable: false,
                teamNeeds: [],
                twitterHandle: nil,
                twitchHandle: nil,
                available: e.available ?? "no",
                availableConsoles: [],
                gameModes: [],
                secondaryName: nil,
                releaseDate: e.releaseDate.map {
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyy-MM-dd"
                    return df.string(from: $0)
                },
                gameType: nil,
                categoryFilters: (e.genres?.components(separatedBy: ", ").filter { !$0.isEmpty }) ?? [],
                lookingFor: [],
                ratings: [],
                quickReviews: [],
                gameDescription: "",
                alternateImageUrl: e.imageUrl,
                ideal: nil,
                quizUrl: nil,
                timeCommitment: nil,
                complexity: nil
            )
            // If you want to expose hot meta on the model, add fields and set here.
            return g
        }
    }
}
