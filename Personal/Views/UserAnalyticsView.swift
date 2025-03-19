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
    @State private var showingTips = false
    @State private var chartData: [ChartDataPoint] = []
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }
    
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let day: String
        let value: CGFloat
        let date: Date
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                streakCard
                
                usageSummaryCard
                
                topicsCard
                
                activityChartCard
                
                insightsCard
            }
            .padding()
        }
        .navigationTitle("Learning Insights")
        .onAppear {
            generateChartData()
        }
        .onChange(of: selectedTimeFrame) { _ in
            generateChartData()
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Your Learning Streak")
                    .font(.headline)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                    
                    Text("\(activityManager.activitySummary.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("You've been learning with Drona for \(activityManager.activitySummary.streak) consecutive days!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Daily streak indicators
            HStack(spacing: 4) {
                ForEach(0..<7) { i in
                    let isActive = i < min(activityManager.activitySummary.streak, 7)
                    Circle()
                        .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
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
    }
    
    private var usageSummaryCard: some View {
        VStack(spacing: 15) {
            Text("Your Learning Journey")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                statBox(
                    value: "\(activityManager.activitySummary.totalConversationsStarted)",
                    label: "Conversations",
                    icon: "text.bubble.fill",
                    color: .blue
                )
                
                statBox(
                    value: "\(activityManager.activitySummary.totalMessagesCount)",
                    label: "Questions Asked",
                    icon: "questionmark.circle.fill",
                    color: .purple
                )
                
                statBox(
                    value: formatTime(),
                    label: "Time Spent",
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
    }
    
    private func formatTime() -> String {
        let totalMinutes = Int(activityManager.activitySummary.totalSessionTime / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes)"
        } else {
            let hours = totalMinutes / 60
            return "\(hours)h"
        }
    }
    
    private var topicsCard: some View {
        VStack(spacing: 15) {
            Text("Your Topics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let mostAskedTopic = activityManager.getMostAskedTopic() {
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
            }
            
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
            
            // Topic distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("Topics Distribution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(topicsDistribution, id: \.name) { item in
                        VStack {
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.color)
                                .frame(width: 30, height: max(50 * item.percentage / 100, 5))
                            
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var topicsDistribution: [TopicItem] {
        let breakdown = activityManager.activitySummary.categoryBreakdown
        let total = breakdown.values.reduce(0, +)
        
        if total == 0 {
            return [
                TopicItem(name: "Academic", percentage: 0, color: .blue),
                TopicItem(name: "Personal", percentage: 0, color: .purple),
                TopicItem(name: "Career", percentage: 0, color: .indigo)
            ]
        }
        
        let sorted = breakdown.sorted { $0.value > $1.value }
        
        return sorted.prefix(5).map { item in
            let color: Color
            switch item.key {
            case "Academic": color = .blue
            case "Personal": color = .purple
            case "Financial": color = .green
            case "Social": color = .orange
            case "Relational": color = .pink
            case "Career": color = .indigo
            default: color = .gray
            }
            
            return TopicItem(
                name: item.key,
                percentage: Double(item.value) / Double(total) * 100,
                color: color
            )
        }
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
            
            // Activity chart
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(chartData) { point in
                        VStack(spacing: 5) {
                            Text("\(Int(point.value))")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .opacity(point.value > 0 ? 1 : 0)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 35, height: max(point.value * 2, point.value > 0 ? 5 : 0))
                            
                            Text(point.day)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(Angle(degrees: 0))
                        }
                    }
                }
                .frame(height: 150)
                .padding(.vertical, 10)
                
                if chartData.isEmpty {
                    Text("No activity data for the selected time frame")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var insightsCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Personalized Insights")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingTips.toggle() }) {
                    Label(showingTips ? "Hide Tips" : "Show Tips", systemImage: showingTips ? "lightbulb.fill" : "lightbulb")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if showingTips {
                HStack(spacing: 15) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    Text("You're most active on \(mostActiveDay). Consider scheduling study sessions on this day for better consistency.")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
            
            HStack(spacing: 15) {
                Image(systemName: activityManager.activitySummary.streak > 3 ? "chart.bar.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(activityManager.activitySummary.streak > 3 ? .green : .orange)
                
                Text(activityManager.activitySummary.streak > 3 ? 
                     "Great job maintaining a \(activityManager.activitySummary.streak)-day streak! Consistent learning leads to better results." : 
                     "Try to use Drona more consistently to build a learning habit. Even 5 minutes daily makes a difference.")
                    .font(.subheadline)
            }
            .padding()
            .background(Color(activityManager.activitySummary.streak > 3 ? .green : .orange).opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Tips to Improve Your Learning")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TipRowView(tip: "Ask follow-up questions to deepen your understanding", number: 1)
                TipRowView(tip: "Review previous conversations to reinforce learning", number: 2)
                TipRowView(tip: "Set specific learning goals for each session", number: 3)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var mostActiveDay: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let activityByDay = [4, 8, 6, 3, 7, 10, 5] // Mock data
        
        if let maxIndex = activityByDay.indices.max(by: { activityByDay[$0] < activityByDay[$1] }) {
            return days[maxIndex]
        }
        
        return "weekdays"
    }
    
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
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func generateChartData() {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        var labels: [String] = []
        
        switch selectedTimeFrame {
        case .week:
            // Last 7 days
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.insert(date, at: 0)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "E"
                    labels.insert(formatter.string(from: date), at: 0)
                }
            }
        case .month:
            // Last 4 weeks by week
            for i in 0..<4 {
                if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) {
                    dates.insert(date, at: 0)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    labels.insert(formatter.string(from: date), at: 0)
                }
            }
        case .allTime:
            // Last 6 months by month
            for i in 0..<6 {
                if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                    dates.insert(date, at: 0)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM"
                    labels.insert(formatter.string(from: date), at: 0)
                }
            }
        }
        
        // Generate data points
        chartData = []
        
        for (index, date) in dates.enumerated() {
            // In a real app, you would get real data for each date from the activity manager
            // For now, we'll generate some random data
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateKey = dateFormatter.string(from: date)
            
            let minutesToday = activityManager.activitySummary.dailyActivity[dateKey] ?? 0
            let value = CGFloat(minutesToday)
            
            chartData.append(ChartDataPoint(day: labels[index], value: value, date: date))
        }
    }
}

struct TopicItem {
    let name: String
    let percentage: Double
    let color: Color
}

struct TipRowView: View {
    let tip: String
    let number: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(tip)
                .font(.subheadline)
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