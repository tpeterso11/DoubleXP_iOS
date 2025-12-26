//
//  RecommendationEngine.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/26/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseDatabase

class RecommendationEngine {
    static let shared = RecommendationEngine()
    private let userRef = Database.database().reference().child("Users")
    
    private var onboardingRecommendations: [User] = []
    
    func fetchRecommendationsPostOnboarding(for currentUser: User, completion: @escaping ([User]) -> Void) {
        userRef.observeSingleEvent(of: .value) { snapshot in
            var recommendations: [(User, Int)] = []
            
            for case let child as DataSnapshot in snapshot.children {
                guard let dict = child.value as? [String: Any],
                      let screenName = dict["screenName"] as? String,
                      screenName != currentUser.screenName,
                      let games = dict["games"] as? [String],
                      let gamingExperience = dict["gamingExperience"] as? String,
                      let lat = dict["userLat"] as? Double,
                      let long = dict["userLong"] as? Double,
                      let selectedAge = dict["selectedAge"] as? String,
                      let signupDateStr = dict["signupDate"] as? String,
                      let signupDate = Self.dateFormatter.date(from: signupDateStr)
                else {
                    continue
                }
                
                let matchedUser = User(uId: child.key)
                matchedUser.screenName = screenName
                matchedUser.games = games
                matchedUser.gamingExperience = gamingExperience
                matchedUser.userLat = lat
                matchedUser.userLong = long
                matchedUser.selectedAge = selectedAge
                matchedUser.lastLogin = signupDateStr
                
                let score = self.calculateMatchScore(user1: currentUser, user2: matchedUser)
                recommendations.append((matchedUser, score))
            }
            
            let topRecommendations = recommendations.sorted { $0.1 > $1.1 }.prefix(3).map { $0.0 }
            self.onboardingRecommendations = topRecommendations
            completion(topRecommendations)
        }
    }
    
    func destroyOnboardingRecommendations() {
        onboardingRecommendations.removeAll()
    }
    
    private func calculateMatchScore(user1: User, user2: User) -> Int {
        var score = 0
        
        // 🎮 Favorite Game (first in array)
        if let fav1 = user1.games.first, let fav2 = user2.games.first, fav1 == fav2 {
            score += 40
        }
        
        // 🎯 Gaming Experience
        if let exp1 = Int(user1.gamingExperience),
           let exp2 = Int(user2.gamingExperience),
           abs(exp1 - exp2) <= 1 {
            score += 25
        }
        
        // 🕓 Signed up around same time (within a week)
        if let date1 = Self.dateFormatter.date(from: user1.lastLogin),
           let date2 = Self.dateFormatter.date(from: user2.lastLogin),
           Calendar.current.dateComponents([.day], from: date1, to: date2).day ?? 99 <= 7 {
            score += 15
        }

        // 📍 Location proximity
        if abs(user1.userLat - user2.userLat) < 0.5 && abs(user1.userLong - user2.userLong) < 0.5 {
            score += 10
        }

        // 👶 Similar age decade
        if let age1 = Int(user1.selectedAge),
           let age2 = Int(user2.selectedAge),
           (age1 / 10) == (age2 / 10) {
            score += 5
        }

        return score
    }
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
