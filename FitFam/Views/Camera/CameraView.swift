import SwiftUI
import AVFoundation

/// Main camera view combining dual preview and controls
/// Provides BeReal-style experience with front/back camera simultaneously
struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var capturedImages: (front: UIImage?, back: UIImage?)? = nil
    @State private var showPostComposer = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                .environmentObject(authViewModel)
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
    
    // MARK: - Image Management State
    @State private var isPrimaryImageFront = false // false = back camera primary, true = front camera primary
    @State private var pipPosition: PIPPosition = .topTrailing
    @State private var isDragging = false
    @State private var isPressed = false
    @State private var showCaptionOverlay = false
    
    // MARK: - Activity Selection State
    @State private var showActivityPicker = false
    
    // MARK: - Upload State
    @StateObject private var imageUploadService = ImageUploadService()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Full-screen main image background
            fullScreenImageView
            
            // Overlay content
            VStack {
                // Top navigation bar
                navigationHeader
                
                Spacer()
                
                // Bottom caption and options panel
                bottomPanel
            }
            
            // Upload progress overlay
            if imageUploadService.isUploading {
                uploadProgressOverlay
            }
        }
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }
        }
        .fullScreenCover(isPresented: $showActivityPicker) {
            ActivityComposeView(
                frontImage: frontImage,
                backImage: backImage,
                onDismiss: {
                    showActivityPicker = false
                },
                onPost: { activity, caption, includeLocation in
                    Task {
                        await postWorkout(activity: activity, caption: caption, includeLocation: includeLocation)
                    }
                }
            )
        }
    }
    
    // MARK: - Full Screen Image View
    
    private var fullScreenImageView: some View {
        GeometryReader { geometry in
            ZStack(alignment: pipPosition.alignment) {
                // Full-screen primary image
                if let backImage = backImage, let frontImage = frontImage {
                    Image(uiImage: isPrimaryImageFront ? frontImage : backImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .scaleEffect(isVisible ? 1.0 : 1.1)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6), value: isVisible)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPrimaryImageFront)
                    
                    // Interactive PIP for secondary image with enhanced styling
                    EnhancedInteractivePIPView(
                        image: isPrimaryImageFront ? backImage : frontImage,
                        position: $pipPosition,
                        isDragging: $isDragging,
                        isPressed: $isPressed,
                        onTap: swapPrimaryImage,
                        onDoubleTap: swapPrimaryImage,
                        isVisible: isVisible
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pipPosition)
                } else if let singleImage = backImage ?? frontImage {
                    // Single image fallback - full screen
                    Image(uiImage: singleImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .scaleEffect(isVisible ? 1.0 : 1.1)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6), value: isVisible)
                } else {
                    // Placeholder for no images
                    Rectangle()
                        .fill(DesignTokens.BackgroundColors.secondary)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            VStack(spacing: DesignTokens.Spacing.lg) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(DesignTokens.TextColors.tertiary)
                                Text("No image captured")
                                    .font(DesignTokens.Typography.Styles.title3)
                                    .foregroundColor(DesignTokens.TextColors.secondary)
                            }
                        )
                }
            }
        }
    }
    
    // MARK: - Navigation Header
    
    private var navigationHeader: some View {
        HStack {
            // Cancel button
            Button(action: {
                HapticManager.lightTap()
                dismissWithAnimation()
            }) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                    Text("Cancel")
                        .font(DesignTokens.Typography.Styles.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                        .fill(.black.opacity(0.4))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg))
                )
            }
            .accessibilityLabel("Cancel post creation")
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, 60) // Account for status bar
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: isVisible)
    }
    
    // MARK: - Bottom Panel
    
    private var bottomPanel: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Caption toggle button (optional)
            HStack {
                Spacer()
                Button(action: {
                    HapticManager.lightTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCaptionOverlay.toggle()
                    }
                }) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: showCaptionOverlay ? "text.bubble.fill" : "text.bubble")
                            .font(.system(size: 16, weight: .medium))
                        Text(showCaptionOverlay ? "Hide Caption" : "Add Caption")
                            .font(DesignTokens.Typography.Styles.footnote)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                            .fill(.black.opacity(0.5))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg))
                    )
                }
                Spacer()
            }
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)
            
            // Caption input panel (when shown)
            if showCaptionOverlay {
                captionInputPanel
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
            
            // Main Select Activity Button (always visible at bottom)
            selectActivityButton
                .offset(y: isVisible ? 0 : 30)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, 34) // Account for home indicator
    }
    
    // MARK: - Caption Input Panel
    
    private var captionInputPanel: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Caption text field
            VStack(spacing: DesignTokens.Spacing.xs) {
                TextField("How was your workout?", text: $caption, axis: .vertical)
                    .font(DesignTokens.Typography.Styles.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .fill(.black.opacity(0.6))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md))
                    )
                    .foregroundColor(.white)
                    .tint(DesignTokens.BrandColors.primary)
                    .lineLimit(2...4)
                    .accessibilityLabel("Workout caption")
                    .accessibilityHint("Describe your workout experience")
                
                HStack {
                    Spacer()
                    Text("\(caption.count)/280")
                        .font(DesignTokens.Typography.Styles.footnote)
                        .foregroundColor(
                            caption.count > 280 ? DesignTokens.SemanticColors.error : .white.opacity(0.7)
                        )
                        .animation(DesignTokens.Animation.fast, value: caption.count)
                }
            }
            
            
            // Quick location toggle
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(DesignTokens.BrandColors.primary)
                    .font(.system(size: 16))
                
                Text("Add Location")
                    .font(DesignTokens.Typography.Styles.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $showLocationPicker)
                    .tint(DesignTokens.BrandColors.primary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                    .fill(.black.opacity(0.4))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md))
            )
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    // MARK: - Select Activity Button
    
    private var selectActivityButton: some View {
        Button(action: {
            print("🎯 Select Activity button tapped")
            HapticManager.mediumTap()
            showActivityPicker = true
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "figure.run")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Activity")
                        .font(DesignTokens.Typography.Styles.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Choose your workout type")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .frame(minHeight: 56) // Minimum touch target
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                    .fill(DesignTokens.BrandColors.primary)
                    .shadow(
                        color: DesignTokens.BrandColors.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .accessibilityLabel("Select workout activity")
        .accessibilityHint("Tap to choose what type of workout you did")
        .onAppear {
            print("🎯 Select Activity button rendered")
        }
    }
    
    // MARK: - Upload Progress Overlay
    
    private var uploadProgressOverlay: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(.black.opacity(0.7))
                .ignoresSafeArea()
            
            // Progress content
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Upload status
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Uploading Post")
                        .font(DesignTokens.Typography.Styles.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Please wait while we upload your workout")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Progress bars
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Overall progress
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("Overall Progress")
                                .font(DesignTokens.Typography.Styles.footnote)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(imageUploadService.overallProgress * 100))%")
                                .font(DesignTokens.Typography.Styles.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        ProgressView(value: imageUploadService.overallProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.BrandColors.primary))
                            .scaleEffect(y: 2.0)
                    }
                    
                    // Individual progress bars
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        // Back camera progress
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text("📷 Back Camera")
                                .font(DesignTokens.Typography.Styles.caption1)
                                .foregroundColor(.white.opacity(0.8))
                            
                            ProgressView(value: imageUploadService.backImageProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.BrandColors.primary))
                                .scaleEffect(y: 1.5)
                        }
                        
                        // Front camera progress
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text("🤳 Front Camera")
                                .font(DesignTokens.Typography.Styles.caption1)
                                .foregroundColor(.white.opacity(0.8))
                            
                            ProgressView(value: imageUploadService.frontImageProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.BrandColors.primary))
                                .scaleEffect(y: 1.5)
                        }
                    }
                }
                
                // Error message if any
                if let error = imageUploadService.uploadError {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("Upload Failed")
                            .font(DesignTokens.Typography.Styles.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(DesignTokens.SemanticColors.error)
                        
                        Text(error)
                            .font(DesignTokens.Typography.Styles.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .fill(DesignTokens.SemanticColors.error.opacity(0.1))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md))
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: imageUploadService.isUploading)
    }
    
    // MARK: - Post Logic
    
    /// Upload images and create workout post
    private func postWorkout(activity: ActivityType, caption: String, includeLocation: Bool) async {
        guard !isPosting,
              let backImage = backImage,
              let frontImage = frontImage,
              let currentUser = authViewModel.currentUser else { 
            return 
        }
        
        await MainActor.run {
            isPosting = true
        }
        
        do {
            // 1. Create Firestore document first to get postId
            let postId = UUID().uuidString
            
            // 2. Upload both images to Firebase Storage
            let uploadResult = try await imageUploadService.uploadDualImages(
                backImage: backImage,
                frontImage: frontImage,
                postId: postId
            )
            
            // 3. Create Post object with dual image URLs
            let workoutData = WorkoutData(
                activityType: activity,
                duration: nil,
                distance: nil,
                calories: nil,
                intensity: nil
            )
            
            let location = includeLocation ? Location(
                latitude: 37.7749, // TODO: Use actual location
                longitude: -122.4194,
                name: "Current Location",
                address: nil
            ) : nil
            
            let post = Post(
                userID: currentUser.firebaseUID,
                username: currentUser.username,
                userAvatarURL: currentUser.avatarURL,
                postType: .checkIn,
                content: caption.isEmpty ? nil : caption,
                workoutData: workoutData,
                mediaURL: nil, // Keep for backward compatibility
                location: location,
                backImageUrl: uploadResult.backImageUrl,
                frontImageUrl: uploadResult.frontImageUrl,
                primaryCamera: isPrimaryImageFront ? "front" : "back",
                visibility: "friends"
            )
            
            // 4. Save to Firestore
            print("🚀 CameraView.postWorkout() - About to save post with ID: \(postId)")
            let firebaseService = FirebaseService()
            try await firebaseService.createPost(post, withId: postId)
            print("✅ CameraView.postWorkout() - Post saved successfully!")
            
            await MainActor.run {
                isPosting = false
                showActivityPicker = false // Close activity composer
                HapticManager.success()
                dismissWithAnimation() // Close post composer
            }
            
            print("✅ Posted workout successfully with dual images")
            
        } catch {
            await MainActor.run {
                isPosting = false
                HapticManager.warning()
            }
            
            print("❌ Failed to post workout: \(error)")
        }
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
    
    /// Swaps which image is primary (front vs back camera)
    private func swapPrimaryImage() {
        HapticManager.selection()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPrimaryImageFront.toggle()
        }
    }
}

