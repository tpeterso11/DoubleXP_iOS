//
//  GameQuizRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import FirebaseDatabase

class GameQuizRequestManager {
    static let shared = GameQuizRequestManager()
    
    private let database = Database.database().reference()
    
    // MARK: - Fetch All Available Quizzes
    func fetchQuizzesForUser(userGames: [String]) async throws -> [GameQuiz] {
            print("\n🔍 fetchQuizzesForUser called")
            print("   User has \(userGames.count) games: \(userGames)")
            
            let allQuizzes = try await fetchAllQuizzes()
            print("   Fetched \(allQuizzes.count) quizzes from Firebase")
            
            // Log each quiz's associated_game_slug
            for quiz in allQuizzes {
                print("   Quiz: '\(quiz.title)' - associated_game_slug: '\(quiz.associatedGameSlug ?? "nil")'")
            }
            
            // Filter
            let visibleQuizzes = allQuizzes.filter { $0.isVisibleTo(userGames: userGames) }
            
            print("   Returning \(visibleQuizzes.count) visible quizzes\n")
            
            return visibleQuizzes
        }
    
    /*func fetchQuizzesForUser(userGames: [String]) async throws -> [GameQuiz] {
            let allQuizzes = try await fetchAllQuizzes()
            
            // Filter quizzes based on associated game slug
            let visibleQuizzes = allQuizzes.filter { quiz in
                quiz.isVisibleTo(userGames: userGames)
            }
            
            print("📋 [Quiz Filtering]")
            print("   Total quizzes: \(allQuizzes.count)")
            print("   Visible to user: \(visibleQuizzes.count)")
            print("   Filtered out: \(allQuizzes.count - visibleQuizzes.count)")
            
            return visibleQuizzes
        }*/
        
