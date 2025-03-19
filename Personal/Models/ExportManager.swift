//
//  ExportManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class ExportManager {
    static let shared = ExportManager()
    
    enum ExportFormat {
        case pdf
        case json
        case text
    }
    
    enum ExportContent {
        case profile
        case conversations
        case allData
    }
    
    // Generate export data for user profile
    func exportUserData(format: ExportFormat, content: ExportContent, completion: @escaping (URL?) -> Void) {
        switch format {
        case .pdf:
            exportAsPDF(content: content, completion: completion)
        case .json:
            exportAsJSON(content: content, completion: completion)
        case .text:
            exportAsText(content: content, completion: completion)
        }
    }
    
    // PDF Export
    private func exportAsPDF(content: ExportContent, completion: @escaping (URL?) -> Void) {
        // Create PDF document
        let pdfDocument = PDFDocument()
        
        // Get data based on content type
        switch content {
        case .profile:
            addProfilePagesToPDF(pdfDocument)
        case .conversations:
            addConversationPagesToPDF(pdfDocument)
        case .allData:
            addProfilePagesToPDF(pdfDocument)
            addConversationPagesToPDF(pdfDocument)
        }
        
        // Save to file
        let fileName = "Drona_Export_\(formattedDate()).pdf"
        saveToFile(data: pdfDocument.dataRepresentation() ?? Data(), fileName: fileName, utType: UTType.pdf, completion: completion)
    }
    
    private func addProfilePagesToPDF(_ pdfDocument: PDFDocument) {
        guard let profile = UserProfileManager.shared.userProfile else { return }
        
        // Create PDF page
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Draw header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            "Drona User Profile".draw(
                at: CGPoint(x: 50, y: 50),
                withAttributes: headerAttributes
            )
            
            "Export Date: \(formattedDate())".draw(
                at: CGPoint(x: 50, y: 90),
                withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
            )
            
            // Line separator
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 110))
            path.addLine(to: CGPoint(x: 562, y: 110))
            path.lineWidth = 1
            UIColor.gray.setStroke()
            path.stroke()
            
            // Profile data
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            
            // Basic Info
            "Basic Information".draw(
                at: CGPoint(x: 50, y: 140),
                withAttributes: titleAttributes
            )
            
            "Name: \(profile.name)".draw(
                at: CGPoint(x: 70, y: 170),
                withAttributes: textAttributes
            )
            
            "Age: \(profile.age)".draw(
                at: CGPoint(x: 70, y: 195),
                withAttributes: textAttributes
            )
            
            "Education Level: \(profile.educationLevel.rawValue)".draw(
                at: CGPoint(x: 70, y: 220),
                withAttributes: textAttributes
            )
            
            // Interests
            "Interests".draw(
                at: CGPoint(x: 50, y: 260),
                withAttributes: titleAttributes
            )
            
            for (index, interest) in profile.interests.enumerated() {
                "• \(interest.rawValue)".draw(
                    at: CGPoint(x: 70, y: 290 + CGFloat(index * 25)),
                    withAttributes: textAttributes
                )
            }
            
            // Preferred Topics
            let topicsStartY = 290 + CGFloat(profile.interests.count * 25) + 30
            "Preferred Topics".draw(
                at: CGPoint(x: 50, y: topicsStartY),
                withAttributes: titleAttributes
            )
            
            for (index, topic) in profile.preferredTopics.enumerated() {
                "• \(topic.rawValue)".draw(
                    at: CGPoint(x: 70, y: topicsStartY + 30 + CGFloat(index * 25)),
                    withAttributes: textAttributes
                )
            }
            
            // Bio
            let bioStartY = topicsStartY + 30 + CGFloat(profile.preferredTopics.count * 25) + 30
            "Bio".draw(
                at: CGPoint(x: 50, y: bioStartY),
                withAttributes: titleAttributes
            )
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let bioRect = CGRect(x: 70, y: bioStartY + 30, width: 492, height: 200)
            let bioAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            (profile.bio as NSString).draw(in: bioRect, withAttributes: bioAttributes)
            
            // Footer
            "Generated by Drona AI".draw(
                at: CGPoint(x: 50, y: 700),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .light)]
            )
            
            "Page 1".draw(
                at: CGPoint(x: 550, y: 700),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
        }
        
        if let pdfPage = PDFPage(image: UIImage(data: pdfData)!) {
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
    }
    
    private func addConversationPagesToPDF(_ pdfDocument: PDFDocument) {
        let conversations = ConversationManager.shared.conversations
        
        for (index, conversation) in conversations.enumerated() {
            // Create PDF page
            let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
            let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
            
            let pdfData = renderer.pdfData { context in
                context.beginPage()
                
                // Draw header
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                
                let subHeaderAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                
                "Drona Conversation".draw(
                    at: CGPoint(x: 50, y: 50),
                    withAttributes: headerAttributes
                )
                
                conversation.title.draw(
                    at: CGPoint(x: 50, y: 80),
                    withAttributes: subHeaderAttributes
                )
                
                "Category: \(conversation.category.rawValue)".draw(
                    at: CGPoint(x: 50, y: 105),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
                )
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                
                "Date: \(dateFormatter.string(from: conversation.lastUpdated))".draw(
                    at: CGPoint(x: 50, y: 125),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
                )
                
                // Line separator
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 50, y: 150))
                path.addLine(to: CGPoint(x: 562, y: 150))
                path.lineWidth = 1
                UIColor.gray.setStroke()
                path.stroke()
                
                // Conversation messages
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                var yPosition: CGFloat = 180
                
                for (msgIndex, message) in conversation.messages.enumerated() {
                    let titleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                        .foregroundColor: message.isFromUser ? UIColor.blue : UIColor.purple
                    ]
                    
                    let messageTime = dateFormatter.string(from: message.timestamp)
                    let sender = message.isFromUser ? "You" : "Drona"
                    
                    // Determine if we need a new page
                    if yPosition > 650 {
                        // Add page number
                        "Page \(index + 1)-\(msgIndex / 5 + 1)".draw(
                            at: CGPoint(x: 530, y: 700),
                            withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
                        )
                        
                        context.beginPage()
                        yPosition = 50
                        
                        // Add continuation header
                        "\(conversation.title) (continued)".draw(
                            at: CGPoint(x: 50, y: yPosition),
                            withAttributes: subHeaderAttributes
                        )
                        
                        yPosition += 30
                    }
                    
                    "\(sender) - \(messageTime)".draw(
                        at: CGPoint(x: 50, y: yPosition),
                        withAttributes: titleAttributes
                    )
                    
                    yPosition += 25
                    
                    let messageRect = CGRect(x: 70, y: yPosition, width: 492, height: 200)
                    let messageAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle
                    ]
                    
                    // Calculate text height
                    let textRect = (message.content as NSString).boundingRect(
                        with: CGSize(width: 492, height: CGFloat.greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: messageAttributes,
                        context: nil
                    )
                    
                    (message.content as NSString).draw(in: messageRect, withAttributes: messageAttributes)
                    
                    yPosition += textRect.height + 20
                }
                
                // Footer
                "Generated by Drona AI".draw(
                    at: CGPoint(x: 50, y: 700),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .light)]
                )
                
                "Page \(index + 1)".draw(
                    at: CGPoint(x: 550, y: 700),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
                )
            }
            
            if let pdfPage = PDFPage(image: UIImage(data: pdfData)!) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
    }
    
    // JSON Export
    private func exportAsJSON(content: ExportContent, completion: @escaping (URL?) -> Void) {
        var jsonData: [String: Any] = [
            "exportDate": formattedDate()
        ]
        
        switch content {
        case .profile:
            if let profile = UserProfileManager.shared.userProfile {
                jsonData["profile"] = [
                    "name": profile.name,
                    "age": profile.age,
                    "educationLevel": profile.educationLevel.rawValue,
                    "interests": profile.interests.map { $0.rawValue },
                    "preferredTopics": profile.preferredTopics.map { $0.rawValue },
                    "bio": profile.bio
                ]
            }
        case .conversations:
            jsonData["conversations"] = ConversationManager.shared.conversations.map { conversation in
                [
                    "id": conversation.id.uuidString,
                    "title": conversation.title,
                    "category": conversation.category.rawValue,
                    "lastUpdated": ISO8601DateFormatter().string(from: conversation.lastUpdated),
                    "messages": conversation.messages.map { message in
                        [
                            "id": message.id.uuidString,
                            "content": message.content,
                            "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
                            "isFromUser": message.isFromUser
                        ]
                    }
                ]
            }
        case .allData:
            if let profile = UserProfileManager.shared.userProfile {
                jsonData["profile"] = [
                    "name": profile.name,
                    "age": profile.age,
                    "educationLevel": profile.educationLevel.rawValue,
                    "interests": profile.interests.map { $0.rawValue },
                    "preferredTopics": profile.preferredTopics.map { $0.rawValue },
                    "bio": profile.bio
                ]
            }
            
            jsonData["conversations"] = ConversationManager.shared.conversations.map { conversation in
                [
                    "id": conversation.id.uuidString,
                    "title": conversation.title,
                    "category": conversation.category.rawValue,
                    "lastUpdated": ISO8601DateFormatter().string(from: conversation.lastUpdated),
                    "messages": conversation.messages.map { message in
                        [
                            "id": message.id.uuidString,
                            "content": message.content,
                            "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
                            "isFromUser": message.isFromUser
                        ]
                    }
                ]
            }
            
            // Add analytics data
            jsonData["analytics"] = [
                "totalSessionsCount": UserActivityManager.shared.activitySummary.totalSessionsCount,
                "totalSessionTime": UserActivityManager.shared.activitySummary.totalSessionTime,
                "totalConversationsStarted": UserActivityManager.shared.activitySummary.totalConversationsStarted,
                "totalMessagesCount": UserActivityManager.shared.activitySummary.totalMessagesCount,
                "categoryBreakdown": UserActivityManager.shared.activitySummary.categoryBreakdown,
                "streak": UserActivityManager.shared.activitySummary.streak,
                "topicsAsked": UserActivityManager.shared.activitySummary.topicsAsked
            ]
        }
        
        // Convert to JSON data
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted) {
            let fileName = "Drona_Export_\(formattedDate()).json"
            saveToFile(data: jsonData, fileName: fileName, utType: UTType.json, completion: completion)
        } else {
            completion(nil)
        }
    }
    
    // Text Export
    private func exportAsText(content: ExportContent, completion: @escaping (URL?) -> Void) {
        var textContent = "DRONA DATA EXPORT\n"
        textContent += "Date: \(formattedDate())\n"
        textContent += "======================================\n\n"
        
        switch content {
        case .profile:
            if let profile = UserProfileManager.shared.userProfile {
                textContent += "USER PROFILE\n"
                textContent += "======================================\n"
                textContent += "Name: \(profile.name)\n"
                textContent += "Age: \(profile.age)\n"
                textContent += "Education Level: \(profile.educationLevel.rawValue)\n\n"
                
                textContent += "Interests:\n"
                for interest in profile.interests {
                    textContent += "- \(interest.rawValue)\n"
                }
                textContent += "\n"
                
                textContent += "Preferred Topics:\n"
                for topic in profile.preferredTopics {
                    textContent += "- \(topic.rawValue)\n"
                }
                textContent += "\n"
                
                textContent += "Bio:\n"
                textContent += "\(profile.bio)\n\n"
            }
        case .conversations:
            textContent += "CONVERSATIONS\n"
            textContent += "======================================\n\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            for (index, conversation) in ConversationManager.shared.conversations.enumerated() {
                textContent += "CONVERSATION #\(index + 1)\n"
                textContent += "Title: \(conversation.title)\n"
                textContent += "Category: \(conversation.category.rawValue)\n"
                textContent += "Date: \(dateFormatter.string(from: conversation.lastUpdated))\n"
                textContent += "--------------------------------------\n\n"
                
                for message in conversation.messages {
                    let time = dateFormatter.string(from: message.timestamp)
                    textContent += "\(message.isFromUser ? "You" : "Drona") - \(time):\n"
                    textContent += "\(message.content)\n\n"
                }
                
                textContent += "======================================\n\n"
            }
        case .allData:
            // Include profile data
            if let profile = UserProfileManager.shared.userProfile {
                textContent += "USER PROFILE\n"
                textContent += "======================================\n"
                textContent += "Name: \(profile.name)\n"
                textContent += "Age: \(profile.age)\n"
                textContent += "Education Level: \(profile.educationLevel.rawValue)\n\n"
                
                textContent += "Interests:\n"
                for interest in profile.interests {
                    textContent += "- \(interest.rawValue)\n"
                }
                textContent += "\n"
                
                textContent += "Preferred Topics:\n"
                for topic in profile.preferredTopics {
                    textContent += "- \(topic.rawValue)\n"
                }
                textContent += "\n"
                
                textContent += "Bio:\n"
                textContent += "\(profile.bio)\n\n"
            }
            
            // Include conversations
            textContent += "CONVERSATIONS\n"
            textContent += "======================================\n\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            for (index, conversation) in ConversationManager.shared.conversations.enumerated() {
                textContent += "CONVERSATION #\(index + 1)\n"
                textContent += "Title: \(conversation.title)\n"
                textContent += "Category: \(conversation.category.rawValue)\n"
                textContent += "Date: \(dateFormatter.string(from: conversation.lastUpdated))\n"
                textContent += "--------------------------------------\n\n"
                
                for message in conversation.messages {
                    let time = dateFormatter.string(from: message.timestamp)
                    textContent += "\(message.isFromUser ? "You" : "Drona") - \(time):\n"
                    textContent += "\(message.content)\n\n"
                }
                
                textContent += "======================================\n\n"
            }
            
            // Include analytics
            textContent += "USAGE STATISTICS\n"
            textContent += "======================================\n"
            textContent += "Total Sessions: \(UserActivityManager.shared.activitySummary.totalSessionsCount)\n"
            textContent += "Total Time Spent: \(formatTime(UserActivityManager.shared.activitySummary.totalSessionTime))\n"
            textContent += "Total Conversations: \(UserActivityManager.shared.activitySummary.totalConversationsStarted)\n"
            textContent += "Total Messages: \(UserActivityManager.shared.activitySummary.totalMessagesCount)\n"
            textContent += "Current Streak: \(UserActivityManager.shared.activitySummary.streak) days\n\n"
            
            textContent += "Category Breakdown:\n"
            for (category, count) in UserActivityManager.shared.activitySummary.categoryBreakdown {
                textContent += "- \(category): \(count)\n"
            }
            textContent += "\n"
        }
        
        // Save to file
        if let textData = textContent.data(using: .utf8) {
            let fileName = "Drona_Export_\(formattedDate()).txt"
            saveToFile(data: textData, fileName: fileName, utType: UTType.plainText, completion: completion)
        } else {
            completion(nil)
        }
    }
    
    // Helper function to save data to file
    private func saveToFile(data: Data, fileName: String, utType: UTType, completion: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            completion(fileURL)
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Helper function to format current date
    private func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        return dateFormatter.string(from: Date())
    }
    
    // Helper function to format time
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
} 