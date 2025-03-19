//
//  MainTabView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @StateObject private var conversationManager = ConversationManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(conversationManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ConversationsListView()
                .environmentObject(conversationManager)
                .tabItem {
                    Label("Conversations", systemImage: "message.fill")
                }
                .tag(1)
            
            NewQuestionView()
                .environmentObject(conversationManager)
                .tabItem {
                    Label("New Question", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            FlashcardsHomeView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var navigateToFlashcards = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeSection
                    
                    flashcardsSection
                    
                    recentConversationsSection
                    
                    quickStartSection
                }
                .padding()
            }
            .navigationTitle("Drona")
            .background(Color("BackgroundColor").ignoresSafeArea())
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let profile = userProfileManager.userProfile {
                Text("Hello, \(profile.name)!")
                    .font(.largeTitle)
                    .bold()
                
                Text("What would you like to discuss today?")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var flashcardsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Flashcards")
                .font(.headline)
                .padding(.top)
            
            Button(action: { navigateToFlashcards = true }) {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.orange)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review Your Flashcards")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Text("Study with spaced repetition")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                NavigationLink(
                    destination: FlashcardsHomeView(),
                    isActive: $navigateToFlashcards
                ) { EmptyView() }
            )
        }
    }
    
    private var recentConversationsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Conversations")
                .font(.headline)
                .padding(.top)
            
            if conversationManager.conversations.isEmpty {
                Text("You don't have any conversations yet. Start a new one!")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(conversationManager.conversations.prefix(3)) { conversation in
                    Button(action: {
                        conversationManager.selectConversation(conversation)
                        // Navigate to conversation detail view
                    }) {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if conversationManager.conversations.count > 3 {
                    NavigationLink(destination: ConversationsListView().environmentObject(conversationManager)) {
                        Text("See all conversations")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 5)
                    }
                }
            }
        }
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Start")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                ForEach(UserProfile.DoubtCategory.allCases.prefix(4), id: \.self) { category in
                    NavigationLink(destination: NewQuestionView(preselectedCategory: category)
                        .environmentObject(conversationManager)) {
                        HStack {
                            categoryIcon(for: category)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(categoryColor(for: category))
                                .cornerRadius(8)
                            
                            Text(category.rawValue)
                                .font(.system(size: 17, weight: .medium))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                NavigationLink(destination: CreateFlashcardView()) {
                    HStack {
                        Image(systemName: "plus.rectangle.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.purple)
                            .cornerRadius(8)
                        
                        Text("Create Flashcard")
                            .font(.system(size: 17, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func categoryIcon(for category: UserProfile.DoubtCategory) -> some View {
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
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(relativeTime(for: conversation.lastUpdated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(conversation.messages.last?.content.prefix(100) ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(conversation.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(conversation.messages.count) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 