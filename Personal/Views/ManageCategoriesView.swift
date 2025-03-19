//
//  ManageCategoriesView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct ManageCategoriesView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var flashcardManager = FlashcardManager.shared
    
    var categories: [String]
    
    @State private var newCategoryName: String = ""
    @State private var editMode: EditMode = .inactive
    @State private var showAddCategory = false
    @State private var categoryToEdit: String? = nil
    @State private var editedCategoryName: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                if showAddCategory {
                    newCategorySection
                }
                
                ForEach(categories, id: \.self) { category in
                    if categoryToEdit == category {
                        editCategoryRow
                    } else {
                        categoryRow(category)
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Manage Categories")
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button(action: {
                    if editMode == .active {
                        editMode = .inactive
                    } else {
                        withAnimation {
                            showAddCategory.toggle()
                        }
                    }
                }) {
                    if editMode == .active {
                        Text("Done")
                    } else {
                        Image(systemName: "plus")
                    }
                }
            )
            .environment(\.editMode, $editMode)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var newCategorySection: some View {
        HStack {
            TextField("New category name", text: $newCategoryName)
            
            Button(action: addCategory) {
                Text("Add")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button(action: {
                withAnimation {
                    showAddCategory = false
                    newCategoryName = ""
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var editCategoryRow: some View {
        HStack {
            TextField("Category name", text: $editedCategoryName)
            
            Button(action: saveEditedCategory) {
                Text("Save")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .disabled(editedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button(action: {
                categoryToEdit = nil
                editedCategoryName = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryRow(_ category: String) -> some View {
        HStack {
            Text(category)
            
            Spacer()
            
            Text("\(cardCount(for: category)) cards")
                .foregroundColor(.secondary)
                .font(.caption)
            
            if editMode == .active {
                Button(action: {
                    categoryToEdit = category
                    editedCategoryName = category
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // Functions
    private func cardCount(for category: String) -> Int {
        return flashcardManager.getCardsForCategory(category).count
    }
    
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty { return }
        
        if flashcardManager.categories.contains(trimmedName) {
            alertTitle = "Category Exists"
            alertMessage = "A category with this name already exists."
            showAlert = true
            return
        }
        
        flashcardManager.categories.insert(trimmedName)
        flashcardManager.saveCategoryChanges()
        
        withAnimation {
            showAddCategory = false
            newCategoryName = ""
        }
    }
    
    private func saveEditedCategory() {
        guard let originalCategory = categoryToEdit else { return }
        
        let trimmedName = editedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty { return }
        
        if originalCategory != trimmedName && flashcardManager.categories.contains(trimmedName) {
            alertTitle = "Category Exists"
            alertMessage = "A category with this name already exists."
            showAlert = true
            return
        }
        
        // Update the category name in all flashcards
        let affectedCards = flashcardManager.getCardsForCategory(originalCategory)
        for card in affectedCards {
            var updatedCard = card
            updatedCard.category = trimmedName
            flashcardManager.updateFlashcard(updatedCard)
        }
        
        // Update categories set
        flashcardManager.categories.remove(originalCategory)
        flashcardManager.categories.insert(trimmedName)
        flashcardManager.saveCategoryChanges()
        
        categoryToEdit = nil
        editedCategoryName = ""
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { categories[$0] }
        
        for category in categoriesToDelete {
            // Check if there are flashcards with this category
            let affectedCards = flashcardManager.getCardsForCategory(category)
            
            if !affectedCards.isEmpty {
                alertTitle = "Cannot Delete Category"
                alertMessage = "This category contains \(affectedCards.count) flashcards. Delete or reassign these flashcards first."
                showAlert = true
                return
            }
            
            flashcardManager.categories.remove(category)
        }
        
        flashcardManager.saveCategoryChanges()
    }
}

struct ManageCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        ManageCategoriesView(categories: ["Mathematics", "Science", "History"])
    }
} 