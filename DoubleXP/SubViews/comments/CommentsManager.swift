//
//  CommentsManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/29/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Firebase

class CommentsManager {
    static let shared = CommentsManager()
    private let ref = Database.database().reference() // CHANGED: RTDB Reference
    
    private let appId = "default-app-id"
    
    private func commentsRef() -> DatabaseReference {
        return ref.child("artifacts").child(appId).child("public").child("data").child("comments")
    }
    
    /// Listen to comments for a specific media item in Real-Time
    /// Note: Ensure you index 'mediaId' in your Firebase Rules for performance.
    func listenToComments(for mediaId: String, completion: @escaping ([CommentModel]) -> Void) -> DatabaseHandle {
        let query = commentsRef()
            .queryOrdered(byChild: "mediaId")
            .queryEqual(toValue: mediaId)
            
        // Observe .value returns the entire list whenever anything changes.
        // For threaded comments, this is often easier than handling child_added recursively manually.
        let handle = query.observe(.value) { snapshot in
            var results: [CommentModel] = []
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let dict = childSnapshot.value as? [String: Any] else { continue }
                
                do {
                    // Convert dict to JSON data then decode
                    let jsonData = try JSONSerialization.data(withJSONObject: dict)
                    var comment = try JSONDecoder().decode(CommentModel.self, from: jsonData)
                    
                    // CHANGED: Manually assign the key to the ID property
                    comment.id = childSnapshot.key
                    results.append(comment)
                } catch {
                    print("Error decoding comment: \(error)")
                }
            }
            
            // RTDB queries return in order of the query key (mediaId), so we likely need to sort by timestamp locally
            results.sort(by: { $0.timestamp < $1.timestamp })
            
            completion(results)
        }
        return handle
    }
    
    func removeListener(handle: DatabaseHandle) {
        commentsRef().removeObserver(withHandle: handle)
    }
    
    /// Post a new comment or reply
    func postComment(mediaId: String, mediaType: MediaType, text: String, parentId: String? = nil) async throws {
        let currentUser = await UserProvider.shared.currentUser!
        let contentId = mediaId + "_" + mediaType.rawValue
        
        let newComment = CommentModel(
            id: contentId,
            mediaId: mediaId,
            mediaType: mediaType.rawValue,
            userId: currentUser.uId,
            userName: currentUser.screenName,
            userAvatar: PokoProvider.shared.userSelectedPoko?.headshotUrl ?? "",
            text: text,
            timestamp: Date().timeIntervalSince1970, // RTDB prefers primitive types
            parentId: parentId,
            likeCount: 0,
            userGames: currentUser.games,
            userAboutMe: currentUser.userAbout,
            userLookingFor: currentUser.userLookingFor,
            userLatitude: currentUser.userLat,
            userLongitude: currentUser.userLong
        )
        
        // Encode to Dictionary
        let data = try JSONEncoder().encode(newComment)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        // Write to RTDB
        try await commentsRef().childByAutoId().setValue(dict)
        
        // Sync Location to GeoFire node
        if(currentUser.userLat != 0 && currentUser.userLong != 0){ // only 0 if the user declined/removed location permissions
            updateGeoFireLocation(userId: currentUser.uId, lat: currentUser.userLat, long: currentUser.userLong)
        }
    }
    
    /// Helper to sync location to 'geofire' node
    private func updateGeoFireLocation(userId: String, lat: Double, long: Double) {
        let geoRef = ref.child("geofire").child(userId)
        
        let locationData: [String: Any] = [
            "l": [lat, long],
            "g": "9q8yy", // Ideally, you generate a real geohash here. For now, using a placeholder or just storing L is fine if you query manually.
            "timestamp": ServerValue.timestamp()
        ]
        
        geoRef.setValue(locationData)
    }
    
    /// Atomic Increment/Decrement
    func updateLikeCount(commentId: String, increment: Bool) async {
        let postRef = commentsRef().child(commentId).child("likeCount")
        do {
            let _ = try await postRef.runTransactionBlock { currentData in
                var value = currentData.value as? Int ?? 0
                value = increment ? value + 1 : value - 1
                currentData.value = value
                return TransactionResult.success(withValue: currentData)
            }
        } catch {
            print("Failed to update like count: \(error.localizedDescription)")
        }
    }
}
