//
//  StudyCoachView.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

struct StudyCoachView: View {
    @ObservedObject private var coachManager = StudyCoachManager.shared
    @State private var messageText = ""
    @State private var showCoachSelection = false
    @State private var showTopicSelection = false
    @State private var selectedTopic = ""
    @State private var showInsightsView = false
    @State private var showPlansView = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let suggestedTopics = [
        "Study technique advice",
        "Time management help",
        "How to stay motivated",
        "Test preparation",
        "Memory improvement",
        "Note-taking strategies",
        "Concentration tips"
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top bar with coach info
                coachInfoBar
                
                // Messages area
                messagesView
                    .padding(.horizontal)
                
                // Bottom input area
                inputBar
            }
            
            // Floating action button for menu
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            showInsightsView = true
                        }) {
                            Label("Learning Insights", systemImage: "lightbulb")
                        }
                        
                        Button(action: {
                            showPlansView = true
                        }) {
                            Label("Study Plans", systemImage: "list.bullet.clipboard")
                        }
                        
                        Button(action: {
                            showCoachSelection = true
                        }) {
                            Label("Change Coach", systemImage: "person.crop.circle.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .padding(12)
                            .background(Circle().fill(Color.blue))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    }
                    .padding([.trailing, .bottom], 80) // Move button away from the send area
                }
            }
        }
        .onAppear {
            // If no active conversation, show topic selection
            if coachManager.currentInteraction == nil {
                showTopicSelection = true
            }
        }
        .sheet(isPresented: $showCoachSelection) {
            CoachSelectionView()
        }
        .sheet(isPresented: $showTopicSelection) {
            TopicSelectionView(selectedTopic: $selectedTopic, isPresented: $showTopicSelection)
                .onDisappear {
                    if !selectedTopic.isEmpty {
                        startNewConversation(topic: selectedTopic)
                    }
                }
        }
        .sheet(isPresented: $showInsightsView) {
            StudyInsightsView()
        }
        .sheet(isPresented: $showPlansView) {
            StudyPlansView()
        }
    }
    
    private var coachInfoBar: some View {
        HStack {
            if let coach = coachManager.activeCoach {
                // Coach avatar
                ZStack {
                    Circle()
                        .fill(coach.avatar.primaryColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: coach.avatar.fallbackSymbol)
                        .foregroundColor(coach.avatar.primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coach.name)
                        .font(.headline)
                    
                    Text(coach.specialty.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak counter
                if coachManager.streakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        
                        Text("\(coachManager.streakDays)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showTopicSelection = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            } else {
                Text("Choose a Study Coach")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showCoachSelection = true
                }) {
                    Text("Select")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                // Extract content to separate views
                if let interaction = coachManager.currentInteraction {
                    MessageListContent(
                        interaction: interaction,
                        isGenerating: coachManager.isGeneratingResponse,
                        coach: coachManager.activeCoach
                    )
                } else {
                    EmptyConversationView(showTopicSelection: $showTopicSelection)
                }
            }
            .padding(.vertical)
            .onChange(of: coachManager.currentInteraction?.messages.count) { _ in
                if let lastID = coachManager.currentInteraction?.messages.last?.id {
                    withAnimation {
                        scrollView.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: coachManager.isGeneratingResponse) { _ in
                if coachManager.isGeneratingResponse {
                    DispatchQueue.main.async {
                        let typingID = coachManager.currentInteraction?.messages.last?.id ?? UUID()
                        withAnimation {
                            scrollView.scrollTo(typingID, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color("BackgroundColor"))
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    // Extract message list to its own view
    private struct MessageListContent: View {
        let interaction: StudyCoach.CoachInteraction
        let isGenerating: Bool
        let coach: StudyCoach?
        
        var body: some View {
            LazyVStack(spacing: 15) {
                ForEach(interaction.messages) { message in
                    CoachMessageBubble(message: message, coach: coach)
                        .id(message.id)
                }
                
                if isGenerating {
                    TypingIndicatorView(coach: coach)
                        .id(UUID())  // Use UUID instead of string
                }
            }
        }
    }
    
    // Custom message bubble specifically for coach messages
    private struct CoachMessageBubble: View {
        let message: StudyCoach.CoachInteraction.CoachMessage
        let coach: StudyCoach?
        
        var body: some View {
            HStack {
                if message.isFromCoach {
                    coachAvatar
                        .padding(.trailing, 6)
                    
                    messageBubble
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(coach?.avatar.primaryColor.opacity(0.1) ?? Color.blue.opacity(0.1))
                        )
                    
                    Spacer(minLength: 40)
                } else {
                    Spacer(minLength: 40)
                    
                    messageBubble
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                }
            }
        }
        
        private var messageBubble: some View {
            Text(message.content)
                .padding(12)
                .cornerRadius(18)
        }
        
        private var coachAvatar: some View {
            ZStack {
                Circle()
                    .fill(coach?.avatar.primaryColor.opacity(0.2) ?? Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: coach?.avatar.fallbackSymbol ?? "person.circle")
                    .foregroundColor(coach?.avatar.primaryColor ?? Color.blue)
                    .font(.system(size: 16))
            }
        }
    }
    
    // Extract typing indicator to its own view
    private struct TypingIndicatorView: View {
        let coach: StudyCoach?
        
        var body: some View {
            HStack(alignment: .bottom, spacing: 2) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(coach?.avatar.primaryColor.opacity(0.1) ?? Color.blue.opacity(0.1))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            TypingCircle(delay: Double(index) * 0.2)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(width: 50, height: 30)
            }
            .padding(.trailing)
        }
    }
    
    // Helper view to prevent complex type-checking
    private struct TypingCircle: View {
        let delay: Double
        @State private var animating = false
        
        var body: some View {
            Circle()
                .fill(StudyCoachManager.shared.activeCoach?.avatar.primaryColor ?? Color.blue)
                .frame(width: 6, height: 6)
                .offset(y: animating ? -2 : 2)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(delay)
                    ) {
                        animating.toggle()
                    }
                }
        }
    }
    
    // Extract empty state to its own view
    private struct EmptyConversationView: View {
        @Binding var showTopicSelection: Bool
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.7))
                
                Text("Start a conversation with your study coach")
                    .font(.headline)
                
                Text("Get personalized learning advice, study plans, and motivation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showTopicSelection = true
                }) {
                    Text("New Conversation")
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
            .padding()
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text field with more specific sizing and onSubmit handler
            TextField("Message your coach...", text: $messageText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isTextFieldFocused)
                .frame(minHeight: 44)
                .onSubmit {
                    sendMessage()
                }
                .submitLabel(.send)
            
            // Send button with fixed size
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.trailing, 4) // Add extra padding to the right for better separation
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    private func startNewConversation(topic: String) {
        coachManager.startInteraction(topic: topic)
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            coachManager.sendMessage(trimmedMessage)
            messageText = ""
        }
        isTextFieldFocused = false
    }
}

struct TopicSelectionView: View {
    @Binding var selectedTopic: String
    @Binding var isPresented: Bool
    @State private var customTopic = ""
    
    let suggestedTopics = [
        "Study techniques",
        "How to stay motivated",
        "Note-taking strategies",
        "Time management",
        "Test preparation",
        "Memory improvement",
        "Learning styles",
        "Concentration tips",
        "Study plan creation",
        "Dealing with stress"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What would you like to discuss?")
                    .font(.headline)
                    .padding(.top)
                
                TextField("Enter a topic or question", text: $customTopic)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Text("Or select a suggested topic:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(suggestedTopics, id: \.self) { topic in
                            Button(action: {
                                selectedTopic = topic
                                isPresented = false
                            }) {
                                HStack {
                                    Text(topic)
                                        .foregroundColor(.primary)
                                        .padding(.leading)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .padding(.trailing)
                                }
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    if !customTopic.isEmpty {
                        selectedTopic = customTopic
                    } else {
                        selectedTopic = "General study advice"
                    }
                    isPresented = false
                }) {
                    Text("Start Conversation")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitle("New Conversation", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
}

struct StudyCoachView_Previews: PreviewProvider {
    static var previews: some View {
        StudyCoachView()
    }
} 
