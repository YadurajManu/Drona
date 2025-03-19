//
//  CoachSelectionView.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

struct CoachSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var coachManager = StudyCoachManager.shared
    
    @State private var selectedAvatar = StudyCoach.CoachAvatar.sage
    @State private var selectedPersonality = StudyCoach.CoachPersonality.supportive
    @State private var selectedSpecialty = StudyCoach.CoachSpecialty.generalLearning
    @State private var coachName = "Maya"
    
    @State private var currentStep = 0
    private let totalSteps = 4
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                    .padding(.horizontal)
                    .padding(.top)
                
                // Step content
                ScrollView {
                    VStack(spacing: 20) {
                        stepContent
                            .padding(.horizontal)
                            .padding(.vertical, 20)
                    }
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    if currentStep < totalSteps - 1 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Text("Next")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: createCoach) {
                            Text("Create Your Coach")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Customize Your Coach")
            .navigationBarItems(
                trailing: Button("Skip") {
                    // Just use the default coach
                    coachManager.createDefaultCoach()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            avatarSelectionStep
        case 2:
            specialtySelectionStep
        case 3:
            personalitySelectionStep
        default:
            EmptyView()
        }
    }
    
    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Meet Your Study Coach")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your personal AI study coach will help you develop effective study habits, provide learning insights, and create personalized study plans.")
                .foregroundColor(.secondary)
            
            Text("Let's customize your coach to match your learning style and preferences.")
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                coachFeatureRow(icon: "lightbulb.fill", color: .yellow, text: "Get personalized learning insights")
                coachFeatureRow(icon: "list.bullet.clipboard", color: .green, text: "Create effective study plans")
                coachFeatureRow(icon: "bolt.fill", color: .orange, text: "Stay motivated with daily check-ins")
                coachFeatureRow(icon: "chart.bar.fill", color: .purple, text: "Track your learning progress")
            }
            .padding(.top)
        }
    }
    
    private var avatarSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Coach's Look")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select an avatar for your study coach.")
                .foregroundColor(.secondary)
            
            TextField("Coach's Name", text: $coachName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                ForEach(StudyCoach.CoachAvatar.allCases, id: \.self) { avatar in
                    avatarOption(avatar: avatar)
                }
            }
            .padding(.top)
            
            Spacer()
        }
    }
    
    private var specialtySelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Coach's Specialty")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("What academic area should your coach specialize in?")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(StudyCoach.CoachSpecialty.allCases, id: \.self) { specialty in
                    specialtyOption(specialty: specialty)
                }
            }
            .padding(.top)
        }
    }
    
    private var personalitySelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Coach's Personality")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("What type of coaching style would you prefer?")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(StudyCoach.CoachPersonality.allCases, id: \.self) { personality in
                    personalityOption(personality: personality)
                }
            }
            .padding(.top)
        }
    }
    
    private func coachFeatureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
                .frame(width: 32)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
    
    private func avatarOption(avatar: StudyCoach.CoachAvatar) -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(avatar.primaryColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: avatar.fallbackSymbol)
                    .foregroundColor(avatar.primaryColor)
                    .font(.system(size: 30))
            }
            .overlay(
                Circle()
                    .stroke(selectedAvatar == avatar ? avatar.primaryColor : Color.clear, lineWidth: 3)
            )
            .onTapGesture {
                selectedAvatar = avatar
            }
            
            Text(avatar.rawValue)
                .font(.caption)
                .foregroundColor(selectedAvatar == avatar ? avatar.primaryColor : .secondary)
        }
    }
    
    private func specialtyOption(specialty: StudyCoach.CoachSpecialty) -> some View {
        Button(action: {
            selectedSpecialty = specialty
        }) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: specialty.iconName)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(specialty.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(specialty.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if selectedSpecialty == specialty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: selectedSpecialty == specialty ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), 
                            radius: 5, 
                            x: 0, 
                            y: 2)
            )
        }
    }
    
    private func personalityOption(personality: StudyCoach.CoachPersonality) -> some View {
        Button(action: {
            selectedPersonality = personality
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(personality.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(personality.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if selectedPersonality == personality {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: selectedPersonality == personality ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), 
                            radius: 5, 
                            x: 0, 
                            y: 2)
            )
        }
    }
    
    private func createCoach() {
        coachManager.customizeCoach(
            name: coachName.isEmpty ? "Maya" : coachName,
            specialty: selectedSpecialty,
            personality: selectedPersonality,
            avatar: selectedAvatar
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CoachSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CoachSelectionView()
    }
} 