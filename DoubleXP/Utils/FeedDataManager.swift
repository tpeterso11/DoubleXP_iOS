//
//  FeedDataManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/11/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import Firebase

#if DEBUG
private let dbgNet = DebugNetworkController.shared
#endif

class FeedDataManager {
    
    /// The shared singleton instance.
    static let shared = FeedDataManager()
    
    /// A flag to determine the data source. Set to `false` to use Firebase.
    public var useMockData = true
    
    /// The fetched content. This is populated after calling `fetchHeaderContent`.
    // --- FIXED: Made public so VM can set it ---
    public var headerContent: [FeedHeaderMediaObj] = []
    
    /// A reference to the Firestore database.
    // private let db = Database.database() // Commented out, Database not imported
    
    /// Custom error type for data fetching.
    enum DataManagerError: Error {
        case fileNotFound(String)
        case firebaseError(Error)
        case mappingError(String)
        case notImplemented
    }
    
    // The initializer is private to ensure it's only created once.
    private init() {}
    
    /// Fetches the header content from the selected data source (mock or Firebase).
    // --- FIXED: Updated signature to be async throws and return data ---
    func fetchHeaderContent() async throws -> [FeedHeaderMediaObj] {
        #if DEBUG
        try await dbgNet.simulateHit()
        #endif

        if useMockData {
            let mockData = generateMockData()
            self.headerContent = mockData
            return mockData
        } else {
            let firebaseData = try await fetchFromFirebase()
            self.headerContent = firebaseData
            return firebaseData
        }
    }
    
    // --- FIXED: Updated signature to be async throws ---
    private func fetchFromFirebase() async throws -> [FeedHeaderMediaObj] {
        // --- SKELETON FOR FIREBASE REQUEST ---
        // TODO: Replace "header_items" with your actual Firestore collection name.
        // TODO: Consider adding `.order(by: "timestamp", descending: true)` to get the latest items.
        /*
         let snapshot = try await db.collection("header_items").getDocuments()
         
         let results: [FeedHeaderMediaObj] = snapshot.documents.compactMap { doc -> FeedHeaderMediaObj? in
             let data = doc.data()
             
             // Example of extracting data. You'll need to safely unwrap these.
             let id = doc.documentID // --- Get the ID ---
             let title = data["title"] as? String ?? ""
             let description = data["description"] as? String ?? ""
             let gameID = data["gameID"] as? String ?? ""
             let showTrailerButton = data["showTrailerButton"] as? Bool ?? false
             let imgUrl = data["imgUrl"] as? String // --- Get imgUrl String ---
             
             // Logic to determine media type from Firestore data
             var media: FeedHeaderMediaObj.MediaType?
             if let youtubeID = data["youtubeID"] as? String {
                 media = .youtube(videoID: youtubeID)
             } else if let videoURLString = data["videoURL"] as? String, let videoURL = URL(string: videoURLString) {
                 media = .nativeVideo(url: videoURL)
             } else if imgUrl != nil { // --- Check if imgUrl exists ---
                 media = .image
             }
             
             guard let finalMedia = media else {
                 return nil // Skip this item if media can't be determined
             }
             
             return FeedHeaderMediaObj(
                 id: id, // --- Pass the ID ---
                 media: finalMedia,
                 imgUrl: imgUrl, // --- Pass the imgUrl ---
                 title: title,
                 description: description,
                 gameID: gameID,
                 showTrailerButton: showTrailerButton
             )
         }
         
         self.headerContent = results
         return results
        */
        
        // --- Placeholder for non-implemented Firebase ---
        throw DataManagerError.notImplemented
    }
    
    /// Generates and returns the array of mock data.
    // --- FIXED: Corrected this function to match the FeedHeaderMediaObj struct ---
    private func generateMockData() -> [FeedHeaderMediaObj] {

            return [

                FeedHeaderMediaObj(id: "1234", media: .youtube(videoID: "kfYEiTdsyas"), title: "Starfield", description: "Venture through the stars and experience unparalleled freedom.", gameID: "game_starfield_01", showTrailerButton: false, imgUrl: nil),

                FeedHeaderMediaObj(id: "5678", media: .nativeVideo(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/gameterminal-767f7.appspot.com/o/trailers%2FDEATHLOOP%20-%20Official%20Gameplay%20Trailer%20(4K)%20%20State%20of%20Play.mp4?alt=media&token=009cfc5b-4b7a-4ff7-8063-93fb7adb319f")!), title: "Alan Wake II", description: "A string of ritualistic murders threatens the small town of Bright Falls.", gameID: "game_alanwake_02", showTrailerButton: false, imgUrl: nil),

                FeedHeaderMediaObj(id: "91203", media: .nativeVideo(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/gameterminal-767f7.appspot.com/o/trailers%2FCyberpunk%202077%20%E2%80%94%20Official%20Cinematic%20Trailer%20%20E3%202019.mp4?alt=media&token=435aafcd-14b2-4499-918a-3be7d1003ba3")!), title: "Cyberpunk 2077: Phantom Liberty", description: "A new spy-thriller adventure in Night City.", gameID: "game_cyberpunk_pl", showTrailerButton: false, imgUrl: nil),

                FeedHeaderMediaObj(id: "12341", media: .image(named: "baldursgate_art"), title: "Baldur's Gate 3", description: "Gather your party and return to the Forgotten Realms.", gameID: "game_baldursgate_03", showTrailerButton: true, imgUrl: "https://image.api.playstation.com/vulcan/ap/rnd/202308/2413/413362d3e50b2a819906bd9e2eb1c7a2b5c49ea184087c1d.png?w=440"),

                FeedHeaderMediaObj(id: "31434134", media: .youtube(videoID: "wi63uvjs6Uc"), title: "God of War Ragnarök", description: "Embark on a mythic journey for answers and allies.", gameID: "game_gow_ragnarok", showTrailerButton: false, imgUrl: nil)

            ]

        }
}
