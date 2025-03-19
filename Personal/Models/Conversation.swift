//
//  Conversation.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import Foundation

struct Conversation: Identifiable, Codable {
    var id = UUID()
    var title: String
    var category: UserProfile.DoubtCategory
    var messages: [Message]
    var dateCreated: Date
    var lastUpdated: Date
    
    static func createNew(title: String, category: UserProfile.DoubtCategory, initialQuestion: String) -> Conversation {
        let now = Date()
        return Conversation(
            title: title,
            category: category,
            messages: [
                Message(content: initialQuestion, isFromUser: true, timestamp: now)
            ],
            dateCreated: now,
            lastUpdated: now
        )
    }
}

struct Message: Identifiable, Codable {
    var id = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    
    static func createUserMessage(_ content: String) -> Message {
        Message(content: content, isFromUser: true, timestamp: Date())
    }
    
    static func createDronaMessage(_ content: String) -> Message {
        Message(content: content, isFromUser: false, timestamp: Date())
    }
} 