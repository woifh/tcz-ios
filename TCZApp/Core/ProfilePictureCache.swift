import UIKit

/// Cache manager for profile pictures with disk and memory caching.
/// Uses version-based cache keys to automatically invalidate when pictures are updated.
final class ProfilePictureCache {
    static let shared = ProfilePictureCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Use Caches directory for disk storage, with fallback to temporary directory
        let cacheDir: URL
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDir = cachesDir
        } else {
            cacheDir = fileManager.temporaryDirectory
        }
        cacheDirectory = cacheDir.appendingPathComponent("ProfilePictures", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        memoryCache.countLimit = 100
    }

    /// Get cached image for a member at a specific version.
    /// Returns nil if not cached or version mismatch.
    func getImage(memberId: String, version: Int) -> UIImage? {
        let key = cacheKey(memberId: memberId, version: version)

        // Check memory cache first
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }

        // Check disk cache
        let filePath = cacheDirectory.appendingPathComponent("\(key).jpg")
        if let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            // Promote to memory cache
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }

        return nil
    }

    /// Store image in both memory and disk cache.
    func setImage(_ image: UIImage, memberId: String, version: Int) {
        let key = cacheKey(memberId: memberId, version: version)

        // Store in memory
        memoryCache.setObject(image, forKey: key as NSString)

        // Store on disk
        let filePath = cacheDirectory.appendingPathComponent("\(key).jpg")
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: filePath)
        }
    }

    /// Invalidate all cached images for a member (called after upload/delete).
    func invalidate(memberId: String) {
        // Remove from memory cache - we don't know all versions, so clear based on prefix
        // NSCache doesn't support prefix removal, so we just let old versions age out

        // Remove all disk files for this member
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix(memberId) {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    /// Clear entire cache (useful for logout or memory warnings).
    func clearAll() {
        memoryCache.removeAllObjects()

        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    private func cacheKey(memberId: String, version: Int) -> String {
        "\(memberId)_v\(version)"
    }
}
