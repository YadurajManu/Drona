//
//  ConversationManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import Foundation
import SwiftUI

class ConversationManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    private let geminiService = GeminiService()
    
    private let userDefaultsKey = "dronaConversations"
    
    init() {
        loadConversations()
    }
    
    func startNewConversation(title: String, category: UserProfile.DoubtCategory, initialQuestion: String, userProfile: UserProfile?, completion: @escaping (Bool) -> Void) {
        let newConversation = Conversation.createNew(title: title, category: category, initialQuestion: initialQuestion)
        currentConversation = newConversation
        
        // Get AI response to the initial question
        getResponseForMessage(message: initialQuestion, in: newConversation, userProfile: userProfile) { [weak self] success in
            if success {
                self?.conversations.insert(newConversation, at: 0)
                self?.saveConversations()
            }
            completion(success)
        }
    }
    
    func sendMessage(content: String, userProfile: UserProfile?, completion: @escaping (Bool) -> Void) {
        guard var conversation = currentConversation else {
            completion(false)
            return
        }
        
        let userMessage = Message.createUserMessage(content)
        conversation.messages.append(userMessage)
        conversation.lastUpdated = Date()
        currentConversation = conversation
        
        // Update the conversation in the array
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }
        
        // Get AI response
        getResponseForMessage(message: content, in: conversation, userProfile: userProfile) { [weak self] success in
            self?.saveConversations()
            completion(success)
        }
    }
    
    private func getResponseForMessage(message: String, in conversation: Conversation, userProfile: UserProfile?, completion: @escaping (Bool) -> Void) {
        // Prepare context from previous messages (limited to last few)
        let recentMessages = conversation.messages.suffix(5)
        let context = recentMessages.map { msg in
            return "\(msg.isFromUser ? "Student" : "Drona"): \(msg.content)"
        }.joined(separator: "\n")
        
        // Get response from Gemini
        geminiService.askQuestion(
            question: message,
            userProfile: userProfile,
            context: "Conversation category: \(conversation.category.rawValue)\nRecent conversation:\n\(context)"
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Add AI response to the conversation
                    guard var updatedConversation = self?.currentConversation else {
                        completion(false)
                        return
                    }
                    
                    let aiMessage = Message.createDronaMessage(response)
                    updatedConversation.messages.append(aiMessage)
                    updatedConversation.lastUpdated = Date()
                    self?.currentConversation = updatedConversation
                    
                    // Update the conversation in the array
                    if let index = self?.conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
                        self?.conversations[index] = updatedConversation
                    }
                    
                    completion(true)
                    
                case .failure(let error):
                    print("Error getting response: \(error.localizedDescription)")
                    
                    // Add error message
                    guard var updatedConversation = self?.currentConversation else {
                        completion(false)
                        return
                    }
                    
                    let errorMessage = Message.createDronaMessage("Sorry, I encountered an error while processing your request. Please try again.")
                    updatedConversation.messages.append(errorMessage)
                    updatedConversation.lastUpdated = Date()
                    self?.currentConversation = updatedConversation
                    
                    // Update the conversation in the array
                    if let index = self?.conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
                        self?.conversations[index] = updatedConversation
                    }
                    
                    completion(false)
                }
            }
        }
    }
    
    func selectConversation(_ conversation: Conversation) {
        currentConversation = conversation
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll(where: { $0.id == conversation.id })
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
        saveConversations()
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadConversations() {
        if let savedConversations = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedConversations = try? JSONDecoder().decode([Conversation].self, from: savedConversations) {
                conversations = decodedConversations
                return
            }
        }
        conversations = []
    }
    
    func clearAllConversations() {
        // Clear conversations array
        conversations = []
        currentConversation = nil
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // Create a singleton instance for global access
    static let shared = ConversationManager()
} 