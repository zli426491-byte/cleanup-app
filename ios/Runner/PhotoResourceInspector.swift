import Flutter
import Photos
import CryptoKit
import UIKit
import AVFoundation

protocol NativePhotoJob: AnyObject {
  func start()
  func cancel()
}

/// Flutter results and deadlines never wait for Photos cancellation callbacks.
final class NativeInspectionCompletion {
  private let lock = NSLock()
  private var finished = false
  private var cancellations: [String: () -> Void] = [:]
  private var deadline: DispatchWorkItem?
  private let completion: ([String: Any]) -> Void
  private static let cancellationQueue = DispatchQueue(
    label: "cleanup.photos-cancel", qos: .utility, attributes: .concurrent)
  private static let deadlineQueue = DispatchQueue(label: "cleanup.photos-deadline", qos: .userInitiated)
  init(completion: @escaping ([String: Any]) -> Void) { self.completion = completion }
  var isFinished: Bool { lock.lock(); defer { lock.unlock() }; return finished }
  func armDeadline(seconds: Double, response: @escaping () -> [String: Any]) {
    let work = DispatchWorkItem { [weak self] in self?.finish(response()) }
    lock.lock()
    if finished { lock.unlock(); return }
    deadline?.cancel(); deadline = work
    lock.unlock()
    // Independent of the state queue, which may be inside a Photos fetch.
    Self.deadlineQueue.asyncAfter(deadline: .now() + seconds, execute: work)
  }
  func track(_ key: String, cancel: @escaping () -> Void) {
    lock.lock()
    if finished { lock.unlock(); Self.cancellationQueue.async(execute: cancel); return }
    cancellations[key] = cancel; lock.unlock()
  }
  func untrack(_ key: String) { lock.lock(); cancellations.removeValue(forKey: key); lock.unlock() }
  @discardableResult func finish(_ response: [String: Any]) -> Bool {
    lock.lock()
    guard !finished else { lock.unlock(); return false }
    finished = true
    let work = deadline; deadline = nil
    let actions = Array(cancellations.values); cancellations.removeAll()
    lock.unlock()
    work?.cancel()
    // Reply is queued BEFORE potentially blocking Photos cancellation.
    DispatchQueue.main.async { self.completion(response) }
    actions.forEach { action in Self.cancellationQueue.async(execute: action) }
    return true
  }
}

/// Stream/hash on Photos' callback thread under a small lock. No queue.sync,
/// no queued movie Data backlog; rejected/incomplete streams have no SHA.
final class NativeResourceAccumulator {
  private let lock = NSLock()
  private var count: Int64 = 0
  private var exceeded = false
  private var hash = SHA256()
  private let maximumBytes: Int64
  private let includeHash: Bool
  init(maximumBytes: Int64, includeHash: Bool) {
    self.maximumBytes = max(0, maximumBytes); self.includeHash = includeHash
  }
  func append(_ data: Data) -> Bool {
    lock.lock(); defer { lock.unlock() }
    let bytes = Int64(data.count)
    // Test before adding, avoiding overflow as well as excess processing.
    guard !exceeded, count <= maximumBytes, bytes <= maximumBytes - count else {
      exceeded = true; return false
    }
    count += bytes
    if includeHash { hash.update(data: data) }
    return true
  }
  func snapshot() -> (bytes: Int64, digest: String?) {
    lock.lock(); defer { lock.unlock() }
    return (count, includeHash && !exceeded ? hash.finalize().map { String(format: "%02x", $0) }.joined() : nil)
  }
}

protocol NativeResourceIO {
  func request(_ resource: PHAssetResource, options: PHAssetResourceRequestOptions,
    data: @escaping (Data) -> Void, completion: @escaping (Error?) -> Void) -> PHAssetResourceDataRequestID
  func cancel(_ identifier: PHAssetResourceDataRequestID)
}
struct PhotosResourceIO: NativeResourceIO {
  private let manager = PHAssetResourceManager.default()
  func request(_ resource: PHAssetResource, options: PHAssetResourceRequestOptions,
    data: @escaping (Data) -> Void, completion: @escaping (Error?) -> Void) -> PHAssetResourceDataRequestID {
    manager.requestData(for: resource, options: options, dataReceivedHandler: data, completionHandler: completion)
  }
  func cancel(_ identifier: PHAssetResourceDataRequestID) { manager.cancelDataRequest(identifier) }
}

