//
//  ProfileView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var showingEditProfileSheet = false
    @State private var showingLogoutAlert = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if let profile = userProfileManager.userProfile {
                    profileHeaderSection(profile: profile)
                    
                    educationSection(profile: profile)
                    
                    interestsSection(profile: profile)
                    
                    topicsSection(profile: profile)
                    
                    aboutSection(profile: profile)
                    
                    Section {
                        Button(action: { showingEditProfileSheet = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        NavigationLink(destination: FlashcardsHomeView()) {
                            HStack {
                                Image(systemName: "rectangle.stack.fill")
                                Text("My Flashcards")
                            }
                            .foregroundColor(.orange)
                        }
                        
                        NavigationLink(destination: DronaSettingsView()) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Drona Settings")
                            }
                        }
                        
                        NavigationLink(destination: DataManagementView().environmentObject(userProfileManager)) {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("Data & Privacy")
                            }
                        }
                        
                        Button(action: { showingExportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                
                                Text("Export Your Data")
                                    .foregroundColor(.green)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Button(action: { backupProfile() }) {
                            HStack {
                                Image(systemName: "externaldrive.badge.checkmark")
                                Text("Backup Profile")
                            }
                            .foregroundColor(.purple)
                        }
                        
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Your Profile")
            .sheet(isPresented: $showingEditProfileSheet) {
                if let profile = userProfileManager.userProfile {
                    EditProfileView(profile: profile)
                        .environmentObject(userProfileManager)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                DataExportView()
                    .environmentObject(userProfileManager)
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to sign out? All your conversations and settings will be cleared.")
            }
        }
    }
    
    private func logout() {
        // Track logout event
        UserActivityManager.shared.trackLogout()
        
        // Clear all user data
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.removeObject(forKey: "dronaResponseLength")
        UserDefaults.standard.removeObject(forKey: "dronaResponseTone")
        UserDefaults.standard.removeObject(forKey: "dronaExampleDetail")
        UserDefaults.standard.removeObject(forKey: "dronaUseFormalLanguage")
        UserDefaults.standard.removeObject(forKey: "dronaPrimaryChatColor")
        UserDefaults.standard.removeObject(forKey: "dronaShowSourcesInResponse")
        UserDefaults.standard.removeObject(forKey: "dronaAutoSuggestQuestions")
        UserDefaults.standard.removeObject(forKey: "dronaShowTypingAnimation")
        
        // Clear conversation history
        ConversationManager.shared.clearAllConversations()
        
        // Clear user activity data
        UserActivityManager.shared.clearActivityData()
        
        // Clear cache if any
        clearAppCache()
        
        // Reset the profile in the manager
        userProfileManager.clearProfile()
    }
    
    private func clearAppCache() {
        // Clear temporary files
        let fileManager = FileManager.default
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        
        do {
            let tempContents = try fileManager.contentsOfDirectory(
                at: tempDirectoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for file in tempContents {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing cache: \(error.localizedDescription)")
        }
    }
    
    private func profileHeaderSection(profile: UserProfile) -> some View {
        Section {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 70, height: 70)
                    
                    Text(String(profile.name.prefix(1).uppercased()))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(profile.age) years old")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func educationSection(profile: UserProfile) -> some View {
        Section(header: Text("Education")) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.blue)
                    .frame(width: 26, height: 26)
                
                Text(profile.educationLevel.rawValue)
            }
        }
    }
    
    private func interestsSection(profile: UserProfile) -> some View {
        Section(header: Text("Interests")) {
            if profile.interests.isEmpty {
                Text("No interests selected")
                    .foregroundColor(.secondary)
            } else {
                ForEach(profile.interests, id: \.self) { interest in
                    HStack {
                        InterestIcon(interest: interest)
                            .foregroundColor(.blue)
                            .frame(width: 26, height: 26)
                        
                        Text(interest.rawValue)
                    }
                }
            }
        }
    }
    
    private func topicsSection(profile: UserProfile) -> some View {
        Section(header: Text("Preferred Topics")) {
            if profile.preferredTopics.isEmpty {
                Text("No topics selected")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                    ForEach(profile.preferredTopics, id: \.self) { topic in
                        TopicChip(category: topic)
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
    
    private func aboutSection(profile: UserProfile) -> some View {
        Section(header: Text("About")) {
            Text(profile.bio.isEmpty ? "No bio information provided" : profile.bio)
                .font(.subheadline)
                .foregroundColor(profile.bio.isEmpty ? .secondary : .primary)
        }
    }
    
    private func exportUserData() {
        showingExportSheet = true
    }
    
    private func backupProfile() {
        guard let profile = userProfileManager.userProfile else { return }
        
        // Create backup entry in UserDefaults
        if let profileData = try? JSONEncoder().encode(profile) {
            let backupKey = "dronaProfileBackup_\(Date().timeIntervalSince1970)"
            UserDefaults.standard.set(profileData, forKey: backupKey)
            
            // Store list of backups
            var backupsList = UserDefaults.standard.stringArray(forKey: "dronaProfileBackupsList") ?? []
            backupsList.append(backupKey)
            UserDefaults.standard.set(backupsList, forKey: "dronaProfileBackupsList")
            
            print("Profile backed up successfully")
        }
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    @State private var name: String
    @State private var age: Int
    @State private var educationLevel: UserProfile.EducationLevel
    @State private var selectedInterests: [UserProfile.Interest]
    @State private var selectedTopics: [UserProfile.DoubtCategory]
    @State private var bio: String
    
    private let originalProfile: UserProfile
    
    init(profile: UserProfile) {
        self.originalProfile = profile
        _name = State(initialValue: profile.name)
        _age = State(initialValue: profile.age)
        _educationLevel = State(initialValue: profile.educationLevel)
        _selectedInterests = State(initialValue: profile.interests)
        _selectedTopics = State(initialValue: profile.preferredTopics)
        _bio = State(initialValue: profile.bio)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    
                    Stepper("Age: \(age)", value: $age, in: 13...100)
                }
                
                Section(header: Text("Education")) {
                    Picker("Education Level", selection: $educationLevel) {
                        ForEach(UserProfile.EducationLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section(header: Text("Interests")) {
                    ForEach(UserProfile.Interest.allCases, id: \.self) { interest in
                        MultiSelectionRow(title: interest.rawValue,
                                          isSelected: selectedInterests.contains(interest)) {
                            if selectedInterests.contains(interest) {
                                selectedInterests.removeAll(where: { $0 == interest })
                            } else {
                                selectedInterests.append(interest)
                            }
                        }
                    }
                }
                
                Section(header: Text("Preferred Topics")) {
                    ForEach(UserProfile.DoubtCategory.allCases, id: \.self) { topic in
                        MultiSelectionRow(title: topic.rawValue,
                                          isSelected: selectedTopics.contains(topic)) {
                            if selectedTopics.contains(topic) {
                                selectedTopics.removeAll(where: { $0 == topic })
                            } else {
                                selectedTopics.append(topic)
                            }
                        }
                    }
                }
                
                Section(header: Text("About You")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func saveProfile() {
        let updatedProfile = UserProfile(
            id: originalProfile.id,
            name: name.trimmingCharacters(in: .whitespaces),
            age: age,
            educationLevel: educationLevel,
            interests: selectedInterests,
            preferredTopics: selectedTopics,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        userProfileManager.updateProfile(updatedProfile)
        presentationMode.wrappedValue.dismiss()
    }
}

struct InterestIcon: View {
    let interest: UserProfile.Interest
    
    var body: some View {
        switch interest {
        case .science:
            return Image(systemName: "atom")
        case .technology:
            return Image(systemName: "desktopcomputer")
        case .engineering:
            return Image(systemName: "gear")
        case .mathematics:
            return Image(systemName: "function")
        case .arts:
            return Image(systemName: "paintpalette")
        case .literature:
            return Image(systemName: "book")
        case .music:
            return Image(systemName: "music.note")
        case .sports:
            return Image(systemName: "sportscourt")
        case .finance:
            return Image(systemName: "chart.bar")
        case .other:
            return Image(systemName: "ellipsis")
        }
    }
}

struct TopicChip: View {
    let category: UserProfile.DoubtCategory
    
    var body: some View {
        HStack {
            Image(systemName: iconName(for: category))
            Text(category.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color(for: category).opacity(0.15))
        .foregroundColor(color(for: category))
        .cornerRadius(15)
    }
    
    private func iconName(for category: UserProfile.DoubtCategory) -> String {
        switch category {
        case .academic:
            return "book.fill"
        case .personal:
            return "person.fill"
        case .financial:
            return "dollarsign.circle.fill"
        case .social:
            return "person.3.fill"
        case .relational:
            return "heart.fill"
        case .career:
            return "briefcase.fill"
        }
    }
    
    private func color(for category: UserProfile.DoubtCategory) -> Color {
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
}

struct MultiSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
} 