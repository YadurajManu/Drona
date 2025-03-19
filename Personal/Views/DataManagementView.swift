//
//  DataManagementView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileManager: UserProfileManager
    @ObservedObject private var activityManager = UserActivityManager.shared
    @State private var showingRestoreBackupSheet = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPrivacyPolicySheet = false
    @State private var showingClearConversationsAlert = false
    @State private var showingClearCacheAlert = false
    @State private var restrictDataSharing = true
    @State private var backupsList: [BackupInfo] = []
    @State private var selectedBackupId: String?
    @State private var isRefreshingBackups = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    struct BackupInfo: Identifiable {
        let id: String
        let date: Date
        let profileName: String
    }
    
    var body: some View {
        List {
            // DATA MANAGEMENT SECTION
            Section(header: 
                Text("DATA MANAGEMENT")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            ) {
                Button(action: { showingClearConversationsAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Clear All Conversations")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
                
                Button(action: { showingClearCacheAlert = true }) {
                    HStack {
                        Image(systemName: "trash.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Text("Clear Cached Data")
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
            }
            
            // BACKUP & RESTORE SECTION
            Section(header: 
                Text("BACKUP & RESTORE")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            ) {
                NavigationLink(destination: backupListView) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        Text("View Backups")
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: refreshBackupsWithAnimation) {
                    HStack {
                        if isRefreshingBackups {
                            ProgressView()
                                .frame(width: 24)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 24)
                        }
                        
                        Text("Refresh Backups List")
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                .disabled(isRefreshingBackups)
            }
            
            // PRIVACY & SECURITY SECTION
            Section(header: 
                Text("PRIVACY & SECURITY")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            ) {
                Button(action: { showingPrivacyPolicySheet = true }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Privacy Policy")
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                
                NavigationLink(destination: UserAnalyticsView()) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        Text("Learning Insights")
                            .foregroundColor(.primary)
                    }
                }
                
                NavigationLink(destination: dataUsageView) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        Text("Data Usage")
                            .foregroundColor(.primary)
                    }
                }
                
                Toggle(isOn: $restrictDataSharing) {
                    Text("Restrict Sensitive Data Sharing")
                        .foregroundColor(.primary)
                }
                .onChange(of: restrictDataSharing) { newValue in
                    savePrivacySettings()
                    showToast(message: "Privacy setting updated")
                }
            }
            
            // ACCOUNT MANAGEMENT SECTION
            Section(header: 
                Text("ACCOUNT MANAGEMENT")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            ) {
                Button(action: { showingDeleteAccountAlert = true }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Delete Account & Data")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPrivacySettings()
            refreshBackupsList()
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showToast)
        )
        .alert("Clear All Conversations", isPresented: $showingClearConversationsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                ConversationManager.shared.clearAllConversations()
                showToast(message: "All conversations cleared")
            }
        } message: {
            Text("This will remove all your conversation history. This action cannot be undone.")
        }
        .alert("Clear Cached Data", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCachedData()
                showToast(message: "Cache cleared successfully")
            }
        } message: {
            Text("This will clear temporary files and cached data to free up space. Your profile and conversations will not be affected.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
                dismiss()
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
            if backupsList.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Backups Found")
                            .font(.headline)
                        
                        Text("Backups you create will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            backupProfile()
                        }) {
                            Text("Create Backup")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(backupsList) { backup in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backup.profileName)
                                .font(.headline)
                            
                            Text(dateFormatter.string(from: backup.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedBackupId = backup.id
                            showRestoreConfirmation(for: backup)
                        }) {
                            Text("Restore")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .onDelete(perform: deleteBackups)
            }
        }
        .navigationTitle("Saved Backups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    backupProfile()
                }) {
                    Text("Backup Now")
                }
            }
        }
    }
    
    private var dataUsageView: some View {
        List {
            Section(header: Text("App Usage")) {
                DataUsageRow(title: "Total Sessions", value: "\(activityManager.activitySummary.totalSessionsCount)")
                DataUsageRow(title: "Conversations", value: "\(activityManager.activitySummary.totalConversationsStarted)")
                DataUsageRow(title: "Messages Sent", value: "\(activityManager.activitySummary.totalMessagesCount)")
                
                HStack {
                    Text("Total Usage Time")
                    Spacer()
                    Text(formatTimeInterval(activityManager.activitySummary.totalSessionTime))
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Storage Usage")) {
                StorageUsageRow(title: "Profile Data", value: "< 1 MB", percent: 0.05)
                StorageUsageRow(title: "Conversations", value: calculateConversationSize(), percent: calculateConversationPercent())
                StorageUsageRow(title: "Cache", value: calculateCacheSize(), percent: calculateCachePercent())
            }
            
            Section(header: Text("Network Usage")) {
                HStack {
                    Text("API Calls")
                    Spacer()
                    Text("\(activityManager.activitySummary.totalMessagesCount * 2)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Data Transferred")
                    Spacer()
                    Text("\(formatDataSize(Double(activityManager.activitySummary.totalMessagesCount * 15)))")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    // Clear usage statistics
                    activityManager.clearActivityData()
                    showToast(message: "Usage statistics reset")
                }) {
                    HStack {
                        Spacer()
                        Text("Reset Usage Statistics")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Data Usage")
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
            .navigationBarItems(trailing: Button("Done") {
                showingPrivacyPolicySheet = false
            })
        }
    }
    
    // MARK: - Helper Functions
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        
        // Hide toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showToast = false
            }
        }
    }
    
    private func refreshBackupsWithAnimation() {
        isRefreshingBackups = true
        
        // Add slight delay to show loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshBackupsList()
            isRefreshingBackups = false
            showToast(message: "Backup list refreshed")
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
    
    private func backupProfile() {
        guard let profile = userProfileManager.userProfile else {
            showToast(message: "No profile to backup")
            return
        }
        
        // Create backup entry in UserDefaults
        if let profileData = try? JSONEncoder().encode(profile) {
            let backupKey = "dronaProfileBackup_\(Date().timeIntervalSince1970)"
            UserDefaults.standard.set(profileData, forKey: backupKey)
            
            // Store list of backups
            var backupsList = UserDefaults.standard.stringArray(forKey: "dronaProfileBackupsList") ?? []
            backupsList.append(backupKey)
            UserDefaults.standard.set(backupsList, forKey: "dronaProfileBackupsList")
            
            refreshBackupsList()
            showToast(message: "Profile backed up successfully")
        } else {
            showToast(message: "Failed to create backup")
        }
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
        showToast(message: "Backup deleted")
    }
    
    private func showRestoreConfirmation(for backup: BackupInfo) {
        // In a real app, would show a confirmation alert here
        guard let backupData = UserDefaults.standard.data(forKey: backup.id),
              let restoredProfile = try? JSONDecoder().decode(UserProfile.self, from: backupData) else {
            showToast(message: "Failed to restore backup")
            return
        }
        
        userProfileManager.saveProfile(restoredProfile)
        showToast(message: "Profile restored successfully")
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
        
        // Clear activity data
        activityManager.clearActivityData()
    }
    
    private func loadPrivacySettings() {
        restrictDataSharing = UserDefaults.standard.bool(forKey: "dronaRestrictDataSharing")
    }
    
    private func savePrivacySettings() {
        UserDefaults.standard.set(restrictDataSharing, forKey: "dronaRestrictDataSharing")
    }
    
    private func calculateConversationSize() -> String {
        // In a real app, would calculate actual size
        let messageCount = activityManager.activitySummary.totalMessagesCount
        let size = Double(messageCount) * 5.0 // Rough estimate: 5 KB per message
        return formatDataSize(size)
    }
    
    private func calculateCacheSize() -> String {
        // In a real app, would calculate actual cache size
        return formatDataSize(Double.random(in: 1...20) * 1024) // Random value for demonstration
    }
    
    private func calculateConversationPercent() -> CGFloat {
        // In a real app, would calculate actual percentage
        let messageCount = activityManager.activitySummary.totalMessagesCount
        return min(CGFloat(messageCount) * 0.01, 0.8) // Cap at 80%
    }
    
    private func calculateCachePercent() -> CGFloat {
        // In a real app, would calculate actual percentage
        return CGFloat.random(in: 0.05...0.2) // Random value for demonstration
    }
    
    private func formatDataSize(_ kilobytes: Double) -> String {
        if kilobytes < 1024 {
            return String(format: "%.1f KB", kilobytes)
        } else {
            let megabytes = kilobytes / 1024
            return String(format: "%.1f MB", megabytes)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Helper Views

struct DataUsageRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct StorageUsageRow: View {
    let title: String
    let value: String
    let percent: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * percent, height: 6)
                        .foregroundColor(.blue)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                VStack {
                    Text(message)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 90)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
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