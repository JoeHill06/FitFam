import SwiftUI

struct WorkoutStatusView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showCamera = false
    @State private var selectedOption: WorkoutOption?
    
    enum WorkoutOption {
        case yes, no, restDay
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Title Section
                VStack(spacing: 16) {
                    Text("💪")
                        .font(.system(size: 80))
                    
                    Text("Are you working out today?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Options Section
                VStack(spacing: 20) {
                    // Yes Button
                    Button {
                        selectedOption = .yes
                        showCamera = true
                    } label: {
                        HStack {
                            Text("🔥")
                                .font(.system(size: 24))
                            Text("Yes!")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(selectedOption == .yes ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: selectedOption)
                    
                    // No Button  
                    Button {
                        selectedOption = .no
                        // Stay on this screen or navigate elsewhere
                    } label: {
                        HStack {
                            Text("😴")
                                .font(.system(size: 24))
                            Text("No")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(selectedOption == .no ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: selectedOption)
                    
                    // Rest Day Button
                    Button {
                        selectedOption = .restDay
                        showCamera = true
                    } label: {
                        HStack {
                            Text("🛋️")
                                .font(.system(size: 24))
                            Text("Rest day")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(selectedOption == .restDay ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: selectedOption)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // User Info
                if let user = authViewModel.currentUser {
                    VStack(spacing: 8) {
                        Text("Welcome back!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(user.displayName.isEmpty ? user.email : user.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCamera) {
                CameraPlaceholderView(workoutType: selectedOption == .yes ? "Workout" : "Rest Day")
            }
        }
    }
}

struct CameraPlaceholderView: View {
    let workoutType: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
                
                Text("Camera Feature")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("📸 \(workoutType) Camera")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("This camera feature will be developed later.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .padding(.bottom, 50)
            }
            .navigationTitle("\(workoutType) Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutStatusView()
        .environmentObject(AuthViewModel())
}