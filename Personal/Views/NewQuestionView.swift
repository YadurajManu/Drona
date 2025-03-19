//
//  NewQuestionView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct NewQuestionView: View {
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var questionText = ""
    @State private var selectedCategory: UserProfile.DoubtCategory = .academic
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var animateGradient = false
    
    // For navigating to created conversation
    @State private var navigateToConversation = false
    
    // Optional preselected category passed from other views
    var preselectedCategory: UserProfile.DoubtCategory?
    
    // Suggested question examples
    private let questionExamples: [UserProfile.DoubtCategory: [String]] = [
        .academic: [
            "How can I improve my understanding of calculus?",
            "What are effective study techniques for memorizing facts?",
            "Can you explain the concept of photosynthesis?"
        ],
        .personal: [
            "How can I build better habits for productivity?",
            "What are ways to reduce stress and anxiety?",
            "How do I improve my self-confidence?"
        ],
        .financial: [
            "How should I start budgeting as a student?",
            "What are good ways to save money while in college?",
            "Can you explain how student loans work?"
        ],
        .social: [
            "How can I make new friends at school?",
            "What are good ways to resolve conflicts with peers?",
            "How do I improve my communication skills?"
        ],
        .relational: [
            "How can I deal with disagreements with my parents?",
            "What are signs of a healthy friendship?",
            "How do I maintain balance between relationships and studies?"
        ],
        .career: [
            "What career paths align with my interests in technology?",
            "How do I create an effective resume?",
            "What skills are most valuable for my future career?"
        ]
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Category selection
                        categorySelectionView
                        
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Brief title for your question", text: $title)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .autocapitalization(.sentences)
                        }
                        
                        // Question field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Question")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            suggestedQuestionExamples
                            
                            ZStack(alignment: .topLeading) {
                                if questionText.isEmpty {
                                    Text("Type your question here...")
                                        .foregroundColor(.gray.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.top, 12)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $questionText)
                                    .frame(minHeight: 150)
                                    .padding(4)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        Spacer(minLength: 30)
                        
                        // Submit button
                        Button(action: submitQuestion) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18))
                                        .padding(.trailing, 5)
                                }
                                
                                Text(isSubmitting ? "Submitting..." : "Submit Question")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(submitButtonBackground)
                            .cornerRadius(15)
                            .shadow(
                                color: isFormInvalid ? Color.clear : categoryColor(for: selectedCategory).opacity(0.3),
                                radius: 5, x: 0, y: 3
                            )
                            .onAppear {
                                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                                    animateGradient.toggle()
                                }
                            }
                        }
                        .disabled(isFormInvalid || isSubmitting)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ask Drona")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                if let category = preselectedCategory {
                    selectedCategory = category
                }
            }
            // Navigation to the conversation detail after creation
            .background(
                NavigationLink(
                    destination: Group {
                        if let conversation = conversationManager.currentConversation {
                            ConversationDetailView(conversation: conversation)
                                .environmentObject(conversationManager)
                                .environmentObject(userProfileManager)
                        }
                    },
                    isActive: $navigateToConversation,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    private var categorySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(UserProfile.DoubtCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            
            categoryDescription
        }
    }
    
    private var categoryDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                categoryIcon
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(categoryColor(for: selectedCategory))
                    .cornerRadius(8)
                
                Text(selectedCategory.rawValue)
                    .font(.headline)
                    .foregroundColor(categoryColor(for: selectedCategory))
            }
            
            Text(descriptionForCategory(selectedCategory))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var suggestedQuestionExamples: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Example questions:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(questionExamples[selectedCategory, default: []], id: \.self) { example in
                    Button {
                        questionText = example
                    } label: {
                        HStack(alignment: .top) {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(categoryColor(for: selectedCategory))
                                .font(.system(size: 14))
                                .frame(width: 20)
                            
                            Text(example)
                                .foregroundColor(.primary)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var categoryIcon: some View {
        switch selectedCategory {
        case .academic:
            return Image(systemName: "book.fill")
        case .personal:
            return Image(systemName: "person.fill")
        case .financial:
            return Image(systemName: "dollarsign.circle.fill")
        case .social:
            return Image(systemName: "person.3.fill")
        case .relational:
            return Image(systemName: "heart.fill")
        case .career:
            return Image(systemName: "briefcase.fill")
        }
    }
    
    private func categoryColor(for category: UserProfile.DoubtCategory) -> Color {
        switch category {
        case .academic:
            return .blue
        case .personal:
            return .purple
        case .financial:
            return .green
        case .social:
            return .orange
        case .relational:
            return .pink
        case .career:
            return .indigo
        }
    }
    
    private var isFormInvalid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedTitle.isEmpty || trimmedQuestion.isEmpty
    }
    
    private func descriptionForCategory(_ category: UserProfile.DoubtCategory) -> String {
        switch category {
        case .academic:
            return "Questions related to studies, subjects, academic concepts, or educational challenges."
        case .personal:
            return "Questions about personal growth, self-improvement, habits, and life choices."
        case .financial:
            return "Questions about money management, budgeting, saving, or financial planning."
        case .social:
            return "Questions about friendships, social situations, networking, or community involvement."
        case .relational:
            return "Questions about relationships with family, friends, romantic partners, or colleagues."
        case .career:
            return "Questions about career planning, professional development, job searching, or workplace challenges."
        }
    }
    
    private func submitQuestion() {
        guard !isFormInvalid else { return }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isSubmitting = true
        
        // Start new conversation
        conversationManager.startNewConversation(
            title: trimmedTitle,
            category: selectedCategory,
            initialQuestion: trimmedQuestion,
            userProfile: userProfileManager.userProfile
        ) { success in
            isSubmitting = false
            
            if success {
                // Navigate to the newly created conversation
                navigateToConversation = true
            } else {
                // Show error alert
                alertMessage = "There was an error submitting your question. Please try again."
                showAlert = true
            }
        }
    }
    
    private var submitButtonBackground: some View {
        Group {
            if isFormInvalid {
                Color.gray.opacity(0.3)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        categoryColor(for: selectedCategory),
                        categoryColor(for: selectedCategory).opacity(0.8)
                    ]),
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            }
        }
    }
}

struct CategoryButton: View {
    let category: UserProfile.DoubtCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                categoryIcon
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : categoryColor)
                
                Text(category.rawValue)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(isSelected ? categoryColor : Color(.systemGray6))
            )
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .academic: return .blue
        case .personal: return .purple
        case .financial: return .green
        case .social: return .orange
        case .relational: return .pink
        case .career: return .indigo
        }
    }
    
    private var categoryIcon: some View {
        switch category {
        case .academic:
            return Image(systemName: "book.fill")
        case .personal:
            return Image(systemName: "person.fill")
        case .financial:
            return Image(systemName: "dollarsign.circle.fill")
        case .social:
            return Image(systemName: "person.3.fill")
        case .relational:
            return Image(systemName: "heart.fill")
        case .career:
            return Image(systemName: "briefcase.fill")
        }
    }
} 