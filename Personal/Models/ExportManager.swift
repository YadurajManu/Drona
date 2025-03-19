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
    func exportUserData(format: ExportFormat, content: ExportContent, userProfileManager: UserProfileManager, completion: @escaping (URL?) -> Void) {
        switch format {
        case .pdf:
            exportAsPDF(content: content, userProfileManager: userProfileManager, completion: completion)
        case .json:
            exportAsJSON(content: content, userProfileManager: userProfileManager, completion: completion)
        case .text:
            exportAsText(content: content, userProfileManager: userProfileManager, completion: completion)
        }
    }
    
    // PDF Export
    private func exportAsPDF(content: ExportContent, userProfileManager: UserProfileManager, completion: @escaping (URL?) -> Void) {
        // Create file URL for the PDF
        let fileName = "Drona_Export_\(formattedDate()).pdf"
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Begin PDF context
        UIGraphicsBeginPDFContextToFile(fileURL.path, CGRect.zero, nil)
        
        // Create pages based on content type
        switch content {
        case .profile:
            if let userProfile = userProfileManager.userProfile {
                createProfilePDFPage(userProfile: userProfile)
            } else {
                print("No user profile available for PDF export")
            }
        case .conversations:
            createConversationPDFPages()
        case .allData:
            if let userProfile = userProfileManager.userProfile {
                createProfilePDFPage(userProfile: userProfile)
            }
            createConversationPDFPages()
        }
        
        // End PDF context
        UIGraphicsEndPDFContext()
        
        // Check if file was created
        if fileManager.fileExists(atPath: fileURL.path) {
            completion(fileURL)
        } else {
            print("Failed to create PDF file")
            completion(nil)
        }
    }
    
    private func createProfilePDFPage(userProfile: UserProfile) {
        // Page size (US Letter)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        // Begin a new PDF page
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
        
        // Get current context
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to get graphics context")
            return
        }
        
        // Draw profile content
        drawProfileContent(in: context, rect: pageRect, userProfile: userProfile)
    }
    
    private func createConversationPDFPages() {
        let conversations = ConversationManager.shared.conversations
        
        // Page size (US Letter)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        for (index, conversation) in conversations.enumerated() {
            // Begin a new PDF page
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            
            // Get current context
            guard let context = UIGraphicsGetCurrentContext() else {
                print("Failed to get graphics context")
                continue
            }
            
            // Draw conversation content
            drawConversationContent(in: context, rect: pageRect, conversation: conversation, index: index)
        }
    }
    
    private func drawConversationContent(in context: CGContext, rect: CGRect, conversation: Conversation, index: Int) {
        // Save the graphics state
        context.saveGState()
        
        // Set up text attributes
        let headerFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let subHeaderFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let bodyFont = UIFont.systemFont(ofSize: 14)
        let messageFont = UIFont.systemFont(ofSize: 12)
        let footerFont = UIFont.systemFont(ofSize: 12, weight: .light)
        
        // Draw header
        drawText(context: context, text: "Drona Conversation", point: CGPoint(x: 50, y: 50), font: headerFont)
        drawText(context: context, text: conversation.title, point: CGPoint(x: 50, y: 80), font: subHeaderFont)
        drawText(context: context, text: "Category: \(conversation.category.rawValue)", point: CGPoint(x: 50, y: 105), font: bodyFont)
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        drawText(context: context, text: "Date: \(dateFormatter.string(from: conversation.lastUpdated))", point: CGPoint(x: 50, y: 125), font: bodyFont)
        
        // Line separator
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 50, y: 150))
        context.addLine(to: CGPoint(x: 562, y: 150))
        context.strokePath()
        
        // Draw messages
        var yPosition: CGFloat = 180
        
        for (msgIndex, message) in conversation.messages.enumerated() {
            // Check if we need a new page
            if yPosition > 650 {
                // Draw footer on current page
                drawText(context: context, text: "Page \(index + 1)-\(msgIndex / 5 + 1)", point: CGPoint(x: 550, y: 700), font: footerFont)
                
                // Start a new page
                UIGraphicsBeginPDFPageWithInfo(rect, nil)
                guard let newContext = UIGraphicsGetCurrentContext() else { continue }
                
                // Reset position
                yPosition = 50
                
                // Add continuation header
                drawText(context: newContext, text: "\(conversation.title) (continued)", point: CGPoint(x: 50, y: yPosition), font: subHeaderFont)
                yPosition += 30
            }
            
            // Draw message sender and time
            let messageTime = dateFormatter.string(from: message.timestamp)
            let sender = message.isFromUser ? "You" : "Drona"
            let senderColor = message.isFromUser ? UIColor.blue : UIColor.purple
            
            let senderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: senderColor
            ]
            
            let senderString = NSAttributedString(string: "\(sender) - \(messageTime)", attributes: senderAttributes)
            
            // Flip the context coordinates for text drawing
            context.saveGState()
            context.translateBy(x: 0, y: 792) // Height of the page
            context.scaleBy(x: 1.0, y: -1.0)
            
            let senderRect = CGRect(x: 50, y: 792 - yPosition, width: 500, height: 20)
            senderString.draw(in: senderRect)
            
            context.restoreGState()
            
            yPosition += 25
            
            // Draw message content
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: messageFont,
                .foregroundColor: UIColor.black
            ]
            
            let messageString = NSAttributedString(string: message.content, attributes: messageAttributes)
            
            context.saveGState()
            context.translateBy(x: 0, y: 792)
            context.scaleBy(x: 1.0, y: -1.0)
            
            let messageRect = CGRect(x: 70, y: 792 - yPosition, width: 492, height: 200)
            messageString.draw(in: messageRect)
            
            context.restoreGState()
            
            // Approximate text height - this is simplified
            let approxHeight = min(CGFloat(message.content.count) / 3, 150)
            yPosition += approxHeight + 20
        }
        
        // Footer
        drawText(context: context, text: "Generated by Drona AI", point: CGPoint(x: 50, y: 700), font: footerFont)
        drawText(context: context, text: "Page \(index + 1)", point: CGPoint(x: 550, y: 700), font: footerFont)
        
        // Restore the graphics state
        context.restoreGState()
    }
    
    private func drawProfileContent(in context: CGContext, rect: CGRect, userProfile: UserProfile) {
        // Save the graphics state
        context.saveGState()
        
        // Set up text attributes
        let headerFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 14)
        let footerFont = UIFont.systemFont(ofSize: 12, weight: .light)
        
        // Draw header
        drawText(context: context, text: "Drona User Profile", point: CGPoint(x: 50, y: 50), font: headerFont)
        
        // Draw export date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        drawText(context: context, text: "Export Date: \(dateFormatter.string(from: Date()))", point: CGPoint(x: 50, y: 90), font: bodyFont)
        
        // Draw line separator
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 50, y: 110))
        context.addLine(to: CGPoint(x: 562, y: 110))
        context.strokePath()
        
        // Draw profile sections
        // Basic Info
        drawText(context: context, text: "Basic Information", point: CGPoint(x: 50, y: 140), font: titleFont)
        drawText(context: context, text: "Name: \(userProfile.name)", point: CGPoint(x: 70, y: 170), font: bodyFont)
        drawText(context: context, text: "Age: \(userProfile.age)", point: CGPoint(x: 70, y: 195), font: bodyFont)
        drawText(context: context, text: "Education Level: \(userProfile.educationLevel.rawValue)", point: CGPoint(x: 70, y: 220), font: bodyFont)
        
        // Interests
        drawText(context: context, text: "Interests", point: CGPoint(x: 50, y: 260), font: titleFont)
        for (index, interest) in userProfile.interests.enumerated() {
            drawText(context: context, text: "• \(interest.rawValue)", point: CGPoint(x: 70, y: 290 + CGFloat(index * 25)), font: bodyFont)
        }
        
        // Preferred Topics
        let topicsStartY = 290 + CGFloat(userProfile.interests.count * 25) + 30
        drawText(context: context, text: "Preferred Topics", point: CGPoint(x: 50, y: topicsStartY), font: titleFont)
        for (index, topic) in userProfile.preferredTopics.enumerated() {
            drawText(context: context, text: "• \(topic.rawValue)", point: CGPoint(x: 70, y: topicsStartY + 30 + CGFloat(index * 25)), font: bodyFont)
        }
        
        // Bio
        let bioStartY = topicsStartY + 30 + CGFloat(userProfile.preferredTopics.count * 25) + 30
        drawText(context: context, text: "Bio", point: CGPoint(x: 50, y: bioStartY), font: titleFont)
        
        // For multiline text, we need a more complex approach
        // This is simplified for now
        drawText(context: context, text: userProfile.bio, point: CGPoint(x: 70, y: bioStartY + 30), font: bodyFont)
        
        // Footer
        drawText(context: context, text: "Generated by Drona AI", point: CGPoint(x: 50, y: 700), font: footerFont)
        drawText(context: context, text: "Page 1", point: CGPoint(x: 550, y: 700), font: footerFont)
        
        // Restore the graphics state
        context.restoreGState()
    }
    
    private func drawText(context: CGContext, text: String, point: CGPoint, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        
        // Flip the context coordinates for text drawing
        context.saveGState()
        context.translateBy(x: 0, y: 792) // Height of the page
        context.scaleBy(x: 1.0, y: -1.0)
        
        let textRect = CGRect(x: point.x, y: 792 - point.y, width: 500, height: 100)
        string.draw(in: textRect)
        
        context.restoreGState()
    }
    
    // JSON Export
    private func exportAsJSON(content: ExportContent, userProfileManager: UserProfileManager, completion: @escaping (URL?) -> Void) {
        var jsonData: [String: Any] = [
            "exportDate": formattedDate()
        ]
        
        switch content {
        case .profile:
            if let profile = userProfileManager.userProfile {
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
            if let profile = userProfileManager.userProfile {
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
    private func exportAsText(content: ExportContent, userProfileManager: UserProfileManager, completion: @escaping (URL?) -> Void) {
        var textContent = "DRONA DATA EXPORT\n"
        textContent += "Date: \(formattedDate())\n"
        textContent += "======================================\n\n"
        
        switch content {
        case .profile:
            if let profile = userProfileManager.userProfile {
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
            if let profile = userProfileManager.userProfile {
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