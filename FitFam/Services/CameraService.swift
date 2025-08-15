import Foundation
import AVFoundation
import UIKit
import Combine
import SwiftUI

/// Service for handling dual camera capture with BeReal-style front/back simultaneous recording
/// Supports both multi-cam (iPhone XS+) and sequential capture fallback for older devices
@MainActor
class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var isSessionConfigured = false // Track if session is configured but not necessarily running
    @Published var previewLayersUpdated = false // Track when preview layers are recreated
    @Published var captureMode: CaptureMode = .photo
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isCapturing = false
    @Published var error: CameraError?
    @Published var isBackCameraPrimary = true // Track which camera is the main view for dual camera
    @Published var isCameraViewActive = false // Track if camera view is currently active
    
    // MARK: - Private Properties
    private let captureSession = AVCaptureMultiCamSession()
    private var frontCameraInput: AVCaptureDeviceInput?
    private var backCameraInput: AVCaptureDeviceInput?
    
    // Photo outputs
    private let frontPhotoOutput = AVCapturePhotoOutput()
    private let backPhotoOutput = AVCapturePhotoOutput()
    
    // Video outputs  
    private let frontVideoOutput = AVCaptureVideoDataOutput()
    private let backVideoOutput = AVCaptureVideoDataOutput()
    
    // Preview layers - Pre-create for faster access
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isStoppingSession = false
    private var sessionTask: Task<Void, Never>?
    private var isMultiCamSupported: Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    // Cache camera devices for faster access
    private var frontCameraDevice: AVCaptureDevice?
    private var backCameraDevice: AVCaptureDevice?
    
    // Keep references to photo capture delegates to prevent deallocation
    private var photoCaptureInProgress = Set<PhotoCaptureDelegate>()
    
    // MARK: - Enums
    enum CaptureMode {
        case photo
        case video
    }
    
    enum CameraPosition {
        case front
        case back
        case dual
    }
    
    enum CameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case multiCamNotSupported
        case deviceNotAvailable
        case captureSessionError(String)
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access not authorized. Please enable in Settings."
            case .configurationFailed:
                return "Failed to configure camera session."
            case .multiCamNotSupported:
                return "Multi-camera not supported on this device."
            case .deviceNotAvailable:
                return "Camera device not available."
            case .captureSessionError(let message):
                return "Camera session error: \(message)"
            case .unknown(let error):
                return "Unknown camera error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Pre-cache camera devices immediately for faster session setup
        Task {
            await precacheCameraDevices()
        }
        checkCameraAuthorization()
    }
    
    /// Prepare session configuration and start it for instant loading
    func prepareSession() async {
        print("🚀 Pre-configuring and starting camera session for instant loading...")
        
        guard isAuthorized else {
            print("❌ Cannot prepare session - camera not authorized")
            return
        }
        
        guard !isSessionConfigured else {
            print("ℹ️ Camera session already configured")
            return
        }
        
        // Configure and start the session immediately for instant loading
        await configureSession(startRunning: true)
    }
    
    // MARK: - Authorization
    
    /// Check and request camera authorization
    private func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📹 Camera authorization status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("✅ Camera access authorized")
            isAuthorized = true
            // Immediately prepare session when already authorized
            Task {
                await prepareSession()
            }
        case .notDetermined:
            print("❓ Camera access not determined - requesting...")
            requestCameraAuthorization()
        case .denied:
            print("❌ Camera access denied")
            isAuthorized = false
        case .restricted:
            print("🚫 Camera access restricted")
            isAuthorized = false
        @unknown default:
            print("⚠️ Unknown camera authorization status")
            isAuthorized = false
        }
    }
    
    /// Request camera permission from user
    private func requestCameraAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.isAuthorized = granted
                // If authorized, prepare the session immediately
                if granted {
                    await self?.prepareSession()
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Start the camera session (configure first if needed)
    func startSession() {
        print("🎥 Starting camera session...")
        print("🔐 Camera authorized: \(isAuthorized)")
        print("🔄 Session currently running: \(isSessionRunning)")
        print("⚙️ Session configured: \(isSessionConfigured)")
        
        guard isAuthorized else {
            print("❌ Camera not authorized")
            error = .notAuthorized
            return
        }
        
        // Don't start if already running, but refresh preview layers
        if isSessionRunning {
            print("ℹ️ Camera session already running, refreshing preview layers")
            // Force preview layer refresh for when returning to camera view
            Task {
                await reconnectPreviewLayers()
                await MainActor.run {
                    self.previewLayersUpdated.toggle()
                }
            }
            return
        }
        
        // Cancel any existing session task
        sessionTask?.cancel()
        
        sessionTask = Task { [weak self] in
            // Wait for any stopping operation to complete
            while self?.isStoppingSession == true {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            if self?.isSessionRunning == true {
                print("ℹ️ Session already running - nothing to do")
                return
            }
            
            if self?.isSessionConfigured == true {
                // Session already configured - just start it
                await self?.startConfiguredSession()
            } else {
                // Configure and start
                await self?.configureSession(startRunning: true)
            }
            
            // Always ensure preview layers are reconnected after any session start
            await self?.reconnectPreviewLayers()
            await MainActor.run {
                self?.previewLayersUpdated.toggle()
            }
        }
    }
    
    /// Start an already configured session
    private func startConfiguredSession() async {
        print("▶️ Starting pre-configured session...")
        
        guard isSessionConfigured && !captureSession.isRunning else {
            print("❌ Session not configured or already running")
            return
        }
        
        // Start session on session queue for better reliability
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
                continuation.resume()
            }
        }
        
        // Verify session started and update state
        await MainActor.run {
            self.isSessionRunning = self.captureSession.isRunning
        }
        
        if captureSession.isRunning {
            // Ensure preview layers are connected after session restart
            await reconnectPreviewLayers()
            await MainActor.run {
                self.previewLayersUpdated.toggle()
            }
            print("✅ Pre-configured session started instantly!")
        } else {
            print("❌ Failed to start pre-configured session")
        }
    }
    
    /// Stop the camera session
    func stopSession() {
        // Cancel any running session start task
        sessionTask?.cancel()
        
        Task { [weak self] in
            await self?.stopSessionAsync()
        }
    }
    
    private func stopSessionAsync() async {
        await MainActor.run {
            self.isStoppingSession = true
        }
        
        guard captureSession.isRunning else {
            await MainActor.run {
                self.isSessionRunning = false
                self.isStoppingSession = false
            }
            return
        }
        
        print("⏹️ Stopping camera session...")
        
        // Stop running on session queue for better reliability
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                self?.captureSession.stopRunning()
                continuation.resume()
            }
        }
        
        // Give the session a moment to fully stop
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            self.isSessionRunning = false
            self.isStoppingSession = false
        }
        
        print("✅ Camera session stopped")
    }
    
    /// Reconnect preview layers to the session if they became disconnected
    private func reconnectPreviewLayers() async {
        guard let frontLayer = frontPreviewLayer, let backLayer = backPreviewLayer else { 
            print("⚠️ Preview layers not available for reconnection")
            return 
        }
        
        print("🔗 Simple preview layer reconnection...")
        
        // Simple reconnection - just ensure layers are connected to session
        if isMultiCamSupported {
            frontLayer.setSessionWithNoConnection(captureSession)
            backLayer.setSessionWithNoConnection(captureSession)
        } else {
            frontLayer.session = captureSession
            backLayer.session = captureSession
        }
        
        print("✅ Simple preview layer reconnection complete")
    }
    
    /// Clean up capture session inputs and outputs
    private func cleanupSession() {
        print("🧹 Cleaning up capture session...")
        
        // Remove all inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        // Remove all outputs
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        // Remove all connections
        for connection in captureSession.connections {
            captureSession.removeConnection(connection)
        }
        
        // Clear camera input references
        frontCameraInput = nil
        backCameraInput = nil
        
        // Clear preview layer references to force recreation
        frontPreviewLayer = nil
        backPreviewLayer = nil
        
        // Reset configuration state
        isSessionConfigured = false
        
        print("✅ Capture session cleaned up")
    }
    
    /// Pre-cache camera devices for faster session setup
    private func precacheCameraDevices() async {
        let (front, back) = await withTaskGroup(of: AVCaptureDevice?.self, returning: (AVCaptureDevice?, AVCaptureDevice?).self) { group in
            group.addTask {
                return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            }
            group.addTask {
                return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            }
            
            var frontDevice: AVCaptureDevice?
            var backDevice: AVCaptureDevice?
            
            for await device in group {
                if device?.position == .front {
                    frontDevice = device
                } else if device?.position == .back {
                    backDevice = device
                }
            }
            
            return (frontDevice, backDevice)
        }
        
        await MainActor.run {
            self.frontCameraDevice = front
            self.backCameraDevice = back
        }
        
        print("🚀 Camera devices pre-cached for faster initialization")
    }
    
    /// Configure dual camera session with fallback to single camera
    private func configureSession(startRunning: Bool = true) async {
        print("⚙️ Configuring camera session...")
        print("📱 Multi-cam supported: \(isMultiCamSupported)")
        
        // Clean up any existing configuration first
        if !captureSession.inputs.isEmpty || !captureSession.outputs.isEmpty {
            print("🧩 Cleaning existing session configuration...")
            cleanupSession()
        }
        
        captureSession.beginConfiguration()
        
        do {
            // Try to configure dual camera setup
            if isMultiCamSupported {
                print("🔄 Attempting dual camera setup...")
                do {
                    try configureDualCameraSession()
                } catch {
                    print("⚠️ Dual camera setup failed, falling back to single camera: \(error)")
                    // Clean up any partially configured inputs/outputs
                    cleanupSession()
                    try configureSingleCameraSession()
                }
            } else {
                print("🔄 Using single camera fallback...")
                try configureSingleCameraSession()
            }
            
            captureSession.commitConfiguration()
            
            await MainActor.run {
                self.isSessionConfigured = true
                print("✅ Camera session configured successfully!")
            }
            
            if startRunning {
                print("▶️ Starting capture session...")
                captureSession.startRunning()
                
                // Ensure preview layers are properly connected after configuration
                await reconnectPreviewLayers()
                
                await MainActor.run {
                    self.isSessionRunning = true
                    print("✅ Camera session started successfully!")
                }
            } else {
                print("⏸️ Session configured but not started (for instant loading)")
            }
            
        } catch {
            print("❌ Camera configuration failed: \(error)")
            captureSession.commitConfiguration()
            
            await MainActor.run {
                self.error = .unknown(error)
            }
        }
    }
    
    /// Configure dual camera session for devices that support multi-cam
    private func configureDualCameraSession() throws {
        print("🔄 Configuring dual camera inputs...")
        
        // Use pre-cached devices or fall back to discovery
        let frontDevice = frontCameraDevice ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        let backDevice = backCameraDevice ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let frontDevice = frontDevice else {
            throw CameraError.deviceNotAvailable
        }
        
        guard let backDevice = backDevice else {
            throw CameraError.deviceNotAvailable
        }
        
        // Configure both cameras in parallel
        let frontInput = try AVCaptureDeviceInput(device: frontDevice)
        let backInput = try AVCaptureDeviceInput(device: backDevice)
        
        guard captureSession.canAddInput(frontInput), captureSession.canAddInput(backInput) else {
            throw CameraError.configurationFailed
        }
        
        captureSession.addInputWithNoConnections(frontInput)
        captureSession.addInputWithNoConnections(backInput)
        frontCameraInput = frontInput
        backCameraInput = backInput
        print("✅ Both camera inputs added")
        
        // Add outputs and create connections
        try addOutputsAndConnections()
        
        // Create preview connections manually for dual cam
        try createPreviewConnections()
        
        print("✅ Dual camera session configured successfully")
    }
    
    /// Create manual preview connections for dual camera
    private func createPreviewConnections() throws {
        // For multi-cam, use sessionWithNoConnections and manually create connections
        if isMultiCamSupported {
            // Create preview layers without automatic connections
            frontPreviewLayer = AVCaptureVideoPreviewLayer()
            frontPreviewLayer?.setSessionWithNoConnection(captureSession)
            frontPreviewLayer?.videoGravity = .resizeAspectFill
            
            backPreviewLayer = AVCaptureVideoPreviewLayer()
            backPreviewLayer?.setSessionWithNoConnection(captureSession)
            backPreviewLayer?.videoGravity = .resizeAspectFill
            
            // Manually create preview connections
            try createManualPreviewConnections()
        } else {
            // For single cam, use regular session
            frontPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            frontPreviewLayer?.videoGravity = .resizeAspectFill
            
            backPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            backPreviewLayer?.videoGravity = .resizeAspectFill
        }
        
        print("📺 Preview layers created for \(isMultiCamSupported ? "multi-cam" : "single-cam")")
    }
    
    /// Create manual preview layer connections for multi-cam
    private func createManualPreviewConnections() throws {
        guard let frontInput = frontCameraInput,
              let backInput = backCameraInput,
              let frontLayer = frontPreviewLayer,
              let backLayer = backPreviewLayer else {
            throw CameraError.configurationFailed
        }
        
        // Front camera preview connection
        if let frontVideoPort = frontInput.ports(for: .video, 
                                                sourceDeviceType: frontInput.device.deviceType, 
                                                sourceDevicePosition: frontInput.device.position).first {
            let frontPreviewConnection = AVCaptureConnection(inputPort: frontVideoPort, videoPreviewLayer: frontLayer)
            if captureSession.canAddConnection(frontPreviewConnection) {
                captureSession.addConnection(frontPreviewConnection)
                print("✅ Front camera preview connection added")
            }
        }
        
        // Back camera preview connection
        if let backVideoPort = backInput.ports(for: .video,
                                              sourceDeviceType: backInput.device.deviceType,
                                              sourceDevicePosition: backInput.device.position).first {
            let backPreviewConnection = AVCaptureConnection(inputPort: backVideoPort, videoPreviewLayer: backLayer)
            if captureSession.canAddConnection(backPreviewConnection) {
                captureSession.addConnection(backPreviewConnection)
                print("✅ Back camera preview connection added")
            }
        }
    }
    
    /// Fallback single camera configuration for older devices
    private func configureSingleCameraSession() throws {
        // Use pre-cached device or fall back to discovery
        let backDevice = backCameraDevice ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let backDevice = backDevice else {
            throw CameraError.deviceNotAvailable
        }
        
        let backInput = try AVCaptureDeviceInput(device: backDevice)
        guard captureSession.canAddInput(backInput) else {
            throw CameraError.configurationFailed
        }
        
        captureSession.addInput(backInput)
        backCameraInput = backInput
        
        // Add back camera output
        if captureSession.canAddOutput(backPhotoOutput) {
            captureSession.addOutput(backPhotoOutput)
        }
        
        print("✅ Single camera session configured (multi-cam not supported)")
    }
    
    /// Add outputs and create manual connections for multi-cam
    private func addOutputsAndConnections() throws {
        print("🔌 Adding photo outputs and connections...")
        
        // Add photo outputs
        guard captureSession.canAddOutput(frontPhotoOutput),
              captureSession.canAddOutput(backPhotoOutput) else {
            print("❌ Cannot add photo outputs")
            throw CameraError.configurationFailed
        }
        
        captureSession.addOutputWithNoConnections(frontPhotoOutput)
        captureSession.addOutputWithNoConnections(backPhotoOutput)
        print("✅ Photo outputs added")
        
        // Create connections manually
        guard let frontInput = frontCameraInput,
              let backInput = backCameraInput else {
            print("❌ Camera inputs not available for connections")
            throw CameraError.configurationFailed
        }
        
        var connectionsCreated = 0
        
        // Front camera connection
        if let frontVideoPort = frontInput.ports(for: .video, 
                                                sourceDeviceType: frontInput.device.deviceType, 
                                                sourceDevicePosition: frontInput.device.position).first {
            let frontPhotoConnection = AVCaptureConnection(inputPorts: [frontVideoPort], 
                                                          output: frontPhotoOutput)
            if captureSession.canAddConnection(frontPhotoConnection) {
                captureSession.addConnection(frontPhotoConnection)
                connectionsCreated += 1
                print("✅ Front camera photo connection added")
            } else {
                print("❌ Cannot add front camera photo connection")
            }
        } else {
            print("❌ Front camera video port not found")
        }
        
        // Back camera connection
        if let backVideoPort = backInput.ports(for: .video,
                                              sourceDeviceType: backInput.device.deviceType,
                                              sourceDevicePosition: backInput.device.position).first {
            let backPhotoConnection = AVCaptureConnection(inputPorts: [backVideoPort], 
                                                         output: backPhotoOutput)
            if captureSession.canAddConnection(backPhotoConnection) {
                captureSession.addConnection(backPhotoConnection)
                connectionsCreated += 1
                print("✅ Back camera photo connection added")
            } else {
                print("❌ Cannot add back camera photo connection")
            }
        } else {
            print("❌ Back camera video port not found")
        }
        
        // Ensure at least one connection was created
        guard connectionsCreated > 0 else {
            print("❌ No camera connections could be created")
            throw CameraError.configurationFailed
        }
        
        print("🔌 Photo outputs and connections configured")
    }
    
    // MARK: - Preview Layers
    
    /// Get front camera preview layer
    func getFrontPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let existingLayer = frontPreviewLayer {
            return existingLayer
        }
        
        // Fallback creation if not pre-created
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        
        frontPreviewLayer = layer
        print("📱 Front camera preview layer created (fallback)")
        return layer
    }
    
    /// Get back camera preview layer  
    func getBackPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let existingLayer = backPreviewLayer {
            return existingLayer
        }
        
        // Fallback creation if not pre-created
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        
        backPreviewLayer = layer
        print("📱 Back camera preview layer created (fallback)")
        return layer
    }
    
    // MARK: - Flash Control
    
    /// Set flash mode for back camera
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        guard let backDevice = backCameraInput?.device else { return }
        
        do {
            try backDevice.lockForConfiguration()
            
            if backDevice.hasFlash && backDevice.isFlashModeSupported(mode) {
                flashMode = mode
                print("💡 Flash mode set to: \(mode.rawValue)")
            } else {
                print("⚠️ Flash mode \(mode.rawValue) not supported")
            }
            
            backDevice.unlockForConfiguration()
        } catch {
            print("❌ Failed to set flash mode: \(error)")
        }
    }
    
    // MARK: - Camera Switching
    
    /// Toggle which camera is primary in dual camera mode, or switch cameras in single camera mode
    func switchCamera() {
        if isMultiCamSupported {
            // For dual camera, toggle which camera is primary
            withAnimation(.easeInOut(duration: 0.3)) {
                isBackCameraPrimary.toggle()
            }
            print("🔄 Switched camera view - Back camera primary: \(isBackCameraPrimary)")
            return
        }
        
        // For single camera mode, physically switch between cameras
        
        Task { @MainActor in
            captureSession.beginConfiguration()
            
            // Remove current input
            if let currentInput = backCameraInput {
                captureSession.removeInput(currentInput)
            }
            if let currentInput = frontCameraInput {
                captureSession.removeInput(currentInput)
            }
            
            do {
                // Switch to opposite camera
                if backCameraInput != nil {
                    // Switch to front
                    guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                        throw CameraError.deviceNotAvailable
                    }
                    let frontInput = try AVCaptureDeviceInput(device: frontDevice)
                    
                    if captureSession.canAddInput(frontInput) {
                        captureSession.addInput(frontInput)
                        frontCameraInput = frontInput
                        backCameraInput = nil
                        print("📱 Switched to front camera")
                    }
                } else {
                    // Switch to back
                    guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        throw CameraError.deviceNotAvailable
                    }
                    let backInput = try AVCaptureDeviceInput(device: backDevice)
                    
                    if captureSession.canAddInput(backInput) {
                        captureSession.addInput(backInput)
                        backCameraInput = backInput
                        frontCameraInput = nil
                        print("📱 Switched to back camera")
                    }
                }
            } catch {
                print("❌ Camera switch failed: \(error)")
            }
            
            captureSession.commitConfiguration()
        }
    }
    
    // MARK: - Capture
    
    /// Capture photo from both cameras simultaneously (or sequentially on older devices)
    func capturePhoto() async -> (frontImage: UIImage?, backImage: UIImage?) {
        print("📸 Capture photo requested")
        
        // Immediate haptic feedback for camera capture
        HapticManager.mediumTap()
        
        guard !isCapturing else {
            print("❌ Already capturing, ignoring request")
            return (nil, nil)
        }
        
        guard isSessionRunning else {
            print("❌ Camera session not running")
            return (nil, nil)
        }
        
        await MainActor.run {
            isCapturing = true
        }
        
        defer {
            Task { @MainActor in
                isCapturing = false
            }
        }
        
        print("🔄 Capturing with multi-cam: \(isMultiCamSupported), front input available: \(frontCameraInput != nil)")
        
        if isMultiCamSupported && frontCameraInput != nil {
            return await captureDualPhoto()
        } else {
            return await captureSinglePhoto()
        }
    }
    
    /// Capture from both cameras simultaneously
    private func captureDualPhoto() async -> (frontImage: UIImage?, backImage: UIImage?) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        return await withTaskGroup(of: (UIImage?, Bool).self, returning: (UIImage?, UIImage?).self) { group in
            group.addTask {
                let image = await self.capturePhotoFromOutput(self.frontPhotoOutput, settings: settings)
                return (image, true) // true indicates front camera
            }
            
            group.addTask {
                let image = await self.capturePhotoFromOutput(self.backPhotoOutput, settings: settings)
                return (image, false) // false indicates back camera
            }
            
            var frontImage: UIImage?
            var backImage: UIImage?
            
            for await (image, isFront) in group {
                if isFront {
                    frontImage = image
                } else {
                    backImage = image
                }
            }
            
            return (frontImage, backImage)
        }
    }
    
    /// Fallback single camera capture
    private func captureSinglePhoto() async -> (frontImage: UIImage?, backImage: UIImage?) {
        let backImage = await capturePhotoFromOutput(backPhotoOutput, settings: AVCapturePhotoSettings())
        return (nil, backImage)
    }
    
    /// Helper to capture photo from specific output
    private func capturePhotoFromOutput(_ output: AVCapturePhotoOutput, settings: AVCapturePhotoSettings) async -> UIImage? {
        let isFrontCamera = output === frontPhotoOutput
        
        return await withCheckedContinuation { continuation in
            var delegate: PhotoCaptureDelegate!
            delegate = PhotoCaptureDelegate(isFrontCamera: isFrontCamera) { [weak self] result in
                self?.photoCaptureInProgress.remove(delegate)
                continuation.resume(returning: result)
            }
            
            // Keep strong reference during capture
            photoCaptureInProgress.insert(delegate)
            
            print("📸 Starting photo capture with output: \(output), isFrontCamera: \(isFrontCamera)")
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private let isFrontCamera: Bool
    private let id = UUID()
    
    init(isFrontCamera: Bool, completion: @escaping (UIImage?) -> Void) {
        self.isFrontCamera = isFrontCamera
        self.completion = completion
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PhotoCaptureDelegate else { return false }
        return self.id == other.id
    }
    
    override var hash: Int {
        return id.hashValue
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 Photo capture completed")
        
        guard error == nil else {
            print("❌ Photo capture error: \(error!.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to convert photo data to UIImage")
            completion(nil)
            return
        }
        
        // Apply horizontal flip for front camera to match real-life mirror expectation
        let finalImage = isFrontCamera ? image.horizontallyFlipped() : image
        
        print("✅ Photo captured successfully (front camera: \(isFrontCamera), flipped: \(isFrontCamera))")
        completion(finalImage)
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    /// Returns a horizontally mirrored version of the image (like a mirror)
    func horizontallyFlipped() -> UIImage {
        // Use UIImage's built-in capability to flip horizontally
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // Flip the coordinate system horizontally
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1, y: 1)
        
        // Draw the image in the flipped context
        draw(at: .zero)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}