//
//  DataManagementView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct DataManagementView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var showingRestoreBackupSheet = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPrivacyPolicySheet = false
    @State private var showingClearConversationsAlert = false
    @State private var backupsList: [BackupInfo] = []
    @State private var selectedBackupId: String?
    
    struct BackupInfo: Identifiable {
        let id: String
        let date: Date
        let profileName: String
    }
    
    var body: some View {
        Form {
            Section(header: Text("Data Management")) {
                Button(action: { showingClearConversationsAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Conversations")
                    }
                    .foregroundColor(.red)
                }
                
                Button(action: clearCachedData) {
                    HStack {
                        Image(systemName: "trash.slash")
                        Text("Clear Cached Data")
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Section(header: Text("Backup & Restore")) {
                NavigationLink(destination: backupListView) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View Backups")
                    }
                }
                
                Button(action: { refreshBackupsList() }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Backups List")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("Privacy & Security")) {
                Button(action: { showingPrivacyPolicySheet = true }) {
                    HStack {
                        Image(systemName: "lock.shield")
                        Text("Privacy Policy")
                    }
                }
                
                NavigationLink(destination: UserAnalyticsView()) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Learning Insights")
                    }
                }
                
                NavigationLink(destination: Text("Data Usage Information")) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Data Usage")
                    }
                }
                
                Toggle("Restrict Sensitive Data Sharing", isOn: .constant(true))
                    .foregroundColor(.primary)
            }
            
            Section(header: Text("Account Management")) {
                Button(action: { showingDeleteAccountAlert = true }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                        Text("Delete Account & Data")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Data & Privacy")
        .onAppear {
            refreshBackupsList()
        }
        .alert("Clear All Conversations", isPresented: $showingClearConversationsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                ConversationManager.shared.clearAllConversations()
            }
        } message: {
            Text("This will remove all your conversation history. This action cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your profile and all associated data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingPrivacyPolicySheet) {
            privacyPolicyView
        }
    }
    
    private var backupListView: some View {
        List {
            ForEach(backupsList) { backup in
                VStack(alignment: .leading) {
                    Text(backup.profileName)
                        .font(.headline)
                    Text(dateFormatter.string(from: backup.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedBackupId = backup.id
                    // Show restore confirmation
                    showRestoreConfirmation(for: backup)
                }
            }
            .onDelete(perform: deleteBackups)
        }
        .navigationTitle("Saved Backups")
        .overlay(
            Group {
                if backupsList.isEmpty {
                    VStack {
                        Image(systemName: "externaldrive.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Backups Found")
                            .font(.headline)
                            .padding(.top)
                        Text("Backups you create will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
    }
    
    private var privacyPolicyView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Group {
                        Text("Data Collection")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Drona collects only the information you provide during profile creation. This includes your name, age, education level, interests, preferred topics, and optional bio. This information is stored locally on your device and is not transmitted to our servers unless you explicitly share your data.")
                    }
                    
                    Group {
                        Text("Data Usage")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("The information you provide is used exclusively to personalize your experience with Drona. Your conversations with Drona are processed using privacy-preserving techniques.")
                    }
                    
                    Group {
                        Text("Data Storage")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your profile information and conversation history are stored locally on your device. You can export, backup, or delete this data at any time from the Data Management screen.")
                    }
                    
                    Group {
                        Text("Third-Party Services")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Drona uses Google's Gemini API to process your questions and generate responses. When you interact with Drona, your questions and relevant context from your profile may be sent to Google's servers for processing. Google's privacy policy applies to this data processing.")
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") {
                showingPrivacyPolicySheet = false
            })
        }
    }
    
    private func refreshBackupsList() {
        // Get list of backup keys
        guard let backupKeys = UserDefaults.standard.stringArray(forKey: "dronaProfileBackupsList") else {
            backupsList = []
            return
        }
        
        // Parse backup information
        backupsList = backupKeys.compactMap { key in
            guard let profileData = UserDefaults.standard.data(forKey: key),
                  let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData),
                  let dateString = key.split(separator: "_").last,
                  let timestamp = Double(dateString) else {
                return nil
            }
            
            let date = Date(timeIntervalSince1970: timestamp)
            return BackupInfo(id: key, date: date, profileName: profile.name)
        }
        .sorted { $0.date > $1.date }
    }
    
    private func deleteBackups(at offsets: IndexSet) {
        let keysToDelete = offsets.map { backupsList[$0].id }
        
        // Remove from UserDefaults
        for key in keysToDelete {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Update backups list
        var currentList = UserDefaults.standard.stringArray(forKey: "dronaProfileBackupsList") ?? []
        currentList.removeAll { keysToDelete.contains($0) }
        UserDefaults.standard.set(currentList, forKey: "dronaProfileBackupsList")
        
        // Update UI
        refreshBackupsList()
    }
    
    private func showRestoreConfirmation(for backup: BackupInfo) {
        // In a real app, would show a confirmation alert here
        print("Would restore backup for \(backup.profileName) from \(dateFormatter.string(from: backup.date))")
    }
    
    private func clearCachedData() {
        let fileManager = FileManager.default
        
        // Clear temporary directory
        let tempDirectoryURL = fileManager.temporaryDirectory
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
        
        // Clear app's cache directory
        if let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let cacheContents = try fileManager.contentsOfDirectory(
                    at: cachesDirectory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                
                for file in cacheContents {
                    try fileManager.removeItem(at: file)
                }
            } catch {
                print("Error clearing app cache: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteAccount() {
        // Clear user profile
        userProfileManager.clearProfile()
        
        // Clear all settings
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
        
        // Clear all conversations
        ConversationManager.shared.clearAllConversations()
        
        // Clear backups
        if let backupKeys = UserDefaults.standard.stringArray(forKey: "dronaProfileBackupsList") {
            for key in backupKeys {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.removeObject(forKey: "dronaProfileBackupsList")
        
        // Clear cached files
        clearCachedData()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct DataManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataManagementView()
                .environmentObject(UserProfileManager())
        }
    }
} 