protocol NativeOriginalVideoIO {
  func request(_ asset: PHAsset, options: PHVideoRequestOptions,
    completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID
  func cancel(_ identifier: PHImageRequestID)
}
struct PhotosOriginalVideoIO: NativeOriginalVideoIO {
  private let manager = PHImageManager.default()
  func request(_ asset: PHAsset, options: PHVideoRequestOptions,
    completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
    manager.requestAVAsset(forVideo: asset, options: options) { video, _, info in completion(video, info) }
  }
  func cancel(_ identifier: PHImageRequestID) { manager.cancelImageRequest(identifier) }
}
private final class NativeInspectionResponse {
  private let lock = NSLock()
  private var response: [String: Any]?
  func set(_ value: [String: Any]) { lock.lock(); response = value; lock.unlock() }
  func get() -> [String: Any]? { lock.lock(); defer { lock.unlock() }; return response }
}

final class PhotoResourceInspector: NSObject, FlutterPlugin {
  private var jobs: [String: NativePhotoJob] = [:]
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cleanup/photo_resources", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PhotoResourceInspector(), channel: channel)
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if !Thread.isMainThread { DispatchQueue.main.async { self.handle(call, result: result) }; return }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "arguments", message: "Missing resource arguments", details: nil)); return
    }
    switch call.method {
    case "compressionCacheDirectory":
      result(URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("video_compress", isDirectory: true).path)
    case "saveCompressedVideo": saveCompressedVideo(args, result: result)
    case "inspectPreviews", "inspectAsset":
      guard let token = args["token"] as? String, !token.isEmpty else {
        result(FlutterError(code: "arguments", message: "Missing request token", details: nil)); return
      }
      guard jobs[token] == nil else {
        result(FlutterError(code: "duplicate_token", message: "A resource request already uses this token", details: nil)); return
      }
      let completion: ([String: Any]) -> Void = { [weak self] response in
        self?.jobs.removeValue(forKey: token); result(response)
      }
      let job: NativePhotoJob
      if call.method == "inspectPreviews" {
        guard let identifiers = args["assetIds"] as? [String], !identifiers.isEmpty,
          identifiers.count <= 8, Set(identifiers).count == identifiers.count else {
          result(FlutterError(code: "arguments", message: "Provide 1–8 distinct asset identifiers", details: nil)); return
        }
        job = PhotoPreviewBatch(assetIds: identifiers, completion: completion)
      } else {
        guard let assetId = args["assetId"] as? String else {
          result(FlutterError(code: "arguments", message: "Missing asset identifier", details: nil)); return
        }
        let milliseconds = (args["resourceTimeoutMs"] as? NSNumber)?.doubleValue ?? 4000
        let seconds = min(10, max(0.1, milliseconds / 1000))
        let bytes = min(Int64(128 * 1024 * 1024), max(1,
          (args["maxBytes"] as? NSNumber)?.int64Value ?? Int64(64 * 1024 * 1024)))
        job = PhotoResourceInspection(assetId: assetId,
          includeHash: args["includeHash"] as? Bool ?? false,
          includeThumbnail: args["includeThumbnail"] as? Bool ?? false,
          timeoutSeconds: seconds, maximumBytes: bytes, completion: completion)
      }
      jobs[token] = job; job.start()
    case "cancelInspections":
      let token = args["token"] as? String; let prefix = args["prefix"] as? String
      let cancelled = jobs.filter { entry in token == entry.key || (prefix != nil && entry.key.hasPrefix(prefix!)) }.map { $0.value }
      cancelled.forEach { $0.cancel() }; result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
  private func saveCompressedVideo(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let path = args["path"] as? String else {
      result(FlutterError(code: "save_failed", message: "Missing video path", details: nil)); return
    }
    let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      result(FlutterError(code: "save_failed", message: "Application cache is unavailable", details: nil)); return
    }
    let cache = cacheURL.standardizedFileURL.resolvingSymlinksInPath()
    guard source.deletingLastPathComponent().path == cache.path,
      source.lastPathComponent.hasPrefix("cleanup_preview_"), FileManager.default.fileExists(atPath: source.path) else {
      result(FlutterError(code: "save_failed", message: "Video preview is outside the application cache", details: nil)); return
    }
    let lock = NSLock(); var identifier: String?; var created = false
    PHPhotoLibrary.shared().performChanges({
      let creation = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: source)
      lock.lock(); created = creation != nil
      identifier = creation?.placeholderForCreatedAsset?.localIdentifier; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); let saved = identifier; let didCreate = created; lock.unlock()
      DispatchQueue.main.async {
        if success && didCreate { result(saved ?? "saved_without_identifier") }
        else { result(FlutterError(code: "save_failed", message: error?.localizedDescription ?? "Photos could not save the video", details: nil)) }
      }
    })
  }
}

