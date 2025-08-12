import SwiftUI
import GoogleSignInSwift

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var showPhoneSignIn = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var isEmailValid = false
    @State private var isPasswordValid = false
    
    // Computed properties for validation
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && emailError == nil && (showSignUp ? passwordError == nil : true)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "figure.strengthtraining.functional")
                        .font(.system(size: 60))
                        .foregroundColor(DesignTokens.Colors.accent)
                    
                    Text("FitFam")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Stay motivated with friends")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(.bottom, 32)
                
                // Google Options
                VStack(spacing: 12) {
                    if showSignUp {
                        // Google Sign Up - Official Button
                        GoogleSignInButton(scheme: .light, style: .wide, state: .normal) {
                            Task {
                                await authViewModel.signUpWithGoogle()
                            }
                        }
                        .frame(height: 50)
                    } else {
                        // Google Sign In - Official Button  
                        GoogleSignInButton(scheme: .light, style: .wide, state: .normal) {
                            Task {
                                await authViewModel.signInWithGoogle()
                            }
                        }
                        .frame(height: 50)
                    }
                    
                    // Phone Sign In
                    Button {
                        showPhoneSignIn.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white)
                            Text("Continue with Phone")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                    .disabled(authViewModel.isLoading)
                }
                
                // Phone Number Input (conditional)
                if showPhoneSignIn {
                    VStack(spacing: 12) {
                        TextField("Phone Number (e.g., +1234567890)", text: $phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                        
                        Button {
                            Task {
                                await authViewModel.signInWithPhone(phoneNumber: phoneNumber)
                            }
                        } label: {
                            Text("Send Verification Code")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
                    }
                    .transition(.slide)
                }
                
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
                
                // Email/Password Login Section
                
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
    
    // MARK: - Validation Methods
    private func validateEmail(_ email: String) {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if email.isEmpty {
            emailError = nil
            isEmailValid = false
        } else if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid email address"
            isEmailValid = false
        } else {
            emailError = nil
            isEmailValid = true
        }
    }
    
    private func validatePassword(_ password: String) {
        if !showSignUp {
            // For sign in, don't validate password complexity
            passwordError = nil
            isPasswordValid = !password.isEmpty
            return
        }
        
        // For sign up, validate password complexity
        if password.isEmpty {
            passwordError = nil
            isPasswordValid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            isPasswordValid = false
        } else if !password.contains(where: { $0.isLetter }) {
            passwordError = "Password must contain at least one letter"
            isPasswordValid = false
        } else if !password.contains(where: { $0.isNumber }) {
            passwordError = "Password must contain at least one number"
            isPasswordValid = false
        } else {
            passwordError = nil
            isPasswordValid = true
        }
    }
}

#Preview {
    AuthenticationView()
}