//
//  UserAnalyticsView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct UserAnalyticsView: View {
    @ObservedObject private var activityManager = UserActivityManager.shared
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var animateCharts = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        List {
            streakCard
                .listRowSeparator(.hidden)
            
            usageSummaryCard
                .listRowSeparator(.hidden)
            
            if let mostAskedTopic = activityManager.getMostAskedTopic() {
                topicsCard(mostAskedTopic: mostAskedTopic)
                    .listRowSeparator(.hidden)
            }
            
            activityChartCard
                .listRowSeparator(.hidden)
            
            insightsCard
                .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Learning Insights")
        .onAppear {
            // Animate charts when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateCharts = true
                }
            }
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Your Learning Streak")
                    .font(.headline)
                
                Spacer()
                
                // Streak circle with counter
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    
                    Text("\(activityManager.activitySummary.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 2)
            }
            
            Text("You've been learning with Drona for \(activityManager.activitySummary.streak) consecutive days!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Streak visualization
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { day in
                    DayCircle(
                        isActive: day <= min(activityManager.activitySummary.streak, 7),
                        number: day
                    )
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var usageSummaryCard: some View {
        VStack(spacing: 15) {
            Text("Your Learning Journey")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                statBox(
                    value: "\(activityManager.activitySummary.totalConversationsStarted)",
                    label: "Conversations",
                    icon: "text.bubble.fill",
                    color: .blue
                )
                
                statBox(
                    value: "\(activityManager.activitySummary.totalMessagesCount)",
                    label: "Questions",
                    icon: "questionmark.circle.fill",
                    color: .purple
                )
                
                statBox(
                    value: "\(Int(activityManager.activitySummary.totalSessionTime / 60))",
                    label: "Minutes",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func topicsCard(mostAskedTopic: String) -> some View {
        VStack(spacing: 15) {
            Text("Your Topics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Most asked topic
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Most Asked About")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(mostAskedTopic)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding(.vertical, 5)
            
            // Most active category
            if let mostActiveCategory = activityManager.getMostActiveCategory() {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Most Active Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(mostActiveCategory)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            
            // Category breakdown
            if activityManager.activitySummary.categoryBreakdown.count > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Breakdown")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
                    ForEach(activityManager.activitySummary.categoryBreakdown.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { category, count in
                        CategoryProgressBar(
                            name: category,
                            value: count,
                            total: activityManager.activitySummary.totalConversationsStarted,
                            animate: animateCharts
                        )
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var activityChartCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Activity Over Time")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { frame in
                        Text(frame.rawValue).tag(frame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Activity bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let activityData = getActivityData()
                    let maxHeight: CGFloat = 100
                    let value = activityData[index]
                    let maxValue = activityData.max() ?? 1
                    let normalizedHeight = maxValue > 0 ? (CGFloat(value) / CGFloat(maxValue) * maxHeight) : 0
                    
                    VStack {
                        Rectangle()
                            .fill(getBarColor(for: index))
                            .frame(width: 30, height: animateCharts ? normalizedHeight : 0)
                            .cornerRadius(5)
                        
                        Text(getDayLabel(for: index))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 130)
            .padding(.top, 10)
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 8, height: 8)
                    
                    Text("Activity Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 8, height: 8)
                    
                    Text("High Activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var insightsCard: some View {
        VStack(spacing: 15) {
            Text("Personalized Insights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Generate insights based on real activity data
            ForEach(generateInsights(), id: \.self) { insight in
                insightRow(icon: insight.icon, color: insight.color, text: insight.text)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Views
    
    private func statBox(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func getActivityData() -> [Int] {
        let dailyActivity = activityManager.getDailyActivityData()
        
        // Create an array of 7 days with their activity minutes
        var result = [0, 0, 0, 0, 0, 0, 0]
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for (date, minutes) in dailyActivity {
            let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? 0
            
            if dayDifference >= 0 && dayDifference < 7 {
                let index = 6 - dayDifference // Reverse order so today is on the right
                result[index] = minutes
            }
        }
        
        return result
    }
    
    private func getDayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let date = calendar.date(byAdding: .day, value: index - 6, to: today) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func getBarColor(for index: Int) -> Color {
        let activityData = getActivityData()
        let value = activityData[index]
        
        // Create a gradient based on activity level
        if value > 30 {
            return Color.green.opacity(0.7)
        } else if value > 15 {
            return Color.blue.opacity(0.7)
        } else {
            return Color.blue.opacity(0.5)
        }
    }
    
    private struct InsightInfo: Hashable {
        let icon: String
        let color: Color
        let text: String
    }
    
    private func generateInsights() -> [InsightInfo] {
        var insights: [InsightInfo] = []
        
        // Streak insight
        if activityManager.activitySummary.streak > 3 {
            insights.append(InsightInfo(
                icon: "flame.fill",
                color: .orange,
                text: "You're on a \(activityManager.activitySummary.streak)-day streak! Consistent learning leads to better retention."
            ))
        }
        
        // Most active category insight
        if let category = activityManager.getMostActiveCategory() {
            insights.append(InsightInfo(
                icon: "chart.bar.fill",
                color: .blue,
                text: "You focus most on \(category) topics. This specialized focus can lead to deeper understanding."
            ))
        }
        
        // Activity pattern insight
        let activityData = getActivityData()
        let weekdayActivity = activityData[1...5].reduce(0, +)
        let weekendActivity = activityData[0] + activityData[6]
        
        if weekdayActivity > weekendActivity * 2 {
            insights.append(InsightInfo(
                icon: "calendar",
                color: .green,
                text: "You're most active on weekdays. Try to maintain a consistent schedule on weekends too."
            ))
        } else if weekendActivity > weekdayActivity {
            insights.append(InsightInfo(
                icon: "calendar",
                color: .purple,
                text: "You study more on weekends. This focused time allows for deeper exploration of topics."
            ))
        }
        
        // Session duration insight
        let avgSessionTime = activityManager.getAverageSessionTime() / 60 // in minutes
        if avgSessionTime > 20 {
            insights.append(InsightInfo(
                icon: "clock.fill",
                color: .indigo,
                text: "Your average session is \(Int(avgSessionTime)) minutes. Longer focused sessions help with complex topics."
            ))
        } else if avgSessionTime > 0 {
            insights.append(InsightInfo(
                icon: "clock.fill",
                color: .pink,
                text: "Your short, frequent sessions average \(Int(avgSessionTime)) minutes. Perfect for spaced repetition learning."
            ))
        }
        
        // Add default insights if we don't have enough
        if insights.count < 2 {
            insights.append(InsightInfo(
                icon: "lightbulb.fill",
                color: .yellow,
                text: "Use Drona regularly to get personalized insights about your learning patterns."
            ))
        }
        
        return Array(insights.prefix(3)) // Return at most 3 insights
    }
}

// MARK: - Supporting Views

struct DayCircle: View {
    let isActive: Bool
    let number: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
            
            Text("\(number)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? .white : .gray)
        }
    }
}

struct CategoryProgressBar: View {
    let name: String
    let value: Int
    let total: Int
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                
                Spacer()
                
                Text("\(value)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: animate ? geometry.size.width * CGFloat(value) / CGFloat(max(total, 1)) : 0, height: 8)
                        .foregroundColor(.blue)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}

struct UserAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserAnalyticsView()
        }
    }
} 