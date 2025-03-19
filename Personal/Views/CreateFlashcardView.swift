//
//  CreateFlashcardView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct CreateFlashcardView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var hint: String = ""
    @State private var category: String = ""
    @State private var selectedColor: Flashcard.CardColor = .blue
    @State private var showCustomCategory = false
    @State private var customCategory: String = ""
    @State private var includeHint: Bool = false
    @State private var showFormatHelp: Bool = false
    
    // Text formatting preview
    @State private var previewQuestion: Bool = false
    @State private var previewAnswer: Bool = false
    
    private var existingCategories: [String] {
        Array(flashcardManager.categories).sorted()
    }
    
    private var isFormValid: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
         !customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Question"),
                    footer: HStack {
                        Text("Supports simple formatting")
                        Button {
                            showFormatHelp = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                ) {
                    if previewQuestion {
                        previewText(question)
                            .padding(.vertical, 8)
                        
                        Button("Edit Text") {
                            previewQuestion = false
                        }
                    } else {
                        TextEditor(text: $question)
                            .frame(minHeight: 100)
                        
                        HStack {
                            Spacer()
                            Button("Preview") {
                                previewQuestion = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Answer")) {
                    if previewAnswer {
                        previewText(answer)
                            .padding(.vertical, 8)
                        
                        Button("Edit Text") {
                            previewAnswer = false
                        }
                    } else {
                        TextEditor(text: $answer)
                            .frame(minHeight: 100)
                        
                        HStack {
                            Spacer()
                            Button("Preview") {
                                previewAnswer = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Hint (Optional)")) {
                    Toggle("Include hint", isOn: $includeHint)
                    
                    if includeHint {
                        TextEditor(text: $hint)
                            .frame(minHeight: 60)
                    }
                }
                
                Section(header: Text("Category")) {
                    if !existingCategories.isEmpty {
                        Picker("Select a category", selection: $category) {
                            Text("Custom Category").tag("")
                            ForEach(existingCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    }
                    
                    if category.isEmpty || existingCategories.isEmpty {
                        TextField("Enter category name", text: $customCategory)
                    }
                }
                
                Section(header: Text("Color")) {
                    HStack {
                        ForEach(Flashcard.CardColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.uiColor)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .padding(5)
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
                
                Section {
                    Button(action: saveFlashcard) {
                        Text("Save Flashcard")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Create Flashcard")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showFormatHelp) {
                Alert(
                    title: Text("Text Formatting"),
                    message: Text("You can use simple formatting:\n\n*bold text* for bold\n_italic text_ for italics\n- item for bullet points\n\nMath: Use $x^2$ for inline equations."),
                    dismissButton: .default(Text("Got it!"))
                )
            }
        }
    }
    
    private func previewText(_ text: String) -> some View {
        Text(LocalizedStringKey(formatMarkdown(text)))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatMarkdown(_ text: String) -> String {
        // Simple markdown conversion for preview purposes
        var formatted = text
        
        // Bold
        let boldPattern = #"\*(.*?)\*"#
        formatted = formatted.replacingOccurrences(
            of: boldPattern, 
            with: "**$1**", 
            options: .regularExpression
        )
        
        // Italic
        let italicPattern = #"_(.*?)_"#
        formatted = formatted.replacingOccurrences(
            of: italicPattern, 
            with: "*$1*", 
            options: .regularExpression
        )
        
        return formatted
    }
    
    private func saveFlashcard() {
        let finalCategory = category.isEmpty ? customCategory : category
        
        var newFlashcard = Flashcard(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
            category: finalCategory.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor
        )
        
        // Add hint if provided
        if includeHint && !hint.isEmpty {
            newFlashcard.hasHint = true
            newFlashcard.hint = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        flashcardManager.addFlashcard(newFlashcard)
        presentationMode.wrappedValue.dismiss()
    }
}

struct CreateFlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFlashcardView()
    }
} 