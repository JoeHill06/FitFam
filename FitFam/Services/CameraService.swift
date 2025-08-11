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
    @Published var captureMode: CaptureMode = .photo
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isCapturing = false
    @Published var error: CameraError?
    @Published var isBackCameraPrimary = true // Track which camera is the main view for dual camera
    
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
    
    // Preview layers
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isMultiCamSupported: Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }
    
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
        checkCameraAuthorization()
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
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Configure and start the camera session
    func startSession() {
        print("🎥 Starting camera session...")
        print("🔐 Camera authorized: \(isAuthorized)")
        
        guard isAuthorized else {
            print("❌ Camera not authorized")
            DispatchQueue.main.async {
                self.error = .notAuthorized
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    /// Stop the camera session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
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
        
        print("✅ Capture session cleaned up")
    }
    
    /// Configure dual camera session with fallback to single camera
    private func configureSession() {
        print("⚙️ Configuring camera session...")
        print("📱 Multi-cam supported: \(isMultiCamSupported)")
        
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
            print("▶️ Starting capture session...")
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                print("✅ Camera session started successfully!")
                self.isSessionRunning = true
                
                // Reset preview layers to ensure they connect properly
                self.frontPreviewLayer = nil
                self.backPreviewLayer = nil
            }
            
        } catch {
            print("❌ Camera configuration failed: \(error)")
            captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.error = .unknown(error)
            }
        }
    }
    
    /// Configure dual camera session for devices that support multi-cam
    private func configureDualCameraSession() throws {
        print("🔄 Configuring dual camera inputs...")
        
        // Configure front camera
        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                       for: .video, 
                                                       position: .front) else {
            throw CameraError.deviceNotAvailable
        }
        
        let frontInput = try AVCaptureDeviceInput(device: frontDevice)
        guard captureSession.canAddInput(frontInput) else {
            throw CameraError.configurationFailed
        }
        
        captureSession.addInputWithNoConnections(frontInput)
        frontCameraInput = frontInput
        print("✅ Front camera input added")
        
        // Configure back camera
        guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                      for: .video, 
                                                      position: .back) else {
            throw CameraError.deviceNotAvailable
        }
        
        let backInput = try AVCaptureDeviceInput(device: backDevice)
        guard captureSession.canAddInput(backInput) else {
            throw CameraError.configurationFailed
        }
        
        captureSession.addInputWithNoConnections(backInput)
        backCameraInput = backInput
        print("✅ Back camera input added")
        
        // Add outputs and create connections
        try addOutputsAndConnections()
        
        // Create preview connections manually for dual cam
        try createPreviewConnections()
        
        print("✅ Dual camera session configured successfully")
    }
    
    /// Create manual preview connections for dual camera
    private func createPreviewConnections() throws {
        // We need to create preview layers after inputs are configured
        // This will be handled when getFrontPreviewLayer() and getBackPreviewLayer() are called
        print("📺 Preview connections will be created when layers are requested")
    }
    
    /// Fallback single camera configuration for older devices
    private func configureSingleCameraSession() throws {
        // Start with back camera as primary
        guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                      for: .video, 
                                                      position: .back) else {
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
        
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        
        // For multi-cam, we need to manually connect to the front camera
        if isMultiCamSupported && frontCameraInput != nil {
            print("📱 Creating front camera preview layer for multi-cam")
            
            // The preview layer will automatically connect to available inputs
            // We'll configure mirroring when the layer is added to a view
        } else {
            print("📱 Creating front camera preview layer for single-cam")
        }
        
        frontPreviewLayer = layer
        return layer
    }
    
    /// Get back camera preview layer  
    func getBackPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let existingLayer = backPreviewLayer {
            return existingLayer
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        
        // Fix orientation for back camera
        if let connection = layer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        if isMultiCamSupported && backCameraInput != nil {
            print("📱 Creating back camera preview layer for multi-cam")
        } else {
            print("📱 Creating back camera preview layer for single-cam")
        }
        
        backPreviewLayer = layer
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
                    frontImage = image?.fixedFrontCameraOrientation()
                } else {
                    backImage = image?.fixedBackCameraOrientation()
                }
            }
            
            return (frontImage, backImage)
        }
    }
    
    /// Fallback single camera capture
    private func captureSinglePhoto() async -> (frontImage: UIImage?, backImage: UIImage?) {
        let backImage = await capturePhotoFromOutput(backPhotoOutput, settings: AVCapturePhotoSettings())
        return (nil, backImage?.fixedBackCameraOrientation())
    }
    
    /// Helper to capture photo from specific output
    private func capturePhotoFromOutput(_ output: AVCapturePhotoOutput, settings: AVCapturePhotoSettings) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            var delegate: PhotoCaptureDelegate!
            delegate = PhotoCaptureDelegate { [weak self] result in
                self?.photoCaptureInProgress.remove(delegate)
                continuation.resume(returning: result)
            }
            
            // Keep strong reference during capture
            photoCaptureInProgress.insert(delegate)
            
            print("📸 Starting photo capture with output: \(output)")
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

extension UIImage {
    /// Fix orientation for front camera images that appear upside down
    func fixedFrontCameraOrientation() -> UIImage {
        // Manually rotate the image 180 degrees using Core Graphics
        guard let cgImage = self.cgImage else { return self }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: cgImage.bitsPerComponent,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return self
        }
        
        // Rotate 180 degrees
        context.translateBy(x: CGFloat(width), y: CGFloat(height))
        context.rotate(by: .pi)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let rotatedCGImage = context.makeImage() else { return self }
        
        return UIImage(cgImage: rotatedCGImage, scale: self.scale, orientation: .up)
    }
    
    /// Fix orientation for back camera images that appear upside down
    func fixedBackCameraOrientation() -> UIImage {
        // Manually rotate the image 180 degrees using Core Graphics
        guard let cgImage = self.cgImage else { return self }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: cgImage.bitsPerComponent,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return self
        }
        
        // Rotate 180 degrees
        context.translateBy(x: CGFloat(width), y: CGFloat(height))
        context.rotate(by: .pi)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let rotatedCGImage = context.makeImage() else { return self }
        
        return UIImage(cgImage: rotatedCGImage, scale: self.scale, orientation: .up)
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private let id = UUID()
    
    init(completion: @escaping (UIImage?) -> Void) {
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
        
        print("✅ Photo captured successfully")
        completion(image)
    }
}