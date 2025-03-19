//
//  OnboardingView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = 18
    @State private var educationLevel = UserProfile.EducationLevel.highSchool
    @State private var selectedInterests: Set<UserProfile.Interest> = []
    @State private var selectedTopics: Set<UserProfile.DoubtCategory> = []
    @State private var bio = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var showingProfile = false
    @State private var animationAmount = 1.0
    @State private var slideOffset: CGFloat = 0
    @State private var fadeInOpacity = 0.0
    
    private let totalSteps = 6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                        .padding(.top, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 25) {
                            // Step title and description
                            stepHeader
                                .padding(.top, 30)
                            
                            // Step content
                            stepContent(geometry: geometry)
                                .padding(.horizontal)
                                .offset(x: slideOffset)
                                .opacity(fadeInOpacity)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                        }
                        .padding(.bottom, keyboardHeight)
                    }
                    
                    // Navigation buttons
                    navigationButtons
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                fadeInOpacity = 1.0
            }
        }
        .onChange(of: currentStep) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                slideOffset = 0
                fadeInOpacity = 1.0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                colorScheme == .dark ? Color.purple.opacity(0.2) : Color.blue.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                    .animation(.spring(), value: currentStep)
            }
        }
        .padding(.horizontal)
    }
    
    private var stepHeader: some View {
        VStack(spacing: 12) {
            Text(stepTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text(stepDescription)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Welcome to Drona! 👋"
        case 1: return "What's your name?"
        case 2: return "Your Age"
        case 3: return "Education Level"
        case 4: return "Your Interests"
        case 5: return "Learning Goals"
        default: return "Tell us about yourself"
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 0: return "Your personal AI learning companion that adapts to your unique educational journey"
        case 1: return "Let's start with your name so we can personalize your experience"
        case 2: return "This helps us tailor content to your age group"
        case 3: return "We'll customize your learning experience based on your education level"
        case 4: return "Select topics that interest you the most"
        case 5: return "What would you like to learn about?"
        default: return "Share a bit about your learning goals and aspirations"
        }
    }
    
    @ViewBuilder
    private func stepContent(geometry: GeometryProxy) -> some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            nameStep
        case 2:
            ageStep
        case 3:
            educationStep
        case 4:
            interestsStep
        case 5:
            topicsStep
        default:
            bioStep
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .scaleEffect(animationAmount)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.5)
                    .repeatForever(autoreverses: true),
                    value: animationAmount
                )
                .onAppear {
                    animationAmount = 1.2
                }
            
            FeatureCard(
                icon: "brain.head.profile",
                title: "Personalized Learning",
                description: "AI-powered tutoring tailored to your needs"
            )
            
            FeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Track Progress",
                description: "Monitor your learning journey with detailed insights"
            )
            
            FeatureCard(
                icon: "person.2.fill",
                title: "24/7 Support",
                description: "Get help whenever you need it"
            )
        }
        .padding(.vertical)
    }
    
    private var nameStep: some View {
        VStack(spacing: 20) {
            TextField("", text: $name)
                .placeholder(when: name.isEmpty) {
                    Text("Enter your name")
                        .foregroundColor(.gray)
                }
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
        }
    }
    
    private var ageStep: some View {
        VStack(spacing: 30) {
            Text("\(age)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            HStack(spacing: 20) {
                Button(action: { if age > 13 { age -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
                
                Slider(value: .init(
                    get: { Double(age) },
                    set: { age = Int($0) }
                ), in: 13...100, step: 1)
                .accentColor(.blue)
                
                Button(action: { if age < 100 { age += 1 } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
    
    private var educationStep: some View {
        VStack(spacing: 15) {
            ForEach(UserProfile.EducationLevel.allCases, id: \.self) { level in
                EducationLevelButton(
                    level: level,
                    isSelected: educationLevel == level,
                    action: { educationLevel = level }
                )
            }
        }
        .padding()
    }
    
    private var interestsStep: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(UserProfile.Interest.allCases, id: \.self) { interest in
                    InterestButton(
                        interest: interest,
                        isSelected: selectedInterests.contains(interest),
                        action: {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var topicsStep: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(UserProfile.DoubtCategory.allCases, id: \.self) { topic in
                    TopicButton(
                        topic: topic,
                        isSelected: selectedTopics.contains(topic),
                        action: {
                            if selectedTopics.contains(topic) {
                                selectedTopics.remove(topic)
                            } else {
                                selectedTopics.insert(topic)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var bioStep: some View {
        VStack(spacing: 20) {
            TextEditor(text: $bio)
                .frame(height: 150)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if currentStep > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Next")
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    isStepValid ? Color.blue : Color.gray
                )
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .disabled(!isStepValid)
        }
        .padding()
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return age >= 13 && age <= 100
        case 3: return true
        case 4: return !selectedInterests.isEmpty
        case 5: return !selectedTopics.isEmpty
        default: return true
        }
    }
    
    private func previousStep() {
        withAnimation {
            slideOffset = 50
            fadeInOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentStep -= 1
            slideOffset = -50
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                slideOffset = 0
                fadeInOpacity = 1
            }
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                slideOffset = -50
                fadeInOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStep += 1
                slideOffset = 50
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    slideOffset = 0
                    fadeInOpacity = 1
                }
            }
        } else {
            createProfile()
        }
    }
    
    private func createProfile() {
        let profile = UserProfile(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: age,
            educationLevel: educationLevel,
            interests: Array(selectedInterests),
            preferredTopics: Array(selectedTopics),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        userProfileManager.saveProfile(profile)
    }
}

// MARK: - Supporting Views

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EducationLevelButton: View {
    let level: UserProfile.EducationLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: educationIcon(for: level))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                Text(level.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func educationIcon(for level: UserProfile.EducationLevel) -> String {
        switch level {
        case .highSchool:
            return "1.circle.fill"
        case .undergrad:
            return "2.circle.fill"
        case .postgrad:
            return "3.circle.fill"
        case .other:
            return "4.circle.fill"
        }
    }
}

struct InterestButton: View {
    let interest: UserProfile.Interest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: interestIcon(for: interest))
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(interest.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func interestIcon(for interest: UserProfile.Interest) -> String {
        switch interest {
        case .science: return "atom"
        case .technology: return "desktopcomputer"
        case .engineering: return "gear"
        case .mathematics: return "function"
        case .arts: return "paintpalette"
        case .literature: return "book"
        case .music: return "music.note"
        case .sports: return "sportscourt"
        case .finance: return "chart.bar"
        case .other: return "ellipsis"
        }
    }
}

struct TopicButton: View {
    let topic: UserProfile.DoubtCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: topicIcon(for: topic))
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : topicColor(for: topic))
                
                Text(topic.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? topicColor(for: topic) : topicColor(for: topic).opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func topicIcon(for topic: UserProfile.DoubtCategory) -> String {
        switch topic {
        case .academic: return "book.fill"
        case .personal: return "person.fill"
        case .financial: return "dollarsign.circle.fill"
        case .social: return "person.3.fill"
        case .relational: return "heart.fill"
        case .career: return "briefcase.fill"
        }
    }
    
    private func topicColor(for topic: UserProfile.DoubtCategory) -> Color {
        switch topic {
        case .academic: return .blue
        case .personal: return .purple
        case .financial: return .green
        case .social: return .orange
        case .relational: return .pink
        case .career: return .indigo
        }
    }
}

// MARK: - View Extensions

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserProfileManager())
    }
} 