// MARK: - Enhanced Interactive PIP View

/// Enhanced Picture-in-Picture view with softer styling for full-screen layout
struct EnhancedInteractivePIPView: View {
    let image: UIImage
    @Binding var position: PIPPosition
    @Binding var isDragging: Bool
    @Binding var isPressed: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let isVisible: Bool
    
    @State private var dragOffset = CGSize.zero
    @State private var lastDragPosition: CGPoint = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: pipSize.width, height: pipSize.height)
            .clipped()
            .cornerRadius(DesignTokens.BorderRadius.lg) // Softer edges
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                    .stroke(pipBorderColor, lineWidth: pipBorderWidth)
            )
            .shadow(
                color: pipShadowColor,
                radius: pipShadowRadius,
                x: 0,
                y: pipShadowY
            )
            .scaleEffect(pipScale)
            .opacity(pipOpacity)
            .offset(dragOffset)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.xl) // Extra vertical padding to avoid UI elements
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Tap to make this photo primary, or drag to reposition")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                handleTap()
            }
            .onTapGesture(count: 2) {
                handleDoubleTap()
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { pressing in
                handlePressChange(pressing)
            } perform: {}
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: position)
    }
    
    // MARK: - Computed Properties
    
    private var pipSize: CGSize {
        CGSize(width: 135, height: 175) // Larger size for better visibility in full-screen layout
    }
    
    private var pipScale: CGFloat {
        if isDragging { return 1.1 }
        if isPressed { return 0.95 }
        return isVisible ? 1.0 : 0.8
    }
    
    private var pipOpacity: Double {
        isVisible ? 1.0 : 0.0
    }
    
    private var pipBorderColor: Color {
        if isDragging { return DesignTokens.BrandColors.primary }
        if isPressed { return DesignTokens.BrandColors.primaryVariant }
        return .white.opacity(0.3) // Softer white border
    }
    
    private var pipBorderWidth: CGFloat {
        if isDragging { return 3 }
        if isPressed { return 2.5 }
        return 2
    }
    
    private var pipShadowColor: Color {
        if isDragging { return DesignTokens.BrandColors.primary.opacity(0.4) }
        return .black.opacity(0.3) // Subtle shadow
    }
    
    private var pipShadowRadius: CGFloat {
        isDragging ? 16 : 8
    }
    
    private var pipShadowY: CGFloat {
        isDragging ? 8 : 4
    }
    
    private var accessibilityLabel: String {
        "Picture-in-picture image in \(position.accessibilityLabel)"
    }
    
    // MARK: - Interaction Handlers
    
    private func handleTap() {
        HapticManager.selection()
        onTap()
    }
    
    private func handleDoubleTap() {
        HapticManager.mediumTap()
        onDoubleTap()
    }
    
    private func handlePressChange(_ pressing: Bool) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isPressed = pressing
        }
        
        if pressing {
            HapticManager.lightTap()
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            lastDragPosition = value.startLocation
        }
        
        dragOffset = value.translation
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let finalLocation = CGPoint(
            x: lastDragPosition.x + value.translation.width,
            y: lastDragPosition.y + value.translation.height
        )
        
        // Determine new position based on drag location
        let newPosition = determinePosition(from: finalLocation)
        
        if newPosition != position {
            HapticManager.success()
            position = newPosition
        }
        
        // Reset drag state
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDragging = false
            dragOffset = .zero
        }
    }
    
    private func determinePosition(from location: CGPoint) -> PIPPosition {
        // More intelligent positioning that considers screen bounds and UI elements
        // Assumes screen center for quadrant-based positioning
        let screenBounds = UIScreen.main.bounds
        let centerX = screenBounds.width / 2
        let centerY = screenBounds.height / 2
        
        let isLeft = location.x < centerX
        let isTop = location.y < centerY
        
        switch (isLeft, isTop) {
        case (true, true): return .topLeading
        case (false, true): return .topTrailing
        case (true, false): return .bottomLeading
        case (false, false): return .bottomTrailing
        }
    }
}

