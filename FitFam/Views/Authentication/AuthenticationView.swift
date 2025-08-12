import SwiftUI
import GoogleSignInSwift

struct AuthenticationView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var showPhoneSignIn = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.functional")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("FitFam")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Stay motivated with friends")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
                        .disabled(authViewModel.isLoading)
                    } else {
                        // Google Sign In - Official Button  
                        GoogleSignInButton(scheme: .light, style: .wide, state: .normal) {
                            Task {
                                await authViewModel.signInWithGoogle()
                            }
                        }
                        .frame(height: 50)
                        .disabled(authViewModel.isLoading)
                    }
                    
                    // Phone Sign In
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPhoneSignIn.toggle()
                        }
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
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                    .scaleEffect(authViewModel.isLoading ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: authViewModel.isLoading)
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
                            if authViewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                    Text("Sending...")
                                        .fontWeight(.semibold)
                                }
                            } else {
                                Text("Send Verification Code")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
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
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.next)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textContentType(showSignUp ? .newPassword : .password)
                            .submitLabel(.done)
                        
                        if showSignUp && !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        // Add haptic feedback
                        HapticManager.shared.mediumImpact()
                        
                        Task {
                            if showSignUp {
                                await authViewModel.signUp(email: email, password: password)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(showSignUp ? "Create Account" : "Sign In")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading || (showSignUp && password.count < 6))
                    .scaleEffect((email.isEmpty || password.isEmpty || authViewModel.isLoading || (showSignUp && password.count < 6)) ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: email.isEmpty)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: password.isEmpty)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: authViewModel.isLoading)
                    .overlay(
                        // Priority glow for main CTA when ready
                        (!email.isEmpty && !password.isEmpty && !authViewModel.isLoading && !(showSignUp && password.count < 6)) ? 
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.6), Color.red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .scaleEffect(1.05)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: true
                            ) : nil
                    )
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSignUp.toggle()
                        }
                        // Clear fields when switching modes
                        email = ""
                        password = ""
                    } label: {
                        Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    if !showSignUp {
                        Button {
                            Task {
                                await authViewModel.resetPassword(email: email)
                            }
                        } label: {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(email.isEmpty)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                
                    Spacer()
                    
                    // Terms and Privacy
                    VStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack {
                            Link("Terms of Service", destination: URL(string: AppEnvironment.termsOfServiceURL)!)
                                .foregroundColor(.red.opacity(0.8))
                            Text("and")
                                .foregroundColor(.white.opacity(0.6))
                            Link("Privacy Policy", destination: URL(string: AppEnvironment.privacyPolicyURL)!)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal, 24)
            }
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