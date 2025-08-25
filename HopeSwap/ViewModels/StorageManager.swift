import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Image Upload
    func uploadImage(_ image: UIImage, path: String, compressionQuality: CGFloat = 0.7) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw StorageError.imageConversionFailed
        }
        
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "originalSize": "\(imageData.count)"
        ]
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Multiple Images Upload
    func uploadItemImages(_ images: [UIImage], itemId: String) async throws -> [String] {
        var uploadedURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let path = "items/\(itemId)/image_\(index)_\(UUID().uuidString).jpg"
            
            do {
                let url = try await uploadImage(image, path: path)
                uploadedURLs.append(url)
            } catch {
                print("Failed to upload image \(index): \(error)")
                // Continue with other images even if one fails
            }
        }
        
        return uploadedURLs
    }
    
    // MARK: - Avatar Upload
    func uploadUserAvatar(_ image: UIImage, userId: String) async throws -> String {
        let path = "avatars/\(userId)/profile_\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path, compressionQuality: 0.8)
    }
    
    // MARK: - Delete Images
    func deleteImage(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
    
    func deleteImages(urls: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        try await self.deleteImage(url: url)
                    } catch {
                        print("Failed to delete image: \(url), error: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Image Processing
    func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize = maxSize
        if aspectRatio > 1 {
            // Landscape
            newSize.height = maxSize.width / aspectRatio
        } else {
            // Portrait
            newSize.width = maxSize.height * aspectRatio
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Helper Methods
    func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        // Resize large images to max 1024x1024 to save storage and bandwidth
        let maxSize = CGSize(width: 1024, height: 1024)
        return resizeImage(image, maxSize: maxSize)
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case imageConversionFailed
    case uploadFailed
    case downloadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .uploadFailed:
            return "Failed to upload image"
        case .downloadFailed:
            return "Failed to download image"
        case .deleteFailed:
            return "Failed to delete image"
        }
    }
}