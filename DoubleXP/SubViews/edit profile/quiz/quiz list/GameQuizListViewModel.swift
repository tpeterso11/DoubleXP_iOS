//
//  GameQuizListViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import Foundation
import Combine

@MainActor
class GameQuizListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var quizItems: [QuizListItem] = []
    @Published var isLoading: Bool = true
    @Published var showIntroOverlay: Bool = false
    @Published var error: String?
    
    // MARK: - Private Properties
    
    private let requestManager = GameQuizRequestManager.shared
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var completedQuizzes: [QuizListItem] {
        quizItems.filter { $0.isCompleted }.sorted { item1, item2 in
            guard let date1 = item1.lastModifiedDate,
                  let date2 = item2.lastModifiedDate else {
                return false
            }
            return date1 > date2
        }
    }
    
    var availableQuizzes: [QuizListItem] {
        quizItems.filter { !$0.isCompleted }.sorted { $0.quiz.createdAt > $1.quiz.createdAt }
    }
    
    var completionPercentage: Int {
        guard !quizItems.isEmpty else { return 0 }
        let completed = completedQuizzes.count
        let total = quizItems.count
        return Int((Double(completed) / Double(total)) * 100)
    }
    
    // MARK: - Initialization
    
    init(userId: String) {
        self.userId = userId
        checkIfShouldShowIntro()
    }
    
    // MARK: - Public Methods
    
    func loadQuizzes() async {
            isLoading = true
            error = nil
            
            // Get current user's games
            guard let currentUser = UserProvider.shared.getUser() else {
                self.error = "User not found"
                self.isLoading = false
                return
            }
            
            do {
                // Fetch quizzes filtered by user's games
                async let quizzesTask = requestManager.fetchQuizzesForUser(userGames: currentUser.games)
                async let completionsTask = requestManager.fetchUserCompletions(userId: userId)
                
                let (quizzes, completions) = try await (quizzesTask, completionsTask)
                
                // Create completion lookup dictionary
                let completionDict = Dictionary(uniqueKeysWithValues: completions.map { ($0.quizId, $0) })
                
                // Build quiz list items
                quizItems = quizzes.map { quiz in
                    QuizListItem(
                        id: quiz.id,
                        quiz: quiz,
                        completion: completionDict[quiz.id]
                    )
                }
                
                isLoading = false
                
                print("✅ Loaded \(quizzes.count) quizzes, \(completions.count) completions")
                print("📊 Completions: \(completions.map { "Quiz: \($0.quizId), ID: \($0.id)" })")
                
            } catch {
                self.error = "Failed to load quizzes: \(error.localizedDescription)"
                isLoading = false
                print("❌ Failed to load quizzes: \(error)")
            }
        }
    
    func refreshQuizzes() async {
            // Get current user's games
            guard let currentUser = UserProvider.shared.getUser() else {
                return
            }
            
            // Refresh without showing loading spinner
            do {
                async let quizzesTask = requestManager.fetchQuizzesForUser(userGames: currentUser.games)
                async let completionsTask = requestManager.fetchUserCompletions(userId: userId)
                
                let (quizzes, completions) = try await (quizzesTask, completionsTask)
                
                let completionDict = Dictionary(uniqueKeysWithValues: completions.map { ($0.quizId, $0) })
                
                quizItems = quizzes.map { quiz in
                    QuizListItem(
                        id: quiz.id,
                        quiz: quiz,
                        completion: completionDict[quiz.id]
                    )
                }
                
                print("🔄 Refreshed - \(quizzes.count) quizzes, \(completions.count) completions")
                
            } catch {
                print("❌ Failed to refresh: \(error)")
            }
        }
    
    func deleteCompletion(_ item: QuizListItem) async {
        guard let completion = item.completion else { return }
        
        do {
            try await requestManager.deleteQuizCompletion(
                userId: userId,
                completionId: completion.id
            )
            
            // Update local state - remove completion from the item
            if let index = quizItems.firstIndex(where: { $0.id == item.id }) {
                quizItems[index] = QuizListItem(
                    id: item.id,
                    quiz: item.quiz,
                    completion: nil
                )
            }
            
            print("✅ Deleted completion for quiz: \(item.quiz.title)")
            
        } catch {
            self.error = "Failed to delete quiz: \(error.localizedDescription)"
            print("❌ Failed to delete completion: \(error)")
        }
    }
    
    // MARK: - Intro Overlay
    
    private func checkIfShouldShowIntro() {
        let key = "hasSeenGameQuizIntro"
        let hasSeenIntro = UserDefaults.standard.bool(forKey: key)
        
        if !hasSeenIntro {
            showIntroOverlay = true
        }
    }
    
    func markIntroAsSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenGameQuizIntro")
        showIntroOverlay = false
    }
    
    // MARK: - Helper Methods
    
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date)
    }
    
    func formattedTotalTaken(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fk", thousands)
        }
        return "\(count)"
    }
}

