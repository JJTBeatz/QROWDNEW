import Foundation
import SwiftUI
import Combine

// MARK: - Image Cache Manager
@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var downloadTasks: [String: URLSessionDataTask] = [:]
    
    // Configuration
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxMemoryCache: Int = 50 * 1024 * 1024 // 50MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Set up cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.totalCostLimit = maxMemoryCache
        cache.countLimit = 200 // Max 200 images in memory
        
        // Setup cache cleaning
        setupCacheCleanup()
    }
    
    // MARK: - Public Methods
    func image(for url: String) -> UIImage? {
        let key = NSString(string: url)
        return cache.object(forKey: key)
    }
    
    func loadImage(from urlString: String) async -> UIImage? {
        // First check memory cache
        if let cachedImage = image(for: urlString) {
            return cachedImage
        }
        
        // Then check disk cache
        if let diskImage = loadImageFromDisk(url: urlString) {
            // Add back to memory cache
            let key = NSString(string: urlString)
            cache.setObject(diskImage, forKey: key, cost: diskImage.jpegData(compressionQuality: 0.8)?.count ?? 0)
            return diskImage
        }
        
        // Finally, download from network
        return await downloadImage(from: urlString)
    }
    
    func preloadImages(_ urls: [String]) {
        Task {
            for url in urls {
                _ = await loadImage(from: url)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCacheSize() -> String {
        let size = getCacheSizeInBytes()
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    // MARK: - Private Methods
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Cancel existing download for this URL
        downloadTasks[urlString]?.cancel()
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // Process image (resize if needed)
            let processedImage = processImage(image)
            
            // Cache in memory
            let key = NSString(string: urlString)
            cache.setObject(processedImage, forKey: key, cost: data.count)
            
            // Cache on disk
            saveImageToDisk(image: processedImage, url: urlString)
            
            return processedImage
            
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        // Resize large images to save memory
        let maxDimension: CGFloat = 1024
        
        guard max(image.size.width, image.size.height) > maxDimension else {
            return image
        }
        
        let scale = maxDimension / max(image.size.width, image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        return image.resized(to: newSize) ?? image
    }
    
    private func loadImageFromDisk(url: String) -> UIImage? {
        let filename = url.sha256
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        // Check if file is too old
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modificationDate) > maxCacheAge {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func saveImageToDisk(image: UIImage, url: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = url.sha256
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
        
        // Clean up old files if cache is too large
        cleanupDiskCacheIfNeeded()
    }
    
    private func setupCacheCleanup() {
        // Clean up cache on app launch
        Task {
            await cleanupExpiredFiles()
        }
        
        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.cache.removeAllObjects()
        }
    }
    
    private func cleanupExpiredFiles() async {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        let now = Date()
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                if let modificationDate = resourceValues.contentModificationDate,
                   now.timeIntervalSince(modificationDate) > maxCacheAge {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                // Ignore errors and continue
            }
        }
    }
    
    private func cleanupDiskCacheIfNeeded() {
        let cacheSize = getCacheSizeInBytes()
        
        guard cacheSize > maxCacheSize else { return }
        
        // Get all cached files with their modification dates
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        var files: [(url: URL, date: Date, size: Int)] = []
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                if let modificationDate = resourceValues.contentModificationDate,
                   let fileSize = resourceValues.fileSize {
                    files.append((url: fileURL, date: modificationDate, size: fileSize))
                }
            } catch {
                // Ignore errors
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        // Remove files until we're under the limit
        var currentSize = cacheSize
        let targetSize = maxCacheSize / 2 // Clean to half the limit
        
        for file in files {
            guard currentSize > targetSize else { break }
            
            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
    }
    
    private func getCacheSizeInBytes() -> Int {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return 0 }
        
        var totalSize = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += resourceValues.fileSize ?? 0
            } catch {
                // Ignore errors
            }
        }
        
        return totalSize
    }
}

// MARK: - Cached Async Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageCache = ImageCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !url.isEmpty, !isLoading else { return }
        
        isLoading = true
        
        Task {
            let loadedImage = await imageCache.loadImage(from: url)
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Optimized Profile Image View
struct OptimizedProfileImageView: View {
    let url: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    init(url: String?, size: CGFloat = 60, cornerRadius: CGFloat = 30) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: size * 0.4))
                )
                .shimmerEffect()
        }
    }
}

// MARK: - Optimized Event Image View
struct OptimizedEventImageView: View {
    let url: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(url: String?, width: CGFloat = 120, height: CGFloat = 80, cornerRadius: CGFloat = 8) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: height)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.gray)
                        .font(.system(size: min(width, height) * 0.3))
                )
                .shimmerEffect()
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - String Extensions for Cache Key
extension String {
    var sha256: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// C function import for SHA256
import CommonCrypto

// MARK: - Performance Monitoring for Images
extension PerformanceMonitor {
    func trackImageLoad(url: String, fromCache: Bool) {
        Task { @MainActor in
            await AnalyticsManager.shared.track(
                event: .performance,
                parameters: [
                    "operation": "image_load",
                    "from_cache": fromCache,
                    "url_hash": url.sha256.prefix(8)
                ]
            )
        }
    }
}

// MARK: - Image Preloader for Lists
class ImagePreloader {
    static let shared = ImagePreloader()
    private let imageCache = ImageCacheManager.shared
    
    private init() {}
    
    func preloadImagesForDJs(_ djs: [DJCard]) {
        let urls = djs.compactMap { $0.thumbnailURL }
        Task { @MainActor in
            imageCache.preloadImages(urls)
        }
    }
    
    func preloadImagesForEvents(_ events: [TrendingEvent]) {
        let urls = events.compactMap { $0.thumbnailURL }
        Task { @MainActor in
            imageCache.preloadImages(urls)
        }
    }
} 