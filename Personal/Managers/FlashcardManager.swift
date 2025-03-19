//
//  FlashcardManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI
import NaturalLanguage

class FlashcardManager: ObservableObject {
    @Published var flashcards: [Flashcard] = []
    @Published var categories: Set<String> = []
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var showGenerationProgress = false
    
    private let userDefaultsKey = "dronaFlashcards"
    private let categoriesKey = "dronaFlashcardCategories"
    
    // For accessing GeminiService
    private let geminiService = GeminiService()
    
    // Create a singleton instance for global access
    static let shared = FlashcardManager()
    
    private init() {
        loadFlashcards()
        loadCategories()
    }
    
    // MARK: - Card Management
    
    func addFlashcard(_ flashcard: Flashcard) {
        flashcards.append(flashcard)
        categories.insert(flashcard.category)
        saveFlashcards()
        saveCategories()
    }
    
    func updateFlashcard(_ flashcard: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            flashcards[index] = flashcard
            saveFlashcards()
            
            // Update categories if necessary
            updateCategories()
        }
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) {
        flashcards.removeAll { $0.id == flashcard.id }
        saveFlashcards()
        
        // Update categories if necessary
        updateCategories()
    }
    
    func updateConfidence(for flashcard: Flashcard, newLevel: Int) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            var updatedCard = flashcards[index]
            updatedCard.updateConfidence(newLevel: newLevel)
            flashcards[index] = updatedCard
            saveFlashcards()
        }
    }
    
    func toggleStar(for flashcard: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            flashcards[index].starred.toggle()
            saveFlashcards()
        }
    }
    
    // MARK: - Flashcard Generation
    
    func generateFlashcardsFromConversation(_ conversation: Conversation, count: Int = 5, completion: @escaping (Bool) -> Void) {
        isGenerating = true
        showGenerationProgress = true
        generationProgress = 0.1
        
        // Prepare context from conversation
        let context = conversation.messages.map { msg in
            return "\(msg.isFromUser ? "Student" : "Drona"): \(msg.content)"
        }.joined(separator: "\n")
        
        // Create a prompt for flashcard generation
        let prompt = """
        Based on the following conversation, generate \(count) flashcards in a question and answer format.
        Focus on the main concepts, definitions, and key points discussed.
        
        Format each flashcard as JSON objects with the following structure:
        {"question": "question text here", "answer": "concise answer here", "category": "subject category"}
        
        Return ONLY the JSON array with the flashcards, no other text.
        
        Conversation:
        \(context)
        """
        
        generationProgress = 0.3
        
        // Ask Gemini to generate flashcards
        geminiService.askQuestion(question: prompt, userProfile: nil, context: "") { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.generationProgress = 0.6
                
                switch result {
                case .success(let response):
                    self.processFlashcardResponse(response, conversation: conversation)
                    self.generationProgress = 1.0
                    
                    // Delay to show completion before hiding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isGenerating = false
                        self.showGenerationProgress = false
                        completion(true)
                    }
                    
                case .failure(_):
                    self.isGenerating = false
                    self.showGenerationProgress = false
                    completion(false)
                }
            }
        }
    }
    
    private func processFlashcardResponse(_ response: String, conversation: Conversation) {
        // Try to parse the response as JSON
        if let jsonData = extractJsonArray(from: response).data(using: .utf8) {
            do {
                let parsedCards = try JSONDecoder().decode([FlashcardData].self, from: jsonData)
                
                // Convert the parsed data to Flashcard objects
                let newCards = parsedCards.map { cardData in
                    return Flashcard(
                        question: cardData.question,
                        answer: cardData.answer,
                        category: cardData.category,
                        fromConversationID: conversation.id,
                        color: randomCardColor()
                    )
                }
                
                // Add the new cards
                self.flashcards.append(contentsOf: newCards)
                
                // Update categories
                for card in newCards {
                    self.categories.insert(card.category)
                }
                
                // Save changes
                self.saveFlashcards()
                self.saveCategories()
                
            } catch {
                print("Error parsing flashcard data: \(error.localizedDescription)")
                // Try alternative parsing method if JSON parsing fails
                extractFlashcardsWithNLP(from: response, conversation: conversation)
            }
        } else {
            // If JSON extraction failed, try NLP-based extraction
            extractFlashcardsWithNLP(from: response, conversation: conversation)
        }
    }
    
    // Extract JSON array from text that might contain additional content
    private func extractJsonArray(from text: String) -> String {
        // Try to find a JSON array in the text
        if let startIndex = text.firstIndex(of: "["),
           let endIndex = text.lastIndex(of: "]") {
            return String(text[startIndex...endIndex])
        }
        
        // Try to find individual JSON objects if no array is present
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return "[\(String(text[startIndex...endIndex]))]"
        }
        
        return "[]"
    }
    
    // Fallback method to extract flashcards using NLP if JSON parsing fails
    private func extractFlashcardsWithNLP(from text: String, conversation: Conversation) {
        // Split text by lines or potential question markers
        let lines = text.components(separatedBy: .newlines)
        
        var currentQuestion = ""
        var currentAnswer = ""
        var flashcardsExtracted = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            // Check if line starts with Q:, Question:, or contains a question mark
            if trimmedLine.starts(with: "Q:") || 
               trimmedLine.starts(with: "Question:") || 
               (trimmedLine.contains("?") && currentQuestion.isEmpty) {
                
                // If we already have a question and answer, save the flashcard
                if !currentQuestion.isEmpty && !currentAnswer.isEmpty {
                    createFlashcardFromExtracted(
                        question: currentQuestion,
                        answer: currentAnswer,
                        conversationID: conversation.id
                    )
                    flashcardsExtracted += 1
                    currentQuestion = ""
                    currentAnswer = ""
                }
                
                // Set the new question
                currentQuestion = trimmedLine
                    .replacingOccurrences(of: "Q:", with: "")
                    .replacingOccurrences(of: "Question:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
            } else if trimmedLine.starts(with: "A:") || 
                      trimmedLine.starts(with: "Answer:") ||
                      (!currentQuestion.isEmpty && currentAnswer.isEmpty) {
                
                // Set the answer
                currentAnswer = trimmedLine
                    .replacingOccurrences(of: "A:", with: "")
                    .replacingOccurrences(of: "Answer:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If we have both question and answer, save the flashcard
                if !currentQuestion.isEmpty && !currentAnswer.isEmpty {
                    createFlashcardFromExtracted(
                        question: currentQuestion,
                        answer: currentAnswer,
                        conversationID: conversation.id
                    )
                    flashcardsExtracted += 1
                    currentQuestion = ""
                    currentAnswer = ""
                }
            }
        }
        
        // Save any remaining question-answer pair
        if !currentQuestion.isEmpty && !currentAnswer.isEmpty {
            createFlashcardFromExtracted(
                question: currentQuestion,
                answer: currentAnswer,
                conversationID: conversation.id
            )
        }
    }
    
    private func createFlashcardFromExtracted(question: String, answer: String, conversationID: UUID) {
        // Derive category from question content using NLP
        let category = deriveCategory(from: question)
        
        let newCard = Flashcard(
            question: question,
            answer: answer,
            category: category,
            fromConversationID: conversationID,
            color: randomCardColor()
        )
        
        self.flashcards.append(newCard)
        self.categories.insert(category)
        
        // Save changes
        self.saveFlashcards()
        self.saveCategories()
    }
    
    // Use NLP to derive a category from the question content
    private func deriveCategory(from question: String) -> String {
        // Default categories based on common subjects
        let defaultCategories = ["Mathematics", "Science", "History", "Literature", "Computer Science", "General Knowledge"]
        
        // Check for keywords in the question
        let lowercaseQuestion = question.lowercased()
        
        if lowercaseQuestion.contains("math") || 
           lowercaseQuestion.contains("equation") || 
           lowercaseQuestion.contains("calculation") ||
           lowercaseQuestion.contains("number") ||
           lowercaseQuestion.contains("formula") {
            return "Mathematics"
        } else if lowercaseQuestion.contains("science") || 
                  lowercaseQuestion.contains("chemistry") || 
                  lowercaseQuestion.contains("physics") ||
                  lowercaseQuestion.contains("biology") ||
                  lowercaseQuestion.contains("experiment") {
            return "Science"
        } else if lowercaseQuestion.contains("history") || 
                  lowercaseQuestion.contains("century") || 
                  lowercaseQuestion.contains("ancient") ||
                  lowercaseQuestion.contains("war") ||
                  lowercaseQuestion.contains("king") ||
                  lowercaseQuestion.contains("queen") {
            return "History"
        } else if lowercaseQuestion.contains("literature") || 
                  lowercaseQuestion.contains("book") || 
                  lowercaseQuestion.contains("author") ||
                  lowercaseQuestion.contains("novel") ||
                  lowercaseQuestion.contains("poem") {
            return "Literature"
        } else if lowercaseQuestion.contains("computer") || 
                  lowercaseQuestion.contains("programming") || 
                  lowercaseQuestion.contains("code") ||
                  lowercaseQuestion.contains("software") ||
                  lowercaseQuestion.contains("algorithm") {
            return "Computer Science"
        }
        
        // If no keywords match, return a default category
        return defaultCategories.randomElement() ?? "General Knowledge"
    }
    
    private func randomCardColor() -> Flashcard.CardColor {
        let colors = Flashcard.CardColor.allCases
        return colors.randomElement() ?? .blue
    }
    
    // MARK: - Querying Cards
    
    func getCardsForCategory(_ category: String) -> [Flashcard] {
        return flashcards.filter { $0.category == category }
    }
    
    func getStarredCards() -> [Flashcard] {
        return flashcards.filter { $0.starred }
    }
    
    func getDueCards() -> [Flashcard] {
        let now = Date()
        return flashcards.filter { $0.dueDate <= now }
    }
    
    func getMarkedCards() -> [Flashcard] {
        return flashcards.filter { $0.markedForLater }
    }
    
    func getRecentlyAdded(limit: Int = 10) -> [Flashcard] {
        return flashcards.sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Data Persistence
    
    private func saveFlashcards() {
        if let encoded = try? JSONEncoder().encode(flashcards) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadFlashcards() {
        if let savedFlashcards = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedFlashcards = try? JSONDecoder().decode([Flashcard].self, from: savedFlashcards) {
                flashcards = decodedFlashcards
                return
            }
        }
        flashcards = []
    }
    
    private func saveCategories() {
        UserDefaults.standard.set(Array(categories), forKey: categoriesKey)
    }
    
    private func loadCategories() {
        if let savedCategories = UserDefaults.standard.stringArray(forKey: categoriesKey) {
            categories = Set(savedCategories)
            return
        }
        categories = []
    }
    
    private func updateCategories() {
        // Extract all categories from flashcards
        let updatedCategories = Set(flashcards.map { $0.category })
        
        // Update the categories set
        categories = updatedCategories
        saveCategories()
    }
    
    // Public method to manually save categories - called from ManageCategoriesView
    func saveCategoryChanges() {
        saveCategories()
    }
    
    // Mark or unmark a card for later review
    func toggleMarkForLater(for card: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == card.id }) {
            var updatedCard = card
            updatedCard.markedForLater.toggle()
            flashcards[index] = updatedCard
            saveFlashcards()
        }
    }
    
    // Update card with a specific rating (SM-2 algorithm)
    func updateCard(for card: Flashcard, withRating rating: Flashcard.ReviewEntry.Rating, timeTaken: TimeInterval? = nil) {
        if let index = flashcards.firstIndex(where: { $0.id == card.id }) {
            var updatedCard = card
            updatedCard.updateWithRating(rating, timeTaken: timeTaken)
            flashcards[index] = updatedCard
            saveFlashcards()
        }
    }
    
    // Get cards with a specific confidence level
    func getCardsByConfidence(level: Int) -> [Flashcard] {
        return flashcards.filter { $0.confidence == level }
    }
    
    // Get detailed review statistics
    func getReviewStatistics() -> ReviewStatistics {
        let totalCards = flashcards.count
        let dueCards = getDueCards().count
        let masteredCards = getCardsByConfidence(level: 5).count
        let difficultCards = getCardsByConfidence(level: 1).count
        let averageEase = flashcards.isEmpty ? 2.5 : flashcards.reduce(0.0) { $0 + $1.easeFactor } / Double(totalCards)
        
        return ReviewStatistics(
            totalCards: totalCards,
            dueCards: dueCards,
            masteredCards: masteredCards,
            difficultCards: difficultCards,
            averageEase: averageEase
        )
    }
    
    // Statistics structure for review data
    struct ReviewStatistics {
        let totalCards: Int
        let dueCards: Int
        let masteredCards: Int
        let difficultCards: Int
        let averageEase: Double
        
        var masteredPercentage: Double {
            totalCards > 0 ? Double(masteredCards) / Double(totalCards) * 100.0 : 0.0
        }
        
        var difficultPercentage: Double {
            totalCards > 0 ? Double(difficultCards) / Double(totalCards) * 100.0 : 0.0
        }
    }
}

// Helper struct for JSON decoding
private struct FlashcardData: Codable {
    let question: String
    let answer: String
    let category: String
} 