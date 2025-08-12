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
            // Handle mirroring properly
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                // Front camera should be mirrored, back camera should not
                connection.isVideoMirrored = isMirrored
            }
            
            // Set proper orientation
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
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
    private let initialFrontCameraOffset: CGSize = CGSize(width: -20, height: 40)
    
    // Draggable state
    @State private var dragOffset: CGSize = .zero
    @State private var currentOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var isInitialized: Bool = false
    
    // Corner detection and animation helpers
    private func getCorners(in geometry: GeometryProxy) -> [CGSize] {
        let safeAreaTop: CGFloat = 50 // Reduced to move top tiles higher up on screen
        let padding: CGFloat = 30 // Increased side padding for better positioning
        let bottomPadding: CGFloat = 180 // Reduced since we removed capture mode toggle
        let halfWidth = frontCameraSize.width / 2
        let halfHeight = frontCameraSize.height / 2
        
        return [
            // Top-left
            CGSize(width: padding + halfWidth - geometry.size.width/2, 
                   height: safeAreaTop + halfHeight - geometry.size.height/2),
            // Top-right
            CGSize(width: geometry.size.width/2 - padding - halfWidth, 
                   height: safeAreaTop + halfHeight - geometry.size.height/2),
            // Bottom-left
            CGSize(width: padding + halfWidth - geometry.size.width/2, 
                   height: geometry.size.height/2 - bottomPadding - halfHeight),
            // Bottom-right
            CGSize(width: geometry.size.width/2 - padding - halfWidth, 
                   height: geometry.size.height/2 - bottomPadding - halfHeight)
        ]
    }
    
    private func nearestCorner(to position: CGSize, in geometry: GeometryProxy) -> CGSize {
        let corners = getCorners(in: geometry)
        return corners.min { corner1, corner2 in
            let distance1 = sqrt(pow(corner1.width - position.width, 2) + pow(corner1.height - position.height, 2))
            let distance2 = sqrt(pow(corner2.width - position.width, 2) + pow(corner2.height - position.height, 2))
            return distance1 < distance2
        } ?? corners[1] // Default to top-right
    }
    
    private func initialOffset(in geometry: GeometryProxy) -> CGSize {
        let corners = getCorners(in: geometry)
        return corners[1] // Start in top-right corner (same calculation as corner snapping)
    }
    
    private func effectiveOffset(in geometry: GeometryProxy) -> CGSize {
        if !isInitialized && currentOffset == .zero {
            // First time calculation - use initial position
            DispatchQueue.main.async {
                if !self.isInitialized {
                    self.currentOffset = self.initialOffset(in: geometry)
                    self.isInitialized = true
                }
            }
            return initialOffset(in: geometry)
        }
        return CGSize(
            width: currentOffset.width + dragOffset.width,
            height: currentOffset.height + dragOffset.height
        )
    }
    
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
                        
                        // Front camera - Draggable overlay
                        CameraPreviewView(
                            previewLayer: cameraService.getFrontPreviewLayer(),
                            cornerRadius: cornerRadius,
                            isMirrored: true
                        )
                        .frame(width: frontCameraSize.width, 
                               height: frontCameraSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(isDragging ? 0.8 : 0.3), lineWidth: isDragging ? 3 : 2)
                        )
                        .shadow(radius: isDragging ? 12 : 8)
                        .scaleEffect(isDragging ? 1.05 : 1.0)
                        .offset(x: effectiveOffset(in: geometry).width, 
                                y: effectiveOffset(in: geometry).height)
                        .onTapGesture {
                            if !isDragging {
                                cameraService.switchCamera()
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    let finalPosition = CGSize(
                                        width: currentOffset.width + dragOffset.width,
                                        height: currentOffset.height + dragOffset.height
                                    )
                                    
                                    let targetCorner = nearestCorner(to: finalPosition, in: geometry)
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        currentOffset = targetCorner
                                        dragOffset = .zero
                                        isDragging = false
                                    }
                                }
                        )
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                    } else {
                        // Front camera - Full screen background
                        CameraPreviewView(
                            previewLayer: cameraService.getFrontPreviewLayer(),
                            cornerRadius: 0,
                            isMirrored: true
                        )
                        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
                        
                        // Back camera - Draggable overlay
                        CameraPreviewView(
                            previewLayer: cameraService.getBackPreviewLayer(),
                            cornerRadius: cornerRadius,
                            isMirrored: false
                        )
                        .frame(width: frontCameraSize.width, 
                               height: frontCameraSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(isDragging ? 0.8 : 0.3), lineWidth: isDragging ? 3 : 2)
                        )
                        .shadow(radius: isDragging ? 12 : 8)
                        .scaleEffect(isDragging ? 1.05 : 1.0)
                        .offset(x: effectiveOffset(in: geometry).width, 
                                y: effectiveOffset(in: geometry).height)
                        .onTapGesture {
                            if !isDragging {
                                cameraService.switchCamera()
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    let finalPosition = CGSize(
                                        width: currentOffset.width + dragOffset.width,
                                        height: currentOffset.height + dragOffset.height
                                    )
                                    
                                    let targetCorner = nearestCorner(to: finalPosition, in: geometry)
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        currentOffset = targetCorner
                                        dragOffset = .zero
                                        isDragging = false
                                    }
                                }
                        )
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                    }
                } else if !cameraService.isAuthorized {
                    // Permission denied state
                    CameraPermissionView()
                } else if cameraService.isSessionConfigured {
                    // Session configured but not running - show instant preview
                    Color.black
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Starting Camera...")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding(.top, 8)
                            }
                        )
                        .onAppear {
                            // Retry starting the session after a short delay if stuck
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if cameraService.isSessionConfigured && !cameraService.isSessionRunning {
                                    print("🔄 Retrying camera session start...")
                                    cameraService.startSession()
                                }
                            }
                        }
                } else {
                    // Initial loading state
                    CameraLoadingView()
                }
            }
        }
        .onAppear {
            print("📱 Camera view appeared - starting session")
            cameraService.startSession()
        }
        .onDisappear {
            print("📱 Camera view disappeared - stopping session")
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