        /// Updated fetchAllQuizzes to include associatedGameSlug
        func fetchAllQuizzes() async throws -> [GameQuiz] {
            let snapshot = try await database.child("GameQuizzes").getData()
            
            guard snapshot.exists(),
                  let value = snapshot.value as? [String: Any] else {
                return []
            }
            
            var quizzes: [GameQuiz] = []
            
            for (quizId, quizData) in value {
                guard let quizDict = quizData as? [String: Any] else { continue }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: quizDict)
                    var quiz = try JSONDecoder().decode(GameQuiz.self, from: jsonData)
                    
                    // Ensure ID is set
                    if quiz.id.isEmpty {
                        quiz = GameQuiz(
                            id: quizId,
                            gameId: quiz.gameId,
                            gameName: quiz.gameName,
                            gameIcon: quiz.gameIcon,
                            title: quiz.title,
                            description: quiz.description,
                            questions: quiz.questions,
                            estimatedMinutes: quiz.estimatedMinutes,
                            category: quiz.category,
                            createdAt: quiz.createdAt,
                            updatedAt: quiz.updatedAt,
                            totalTaken: quiz.totalTaken,
                            averageCompletionRate: quiz.averageCompletionRate,
                            associatedGameSlug: quiz.associatedGameSlug // NEW: Pass through
                        )
                    }
                    
                    quizzes.append(quiz)
                } catch {
                    print("❌ Failed to decode quiz \(quizId): \(error)")
                }
            }
            
            // Sort by creation date (newest first)
            return quizzes.sorted { $0.createdAt > $1.createdAt }
        }
    
    /// Fetches all available quizzes from Firebase
    /// Path: /GameQuizzes/{quizId}
    
    
    // MARK: - Fetch User Completions
    
    /// Fetches all quiz completions for a specific user
    /// Path: /UserQuizCompletions/{userId}/{completionId}
    func fetchUserCompletions(userId: String) async throws -> [UserQuizCompletion] {
        print("📥 Fetching completions for user: \(userId)")
        
        let snapshot = try await database.child("UserQuizCompletions").child(userId).getData()
        
        guard snapshot.exists() else {
            print("   No completions found")
            return []
        }
        
        guard let value = snapshot.value as? [String: Any] else {
            print("   Invalid data format")
            return []
        }
        
        print("   Found \(value.count) completion(s)")
        
        var completions: [UserQuizCompletion] = []
        
        for (completionId, completionData) in value {
            guard let completionDict = completionData as? [String: Any] else {
                print("   ⚠️ Skipping invalid completion: \(completionId)")
                continue
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: completionDict)
                var completion = try JSONDecoder().decode(UserQuizCompletion.self, from: jsonData)
                
                // Ensure ID is set from the key
                if completion.id != completionId {
                    completion = UserQuizCompletion(
                        id: completionId,
                        userId: completion.userId,
                        quizId: completion.quizId,
                        answers: completion.answers,
                        completedAt: completion.completedAt,
                        lastModifiedAt: completion.lastModifiedAt,
                        isPublic: completion.isPublic
                    )
                }
                
                print("   ✓ Decoded completion: \(completionId) for quiz: \(completion.quizId)")
                completions.append(completion)
            } catch {
                print("   ❌ Failed to decode completion \(completionId): \(error)")
            }
        }
        
        print("✅ Successfully loaded \(completions.count) completions")
        return completions
    }
    
    // MARK: - Save Quiz Completion
    
    /// Saves or updates a quiz completion for a user
    func saveQuizCompletion(_ completion: UserQuizCompletion) async throws {
        print("💾 Saving quiz completion...")
        print("   User ID: \(completion.userId)")
        print("   Quiz ID: \(completion.quizId)")
        print("   Answers: \(completion.answers.count)")
        
        // Generate or use existing completion ID
        let completionId = completion.id.isEmpty ? UUID().uuidString : completion.id
        
        print("   Completion ID: \(completionId)")
        
        let completionDict: [String: Any] = [
            "user_id": completion.userId,
            "quiz_id": completion.quizId,
            "answers": completion.answers.map { answer in
                [
                    "question_id": answer.questionId,
                    "selected_options": answer.selectedOptions,
                    "text_response": answer.textResponse ?? ""
                ]
            },
            "completed_at": completion.completedAt,
            "last_modified_at": completion.lastModifiedAt,
            "is_public": completion.isPublic
        ]
        
        let path = "UserQuizCompletions/\(completion.userId)/\(completionId)"
        print("   Firebase path: \(path)")
        
        try await database
            .child("UserQuizCompletions")
            .child(completion.userId)
            .child(completionId)
            .setValue(completionDict)
        
        print("✅ Quiz completion saved successfully")
        
        // Update quiz stats (only if newly completed, not edited)
        if completion.id.isEmpty || completion.completedAt == completion.lastModifiedAt {
            try await incrementQuizTakenCount(quizId: completion.quizId)
        }
    }
    
    // MARK: - Delete Quiz Completion
    
    /// Deletes a quiz completion
    func deleteQuizCompletion(userId: String, completionId: String) async throws {
        try await database
            .child("UserQuizCompletions")
            .child(userId)
            .child(completionId)
            .removeValue()
    }
    
    // MARK: - Update Quiz Stats
    
    /// Increments the total taken count for a quiz
    private func incrementQuizTakenCount(quizId: String) async throws {
        let ref = database.child("GameQuizzes").child(quizId).child("total_taken")
        
        // Use transaction to safely increment
        try await ref.runTransactionBlock { currentData in
            if let currentValue = currentData.value as? Int {
                currentData.value = currentValue + 1
            } else {
                currentData.value = 1
            }
            return TransactionResult.success(withValue: currentData)
        }
    }
    
    // MARK: - Fetch Single Quiz
    
    /// Fetches a single quiz by ID (for quick retrieval)
    func fetchQuiz(quizId: String) async throws -> GameQuiz? {
        let snapshot = try await database.child("GameQuizzes").child(quizId).getData()
        
        guard snapshot.exists(),
              let value = snapshot.value as? [String: Any] else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: value)
        var quiz = try JSONDecoder().decode(GameQuiz.self, from: jsonData)
        
        // Ensure ID is set
        if quiz.id.isEmpty {
            quiz = GameQuiz(
                id: quizId,
                gameId: quiz.gameId,
                gameName: quiz.gameName,
                gameIcon: quiz.gameIcon,
                title: quiz.title,
                description: quiz.description,
                questions: quiz.questions,
                estimatedMinutes: quiz.estimatedMinutes,
                category: quiz.category,
                createdAt: quiz.createdAt,
                updatedAt: quiz.updatedAt,
                totalTaken: quiz.totalTaken,
                averageCompletionRate: quiz.averageCompletionRate
            )
        }
        
        return quiz
    }
    
    // MARK: - Fetch Quiz Stats
    
    /// Fetches aggregated stats for a quiz
    func fetchQuizStats(quizId: String) async throws -> QuizStats {
        let snapshot = try await database.child("GameQuizzes").child(quizId).getData()
        
        guard snapshot.exists(),
              let value = snapshot.value as? [String: Any],
              let totalTaken = value["total_taken"] as? Int else {
            return QuizStats(totalTaken: 0, averageCompletionRate: 0.0)
        }
        
        let avgCompletionRate = value["average_completion_rate"] as? Double ?? 0.0
        
        return QuizStats(totalTaken: totalTaken, averageCompletionRate: avgCompletionRate)
    }
}

// MARK: - Supporting Models

struct QuizStats {
    let totalTaken: Int
    let averageCompletionRate: Double
    
    var formattedTotalTaken: String {
        if totalTaken >= 1000 {
            return String(format: "%.1fk", Double(totalTaken) / 1000.0)
        }
        return "\(totalTaken)"
    }
}