// MARK: - Interactive PIP View

/// Interactive Picture-in-Picture view with tap, double-tap, and drag functionality
struct InteractivePIPView: View {
    let image: UIImage
    @Binding var position: PIPPosition
    @Binding var isDragging: Bool
    @Binding var isPressed: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let isVisible: Bool
    
    @State private var dragOffset = CGSize.zero
    @State private var lastDragPosition: CGPoint = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: pipSize.width, height: pipSize.height)
            .clipped()
            .cornerRadius(DesignTokens.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                    .stroke(pipBorderColor, lineWidth: pipBorderWidth)
            )
            .shadow(
                color: pipShadowColor,
                radius: pipShadowRadius,
                x: 0,
                y: pipShadowY
            )
            .scaleEffect(pipScale)
            .opacity(pipOpacity)
            .offset(dragOffset)
            .padding(DesignTokens.Spacing.lg)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Tap to make this photo primary, or drag to reposition")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                handleTap()
            }
            .onTapGesture(count: 2) {
                handleDoubleTap()
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { pressing in
                handlePressChange(pressing)
            } perform: {}
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: position)
    }
    
    // MARK: - Computed Properties
    
    private var pipSize: CGSize {
        CGSize(width: 100, height: 130)
    }
    
    private var pipScale: CGFloat {
        if isDragging { return 1.1 }
        if isPressed { return 0.95 }
        return isVisible ? 1.0 : 0.8
    }
    
    private var pipOpacity: Double {
        isVisible ? 1.0 : 0.0
    }
    
    private var pipBorderColor: Color {
        if isDragging { return DesignTokens.BrandColors.primary }
        if isPressed { return DesignTokens.BrandColors.primaryVariant }
        return DesignTokens.BackgroundColors.primary
    }
    
    private var pipBorderWidth: CGFloat {
        if isDragging { return 4 }
        if isPressed { return 3 }
        return 3
    }
    
    private var pipShadowColor: Color {
        if isDragging { return DesignTokens.BrandColors.primary.opacity(0.3) }
        return DesignTokens.Shadows.md.color
    }
    
    private var pipShadowRadius: CGFloat {
        isDragging ? 12 : DesignTokens.Shadows.md.radius
    }
    
    private var pipShadowY: CGFloat {
        isDragging ? 6 : DesignTokens.Shadows.md.y
    }
    
    private var accessibilityLabel: String {
        "Picture-in-picture image in \(position.accessibilityLabel)"
    }
    
    // MARK: - Interaction Handlers
    
    private func handleTap() {
        HapticManager.selection()
        onTap()
    }
    
    private func handleDoubleTap() {
        HapticManager.mediumTap()
        onDoubleTap()
    }
    
    private func handlePressChange(_ pressing: Bool) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isPressed = pressing
        }
        
        if pressing {
            HapticManager.lightTap()
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            lastDragPosition = value.startLocation
        }
        
        dragOffset = value.translation
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let finalLocation = CGPoint(
            x: lastDragPosition.x + value.translation.width,
            y: lastDragPosition.y + value.translation.height
        )
        
        // Determine new position based on drag location
        let newPosition = determinePosition(from: finalLocation)
        
        if newPosition != position {
            HapticManager.success()
            position = newPosition
        }
        
        // Reset drag state
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDragging = false
            dragOffset = .zero
        }
    }
    
    private func determinePosition(from location: CGPoint) -> PIPPosition {
        // Simple quadrant-based positioning
        // You could make this more sophisticated based on screen bounds
        let isLeft = location.x < 200 // Rough center point
        let isTop = location.y < 200
        
        switch (isLeft, isTop) {
        case (true, true): return .topLeading
        case (false, true): return .topTrailing
        case (true, false): return .bottomLeading
        case (false, false): return .bottomTrailing
        }
    }
}

// MARK: - PIP Position Enum

/// Positions for the Picture-in-Picture overlay
enum PIPPosition: CaseIterable {
    case topLeading
    case topTrailing  
    case bottomLeading
    case bottomTrailing
    
    var alignment: Alignment {
        switch self {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .topLeading: return "Top left corner"
        case .topTrailing: return "Top right corner" 
        case .bottomLeading: return "Bottom left corner"
        case .bottomTrailing: return "Bottom right corner"
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView()
}