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
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
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
            // Refresh data
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
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
            
            // Placeholder for chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack {
                        let height = CGFloat([15, 30, 20, 45, 25, 40, 35][index])
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 30, height: height)
                            .cornerRadius(5)
                        
                        Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
            .padding(.vertical)
            
            Text("This is a placeholder for activity visualization. In a real implementation, this would be a proper chart showing your activity patterns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
            Text("Personalized Insights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 15) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("You're most active on weekdays, especially in the evenings. Your learning is most effective when you have consistent sessions.")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            
            HStack(spacing: 15) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Your conversations about academic topics tend to be longer and more detailed than other categories.")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct UserAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserAnalyticsView()
        }
    }
} 