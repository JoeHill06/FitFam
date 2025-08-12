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
            VStack(spacing: DesignTokens.Spacing.lg) {
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
                .padding(.bottom, DesignTokens.Spacing.xl)
                
                // Google Options
                VStack(spacing: DesignTokens.Spacing.md) {
                    if showSignUp {
                        // Google Sign Up - Official Button
                        GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                            Task {
                                await authViewModel.signUpWithGoogle()
                            }
                        }
                        .frame(height: DesignTokens.InteractionSize.comfortable)
                    } else {
                        // Google Sign In - Official Button  
                        GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                            Task {
                                await authViewModel.signInWithGoogle()
                            }
                        }
                        .frame(height: DesignTokens.InteractionSize.comfortable)
                    }
                    
                    // Phone Sign In Button
                    Button {
                        HapticManager.lightTap()
                        showPhoneSignIn.toggle()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue with Phone")
                                .font(DesignTokens.Typography.bodyMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.InteractionSize.comfortable)
                        .background(DesignTokens.Colors.surfaceElevated)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .stroke(DesignTokens.Colors.border, lineWidth: 1)
                        )
                    }
                    .disabled(authViewModel.isLoading)
                }
                
                // Phone Number Input (conditional)
                if showPhoneSignIn {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        TextField("Phone Number (e.g., +1234567890)", text: $phoneNumber)
                            .font(DesignTokens.Typography.body)
                            .padding(DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.surfaceElevated)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
                            )
                            .keyboardType(.phonePad)
                        
                        Button {
                            HapticManager.mediumTap()
                            Task {
                                await authViewModel.signInWithPhone(phoneNumber: phoneNumber)
                            }
                        } label: {
                            Text("Send Verification Code")
                                .font(DesignTokens.Typography.bodyMedium)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignTokens.InteractionSize.comfortable)
                                .background(phoneNumber.isEmpty ? DesignTokens.Colors.surfaceElevated : DesignTokens.Colors.accent)
                                .foregroundColor(phoneNumber.isEmpty ? DesignTokens.Colors.textTertiary : DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.CornerRadius.md)
                        }
                        .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .animation(DesignTokens.Animation.medium, value: showPhoneSignIn)
                }
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignTokens.Colors.separator)
                    
                    Text("or")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignTokens.Colors.separator)
                }
                
                // Email/Password Form
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Email Field
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        TextField("Email", text: $email)
                            .font(DesignTokens.Typography.body)
                            .padding(DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.surfaceElevated)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(
                                        emailError != nil ? DesignTokens.Colors.error : DesignTokens.Colors.border,
                                        lineWidth: 1
                                    )
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _, newValue in
                                validateEmail(newValue)
                            }
                        
                        if let emailError = emailError {
                            Text(emailError)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.error)
                                .transition(.opacity)
                        }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        SecureField("Password", text: $password)
                            .font(DesignTokens.Typography.body)
                            .padding(DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.surfaceElevated)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(
                                        passwordError != nil ? DesignTokens.Colors.error : DesignTokens.Colors.border,
                                        lineWidth: 1
                                    )
                            )
                            .textContentType(showSignUp ? .newPassword : .password)
                            .onChange(of: password) { _, newValue in
                                validatePassword(newValue)
                            }
                        
                        if let passwordError = passwordError {
                            Text(passwordError)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.error)
                                .transition(.opacity)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Primary Action Button
                    Button {
                        HapticManager.mediumTap()
                        Task {
                            if showSignUp {
                                await authViewModel.signUp(email: email, password: password)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.textPrimary))
                                    .scaleEffect(0.8)
                            } else {
                                Text(showSignUp ? "Create Account" : "Sign In")
                                    .font(DesignTokens.Typography.bodyMedium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.InteractionSize.comfortable)
                        .background(
                            isFormValid && !authViewModel.isLoading ? DesignTokens.Colors.accent : DesignTokens.Colors.surfaceElevated
                        )
                        .foregroundColor(
                            isFormValid && !authViewModel.isLoading ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary
                        )
                        .cornerRadius(DesignTokens.CornerRadius.md)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    // Toggle Sign Up/In
                    Button {
                        HapticManager.lightTap()
                        showSignUp.toggle()
                        // Clear validation errors when switching
                        emailError = nil
                        passwordError = nil
                    } label: {
                        Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(DesignTokens.Typography.footnote)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    // Forgot Password
                    if !showSignUp {
                        Button {
                            HapticManager.lightTap()
                            Task {
                                await authViewModel.resetPassword(email: email)
                            }
                        } label: {
                            Text("Forgot Password?")
                                .font(DesignTokens.Typography.footnote)
                                .foregroundColor(DesignTokens.Colors.textTertiary)
                        }
                        .disabled(email.isEmpty)
                    }
                }
                
                Spacer()
                
                // Terms and Privacy
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("By continuing, you agree to our")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Link("Terms of Service", destination: URL(string: AppEnvironment.termsOfServiceURL)!)
                        Text("and")
                        Link("Privacy Policy", destination: URL(string: AppEnvironment.privacyPolicyURL)!)
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.accent)
                }
            }
            .padding(.horizontal, 24)
            .background(Color.black)
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
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
        } else {
            passwordError = nil
            isPasswordValid = true
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}