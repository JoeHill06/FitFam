import SwiftUI
import AVFoundation

/// Camera controls overlay with capture, flash, and mode switching
/// Positioned at bottom of screen with BeReal-style design
struct CameraControlsView: View {
    @EnvironmentObject var cameraService: CameraService
    @Binding var capturedImages: (front: UIImage?, back: UIImage?)?
    
    // Control state
    @State private var showFlashOptions = false
    @State private var captureTimer = 0
    @State private var isTimerActive = false
    
    // Layout constants
    private let controlHeight: CGFloat = 120
    private let captureButtonSize: CGFloat = 80
    private let smallButtonSize: CGFloat = 50
    
    var body: some View {
        VStack {
            Spacer()
            
            // Main controls container
            ZStack {
                // Background blur
                RoundedRectangle(cornerRadius: 40)
                    .fill(.ultraThinMaterial)
                    .frame(height: controlHeight)
                
                HStack {
                    // Flash toggle button
                    flashButton
                    
                    Spacer()
                    
                    // Main capture button
                    captureButton
                    
                    Spacer()
                    
                    // Camera switch button (for single cam mode)
                    switchCameraButton
                }
                .padding(.horizontal, 30)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Account for home indicator
        }
        .overlay(alignment: .center) {
            // Timer countdown overlay
            if isTimerActive {
                timerOverlay
            }
        }
    }
    
    // MARK: - Flash Button
    
    private var flashButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showFlashOptions.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.3))
                    .frame(width: smallButtonSize, height: smallButtonSize)
                
                Image(systemName: flashIconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .popover(isPresented: $showFlashOptions) {
            flashOptionsView
                .presentationCompactAdaptation(.popover)
        }
    }
    
    private var flashIconName: String {
        switch cameraService.flashMode {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.automatic.fill"
        @unknown default:
            return "bolt.fill"
        }
    }
    
    private var flashOptionsView: some View {
        VStack(spacing: 12) {
            flashOption(mode: .off, icon: "bolt.slash.fill", title: "Off")
            flashOption(mode: .on, icon: "bolt.fill", title: "On")
            flashOption(mode: .auto, icon: "bolt.badge.automatic.fill", title: "Auto")
        }
        .padding()
    }
    
    private func flashOption(mode: AVCaptureDevice.FlashMode, icon: String, title: String) -> some View {
        Button {
            cameraService.setFlashMode(mode)
            showFlashOptions = false
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                    .font(.body)
                Spacer()
                
                if cameraService.flashMode == mode {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        Button {
            print("📸 Capture button tapped")
            Task {
                await capturePhoto()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(lineWidth: 6)
                    .fill(.white)
                    .frame(width: captureButtonSize, height: captureButtonSize)
                
                // Inner circle - changes appearance during capture
                Circle()
                    .fill(cameraService.isCapturing ? .red : .white)
                    .frame(width: captureButtonSize - 16, height: captureButtonSize - 16)
                    .scaleEffect(cameraService.isCapturing ? 0.8 : 1.0)
                
                // Capture icon
                if !cameraService.isCapturing {
                    Image(systemName: cameraService.captureMode == .photo ? "camera.fill" : "video.fill")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
        }
        .disabled(cameraService.isCapturing || !cameraService.isSessionRunning)
        .scaleEffect(cameraService.isCapturing ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: cameraService.isCapturing)
    }
    
    // MARK: - Camera Switch Button
    
    private var switchCameraButton: some View {
        Button {
            print("🔄 Switch camera button tapped")
            cameraService.switchCamera()
        } label: {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.3))
                    .frame(width: smallButtonSize, height: smallButtonSize)
                
                // Use different icon for dual camera mode vs single camera mode
                Image(systemName: AVCaptureMultiCamSession.isMultiCamSupported ? 
                      "arrow.triangle.2.circlepath.camera" : "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .disabled(!cameraService.isSessionRunning)
    }
    
    // MARK: - Timer Overlay
    
    private var timerOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Countdown display
            Text("\(captureTimer)")
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.3), value: captureTimer)
        }
    }
    
    // MARK: - Capture Logic
    
    /// Capture photo with optional timer
    private func capturePhoto() async {
        // Start haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        
        // Capture the photo
        let result = await cameraService.capturePhoto()
        
        // Update captured images
        await MainActor.run {
            capturedImages = (front: result.frontImage, back: result.backImage)
            impactFeedback.impactOccurred()
        }
        
        // Log success
        print("📸 Photo captured - Front: \(result.frontImage != nil), Back: \(result.backImage != nil)")
    }
    
    /// Start countdown timer before capture
    private func startCaptureTimer(seconds: Int) {
        captureTimer = seconds
        isTimerActive = true
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            captureTimer -= 1
            
            if captureTimer <= 0 {
                timer.invalidate()
                isTimerActive = false
                
                Task {
                    await capturePhoto()
                }
            }
        }
    }
}

// MARK: - Mode Toggle

/// Toggle between photo and video modes
struct CaptureModeToggle: View {
    @EnvironmentObject var cameraService: CameraService
    
    var body: some View {
        HStack(spacing: 0) {
            modeButton(mode: .photo, title: "PHOTO")
            modeButton(mode: .video, title: "VIDEO")
        }
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func modeButton(mode: CameraService.CaptureMode, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                cameraService.captureMode = mode
            }
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(cameraService.captureMode == mode ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cameraService.captureMode == mode ? .white : .clear)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CameraControlsView(capturedImages: .constant(nil))
            .environmentObject(CameraService())
    }
}