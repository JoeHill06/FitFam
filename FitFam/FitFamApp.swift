//
//  FitFamApp.swift
//  FitFam
//
//  Created by Joe Hill on 10/08/2025.
//

import SwiftUI
import FirebaseCore

@main
struct FitFamApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        AppConfiguration.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
