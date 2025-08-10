import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.functional")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("FitFam")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Stay motivated with friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
                
                // Sign in with Apple
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: { result in
                        Task {
                            await authViewModel.signInWithApple()
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(25)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                // Email/Password Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(showSignUp ? .newPassword : .password)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            if showSignUp {
                                await authViewModel.signUp(email: email, password: password)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(showSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    Button {
                        showSignUp.toggle()
                    } label: {
                        Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    
                    if !showSignUp {
                        Button {
                            Task {
                                await authViewModel.resetPassword(email: email)
                            }
                        } label: {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .disabled(email.isEmpty)
                    }
                }
                
                Spacer()
                
                // Terms and Privacy
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Link("Terms of Service", destination: URL(string: AppEnvironment.termsOfServiceURL)!)
                        Text("and")
                        Link("Privacy Policy", destination: URL(string: AppEnvironment.privacyPolicyURL)!)
                    }
                    .font(.caption)
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview {
    AuthenticationView()
}