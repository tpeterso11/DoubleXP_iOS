//
//  UserProfileRequestManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation

class UserProfileRequestManager {
    static let shared = UserProfileRequestManager()
    
    // MARK: - Configuration
    
    private let baseURL: String = "https://us-central1-gameterminal-767f7.cloudfunctions.net"
    
    // MARK: - Main Profile Fetch
    
    /// Fetches complete user profile data including quiz completions and proximity
    /// This is resilient - quiz and proximity failures won't break the response
    func fetchUserProfile(
            userId: String,
            currentUserId: String? = nil,
            maxDistanceMiles: Double = 100
        ) async throws -> UserProfileResponse {
            
            var urlComponents = URLComponents(string: "\(baseURL)/userProfile/v1/user-profile")!
            
            var queryItems = [URLQueryItem(name: "user_id", value: userId)]
            
            if let currentUserId = currentUserId {
                queryItems.append(URLQueryItem(name: "current_user_id", value: currentUserId))
            }
            
            queryItems.append(URLQueryItem(name: "max_distance", value: "\(maxDistanceMiles)"))
            queryItems.append(URLQueryItem(name: "include_errors", value: "1"))
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw UserProfileError.invalidURL
            }
            
            print("📡 [UserProfileAPI] Fetching profile: \(userId)")
            if let currentUserId = currentUserId {
                print("   Current user: \(currentUserId)")
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserProfileError.invalidResponse
            }
            
            print("   Response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw UserProfileError.userNotFound
                }
                throw UserProfileError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let profileResponse = try decoder.decode(UserProfileResponse.self, from: data)
            
            print("✅ [UserProfileAPI] Profile fetched successfully")
            print("   Quiz completions: \(profileResponse.quizzes.completions.count)")
            //print("   Proximity: \(profileResponse.proximity?.distanceMiles.map { "\($0) miles" } ?? "N/A")")
            
            if let errors = profileResponse.errors, !errors.notes.isEmpty {
                print("⚠️ [UserProfileAPI] Partial failures: \(errors.notes.joined(separator: ", "))")
            }
            
