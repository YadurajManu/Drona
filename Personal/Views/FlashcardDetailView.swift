//
//  FlashcardDetailView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct FlashcardDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    
    var flashcard: Flashcard
    
    @State private var isEditing = false
    @State private var editedQuestion: String = ""
    @State private var editedAnswer: String = ""
    @State private var editedCategory: String = ""
    @State private var editedColor: Flashcard.CardColor
    @State private var showDeleteConfirmation = false
    @State private var isShowingAnswer = false
    
    init(flashcard: Flashcard) {
        self.flashcard = flashcard
        
        // Initialize state variables
        _editedQuestion = State(initialValue: flashcard.question)
        _editedAnswer = State(initialValue: flashcard.answer)
        _editedCategory = State(initialValue: flashcard.category)
        _editedColor = State(initialValue: flashcard.color)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Card view
            if isEditing {
                editView
            } else {
                detailView
            }
            
            // Confidence rating footer
            if !isEditing {
                confidenceRatingView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(!isFormValid)
                    } else {
                        Menu {
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("Edit Flashcard", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete Flashcard", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                var updatedCard = flashcard
                                updatedCard.starred.toggle()
                                flashcardManager.toggleStar(for: flashcard)
                            }) {
                                Label(
                                    flashcard.starred ? "Remove Star" : "Star Card",
                                    systemImage: flashcard.starred ? "star.slash" : "star"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Flashcard"),
                message: Text("Are you sure you want to delete this flashcard? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteFlashcard()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var detailView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(flashcard.color.uiColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(flashcard.color.uiColor, lineWidth: 2)
                        )
                    
                    VStack(spacing: 20) {
                        if isShowingAnswer {
                            Text("Answer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            Text(flashcard.answer)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .animation(.easeInOut)
                        } else {
                            Text("Question")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            Text(flashcard.question)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .animation(.easeInOut)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isShowingAnswer.toggle()
                            }
                        }) {
                            Text(isShowingAnswer ? "Show Question" : "Show Answer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 25)
                                .background(flashcard.color.uiColor)
                                .cornerRadius(15)
                                .shadow(color: flashcard.color.uiColor.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.bottom)
                    }
                    .padding(.vertical, 10)
                }
                .frame(minHeight: 300)
                .padding(.horizontal)
                
                // Metadata
                VStack(alignment: .leading, spacing: 15) {
                    metadataRow(icon: "folder", title: "Category", value: flashcard.category)
                    
                    if flashcard.hasHint {
                        metadataRow(icon: "lightbulb", title: "Hint", value: flashcard.hint)
                    }
                    
                    metadataRow(
                        icon: "calendar",
                        title: "Created",
                        value: formatDate(flashcard.createdAt, style: .medium)
                    )
                    
                    if let lastReviewed = flashcard.lastReviewed {
                        metadataRow(
                            icon: "clock",
                            title: "Last Reviewed",
                            value: formatDate(lastReviewed, style: .medium)
                        )
                    }
                    
                    metadataRow(
                        icon: "calendar.badge.clock",
                        title: "Next Review Due",
                        value: formatDate(flashcard.dueDate, style: .medium)
                    )
                    
                    metadataRow(
                        icon: "repeat",
                        title: "Review Count",
                        value: "\(flashcard.reviewHistory.count)"
                    )
                    
                    metadataRow(
                        icon: "speedometer",
                        title: "Ease Factor",
                        value: String(format: "%.2f", flashcard.easeFactor)
                    )
                    
                    metadataRow(
                        icon: "calendar.day.timeline.right",
                        title: "Current Interval",
                        value: "\(flashcard.interval) day\(flashcard.interval == 1 ? "" : "s")"
                    )
                    
                    metadataRow(
                        icon: "star",
                        title: "Starred",
                        value: flashcard.starred ? "Yes" : "No"
                    )
                    
                    if flashcard.markedForLater {
                        metadataRow(
                            icon: "bookmark.fill",
                            title: "Marked for Later",
                            value: "Yes"
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if !flashcard.reviewHistory.isEmpty {
                    reviewHistorySection
                }
            }
            .padding(.vertical)
        }
    }
    
    private var editView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Question")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editedQuestion)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Answer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editedAnswer)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Category", text: $editedCategory)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Card Color")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(Flashcard.CardColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.uiColor)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: editedColor == color ? 2 : 0)
                                )
                                .padding(5)
                                .onTapGesture {
                                    editedColor = color
                                }
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    isEditing = false
                    
                    // Reset to original values
                    editedQuestion = flashcard.question
                    editedAnswer = flashcard.answer
                    editedCategory = flashcard.category
                    editedColor = flashcard.color
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.vertical)
        }
    }
    
    private var confidenceRatingView: some View {
        VStack(spacing: 15) {
            Text("How well do you know this card?")
                .font(.headline)
            
            HStack(spacing: 15) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        updateConfidence(level: level)
                    }) {
                        VStack {
                            Text("\(level)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(confidenceColor(level))
                                .cornerRadius(20)
                            
                            Text(confidenceLabel(level))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.bottom, 5)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func metadataRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
    
    private var reviewHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review History")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(flashcard.reviewHistory.indices.reversed(), id: \.self) { index in
                        let entry = flashcard.reviewHistory[index]
                        reviewHistoryCard(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func reviewHistoryCard(entry: Flashcard.ReviewEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ratingLabel(for: entry.rating)
                Spacer()
                Text(formatShortDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Interval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(entry.priorInterval)")
                            .font(.callout)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        
                        Text("\(entry.newInterval)")
                            .font(.callout)
                    }
                }
                
                Spacer()
                
                if let time = entry.timeTaken {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(time))
                            .font(.callout)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 155)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    private func ratingLabel(for rating: Flashcard.ReviewEntry.Rating) -> some View {
        switch rating {
        case .again:
            return Label("Again", systemImage: "xmark.circle")
                .foregroundColor(.red)
        case .hard:
            return Label("Hard", systemImage: "exclamationmark.circle")
                .foregroundColor(.orange)
        case .good:
            return Label("Good", systemImage: "checkmark.circle")
                .foregroundColor(.blue)
        case .easy:
            return Label("Easy", systemImage: "star.circle")
                .foregroundColor(.green)
        }
    }
    
    // MARK: - Helper Functions
    
    private var isFormValid: Bool {
        !editedQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveChanges() {
        var updatedCard = flashcard
        updatedCard.question = editedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCard.answer = editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCard.category = editedCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCard.color = editedColor
        
        flashcardManager.updateFlashcard(updatedCard)
        isEditing = false
    }
    
    private func deleteFlashcard() {
        flashcardManager.deleteFlashcard(flashcard)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func updateConfidence(level: Int) {
        flashcardManager.updateConfidence(for: flashcard, newLevel: level)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    private func confidenceColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .blue
        case 4: return .green
        case 5: return .purple
        default: return .gray
        }
    }
    
    private func confidenceLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Difficult"
        case 2: return "Hard"
        case 3: return "Good"
        case 4: return "Easy"
        case 5: return "Known"
        default: return ""
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return String(format: "%.0fs", interval)
        } else {
            return String(format: "%.0fm %.0fs", floor(interval / 60), interval.truncatingRemainder(dividingBy: 60))
        }
    }
}

struct FlashcardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCard = Flashcard(
            question: "What is photosynthesis?",
            answer: "The process by which green plants and some other organisms use sunlight to synthesize nutrients from carbon dioxide and water.",
            category: "Science",
            color: .green
        )
        
        return NavigationView {
            FlashcardDetailView(flashcard: sampleCard)
        }
    }
} 