//
//  Flashcard.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI

struct Flashcard: Identifiable, Codable, Equatable {
    var id = UUID()
    var question: String
    var answer: String
    var category: String // Subject or topic
    var createdAt: Date
    var lastReviewed: Date?
    var confidence: Int // 1-5 scale: 1=difficult, 5=mastered
    var fromConversationID: UUID? // Link to source conversation
    var starred: Bool = false
    
    // SM-2 Algorithm parameters
    var easeFactor: Double = 2.5 // Initial ease factor (how easy is the card to remember)
    var interval: Int = 0 // Current interval in days
    var repetitions: Int = 0 // Number of times the card has been successfully recalled
    var reviewHistory: [ReviewEntry] = [] // History of review sessions
    var dueDate: Date // When the card is due for review
    var markedForLater: Bool = false // Whether the card is marked for later review
    
    // Card display customization
    var hasHint: Bool = false
    var hint: String = ""
    var color: CardColor
    
    // Store review history
    struct ReviewEntry: Codable, Equatable {
        var date: Date
        var rating: Rating // The rating given during review
        var timeTaken: TimeInterval? // How long it took to answer (optional)
        var priorInterval: Int // The interval before this review
        var newInterval: Int // The interval set after this review
        
        enum Rating: Int, Codable {
            case again = 0 // Failed, start over
            case hard = 1  // Difficult, but recalled
            case good = 2  // Correctly recalled with some effort
            case easy = 3  // Easily recalled
        }
    }
    
    enum CardColor: String, Codable, CaseIterable {
        case blue
        case purple
        case green
        case orange
        case pink
        
        var uiColor: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .green: return .green
            case .orange: return .orange
            case .pink: return .pink
            }
        }
    }
    
    static func == (lhs: Flashcard, rhs: Flashcard) -> Bool {
        lhs.id == rhs.id
    }
    
    init(question: String, answer: String, category: String, fromConversationID: UUID? = nil, color: CardColor = .blue) {
        self.question = question
        self.answer = answer
        self.category = category
        self.createdAt = Date()
        self.confidence = 1
        self.dueDate = Date() // Due immediately upon creation
        self.fromConversationID = fromConversationID
        self.color = color
    }
    
    /// Update review date using the SM-2 algorithm (Anki-style spaced repetition)
    mutating func updateWithRating(_ rating: ReviewEntry.Rating, timeTaken: TimeInterval? = nil) {
        let now = Date()
        let priorInterval = interval
        var newInterval = 0
        var newEaseFactor = easeFactor
        
        // Update repetitions and intervals based on rating
        switch rating {
        case .again: // Failed to recall
            repetitions = 0
            newInterval = 1 // 1 day
            newEaseFactor = max(1.3, easeFactor - 0.2) // Decrease ease factor but keep minimum
            
        case .hard: // Difficult recall
            if repetitions == 0 {
                newInterval = 1 // First interval: 1 day
            } else if repetitions == 1 {
                newInterval = 3 // Second interval: 3 days
            } else {
                newInterval = Int(Double(interval) * 1.2 * newEaseFactor) // Slower progression
            }
            repetitions += 1
            newEaseFactor = max(1.3, easeFactor - 0.15) // Small decrease in ease
            
        case .good: // Normal recall
            if repetitions == 0 {
                newInterval = 1 // First interval: 1 day
            } else if repetitions == 1 {
                newInterval = 4 // Second interval: 4 days
            } else {
                newInterval = Int(Double(interval) * newEaseFactor) // Standard progression
            }
            repetitions += 1
            // Ease remains unchanged for "good" rating
            
        case .easy: // Easy recall
            if repetitions == 0 {
                newInterval = 3 // First interval: 3 days
            } else if repetitions == 1 {
                newInterval = 7 // Second interval: 7 days
            } else {
                newInterval = Int(Double(interval) * newEaseFactor * 1.3) // Faster progression
            }
            repetitions += 1
            newEaseFactor = min(3.0, easeFactor + 0.15) // Increase ease, but cap at 3.0
        }
        
        // Maximum interval cap (optional, prevents intervals from growing too large)
        let maxInterval = 365 // Maximum interval of 1 year
        newInterval = min(newInterval, maxInterval)
        
        // Update card properties
        interval = newInterval
        easeFactor = newEaseFactor
        dueDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now
        lastReviewed = now
        
        // Set confidence level based on rating (for backward compatibility)
        switch rating {
        case .again: confidence = 1
        case .hard: confidence = 2
        case .good: confidence = 3
        case .easy: confidence = 5
        }
        
        // Record this review in history
        let reviewEntry = ReviewEntry(
            date: now,
            rating: rating,
            timeTaken: timeTaken,
            priorInterval: priorInterval,
            newInterval: newInterval
        )
        reviewHistory.append(reviewEntry)
    }
    
    /// Legacy method for backward compatibility
    mutating func updateNextReview() {
        // Map confidence to rating
        let rating: ReviewEntry.Rating
        switch confidence {
        case 1: rating = .again
        case 2: rating = .hard
        case 3: rating = .good
        case 4, 5: rating = .easy
        default: rating = .good
        }
        
        updateWithRating(rating)
    }
    
    /// Legacy method for backward compatibility
    mutating func updateConfidence(newLevel: Int) {
        self.confidence = max(1, min(5, newLevel))
        
        // Map confidence to rating
        let rating: ReviewEntry.Rating
        switch newLevel {
        case 1: rating = .again
        case 2: rating = .hard
        case 3: rating = .good
        case 4, 5: rating = .easy
        default: rating = .good
        }
        
        updateWithRating(rating)
    }
} 