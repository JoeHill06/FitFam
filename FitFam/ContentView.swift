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
    @State private var showExercisePrompt = false
    @State private var hasShownExercisePrompt = false
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.needsOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView(selectedTab: $selectedTab)
                        .environmentObject(authViewModel)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        .tokenBackground(DesignTokens.BackgroundColors.primary)
        .preferredColorScheme(.dark)
        .animation(DesignTokens.Animation.normal, value: authViewModel.isAuthenticated)
        .animation(DesignTokens.Animation.normal, value: authViewModel.needsOnboarding)
        .onChange(of: authViewModel.needsOnboarding) { _, newValue in
            print("🔄 needsOnboarding changed to: \(newValue)")
        }
        .onChange(of: authViewModel.currentUser?.isOnboarded) { _, newValue in
            print("🔄 User isOnboarded changed to: \(newValue ?? false)")
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            // Show exercise prompt once per cold app launch when user becomes authenticated
            // and doesn't need onboarding
            if isAuthenticated && !authViewModel.needsOnboarding && !hasShownExercisePrompt {
                showExercisePrompt = true
                hasShownExercisePrompt = true
            }
        }
        .fullScreenCover(isPresented: $showExercisePrompt) {
            ExercisePromptModalView { response in
                handleExercisePromptResponse(response)
            }
        }
    }
    
    // MARK: - Exercise Prompt Response Handler
    
    private func handleExercisePromptResponse(_ response: ExercisePromptResponse) {
        showExercisePrompt = false
        
        switch response {
        case .yes:
            // Navigate to camera for workout check-in
            selectedTab = 2
            
        case .restDay:
            // Navigate to camera with rest day mode (same as regular for now)
            selectedTab = 2
            
        case .no:
            // Dismiss and land on Home feed
            selectedTab = 0
        }
        
        HapticManager.success()
    }
}

// MARK: - MainTabView

/// Main tab-based navigation for authenticated users
struct MainTabView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedTab: Int                   // Currently selected tab index
    
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
        .accentColor(DesignTokens.BrandColors.primary)
        .tokenBackground(DesignTokens.BackgroundColors.primary)
        .preferredColorScheme(.dark)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.adaptive(light: "#FFFFFF", dark: "#000000")
            
            // Selected tab item
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.adaptive(light: "#FF3B30", dark: "#FF453A")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.adaptive(light: "#FF3B30", dark: "#FF453A")
            ]
            
            // Unselected tab item
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.adaptive(light: "#757575", dark: "#EBEBF5")
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.adaptive(light: "#757575", dark: "#EBEBF5")
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: selectedTab) { _, newTab in
            HapticManager.tabChanged()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if !isAuth {
                // Reset tab selection when user signs out
                selectedTab = 0
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

#Preview("Main Tab View") {
    MainTabView(selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
}
