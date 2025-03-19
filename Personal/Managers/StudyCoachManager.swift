//
//  StudyCoachManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import Foundation
import SwiftUI
import Combine

class StudyCoachManager: ObservableObject {
    @Published var coaches: [StudyCoach] = []
    @Published var activeCoach: StudyCoach?
    @Published var isGeneratingResponse = false
    @Published var currentInteraction: StudyCoach.CoachInteraction?
    @Published var studyInsights: [StudyCoach.CoachInsight] = []
    @Published var studyPlans: [StudyCoach.StudyPlan] = []
    @Published var recommendedTasks: [StudyCoach.StudyPlan.StudyTask] = []
    @Published var streakDays = 0
    
    private let userDefaultsKey = "dronaStudyCoaches"
    private let activeCoachKey = "dronaActiveCoach"
    private let insightsKey = "dronaStudyInsights"
    private let plansKey = "dronaStudyPlans"
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    private let geminiService = GeminiService()
    private let userProfileManager = UserProfileManager()
    private let flashcardManager = FlashcardManager.shared
    private let conversationManager = ConversationManager.shared
    
    // Singleton instance
    static let shared = StudyCoachManager()
    
    init() {
        loadCoaches()
        loadActiveCoach()
        loadInsights()
        loadStudyPlans()
        
        // Create default coach if no coaches exist
        if coaches.isEmpty {
            createDefaultCoach()
        }
        
        subscribeToUpdates()
    }
    
    // MARK: - Coach Management
    
    func createDefaultCoach() {
        let defaultCoach = StudyCoach.createDefault()
        coaches.append(defaultCoach)
        activeCoach = defaultCoach
        saveCoaches()
        saveActiveCoach()
    }
    
    func customizeCoach(name: String, specialty: StudyCoach.CoachSpecialty, personality: StudyCoach.CoachPersonality, avatar: StudyCoach.CoachAvatar) {
        let newCoach = StudyCoach.createDefault(
            name: name,
            specialty: specialty,
            personality: personality,
            avatar: avatar
        )
        
        coaches.append(newCoach)
        activeCoach = newCoach
        saveCoaches()
        saveActiveCoach()
    }
    
    func setActiveCoach(_ coach: StudyCoach) {
        activeCoach = coach
        saveActiveCoach()
    }
    
    // MARK: - AI Interaction
    
    func startInteraction(topic: String, initialMessage: String? = nil) {
        guard var coach = activeCoach else { return }
        
        let now = Date()
        var messages: [StudyCoach.CoachInteraction.CoachMessage] = []
        
        // If there's an initial message from the user, add it
        if let initialMessage = initialMessage {
            let userMessage = StudyCoach.CoachInteraction.CoachMessage(
                content: initialMessage,
                isFromCoach: false,
                timestamp: now,
                messageType: .text
            )
            messages.append(userMessage)
        }
        
        // Create a new interaction
        let interaction = StudyCoach.CoachInteraction(
            date: now,
            messages: messages,
            topic: topic,
            resultedInAction: false
        )
        
        // Update the coach
        coach.lastInteraction = now
        coach.updateStreak()
        coach.interactions.append(interaction)
        streakDays = coach.streakDays
        
        // Save changes
        self.activeCoach = coach
        self.currentInteraction = interaction
        updateCoach(coach)
        
        // Generate an AI response if there was an initial message
        if initialMessage != nil {
            generateAIResponse(to: initialMessage!)
        }
    }
    
    func sendMessage(_ content: String, messageType: StudyCoach.CoachInteraction.CoachMessage.MessageType = .text) {
        guard var coach = activeCoach, var interaction = currentInteraction else { return }
        
        // Create the user message
        let userMessage = StudyCoach.CoachInteraction.CoachMessage(
            content: content,
            isFromCoach: false,
            timestamp: Date(),
            messageType: messageType
        )
        
        // Add to the interaction
        interaction.messages.append(userMessage)
        self.currentInteraction = interaction
        
        // Update the coach's interaction
        if let index = coach.interactions.firstIndex(where: { $0.id == interaction.id }) {
            coach.interactions[index] = interaction
            updateCoach(coach)
        }
        
        // Generate an AI response
        generateAIResponse(to: content)
    }
    
