//
//  FitFamApp.swift
//  FitFam
//
//  Created by Joe Hill on 10/08/2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct FitFamApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cameraService = CameraService() // Initialize camera service eagerly
    
    init() {
        AppConfiguration.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(cameraService) // Provide global camera service
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
