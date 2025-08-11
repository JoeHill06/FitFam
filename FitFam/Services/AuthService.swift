import Foundation
import FirebaseAuth
import FirebaseCore
import Combine
import GoogleSignIn
import UIKit

class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("🔧 Firebase not configured - running in demo mode")
            self.user = nil
            return
        }
        
        self.user = Auth.auth().currentUser
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
            }
        }
    }
    
    // Google Sign In
    func signInWithGoogle() async throws {
        guard FirebaseApp.app() != nil else {
            await MainActor.run { errorMessage = "Firebase not configured. Add GoogleService-Info.plist to enable authentication." }
            throw AuthError.unknown
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        // Get the presenting view controller
        guard let presentingViewController = await MainActor.run(body: {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        }) else {
            await MainActor.run { errorMessage = "Could not find presenting view controller" }
            throw AuthError.unknown
        }
        
        do {
            print("🚀 Starting Google Sign In...")
            
            // Perform Google Sign In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            print("✅ Google Sign In completed, processing tokens...")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ Failed to get Google ID token")
                await MainActor.run { errorMessage = "Failed to get Google ID token" }
                throw AuthError.invalidCredentials
            }
            
            let accessToken = result.user.accessToken.tokenString
            print("✅ Got Google tokens, creating Firebase credential...")
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            print("✅ Firebase credential created, signing in...")
            
            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)
            await MainActor.run { self.user = authResult.user }
            
            print("✅ Google Sign In successful for user: \(authResult.user.email ?? "unknown")")
            
        } catch let error as NSError {
            print("❌ Google Sign In error: \(error)")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error userInfo: \(error.userInfo)")
            
            // Handle specific Google Sign In errors
            if error.domain == "com.google.GIDSignIn" {
                switch error.code {
                case -2: // User canceled
                    await MainActor.run { errorMessage = "Google Sign In was cancelled" }
                case -4: // No internet connection
                    await MainActor.run { errorMessage = "No internet connection" }
                default:
                    await MainActor.run { errorMessage = "Google Sign In failed: \(error.localizedDescription)" }
                }
            } else {
                await MainActor.run { errorMessage = "Google Sign In failed: \(error.localizedDescription)" }
            }
            throw error
        }
    }
    
    // Phone Sign In
    func signInWithPhone(phoneNumber: String) async throws {
        guard FirebaseApp.app() != nil else {
            await MainActor.run { errorMessage = "Firebase not configured. Add GoogleService-Info.plist to enable authentication." }
            throw AuthError.unknown
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        // TODO: Implement Phone Sign In
        await MainActor.run { errorMessage = "Phone Sign In coming soon!" }
        throw AuthError.unknown
    }
    
    func signIn(email: String, password: String) async throws {
        guard FirebaseApp.app() != nil else {
            await MainActor.run { errorMessage = "Firebase not configured. Add GoogleService-Info.plist to enable authentication." }
            throw AuthError.unknown
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run { self.user = result.user }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run { self.user = result.user }
        } catch {
            print("🔴 Firebase Auth Error: \(error)")
            if let authError = error as NSError? {
                print("🔴 Error Code: \(authError.code)")
                print("🔴 Error Domain: \(authError.domain)")
                print("🔴 Error Details: \(authError.userInfo)")
            }
            await MainActor.run { errorMessage = error.localizedDescription }
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            throw error
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        Task { @MainActor in self.user = nil }
    }
    
    func deleteAccount() async throws {
        guard let user = user else {
            throw AuthError.noUser
        }
        
        try await user.delete()
        self.user = nil
    }
}

enum AuthError: LocalizedError {
    case noUser
    case invalidCredentials
    case networkError
    case cancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .cancelled:
            return "Sign in was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

