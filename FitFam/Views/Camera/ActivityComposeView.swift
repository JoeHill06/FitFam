//
//  ActivityComposeView.swift
//  FitFam
//
//  Created by Claude on 15/08/2025.
//  
//  Full-screen activity selection and post composition view.
//  Replaces the modal picker with a dedicated posting screen.
//

import SwiftUI

struct ActivityComposeView: View {
    let frontImage: UIImage?
    let backImage: UIImage?
    let onDismiss: () -> Void
    let onPost: (ActivityType, String, Bool) -> Void
    
    @State private var selectedActivity: ActivityType?
    @State private var caption = ""
    @State private var includeLocation = false
    @State private var isVisible = false
    
    // Upload state
    @StateObject private var imageUploadService = ImageUploadService()
    @State private var isPosting = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignTokens.BackgroundColors.primary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Activity Selection Grid
                        activitySelectionGrid
                        
                        // Caption Section
                        captionSection
                        
                        // Location Toggle
                        locationSection
                        
                        // Spacer for bottom button
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.lg)
                }
                
                // Post Button (Fixed at bottom)
                VStack {
                    Spacer()
                    postButton
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.bottom, 34) // Account for home indicator
                }
                
                // Upload progress overlay
                if imageUploadService.isUploading || isPosting {
                    uploadProgressOverlay
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.lightTap()
                        withAnimation(.easeIn(duration: 0.25)) {
                            isVisible = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onDismiss()
                        }
                    }
                    .foregroundColor(DesignTokens.TextColors.secondary)
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Share Your Workout")
                .font(DesignTokens.Typography.Styles.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.TextColors.primary)
            
            Text("Select activity type and add details")
                .font(DesignTokens.Typography.Styles.body)
                .foregroundColor(DesignTokens.TextColors.secondary)
                .multilineTextAlignment(.center)
        }
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.4), value: isVisible)
    }
    
    // MARK: - Activity Selection Grid
    
    private var activitySelectionGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Activity Type")
                    .font(DesignTokens.Typography.Styles.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.TextColors.primary)
                
                Text("*")
                    .foregroundColor(DesignTokens.SemanticColors.error)
                
                Spacer()
            }
            
            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    ActivityCard(
                        activity: activity,
                        isSelected: selectedActivity == activity,
                        onTap: {
                            HapticManager.selection()
                            selectedActivity = activity
                            print("🎯 Activity selected: \(activity.displayName)")
                        }
                    )
                }
            }
            
            if selectedActivity == nil {
                Text("Please select an activity type")
                    .font(DesignTokens.Typography.Styles.footnote)
                    .foregroundColor(DesignTokens.SemanticColors.error)
                    .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .offset(y: isVisible ? 0 : 30)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Caption")
                .font(DesignTokens.Typography.Styles.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.TextColors.primary)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                TextField("How was your workout?", text: $caption, axis: .vertical)
                    .font(DesignTokens.Typography.Styles.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .fill(DesignTokens.SurfaceColors.elevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                                    .stroke(DesignTokens.BorderColors.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(DesignTokens.TextColors.primary)
                    .tint(DesignTokens.BrandColors.primary)
                    .lineLimit(2...4)
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
        }
        .offset(y: isVisible ? 0 : 30)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Location")
                .font(DesignTokens.Typography.Styles.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.TextColors.primary)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(DesignTokens.BrandColors.primary)
                    .font(.system(size: 16))
                
                Text("Include location")
                    .font(DesignTokens.Typography.Styles.body)
                    .foregroundColor(DesignTokens.TextColors.primary)
                
                Spacer()
                
                Toggle("", isOn: $includeLocation)
                    .tint(DesignTokens.BrandColors.primary)
                    .onChange(of: includeLocation) { _, newValue in
                        if newValue {
                            HapticManager.lightTap()
                        }
                    }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                    .fill(DesignTokens.SurfaceColors.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .stroke(DesignTokens.BorderColors.primary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .offset(y: isVisible ? 0 : 30)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
    }
    
    // MARK: - Post Button
    
    private var postButton: some View {
        Button(action: {
            guard let selectedActivity = selectedActivity else {
                HapticManager.warning()
                print("❌ Cannot post without activity selection")
                return
            }
            
            print("📝 Posting workout with activity: \(selectedActivity.displayName)")
            HapticManager.mediumTap()
            
            isPosting = true
            onPost(selectedActivity, caption.trimmingCharacters(in: .whitespacesAndNewlines), includeLocation)
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                if isPosting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Share Workout")
                        .font(DesignTokens.Typography.Styles.title3)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                    .fill(
                        selectedActivity == nil ? DesignTokens.TextColors.disabled :
                        (isPosting ? DesignTokens.BrandColors.primaryVariant : DesignTokens.BrandColors.primary)
                    )
                    .shadow(
                        color: selectedActivity != nil ? DesignTokens.BrandColors.primary.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(selectedActivity == nil || isPosting)
        .scaleEffect(selectedActivity == nil ? 0.98 : 1.0)
        .opacity(selectedActivity == nil ? 0.6 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedActivity != nil)
        .accessibilityLabel("Share workout post")
        .accessibilityHint("Publishes your workout to the feed")
        .offset(y: isVisible ? 0 : 50)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
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
                    Text("Sharing Workout")
                        .font(DesignTokens.Typography.Styles.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Please wait while we upload your workout")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Progress indicator
                if imageUploadService.isUploading {
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
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
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
}

// MARK: - Activity Card Component

struct ActivityCard: View {
    let activity: ActivityType
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Emoji Icon
                Text(activity.icon)
                    .font(.system(size: 48))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Activity Name
                Text(activity.displayName)
                    .font(DesignTokens.Typography.Styles.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(
                        isSelected ? DesignTokens.BrandColors.primary : DesignTokens.TextColors.primary
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                    .fill(
                        isSelected ? DesignTokens.BrandColors.primary.opacity(0.1) : 
                        (isPressed ? DesignTokens.SurfaceColors.pressed : DesignTokens.SurfaceColors.elevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                            .stroke(
                                isSelected ? DesignTokens.BrandColors.primary : 
                                DesignTokens.BorderColors.primary.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: isSelected ? DesignTokens.BrandColors.primary.opacity(0.3) : 
                DesignTokens.Shadows.sm.color,
                radius: isSelected ? 8 : DesignTokens.Shadows.sm.radius,
                x: DesignTokens.Shadows.sm.x,
                y: DesignTokens.Shadows.sm.y
            )
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ActivityComposeView(
        frontImage: nil,
        backImage: nil,
        onDismiss: {},
        onPost: { _, _, _ in }
    )
}