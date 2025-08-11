import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
/// Displays camera feed with proper aspect ratio and mirroring
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    let cornerRadius: CGFloat
    let isMirrored: Bool
    
    init(previewLayer: AVCaptureVideoPreviewLayer, 
         cornerRadius: CGFloat = 12, 
         isMirrored: Bool = false) {
        self.previewLayer = previewLayer
        self.cornerRadius = cornerRadius
        self.isMirrored = isMirrored
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        
        // Configure preview layer
        previewLayer.frame = view.bounds
        previewLayer.cornerRadius = cornerRadius
        
        // Apply mirroring and orientation
        if let connection = previewLayer.connection {
            // Handle mirroring - flip both cameras horizontally
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                if isMirrored {
                    // Front camera - flip horizontally (opposite of before)
                    connection.isVideoMirrored = false
                } else {
                    // Back camera - flip horizontally too
                    connection.isVideoMirrored = true
                }
            }
            
            // Fix orientation - flip both cameras vertically
            if connection.isVideoOrientationSupported {
                if isMirrored {
                    // Front camera - flip vertically (opposite of before)
                    connection.videoOrientation = .portrait
                } else {
                    // Back camera - flip vertically too
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view bounds change
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

/// Dual camera preview layout matching BeReal/Instagram style
/// Shows large back camera with smaller front camera overlay
struct DualCameraPreviewView: View {
    @EnvironmentObject var cameraService: CameraService
    
    // Layout configuration
    private let frontCameraSize: CGSize = CGSize(width: 120, height: 160)
    private let cornerRadius: CGFloat = 12
    private let frontCameraOffset: CGSize = CGSize(width: -20, height: 40)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - Black for loading state
                Color.black
                    .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
                
                if cameraService.isSessionRunning {
                    if cameraService.isBackCameraPrimary {
                        // Back camera - Full screen background
                        CameraPreviewView(
                            previewLayer: cameraService.getBackPreviewLayer(),
                            cornerRadius: 0,
                            isMirrored: false
                        )
                        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
                        
                        // Front camera - Small overlay in top right (clickable)
                        VStack {
                            HStack {
                                Spacer()
                                
                                CameraPreviewView(
                                    previewLayer: cameraService.getFrontPreviewLayer(),
                                    cornerRadius: cornerRadius,
                                    isMirrored: true
                                )
                                .frame(width: frontCameraSize.width, 
                                       height: frontCameraSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(radius: 8)
                                .offset(frontCameraOffset)
                                .onTapGesture {
                                    cameraService.switchCamera()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 60) // Account for status bar
                        .padding(.trailing, 20)
                    } else {
                        // Front camera - Full screen background
                        CameraPreviewView(
                            previewLayer: cameraService.getFrontPreviewLayer(),
                            cornerRadius: 0,
                            isMirrored: true
                        )
                        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
                        
                        // Back camera - Small overlay in top right (clickable)
                        VStack {
                            HStack {
                                Spacer()
                                
                                CameraPreviewView(
                                    previewLayer: cameraService.getBackPreviewLayer(),
                                    cornerRadius: cornerRadius,
                                    isMirrored: false
                                )
                                .frame(width: frontCameraSize.width, 
                                       height: frontCameraSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(radius: 8)
                                .offset(frontCameraOffset)
                                .onTapGesture {
                                    cameraService.switchCamera()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 60) // Account for status bar
                        .padding(.trailing, 20)
                    }
                } else if !cameraService.isAuthorized {
                    // Permission denied state
                    CameraPermissionView()
                } else {
                    // Loading state
                    CameraLoadingView()
                }
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .alert("Camera Error", isPresented: .constant(cameraService.error != nil)) {
            Button("OK") {
                cameraService.error = nil
            }
        } message: {
            Text(cameraService.error?.errorDescription ?? "Unknown error occurred")
        }
        .environmentObject(cameraService)
    }
}

/// Permission request view shown when camera access is denied
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("FitFam needs camera access to capture your workout photos. Please enable camera permission in Settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 32)
    }
}

/// Loading view shown while camera is initializing
struct CameraLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Initializing Camera...")
                .foregroundColor(.white)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    DualCameraPreviewView()
}