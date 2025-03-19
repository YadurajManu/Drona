//
//  DronaApp.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

@main
struct DronaApp: App {
    @StateObject private var userProfileManager = UserProfileManager()
    
    var body: some Scene {
        WindowGroup {
            if userProfileManager.isProfileCreated {
                MainTabView()
                    .environmentObject(userProfileManager)
            } else {
                OnboardingView()
                    .environmentObject(userProfileManager)
            }
        }
    }
}
