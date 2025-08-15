//
//  ImageUploadService.swift
//  FitFam
//
//  Created by Claude on 14/08/2025.
//  
//  Service for handling dual image uploads with compression, progress tracking, and retry logic.
//  Follows Beer Buddy pattern for front/back camera image management.
//

import Foundation
import UIKit
import FirebaseStorage
import Combine

@MainActor
class ImageUploadService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var backImageProgress: Double = 0.0
    @Published var frontImageProgress: Double = 0.0
    @Published var overallProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    
    // MARK: - Private Properties
    private let storage = Storage.storage()
    private let maxRetries = 3
    private let maxDimension: CGFloat = 2048
    private let jpegQuality: CGFloat = 0.85 // ~0.82-0.88 range
    
    // MARK: - Upload Result
    struct UploadResult {
        let backImageUrl: String
        let frontImageUrl: String
    }
    
    // MARK: - Public Methods
    
    /// Upload both back and front camera images with progress tracking
    func uploadDualImages(backImage: UIImage, frontImage: UIImage, postId: String) async throws -> UploadResult {
        isUploading = true
        uploadError = nil
        resetProgress()
        
        do {
            // Compress images
            let backImageData = compressImage(backImage)
            let frontImageData = compressImage(frontImage)
            
            // Upload both images concurrently
            async let backUrl = uploadImageWithRetry(
                imageData: backImageData,
                path: "posts/\(postId)/back.jpg",
                imageType: "back"
            )
            
            async let frontUrl = uploadImageWithRetry(
                imageData: frontImageData,
                path: "posts/\(postId)/front.jpg",
                imageType: "front"
            )
            
            let (backResult, frontResult) = try await (backUrl, frontUrl)
            
            await MainActor.run {
                self.overallProgress = 1.0
                self.isUploading = false
            }
            
            return UploadResult(backImageUrl: backResult, frontImageUrl: frontResult)
            
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.uploadError = "Upload failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func compressImage(_ image: UIImage) -> Data {
        // Resize to max dimension while maintaining aspect ratio
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        
        // Compress to JPEG with specified quality
        guard let jpegData = resizedImage.jpegData(compressionQuality: jpegQuality) else {
            fatalError("Failed to convert image to JPEG data")
        }
        
        print("📏 Compressed image: \(jpegData.count / 1024)KB")
        return jpegData
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        // If image is already smaller than max dimension, return as-is
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private func uploadImageWithRetry(imageData: Data, path: String, imageType: String) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await uploadImage(imageData: imageData, path: path, imageType: imageType)
            } catch {
                lastError = error
                print("❌ Upload attempt \(attempt) failed for \(path): \(error)")
                
                if attempt < maxRetries {
                    // Exponential backoff: 1s, 2s, 4s
                    let delay = TimeInterval(1 << (attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? URLError(.unknown)
    }
    
    private func uploadImage(imageData: Data, path: String, imageType: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Get download URL after successful upload
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }
            }
            
            // Track upload progress
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let progressValue = Double(progress.fractionCompleted)
                
                Task { @MainActor in
                    if imageType == "back" {
                        self.backImageProgress = progressValue
                    } else {
                        self.frontImageProgress = progressValue
                    }
                    self.updateOverallProgress()
                }
            }
        }
    }
    
    private func updateOverallProgress() {
        overallProgress = (backImageProgress + frontImageProgress) / 2.0
    }
    
    private func resetProgress() {
        backImageProgress = 0.0
        frontImageProgress = 0.0
        overallProgress = 0.0
    }
}