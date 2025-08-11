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
            
            // Capture mode toggle
            VStack {
                Spacer()
                
                HStack {
                    CaptureModeToggle()
                        .environmentObject(cameraService)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 200) // Above capture controls
            }
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
        HStack {
            // Close button
            Button {
                // Handle close - would typically dismiss or go back
                print("Close camera")
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Camera info/settings
            VStack(alignment: .trailing, spacing: 4) {
                if cameraService.isSessionRunning {
                    Text("●")
                        .foregroundColor(.red)
                        .font(.caption)
                    + Text(" REC")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                if AVCaptureMultiCamSession.isMultiCamSupported {
                    Text("DUAL CAM")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("SINGLE CAM")
                        .font(.caption2)
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            .padding()
            .background(.black.opacity(0.3))
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
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
                VStack(spacing: 20) {
                    // Image preview
                    imagePreviewSection
                    
                    // Caption input
                    captionSection
                    
                    // Location and visibility options
                    optionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await postWorkout()
                        }
                    }
                    .disabled(isPosting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewSection: some View {
        VStack(spacing: 16) {
            if let backImage = backImage {
                // Main back camera image
                Image(uiImage: backImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(12)
                
                // Front camera image (smaller)
                if let frontImage = frontImage {
                    HStack {
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 100)
                            .clipped()
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.headline)
            
            TextField("How was your workout?", text: $caption, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 16) {
            // Location toggle
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                
                Text("Add Location")
                    .font(.body)
                
                Spacer()
                
                Button("Add") {
                    showLocationPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Visibility setting
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.green)
                
                Text("Visible to Friends")
                    .font(.body)
                
                Spacer()
                
                Text("Friends Only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
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