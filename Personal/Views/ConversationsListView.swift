//
//  ConversationsListView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct ConversationsListView: View {
    @EnvironmentObject var conversationManager: ConversationManager
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    @State private var selectedFilter: UserProfile.DoubtCategory?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterScrollView
                
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredConversations) { conversation in
                            NavigationLink(
                                destination: ConversationDetailView(conversation: conversation)
                                    .environmentObject(conversationManager)
                            ) {
                                ConversationRow(conversation: conversation)
                                    .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Conversations")
            .searchable(text: $searchText, prompt: "Search conversations")
            .alert("Delete Conversation", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        conversationManager.deleteConversation(conversation)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this conversation? This action cannot be undone.")
            }
        }
    }
    
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                ForEach(UserProfile.DoubtCategory.allCases, id: \.self) { category in
                    FilterChip(title: category.rawValue, isSelected: selectedFilter == category) {
                        selectedFilter = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.7))
                .symbolRenderingMode(.hierarchical)
            
            Text("No conversations found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty || selectedFilter != nil {
                Text("Try changing your search or filter")
                    .foregroundColor(.secondary)
            } else {
                Text("Start a new conversation by tapping the + button")
                    .foregroundColor(.secondary)
                
                NavigationLink(destination: NewQuestionView().environmentObject(conversationManager)) {
                    Text("Start new conversation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var filteredConversations: [Conversation] {
        var result = conversationManager.conversations
        
        if let filter = selectedFilter {
            result = result.filter { $0.category == filter }
        }
        
        if !searchText.isEmpty {
            result = result.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return result
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isScrollingUp = false
    @State private var showScrollToBottom = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                chatHeader
                
                // Chat area
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversation.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.opacity)
                            }
                            
                            // Invisible spacer view at the bottom for scrolling
                            Color.clear
                                .frame(height: 1)
                                .id("bottomID")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: conversationManager.currentConversation?.messages.count) { _ in
                        if let lastMessage = conversationManager.currentConversation?.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if showScrollToBottom {
                            Button {
                                withAnimation {
                                    scrollView.scrollTo("bottomID", anchor: .bottom)
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let lastMessage = conversation.messages.last {
                                withAnimation {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        conversationManager.selectConversation(conversation)
                    }
                }
                
                // Typing indicator when loading
                if isLoading {
                    HStack(spacing: 4) {
                        Image(systemName: "graduationcap.fill")
                            .font(.footnote)
                            .foregroundColor(.blue)
                        
                        Text("Drona is typing")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TypingIndicator()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Divider()
                
                messageInputView
            }
        }
        .navigationBarHidden(true)
    }
    
    private var chatHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    // Navigate back
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor(for: conversation.category))
                            .frame(width: 8, height: 8)
                        
                        Text(conversation.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: {
                        // Share conversation
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {
                        // Delete conversation
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var messageInputView: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .trailing) {
                TextField("Message Drona...", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isTextFieldFocused)
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1)
                
                if !messageText.isEmpty {
                    Button {
                        messageText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                }
            }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(canSendMessage ? .blue : .gray.opacity(0.5))
            }
            .disabled(!canSendMessage)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    private func categoryColor(for category: UserProfile.DoubtCategory) -> Color {
        switch category {
        case .academic: return .blue
        case .personal: return .purple
        case .financial: return .green
        case .social: return .orange
        case .relational: return .pink
        case .career: return .indigo
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty, !isLoading else { return }
        
        isLoading = true
        messageText = ""
        isTextFieldFocused = false
        
        conversationManager.sendMessage(content: trimmedMessage, userProfile: userProfileManager.userProfile) { success in
            isLoading = false
            if !success {
                // Handle error
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var showTimeStamp = false
    
    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
            HStack {
                if message.isFromUser {
                    Spacer()
                    
                    Text(message.content)
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Drona")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(message.content)
                                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(20, corners: [.topRight, .bottomLeft, .bottomRight])
                        }
                    }
                    
                    Spacer()
                }
            }
            .onTapGesture {
                withAnimation {
                    showTimeStamp.toggle()
                }
            }
            
            if showTimeStamp {
                Text(formattedTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        // If today, show only time
        if Calendar.current.isDateInToday(date) {
            return formatter.string(from: date)
        }
        
        // If this year, show month and day
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var showDot1 = false
    @State private var showDot2 = false
    @State private var showDot3 = false
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .frame(width: 4, height: 4)
                .opacity(showDot1 ? 1 : 0.3)
            
            Circle()
                .frame(width: 4, height: 4)
                .opacity(showDot2 ? 1 : 0.3)
            
            Circle()
                .frame(width: 4, height: 4)
                .opacity(showDot3 ? 1 : 0.3)
        }
        .foregroundColor(.gray)
        .onAppear {
            animate()
        }
    }
    
    private func animate() {
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(0.0)) {
            showDot1 = true
        }
        
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(0.2)) {
            showDot2 = true
        }
        
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(0.4)) {
            showDot3 = true
        }
    }
}

// Extension to apply different corner radii to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 