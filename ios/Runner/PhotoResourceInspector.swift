import Flutter
import Photos
import CryptoKit
import UIKit

/// Reads local Photos resources in bounded chunks. It never exports originals
/// and never enables iCloud downloads. A fingerprint is valid only when EVERY
/// resource completed, including adjustments and Live Photo paired movies.
final class PhotoResourceInspector: NSObject, FlutterPlugin {
  private var jobs: [String: PhotoResourceInspection] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cleanup/photo_resources", binaryMessenger: registrar.messenger())
    let plugin = PhotoResourceInspector()
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if !Thread.isMainThread {
      DispatchQueue.main.async { self.handle(call, result: result) }
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "arguments", message: "Missing resource arguments", details: nil)); return
    }
    switch call.method {
    case "compressionCacheDirectory":
      result(URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("video_compress", isDirectory: true).path)
    case "saveCompressedVideo":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "save_failed", message: "Missing video path", details: nil)); return
      }
      let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
      guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        result(FlutterError(code: "save_failed", message: "Application cache is unavailable", details: nil)); return
      }
      let cache = cacheURL.standardizedFileURL.resolvingSymlinksInPath()
      guard source.deletingLastPathComponent().path == cache.path,
        source.lastPathComponent.hasPrefix("cleanup_preview_"),
        FileManager.default.fileExists(atPath: source.path) else {
        result(FlutterError(code: "save_failed", message: "Video preview is outside the application cache", details: nil)); return
      }
      let identifierLock = NSLock()
      var savedIdentifier: String?
      var didCreateRequest = false
      PHPhotoLibrary.shared().performChanges({
        let creation = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: source)
        identifierLock.lock()
        didCreateRequest = creation != nil
        savedIdentifier = creation?.placeholderForCreatedAsset?.localIdentifier
        identifierLock.unlock()
      }, completionHandler: { success, error in
        identifierLock.lock()
        let identifier = savedIdentifier
        let created = didCreateRequest
        identifierLock.unlock()
        DispatchQueue.main.async {
          if success && created { result(identifier ?? "saved_without_identifier") }
          else { result(FlutterError(code: "save_failed", message: error?.localizedDescription ?? "Photos could not save the video", details: nil)) }
        }
      })
    case "inspectAsset":
      guard let assetId = args["assetId"] as? String, let token = args["token"] as? String else {
        result(FlutterError(code: "arguments", message: "Missing asset identifier or token", details: nil)); return
      }
      guard jobs[token] == nil else {
        result(FlutterError(code: "duplicate_token", message: "A resource request already uses this token", details: nil)); return
      }
      let job = PhotoResourceInspection(assetId: assetId,
        includeHash: args["includeHash"] as? Bool ?? false,
        includeThumbnail: args["includeThumbnail"] as? Bool ?? false) { [weak self] response in
        self?.jobs.removeValue(forKey: token)
        result(response)
      }
      jobs[token] = job
      job.start()
    case "cancelInspections":
      let token = args["token"] as? String
      let prefix = args["prefix"] as? String
      // Copy jobs before callbacks remove dictionary entries on the main queue.
      let cancelled = jobs.filter { entry in token == entry.key || (prefix != nil && entry.key.hasPrefix(prefix!)) }.map { $0.value }
      cancelled.forEach { $0.cancel() }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
}

private final class PhotoResourceInspection {
  private let assetId: String
  private let includeHash: Bool
  private let includeThumbnail: Bool
  private let completion: ([String: Any]) -> Void
  // All counters, hash state, request IDs, completion and cancellation state
  // are touched only on this serial queue. Photos callbacks enqueue here.
  private let queue = DispatchQueue(label: "cleanup.local-resource", qos: .utility)
  private let manager = PHAssetResourceManager.default()
  private var resources: [PHAssetResource] = []
  private var asset: PHAsset?
  private var resourceIndex = 0
  private var dataRequest: PHAssetResourceDataRequestID?
  private var imageRequest: PHImageRequestID?
  private var timeout: DispatchWorkItem?
  private var finished = false
  private var totalBytes: Int64 = 0
  private var resourceBytes: Int64 = 0
  private var resourceHash = SHA256()
  private var descriptors: [String] = []
  private var verifiedResources = false
  private var fingerprint: String?

  init(assetId: String, includeHash: Bool, includeThumbnail: Bool,
       completion: @escaping ([String: Any]) -> Void) {
    self.assetId = assetId; self.includeHash = includeHash
    self.includeThumbnail = includeThumbnail; self.completion = completion
  }

