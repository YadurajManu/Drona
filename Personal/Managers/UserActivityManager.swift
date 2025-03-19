//
//  UserActivityManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI

class UserActivityManager: ObservableObject {
    @Published var activitySummary: ActivitySummary = ActivitySummary()
    private let userDefaultsKey = "dronaUserActivity"
    private var timer: Timer?
    private var currentSessionStartTime: Date?
    
    // Singleton instance
    static let shared = UserActivityManager()
    
    struct ActivitySummary: Codable {
        var totalSessionsCount: Int = 0
        var totalSessionTime: TimeInterval = 0
        var totalConversationsStarted: Int = 0
        var totalMessagesCount: Int = 0
        var categoryBreakdown: [String: Int] = [:]
        var lastActiveDate: Date?
        var dailyActivity: [String: Int] = [:] // Date string to minutes
        var streak: Int = 0
        var topicsAsked: [String: Int] = [:]
    }
    
    struct UserEvent: Codable {
        let eventType: EventType
        let timestamp: Date
        let details: [String: String]
        
        enum EventType: String, Codable {
            case sessionStart
            case sessionEnd
            case conversationStart
            case messageSent
            case settingsChange
            case profileUpdate
            case dataExported
            case logout
        }
    }
    
    private init() {
        loadActivityData()
    }
    
    // MARK: - Session Tracking
    
    func startSession() {
        currentSessionStartTime = Date()
        
        // Log event
        logEvent(.sessionStart, details: [:])
        
        // Start timer to update session time periodically
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateSessionTime()
        }
    }
    
    func endSession() {
        // Calculate session duration
        if let startTime = currentSessionStartTime {
            let sessionDuration = Date().timeIntervalSince(startTime)
            activitySummary.totalSessionTime += sessionDuration
            
            // Log event
            logEvent(.sessionEnd, details: ["duration": "\(Int(sessionDuration))"]) 
        }
        
        timer?.invalidate()
        timer = nil
        currentSessionStartTime = nil
        
        // Save updated data
        saveActivityData()
    }
    
    private func updateSessionTime() {
        if let startTime = currentSessionStartTime {
            let sessionDuration = Date().timeIntervalSince(startTime)
            
            // Update daily activity
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let today = dateFormatter.string(from: Date())
            
            let minutesToday = (activitySummary.dailyActivity[today] ?? 0) + 1
            activitySummary.dailyActivity[today] = minutesToday
            
            // Update streak
            updateStreak()
            
            // Save periodically
            saveActivityData()
        }
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = dateFormatter.string(from: Date())
        
        if let lastActive = activitySummary.lastActiveDate {
            let yesterday = dateFormatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date())!)
            
            // If last active was yesterday, increment streak
            let lastActiveString = dateFormatter.string(from: lastActive)
            if lastActiveString == yesterday {
                activitySummary.streak += 1
            } 
            // If last active was before yesterday, reset streak
            else if lastActiveString != today {
                activitySummary.streak = 1
            }
        } else {
            activitySummary.streak = 1
        }
        
        activitySummary.lastActiveDate = Date()
    }
    
    // MARK: - Event Tracking
    
    func trackConversationStarted(category: String) {
        activitySummary.totalConversationsStarted += 1
        activitySummary.categoryBreakdown[category] = (activitySummary.categoryBreakdown[category] ?? 0) + 1
        
        logEvent(.conversationStart, details: ["category": category])
        saveActivityData()
    }
    
    func trackMessageSent(topic: String?) {
        activitySummary.totalMessagesCount += 1
        
        if let topic = topic, !topic.isEmpty {
            activitySummary.topicsAsked[topic] = (activitySummary.topicsAsked[topic] ?? 0) + 1
        }
        
        logEvent(.messageSent, details: topic != nil ? ["topic": topic!] : [:])
        saveActivityData()
    }
    
    func trackSettingsChanged(setting: String, value: String) {
        logEvent(.settingsChange, details: ["setting": setting, "value": value])
    }
    
    func trackProfileUpdated() {
        logEvent(.profileUpdate, details: [:])
    }
    
    func trackDataExported() {
        logEvent(.dataExported, details: [:])
    }
    
    func trackLogout() {
        logEvent(.logout, details: [:])
        endSession()
    }
    
    // MARK: - Analytics
    
    func getMostActiveCategory() -> String? {
        return activitySummary.categoryBreakdown.max { $0.value < $1.value }?.key
    }
    
    func getMostAskedTopic() -> String? {
        return activitySummary.topicsAsked.max { $0.value < $1.value }?.key
    }
    
    func getAverageSessionTime() -> TimeInterval {
        if activitySummary.totalSessionsCount == 0 {
            return 0
        }
        return activitySummary.totalSessionTime / Double(activitySummary.totalSessionsCount)
    }
    
    func getDailyActivityData() -> [(date: Date, minutes: Int)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return activitySummary.dailyActivity.compactMap { (dateString, minutes) in
            if let date = dateFormatter.date(from: dateString) {
                return (date, minutes)
            }
            return nil
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Data Storage
    
    private func logEvent(_ eventType: UserEvent.EventType, details: [String: String]) {
        let event = UserEvent(
            eventType: eventType,
            timestamp: Date(),
            details: details
        )
        
        // In a real app, would store events for detailed analytics
        print("Event logged: \(event.eventType.rawValue) at \(event.timestamp)")
        
        // Update session count if needed
        if eventType == .sessionStart {
            activitySummary.totalSessionsCount += 1
        }
    }
    
    private func saveActivityData() {
        if let encoded = try? JSONEncoder().encode(activitySummary) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadActivityData() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedSummary = try? JSONDecoder().decode(ActivitySummary.self, from: savedData) {
                activitySummary = decodedSummary
                return
            }
        }
        // If no saved data or decoding fails, use the default empty summary
    }
    
    func clearActivityData() {
        activitySummary = ActivitySummary()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
} 