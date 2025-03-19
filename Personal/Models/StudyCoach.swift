//
//  StudyCoach.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import Foundation
import SwiftUI

struct StudyCoach: Identifiable, Codable {
    var id = UUID()
    var name: String
    var avatar: CoachAvatar
    var specialty: CoachSpecialty
    var personality: CoachPersonality
    var relationshipLevel: Int // 1-5 scale of how much the coach knows the user
    var lastInteraction: Date?
    
    // User's progress with this coach
    var interactions: [CoachInteraction] = []
    var studyPlans: [StudyPlan] = []
    var insights: [CoachInsight] = []
    var streakDays: Int = 0
    var lastStreakCheckDate: Date?
    
    // Study coach specialties
    enum CoachSpecialty: String, Codable, CaseIterable {
        case generalLearning = "General Learning"
        case mathScience = "Math & Science"
        case languageArts = "Language & Arts"
        case historyHumanities = "History & Humanities"
        case testPrep = "Test Preparation"
        case languages = "Language Learning"
        case professionalSkills = "Professional Skills"
        
        var description: String {
            switch self {
            case .generalLearning:
                return "All-around coach for general learning strategies"
            case .mathScience:
                return "Specializes in STEM subjects and scientific thinking"
            case .languageArts:
                return "Focuses on writing, reading comprehension, and creative skills"
            case .historyHumanities:
                return "Expert in historical context and social sciences"
            case .testPrep:
                return "Helps prepare for standardized tests and important exams"
            case .languages:
                return "Assists with language acquisition and practice"
            case .professionalSkills:
                return "Focuses on career skills and professional development"
            }
        }
        
        var iconName: String {
            switch self {
            case .generalLearning: return "brain.head.profile"
            case .mathScience: return "function"
            case .languageArts: return "text.book.closed"
            case .historyHumanities: return "building.columns"
            case .testPrep: return "checkmark.circle"
            case .languages: return "character.bubble"
            case .professionalSkills: return "briefcase"
            }
        }
    }
    
    // Coach personality types
    enum CoachPersonality: String, Codable, CaseIterable {
        case motivational = "Motivational"
        case analytical = "Analytical"
        case supportive = "Supportive"
        case challenging = "Challenging"
        case creative = "Creative"
        
        var description: String {
            switch self {
            case .motivational:
                return "Keeps you inspired and excited about learning"
            case .analytical:
                return "Focuses on data and patterns in your learning"
            case .supportive:
                return "Emphasizes encouragement and emotional support"
            case .challenging:
                return "Pushes you beyond your comfort zone"
            case .creative:
                return "Suggests innovative approaches to learning"
            }
        }
        
        var coachingStyle: String {
            switch self {
            case .motivational:
                return "Uses positive reinforcement and inspiring examples"
            case .analytical:
                return "Provides detailed breakdowns of your performance"
            case .supportive:
                return "Offers reassurance and scaffolding for difficult concepts"
            case .challenging:
                return "Sets ambitious goals and honest feedback"
            case .creative:
                return "Suggests unconventional methods and interdisciplinary connections"
            }
        }
    }
    
    // Visual representation of the coach
    enum CoachAvatar: String, Codable, CaseIterable {
        case sage = "Sage"
        case scientist = "Scientist"
        case artist = "Artist"
        case athlete = "Athlete"
        case explorer = "Explorer"
        
        var imageName: String {
            switch self {
            case .sage: return "coach_sage"
            case .scientist: return "coach_scientist"
            case .artist: return "coach_artist"
            case .athlete: return "coach_athlete"
            case .explorer: return "coach_explorer"
            }
        }
        
        var fallbackSymbol: String {
            switch self {
            case .sage: return "book.circle"
            case .scientist: return "atom"
            case .artist: return "paintpalette"
            case .athlete: return "figure.run"
            case .explorer: return "map"
            }
        }
        
        var primaryColor: Color {
            switch self {
            case .sage: return .purple
            case .scientist: return .blue
            case .artist: return .orange
            case .athlete: return .green
            case .explorer: return .red
            }
        }
    }
    
    // A single interaction with the study coach
    struct CoachInteraction: Identifiable, Codable {
        var id = UUID()
        var date: Date
        var messages: [CoachMessage]
        var topic: String
        var sentimentScore: Double? // -1.0 to 1.0, measuring the positivity of the interaction
        var duration: TimeInterval? // How long the interaction lasted
        var resultedInAction: Bool // Whether the interaction led to a study task
        
        struct CoachMessage: Identifiable, Codable {
            var id = UUID()
            var content: String
            var isFromCoach: Bool
            var timestamp: Date
            var messageType: MessageType
            
            enum MessageType: String, Codable {
                case text
                case suggestion
                case question
                case insight
                case encouragement
                case plan
                case task
            }
        }
    }
    
    // Study plan recommended by the coach
    struct StudyPlan: Identifiable, Codable {
        var id = UUID()
        var title: String
        var description: String
        var createdDate: Date
        var targetDate: Date?
        var isCompleted: Bool = false
        var progress: Double = 0.0 // 0.0 to 1.0
        var tasks: [StudyTask]
        var category: String
        var difficulty: Int // 1-5 scale
        
        struct StudyTask: Identifiable, Codable {
            var id = UUID()
            var title: String
            var description: String
            var isCompleted: Bool = false
            var estimatedMinutes: Int
            var actualMinutes: Int?
            var deadline: Date?
            var reminderTime: Date?
        }
    }
    
    // Insights provided by the coach based on learning data
    struct CoachInsight: Identifiable, Codable {
        var id = UUID()
        var title: String
        var description: String
        var category: InsightType
        var createdDate: Date
        var source: InsightSource
        var isActionable: Bool
        var relatedAction: String?
        
        enum InsightType: String, Codable {
            case pattern = "Learning Pattern"
            case strength = "Strength"
            case challenge = "Challenge"
            case improvement = "Improvement Area"
            case recommendation = "Recommendation"
            case milestone = "Milestone"
        }
        
        enum InsightSource: String, Codable {
            case flashcards = "Flashcard Data"
            case conversations = "Conversations"
            case studyTime = "Study Habits"
            case performance = "Performance Metrics"
            case userInput = "User Feedback"
        }
    }
    
    // Factory method to create a default coach
    static func createDefault(name: String = "Maya", specialty: CoachSpecialty = .generalLearning, personality: CoachPersonality = .supportive, avatar: CoachAvatar = .sage) -> StudyCoach {
        StudyCoach(
            name: name,
            avatar: avatar,
            specialty: specialty,
            personality: personality,
            relationshipLevel: 1,
            lastInteraction: nil
        )
    }
    
    // Calculate streak status
    mutating func updateStreak() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if we already checked today
        if let lastCheck = lastStreakCheckDate, calendar.isDateInToday(lastCheck) {
            return
        }
        
        // Check if the last interaction was yesterday
        if let lastDate = lastInteraction {
            if calendar.isDateInYesterday(lastDate) || calendar.isDateInToday(lastDate) {
                streakDays += 1
            } else {
                // Streak broken if not yesterday or today
                streakDays = 1
            }
        } else {
            // First interaction
            streakDays = 1
        }
        
        lastStreakCheckDate = now
    }
} 