  func start() {
    queue.async {
      guard !self.finished else { return }
      let deadline = DispatchWorkItem { [weak self] in self?.fail("local_resource_timeout") }
      self.timeout = deadline
      self.queue.asyncAfter(deadline: .now() + 60, execute: deadline)
      guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.assetId], options: nil).firstObject else {
        self.fail("asset_unavailable"); return
      }
      self.asset = asset
      self.resources = PHAssetResource.assetResources(for: asset)
      guard !self.resources.isEmpty else { self.fail("no_resources"); return }
      // Unknown future resource semantics must not be silently ignored.
      guard self.resources.allSatisfy({ Self.knownResourceTypes.contains($0.type.rawValue) }) else {
        self.fail("unknown_resource_type"); return
      }
      let types = Set(self.resources.map { $0.type.rawValue })
      guard (asset.mediaType == .image && types.contains(PHAssetResourceType.photo.rawValue)) ||
            (asset.mediaType == .video && types.contains(PHAssetResourceType.video.rawValue)) else {
        self.fail("original_resource_missing"); return
      }
      if asset.mediaSubtypes.contains(.photoLive) && !types.contains(PHAssetResourceType.pairedVideo.rawValue) {
        self.fail("live_photo_pair_missing"); return
      }
      // Edited photo/video/Live Photo must include the rendered current output.
      if types.contains(PHAssetResourceType.adjustmentData.rawValue) {
        if asset.mediaType == .image && !types.contains(PHAssetResourceType.fullSizePhoto.rawValue) {
          self.fail("edited_photo_render_missing"); return
        }
        if asset.mediaType == .video && !types.contains(PHAssetResourceType.fullSizeVideo.rawValue) {
          self.fail("edited_video_render_missing"); return
        }
        if asset.mediaSubtypes.contains(.photoLive) && !types.contains(PHAssetResourceType.fullSizePairedVideo.rawValue) {
          self.fail("edited_live_pair_missing"); return
        }
      }
      self.readNextResource()
    }
  }

  // Public PHAssetResourceType values 1...12: originals, alternates, current
  // renders, adjustment data/bases and paired movies. PhotoProxy/new unknown
  // representations are deliberately left pending rather than guessed.
  private static let knownResourceTypes: Set<Int> = Set(1...12)

  func cancel() { queue.async { self.fail("cancelled") } }

  private func readNextResource() {
    guard !finished else { return }
    if resourceIndex == resources.count {
      verifiedResources = true
      if includeHash {
        // Each descriptor includes TYPE, LENGTH and full resource SHA256.
        // Sort to ignore Photos enumeration order, but retain duplicate entries.
        // Asset IDs, names, timestamps and metadata never enter the hash.
        let compound = "photos-resources-v1\n" + descriptors.sorted().joined(separator: "\n") + "\n"
        fingerprint = Self.hex(SHA256.hash(data: Data(compound.utf8)))
      }
      loadCurrentThumbnail(); return
    }
    let resource = resources[resourceIndex]
    resourceBytes = 0; resourceHash = SHA256()
    let options = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = false
    dataRequest = manager.requestData(for: resource, options: options,
      dataReceivedHandler: { [weak self] chunk in
        // Photos delivers data on a serial callback queue. Synchronous handoff
        // provides backpressure and avoids buffering a full video in queued Data.
        guard let self = self else { return }
        self.queue.sync {
          guard !self.finished else { return }
          self.resourceBytes += Int64(chunk.count)
          if self.includeHash { self.resourceHash.update(data: chunk) }
        }
      }, completionHandler: { [weak self] error in
        guard let self = self else { return }
        self.queue.async {
          guard !self.finished else { return }
          self.dataRequest = nil
          guard error == nil && self.resourceBytes > 0 else {
            self.fail("local_resource_unavailable"); return
          }
          self.totalBytes += self.resourceBytes
          if self.includeHash {
            let digest = Self.hex(self.resourceHash.finalize())
            self.descriptors.append("\(resource.type.rawValue):\(self.resourceBytes):\(digest)")
          }
          self.resourceIndex += 1
          self.readNextResource()
        }
      })
  }

  private func loadCurrentThumbnail() {
    guard includeThumbnail, let asset = asset else { succeed(thumbnail: nil); return }
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = false
    options.isSynchronous = false
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.version = .current
    imageRequest = PHImageManager.default().requestImage(for: asset,
      targetSize: CGSize(width: 256, height: 256), contentMode: .aspectFit, options: options) { [weak self] image, info in
      guard let self = self else { return }
      // A degraded thumbnail is not a final current-version content sample.
      if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
      let data = image?.jpegData(compressionQuality: 0.92)
      self.queue.async {
        guard !self.finished else { return }
        self.imageRequest = nil
        self.succeed(thumbnail: data)
      }
    }
  }

  private func succeed(thumbnail: Data?) {
    guard let original = asset,
      let current = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject,
      current.modificationDate == original.modificationDate,
      current.mediaType == original.mediaType,
      current.pixelWidth == original.pixelWidth && current.pixelHeight == original.pixelHeight else {
      fail("asset_changed_during_analysis"); return
    }
    var response: [String: Any] = ["sizeKnown": verifiedResources,
      "size": totalBytes, "complete": verifiedResources]
    if let hash = fingerprint { response["hash"] = hash }
    if let thumbnail = thumbnail { response["thumbnail"] = FlutterStandardTypedData(bytes: thumbnail) }
    if includeThumbnail && thumbnail == nil { response["pendingReason"] = "local_preview_unavailable" }
    finish(response)
  }

  private func fail(_ reason: String) {
    finish(["sizeKnown": false, "size": 0, "complete": false, "pendingReason": reason])
  }

  private func finish(_ response: [String: Any]) {
    guard !finished else { return }
    finished = true
    timeout?.cancel(); timeout = nil
    if let id = dataRequest { manager.cancelDataRequest(id); dataRequest = nil }
    if let id = imageRequest { PHImageManager.default().cancelImageRequest(id); imageRequest = nil }
    DispatchQueue.main.async { self.completion(response) }
  }

  private static func hex<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
    digest.map { String(format: "%02x", $0) }.joined()
  }
}