/// CURRENT cached visual samples are independent of original resource reads.
/// Even non-degraded thumbnails prove no original equality; degraded samples
/// must not drive Best/quality advice.
final class PhotoPreviewInspection: NativePhotoJob {
  private let assetId: String
  private let timeoutSeconds: Double
  private let gate: NativeInspectionCompletion
  private let cached = NativeInspectionResponse()
  init(assetId: String, timeoutSeconds: Double = 1.5,
    completion: @escaping ([String: Any]) -> Void) {
    self.assetId = assetId; self.timeoutSeconds = timeoutSeconds
    gate = NativeInspectionCompletion(completion: completion)
  }
  func start() {
    gate.armDeadline(seconds: timeoutSeconds) { [assetId, cached] in
      cached.get() ?? ["assetId": assetId, "status": "timeout"]
    }
    DispatchQueue.global(qos: .utility).async {
      guard !self.gate.isFinished else { return }
      guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.assetId], options: nil).firstObject,
        asset.mediaType == .image else {
        self.gate.finish(["assetId": self.assetId, "status": "unavailable"]); return
      }
      if self.gate.isFinished { return }
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = false; options.isSynchronous = false
      options.deliveryMode = .opportunistic; options.resizeMode = .fast; options.version = .current
      let manager = PHImageManager.default()
      let request = manager.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256),
        contentMode: .aspectFit, options: options) { [weak self] image, info in
        guard let self = self, !self.gate.isFinished else { return }
        if let image = image, min(image.size.width, image.size.height) >= 16,
          max(image.size.width, image.size.height) >= 64 {
          let scale = min(1, 256 / max(image.size.width, image.size.height))
          let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
          let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
          let rendered = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
          }
          guard let bytes = rendered.jpegData(compressionQuality: 0.88) else {
            self.gate.finish(["assetId": self.assetId, "status": "unavailable"]); return
          }
          // A useful cached sample survives the deadline even if a subsequent
          // Photos fetch stalls. Until validated it has no quality/Best advice.
          let row: [String: Any] = ["assetId": self.assetId, "status": "local",
            "thumbnail": FlutterStandardTypedData(bytes: bytes), "thumbnailDegraded": true]
          self.cached.set(row)
          guard let current = PHAsset.fetchAssets(withLocalIdentifiers: [self.assetId], options: nil).firstObject,
            current.modificationDate == asset.modificationDate else {
            self.gate.finish(["assetId": self.assetId, "status": "unavailable"]); return
          }
          if (info?[PHImageResultIsDegradedKey] as? Bool) != true {
            var final = row; final["thumbnailDegraded"] = false
            self.gate.finish(final)
          }
        } else if (info?[PHImageResultIsInCloudKey] as? Bool) == true {
          self.gate.finish(self.cached.get() ?? ["assetId": self.assetId, "status": "not_local"])
        } else if info?[PHImageErrorKey] != nil || (info?[PHImageResultIsDegradedKey] as? Bool) != true {
          self.gate.finish(self.cached.get() ?? ["assetId": self.assetId, "status": "unavailable"])
        }
      }
      self.gate.track("image") { manager.cancelImageRequest(request) }
    }
  }
  func cancel() { gate.finish(["assetId": assetId, "status": "unavailable", "pendingReason": "cancelled"]) }
}

