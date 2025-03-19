//
//  ContentView.swift
//  Drona
//
//  Created by Yaduraj Singh on 19/03/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userProfileManager = UserProfileManager()
    
    var body: some View {
        Group {
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

#Preview {
    ContentView()
}
