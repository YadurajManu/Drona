//
//  DataExportView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedContent: ExportContent = .allData
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var exportURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF Document"
        case json = "JSON Data"
        case text = "Plain Text"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext.fill"
            case .json: return "curlybraces"
            case .text: return "doc.text.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .json: return .blue
            case .text: return .gray
            }
        }
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .json: return "json"
            case .text: return "txt"
            }
        }
        
        var description: String {
            switch self {
            case .pdf: return "Professional document with formatted data"
            case .json: return "Machine-readable structured data format"
            case .text: return "Simple text format, easy to read anywhere"
            }
        }
    }
    
    enum ExportContent: String, CaseIterable, Identifiable {
        case profile = "User Profile"
        case conversations = "Conversations"
        case allData = "All Data"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .profile: return "person.fill"
            case .conversations: return "text.bubble.fill"
            case .allData: return "square.and.arrow.down.fill"
            }
        }
        
        var description: String {
            switch self {
            case .profile: return "Your personal information and preferences"
            case .conversations: return "All your conversations with Drona"
            case .allData: return "Profile, conversations and usage statistics"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    formatSection
                    
                    contentSection
                    
                    previewSection
                    
                    exportButton
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Export Your Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                
                                Text("Preparing your data...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up.on.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("Export Your Drona Data")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("Choose how you want to export your data. You can download your information in various formats.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT FORMAT")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            ForEach(ExportFormat.allCases) { format in
                FormatOptionRow(
                    format: format,
                    isSelected: selectedFormat == format,
                    action: { selectedFormat = format }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT TO INCLUDE")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            ForEach(ExportContent.allCases) { content in
                ContentOptionRow(
                    content: content,
                    isSelected: selectedContent == content,
                    action: { selectedContent = content }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT PREVIEW")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: selectedFormat.icon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedFormat.color)
                    
                    VStack(alignment: .leading) {
                        Text("Drona_Export.\(selectedFormat.fileExtension)")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("\(fileSize) • \(formattedDate())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                
                VStack(alignment: .leading, spacing: 14) {
                    previewDataRow(icon: "doc.text.fill", label: "User Profile", included: [.profile, .allData].contains(selectedContent))
                    
                    Divider()
                    
                    previewDataRow(icon: "text.bubble.fill", label: "Conversations (\(ConversationManager.shared.conversations.count))", included: [.conversations, .allData].contains(selectedContent))
                    
                    Divider()
                    
                    previewDataRow(icon: "chart.bar.fill", label: "Usage Statistics", included: selectedContent == .allData)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
    
    private func previewDataRow(icon: String, label: String, included: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(included ? .blue : .gray)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(included ? .primary : .gray)
            
            Spacer()
            
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(included ? .green : .red)
        }
    }
    
    private var exportButton: some View {
        Button(action: exportData) {
            Text("Export Data")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.top, 20)
        .disabled(isExporting)
    }
    
    private var fileSize: String {
        switch selectedContent {
        case .profile:
            return "~20 KB"
        case .conversations:
            let convoCount = ConversationManager.shared.conversations.count
            return "~\(convoCount * 50) KB"
        case .allData:
            let convoCount = ConversationManager.shared.conversations.count
            return "~\(convoCount * 50 + 30) KB"
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func exportData() {
        isExporting = true
        
        let exportFormat: ExportManager.ExportFormat
        switch selectedFormat {
        case .pdf: exportFormat = .pdf
        case .json: exportFormat = .json
        case .text: exportFormat = .text
        }
        
        let exportContent: ExportManager.ExportContent
        switch selectedContent {
        case .profile: exportContent = .profile
        case .conversations: exportContent = .conversations
        case .allData: exportContent = .allData
        }
        
        ExportManager.shared.exportUserData(format: exportFormat, content: exportContent) { url in
            DispatchQueue.main.async {
                isExporting = false
                
                if let exportedURL = url {
                    exportURL = exportedURL
                    exportSuccess = true
                    showingShareSheet = true
                } else {
                    alertTitle = "Export Failed"
                    alertMessage = "There was an error exporting your data. Please try again."
                    showAlert = true
                }
            }
        }
    }
}

struct FormatOptionRow: View {
    let format: DataExportView.ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: format.icon)
                    .font(.system(size: 24))
                    .foregroundColor(format.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.headline)
                    
                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                    .font(.system(size: 22))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentOptionRow: View {
    let content: DataExportView.ExportContent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: content.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.rawValue)
                        .font(.headline)
                    
                    Text(content.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                    .font(.system(size: 22))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportView()
            .environmentObject(UserProfileManager())
    }
} 