final class PhotoPreviewBatch: NativePhotoJob {
  private let assetIds: [String]
  private let gate: NativeInspectionCompletion
  private let lock = NSLock()
  private var rows: [String: [String: Any]] = [:]
  private var children: [PhotoPreviewInspection] = []
  init(assetIds: [String], completion: @escaping ([String: Any]) -> Void) {
    self.assetIds = assetIds; gate = NativeInspectionCompletion(completion: completion)
  }
  func start() {
    gate.armDeadline(seconds: 2) { [weak self] in self?.response(missing: "timeout") ?? [:] }
    for identifier in assetIds {
      let child = PhotoPreviewInspection(assetId: identifier) { [weak self] row in
        guard let self = self, !self.gate.isFinished else { return }
        self.lock.lock(); self.rows[identifier] = row; let complete = self.rows.count == self.assetIds.count; self.lock.unlock()
        if complete { self.gate.finish(self.response(missing: "timeout")) }
      }
      children.append(child)
      gate.track(identifier) { child.cancel() }
      child.start()
    }
  }
  private func response(missing: String) -> [String: Any] {
    lock.lock(); defer { lock.unlock() }
    return ["assets": assetIds.map { rows[$0] ?? ["assetId": $0, "status": missing] },
      "complete": false, "sizeKnown": false, "size": 0]
  }
  func cancel() { gate.finish(response(missing: "unavailable")) }
}

