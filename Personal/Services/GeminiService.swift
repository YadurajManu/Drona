//
//  GeminiService.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import Foundation

class GeminiService {
    private let apiKey = "AIzaSyD3Xbweiz-suIDVW_qvbCI4jYDwCzOqy1g"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
    
    func askQuestion(question: String, userProfile: UserProfile?, context: String = "", completion: @escaping (Result<String, Error>) -> Void) {
        
        var profileContext = ""
        if let profile = userProfile {
            profileContext = """
            User profile information:
            Name: \(profile.name)
            Age: \(profile.age)
            Education level: \(profile.educationLevel.rawValue)
            Interests: \(profile.interests.map { $0.rawValue }.joined(separator: ", "))
            Preferred topics: \(profile.preferredTopics.map { $0.rawValue }.joined(separator: ", "))
            Bio: \(profile.bio)
            """
        }
        
        let fullContext = """
        You are Drona, an AI mentor and guide for students named after the legendary teacher from Indian mythology.
        Your purpose is to provide thoughtful, accurate, and personalized guidance to students on various topics including:
        - Academic questions and learning concepts
        - Personal development and self-improvement
        - Financial literacy and money management
        - Social skills and interpersonal relationships
        - Emotional well-being and mental health
        - Career planning and professional development
        
        Be conversational but concise, supportive, and adapt your tone to the student's age and education level.
        Provide actionable advice and insightful perspectives. When appropriate, use examples or analogies.
        Always maintain a positive, encouraging tone. If you don't know something, be honest about limitations.
        
        \(profileContext)
        
        \(context)
        """
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(fullContext)\n\nQuestion: \(question)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048,
                "responseMimeType": "text/plain"
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ]
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(NSError(domain: "GeminiService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GeminiService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let errorInfo = json["error"] as? [String: Any],
                       let message = errorInfo["message"] as? String {
                        completion(.failure(NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])))
                        return
                    }
                    
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let candidate = candidates.first,
                       let content = candidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let part = parts.first,
                       let text = part["text"] as? String {
                        completion(.success(text))
                    } else {
                        let errorString = String(data: data, encoding: .utf8) ?? "Unknown response format"
                        completion(.failure(NSError(domain: "GeminiService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(errorString)"])))
                    }
                } else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "GeminiService", code: 3, userInfo: [NSLocalizedDescriptionKey: errorString])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 