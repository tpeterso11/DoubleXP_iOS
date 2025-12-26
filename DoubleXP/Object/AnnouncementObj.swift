//
//  AnnouncementObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/8/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

struct AnnouncementObj: Codable, Hashable {
    var announcementId: String
    var announcementTitle: String
    var announcementMessage: String
    var announcementActive: String
    var gameImageUrl: String
    var announcementType: String
    var announcementDate: String
    var announcementGames: [String] = []
    var announcementAudience: [String] = []
    var announcementDuration: String = ""
    var announcementSender: String = ""
    var announcementDetails: String
    var detailsImageUrl: String
    var detailsTitle: String
}

struct AnnouncementDismissalManager {
    private static let dismissedKey = "dismissedAnnouncements"

    // Save an ID to the dismissed list
    static func dismissAnnouncement(id: String) {
        var dismissed = getDismissedAnnouncements()
        dismissed.insert(id)
        UserDefaults.standard.set(Array(dismissed), forKey: dismissedKey)
    }

    // Retrieve the full set
    static func getDismissedAnnouncements() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: dismissedKey) ?? []
        return Set(array)
    }

    // Check if a given ID is dismissed
    static func isDismissed(id: String) -> Bool {
        return getDismissedAnnouncements().contains(id)
    }

    // Optional: clear all (for debugging or logout)
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: dismissedKey)
    }
}

