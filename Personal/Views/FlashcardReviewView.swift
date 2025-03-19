//
//  FlashcardReviewView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct FlashcardReviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    
    var cards: [Flashcard]
    
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    @State private var showEndOfReviewView = false
    @State private var reviewedCards = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var startTime: Date? = nil
    @State private var sessionStartTime = Date()
    @State private var reviewStats = ReviewSessionStats()
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Session statistics
    struct ReviewSessionStats {
        var againCount = 0
        var hardCount = 0
        var goodCount = 0
        var easyCount = 0
        var totalTime: TimeInterval = 0
        
        var totalCards: Int {
            againCount + hardCount + goodCount + easyCount
        }
        
        func averageTimePerCard() -> TimeInterval {
            return totalCards > 0 ? totalTime / Double(totalCards) : 0
        }
    }
    
    private var currentCard: Flashcard {
        cards[currentIndex]
    }
    
    private var isLastCard: Bool {
        currentIndex == cards.count - 1
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if showEndOfReviewView {
                sessionSummaryView
            } else {
                VStack {
                    // Progress indicator
                    HStack {
                        Text("\(currentIndex + 1)/\(cards.count)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showEndOfReviewView = true
                            }
                        }) {
                            Text("End Review")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    
                    // Card
                    ZStack {
                        // Shadow card (behind current card)
                        if currentIndex < cards.count - 1 {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray5))
                                .frame(height: 400)
                                .padding(.horizontal, 40)
                                .offset(x: 10, y: 10)
                        }
                        
                        // Main card
                        VStack {
                            Text(isShowingAnswer ? "Answer" : "Question")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            Spacer()
                            
                            Text(isShowingAnswer ? currentCard.answer : currentCard.question)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .rotation3DEffect(
                                    .degrees(rotation),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                            
                            if currentCard.hasHint && !isShowingAnswer {
                                Button {
                                    // Show hint as alert or overlay
                                } label: {
                                    Label("Show Hint", systemImage: "lightbulb")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                            
                            Spacer()
                            
                            if !isShowingAnswer {
                                Button(action: {
                                    startTime = Date() // Begin timing for the answer
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        rotation += 180
                                        isShowingAnswer = true
                                    }
                                    // Prepare haptic feedback for answer ratings
                                    feedbackGenerator.prepare()
                                }) {
                                    Text("Show Answer")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 25)
                                        .background(currentCard.color.uiColor)
                                        .cornerRadius(15)
                                }
                                .padding(.bottom)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(currentCard.color.uiColor, lineWidth: 2)
                        )
                        .rotation3DEffect(
                            .degrees(isShowingAnswer ? 0 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .offset(offset)
                        .scaleEffect(scale)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if isShowingAnswer {
                                        offset = gesture.translation
                                        
                                        // Apply slight rotation based on drag
                                        let dragAngle = Double(gesture.translation.width / 300) * 10
                                        rotation = 180 + dragAngle
                                    }
                                }
                                .onEnded { gesture in
                                    if isShowingAnswer {
                                        // Determine confidence based on swipe direction and distance
                                        if gesture.translation.width > 150 {
                                            // Swipe right (easy)
                                            rateAndAdvance(rating: .easy)
                                        } else if gesture.translation.width < -150 {
                                            // Swipe left (again/hard)
                                            rateAndAdvance(rating: .again)
                                        } else if gesture.translation.height > 100 {
                                            // Swipe down (good)
                                            rateAndAdvance(rating: .good)
                                        } else if gesture.translation.height < -100 {
                                            // Swipe up (mark for later)
                                            markForLaterAndAdvance()
                                        } else {
                                            // Return to center
                                            withAnimation(.spring()) {
                                                offset = .zero
                                                rotation = 180
                                            }
                                        }
                                    }
                                }
                        )
                        .animation(.spring(), value: offset)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Rating buttons (only shown when answer is visible)
                    if isShowingAnswer {
                        VStack(spacing: 15) {
                            HStack {
                                Text("How well did you know this?")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    markForLaterAndAdvance()
                                } label: {
                                    Image(systemName: "bookmark")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(spacing: 10) {
                                ratingButton(rating: .again, label: "Again", color: .red)
                                ratingButton(rating: .hard, label: "Hard", color: .orange)
                                ratingButton(rating: .good, label: "Good", color: .blue)
                                ratingButton(rating: .easy, label: "Easy", color: .green)
                            }
                            
                            // Show when the card will next appear
                            if let dueDate = calculateNextDue(for: .good) {
                                Text("Next review: \(formatRelativeDate(dueDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .transition(.move(edge: .bottom))
                    }
                }
                .onAppear {
                    // Reset the review session on appear
                    sessionStartTime = Date()
                    reviewStats = ReviewSessionStats()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var sessionSummaryView: some View {
        ScrollView {
            VStack(spacing: 25) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Review Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You've reviewed \(reviewedCards) cards")
                    .font(.title2)
                
                summaryStatsView
                
                performanceChartView
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(width: 200)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    private var summaryStatsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                summaryStatCard(
                    title: "Again", 
                    value: "\(reviewStats.againCount)",
                    color: .red
                )
                
                summaryStatCard(
                    title: "Hard", 
                    value: "\(reviewStats.hardCount)",
                    color: .orange
                )
            }
            
            HStack {
                summaryStatCard(
                    title: "Good", 
                    value: "\(reviewStats.goodCount)",
                    color: .blue
                )
                
                summaryStatCard(
                    title: "Easy", 
                    value: "\(reviewStats.easyCount)",
                    color: .green
                )
            }
            
            HStack {
                summaryStatCard(
                    title: "Total Time", 
                    value: formatDuration(reviewStats.totalTime),
                    color: .purple
                )
                
                summaryStatCard(
                    title: "Avg. per Card", 
                    value: formatDuration(reviewStats.averageTimePerCard()),
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var performanceChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 8) {
                performanceBar(
                    value: reviewStats.againCount,
                    total: reviewStats.totalCards,
                    color: .red, 
                    label: "Again"
                )
                
                performanceBar(
                    value: reviewStats.hardCount,
                    total: reviewStats.totalCards,
                    color: .orange, 
                    label: "Hard"
                )
                
                performanceBar(
                    value: reviewStats.goodCount,
                    total: reviewStats.totalCards,
                    color: .blue, 
                    label: "Good"
                )
                
                performanceBar(
                    value: reviewStats.easyCount,
                    total: reviewStats.totalCards,
                    color: .green, 
                    label: "Easy"
                )
            }
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func performanceBar(value: Int, total: Int, color: Color, label: String) -> some View {
        let percentage = total > 0 ? CGFloat(value) / CGFloat(total) : 0
        let height = max(20, percentage * 120) // Scale for visualization
        
        return VStack {
            Text("\(value)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 30, height: height)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func summaryStatCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func ratingButton(rating: Flashcard.ReviewEntry.Rating, label: String, color: Color) -> some View {
        Button(action: {
            rateAndAdvance(rating: rating)
        }) {
            VStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(color)
                    .cornerRadius(10)
                
                if let dueDate = calculateNextDue(for: rating) {
                    Text(formatShortDate(dueDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func markForLaterAndAdvance() {
        feedbackGenerator.impactOccurred(intensity: 0.7)
        flashcardManager.toggleMarkForLater(for: currentCard)
        
        // Animate card away
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = CGSize(width: 0, height: -500)
            scale = 0.8
        }
        
        // Move to next card or end
        advanceToNextCard()
    }
    
    private func rateAndAdvance(rating: Flashcard.ReviewEntry.Rating) {
        // Calculate time taken to answer if we started timing
        var timeTaken: TimeInterval? = nil
        if let start = startTime {
            timeTaken = Date().timeIntervalSince(start)
        }
        
        // Provide haptic feedback based on rating
        switch rating {
        case .again:
            feedbackGenerator.impactOccurred(intensity: 0.8)
            reviewStats.againCount += 1
        case .hard:
            feedbackGenerator.impactOccurred(intensity: 0.5)
            reviewStats.hardCount += 1
        case .good:
            feedbackGenerator.impactOccurred(intensity: 0.3)
            reviewStats.goodCount += 1
        case .easy:
            feedbackGenerator.impactOccurred(intensity: 0.2)
            reviewStats.easyCount += 1
        }
        
        // Update card in manager
        flashcardManager.updateCard(for: currentCard, withRating: rating, timeTaken: timeTaken)
        reviewedCards += 1
        
        // Update session statistics
        if let time = timeTaken {
            reviewStats.totalTime += time
        }
        
        // Animate card away based on rating
        let offsetX: CGFloat
        switch rating {
        case .again:
            offsetX = -400
        case .hard:
            offsetX = -200
        case .good:
            offsetX = 200
        case .easy:
            offsetX = 400
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = CGSize(width: offsetX, height: 0)
            scale = 0.8
        }
        
        // Move to next card or end
        advanceToNextCard()
    }
    
    private func advanceToNextCard() {
        // Reset timing for next card
        startTime = nil
        
        // Move to next card or end session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isLastCard {
                withAnimation {
                    showEndOfReviewView = true
                }
            } else {
                // Reset for next card
                currentIndex += 1
                isShowingAnswer = false
                offset = .zero
                scale = 1.0
                rotation = 0
            }
        }
    }
    
    // Calculate the next due date based on the rating
    private func calculateNextDue(for rating: Flashcard.ReviewEntry.Rating) -> Date? {
        var simulatedCard = currentCard
        simulatedCard.updateWithRating(rating)
        return simulatedCard.dueDate
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct FlashcardReviewView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCards = [
            Flashcard(
                question: "What is the capital of France?",
                answer: "Paris",
                category: "Geography",
                color: .blue
            ),
            Flashcard(
                question: "What is photosynthesis?",
                answer: "The process by which green plants use sunlight to synthesize nutrients from carbon dioxide and water",
                category: "Science",
                color: .green
            )
        ]
        
        return FlashcardReviewView(cards: sampleCards)
    }
} 