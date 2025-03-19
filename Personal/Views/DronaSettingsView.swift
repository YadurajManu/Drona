//
//  DronaSettingsView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct DronaSettingsView: View {
    @AppStorage("dronaResponseLength") private var responseLength: ResponseLength = .balanced
    @AppStorage("dronaResponseTone") private var responseTone: ResponseTone = .conversational
    @AppStorage("dronaExampleDetail") private var exampleDetail: Bool = true
    @AppStorage("dronaUseFormalLanguage") private var useFormalLanguage: Bool = false
    @AppStorage("dronaPrimaryChatColor") private var primaryChatColor: String = "blue"
    @AppStorage("dronaShowSourcesInResponse") private var showSourcesInResponse: Bool = true
    @AppStorage("dronaAutoSuggestQuestions") private var autoSuggestQuestions: Bool = true
    @AppStorage("dronaShowTypingAnimation") private var showTypingAnimation: Bool = true
    
    private let colorOptions = [
        "blue": Color.blue,
        "purple": Color.purple,
        "green": Color.green,
        "orange": Color.orange,
        "pink": Color.pink,
        "indigo": Color.indigo
    ]
    
    enum ResponseLength: String, CaseIterable, Identifiable {
        case concise = "Concise"
        case balanced = "Balanced"
        case detailed = "Detailed"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .concise: return "Short, to-the-point responses"
            case .balanced: return "Moderate length with key information"
            case .detailed: return "Comprehensive answers with examples"
            }
        }
    }
    
    enum ResponseTone: String, CaseIterable, Identifiable {
        case conversational = "Conversational"
        case professional = "Professional"
        case academic = "Academic"
        case encouraging = "Encouraging"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .conversational: return "Friendly, casual tone"
            case .professional: return "Formal, business-like tone"
            case .academic: return "Scholarly with precise terminology"
            case .encouraging: return "Motivational and supportive"
            }
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Response Preferences"), footer: Text("These settings affect how Drona responds to your questions")) {
                Picker("Response Length", selection: $responseLength) {
                    ForEach(ResponseLength.allCases) { length in
                        Text(length.rawValue).tag(length)
                    }
                }
                
                Text(responseLength.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Tone", selection: $responseTone) {
                    ForEach(ResponseTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                
                Text(responseTone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Use Formal Language", isOn: $useFormalLanguage)
                Toggle("Include Examples", isOn: $exampleDetail)
                Toggle("Show Sources in Responses", isOn: $showSourcesInResponse)
            }
            
            Section(header: Text("Appearance")) {
                HStack {
                    Text("Primary Color")
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(Array(colorOptions.keys.sorted()), id: \.self) { key in
                            Circle()
                                .fill(colorOptions[key] ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: primaryChatColor == key ? 2 : 0)
                                )
                                .onTapGesture {
                                    primaryChatColor = key
                                }
                        }
                    }
                }
            }
            
            Section(header: Text("Interaction Features")) {
                Toggle("Auto-suggest Related Questions", isOn: $autoSuggestQuestions)
                Toggle("Show Typing Animation", isOn: $showTypingAnimation)
            }
            
            Section(header: Text("Reset Options")) {
                Button(action: resetSettings) {
                    HStack {
                        Spacer()
                        Text("Reset to Default Settings")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("About Drona"), footer: Text("Drona is an AI mentor inspired by the legendary guru from Indian mythology. Drona is designed to provide guidance and support in your educational journey.")) {
                HStack {
                    Text("AI Model")
                    Spacer()
                    Text("Gemini 1.5 Pro")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Drona Settings")
    }
    
    private func resetSettings() {
        responseLength = .balanced
        responseTone = .conversational
        exampleDetail = true
        useFormalLanguage = false
        primaryChatColor = "blue"
        showSourcesInResponse = true
        autoSuggestQuestions = true
        showTypingAnimation = true
    }
}

struct DronaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DronaSettingsView()
        }
    }
} 