            return profileResponse
        }
    }

    // MARK: - Response Models

    struct UserProfileResponse: Codable {
        let user: UserData
        let quizzes: QuizData
        let proximity: ProximityData?
        let errors: ErrorData?
    }

    struct UserData: Codable {
        // Core identity
        let uId: String
        let screenName: String
        let gamerTag: String
        let bio: String
        let tagline: String
        let joinedAt: TimeInterval
        
        // Profile details
        let selectedAge: String
        let primaryLanguage: String
        let secondaryLanguage: String
        let gamingExperience: String
        let timezone: String
        
        // Platform flags
        let ps: Bool
        let xbox: Bool
        let pc: Bool
        let mobile: Bool
        let nintendo: Bool
        
        // Social connections
        let twitchConnect: String
        let instagramConnect: String
        let discordConnect: String
        let tiktokConnect: String
        let twitterConnect: String
        
        // Settings
        let onlineStatus: String
        let search: String
        let notifications: String
        let messagingNotifications: Bool
        
        // Collections (as arrays of strings/objects that need further parsing)
        let games: [String]
        let pokos: [String]
        let communities: [String]
        let userLookingFor: [String]
        let userAbout: [String]
        let blockList: [String]
        let restrictList: [String]
        
        // Social connections
        let followers: [String]
        let following: [String]
        
        // Content
        let highlightVideoId: String
        let spotlightVideoIds: [String]
        
        // Location (optional - only if user enabled)
        let userLat: Double?
        let userLong: Double?
        
        // No CodingKeys needed - convertFromSnakeCase handles it automatically
        // API sends: u_id, screen_name, gamer_tag, etc.
        // Decoder converts to: uId, screenName, gamerTag, etc.
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            // Core identity - required
            uId = try container.decode(String.self, forKey: AnyCodingKey("uId"))
            screenName = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("screenName")) ?? ""
            gamerTag = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("gamerTag")) ?? ""
            bio = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("bio")) ?? ""
            tagline = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("tagline")) ?? ""
            joinedAt = try container.decodeIfPresent(TimeInterval.self, forKey: AnyCodingKey("joinedAt")) ?? 0
            
            // Profile details
            selectedAge = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("selectedAge")) ?? ""
            primaryLanguage = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("primaryLanguage")) ?? ""
            secondaryLanguage = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("secondaryLanguage")) ?? ""
            gamingExperience = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("gamingExperience")) ?? ""
            timezone = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("timezone")) ?? ""
            
            // Platform flags
            ps = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("ps")) ?? false
            xbox = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("xbox")) ?? false
            pc = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("pc")) ?? false
            mobile = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("mobile")) ?? false
            nintendo = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("nintendo")) ?? false
            
            // Social connections
            twitchConnect = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("twitchConnect")) ?? ""
            instagramConnect = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("instagramConnect")) ?? ""
            discordConnect = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("discordConnect")) ?? ""
            tiktokConnect = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("tiktokConnect")) ?? ""
            twitterConnect = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("twitterConnect")) ?? ""
            
            // Settings
            onlineStatus = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("onlineStatus")) ?? "offline"
            search = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("search")) ?? "true"
            notifications = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("notifications")) ?? "true"
            messagingNotifications = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("messagingNotifications")) ?? false
            
            // Collections
            games = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("games")) ?? []
            pokos = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("pokos")) ?? []
            communities = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("communities")) ?? []
            userLookingFor = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("userLookingFor")) ?? []
            userAbout = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("userAbout")) ?? []
            blockList = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("blockList")) ?? []
            restrictList = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("restrictList")) ?? []
            
            // Social connections
            followers = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("followers")) ?? []
            following = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("following")) ?? []
            
            // Content
            highlightVideoId = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("highlightVideoId")) ?? ""
            spotlightVideoIds = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("spotlightVideoIds")) ?? []
            
            // Location (truly optional)
            userLat = try container.decodeIfPresent(Double.self, forKey: AnyCodingKey("userLat"))
            userLong = try container.decodeIfPresent(Double.self, forKey: AnyCodingKey("userLong"))
        }
    }

    // Helper for dynamic CodingKeys
    struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init(_ string: String) {
            self.stringValue = string
            self.intValue = nil
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    struct QuizData: Codable {
        let completions: [APIQuizCompletion]
        let quizDetails: [String: APIQuizDetail]
        
        // No CodingKeys needed - convertFromSnakeCase handles it automatically
        // API sends: quiz_details
        // Decoder converts to: quizDetails
    }

    struct APIQuizCompletion: Codable, Identifiable {
        let id: String
        let userId: String
        let quizId: String
        let answers: [APIQuizAnswer]
        let completedAt: TimeInterval
        let lastModifiedAt: TimeInterval
        let isPublic: Bool
        
        // Custom decoder to handle missing fields with defaults
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            id = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")) ?? ""
            userId = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("userId")) ?? ""
            quizId = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("quizId")) ?? ""
            answers = try container.decodeIfPresent([APIQuizAnswer].self, forKey: AnyCodingKey("answers")) ?? []
            completedAt = try container.decodeIfPresent(TimeInterval.self, forKey: AnyCodingKey("completedAt")) ?? 0
            lastModifiedAt = try container.decodeIfPresent(TimeInterval.self, forKey: AnyCodingKey("lastModifiedAt")) ?? 0
            isPublic = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("isPublic")) ?? true
        }
    }

    struct APIQuizAnswer: Codable {
        let questionId: String
        let selectedOptions: [String]
        let textResponse: String?
        
        // Custom decoder to work with convertFromSnakeCase
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            // These should exist - throw error if missing so we can debug
            questionId = try container.decode(String.self, forKey: AnyCodingKey("questionId"))
            selectedOptions = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("selectedOptions")) ?? []
            textResponse = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("textResponse"))
        }
    }

    struct APIQuizDetail: Codable {
        let id: String
        let gameId: String
        let gameName: String
        let gameIcon: String
        let title: String
        let description: String
        let questions: [APIQuizQuestion]
        let estimatedMinutes: Int
        let category: String
        let createdAt: TimeInterval
        let updatedAt: TimeInterval
        let totalTaken: Int
        let averageCompletionRate: Double
        
        // Custom decoder to handle missing fields with defaults
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            id = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")) ?? ""
            gameId = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("gameId")) ?? ""
            gameName = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("gameName")) ?? ""
            gameIcon = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("gameIcon")) ?? ""
            title = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("title")) ?? ""
            description = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("description")) ?? ""
            questions = try container.decodeIfPresent([APIQuizQuestion].self, forKey: AnyCodingKey("questions")) ?? []
            estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("estimatedMinutes")) ?? 0
            category = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("category")) ?? ""
            createdAt = try container.decodeIfPresent(TimeInterval.self, forKey: AnyCodingKey("createdAt")) ?? 0
            updatedAt = try container.decodeIfPresent(TimeInterval.self, forKey: AnyCodingKey("updatedAt")) ?? 0
            totalTaken = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("totalTaken")) ?? 0
            averageCompletionRate = try container.decodeIfPresent(Double.self, forKey: AnyCodingKey("averageCompletionRate")) ?? 0
        }
    }

    struct APIQuizQuestion: Codable {
        let id: String
        let questionText: String
        let questionType: String
        let options: [String]
        let required: Bool
        let order: Int
        let isImportant: Bool
        
        // Custom decoder to handle missing fields with defaults
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            id = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")) ?? ""
            questionText = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("questionText")) ?? ""
            questionType = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("questionType")) ?? ""
            options = try container.decodeIfPresent([String].self, forKey: AnyCodingKey("options")) ?? []
            required = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("required")) ?? false
            order = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("order")) ?? 0
            isImportant = try container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("isImportant")) ?? false
        }
    }

    struct ProximityData: Codable {
        let distanceMiles: Double
        let withinRange: Bool
        
        // No CodingKeys needed - convertFromSnakeCase handles it automatically
    }

    struct ErrorData: Codable {
        let user: String?
        let quizzes: String?
        let proximity: String?
        let notes: [String]
        
        // No CodingKeys needed - convertFromSnakeCase handles it automatically
    }

    // MARK: - Errors

    enum UserProfileError: LocalizedError {
        case invalidURL
        case invalidResponse
        case userNotFound
        case httpError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .userNotFound:
                return "User not found"
            case .httpError(let statusCode):
                return "HTTP error: \(statusCode)"
            }
        }
    }

    // MARK: - Helper: Convert API response to ProfileQuizItem

    extension APIQuizCompletion {
        func toProfileQuizItem(with quizDetail: APIQuizDetail) -> ProfileQuizItem {
            // Convert category string to QuizCategory enum
            let categoryEnum: QuizCategory
            switch quizDetail.category.lowercased() {
            case "playstyle":
                categoryEnum = .playstyle
            case "communication":
                categoryEnum = .communication
            case "strategy":
                categoryEnum = .strategy
            case "teamwork":
                categoryEnum = .teamwork
            case "mechanics":
                categoryEnum = .mechanics
            default:
                categoryEnum = .playstyle // Default fallback
            }
            
            return ProfileQuizItem(
                id: self.id,
                quiz: GameQuiz(
                    id: quizDetail.id,
                    gameId: quizDetail.gameId,
                    gameName: quizDetail.gameName,
                    gameIcon: quizDetail.gameIcon,
                    title: quizDetail.title,
                    description: quizDetail.description,
                    questions: quizDetail.questions.map { apiQuestion in
                        QuizQuestion(
                            id: apiQuestion.id,
                            questionText: apiQuestion.questionText,
                            questionType: QuestionType(rawValue: apiQuestion.questionType) ?? .multipleChoice,
                            options: apiQuestion.options,
                            required: apiQuestion.required,
                            order: apiQuestion.order,
                            isImportant: apiQuestion.isImportant
                        )
                    },
                    estimatedMinutes: quizDetail.estimatedMinutes,
                    category: categoryEnum,
                    createdAt: quizDetail.createdAt,
                    updatedAt: quizDetail.updatedAt,
                    totalTaken: quizDetail.totalTaken,
                    averageCompletionRate: quizDetail.averageCompletionRate
                ),
                completion: UserQuizCompletion(
                    id: self.id,
                    userId: self.userId,
                    quizId: self.quizId,
                    answers: self.answers.map { apiAnswer in
                        QuizAnswer(
                            questionId: apiAnswer.questionId,
                            selectedOptions: apiAnswer.selectedOptions,
                            textResponse: apiAnswer.textResponse
                        )
                    },
                    completedAt: self.completedAt,
                    lastModifiedAt: self.lastModifiedAt,
                    isPublic: self.isPublic
                ),
                answerCount: self.answers.count,
                completedDate: Date(timeIntervalSince1970: self.completedAt)
            )
        }
    }
