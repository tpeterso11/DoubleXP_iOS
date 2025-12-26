//
//  AggregatedFirebaseService.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabaseInternal

class AggregatedFirebaseService {
    static let shared = AggregatedFirebaseService() // 🔐 Singleton instance
    var gameAnnouncements = [AnnouncementObj]()
    var gameInvites = [RivalObj]()
    var upcomingGames = [UpcomingGame]()
    private init() {} // 🚫 Prevent external instantiation

    private func resolveExpiresAtMs(dict: [String: Any], nowMs: Int64) -> Int64 {
        if let direct = toInt64(dict["expiresAtMs"]) { return direct }

        if let legacyStr = dict["date"] as? String,
           let created = parseLegacyDate(legacyStr) {
            let durMin = (dict["durationMin"] as? Int) ?? 20
            return Int64(created.timeIntervalSince1970 * 1000) + Int64(durMin * 60 * 1000)
        }

        let createdMs = toInt64(dict["createdAtMs"]) ?? (nowMs - 1)
        let durMin = (dict["durationMin"] as? Int) ?? 20
        return createdMs + Int64(durMin * 60 * 1000)
    }

    private func byExpiredDesc(_ a: (key: String, ms: Int64), _ b: (key: String, ms: Int64)) -> Bool {
        return a.ms > b.ms
    }
    
    private let ACTIVE_NODE  = "rivals_active"
    private let ARCHIVE_NODE = "rivals_archive"

    private func msNow() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

    private func toInt64(_ any: Any?) -> Int64? {
        if let v = any as? Int64 { return v }
        if let v = any as? Int   { return Int64(v) }
        if let v = any as? Double { return Int64(v) }
        if let v = any as? NSNumber { return v.int64Value }
        return nil
    }
    
    private struct InviteRecord {
        let key: String
        let id: String
        let gamerTag: String
        let game: String
        let fromUid: String
        let type: String
        let senderPokoId: String
        let durationMin: Int
        let expiresAtMs: Int64
        let originalDict: [String: Any]
    }

    private func parseLegacyDate(_ s: String) -> Date? {
        // Matches your earlier formatter "MM-dd-yyyy HH:mm zzz"
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "MM-dd-yyyy HH:mm zzz"
        return f.date(from: s)
    }
    

