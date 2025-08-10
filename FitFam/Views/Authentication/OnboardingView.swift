import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var displayName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    @State private var currentStep = 0
    
    private let steps = ["Welcome", "Profile", "Ready"]
    
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
                    
                    // Step 2: Profile Setup
                    profileStep
                        .tag(1)
                    
                    // Step 3: Ready
                    readyStep
                        .tag(2)
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
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Get Started" : "Next") {
                        if currentStep == 2 {
                            Task {
                                await completeOnboarding()
                            }
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        (currentStep == 1 && (username.isEmpty || displayName.isEmpty)) ||
                        authViewModel.isLoading
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
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
    
    private var profileStep: some View {
        VStack(spacing: 32) {
            Text("Set up your profile")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 24) {
                // Avatar Selection
                VStack {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            if let avatarImage {
                                avatarImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            }
                            
                            Circle()
                                .strokeBorder(.primary, lineWidth: 2)
                                .frame(width: 100, height: 100)
                        }
                    }
                    
                    Text("Add Profile Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        TextField("Enter username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.headline)
                        TextField("Enter display name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                    }
                }
            }
        }
        .padding(.horizontal)
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
    
    private func completeOnboarding() async {
        await authViewModel.completeOnboarding(
            username: username,
            displayName: displayName,
            avatarData: avatarData
        )
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

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}