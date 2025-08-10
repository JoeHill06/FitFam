//
//  ContentView.swift
//  FitFam
//
//  Created by Joe Hill on 10/08/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.needsOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else {
                    WorkoutStatusView()
                        .environmentObject(authViewModel)
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.needsOnboarding)
        .onChange(of: authViewModel.needsOnboarding) { _, newValue in
            print("🔄 needsOnboarding changed to: \(newValue)")
        }
        .onChange(of: authViewModel.currentUser?.isOnboarded) { _, newValue in
            print("🔄 User isOnboarded changed to: \(newValue ?? false)")
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            // Home Feed
            NavigationView {
                VStack {
                    Text("Home Feed")
                        .font(.title)
                        .padding()
                    
                    Text("Welcome \(authViewModel.currentUser?.displayName ?? "")!")
                        .font(.headline)
                        .padding()
                    
                    NavigationLink("Test Integration Page") {
                        TestView()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                    
                    Spacer()
                    
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .navigationTitle("FitFam")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            // Camera/Check-in
            Text("Camera View")
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Check-in")
                }
            
            // Groups
            Text("Groups View")
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }
            
            // Profile
            Text("Profile View")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
