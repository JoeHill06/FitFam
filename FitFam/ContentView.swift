//
//  ContentView.swift
//  FitFam
//
//  Created by Joe Hill on 10/08/2025.
//  Enhanced by Claude on 10/08/2025.
//
//  Root view managing app navigation flow: Authentication → Onboarding → Main App
//  Handles state transitions between different app phases based on user authentication status.
//

import SwiftUI

/// Root content view handling app navigation flow
struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - Body
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.needsOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        .primaryBackground()
        .preferredColorScheme(.dark)
        .animation(DesignTokens.Animation.medium, value: authViewModel.isAuthenticated)
        .animation(DesignTokens.Animation.medium, value: authViewModel.needsOnboarding)
        .onChange(of: authViewModel.needsOnboarding) { _, newValue in
            print("🔄 needsOnboarding changed to: \(newValue)")
        }
        .onChange(of: authViewModel.currentUser?.isOnboarded) { _, newValue in
            print("🔄 User isOnboarded changed to: \(newValue ?? false)")
        }
    }
}

// MARK: - MainTabView

/// Main tab-based navigation for authenticated users
struct MainTabView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0              // Currently selected tab index
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed
            HomeFeedView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Activity Map
            ActivityMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(1)
            
            // Camera/Check-in - Keep our dual camera functionality
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Check-in")
                }
                .tag(2)
            
            // Stats & Streaks
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
                .tag(3)
            
            // Profile & Settings
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(DesignTokens.Colors.accent)
        .primaryBackground()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
