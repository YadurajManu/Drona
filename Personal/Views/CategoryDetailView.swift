//
//  CategoryDetailView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    
    var category: String
    @State private var searchText: String = ""
    @State private var showingReviewSheet = false
    @State private var sortOption: SortOption = .newest
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case confidenceAsc = "Confidence: Low to High"
        case confidenceDesc = "Confidence: High to Low"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search in \(category)...")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Sort options
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                    
                    Text("\(filteredCards.count) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                if filteredCards.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCards) { card in
                                FlashcardRowView(flashcard: card)
                            }
                        }
                        .padding()
                    }
                }
                
                // Review button
                if !filteredCards.isEmpty {
                    Button(action: {
                        showingReviewSheet = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Review \(category) Cards")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle(category)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                }
            )
            .fullScreenCover(isPresented: $showingReviewSheet) {
                FlashcardReviewView(cards: filteredCards)
            }
        }
    }
    
    private var filteredCards: [Flashcard] {
        var cards = flashcardManager.getCardsForCategory(category)
        
        // Apply search filter
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.question.lowercased().contains(searchText.lowercased()) ||
                card.answer.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply sort
        switch sortOption {
        case .newest:
            return cards.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return cards.sorted { $0.createdAt < $1.createdAt }
        case .confidenceAsc:
            return cards.sorted { $0.confidence < $1.confidence }
        case .confidenceDesc:
            return cards.sorted { $0.confidence > $1.confidence }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if searchText.isEmpty {
                // No cards in this category
                Image(systemName: "folder")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("No flashcards in this category")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create new flashcards or generate them from conversations")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // No search results
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                
                Text("No matching flashcards")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try a different search term")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryDetailView(category: "Mathematics")
    }
} 