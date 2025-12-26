//
//  GameQuizTakingViewModel.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import Combine

@MainActor
class GameQuizTakingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [String: QuizAnswer] = [:]
    @Published var showConfirmation: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var hasSubmitted: Bool = false
    @Published var showExitAlert: Bool = false
    @Published var error: String?
    @Published var isEditingFromConfirmation: Bool = false
    
    // MARK: - Properties
    
    let quiz: GameQuiz
    let userId: String
    let existingCompletion: UserQuizCompletion?
    let isEditing: Bool
    
    private let requestManager = GameQuizRequestManager.shared
    
    // MARK: - Computed Properties
    
    var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(quiz.questions.count)
    }
    
    var progressText: String {
        "\(currentQuestionIndex + 1) of \(quiz.questions.count)"
    }
    
    var canGoNext: Bool {
        // Check if current question is answered (if required)
        if currentQuestion.required {
            return answers[currentQuestion.id] != nil
        }
        return true
    }
    
    var canGoBack: Bool {
        currentQuestionIndex > 0
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }
    
    var answeredCount: Int {
        answers.count
    }
    
    var requiredQuestionsAnswered: Bool {
        let requiredQuestions = quiz.questions.filter { $0.required }
        return requiredQuestions.allSatisfy { question in
            answers[question.id] != nil
        }
    }
    
    var hasAnyAnswers: Bool {
        !answers.isEmpty
    }
    
    // MARK: - Initialization
    
    init(quiz: GameQuiz, userId: String, existingCompletion: UserQuizCompletion? = nil) {
        self.quiz = quiz
        self.userId = userId
        self.existingCompletion = existingCompletion
        self.isEditing = existingCompletion != nil
        
        // Load existing answers if editing
        if let completion = existingCompletion {
            var loadedAnswers: [String: QuizAnswer] = [:]
            for answer in completion.answers {
                loadedAnswers[answer.questionId] = answer
            }
            self.answers = loadedAnswers
        }
    }
    
    // MARK: - Navigation
    
    func goToNextQuestion() {
        // If editing from confirmation, return to confirmation
        if isEditingFromConfirmation {
            showConfirmation = true
            isEditingFromConfirmation = false
            return
        }
        
        guard currentQuestionIndex < quiz.questions.count - 1 else {
            // Last question, show confirmation
            showConfirmation = true
            return
        }
        
        currentQuestionIndex += 1
    }
    
    func goToPreviousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
    }
    
    func goToQuestion(at index: Int) {
        guard index >= 0 && index < quiz.questions.count else { return }
        currentQuestionIndex = index
        showConfirmation = false
        isEditingFromConfirmation = true // Flag that we're editing from confirmation
    }
    
    // MARK: - Answer Management
    
    func setAnswer(for questionId: String, selectedOptions: [String], textResponse: String? = nil) {
        let answer = QuizAnswer(
            questionId: questionId,
            selectedOptions: selectedOptions,
            textResponse: textResponse
        )
        answers[questionId] = answer
    }
    
    func getAnswer(for questionId: String) -> QuizAnswer? {
        return answers[questionId]
    }
    
    func isOptionSelected(questionId: String, option: String) -> Bool {
        guard let answer = answers[questionId] else { return false }
        return answer.selectedOptions.contains(option)
    }
    
    func toggleOption(questionId: String, option: String, isMultipleChoice: Bool) {
        var currentAnswer = answers[questionId]
        var selectedOptions = currentAnswer?.selectedOptions ?? []
        
        if isMultipleChoice {
            // Multiple choice - toggle
            if let index = selectedOptions.firstIndex(of: option) {
                selectedOptions.remove(at: index)
            } else {
                selectedOptions.append(option)
            }
        } else {
            // Single choice - replace
            selectedOptions = [option]
        }
        
        if selectedOptions.isEmpty {
            // Remove answer if no options selected
            answers.removeValue(forKey: questionId)
        } else {
            setAnswer(for: questionId, selectedOptions: selectedOptions)
        }
    }
    
    // MARK: - Submission
    
    func submitQuiz() async -> Bool {
        guard requiredQuestionsAnswered else {
            error = "Please answer all required questions"
            return false
        }
        
        isSubmitting = true
        error = nil
        
        do {
            let completion = UserQuizCompletion(
                id: existingCompletion?.id ?? UUID().uuidString,
                userId: userId,
                quizId: quiz.id,
                answers: Array(answers.values),
                completedAt: existingCompletion?.completedAt ?? Date().timeIntervalSince1970,
                lastModifiedAt: Date().timeIntervalSince1970,
                isPublic: existingCompletion?.isPublic ?? true
            )
            
            try await requestManager.saveQuizCompletion(completion)
            
            isSubmitting = false
            hasSubmitted = true
            
            print("✅ Quiz submitted successfully")
            return true
            
        } catch {
            self.error = "Failed to submit quiz: \(error.localizedDescription)"
            isSubmitting = false
            print("❌ Failed to submit quiz: \(error)")
            return false
        }
    }
    
    // MARK: - Save Progress
    
    func saveProgress() async {
        // Save as draft (same as submit but mark as incomplete)
        guard hasAnyAnswers else { return }
        
        do {
            let completion = UserQuizCompletion(
                id: existingCompletion?.id ?? UUID().uuidString,
                userId: userId,
                quizId: quiz.id,
                answers: Array(answers.values),
                completedAt: existingCompletion?.completedAt ?? Date().timeIntervalSince1970,
                lastModifiedAt: Date().timeIntervalSince1970,
                isPublic: false // Mark as private/draft until completed
            )
            
            try await requestManager.saveQuizCompletion(completion)
            print("✅ Progress saved")
            
        } catch {
            print("❌ Failed to save progress: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getQuestionNumber(for questionId: String) -> Int? {
        guard let index = quiz.questions.firstIndex(where: { $0.id == questionId }) else {
            return nil
        }
        return index + 1
    }
}