    private func generateAIResponse(to message: String) {
        guard let coach = activeCoach, let interaction = currentInteraction else { return }
        
        isGeneratingResponse = true
        
        // Build context for the AI
        let coachContext = """
        You are \(coach.name), a study coach with expertise in \(coach.specialty.rawValue) and a \(coach.personality.rawValue) personality.
        Your coaching style is: \(coach.personality.coachingStyle)
        
        The user's streak is: \(coach.streakDays) days
        Relationship level with user: \(coach.relationshipLevel)/5
        
        You're helping the user with: \(interaction.topic)
        
        Your responses should reflect your specialty and personality. Be concise but helpful.
        
        Coaching goal: Help the user develop effective study habits, provide learning insights, and create personalized study plans.
        """
        
        let userProfile = userProfileManager.userProfile
        let userProfileContext = userProfile != nil ? """
        User profile:
        Name: \(userProfile!.name)
        Age: \(userProfile!.age)
        Education: \(userProfile!.educationLevel.rawValue)
        Interests: \(userProfile!.interests.map { $0.rawValue }.joined(separator: ", "))
        Preferred topics: \(userProfile!.preferredTopics.map { $0.rawValue }.joined(separator: ", "))
        """ : "No user profile available."
        
        let conversationHistory = interaction.messages.map { msg in
            return "\(msg.isFromCoach ? "\(coach.name)" : "User"): \(msg.content)"
        }.joined(separator: "\n")
        
        // Combine all context
        let fullContext = "\(coachContext)\n\n\(userProfileContext)\n\nConversation history:\n\(conversationHistory)"
        
        // Call Gemini API
        geminiService.askQuestion(question: message, userProfile: nil, context: fullContext) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isGeneratingResponse = false
                
                switch result {
                case .success(let aiResponse):
                    self.processAIResponse(aiResponse)
                case .failure(let error):
                    self.handleAIError(error)
                }
            }
        }
    }
    
    private func processAIResponse(_ response: String) {
        guard var coach = activeCoach, var interaction = currentInteraction else { return }
        
        // Create the coach message
        let coachMessage = StudyCoach.CoachInteraction.CoachMessage(
            content: response,
            isFromCoach: true,
            timestamp: Date(),
            messageType: determineMessageType(from: response)
        )
        
        // Add to the interaction
        interaction.messages.append(coachMessage)
        currentInteraction = interaction
        
        // Update the coach's interaction
        if let index = coach.interactions.firstIndex(where: { $0.id == interaction.id }) {
            coach.interactions[index] = interaction
            updateCoach(coach)
        }
        
        // Check if this response contains actionable insights
        extractInsightsFromResponse(response)
    }
    
    private func handleAIError(_ error: Error) {
        guard var coach = activeCoach, var interaction = currentInteraction else { return }
        
        // Create a fallback message
        let fallbackMessage = StudyCoach.CoachInteraction.CoachMessage(
            content: "I'm having trouble connecting right now. Let's try again in a moment.",
            isFromCoach: true,
            timestamp: Date(),
            messageType: .text
        )
        
        // Add to the interaction
        interaction.messages.append(fallbackMessage)
        currentInteraction = interaction
        
        // Update the coach's interaction
        if let index = coach.interactions.firstIndex(where: { $0.id == interaction.id }) {
            coach.interactions[index] = interaction
            updateCoach(coach)
        }
    }
    
    // MARK: - Insight Generation
    
    func generateStudyInsight(from source: StudyCoach.CoachInsight.InsightSource) {
        guard let coach = activeCoach else { return }
        
        // Determine what data to analyze based on source
        let analysisPrompt: String
        
        switch source {
        case .flashcards:
            let totalCards = flashcardManager.flashcards.count
            let masteredCards = flashcardManager.getCardsByConfidence(level: 5).count
            let difficultCards = flashcardManager.getCardsByConfidence(level: 1).count
            let categories = Array(flashcardManager.categories)
            
            analysisPrompt = """
            Based on flashcard data:
            Total cards: \(totalCards)
            Mastered cards: \(masteredCards)
            Difficult cards: \(difficultCards)
            Categories: \(categories.joined(separator: ", "))
            
            Generate ONE actionable learning insight about the user's flashcard study patterns.
            Format as JSON: {"title": "Brief insight title", "description": "Detailed insight", "category": "pattern/strength/challenge/improvement/recommendation/milestone", "isActionable": true/false, "relatedAction": "suggestion if actionable"}
            """
            
        case .conversations:
            let totalConversations = conversationManager.conversations.count
            let recentTopics = conversationManager.conversations.prefix(5).map { $0.category.rawValue }
            
            analysisPrompt = """
            Based on conversation data:
            Total conversations: \(totalConversations)
            Recent topics: \(recentTopics.joined(separator: ", "))
            
            Generate ONE actionable learning insight about the user's topics of interest and question patterns.
            Format as JSON: {"title": "Brief insight title", "description": "Detailed insight", "category": "pattern/strength/challenge/improvement/recommendation/milestone", "isActionable": true/false, "relatedAction": "suggestion if actionable"}
            """
            
        case .studyTime:
            // For demonstration, we'll use placeholder data
            analysisPrompt = """
            Based on study habits:
            Average study time: 45 minutes per session
            Most productive time: Evenings
            Consistency: Moderate
            
            Generate ONE actionable learning insight about the user's study habits.
            Format as JSON: {"title": "Brief insight title", "description": "Detailed insight", "category": "pattern/strength/challenge/improvement/recommendation/milestone", "isActionable": true/false, "relatedAction": "suggestion if actionable"}
            """
            
        default:
            analysisPrompt = """
            Generate ONE general learning insight that would be helpful for a student.
            Format as JSON: {"title": "Brief insight title", "description": "Detailed insight", "category": "pattern/strength/challenge/improvement/recommendation/milestone", "isActionable": true/false, "relatedAction": "suggestion if actionable"}
            """
        }
        
        // Build context for the AI
        let coachContext = """
        You are \(coach.name), a study coach with expertise in \(coach.specialty.rawValue).
        Your task is to analyze learning data and generate an insightful observation.
        """
        
        let fullContext = "\(coachContext)\n\n\(analysisPrompt)"
        
        // Call Gemini API
        geminiService.askQuestion(question: "Generate a learning insight", userProfile: nil, context: fullContext) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let aiResponse):
                    self.extractInsightFromAIResponse(aiResponse, source: source)
                case .failure:
                    // Handle error silently for background insight generation
                    break
                }
            }
        }
    }
    
    private func extractInsightFromAIResponse(_ response: String, source: StudyCoach.CoachInsight.InsightSource) {
        // Extract JSON from response
        guard let jsonData = extractJSONFromString(response)?.data(using: .utf8),
              let insightData = try? JSONDecoder().decode(InsightDTO.self, from: jsonData) else {
            return
        }
        
        // Create insight from parsed data
        let insight = StudyCoach.CoachInsight(
            id: UUID(),
            title: insightData.title,
            description: insightData.description,
            category: parseInsightType(insightData.category),
            createdDate: Date(),
            source: source,
            isActionable: insightData.isActionable,
            relatedAction: insightData.relatedAction
        )
        
        // Add to insights and save
        self.studyInsights.append(insight)
        saveInsights()
    }
    
    // MARK: - Study Plan Generation
    
    func generateStudyPlan(for subject: String, difficulty: Int, deadline: Date?) {
        guard let coach = activeCoach else { return }
        
        let userProfile = userProfileManager.userProfile
        let userProfileContext = userProfile != nil ? """
        User profile:
        Name: \(userProfile!.name)
        Age: \(userProfile!.age)
        Education: \(userProfile!.educationLevel.rawValue)
        Interests: \(userProfile!.interests.map { $0.rawValue }.joined(separator: ", "))
        """ : "No user profile available."
        
        // Calculate days until deadline
        let daysUntilDeadline = deadline != nil ? 
            Calendar.current.dateComponents([.day], from: Date(), to: deadline!).day ?? 14 : 14
        
        let planPrompt = """
        Create a study plan for the subject: \(subject)
        Difficulty level (1-5): \(difficulty)
        Days available: \(daysUntilDeadline)
        
        Format the plan as JSON:
        {
          "title": "Study Plan Title",
          "description": "Brief description of the plan",
          "tasks": [
            {
              "title": "Task Title",
              "description": "Detailed description",
              "estimatedMinutes": 30
            },
            // more tasks
          ]
        }
        
        The plan should have 3-5 tasks that are specific, measurable, and appropriate for the difficulty level.
        """
        
        // Build context for the AI
        let coachContext = """
        You are \(coach.name), a study coach with expertise in \(coach.specialty.rawValue).
        Your task is to create a personalized study plan for the user.
        """
        
        let fullContext = "\(coachContext)\n\n\(userProfileContext)\n\n\(planPrompt)"
        
        // Call Gemini API
        geminiService.askQuestion(question: "Generate a study plan", userProfile: nil, context: fullContext) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let aiResponse):
                    self.processPlanFromAIResponse(aiResponse, subject: subject, difficulty: difficulty, deadline: deadline)
                case .failure:
                    // Handle error with a default plan
                    self.createDefaultPlan(for: subject, difficulty: difficulty, deadline: deadline)
                }
            }
        }
    }
    
    private func processPlanFromAIResponse(_ response: String, subject: String, difficulty: Int, deadline: Date?) {
        // Extract JSON from response
        guard let jsonData = extractJSONFromString(response)?.data(using: .utf8),
              let planData = try? JSONDecoder().decode(StudyPlanDTO.self, from: jsonData) else {
            // Fallback to default plan if parsing fails
            createDefaultPlan(for: subject, difficulty: difficulty, deadline: deadline)
            return
        }
        
        // Create tasks from parsed data
        let tasks = planData.tasks.map { taskDTO in
            return StudyCoach.StudyPlan.StudyTask(
                id: UUID(),
                title: taskDTO.title,
                description: taskDTO.description,
                estimatedMinutes: taskDTO.estimatedMinutes
            )
        }
        
        // Create the plan
        let plan = StudyCoach.StudyPlan(
            id: UUID(),
            title: planData.title,
            description: planData.description,
            createdDate: Date(),
            targetDate: deadline,
            tasks: tasks,
            category: subject,
            difficulty: difficulty
        )
        
        // Add to plans and save
        self.studyPlans.append(plan)
        saveStudyPlans()
    }
    
    func createDefaultPlan(for subject: String, difficulty: Int, deadline: Date?) {
        // Create a simple default plan
        let defaultTasks = [
            StudyCoach.StudyPlan.StudyTask(
                id: UUID(),
                title: "Review key concepts",
                description: "Go through the main ideas and principles of \(subject)",
                estimatedMinutes: 30
            ),
            StudyCoach.StudyPlan.StudyTask(
                id: UUID(),
                title: "Practice problems",
                description: "Solve example problems to reinforce understanding",
                estimatedMinutes: 45
            ),
            StudyCoach.StudyPlan.StudyTask(
                id: UUID(),
                title: "Create summary notes",
                description: "Make concise notes highlighting the most important points",
                estimatedMinutes: 30
            )
        ]
        
        let plan = StudyCoach.StudyPlan(
            id: UUID(),
            title: "Study Plan for \(subject)",
            description: "A structured approach to mastering \(subject)",
            createdDate: Date(),
            targetDate: deadline,
            tasks: defaultTasks,
            category: subject,
            difficulty: difficulty
        )
        
        // Add to plans and save
        self.studyPlans.append(plan)
        saveStudyPlans()
    }
    
    // MARK: - Plan Management
    
    func updateStudyPlan(_ plan: StudyCoach.StudyPlan) {
        if let index = studyPlans.firstIndex(where: { $0.id == plan.id }) {
            studyPlans[index] = plan
            saveStudyPlans()
        }
    }
    
    func completeTask(planId: UUID, taskId: UUID, timeSpent: Int? = nil) {
        if let planIndex = studyPlans.firstIndex(where: { $0.id == planId }),
           let taskIndex = studyPlans[planIndex].tasks.firstIndex(where: { $0.id == taskId }) {
            
            // Mark task as completed
            var updatedTask = studyPlans[planIndex].tasks[taskIndex]
            updatedTask.isCompleted = true
            updatedTask.actualMinutes = timeSpent
            studyPlans[planIndex].tasks[taskIndex] = updatedTask
            
            // Update plan progress
            let totalTasks = studyPlans[planIndex].tasks.count
            let completedTasks = studyPlans[planIndex].tasks.filter { $0.isCompleted }.count
            studyPlans[planIndex].progress = Double(completedTasks) / Double(totalTasks)
            
            // Check if plan is complete
            if studyPlans[planIndex].progress >= 1.0 {
                studyPlans[planIndex].isCompleted = true
            }
            
            saveStudyPlans()
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineMessageType(from message: String) -> StudyCoach.CoachInteraction.CoachMessage.MessageType {
        // Simple heuristics to determine message type
        if message.contains("?") {
            return .question
        } else if message.contains("recommend") || message.contains("suggest") {
            return .suggestion
        } else if message.contains("plan") || message.contains("schedule") {
            return .plan
        } else if message.contains("great job") || message.contains("well done") || message.contains("proud") {
            return .encouragement
        } else if message.contains("insight") || message.contains("notice") || message.contains("pattern") {
            return .insight
        } else if message.contains("task") || message.contains("homework") || message.contains("assignment") {
            return .task
        } else {
            return .text
        }
    }
    
    private func extractInsightsFromResponse(_ response: String) {
        // Check if the response mentions a study insight
        if response.lowercased().contains("insight") || response.lowercased().contains("pattern") || response.lowercased().contains("noticed") {
            // Randomly select a source for the insight
            let sources: [StudyCoach.CoachInsight.InsightSource] = [
                .flashcards, .conversations, .studyTime, .performance, .userInput
            ]
            
            if let randomSource = sources.randomElement() {
                generateStudyInsight(from: randomSource)
            }
        }
    }
    
    private func extractJSONFromString(_ text: String) -> String? {
        let jsonPattern = "\\{[^\\{\\}]*((\\{[^\\{\\}]*\\})[^\\{\\}]*)*\\}"
        
        if let regex = try? NSRegularExpression(pattern: jsonPattern, options: []) {
            let nsString = text as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                return nsString.substring(with: match.range)
            }
        }
        
        return nil
    }
    
    private func parseInsightType(_ typeString: String) -> StudyCoach.CoachInsight.InsightType {
        switch typeString.lowercased() {
        case "pattern", "learning pattern":
            return .pattern
        case "strength":
            return .strength
        case "challenge":
            return .challenge
        case "improvement", "improvement area":
            return .improvement
        case "recommendation":
            return .recommendation
        case "milestone":
            return .milestone
        default:
            return .recommendation
        }
    }
    
    // MARK: - Data Persistence
    
    private func updateCoach(_ coach: StudyCoach) {
        if let index = coaches.firstIndex(where: { $0.id == coach.id }) {
            coaches[index] = coach
            if activeCoach?.id == coach.id {
                activeCoach = coach
            }
            saveCoaches()
            saveActiveCoach()
        }
    }
    
    private func loadCoaches() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedCoaches = try? JSONDecoder().decode([StudyCoach].self, from: data) {
                coaches = decodedCoaches
            }
        }
    }
    
    private func saveCoaches() {
        if let encoded = try? JSONEncoder().encode(coaches) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadActiveCoach() {
        if let data = UserDefaults.standard.data(forKey: activeCoachKey) {
            if let decodedCoach = try? JSONDecoder().decode(StudyCoach.self, from: data) {
                activeCoach = decodedCoach
                streakDays = decodedCoach.streakDays
            }
        }
    }
    
    private func saveActiveCoach() {
        if let coach = activeCoach, let encoded = try? JSONEncoder().encode(coach) {
            UserDefaults.standard.set(encoded, forKey: activeCoachKey)
        }
    }
    
    private func loadInsights() {
        if let data = UserDefaults.standard.data(forKey: insightsKey) {
            if let decodedInsights = try? JSONDecoder().decode([StudyCoach.CoachInsight].self, from: data) {
                studyInsights = decodedInsights
            }
        }
    }
    
    private func saveInsights() {
        if let encoded = try? JSONEncoder().encode(studyInsights) {
            UserDefaults.standard.set(encoded, forKey: insightsKey)
        }
    }
    
    private func loadStudyPlans() {
        if let data = UserDefaults.standard.data(forKey: plansKey) {
            if let decodedPlans = try? JSONDecoder().decode([StudyCoach.StudyPlan].self, from: data) {
                studyPlans = decodedPlans
            }
        }
    }
    
    private func saveStudyPlans() {
        if let encoded = try? JSONEncoder().encode(studyPlans) {
            UserDefaults.standard.set(encoded, forKey: plansKey)
        }
    }
    
    private func subscribeToUpdates() {
        // Watch for changes that might require updating the coach
        NotificationCenter.default.publisher(for: .flashcardDataUpdated)
            .sink { [weak self] _ in
                self?.analyzeFlashcardData()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeFlashcardData() {
        // Maybe generate insights based on flashcard changes
        if Int.random(in: 1...10) <= 3 { // 30% chance
            generateStudyInsight(from: .flashcards)
        }
    }
}

// Data Transfer Objects for parsing AI responses
struct InsightDTO: Codable {
    let title: String
    let description: String
    let category: String
    let isActionable: Bool
    let relatedAction: String?
}

struct StudyPlanDTO: Codable {
    let title: String
    let description: String
    let tasks: [TaskDTO]
    
    struct TaskDTO: Codable {
        let title: String
        let description: String
        let estimatedMinutes: Int
    }
}

// Notifications
extension Notification.Name {
    static let flashcardDataUpdated = Notification.Name("flashcardDataUpdated")
} 