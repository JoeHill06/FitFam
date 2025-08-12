import SwiftUI
import AVFoundation

/// Main camera view combining dual preview and controls
/// Provides BeReal-style experience with front/back camera simultaneously
struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var capturedImages: (front: UIImage?, back: UIImage?)? = nil
    @State private var showPostComposer = false
    
    var body: some View {
        ZStack {
            // Camera preview (full screen)
            DualCameraPreviewView()
                .environmentObject(cameraService)
            
            // Top UI overlay
            VStack {
                topOverlay
                Spacer()
            }
            
            // Bottom controls
            CameraControlsView(capturedImages: $capturedImages)
                .environmentObject(cameraService)
            
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onChange(of: capturedImages != nil) { _, hasImages in
            if hasImages {
                showPostComposer = true
            }
        }
        .fullScreenCover(isPresented: $showPostComposer) {
            if let images = capturedImages {
                PostComposerView(
                    frontImage: images.front,
                    backImage: images.back,
                    onDismiss: {
                        showPostComposer = false
                        capturedImages = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Top Overlay
    
    private var topOverlay: some View {
        EmptyView()
    }
}

/// Post composer view for adding captions and posting
/// Shown after photo capture
struct PostComposerView: View {
    let frontImage: UIImage?
    let backImage: UIImage?
    let onDismiss: () -> Void
    
    @State private var caption = ""
    @State private var isPosting = false
    @State private var showLocationPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Image preview
                    imagePreviewSection
                    
                    // Caption input
                    captionSection
                    
                    // Simplified options
                    simpleOptionsSection
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Share Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        Task {
                            await postWorkout()
                        }
                    }
                    .disabled(isPosting)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if let backImage = backImage {
                    // Main back camera image (full width, proper aspect ratio)
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width * 1.2)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // Front camera image (overlay in corner)
                    if let frontImage = frontImage {
                        VStack {
                            HStack {
                                Spacer()
                                Image(uiImage: frontImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 120)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * 1.2)
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share your experience")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("How was your workout?", text: $caption, axis: .vertical)
                .textFieldStyle(DarkTextFieldStyle())
                .lineLimit(3...6)
                .submitLabel(.done)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Simple Options Section
    
    private var simpleOptionsSection: some View {
        VStack(spacing: 12) {
            // Simple visibility indicator
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sharing with friends")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Only your FitFam can see this")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Post Logic
    
    /// Upload images and create workout post
    private func postWorkout() async {
        guard !isPosting else { return }
        
        await MainActor.run {
            isPosting = true
        }
        
        // TODO: Implement actual posting logic
        // 1. Upload images to Firebase Storage
        // 2. Create WorkoutCheckIn object
        // 3. Save to Firestore
        // 4. Update user streak
        
        // Simulate posting delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isPosting = false
            onDismiss()
        }
        
        print("📤 Posted workout with caption: \(caption)")
    }
}

// MARK: - Preview

#Preview {
    CameraView()
}