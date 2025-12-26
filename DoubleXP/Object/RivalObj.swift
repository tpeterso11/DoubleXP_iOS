//
//  RivalObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

struct RivalObj: Codable, Hashable {
    let id: String
    let gamerTag: String
    let senderPokoId: String
    let getterPokoId: String
    let game: String
    let gameImageUrl: String
    let type: String
    let date: String
    let uid: String
    let durationMin: Int
    let customMessage: String
    let customResponse: String
    let rivalStatus: String       // "accepted", "rejected", "proposed"
    let createdAtMs: Int64
    let expiresAtMs: Int64

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RivalObj, rhs: RivalObj) -> Bool {
        lhs.id == rhs.id
    }
}
