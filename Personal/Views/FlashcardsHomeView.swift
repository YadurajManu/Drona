//
//  FlashcardsHomeView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct FlashcardsHomeView: View {
    @ObservedObject var flashcardManager = FlashcardManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: CategoryItem? = nil
    @State private var showingCreateSheet = false
    @State private var showGenerateSheet = false
    @State private var showingCategorySheet = false
    @State private var selectedTab = 0
    
    // Struct to make category item identifiable for fullScreenCover
    struct CategoryItem: Identifiable {
        let id = UUID()
        let name: String
    }
    
    private var tabs = ["Due Today", "Recent", "Categories", "Starred"]
    
    // Filtered cards based on search
    private var filteredCards: [Flashcard] {
        if searchText.isEmpty {
            return flashcardManager.flashcards
        } else {
            return flashcardManager.flashcards.filter { card in
                card.question.lowercased().contains(searchText.lowercased()) ||
                card.answer.lowercased().contains(searchText.lowercased()) ||
                card.category.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private var dueCards: [Flashcard] {
        return flashcardManager.getDueCards()
    }
    
    private var recentCards: [Flashcard] {
        return flashcardManager.getRecentlyAdded(limit: 20)
    }
    
    private var starredCards: [Flashcard] {
        return flashcardManager.getStarredCards()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText, placeholder: "Search flashcards...")
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Custom segmented control
                    CustomSegmentedControl(
                        tabs: tabs,
                        selectedTab: $selectedTab
                    )
                    .padding(.top, 16)
                    
                    // Main content based on tab
                    TabView(selection: $selectedTab) {
                        // Due Today
                        DueCardsView(cards: dueCards)
                            .tag(0)
                        
                        // Recent
                        RecentCardsView(cards: recentCards)
                            .tag(1)
                        
                        // Categories
                        CategoriesView(
                            categories: Array(flashcardManager.categories).sorted(),
                            selectedCategory: $selectedCategory
                        )
                        .tag(2)
                        
                        // Starred
                        StarredCardsView(cards: starredCards)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Flash review button
                    if selectedTab != 2 { // Don't show in categories view
                        QuickReviewButton(cards: currentCards)
                            .padding(.bottom, 16)
                    }
                }
                
                // Floating action button for adding/generating cards
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        // Floating menu button
                        Menu {
                            Button(action: { showingCreateSheet = true }) {
                                Label("Create Flashcard", systemImage: "square.and.pencil")
                            }
                            
                            Button(action: { showGenerateSheet = true }) {
                                Label("Generate from Conversation", systemImage: "wand.and.stars")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarItems(
                trailing: Button(action: {
                    showingCategorySheet = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showingCreateSheet) {
                CreateFlashcardView()
            }
            .sheet(isPresented: $showGenerateSheet) {
                GenerateFlashcardsView()
            }
            .sheet(isPresented: $showingCategorySheet) {
                ManageCategoriesView(categories: Array(flashcardManager.categories))
            }
            .fullScreenCover(item: $selectedCategory) { category in
                CategoryDetailView(category: category.name)
            }
            .overlay {
                if flashcardManager.isGenerating {
                    GenerationProgressView(
                        progress: flashcardManager.generationProgress,
                        isShowing: flashcardManager.showGenerationProgress
                    )
                }
            }
        }
    }
    
    // Get current cards based on selected tab
    private var currentCards: [Flashcard] {
        switch selectedTab {
        case 0: return dueCards
        case 1: return recentCards
        case 3: return starredCards
        default: return []
        }
    }
}

// MARK: - Supporting Views

struct DueCardsView: View {
    let cards: [Flashcard]
    
    var body: some View {
        if cards.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("You're all caught up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("No cards due for review today")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("\(cards.count) cards due for review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    ForEach(cards) { card in
                        FlashcardRowView(flashcard: card)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct RecentCardsView: View {
    let cards: [Flashcard]
    
    var body: some View {
        if cards.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("No flashcards yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first flashcard by tapping the + button")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cards) { card in
                        FlashcardRowView(flashcard: card)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct CategoriesView: View {
    let categories: [String]
    @Binding var selectedCategory: FlashcardsHomeView.CategoryItem?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        if categories.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "folder")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("No categories yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Categories will be created automatically when you add flashcards")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        CategoryCardView(
                            category: category,
                            count: FlashcardManager.shared.getCardsForCategory(category).count
                        )
                        .onTapGesture {
                            selectedCategory = FlashcardsHomeView.CategoryItem(name: category)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct StarredCardsView: View {
    let cards: [Flashcard]
    
    var body: some View {
        if cards.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "star")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("No starred cards")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Star your favorite cards to find them quickly")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cards) { card in
                        FlashcardRowView(flashcard: card)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct FlashcardRowView: View {
    let flashcard: Flashcard
    @State private var showingCardDetail = false
    @ObservedObject private var manager = FlashcardManager.shared
    
    var body: some View {
        Button(action: {
            showingCardDetail = true
        }) {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(flashcard.color.uiColor)
                    .frame(width: 6)
                    .cornerRadius(3)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(flashcard.question)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(flashcard.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(formatDate(flashcard.createdAt))", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let reviewDate = flashcard.lastReviewed {
                            Text("Last: \(formatDate(reviewDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Button(action: {
                        manager.toggleStar(for: flashcard)
                    }) {
                        Image(systemName: flashcard.starred ? "star.fill" : "star")
                            .foregroundColor(flashcard.starred ? .yellow : .gray)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Spacer()
                    
                    Text("Lvl \(flashcard.confidence)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(confidenceColor(flashcard.confidence))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCardDetail) {
            FlashcardDetailView(flashcard: flashcard)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

struct CategoryCardView: View {
    let category: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: categoryIcon(for: category))
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
            
            Text("\(count) cards")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: progressValue(for: category), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: category)))
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func categoryIcon(for category: String) -> String {
        let lowerCategory = category.lowercased()
        
        if lowerCategory.contains("math") {
            return "function"
        } else if lowerCategory.contains("science") {
            return "atom"
        } else if lowerCategory.contains("history") {
            return "book.closed"
        } else if lowerCategory.contains("literature") {
            return "text.book.closed"
        } else if lowerCategory.contains("computer") {
            return "desktopcomputer"
        } else if lowerCategory.contains("language") {
            return "text.bubble"
        } else if lowerCategory.contains("art") {
            return "paintpalette"
        } else if lowerCategory.contains("music") {
            return "music.note"
        } else {
            return "folder"
        }
    }
    
    private func progressValue(for category: String) -> Double {
        let cards = FlashcardManager.shared.getCardsForCategory(category)
        if cards.isEmpty { return 0.0 }
        
        let mastered = cards.filter { $0.confidence >= 4 }.count
        return Double(mastered) / Double(cards.count)
    }
    
    private func progressColor(for category: String) -> Color {
        let progress = progressValue(for: category)
        
        if progress < 0.3 {
            return .red
        } else if progress < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

struct QuickReviewButton: View {
    let cards: [Flashcard]
    @State private var showingReviewSession = false
    
    var body: some View {
        Button(action: {
            if !cards.isEmpty {
                showingReviewSession = true
            }
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Quick Review")
                    .font(.headline)
                Image(systemName: "sparkles")
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(cards.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .disabled(cards.isEmpty)
        .fullScreenCover(isPresented: $showingReviewSession) {
            FlashcardReviewView(cards: cards)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CustomSegmentedControl: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedTab = index
                        }
                    }) {
                        Text(tabs[index])
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .foregroundColor(selectedTab == index ? .primary : .secondary)
                            .font(selectedTab == index ? .headline : .subheadline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Indicator
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 2)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: UIScreen.main.bounds.width / CGFloat(tabs.count), height: 2)
                    .offset(x: CGFloat(selectedTab) * UIScreen.main.bounds.width / CGFloat(tabs.count))
                    .animation(.spring(), value: selectedTab)
            }
        }
    }
}

struct GenerationProgressView: View {
    let progress: Double
    let isShowing: Bool
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Generating Flashcards")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    if progress >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 30))
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.8))
                .cornerRadius(15)
            }
            .transition(.opacity)
        }
    }
}

// Preview
struct FlashcardsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardsHomeView()
    }
} 