/// Complete, unchanged ALL-resource reads verify SHA/size. A single original
/// video resource can also verify size from its local file without reading it.
final class PhotoResourceInspection: NativePhotoJob {
  private let assetId: String
  private let includeHash: Bool
  private let includeThumbnail: Bool
  private let timeoutSeconds: Double
  private let maximumBytes: Int64
  private let io: NativeResourceIO
  private let videoIO: NativeOriginalVideoIO
  private let gate: NativeInspectionCompletion
  private let verified = NativeInspectionResponse()
  private let queue = DispatchQueue(label: "cleanup.resource-state", qos: .utility)
  private var resources: [PHAssetResource] = []
  private var asset: PHAsset?
  private var resourceIndex = 0
  private var totalBytes: Int64 = 0
  private var descriptors: [String] = []
  init(assetId: String, includeHash: Bool, includeThumbnail: Bool,
    timeoutSeconds: Double = 4, maximumBytes: Int64 = 64 * 1024 * 1024,
    io: NativeResourceIO = PhotosResourceIO(), videoIO: NativeOriginalVideoIO = PhotosOriginalVideoIO(),
    completion: @escaping ([String: Any]) -> Void) {
    self.assetId = assetId; self.includeHash = includeHash; self.includeThumbnail = includeThumbnail
    self.timeoutSeconds = timeoutSeconds; self.maximumBytes = maximumBytes; self.io = io
    self.videoIO = videoIO
    gate = NativeInspectionCompletion(completion: completion)
  }
  private static let knownResourceTypes: Set<Int> = Set(1...12)
  private static func pending(_ reason: String) -> [String: Any] {
    ["sizeKnown": false, "sizeComplete": false, "hashComplete": false,
      "size": 0, "complete": false, "pendingReason": reason]
  }
  static func canReadOriginalVideoFileSize(mediaType: PHAssetMediaType,
    resourceTypes: [PHAssetResourceType], includeHash: Bool) -> Bool {
    !includeHash && mediaType == .video && resourceTypes.count == 1 && resourceTypes.first == .video
  }
  static func localRegularFileSize(at url: URL) -> Int64? {
    guard url.isFileURL, url.host == nil || url.host == "" || url.host == "localhost",
      let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
      values.isRegularFile == true, let bytes = values.fileSize, bytes > 0 else { return nil }
    return Int64(bytes)
  }
  func start() {
    gate.armDeadline(seconds: timeoutSeconds) { [verified] in verified.get() ?? Self.pending("resource_time_budget") }
    queue.async {
      guard !self.gate.isFinished else { return }
      guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.assetId], options: nil).firstObject else {
        self.fail("asset_unavailable"); return
      }
      self.asset = asset; self.resources = PHAssetResource.assetResources(for: asset)
      guard !self.resources.isEmpty else { self.fail("no_resources"); return }
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
      guard !self.gate.isFinished else { return }
      if Self.canReadOriginalVideoFileSize(mediaType: asset.mediaType,
        resourceTypes: self.resources.map { $0.type }, includeHash: self.includeHash) {
        self.readOriginalVideoFileSize(asset)
      } else { self.readNextResource() }
    }
  }
  func cancel() { gate.finish(Self.pending("cancelled")) }
  private func fail(_ reason: String) { gate.finish(Self.pending(reason)) }
  private func readOriginalVideoFileSize(_ asset: PHAsset) {
    guard !gate.isFinished else { return }
    let key = "original-video-size"
    let options = PHVideoRequestOptions(); options.version = .original; options.isNetworkAccessAllowed = false
    let request = videoIO.request(asset, options: options) { [weak self] video, info in
      guard let self = self else { return }
      self.queue.async {
        guard !self.gate.isFinished else { return }
        self.gate.untrack(key)
        // Compositions, cloud-only videos and inaccessible files use the
        // existing bounded resource stream; no export or download is started.
        guard info?[PHImageErrorKey] == nil, (info?[PHImageCancelledKey] as? Bool) != true,
          let original = video as? AVURLAsset,
          let bytes = Self.localRegularFileSize(at: original.url) else {
          self.readNextResource(); return
        }
        self.totalBytes = bytes; self.succeed()
      }
    }
    gate.track(key) { [videoIO] in videoIO.cancel(request) }
  }
  private func readNextResource() {
    guard !gate.isFinished else { return }
    if resourceIndex == resources.count { succeed(); return }
    let resource = resources[resourceIndex]
    let completedBytes = totalBytes
    let key = "resource-\(resourceIndex)"
    let counter = NativeResourceAccumulator(maximumBytes: maximumBytes - totalBytes, includeHash: includeHash)
    let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = false
    let request = io.request(resource, options: options, data: { [weak self] chunk in
      guard let self = self, !self.gate.isFinished else { return }
      if !counter.append(chunk) {
        var response = Self.pending("byte_budget_exceeded")
        response["partialBytes"] = completedBytes + counter.snapshot().bytes
        self.gate.finish(response)
      }
    }, completion: { [weak self] error in
      guard let self = self else { return }
      self.queue.async {
        guard !self.gate.isFinished else { return }
        self.gate.untrack(key)
        let value = counter.snapshot()
        guard error == nil && value.bytes > 0 else { self.fail("local_resource_unavailable"); return }
        self.totalBytes += value.bytes
        if let digest = value.digest { self.descriptors.append("\(resource.type.rawValue):\(value.bytes):\(digest)") }
        self.resourceIndex += 1; self.readNextResource()
      }
    })
    gate.track(key) { [io] in io.cancel(request) }
  }
  private func succeed() {
    guard !gate.isFinished else { return }
    guard let original = asset,
      let current = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject,
      current.modificationDate == original.modificationDate && current.mediaType == original.mediaType,
      current.pixelWidth == original.pixelWidth && current.pixelHeight == original.pixelHeight,
      current.mediaSubtypes == original.mediaSubtypes,
      PHAssetResource.assetResources(for: current).map({ $0.type.rawValue }).sorted() ==
        resources.map({ $0.type.rawValue }).sorted() else {
      fail("asset_changed_during_analysis"); return
    }
    let hashComplete = includeHash && descriptors.count == resources.count
    var response: [String: Any] = ["sizeKnown": true, "sizeComplete": true,
      "hashComplete": hashComplete, "size": totalBytes, "complete": true]
    if hashComplete {
      let compound = "photos-resources-v1\n" + descriptors.sorted().joined(separator: "\n") + "\n"
      response["hash"] = SHA256.hash(data: Data(compound.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    verified.set(response)
    guard includeThumbnail else { gate.finish(response); return }
    // Compatibility only; primary scanning requests preview batches separately.
    let preview = PhotoPreviewInspection(assetId: assetId, timeoutSeconds: 1.5) { [weak self] row in
      var combined = response
      if let bytes = row["thumbnail"] {
        combined["thumbnail"] = bytes; combined["thumbnailDegraded"] = row["thumbnailDegraded"]
      } else { combined["pendingReason"] = "local_preview_unavailable" }
      self?.gate.finish(combined)
    }
    gate.track("preview") { preview.cancel() }; preview.start()
  }
}
