import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let authService: AuthService
    private let firebaseService: FirebaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService = AuthService(), firebaseService: FirebaseService = FirebaseService()) {
        self.authService = authService
        self.firebaseService = firebaseService
        
        setupBindings()
        checkAuthenticationState()
    }
    
    private func setupBindings() {
        authService.$user
            .sink { [weak self] firebaseUser in
                Task {
                    await self?.handleAuthStateChange(firebaseUser)
                }
            }
            .store(in: &cancellables)
        
        authService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        authService.$errorMessage
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAuthenticationState() {
        isAuthenticated = authService.user != nil
        
        if let firebaseUser = authService.user {
            Task {
                await loadUser(firebaseUID: firebaseUser.uid)
            }
        }
    }
    
    private func handleAuthStateChange(_ firebaseUser: FirebaseAuth.User?) async {
        if let firebaseUser = firebaseUser {
            await loadUser(firebaseUID: firebaseUser.uid)
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    private func loadUser(firebaseUID: String) async {
        do {
            currentUser = try await firebaseService.getUser(by: firebaseUID)
        } catch {
            print("Error loading user: \(error.localizedDescription)")
        }
    }
    
    func signInWithApple() async {
        do {
            try await authService.signInWithApple()
            
            guard let firebaseUser = authService.user else {
                showError("Failed to get user information")
                return
            }
            
            let existingUser = try await firebaseService.getUser(by: firebaseUser.uid)
            if existingUser == nil {
                await createNewUser(from: firebaseUser)
            }
        } catch {
            showError("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please enter both email and password")
            return
        }
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            showError("Sign in failed: \(error.localizedDescription)")
        }
    }
    
    func signUp(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please enter both email and password")
            return
        }
        
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters long")
            return
        }
        
        do {
            try await authService.signUp(email: email, password: password)
            
            guard let firebaseUser = authService.user else {
                showError("Failed to get user information")
                return
            }
            
            await createNewUser(from: firebaseUser)
        } catch {
            showError("Sign up failed: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            showError("Please enter your email address")
            return
        }
        
        do {
            try await authService.resetPassword(email: email)
            showError("Password reset email sent. Please check your inbox.")
        } catch {
            showError("Failed to send password reset email: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            showError("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        guard let user = currentUser else { return }
        
        do {
            try await authService.deleteAccount()
            currentUser = nil
            isAuthenticated = false
        } catch {
            showError("Failed to delete account: \(error.localizedDescription)")
        }
    }
    
    func completeOnboarding(username: String, displayName: String, avatarData: Data? = nil) async {
        guard var user = currentUser else {
            showError("No user found")
            return
        }
        
        isLoading = true
        
        do {
            if let avatarData = avatarData {
                let avatarURL = try await firebaseService.uploadMedia(
                    data: avatarData,
                    path: "avatars/\(user.firebaseUID).jpg",
                    contentType: "image/jpeg"
                )
                user.avatarURL = avatarURL
            }
            
            user.username = username
            user.displayName = displayName
            user.isOnboarded = true
            
            try await firebaseService.updateUser(user)
            currentUser = user
            
            print("✅ Onboarding completed for user: \(user.username)")
            print("✅ User isOnboarded: \(user.isOnboarded)")
            print("✅ needsOnboarding: \(needsOnboarding)")
            
        } catch {
            showError("Failed to complete onboarding: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func createNewUser(from firebaseUser: FirebaseAuth.User) async {
        let user = User(
            firebaseUID: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            username: "",
            displayName: firebaseUser.displayName ?? ""
        )
        
        do {
            try await firebaseService.createUser(user)
            currentUser = user
        } catch {
            showError("Failed to create user profile: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    var needsOnboarding: Bool {
        guard let user = currentUser else { return false }
        return !user.isOnboarded
    }
    
    var isEmailUser: Bool {
        authService.user?.providerData.contains { $0.providerID == "password" } ?? false
    }
}