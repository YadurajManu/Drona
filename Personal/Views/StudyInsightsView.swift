//
//  StudyInsightsView.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

struct StudyInsightsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var coachManager = StudyCoachManager.shared
    @State private var selectedFilter: InsightFilter = .all
    
    enum InsightFilter: String, CaseIterable {
        case all = "All"
        case patterns = "Patterns"
        case strengths = "Strengths"
        case improvements = "Improvements"
        case recommendations = "Recommendations"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(InsightFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: filter == selectedFilter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                if filteredInsights.isEmpty {
                    emptyStateView
                } else {
                    insightsList
                }
            }
            .navigationTitle("Learning Insights")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var insightsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredInsights) { insight in
                    InsightCard(insight: insight)
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("No insights yet")
                .font(.headline)
            
            Text("As you use Drona, your coach will generate personalized learning insights based on your activity.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: generateSampleInsight) {
                Text("Generate Sample Insight")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredInsights: [StudyCoach.CoachInsight] {
        switch selectedFilter {
        case .all:
            return coachManager.studyInsights
        case .patterns:
            return coachManager.studyInsights.filter { $0.category == .pattern }
        case .strengths:
            return coachManager.studyInsights.filter { $0.category == .strength }
        case .improvements:
            return coachManager.studyInsights.filter { $0.category == .improvement || $0.category == .challenge }
        case .recommendations:
            return coachManager.studyInsights.filter { $0.category == .recommendation }
        }
    }
    
    private func generateSampleInsight() {
        let sources: [StudyCoach.CoachInsight.InsightSource] = [
            .flashcards, .conversations, .studyTime, .performance
        ]
        
        if let randomSource = sources.randomElement() {
            coachManager.generateStudyInsight(from: randomSource)
        }
    }
}

struct InsightCard: View {
    let insight: StudyCoach.CoachInsight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                insightTypeLabel
                
                Spacer()
                
                Text(formatDate(insight.createdDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.title)
                .font(.headline)
            
            if isExpanded || insight.description.count < 100 {
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(insight.description.prefix(100) + "...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if insight.description.count >= 100 {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            if insight.isActionable, let action = insight.relatedAction {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text(action)
                        .font(.callout)
                        .fontWeight(.medium)
                }
                .padding(.top, 5)
            }
            
            HStack {
                sourceTag
                
                Spacer()
                
                Button(action: {
                    // Action to apply/implement the insight
                }) {
                    Text("Apply")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var insightTypeLabel: some View {
        HStack {
            Image(systemName: iconForInsightType)
            Text(insight.category.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForInsightType.opacity(0.1))
        .foregroundColor(colorForInsightType)
        .cornerRadius(8)
    }
    
    private var sourceTag: some View {
        Text("From \(insight.source.rawValue)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(8)
    }
    
    private var iconForInsightType: String {
        switch insight.category {
        case .pattern:
            return "chart.line.uptrend.xyaxis"
        case .strength:
            return "star.fill"
        case .challenge:
            return "exclamationmark.triangle"
        case .improvement:
            return "arrow.up.right"
        case .recommendation:
            return "lightbulb.fill"
        case .milestone:
            return "flag.fill"
        }
    }
    
    private var colorForInsightType: Color {
        switch insight.category {
        case .pattern:
            return .blue
        case .strength:
            return .green
        case .challenge:
            return .orange
        case .improvement:
            return .purple
        case .recommendation:
            return .yellow
        case .milestone:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct StudyInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        StudyInsightsView()
    }
} 