//
//  GenerateFlashcardsView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct GenerateFlashcardsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    @ObservedObject private var conversationManager = ConversationManager()
    
    @State private var selectedConversation: Conversation?
    @State private var cardCount: Int = 5
    @State private var generating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if conversationManager.conversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Select a conversation to generate flashcards from:")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(conversationManager.conversations) { conversation in
                                ConversationCardView(
                                    conversation: conversation,
                                    isSelected: selectedConversation?.id == conversation.id
                                )
                                .onTapGesture {
                                    selectedConversation = conversation
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 15) {
                        Text("Number of cards to generate:")
                            .font(.headline)
                        
                        Stepper("\(cardCount) cards", value: $cardCount, in: 1...15)
                            .padding(.horizontal, 40)
                        
                        Button(action: generateFlashcards) {
                            HStack {
                                if generating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .padding(.trailing, 5)
                                }
                                
                                Text(generating ? "Generating..." : "Generate Flashcards")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedConversation == nil ? Color.gray : Color.blue)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .disabled(selectedConversation == nil || generating)
                        .padding()
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Generate Flashcards")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Generation Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("No conversations available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation with Drona to generate flashcards from your discussions")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Go Back")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func generateFlashcards() {
        guard let conversation = selectedConversation else { return }
        
        generating = true
        
        flashcardManager.generateFlashcardsFromConversation(conversation, count: cardCount) { success in
            generating = false
            
            if success {
                alertMessage = "Flashcards generated successfully!"
            } else {
                alertMessage = "There was a problem generating flashcards. Please try again."
            }
            
            showAlert = true
        }
    }
}

struct ConversationCardView: View {
    let conversation: Conversation
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(categoryText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.system(size: 24))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private var categoryText: String {
        "Category: \(conversation.category.rawValue)"
    }
    
    private var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.lastUpdated, relativeTo: Date())
    }
}

struct GenerateFlashcardsView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateFlashcardsView()
    }
} 