    func getGameAnnouncements() async {
        let ref = Database.database().reference().child("Announcements")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for announcement in snapshot.children {
                    let current = announcement as! DataSnapshot
                    var active = "false"
                    //var audience = ""
                    var gameImageUrl = ""
                    var message = ""
                    var title = ""
                    var type = ""
                    var date = ""
                    var detailsImageUrl = ""
                    var detailsTitle = ""
                    var announcementDetails = ""
                    let id = current.key
                    if(current.hasChild("active")){
                        active = current.childSnapshot(forPath: "active").value as? String ?? "false"
                    }
                    if(current.hasChild("details")){
                        announcementDetails = current.childSnapshot(forPath: "details").value as? String ?? ""
                    }
                    if(current.hasChild("gameImageUrl")){
                        gameImageUrl = current.childSnapshot(forPath: "gameImageUrl").value as? String ?? ""
                    }
                    if(current.hasChild("message")){
                        message = current.childSnapshot(forPath: "message").value as? String ?? ""
                    }
                    if(current.hasChild("title")){
                        title = current.childSnapshot(forPath: "title").value as? String ?? ""
                    }
                    if(current.hasChild("type")){
                        type = current.childSnapshot(forPath: "type").value as? String ?? ""
                    }
                    if(current.hasChild("announcementDate")){
                        date = current.childSnapshot(forPath: "announcementDate").value as? String ?? ""
                    }
                    if(current.hasChild("detailsImageUrl")){
                        detailsImageUrl = current.childSnapshot(forPath: "detailsImageUrl").value as? String ?? ""
                    }
                    if(current.hasChild("detailsTitle")){
                        detailsTitle = current.childSnapshot(forPath: "detailsTitle").value as? String ?? ""
                    }
                    let announcementObj = AnnouncementObj(announcementId: id, announcementTitle: title, announcementMessage: message, announcementActive: active, gameImageUrl: gameImageUrl, announcementType: type, announcementDate: date, announcementDetails: announcementDetails, detailsImageUrl: detailsImageUrl, detailsTitle: detailsTitle)
                    
                    if !self.gameAnnouncements.contains(where: { $0.announcementId == announcementObj.announcementId }) {
                        self.gameAnnouncements.append(announcementObj)
                    }
                }
            }
        })
    }

    private func makeInviteRecord(snap: DataSnapshot, nowMs: Int64) -> InviteRecord? {
        guard let dict = snap.value as? [String: Any] else { return nil }

        let id: String = (dict["id"] as? String) ?? snap.key
        let tag: String = (dict["gamerTag"] as? String) ?? ""
        let game: String = (dict["game"] as? String) ?? ""
        let from: String = (dict["uid"] as? String) ?? ""
        let typ: String = (dict["type"] as? String) ?? ""
        let senderPokoId: String = (dict["senderPokoId"] as? String) ?? ""
        let durationMin: Int = (dict["durationMin"] as? Int) ?? 0

        // Resolve expiry with robust fallbacks (Int/Int64/Double/NSNumber + legacy date)
        let exp: Int64 = {
            if let ms = toInt64(dict["expiresAtMs"]) { return ms }
            if let s = dict["date"] as? String, let created = parseLegacyDate(s) {
                let dur = (dict["durationMin"] as? Int) ?? 20
                return Int64(created.timeIntervalSince1970 * 1000) + Int64(dur * 60 * 1000)
            }
            let createdMs: Int64 = toInt64(dict["createdAtMs"]) ?? (nowMs - 1)
            let dur = (dict["durationMin"] as? Int) ?? 20
            return createdMs + Int64(dur * 60 * 1000)
        }()

        return InviteRecord(
            key: snap.key,
            id: id,
            gamerTag: tag,
            game: game,
            fromUid: from,
            type: typ,
            senderPokoId: senderPokoId,
            durationMin: durationMin,
            expiresAtMs: exp,
            originalDict: dict
        )
    }

    // MARK: - Public entry: fetch + process + prune

    func getUserGameInvites(
        uid: String,
        archiveTTLHours: Int = 48,
        maxArchivedToKeep: Int = 50
    ) {
        let userRef   = Database.database().reference().child("Users").child(uid)
        let activeRef = userRef.child(ACTIVE_NODE)

        // Keep the closure tiny; delegate to a helper
        activeRef.getData { [weak self] error, snapshot in
            guard let self = self, error == nil, let activeSnap = snapshot else { return }
            self.processActiveInvitesSnapshot(
                activeSnap,
                userRef: userRef,
                now: msNow(),
                uid: uid,
                archiveTTLHours: archiveTTLHours,
                maxArchivedToKeep: maxArchivedToKeep
            )
        }
    }

    // MARK: - Processor: small, explicit, compiler-friendly

    private func processActiveInvitesSnapshot(
        _ activeSnap: DataSnapshot,
        userRef: DatabaseReference,
        now: Int64,
        uid: String,
        archiveTTLHours: Int,
        maxArchivedToKeep: Int
    ) {
        var updates: [String: Any] = [:]
        var seenIds = Set(self.gameInvites.map { $0.id })  // de-dupe against existing
        let children = activeSnap.children

        for case let snap as DataSnapshot in children {
            guard let rec = makeInviteRecord(snap: snap, nowMs: now) else { continue }

            if now < rec.expiresAtMs {
                // Still valid → append if not already present
                if !seenIds.contains(rec.id) {
                    // Build RivalObj using originalDict for optional fields
                    let d = rec.originalDict
                    let obj = RivalObj(
                        id: rec.id,
                        gamerTag: rec.gamerTag,
                        senderPokoId: rec.senderPokoId,
                        getterPokoId: (d["getterPokoId"] as? String) ?? "",
                        game: rec.game,
                        gameImageUrl: (d["gameImageUrl"] as? String) ?? "",
                        type: rec.type,
                        date: String(rec.expiresAtMs),
                        uid: rec.fromUid,
                        durationMin: rec.durationMin,
                        customMessage: (d["customMessage"] as? String) ?? "",
                        customResponse: (d["customResponse"] as? String) ?? "",
                        rivalStatus: (d["rivalStatus"] as? String) ?? "",
                        createdAtMs: toInt64(d["createdAtMs"]) ?? 0,
                        expiresAtMs: rec.expiresAtMs
                    )
                    self.gameInvites.append(obj)
                    seenIds.insert(rec.id)
                }
            } else {
                // Expired → move to archive (batched fan-out)
                var expiredData = rec.originalDict
                expiredData["status"] = "expired"
                expiredData["expiredAtMs"] = ServerValue.timestamp() as Any
                updates["\(ACTIVE_NODE)/\(rec.key)"]  = NSNull()
                updates["\(ARCHIVE_NODE)/\(rec.key)"] = expiredData
            }
        }

        if !updates.isEmpty {
            userRef.updateChildValues(updates)
        }

        pruneRivalsArchive(uid: uid, ttlHours: archiveTTLHours, keepMostRecent: maxArchivedToKeep)
    }

    // MARK: - Archive pruning kept small and explicit

    func pruneRivalsArchive(uid: String, ttlHours: Int = 48, keepMostRecent: Int = 50) {
        let userRef    = Database.database().reference().child("Users").child(uid)
        let archiveRef = userRef.child(ARCHIVE_NODE)
        let cutoff: Int64 = msNow() - Int64(ttlHours) * 60 * 60 * 1000

        archiveRef.observeSingleEvent(of: .value, with: { (snap: DataSnapshot) in
            guard snap.exists() else { return }

            var rows: [(key: String, expiredAtMs: Int64)] = []
            for case let s as DataSnapshot in snap.children {
                if let d = s.value as? [String: Any] {
                    let ms: Int64 = self.toInt64(d["expiredAtMs"]) ?? 0
                    rows.append((s.key, ms))
                }
            }

            // TTL deletions
            var deletions = Set(rows.compactMap { ($0.expiredAtMs != 0 && $0.expiredAtMs < cutoff) ? $0.key : nil })

            // Cap deletions (keep newest N)
            let sorted = rows.sorted { $0.expiredAtMs > $1.expiredAtMs }
            if sorted.count > keepMostRecent {
                for r in sorted.dropFirst(keepMostRecent) { deletions.insert(r.key) }
            }

            guard !deletions.isEmpty else { return }
            var updates: [String: Any] = [:]
            for k in deletions { updates["\(self.ARCHIVE_NODE)/\(k)"] = NSNull() }
            userRef.updateChildValues(updates)
        })
    }
    
    func inviteTimingString(createdAtMs: Int64, durationMin: Int) -> String {
        let now = Date()
        let createdDate = Date(timeIntervalSince1970: TimeInterval(createdAtMs) / 1000.0)
        let elapsedSec = Int(now.timeIntervalSince(createdDate))

        // 1) Elapsed (how long ago the invite was created)
        let elapsedString: String
        if elapsedSec < 60 {
            elapsedString = "\(elapsedSec) sec ago"
        } else if elapsedSec < 3600 {
            elapsedString = "\(elapsedSec / 60) min ago"
        } else if elapsedSec < 86400 {
            elapsedString = "\(elapsedSec / 3600) hr ago"
        } else {
            elapsedString = "\(elapsedSec / 86400) d ago"
        }

        // 2) Time until/after meetup
        let targetDate = createdDate.addingTimeInterval(TimeInterval(durationMin * 60))
        let remainingSec = Int(targetDate.timeIntervalSince(now))

        let remainingString: String
        if remainingSec >= 3600 {
            remainingString = "About \(remainingSec / 3600) hr"
        } else if remainingSec >= 60 {
            remainingString = "About \(remainingSec / 60) min"
        } else if remainingSec >= 0 {
            // 0..59 sec from now
            remainingString = "Now"
        } else {
            // Past due
            let pastSec = -remainingSec
            if pastSec < 3600 {
                // Round to at least 1 minute
                let mins = max(1, pastSec / 60)
                remainingString = "\(mins) min ago"
            } else {
                remainingString = "Expired"
            }
        }

        return "\(elapsedString) • \(remainingString)"
    }
    
    func acceptInvite(invite: RivalObj) {
        let db = Database.database().reference()
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let inviteId  = invite.id
        let senderUid = invite.uid                  // original inviter (the other user)
        let me        = (UIApplication.shared.delegate as! AppDelegate).currentUser!

        // Optional safety: don’t accept expired
        if let expMs = Int64(invite.date), now >= expMs {
            print("Invite \(inviteId) already expired; not accepting.")
            return
        }

        // Paths
        let getterActiveRef  = db.child("Users").child(me.uId).child(ACTIVE_NODE).child(inviteId)

        // Read the getter’s active record so we can archive the full object
        getterActiveRef.getData { error, snap in
            var updates: [String: Any] = [:]

            // Mirrored payload that the sender will see in their active feed
            let mirrored: [String: Any] = [
                "id": inviteId,
                "type": invite.type,                   // "invite" | "challenge"
                "game": invite.game,
                "gamerTag": invite.gamerTag,          // inviter’s tag (as originally sent)
                "uid": senderUid,                     // original inviter uid
                "durationMin": invite.durationMin,
                "expiresAtMs": Int64(invite.date) ?? (now + Int64(invite.durationMin * 60 * 1000)),
                "senderPokoId": invite.senderPokoId,

                "status": "accepted",
                "rivalStatus": "accepted",
                "acceptedAtMs": ServerValue.timestamp(),

                // responder (me)
                "getterUid": me.uId,
                "getterGamerTag": me.screenName,
                "responderPokoId": me.currentSelectedPokoId
            ]

            // Fan-out: remove from getter/active, write to getter/archive, and write mirrored to sender/active
            updates["Users/\(me.uId)/\(self.ACTIVE_NODE)/\(inviteId)"]  = NSNull()
            updates["Users/\(me.uId)/\(self.ARCHIVE_NODE)/\(inviteId)"] = mirrored
            updates["Users/\(senderUid)/\(self.ACTIVE_NODE)/\(inviteId)"] = mirrored

            db.updateChildValues(updates) { err, _ in
                if let err = err {
                    print("❌ acceptInvite failed: \(err.localizedDescription)")
                } else {
                    print("✅ acceptInvite archived getter + notified sender for \(inviteId)")
                }
            }
        }
    }

    func declineInvite(invite: RivalObj, customMessage: String? = nil) {
        let db = Database.database().reference()
        let inviteId  = invite.id
        let senderUid = invite.uid
        let me        = (UIApplication.shared.delegate as! AppDelegate).currentUser!

        let getterActiveRef  = db.child("Users").child(me.uId).child(ACTIVE_NODE).child(inviteId)

        getterActiveRef.getData { error, snap in
            var updates: [String: Any] = [:]

            // Mirrored for sender
            var mirrored: [String: Any] = [
                "id": inviteId,
                "type": invite.type,
                "game": invite.game,
                "status": "rejected",
                "rejectedAtMs": ServerValue.timestamp(),

                // Keep some context
                "gamerTag": invite.gamerTag,
                "uid": senderUid,
                "durationMin": invite.durationMin,
                "expiresAtMs": invite.expiresAtMs
            ]
            if let msg = customMessage { mirrored["customMessage"] = msg }

            // Fan-out: remove from getter/active, write to getter/archive, write mirrored to sender/active
            updates["Users/\(me.uId)/\(self.ACTIVE_NODE)/\(inviteId)"]  = NSNull()
            updates["Users/\(me.uId)/\(self.ARCHIVE_NODE)/\(inviteId)"] = mirrored
            updates["Users/\(senderUid)/\(self.ACTIVE_NODE)/\(inviteId)"] = mirrored

            db.updateChildValues(updates) { err, _ in
                if let err = err {
                    print("❌ declineInvite failed: \(err.localizedDescription)")
                } else {
                    print("✅ declineInvite archived getter + notified sender for \(inviteId)")
                }
            }
        }
    }
    
    func dismissInviteInBackground(uid: String, invite: RivalObj) {
        let userRef   = Database.database().reference().child("Users").child(uid)
        let activeRef = userRef.child(ACTIVE_NODE)

        // Try direct key; if not found, query by id
        func move(activeKey: String, original: [String: Any]) {
            var archived = original
            archived["status"] = "dismissed"
            archived["dismissedAtMs"] = ServerValue.timestamp()

            let updates: [String: Any] = [
                "\(ACTIVE_NODE)/\(activeKey)": NSNull(),
                "\(ARCHIVE_NODE)/\(activeKey)": archived
            ]

            userRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    // Fire-and-forget: log for diagnostics. Optional: enqueue retry/backoff here.
                    print("⚠️ Dismiss move failed: \(error.localizedDescription)")
                }
            }
        }

        // Fast path: active child with the invite id as key
        activeRef.child(invite.id).getData { err, snap in
            if err == nil, let snap, snap.exists(), let dict = snap.value as? [String: Any] {
                move(activeKey: snap.key, original: dict)
                return
            }

            // Fallback: query by "id" field (for auto IDs)
            let q = activeRef.queryOrdered(byChild: "id").queryEqual(toValue: invite.id)
            q.observeSingleEvent(of: .value) { qsnap in
                guard qsnap.exists(),
                      let first = qsnap.children.allObjects.first as? DataSnapshot,
                      let dict = first.value as? [String: Any] else {
                    // Already gone or never found; nothing to do
                    return
                }
                move(activeKey: first.key, original: dict)
            }
        }
    }
    
    func getUpcomingGames() {
        let ref = Database.database().reference().child("Upcoming Games")

        // One shot read; avoids observer lifecycle issues
        ref.getData { error, snapshot in
            guard error == nil, let snapshot = snapshot, snapshot.exists() else {
                AggregatedFirebaseService.shared.upcomingGames = []
                return
            }

            // Convert children to typed array
            let children = snapshot.children.allObjects as? [DataSnapshot] ?? []

            // Build models from dicts with a single pass
            let games: [UpcomingGame] = children.compactMap { snap in
                guard let dict = snap.value as? [String: Any] else { return nil }
                return UpcomingGame(id: snap.key, dict: dict)
            }

            // Cache for later use
            AggregatedFirebaseService.shared.upcomingGames = games
        }
    }
    
    func submitReactions(
            for userId: String,
            payloads: [PendingReactionPayload]
        ) {
            guard !payloads.isEmpty else {
                return
            }

            let reactionsRoot = Database.database().reference().child("Reactions")

            // Build a single update batch for all payloads
            var updates: [String: Any] = [:]

            for payload in payloads {
                // Example key: "game_12345"
                let targetKey = "\(payload.targetKind.rawValue)_\(payload.targetID)"
                let path = "\(targetKey)/\(userId)"

                if let finalReaction = payload.finalReaction {
                    var data: [String: Any] = [
                        "reactionType": finalReaction.rawValue,
                        "updatedAtMs": Int64(payload.updatedAt.timeIntervalSince1970 * 1000.0)
                    ]

                    if let art = payload.artURLString, !art.isEmpty {
                        data["artUrl"] = art
                    }

                    updates[path] = data
                } else {
                    // No reaction => remove this user's node for that target
                    updates[path] = NSNull()
                }
            }

            guard !updates.isEmpty else {
                return
            }

            reactionsRoot.updateChildValues(updates) { error, _ in
                if let error = error {
                    print("❌ [AggregatedFirebaseService] submitReactions failed: \(error.localizedDescription)")
                    // We do NOT clear pending here; ReactionsManager keeps them
                    // so they can be retried on the next flush.
                    return
                }

                print("✅ [AggregatedFirebaseService] submitReactions succeeded for user \(userId) with \(payloads.count) item(s)")

                // On success, clear the corresponding pending payloads from the manager.
                Task { @MainActor in
                    //ReactionsManager.shared.markBatchAsSynced(<#T##articleIDs: [String]##[String]#>)
                }
            }
        }
}
