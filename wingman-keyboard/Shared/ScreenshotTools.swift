#if canImport(UIKit)
import UIKit
import Photos

enum ImageTools {
    /// Long edge in pixels. Chat text stays readable and the upload stays small (~1.5k image tokens).
    static let maxDimension: CGFloat = 1600

    /// Downscales and JPEG-encodes an image for the API.
    static func jpegForClaude(_ image: UIImage, maxDimension: CGFloat = maxDimension, quality: CGFloat = 0.72) -> Data? {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }
        let ratio = min(1, maxDimension / max(pixelWidth, pixelHeight))
        let target = CGSize(width: floor(pixelWidth * ratio), height: floor(pixelHeight * ratio))

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    static func jpegForClaude(data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return jpegForClaude(image)
    }
}

/// Finds the most recent screenshot in the photo library.
/// Needs Photos access (granted in the Wingman app) and, inside the keyboard, Full Access.
enum ScreenshotFinder {
    static var isAuthorized: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    static func latestScreenshot(maxAge: TimeInterval, now: Date = Date()) -> PHAsset? {
        guard isAuthorized else { return nil }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "(mediaSubtypes & %d) != 0",
                                        Int(PHAssetMediaSubtype.photoScreenshot.rawValue))
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        guard let asset = PHAsset.fetchAssets(with: .image, options: options).firstObject,
              let created = asset.creationDate,
              now.timeIntervalSince(created) <= maxAge else { return nil }
        return asset
    }

    /// Loads the asset already scaled down, so the keyboard never decodes a full-size image.
    static func loadJPEG(for asset: PHAsset) async -> Data? {
        let longEdge = CGFloat(max(asset.pixelWidth, asset.pixelHeight))
        let ratio = longEdge > 0 ? min(1, ImageTools.maxDimension / longEdge) : 1
        let target = CGSize(width: CGFloat(asset.pixelWidth) * ratio, height: CGFloat(asset.pixelHeight) * ratio)

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let image: UIImage? = await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: target,
                                                  contentMode: .aspectFit,
                                                  options: options) { image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !degraded, !resumed else { return }
                resumed = true
                continuation.resume(returning: image)
            }
        }
        guard let image else { return nil }
        return ImageTools.jpegForClaude(image)
    }
}
#endif
