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
    @State private var isVisible = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Image preview
                    imagePreviewSection
                    
                    // Caption input
                    captionSection
                    
                    // Location and visibility options
                    optionsSection
                    
                    Spacer(minLength: DesignTokens.Spacing.xl4)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .tokenBackground(DesignTokens.BackgroundColors.primary)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.BackgroundColors.secondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    TextButton("Cancel", color: DesignTokens.TextColors.secondary) {
                        HapticManager.lightTap()
                        dismissWithAnimation()
                    }
                    .accessibilityLabel("Cancel post creation")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.BrandColors.primary))
                            .scaleEffect(0.8)
                    } else {
                        TextButton("Post", color: DesignTokens.BrandColors.primary) {
                            HapticManager.mediumTap()
                            Task {
                                await postWorkout()
                            }
                        }
                        .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Share workout post")
                        .accessibilityHint("Publishes your workout to the feed")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if let backImage = backImage {
                // Main back camera image with enhanced styling
                ZStack(alignment: .topLeading) {
                    Image(uiImage: backImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 400)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(DesignTokens.BorderRadius.lg)
                        .shadow(
                            color: DesignTokens.Shadows.md.color,
                            radius: DesignTokens.Shadows.md.radius,
                            x: DesignTokens.Shadows.md.x,
                            y: DesignTokens.Shadows.md.y
                        )
                    
                    // Front camera image overlay (BeReal style)
                    if let frontImage = frontImage {
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 130)
                            .clipped()
                            .cornerRadius(DesignTokens.BorderRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                                    .stroke(DesignTokens.BackgroundColors.primary, lineWidth: 3)
                            )
                            .shadow(
                                color: DesignTokens.Shadows.sm.color,
                                radius: DesignTokens.Shadows.sm.radius,
                                x: DesignTokens.Shadows.sm.x,
                                y: DesignTokens.Shadows.sm.y
                            )
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.leading, DesignTokens.Spacing.lg)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .opacity(isVisible ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
                    }
                }
                .scaleEffect(isVisible ? 1.0 : 0.95)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4), value: isVisible)
            } else {
                // Placeholder if no images
                Rectangle()
                    .fill(DesignTokens.BackgroundColors.secondary)
                    .frame(height: 400)
                    .cornerRadius(DesignTokens.BorderRadius.lg)
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundColor(DesignTokens.TextColors.tertiary)
                            Text("No image captured")
                                .font(DesignTokens.Typography.Styles.body)
                                .foregroundColor(DesignTokens.TextColors.secondary)
                        }
                    )
            }
        }
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Caption")
                .font(DesignTokens.Typography.Styles.headline)
                .foregroundColor(DesignTokens.TextColors.primary)
                .offset(y: isVisible ? 0 : 10)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isVisible)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                TextField("How was your workout?", text: $caption, axis: .vertical)
                    .font(DesignTokens.Typography.Styles.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.BackgroundColors.secondary)
                    .cornerRadius(DesignTokens.BorderRadius.md)
                    .foregroundColor(DesignTokens.TextColors.primary)
                    .tint(DesignTokens.BrandColors.primary)
                    .lineLimit(3...8)
                    .accessibilityLabel("Workout caption")
                    .accessibilityHint("Describe your workout experience")
                
                HStack {
                    Spacer()
                    Text("\(caption.count)/280")
                        .font(DesignTokens.Typography.Styles.footnote)
                        .foregroundColor(
                            caption.count > 280 ? DesignTokens.SemanticColors.error : DesignTokens.TextColors.tertiary
                        )
                        .animation(DesignTokens.Animation.fast, value: caption.count)
                }
            }
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Location toggle
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(DesignTokens.SemanticColors.info)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Add Location")
                        .font(DesignTokens.Typography.Styles.bodyMedium)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    Text("Share where you worked out")
                        .font(DesignTokens.Typography.Styles.caption1)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                
                Spacer()
                
                TextButton("Add", color: DesignTokens.BrandColors.primary) {
                    HapticManager.lightTap()
                    showLocationPicker = true
                }
                .accessibilityLabel("Add workout location")
            }
            .padding(DesignTokens.Spacing.md)
            .tokenSurface(
                backgroundColor: DesignTokens.BackgroundColors.secondary,
                cornerRadius: DesignTokens.BorderRadius.md,
                shadow: DesignTokens.Shadows.sm
            )
            .offset(y: isVisible ? 0 : 30)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
            
            // Visibility setting
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(DesignTokens.SemanticColors.success)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Visible to Friends")
                        .font(DesignTokens.Typography.Styles.bodyMedium)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    Text("Only your friends can see this post")
                        .font(DesignTokens.Typography.Styles.caption1)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.SemanticColors.success)
                    .font(.system(size: 18))
            }
            .padding(DesignTokens.Spacing.md)
            .tokenSurface(
                backgroundColor: DesignTokens.BackgroundColors.secondary,
                cornerRadius: DesignTokens.BorderRadius.md,
                shadow: DesignTokens.Shadows.sm
            )
            .offset(y: isVisible ? 0 : 40)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
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
            HapticManager.success()
            dismissWithAnimation()
        }
        
        print("📤 Posted workout with caption: \(caption)")
    }
    
    /// Dismisses the view with smooth animation
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView()
}