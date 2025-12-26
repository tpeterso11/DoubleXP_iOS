//
//  GameQuizModels.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

// MARK: - Game Quiz Models

struct GameQuiz: Identifiable, Codable, Equatable {
    let id: String
    let gameId: String
    let gameName: String
    let gameIcon: String
    let title: String
    let description: String
    let questions: [QuizQuestion]
    let estimatedMinutes: Int
    let category: QuizCategory
    let createdAt: TimeInterval
    let updatedAt: TimeInterval
    let totalTaken: Int
    let averageCompletionRate: Double
    let associatedGameSlug: String? // NEW: Optional game slug for filtering
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case gameName = "game_name"
        case gameIcon = "game_icon"
        case title
        case description
        case questions
        case estimatedMinutes = "estimated_minutes"
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalTaken = "total_taken"
        case averageCompletionRate = "average_completion_rate"
        case associatedGameSlug = "associated_game_slug" // NEW
    }
    
    init(
        id: String,
        gameId: String,
        gameName: String,
        gameIcon: String,
        title: String,
        description: String,
        questions: [QuizQuestion],
        estimatedMinutes: Int,
        category: QuizCategory,
        createdAt: TimeInterval,
        updatedAt: TimeInterval,
        totalTaken: Int,
        averageCompletionRate: Double,
        associatedGameSlug: String? = nil // NEW: Optional parameter
    ) {
        self.id = id
        self.gameId = gameId
        self.gameName = gameName
        self.gameIcon = gameIcon
        self.title = title
        self.description = description
        self.questions = questions
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalTaken = totalTaken
        self.averageCompletionRate = averageCompletionRate
        self.associatedGameSlug = associatedGameSlug
    }
    
    /// Determines if this quiz should be shown to a user based on their games
    func isVisibleTo(userGames: [String]) -> Bool {
        // If no associated game slug, quiz is visible to everyone
        guard let requiredSlug = associatedGameSlug, !requiredSlug.isEmpty else {
            return true
        }
        
        // Check if user has the required game (case-insensitive comparison)
        let userGamesLower = userGames.map { $0.lowercased() }
        return userGamesLower.contains(requiredSlug.lowercased())
    }
}

enum QuizCategory: String, Codable {
    case playstyle = "playstyle"
    case communication = "communication"
    case strategy = "strategy"
    case teamwork = "teamwork"
    case mechanics = "mechanics"
    
    var displayName: String {
        switch self {
        case .playstyle: return "Play Style"
        case .communication: return "Communication"
        case .strategy: return "Strategy"
        case .teamwork: return "Teamwork"
        case .mechanics: return "Mechanics"
        }
    }
}

struct QuizQuestion: Identifiable, Codable, Equatable {
    let id: String
    let questionText: String
    let questionType: QuestionType
    let options: [String]
    let required: Bool
    let order: Int
    let isImportant: Bool // Flag for "Important to Gamers"
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case questionType = "question_type"
        case options
        case required
        case order
        case isImportant = "is_important"
    }
}

enum QuestionType: String, Codable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case yesNo = "yes_no"
    case scale = "scale"
    case text = "text"
}

// MARK: - User Quiz Completion

struct UserQuizCompletion: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let quizId: String
    let answers: [QuizAnswer]
    let completedAt: TimeInterval
    let lastModifiedAt: TimeInterval
    var isPublic: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case quizId = "quiz_id"
        case answers
        case completedAt = "completed_at"
        case lastModifiedAt = "last_modified_at"
        case isPublic = "is_public"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""
        userId = try container.decode(String.self, forKey: .userId)
        quizId = try container.decode(String.self, forKey: .quizId)
        answers = try container.decode([QuizAnswer].self, forKey: .answers)
        completedAt = try container.decode(TimeInterval.self, forKey: .completedAt)
        lastModifiedAt = try container.decode(TimeInterval.self, forKey: .lastModifiedAt)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
    }
    
    init(id: String, userId: String, quizId: String, answers: [QuizAnswer], completedAt: TimeInterval, lastModifiedAt: TimeInterval, isPublic: Bool) {
        self.id = id
        self.userId = userId
        self.quizId = quizId
        self.answers = answers
        self.completedAt = completedAt
        self.lastModifiedAt = lastModifiedAt
        self.isPublic = isPublic
    }
}

struct QuizAnswer: Codable, Equatable {
    let questionId: String
    let selectedOptions: [String]
    let textResponse: String?
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case selectedOptions = "selected_options"
        case textResponse = "text_response"
    }
}

// MARK: - View Models (UI-Friendly)

struct QuizListItem: Identifiable, Equatable {
    let id: String
    let quiz: GameQuiz
    let completion: UserQuizCompletion?
    
    var isCompleted: Bool {
        completion != nil
    }
    
    var completionDate: Date? {
        guard let completion = completion else { return nil }
        return Date(timeIntervalSince1970: completion.completedAt)
    }
    
    var lastModifiedDate: Date? {
        guard let completion = completion else { return nil }
        return Date(timeIntervalSince1970: completion.lastModifiedAt)
    }
}

// MARK: - Firebase Response Models

struct QuizzesResponse: Codable {
    let quizzes: [String: GameQuiz]
}

struct CompletionsResponse: Codable {
    let completions: [String: UserQuizCompletion]
}
