import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var firstName = ""
    @State private var surname = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    @State private var currentStep = 0
    
    private let steps = ["Welcome", "Sign In", "Profile", "Ready"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Progress Indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 1: Welcome
                    welcomeStep
                        .tag(0)
                    
                    // Step 2: Authentication
                    authenticationStep
                        .tag(1)
                    
                    // Step 3: Profile Setup
                    profileStep
                        .tag(2)
                    
                    // Step 4: Ready
                    readyStep
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .frame(minWidth: 80, minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 3 ? "Get Started" : "Next") {
                        // Add bounce animation and haptic feedback
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {}
                        HapticManager.shared.mediumImpact()
                        
                        if currentStep == 3 {
                            Task {
                                await completeOnboarding()
                            }
                        } else if currentStep == 1 {
                            // Authentication step - handle sign in
                            Task {
                                await handleAuthentication()
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                    }
                    .frame(minWidth: 120, minHeight: 48)
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
                    .font(.body)
                    .fontWeight(.bold)
                    .scaleEffect((currentStep == 2 && (firstName.isEmpty || surname.isEmpty || username.isEmpty || username.count < 3)) || 
                               (currentStep == 1 && !authViewModel.isAuthenticated) || 
                               authViewModel.isLoading ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: (currentStep == 2 && (firstName.isEmpty || surname.isEmpty || username.isEmpty || username.count < 3)))
                    .overlay(
                        // Special "Get Started" CTA priority animation
                        currentStep == 3 ? 
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .scaleEffect(1.1)
                            .opacity(0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: true
                            ) : nil
                    )
                    .disabled(
                        (currentStep == 2 && (firstName.isEmpty || surname.isEmpty || username.isEmpty || username.count < 3)) ||
                        (currentStep == 1 && !authViewModel.isAuthenticated) ||
                        authViewModel.isLoading
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // If user is already authenticated, skip to profile step
            if authViewModel.isAuthenticated && currentStep == 0 {
                currentStep = 2 // Skip to profile step
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    avatarData = data
                    if let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                Text("Welcome to FitFam!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Connect with friends and stay motivated on your fitness journey together.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "camera.fill", text: "Share daily workout photos")
                FeatureRow(icon: "flame.fill", text: "Track streaks with friends")
                FeatureRow(icon: "heart.fill", text: "React and encourage each other")
                FeatureRow(icon: "lock.fill", text: "Private groups only")
            }
            .padding(.horizontal)
        }
    }
    
    private var authenticationStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.key")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Sign In to Continue")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with friends and sync your progress across devices.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                // Google Sign In Button
                Button(action: {
                    Task {
                        await handleAuthentication()
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title3)
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading)
                
                if authViewModel.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Signed in successfully!")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var profileStep: some View {
        VStack(spacing: 32) {
            Text("Set up your profile")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 24) {
                // Avatar Selection
                VStack {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            if let avatarImage {
                                avatarImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            
                            Circle()
                                .strokeBorder(Color.red, lineWidth: 3)
                                .frame(width: 120, height: 120)
                        }
                    }
                    
                    Text("Add Profile Photo")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                
                // Form Fields
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            TextField("Enter your first name", text: $firstName)
                                .textFieldStyle(DarkTextFieldStyle())
                                .textContentType(.givenName)
                                .keyboardType(.default)
                                .autocapitalization(.words)
                                .disableAutocorrection(false)
                                .submitLabel(.next)
                                .onChange(of: firstName) { _, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed != newValue {
                                        firstName = trimmed
                                    }
                                    updateDisplayFields()
                                    if !trimmed.isEmpty {
                                        HapticManager.shared.lightTap()
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Surname")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            TextField("Enter your surname", text: $surname)
                                .textFieldStyle(DarkTextFieldStyle())
                                .textContentType(.familyName)
                                .keyboardType(.default)
                                .autocapitalization(.words)
                                .disableAutocorrection(false)
                                .submitLabel(.next)
                                .onChange(of: surname) { _, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed != newValue {
                                        surname = trimmed
                                    }
                                    updateDisplayFields()
                                    if !trimmed.isEmpty {
                                        HapticManager.shared.lightTap()
                                    }
                                }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            if !username.isEmpty && username.count < 3 {
                                Text("• At least 3 characters")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        TextField("Enter username (no spaces)", text: $username)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textContentType(.username)
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.next)
                            .onChange(of: username) { _, newValue in
                                let filtered = newValue.lowercased()
                                    .replacingOccurrences(of: " ", with: "")
                                    .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                if filtered != newValue {
                                    username = filtered
                                    HapticManager.shared.lightTap()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        TextField("How others will see you", text: $displayName)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textContentType(.name)
                            .keyboardType(.default)
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                            .submitLabel(.done)
                            .onChange(of: displayName) { _, newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed != newValue {
                                    displayName = trimmed
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var readyStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start your fitness journey by sharing your first workout or create/join a friend group.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.primary)
                    Text("@\(username)")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.primary)
                    Text(displayName)
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private func handleAuthentication() async {
        do {
            await authViewModel.signInWithGoogle()
            
            // Wait a moment for authentication state to update
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if authViewModel.isAuthenticated {
                // Success haptic and sound for authentication
                HapticManager.shared.success()
                SoundManager.shared.success()
                
                withAnimation {
                    currentStep += 1
                }
            }
        } catch {
            print("Authentication error: \(error)")
        }
    }
    
    private func updateDisplayFields() {
        // Auto-generate username and display name from first name and surname
        if !firstName.isEmpty && !surname.isEmpty {
            let generatedUsername = (firstName + surname).lowercased().replacingOccurrences(of: " ", with: "")
            let generatedDisplayName = "\(firstName) \(surname)"
            
            if username.isEmpty {
                username = generatedUsername
            }
            if displayName.isEmpty {
                displayName = generatedDisplayName
            }
        }
    }
    
    private func completeOnboarding() async {
        await authViewModel.completeOnboarding(
            firstName: firstName,
            surname: surname,
            username: username,
            displayName: displayName,
            avatarData: avatarData
        )
        
        // Celebration haptic and sound for completing onboarding
        HapticManager.shared.celebration()
        SoundManager.shared.achievement()
        
        // Force UI update after completion
        await MainActor.run {
            print("🎉 Onboarding completed! needsOnboarding: \(authViewModel.needsOnboarding)")
            print("🎉 currentUser isOnboarded: \(authViewModel.currentUser?.isOnboarded ?? false)")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct DarkTextFieldStyle: TextFieldStyle {
    @State private var isFocused = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(isFocused ? 0.15 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.red : Color.red.opacity(0.5), lineWidth: isFocused ? 2 : 1.5)
                            .shadow(color: isFocused ? Color.red.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                    )
            )
            .foregroundColor(.white)
            .font(.body)
            .fontWeight(.medium)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFocused = true
                    HapticManager.shared.lightTap()
                }
            }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}