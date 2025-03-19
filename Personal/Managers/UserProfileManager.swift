//
//  UserProfileManager.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import Foundation
import SwiftUI

class UserProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isProfileCreated: Bool = false
    
    private let userDefaultsKey = "dronaUserProfile"
    
    // Add a shared singleton instance
    static let shared = UserProfileManager()
    
    init() {
        loadProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        userProfile = profile
        isProfileCreated = true
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func loadProfile() {
        if let savedProfile = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
                userProfile = decodedProfile
                isProfileCreated = true
                return
            }
        }
        isProfileCreated = false
    }
    
    func updateProfile(_ profile: UserProfile) {
        saveProfile(profile)
    }
    
    func clearProfile() {
        userProfile = nil
        isProfileCreated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
} 