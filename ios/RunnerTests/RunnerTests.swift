import Flutter
import Photos
import UIKit
import XCTest
import AVFoundation
import CoreVideo
import CryptoKit
@testable import Runner

/// Real Swift queue/cancellation tests plus real Photos reads on the CI
/// simulator. These never create or delete media on a physical device.
private final class ControlledResourceIO: NativeResourceIO {
  private let lock = NSLock()
  var onRequest: (() -> Void)?
  var onCancel: (() -> Void)?
  var requestBarrier: DispatchSemaphore?
  var cancelBarrier: DispatchSemaphore?
  private var received: ((Data) -> Void)?
  private var completed: ((Error?) -> Void)?
  func request(_ resource: PHAssetResource, options: PHAssetResourceRequestOptions,
    data: @escaping (Data) -> Void, completion: @escaping (Error?) -> Void) -> PHAssetResourceDataRequestID {
    XCTAssertFalse(options.isNetworkAccessAllowed, "Original verification must never download iCloud resources.")
    lock.lock(); received = data; completed = completion; lock.unlock()
    onRequest?()
    requestBarrier?.wait()
    return 42
  }
  func cancel(_ identifier: PHAssetResourceDataRequestID) {
    XCTAssertEqual(identifier, 42)
    onCancel?()
    cancelBarrier?.wait()
  }
  func send(_ bytes: Data) {
    lock.lock(); let callback = received; lock.unlock(); callback?(bytes)
  }
  func settle() {
    lock.lock(); let callback = completed; lock.unlock(); callback?(nil)
  }
}

/// Persistent, owned Photos fixtures for the two real Flutter integration
/// workloads. Selected explicitly by the CI harness, never during app startup.
/// No Photos deletion occurs here: both stages use the same disposable simulator.
private func requireNativeFixtureModeMarker() throws {
  #if targetEnvironment(simulator)
  let marker = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("cleanup-native-fixture-mode")
  let exists = FileManager.default.fileExists(atPath: marker.path)
  print("Native Documents fixture-only marker: exists=\(exists), path=\(marker.path)")
  guard exists else {
    XCTFail("The isolated native test host must suppress Dart scans before native fixtures are ready.")
    throw NSError(domain: "CleanupNativeTests", code: 25)
  }
  #endif
}

final class PhotoLibrarySeedTests: XCTestCase {
  private let owner = "cleanup-native-photos-integration-v1"
  private let manifestName = "cleanup-scan-fixtures.json"

  override func setUpWithError() throws {
    continueAfterFailure = false
    try requireNativeFixtureModeMarker()
  }

  private var manifestURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(manifestName)
  }

  private func digest(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private func requireSimulatorAuthorization() throws {
    #if targetEnvironment(simulator)
    let status: PHAuthorizationStatus
    if #available(iOS 14, *) { status = PHPhotoLibrary.authorizationStatus(for: .readWrite) }
    else { status = PHPhotoLibrary.authorizationStatus() }
    guard status == .authorized else {
      XCTFail("Real modern full Photos permission is required for the seed workloads, status=\(status.rawValue).")
      throw NSError(domain: owner, code: 10)
    }
    #else
    throw XCTSkip("Bulk Photos fixtures are restricted to an isolated simulator.")
    #endif
  }

  private func jpeg(index: Int, variant: Int = 0, width: Int = 320, height: Int = 240) throws -> Data {
    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
    let size = CGSize(width: CGFloat(width), height: CGFloat(height))
    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
      let canvas = CGRect(origin: .zero, size: size)
      let hue = CGFloat((index * 37) % 360) / 360
      UIColor(hue: hue, saturation: 0.55, brightness: 0.82, alpha: 1).setFill()
      context.fill(canvas)
      let scaleX = CGFloat(width) / 320, scaleY = CGFloat(height) / 240
      context.cgContext.scaleBy(x: scaleX, y: scaleY)
      for shape in 0..<6 {
        UIColor(hue: CGFloat((index * 17 + shape * 53) % 360) / 360,
          saturation: 0.7, brightness: 0.95, alpha: 1).setFill()
        let x = CGFloat((index * 23 + shape * 47) % 250) + CGFloat(variant)
        let y = CGFloat((index * 11 + shape * 31) % 175)
        let box = CGRect(x: x, y: y, width: CGFloat(35 + (shape * 9)), height: CGFloat(25 + (shape * 7)))
        if (index + shape) % 2 == 0 { context.cgContext.fillEllipse(in: box) }
        else { context.cgContext.fill(box) }
      }
      // Distinct visible content, not thousands of identical files with fake IDs.
      let label = "Cleanup fixture \(index)" as NSString
      label.draw(at: CGPoint(x: 8, y: 212), withAttributes: [
        .font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: UIColor.white])
      if variant > 0 {
        UIColor.white.setFill()
        context.cgContext.fill(CGRect(x: 300 - variant, y: 8, width: 3, height: 3))
      }
    }
    return try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
  }

  private struct SeedPhoto {
    let data: Data
    let fileURL: URL?
    let role: String
    let index: Int
    let date: Date
  }

  private func importPhotos(_ photos: [SeedPhoto], timeout: TimeInterval = 60) throws -> [String] {
    // addResource(data:) may normalize JPEG metadata on import (the real CI
    // observed +62 bytes on the first similar photo). Use actual source files
    // for every JPEG, retaining independent input Data SHA/byte expectations.
    var ownedFiles: [URL] = []
    defer { for file in ownedFiles { try? FileManager.default.removeItem(at: file) } }
    let files = try photos.map { photo -> URL in
      if let file = photo.fileURL { return file }
      let file = FileManager.default.temporaryDirectory
        .appendingPathComponent("cleanup-source-jpeg-\(UUID().uuidString).jpg")
      ownedFiles.append(file)
      try photo.data.write(to: file)
      return file
    }
    let firstIndex = photos.first?.index ?? -1
    let lastIndex = photos.last?.index ?? -1
    let saved = expectation(description: "Import \(photos.count) real JPEG Photos assets")
    let lock = NSLock(); var ids: [String] = []; var saveError: Error?
    let started = Date()
    print("REAL_PHOTOS_IMPORT_BEGIN first=\(firstIndex) last=\(lastIndex) count=\(photos.count) timeout=\(Int(timeout))s")
    // Photos may pause a large simulator library while its database catches
    // up. Give each small transaction a finite deadline and show liveness in
    // the CI log; never retry an unresolved transaction that could commit late.
    let heartbeat = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
    heartbeat.schedule(deadline: .now() + 15, repeating: .seconds(15))
    heartbeat.setEventHandler {
      print("REAL_PHOTOS_IMPORT_WAIT first=\(firstIndex) last=\(lastIndex) elapsed=\(Int(Date().timeIntervalSince(started)))s")
    }
    heartbeat.resume()
    defer { heartbeat.cancel() }
    PHPhotoLibrary.shared().performChanges({
      var created: [String] = []
      for (index, photo) in photos.enumerated() {
        let request = PHAssetCreationRequest.forAsset()
        request.creationDate = photo.date
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = photo.fileURL?.lastPathComponent ?? "cleanup-fixture-\(photo.index).jpg"
        options.shouldMoveFile = false
        request.addResource(with: .photo, fileURL: files[index], options: options)
        if let id = request.placeholderForCreatedAsset?.localIdentifier { created.append(id) }
      }
      lock.lock(); ids = created; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); saveError = success ? nil : error ?? NSError(domain: self.owner, code: 11); lock.unlock()
      saved.fulfill()
    })
    let outcome = XCTWaiter.wait(for: [saved], timeout: timeout)
    guard outcome == .completed else {
      XCTFail("Photos import did not finish: first=\(firstIndex) last=\(lastIndex) count=\(photos.count) elapsed=\(Int(Date().timeIntervalSince(started)))s waiter=\(outcome). Transaction was not retried because it may still commit.")
      throw NSError(domain: owner, code: 25)
    }
    lock.lock(); let result = ids; let error = saveError; lock.unlock()
    if let error = error { throw error }
    guard result.count == photos.count else {
      XCTFail("A real creation placeholder is required for every JPEG: \(result.count)/\(photos.count).")
      throw NSError(domain: owner, code: 12)
    }
    // Placeholders alone are not proof that the committed assets are visible
    // to the production Photos query. Check every batch before recording IDs.
    var visibleCount = 0
    let visibilityDeadline = Date().addingTimeInterval(20)
    repeat {
      visibleCount = PHAsset.fetchAssets(withLocalIdentifiers: result, options: nil).count
      if visibleCount == result.count { break }
      Thread.sleep(forTimeInterval: 0.25)
    } while Date() < visibilityDeadline
    guard visibleCount == result.count else {
      XCTFail("Committed Photos batch is not fully queryable: first=\(firstIndex) last=\(lastIndex) visible=\(visibleCount)/\(result.count).")
      throw NSError(domain: owner, code: 26)
    }
    print("REAL_PHOTOS_IMPORT_VERIFIED first=\(firstIndex) last=\(lastIndex) count=\(result.count) elapsed=\(Int(Date().timeIntervalSince(started)))s")
    return result
  }

  private func makeEncodedVideo(minimumBytes: Int64) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("cleanup-real-video-\(UUID().uuidString).mov")
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
    let width = 1280, height = 720, frameRate: Int32 = 24
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 160_000_000,
        AVVideoMaxKeyFrameIntervalKey: 1, AVVideoAllowFrameReorderingKey: false,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
      sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
    guard writer.canAdd(input) else { throw NSError(domain: owner, code: 13) }
    writer.add(input)
    guard writer.startWriting() else { throw writer.error ?? NSError(domain: owner, code: 14) }
    writer.startSession(atSourceTime: .zero)
    let written = expectation(description: "Encode an actual H264 video larger than \(minimumBytes) bytes")
    let queue = DispatchQueue(label: "cleanup.seed-real-video")
    var frameCount = 0; var finishing = false
    input.requestMediaDataWhenReady(on: queue) {
      guard !finishing else { return }
      while input.isReadyForMoreMediaData && !finishing {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
          nil, &buffer)
        guard status == kCVReturnSuccess, let frame = buffer else {
          finishing = true; writer.cancelWriting(); written.fulfill(); return
        }
        CVPixelBufferLockBaseAddress(frame, [])
        if let base = CVPixelBufferGetBaseAddress(frame) {
          let byteCount = CVPixelBufferGetBytesPerRow(frame) * height
          arc4random_buf(base, byteCount)
          let pixels = base.assumingMemoryBound(to: UInt32.self)
          for index in 0..<(byteCount / 4) { pixels[index] |= 0xFF000000 }
        }
        CVPixelBufferUnlockBaseAddress(frame, [])
        guard adaptor.append(frame, withPresentationTime: CMTime(value: Int64(frameCount), timescale: frameRate)) else {
          finishing = true; writer.cancelWriting(); written.fulfill(); return
        }
        frameCount += 1
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        if (frameCount >= 24 && bytes > minimumBytes + 2 * 1024 * 1024) || frameCount >= 480 {
          finishing = true; input.markAsFinished()
          writer.endSession(atSourceTime: CMTime(value: Int64(frameCount), timescale: frameRate))
          writer.finishWriting { written.fulfill() }
        }
      }
    }
    wait(for: [written], timeout: 180)
    guard writer.status == .completed else {
      writer.cancelWriting(); try? FileManager.default.removeItem(at: url)
      throw writer.error ?? NSError(domain: owner, code: 15)
    }
    let bytes = try XCTUnwrap(PhotoResourceInspection.localRegularFileSize(at: url))
    let video = AVURLAsset(url: url)
    guard bytes > minimumBytes, !video.tracks(withMediaType: .video).isEmpty,
      video.duration.isValid, CMTimeGetSeconds(video.duration) > 0 else {
      try? FileManager.default.removeItem(at: url)
      XCTFail("The fixture must contain real encoded video frames and actual file bytes above the threshold.")
      throw NSError(domain: owner, code: 16)
    }
    print("Real H264 seed encoded: frames=\(frameCount), bytes=\(bytes), seconds=\(CMTimeGetSeconds(video.duration))")
    return url
  }

  private func importVideo(_ url: URL) throws -> String {
    let saved = expectation(description: "Save the actual large video to Photos")
    let lock = NSLock(); var identifier: String?; var saveError: Error?
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.creationDate = Date()
      request.addResource(with: .video, fileURL: url, options: nil)
      lock.lock(); identifier = request.placeholderForCreatedAsset?.localIdentifier; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); saveError = success ? nil : error ?? NSError(domain: self.owner, code: 17); lock.unlock()
      saved.fulfill()
    })
    wait(for: [saved], timeout: 60)
    lock.lock(); let result = identifier; let error = saveError; lock.unlock()
    if let error = error { throw error }
    return try XCTUnwrap(result)
  }

  private func makeShortVideoTemplate(index: Int, url: URL) throws {
    let width = index % 2 == 0 ? 640 : 480
    let height = index % 2 == 0 ? 360 : 640
    let frames = index % 2 == 0 ? 24 : 36
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
      sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
    guard writer.canAdd(input) else { throw NSError(domain: owner, code: 21) }
    writer.add(input)
    guard writer.startWriting() else { throw writer.error ?? NSError(domain: owner, code: 22) }
    writer.startSession(atSourceTime: .zero)
    let written = expectation(description: "Encode distinct moving short-video template \(index)")
    var frameCount = 0; var finishing = false
    input.requestMediaDataWhenReady(on: DispatchQueue(label: "cleanup.seed-short-video")) {
      guard !finishing else { return }
      while input.isReadyForMoreMediaData && !finishing {
        var buffer: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
          nil, &buffer) == kCVReturnSuccess, let frame = buffer else {
          finishing = true; writer.cancelWriting(); written.fulfill(); return
        }
        CVPixelBufferLockBaseAddress(frame, [])
        guard let base = CVPixelBufferGetBaseAddress(frame),
          let canvas = CGContext(data: base, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(frame), space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
          CVPixelBufferUnlockBaseAddress(frame, [])
          finishing = true; writer.cancelWriting(); written.fulfill(); return
        }
        canvas.setFillColor(UIColor(hue: CGFloat(index) / 10, saturation: 0.65, brightness: 0.8, alpha: 1).cgColor)
        canvas.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        canvas.setFillColor(UIColor.white.cgColor)
        let x = CGFloat((frameCount * 13 + index * 29) % (width - 80))
        canvas.fill(CGRect(x: x, y: CGFloat(height / 4), width: 80, height: 65))
        canvas.setFillColor(UIColor(hue: CGFloat((index + 4) % 10) / 10,
          saturation: 0.9, brightness: 1, alpha: 1).cgColor)
        canvas.fillEllipse(in: CGRect(x: CGFloat(width / 3), y: CGFloat((frameCount * 7) % (height - 70)),
          width: CGFloat(40 + index * 3), height: 60))
        CVPixelBufferUnlockBaseAddress(frame, [])
        guard adaptor.append(frame, withPresentationTime: CMTime(value: Int64(frameCount), timescale: 24)) else {
          finishing = true; writer.cancelWriting(); written.fulfill(); return
        }
        frameCount += 1
        if frameCount == frames {
          finishing = true; input.markAsFinished()
          writer.endSession(atSourceTime: CMTime(value: Int64(frames), timescale: 24))
          writer.finishWriting { written.fulfill() }
        }
      }
    }
    wait(for: [written], timeout: 30)
    guard writer.status == .completed else {
      writer.cancelWriting(); throw writer.error ?? NSError(domain: owner, code: 23)
    }
    let video = AVURLAsset(url: url)
    XCTAssertGreaterThan(try XCTUnwrap(PhotoResourceInspection.localRegularFileSize(at: url)), 0)
    XCTAssertFalse(video.tracks(withMediaType: .video).isEmpty)
    XCTAssertGreaterThanOrEqual(CMTimeGetSeconds(video.duration), 1)
  }

  private func importShortVideos(_ urls: [URL], startingAt offset: Int) throws -> [String] {
    let saved = expectation(description: "Import \(urls.count) real short Photos videos")
    let lock = NSLock(); var ids: [String] = []; var saveError: Error?
    PHPhotoLibrary.shared().performChanges({
      var created: [String] = []
      for (index, url) in urls.enumerated() {
        let request = PHAssetCreationRequest.forAsset()
        request.creationDate = Date(timeIntervalSince1970: 1262304000 + Double(((offset + index) * 163) % 4800) * 86400)
        let options = PHAssetResourceCreationOptions(); options.shouldMoveFile = false
        request.addResource(with: .video, fileURL: url, options: options)
        if let id = request.placeholderForCreatedAsset?.localIdentifier { created.append(id) }
      }
      lock.lock(); ids = created; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); saveError = success ? nil : error ?? NSError(domain: self.owner, code: 24); lock.unlock()
      saved.fulfill()
    })
    wait(for: [saved], timeout: 60)
    lock.lock(); let result = ids; let error = saveError; lock.unlock()
    if let error = error { throw error }
    XCTAssertEqual(result.count, urls.count)
    return result
  }

  private func inspect(_ identifier: String, hash: Bool) throws -> [String: Any] {
    let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject)
    let resources = PHAssetResource.assetResources(for: asset)
    XCTAssertEqual(resources.count, 1)
    XCTAssertEqual(resources.first?.type, hash ? .photo : .video)
    let replied = expectation(description: "Run production Photos inspection for \(identifier)")
    var response: [String: Any]?
    // These are the actual production reader, video IO, completeness guards and
    // unchanged-asset checks, with the production 4s / 64MiB limits.
    let job = PhotoResourceInspection(assetId: identifier, includeHash: hash,
      includeThumbnail: false, timeoutSeconds: 4, maximumBytes: 64 * 1024 * 1024) {
      response = $0; replied.fulfill()
    }
    job.start(); wait(for: [replied], timeout: 6)
    let result = try XCTUnwrap(response)
    let diagnostic = try JSONSerialization.data(withJSONObject: ["id": identifier,
      "includeHash": hash, "result": result], options: [.sortedKeys])
    print("REAL_PHOTOS_INSPECTION_RESULT \(String(decoding: diagnostic, as: UTF8.self))")
    XCTAssertEqual(result["complete"] as? Bool, true, "\(result)")
    XCTAssertEqual(result["sizeKnown"] as? Bool, true)
    XCTAssertEqual(result["sizeComplete"] as? Bool, true)
    XCTAssertEqual(result["hashComplete"] as? Bool, hash)
    if hash { XCTAssertEqual((result["hash"] as? String)?.count, 64) }
    else { XCTAssertNil(result["hash"]) }
    return result
  }

  private func seed(photoCount target: Int) throws {
    try requireSimulatorAuthorization()
    var manifest: [String: Any] = [:]
    if FileManager.default.fileExists(atPath: manifestURL.path) {
      manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
      guard manifest["owner"] as? String == owner else { throw NSError(domain: owner, code: 18) }
    }
    var photoIds = manifest["photoFixtureIds"] as? [String] ?? []
    var allIds = manifest["allFixtureIds"] as? [String] ?? []
    var duplicateIds = manifest["duplicateIds"] as? [String] ?? []
    var differentIds = manifest["differentPhotoIds"] as? [String] ?? []
    var videoIds = manifest["largeVideoIds"] as? [String] ?? []
    var shortVideoIds = manifest["shortVideoIds"] as? [String] ?? []
    var assetBytes = manifest["assetBytes"] as? [String: Int64] ?? [:]
    var sourceByteCounts = manifest["sourceByteCounts"] as? [String: Int64] ?? [:]
    var sourceHashes = manifest["sourceSHA256"] as? [String: String] ?? [:]
    var sourceHashesSeen = Set(sourceHashes.values)
    guard photoIds.count <= target, target == 1000 || (target == 10000 && photoIds.count == 1000),
      allIds.count == Set(allIds).count,
      PHAsset.fetchAssets(withLocalIdentifiers: allIds, options: nil).count == allIds.count else {
      XCTFail("Only this simulator's own intact 1000-item workload may be extended to 10000.")
      throw NSError(domain: owner, code: 19)
    }
    let duplicateFile = FileManager.default.temporaryDirectory.appendingPathComponent("cleanup-identical-\(UUID().uuidString).jpg")
    defer { try? FileManager.default.removeItem(at: duplicateFile) }
    if photoIds.isEmpty {
      let sameJPEG = try jpeg(index: 800001)
      try sameJPEG.write(to: duplicateFile)
      var marked: [SeedPhoto] = []
      for index in 0..<8 {
        let data: Data
        if index < 2 { data = sameJPEG }
        else { data = try jpeg(index: 810000 + ((index - 2) / 3), variant: (index - 2) % 3) }
        marked.append(SeedPhoto(data: data, fileURL: index < 2 ? duplicateFile : nil,
          role: index < 2 ? "duplicate" : "similar", index: index,
          date: Date().addingTimeInterval(Double(index - 20))))
      }
      let created = try importPhotos(marked)
      for (offset, id) in created.enumerated() {
        photoIds.append(id); allIds.append(id)
        sourceByteCounts[id] = Int64(marked[offset].data.count); sourceHashes[id] = digest(marked[offset].data)
        sourceHashesSeen.insert(sourceHashes[id]!)
        if offset < 2 { duplicateIds.append(id) } else { differentIds.append(id) }
      }
      for threshold in [Int64(5 * 1024 * 1024), Int64(64 * 1024 * 1024)] {
        let file = try makeEncodedVideo(minimumBytes: threshold)
        defer { try? FileManager.default.removeItem(at: file) }
        let bytes = try XCTUnwrap(PhotoResourceInspection.localRegularFileSize(at: file))
        let id = try importVideo(file)
        videoIds.append(id); allIds.append(id); sourceByteCounts[id] = bytes
      }
    }
    while photoIds.count < target {
      // A 250-resource transaction stalled after 5,250 photos on the 10k CI
      // simulator. Smaller commits reduce Photos daemon backpressure while
      // preserving real file-backed Photos assets and exact count checks.
      let batchSize = target == 10000 ? 50 : 250
      let start = photoIds.count, end = min(target, start + batchSize)
      var batch: [SeedPhoto] = []
      for index in start..<end {
        let highResolution = index % 100 == 0
        let landscapeWidth = highResolution ? 4032 : index % 3 == 0 ? 1280 : 640
        let landscapeHeight = highResolution ? 3024 : index % 3 == 0 ? 960 : 480
        let portrait = highResolution ? (index / 100) % 2 == 1 : index % 2 == 1
        let width = portrait ? landscapeHeight : landscapeWidth
        let height = portrait ? landscapeWidth : landscapeHeight
        let data = try autoreleasepool {
          try jpeg(index: index, width: width, height: height)
        }
        let hash = digest(data)
        guard sourceHashesSeen.insert(hash).inserted else {
          XCTFail("Unique synthetic photos must contain distinct encoded JPEG content.")
          throw NSError(domain: owner, code: 20)
        }
        let past = Date(timeIntervalSince1970: 1262304000 + Double((index * 179) % 4800) * 86400)
        batch.append(SeedPhoto(data: data, fileURL: nil, role: "unique", index: index, date: past))
      }
      let created = try importPhotos(batch, timeout: target == 10000 ? 180 : 60)
      for (offset, id) in created.enumerated() {
        photoIds.append(id); allIds.append(id)
        sourceByteCounts[id] = Int64(batch[offset].data.count); sourceHashes[id] = digest(batch[offset].data)
      }
      print("Real Photos seed progress: \(photoIds.count)/\(target) photos plus \(videoIds.count + shortVideoIds.count) videos")
    }
    let sourceDirectory = manifestURL.deletingLastPathComponent().appendingPathComponent("cleanup-seed-video-sources")
    try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
    var shortSources: [URL] = [], shortSourceHashes: Set<String> = []
    for index in 0..<10 {
      let file = sourceDirectory.appendingPathComponent("cleanup-short-template-\(index).mov")
      if !FileManager.default.fileExists(atPath: file.path) { try makeShortVideoTemplate(index: index, url: file) }
      let video = AVURLAsset(url: file)
      XCTAssertFalse(video.tracks(withMediaType: .video).isEmpty)
      XCTAssertGreaterThanOrEqual(CMTimeGetSeconds(video.duration), 1)
      XCTAssertTrue(shortSourceHashes.insert(digest(try Data(contentsOf: file))).inserted,
        "At least ten genuinely different encoded short-video templates are required.")
      shortSources.append(file)
    }
    let shortTarget = target / 20
    XCTAssertLessThanOrEqual(shortVideoIds.count, shortTarget)
    while shortVideoIds.count < shortTarget {
      let start = shortVideoIds.count, end = min(shortTarget, start + 100)
      let files = (start..<end).map { shortSources[$0 % shortSources.count] }
      let created = try importShortVideos(files, startingAt: start)
      for (offset, id) in created.enumerated() {
        shortVideoIds.append(id); allIds.append(id)
        sourceByteCounts[id] = try XCTUnwrap(PhotoResourceInspection.localRegularFileSize(at: files[offset]))
      }
      print("Real Photos short-video seed progress: \(shortVideoIds.count)/\(shortTarget)")
    }
    let allVideoIds = videoIds + shortVideoIds
    let actual = PHAsset.fetchAssets(withLocalIdentifiers: allIds, options: nil)
    XCTAssertEqual(actual.count, target + shortTarget + 2)
    XCTAssertEqual(PHAsset.fetchAssets(withLocalIdentifiers: photoIds, options: nil).count, target)
    var actualPhotos = 0, actualVideos = 0
    var resolutionCounts: [String: Int] = [:]
    var videoResolutionCounts: [String: Int] = [:]
    actual.enumerateObjects { asset, _, _ in
      if asset.mediaType == .image {
        actualPhotos += 1
        let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
        resolutionCounts[resolution, default: 0] += 1
      } else if asset.mediaType == .video {
        actualVideos += 1
        let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
        videoResolutionCounts[resolution, default: 0] += 1
      }
    }
    XCTAssertEqual(actualPhotos, target); XCTAssertEqual(actualVideos, shortTarget + 2)
    XCTAssertEqual(PHAsset.fetchAssets(withLocalIdentifiers: allVideoIds, options: nil).count, shortTarget + 2)
    let shortAssets = PHAsset.fetchAssets(withLocalIdentifiers: shortVideoIds, options: nil)
    XCTAssertEqual(shortAssets.count, shortTarget)
    shortAssets.enumerateObjects { asset, _, _ in
      XCTAssertEqual(asset.mediaType, .video)
      let resources = PHAssetResource.assetResources(for: asset)
      XCTAssertEqual(resources.count, 1); XCTAssertEqual(resources.first?.type, .video)
    }
    XCTAssertEqual(videoResolutionCounts.values.reduce(0, +), shortTarget + 2)
    XCTAssertEqual(resolutionCounts.values.reduce(0, +), target)
    XCTAssertGreaterThan(resolutionCounts["4032x3024", default: 0], 0)
    XCTAssertGreaterThan(resolutionCounts["3024x4032", default: 0], 0)
    XCTAssertEqual(duplicateIds.count, 2); XCTAssertEqual(differentIds.count, 6); XCTAssertEqual(videoIds.count, 2)
    var nativeResults: [String: [String: Any]] = [:]
    // Save provenance before fail-fast assertions, so a real I/O mismatch still
    // has its own asset/role/source identity in machine-readable artifacts. It
    // remains explicitly pending and cannot pass the Flutter/harness guard.
    var pendingManifest: [String: Any] = ["schemaVersion": 1, "owner": owner,
      "stage": target, "workloadCount": target, "actualFixtureCount": actual.count,
      "status": "native_validation_pending", "allFixtureIds": allIds,
      "photoFixtureIds": photoIds, "duplicateIds": duplicateIds,
      "differentPhotoIds": differentIds, "largeVideoIds": videoIds,
      "shortVideoIds": shortVideoIds, "videoFixtureIds": allVideoIds,
      "sourceByteCounts": sourceByteCounts, "sourceSHA256": sourceHashes,
      "nativeResultsById": nativeResults]
    try JSONSerialization.data(withJSONObject: pendingManifest, options: [.prettyPrinted, .sortedKeys])
      .write(to: manifestURL, options: .atomic)
    for id in duplicateIds + differentIds + videoIds {
      let isPhoto = !videoIds.contains(id)
      let result = try inspect(id, hash: isPhoto)
      let measuredBytes = try XCTUnwrap((result["size"] as? NSNumber)?.int64Value)
      nativeResults[id] = result
      pendingManifest["nativeResultsById"] = nativeResults
      try JSONSerialization.data(withJSONObject: pendingManifest, options: [.prettyPrinted, .sortedKeys])
        .write(to: manifestURL, options: .atomic)
      var diagnostic: [String: Any] = ["id": id,
        "role": duplicateIds.contains(id) ? "duplicate" : differentIds.contains(id) ? "similar" : "large_video",
        "sourceBytes": try XCTUnwrap(sourceByteCounts[id]), "measuredBytes": measuredBytes,
        "nativeResult": result]
      if let source = sourceHashes[id], let bytes = sourceByteCounts[id] {
        diagnostic["sourceSHA256"] = source
        diagnostic["expectedCompoundSHA256"] = digest(Data("photos-resources-v1\n1:\(bytes):\(source)\n".utf8))
      }
      let diagnosticData = try JSONSerialization.data(withJSONObject: diagnostic, options: [.sortedKeys])
      print("REAL_PHOTOS_MARKER_RESULT \(String(decoding: diagnosticData, as: UTF8.self))")
      XCTAssertEqual(measuredBytes, sourceByteCounts[id])
      assetBytes[id] = measuredBytes
      if isPhoto {
        let source = try XCTUnwrap(sourceHashes[id]), bytes = try XCTUnwrap(assetBytes[id])
        let expected = digest(Data("photos-resources-v1\n1:\(bytes):\(source)\n".utf8))
        XCTAssertEqual(result["hash"] as? String, expected)
      }
    }
    XCTAssertEqual(nativeResults[duplicateIds[0]]?["hash"] as? String, nativeResults[duplicateIds[1]]?["hash"] as? String)
    let distinctHashes = differentIds.compactMap { nativeResults[$0]?["hash"] as? String }
    XCTAssertEqual(Set(distinctHashes).count, differentIds.count)
    XCTAssertFalse(distinctHashes.contains(nativeResults[duplicateIds[0]]?["hash"] as? String ?? ""))
    XCTAssertGreaterThan(try XCTUnwrap(assetBytes[videoIds[0]]), Int64(5 * 1024 * 1024))
    XCTAssertGreaterThan(try XCTUnwrap(assetBytes[videoIds[1]]), Int64(64 * 1024 * 1024))
    manifest = ["schemaVersion": 1, "owner": owner, "stage": target, "workloadCount": target,
      "actualFixtureCount": actual.count, "allFixtureIds": allIds, "photoFixtureIds": photoIds,
      "duplicateIds": duplicateIds, "differentPhotoIds": differentIds, "largeVideoIds": videoIds,
      "shortVideoIds": shortVideoIds, "videoFixtureIds": allVideoIds,
      "assetBytes": assetBytes, "sourceByteCounts": sourceByteCounts, "sourceSHA256": sourceHashes,
      "nativeResultsById": nativeResults, "resolutionCounts": resolutionCounts,
      "photoResolutionCounts": resolutionCounts, "videoResolutionCounts": videoResolutionCounts,
      "shortVideoTemplateCount": shortSources.count,
      "shortVideoTemplateSHA256": shortSourceHashes.sorted(),
      "shortVideosReuseTenEncodedSources": true,
      "sourcePhotoBytes": photoIds.reduce(Int64(0)) { $0 + (sourceByteCounts[$1] ?? 0) },
      "sourceVideoBytes": allVideoIds.reduce(Int64(0)) { $0 + (sourceByteCounts[$1] ?? 0) },
      "fixtureRoleCounts": ["duplicatePhotos": 2, "similarPhotos": 6, "uniquePhotos": target - 8,
        "normalVideos": 1, "largeVideos": 1, "shortVideos": shortTarget], "status": "native_verified",
      "createdAt": ISO8601DateFormatter().string(from: Date()),
      "limitations": "Synthetic local JPEG/H264 Photos assets; no iCloud, Live Photo or edited-resource acceptance."]
    try FileManager.default.createDirectory(at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: manifestURL, options: .atomic)
    let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: manifest), uniformTypeIdentifier: "public.json")
    attachment.name = "cleanup-real-photos-\(target)-manifest"; attachment.lifetime = .keepAlways; add(attachment)
    print("REAL_PHOTOS_SEED_VERIFIED stage=\(target) photos=\(photoIds.count) assets=\(actual.count) manifest=\(manifestURL.path)")
  }

  func testSeed1000RealPhotoLibrary() throws { try seed(photoCount: 1000) }
  func testSeed10000RealPhotoLibrary() throws { try seed(photoCount: 10000) }
}

private final class ControlledOriginalVideoIO: NativeOriginalVideoIO {
  private let lock = NSLock()
  var onRequest: (() -> Void)?
  var onCancel: (() -> Void)?
  var requestBarrier: DispatchSemaphore?
  private var completed: ((AVAsset?, [AnyHashable: Any]?) -> Void)?
  func request(_ asset: PHAsset, options: PHVideoRequestOptions,
    completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
    XCTAssertEqual(options.version, .original, "An edited render cannot stand in for the original file.")
    XCTAssertFalse(options.isNetworkAccessAllowed, "Size lookup must never download an iCloud video.")
    lock.lock(); completed = completion; lock.unlock()
    onRequest?(); requestBarrier?.wait()
    return 43
  }
  func cancel(_ identifier: PHImageRequestID) { XCTAssertEqual(identifier, 43); onCancel?() }
  func settle(_ video: AVAsset?, info: [AnyHashable: Any]? = nil) {
    lock.lock(); let callback = completed; lock.unlock(); callback?(video, info)
  }
}

final class RunnerTests: XCTestCase {
  private static var fixtureIdentifier: String?
  private static var preparedFixtureIdentifier: String?
  private static var authorizationRequested = false
  private static var videoFixtureIdentifier: String?

  override func setUpWithError() throws {
    continueAfterFailure = false
    try requireNativeFixtureModeMarker()
  }

  private func temporaryFile(bytes: UInt64) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("cleanup_native_\(UUID().uuidString)")
    guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
      throw NSError(domain: "CleanupNativeTests", code: 4)
    }
    let handle = try FileHandle(forWritingTo: url)
    do { try handle.truncate(atOffset: bytes); try handle.close() }
    catch { try? handle.close(); try? FileManager.default.removeItem(at: url); throw error }
    return url
  }

  private func simulatorVideo() throws -> String {
    #if targetEnvironment(simulator)
    // Reuse the existing isolated-simulator authorization setup.
    _ = try simulatorPhoto()
    if let existing = Self.videoFixtureIdentifier { return existing }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("cleanup_video_\(UUID().uuidString).mov")
    defer { try? FileManager.default.removeItem(at: url) }
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 16, AVVideoHeightKey: 16])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
      sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: 16, kCVPixelBufferHeightKey as String: 16])
    XCTAssertTrue(writer.canAdd(input)); writer.add(input)
    XCTAssertTrue(writer.startWriting()); writer.startSession(atSourceTime: .zero)
    var buffer: CVPixelBuffer?
    XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 16, 16, kCVPixelFormatType_32ARGB,
      nil, &buffer), kCVReturnSuccess)
    let frame = try XCTUnwrap(buffer)
    CVPixelBufferLockBaseAddress(frame, [])
    if let base = CVPixelBufferGetBaseAddress(frame) {
      memset(base, 0, CVPixelBufferGetBytesPerRow(frame) * CVPixelBufferGetHeight(frame))
    }
    CVPixelBufferUnlockBaseAddress(frame, [])
    let written = expectation(description: "Write a disposable simulator video")
    var appended = false
    input.requestMediaDataWhenReady(on: DispatchQueue(label: "cleanup.test-video")) {
      guard !appended, input.isReadyForMoreMediaData else { return }
      appended = true
      XCTAssertTrue(adaptor.append(frame, withPresentationTime: .zero))
      input.markAsFinished(); writer.endSession(atSourceTime: CMTime(value: 1, timescale: 1))
      writer.finishWriting { written.fulfill() }
    }
    wait(for: [written], timeout: 10)
    XCTAssertEqual(writer.status, .completed, "\(String(describing: writer.error))")
    let saved = expectation(description: "Import the simulator-only video")
    let lock = NSLock(); var identifier: String?; var saveError: Error?
    PHPhotoLibrary.shared().performChanges({
      let creation = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      lock.lock(); identifier = creation?.placeholderForCreatedAsset?.localIdentifier; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); saveError = success ? nil : error ?? NSError(domain: "CleanupNativeTests", code: 5); lock.unlock()
      saved.fulfill()
    })
    wait(for: [saved], timeout: 10)
    lock.lock(); let result = identifier; let error = saveError; lock.unlock()
    if let error = error { throw error }
    let value = try XCTUnwrap(result)
    let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [value], options: nil).firstObject)
    let types = PHAssetResource.assetResources(for: asset).map { $0.type }
    XCTAssertEqual(asset.mediaType, .video); XCTAssertEqual(types, [.video])
    Self.videoFixtureIdentifier = value
    return value
    #else
    throw XCTSkip("Photos fixtures are restricted to an isolated simulator.")
    #endif
  }

  private func prepareSimulatorPhotoMetadata(_ identifier: String) throws -> String {
    if Self.preparedFixtureIdentifier == identifier { return identifier }
    // Fixture creation can finish before PhotoKit has loaded original metadata.
    // Keep that cold setup outside the reader/cancellation assertion budgets.
    // Production still fetches its own asset/resources and retains its deadline.
    XCTAssertTrue(Thread.isMainThread, "Prepare the disposable Photos fixture on the main test thread.")
    let began = ProcessInfo.processInfo.systemUptime
    let asset = try XCTUnwrap(PHAsset.fetchAssets(
      withLocalIdentifiers: [identifier], options: nil).firstObject)
    let fetched = ProcessInfo.processInfo.systemUptime
    let resources = PHAssetResource.assetResources(for: asset)
    let enumerated = ProcessInfo.processInfo.systemUptime
    print("Simulator Photos fixture metadata ready: fetch=\(fetched - began)s, resources=\(enumerated - fetched)s, count=\(resources.count)")
    guard !resources.isEmpty,
      resources.contains(where: { $0.type == .photo }), asset.mediaType == .image else {
      XCTFail("The real simulator fixture must expose an original photo resource before reader tests start.")
      throw NSError(domain: "CleanupNativeTests", code: 3)
    }
    Self.preparedFixtureIdentifier = identifier
    return identifier
  }

  private func simulatorPhoto() throws -> String {
    #if targetEnvironment(simulator)
    var status: PHAuthorizationStatus
    if #available(iOS 14, *) { status = PHPhotoLibrary.authorizationStatus(for: .readWrite) }
    else { status = PHPhotoLibrary.authorizationStatus() }
    var legacyStatus = PHPhotoLibrary.authorizationStatus()
    print("Simulator Photos fixture access: modern=\(status.rawValue), legacy=\(legacyStatus.rawValue)")
    if status == .notDetermined && !Self.authorizationRequested {
      Self.authorizationRequested = true
      let device = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
      print("Simulator Photos request context: main=\(Thread.isMainThread), device=\(device), pid=\(ProcessInfo.processInfo.processIdentifier), host=\(Bundle.main.bundlePath)")
      DispatchQueue.main.async {
        print("Simulator Photos main-queue app state: \(UIApplication.shared.applicationState.rawValue)")
      }
      let authorized = expectation(description: "Resolve simulator read/write Photos authorization")
      let handler: (PHAuthorizationStatus) -> Void = { resolved in
        print("Simulator Photos read/write request resolved: \(resolved.rawValue)")
        authorized.fulfill()
      }
      if #available(iOS 14, *) { PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler) }
      else { PHPhotoLibrary.requestAuthorization(handler) }
      wait(for: [authorized], timeout: 10)
      if #available(iOS 14, *) { status = PHPhotoLibrary.authorizationStatus(for: .readWrite) }
      else { status = PHPhotoLibrary.authorizationStatus() }
      legacyStatus = PHPhotoLibrary.authorizationStatus()
    }
    // Deliberately fail, rather than silently skip CI's Photos integration.
    guard status == .authorized else {
      let host = Bundle.main.bundleIdentifier ?? "unknown"
      let testBundle = Bundle(for: RunnerTests.self).bundleIdentifier ?? "unknown"
      let addStatus: Int
      if #available(iOS 14, *) { addStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly).rawValue }
      else { addStatus = status.rawValue }
      XCTFail("Simulator Photos readWrite=\(status.rawValue), legacy=\(legacyStatus.rawValue), addOnly=\(addStatus), host=\(host), tests=\(testBundle). Grant access after installing the final test host.")
      throw NSError(domain: "CleanupNativeTests", code: 1)
    }
    if let existing = Self.fixtureIdentifier { return try prepareSimulatorPhotoMetadata(existing) }
    let image = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 240)).image { context in
      UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 320, height: 240))
      UIColor.yellow.setFill(); context.fill(CGRect(x: 15, y: 20, width: 120, height: 90))
      UIColor.red.setFill(); context.fill(CGRect(x: 175, y: 130, width: 110, height: 80))
    }
    let saved = expectation(description: "Create a simulator-only Photos fixture")
    let lock = NSLock()
    var identifier: String?
    var saveError: Error?
    PHPhotoLibrary.shared().performChanges({
      let creation = PHAssetChangeRequest.creationRequestForAsset(from: image)
      lock.lock(); identifier = creation.placeholderForCreatedAsset?.localIdentifier; lock.unlock()
    }, completionHandler: { success, error in
      lock.lock(); saveError = success ? nil : error ?? NSError(domain: "CleanupNativeTests", code: 2); lock.unlock()
      saved.fulfill()
    })
    wait(for: [saved], timeout: 10)
    lock.lock(); let result = identifier; let error = saveError; lock.unlock()
    if let error = error { throw error }
    let value = try XCTUnwrap(result)
    Self.fixtureIdentifier = value
    // The isolated CI simulator is disposable. Avoid a Photos delete prompt
    // and never risk deleting any device/user media during these tests.
    return try prepareSimulatorPhotoMetadata(value)
    #else
    throw XCTSkip("Photos fixtures are restricted to an isolated simulator.")
    #endif
  }

  func testStreamSHAAndByteBudgetRejectsIncompleteHash() {
    let stream = NativeResourceAccumulator(maximumBytes: 3, includeHash: true)
    XCTAssertTrue(stream.append(Data("a".utf8)))
    XCTAssertTrue(stream.append(Data("bc".utf8)))
    XCTAssertEqual(stream.snapshot().bytes, 3)
    XCTAssertEqual(stream.snapshot().digest,
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    XCTAssertFalse(stream.append(Data([4])))
    XCTAssertEqual(stream.snapshot().bytes, 3)
    XCTAssertNil(stream.snapshot().digest, "An over-budget prefix is never a verified original hash.")
  }

  func testOriginalVideoFileSizeRequiresExactlyOneVideoResourceAndNoHash() {
    XCTAssertTrue(PhotoResourceInspection.canReadOriginalVideoFileSize(
      mediaType: .video, resourceTypes: [.video], includeHash: false))
    let unsupportedResources: [[PHAssetResourceType]] = [[], [.photo], [.video, .audio], [.video, .video],
      [.video, .adjustmentData, .fullSizeVideo], [.photo, .pairedVideo]]
    for types in unsupportedResources {
      XCTAssertFalse(PhotoResourceInspection.canReadOriginalVideoFileSize(
        mediaType: .video, resourceTypes: types, includeHash: false))
    }
    XCTAssertFalse(PhotoResourceInspection.canReadOriginalVideoFileSize(
      mediaType: .image, resourceTypes: [.video], includeHash: false))
    XCTAssertFalse(PhotoResourceInspection.canReadOriginalVideoFileSize(
      mediaType: .video, resourceTypes: [.video], includeHash: true))
  }

  func testLocalVideoFileSizeExceedsStreamBudgetWithoutIntegerTruncation() throws {
    // A sparse file exercises a real stat without allocating or reading GiBs.
    let bytes: UInt64 = 3 * 1024 * 1024 * 1024 + 17
    let url = try temporaryFile(bytes: bytes)
    defer { try? FileManager.default.removeItem(at: url) }
    XCTAssertEqual(PhotoResourceInspection.localRegularFileSize(at: url), Int64(bytes))
  }

  func testLocalVideoFileSizeRejectsMissingEmptyDirectoryAndRemoteURLs() throws {
    let empty = try temporaryFile(bytes: 0)
    defer { try? FileManager.default.removeItem(at: empty) }
    XCTAssertNil(PhotoResourceInspection.localRegularFileSize(at: empty))
    XCTAssertNil(PhotoResourceInspection.localRegularFileSize(at:
      empty.appendingPathExtension("missing")))
    XCTAssertNil(PhotoResourceInspection.localRegularFileSize(at: FileManager.default.temporaryDirectory))
    XCTAssertNil(PhotoResourceInspection.localRegularFileSize(at:
      try XCTUnwrap(URL(string: "https://example.invalid/movie.mov"))))
    XCTAssertNil(PhotoResourceInspection.localRegularFileSize(at:
      try XCTUnwrap(URL(string: "file://remote.invalid/movie.mov"))))
  }

  func testOriginalVideoSizeAboveByteBudgetDoesNotStreamOrVerifyHash() throws {
    let identifier = try simulatorVideo()
    let bytes: UInt64 = 80 * 1024 * 1024 + 1
    let url = try temporaryFile(bytes: bytes)
    defer { try? FileManager.default.removeItem(at: url) }
    let video = ControlledOriginalVideoIO(); let stream = ControlledResourceIO()
    let started = expectation(description: "Request the original local video")
    let replied = expectation(description: "Stat returns a complete size")
    video.onRequest = { started.fulfill() }
    stream.onRequest = { XCTFail("A usable single-resource file must not be streamed.") }
    var response: [String: Any]?
    let job = PhotoResourceInspection(assetId: identifier, includeHash: false,
      includeThumbnail: false, timeoutSeconds: 2, maximumBytes: 1, io: stream, videoIO: video) {
      response = $0; replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2)
    video.settle(AVURLAsset(url: url))
    wait(for: [replied], timeout: 2)
    XCTAssertEqual((response?["size"] as? NSNumber)?.int64Value, Int64(bytes))
    XCTAssertEqual(response?["sizeKnown"] as? Bool, true)
    XCTAssertEqual(response?["sizeComplete"] as? Bool, true)
    XCTAssertEqual(response?["complete"] as? Bool, true)
    XCTAssertEqual(response?["hashComplete"] as? Bool, false)
    XCTAssertNil(response?["hash"])
  }

  func testOriginalVideoCompositionFallsBackToBoundedResourceStream() throws {
    let identifier = try simulatorVideo()
    let video = ControlledOriginalVideoIO(); let stream = ControlledResourceIO()
    let started = expectation(description: "Original video request starts")
    let fallback = expectation(description: "Composition uses bounded resource read")
    let replied = expectation(description: "Fallback returns its complete byte count")
    video.onRequest = { started.fulfill() }; stream.onRequest = { fallback.fulfill() }
    var response: [String: Any]?
    let job = PhotoResourceInspection(assetId: identifier, includeHash: false,
      includeThumbnail: false, timeoutSeconds: 2, maximumBytes: 6, io: stream, videoIO: video) {
      response = $0; replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2)
    video.settle(AVMutableComposition())
    wait(for: [fallback], timeout: 2)
    stream.send(Data("abc".utf8)); stream.settle()
    wait(for: [replied], timeout: 2)
    XCTAssertEqual((response?["size"] as? NSNumber)?.int64Value, 3)
    XCTAssertEqual(response?["sizeComplete"] as? Bool, true)
    XCTAssertEqual(response?["hashComplete"] as? Bool, false)
    XCTAssertNil(response?["hash"])
  }

  func testOriginalVideoDeadlineCancelsRequestAndIgnoresLateSize() throws {
    let identifier = try simulatorVideo()
    let url = try temporaryFile(bytes: 80 * 1024 * 1024)
    defer { try? FileManager.default.removeItem(at: url) }
    let video = ControlledOriginalVideoIO(); let stream = ControlledResourceIO()
    let started = expectation(description: "Original video request starts")
    let replied = expectation(description: "Original-video deadline returns")
    let cancelled = expectation(description: "Deadline cancels the Photos image request")
    video.onRequest = { started.fulfill() }
    video.onCancel = { video.settle(AVURLAsset(url: url)); cancelled.fulfill() }
    stream.onRequest = { XCTFail("A cancelled late callback must not start resource reads.") }
    var calls = 0
    let job = PhotoResourceInspection(assetId: identifier, includeHash: false,
      includeThumbnail: false, timeoutSeconds: 1, io: stream, videoIO: video) { result in
      calls += 1
      XCTAssertEqual(result["pendingReason"] as? String, "resource_time_budget")
      XCTAssertEqual(result["sizeComplete"] as? Bool, false)
      XCTAssertEqual(result["hashComplete"] as? Bool, false)
      XCTAssertNil(result["hash"]); replied.fulfill()
    }
    job.start(); wait(for: [started, replied, cancelled], timeout: 3)
    XCTAssertEqual(calls, 1)
  }

  func testOriginalVideoCancellationRepliesBeforeLateRequestIdentifier() throws {
    let identifier = try simulatorVideo()
    let url = try temporaryFile(bytes: 80 * 1024 * 1024)
    defer { try? FileManager.default.removeItem(at: url) }
    let video = ControlledOriginalVideoIO(); let stream = ControlledResourceIO()
    let started = expectation(description: "Original video request is blocked")
    let replied = expectation(description: "Cancel replies without waiting for the request identifier")
    let cancelled = expectation(description: "Late Photos image request identifier is cancelled")
    let barrier = DispatchSemaphore(value: 0); video.requestBarrier = barrier
    defer { barrier.signal() }
    video.onRequest = { started.fulfill() }
    video.onCancel = { video.settle(AVURLAsset(url: url)); cancelled.fulfill() }
    stream.onRequest = { XCTFail("Cancel must prevent a fallback resource read.") }
    var calls = 0
    let job = PhotoResourceInspection(assetId: identifier, includeHash: false,
      includeThumbnail: false, timeoutSeconds: 3, io: stream, videoIO: video) { result in
      calls += 1
      XCTAssertEqual(result["pendingReason"] as? String, "cancelled")
      XCTAssertEqual(result["sizeKnown"] as? Bool, false)
      XCTAssertNil(result["hash"]); replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2); job.cancel()
    wait(for: [replied], timeout: 1)
    barrier.signal(); wait(for: [cancelled], timeout: 2)
    XCTAssertEqual(calls, 1)
  }

  func testRealPhotosOriginalVideoSizeUsesLocalFileWithoutStreaming() throws {
    let identifier = try simulatorVideo()
    let stream = ControlledResourceIO()
    stream.onRequest = { XCTFail("The real simulator video should expose a local original URL.") }
    let replied = expectation(description: "Read the real original video file size")
    var response: [String: Any]?
    let job = PhotoResourceInspection(assetId: identifier, includeHash: false,
      includeThumbnail: false, timeoutSeconds: 8, maximumBytes: 1, io: stream) {
      response = $0; replied.fulfill()
    }
    job.start(); wait(for: [replied], timeout: 10)
    XCTAssertEqual(response?["sizeKnown"] as? Bool, true, "\(String(describing: response))")
    XCTAssertEqual(response?["sizeComplete"] as? Bool, true)
    XCTAssertEqual(response?["complete"] as? Bool, true)
    XCTAssertGreaterThan((response?["size"] as? NSNumber)?.int64Value ?? 0, 1)
    XCTAssertEqual(response?["hashComplete"] as? Bool, false)
    XCTAssertNil(response?["hash"])
  }

  func testDeadlineRepliesWithoutWaitingForBlockingCancellation() {
    let replied = expectation(description: "Deadline replies on main")
    let cancelling = expectation(description: "Native cancellation is independently running")
    let barrier = DispatchSemaphore(value: 0)
    var calls = 0
    let gate = NativeInspectionCompletion { result in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertEqual(result["pendingReason"] as? String, "resource_time_budget")
      calls += 1; replied.fulfill()
    }
    gate.track("fake-manager") { cancelling.fulfill(); barrier.wait() }
    gate.armDeadline(seconds: 0.03) { ["pendingReason": "resource_time_budget"] }
    wait(for: [replied, cancelling], timeout: 2)
    XCTAssertEqual(calls, 1)
    XCTAssertFalse(gate.finish(["late": true]))
    barrier.signal()
  }

  func testFinishIsExactlyOnceUnderConcurrentTimeoutAndCancel() {
    let replied = expectation(description: "Only one Flutter result")
    replied.assertForOverFulfill = true
    var calls = 0
    let gate = NativeInspectionCompletion { _ in calls += 1; replied.fulfill() }
    let work = DispatchGroup()
    for index in 0..<100 {
      work.enter()
      DispatchQueue.global().async { gate.finish(["winner": index]); work.leave() }
    }
    XCTAssertEqual(work.wait(timeout: .now() + 2), .success)
    wait(for: [replied], timeout: 2)
    XCTAssertEqual(calls, 1)
    XCTAssertTrue(gate.isFinished)
  }

  func testLateRequestIdentifierIsCancelledAfterImmediateFinish() {
    let replied = expectation(description: "Cancel replies immediately")
    let cancelled = expectation(description: "Late request registration is cancelled")
    let gate = NativeInspectionCompletion { _ in replied.fulfill() }
    XCTAssertTrue(gate.finish(["pendingReason": "cancelled"]))
    gate.track("late-manager-id") { cancelled.fulfill() }
    wait(for: [replied, cancelled], timeout: 2)
  }

  func testPreviewBatchChannelContractAcceptsThirtyTwoDistinctIds() {
    let ids = (0..<32).map { "photo-\($0)" }
    XCTAssertEqual(PhotoPreviewBatch.maximumAssetCount, 32)
    XCTAssertEqual(PhotoPreviewBatch.maximumConcurrentRequests, 16)
    XCTAssertEqual(PhotoPreviewBatch.batchTimeoutSeconds(for: 8), 2)
    XCTAssertEqual(PhotoPreviewBatch.batchTimeoutSeconds(for: 32), 6)
    XCTAssertGreaterThan(PhotoPreviewBatch.batchTimeoutSeconds(for: 32),
      2 * PhotoPreviewBatch.itemTimeoutSeconds(for: 32))
    XCTAssertTrue(PhotoPreviewBatch.accepts(ids))
    XCTAssertFalse(PhotoPreviewBatch.accepts([]))
    XCTAssertFalse(PhotoPreviewBatch.accepts(ids + ["photo-32"]))
    XCTAssertFalse(PhotoPreviewBatch.accepts(ids + ["photo-0"]))
  }

  func testWidePreviewBatchReturnsEveryRowWithoutOriginalReads() throws {
    let ids = (0..<32).map { "missing-photo-\($0)/L0/001" }
    let replied = expectation(description: "All bounded preview rows return")
    var response: [String: Any]?
    let batch = PhotoPreviewBatch(assetIds: ids) { response = $0; replied.fulfill() }
    batch.start()
    wait(for: [replied], timeout: 7)
    let result = try XCTUnwrap(response)
    let rows = try XCTUnwrap(result["assets"] as? [[String: Any]])
    XCTAssertEqual(rows.count, 32)
    XCTAssertEqual(rows.compactMap { $0["assetId"] as? String }, ids)
    // On a busy Photos simulator the bounded batch may expire before all
    // missing identifiers are fetched. Neither state may claim local media.
    let pendingStatuses: Set<String> = ["unavailable", "timeout", "not_started"]
    XCTAssertTrue(rows.allSatisfy { pendingStatuses.contains($0["status"] as? String ?? "") })
    XCTAssertNil(result["hash"])
    XCTAssertEqual(result["sizeKnown"] as? Bool, false)
  }

  func testRealPhotosCachedPreviewIsIndependentAndNeverVerifiedDuplicate() throws {
    let identifier = try simulatorPhoto()
    let replied = expectation(description: "Real Photos preview batch")
    var response: [String: Any]?
    let batch = PhotoPreviewBatch(assetIds: [identifier]) { response = $0; replied.fulfill() }
    batch.start()
    wait(for: [replied], timeout: 4)
    let result = try XCTUnwrap(response)
    XCTAssertEqual(result["complete"] as? Bool, false)
    XCTAssertEqual(result["sizeKnown"] as? Bool, false)
    XCTAssertNil(result["hash"])
    let rows = try XCTUnwrap(result["assets"] as? [[String: Any]])
    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows[0]["status"] as? String, "local")
    let bytes = try XCTUnwrap(rows[0]["thumbnail"] as? FlutterStandardTypedData)
    let decoded = try XCTUnwrap(UIImage(data: bytes.data))
    XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 256)
    XCTAssertNil(rows[0]["hash"])
    XCTAssertNotNil(rows[0]["thumbnailDegraded"] as? Bool)
  }

  func testRealPhotosAllResourceSHAAndSizeComplete() throws {
    let identifier = try simulatorPhoto()
    let replied = expectation(description: "Read real Photos original resources")
    var response: [String: Any]?
    let job = PhotoResourceInspection(assetId: identifier, includeHash: true,
      includeThumbnail: false, timeoutSeconds: 8) { response = $0; replied.fulfill() }
    job.start()
    wait(for: [replied], timeout: 10)
    let result = try XCTUnwrap(response)
    XCTAssertEqual(result["complete"] as? Bool, true, "\(result)")
    XCTAssertEqual(result["sizeKnown"] as? Bool, true)
    XCTAssertEqual(result["sizeComplete"] as? Bool, true)
    XCTAssertEqual(result["hashComplete"] as? Bool, true)
    XCTAssertGreaterThan((result["size"] as? NSNumber)?.int64Value ?? 0, 0)
    XCTAssertEqual((result["hash"] as? String)?.count, 64)
    XCTAssertNil(result["thumbnail"])
  }

  func testStalledOriginalDoesNotBlockRealPhotosPreview() throws {
    let identifier = try simulatorPhoto()
    // simulatorPhoto prepares real metadata before any reader assertion budget.
    let io = ControlledResourceIO()
    let started = expectation(description: "Injected native original read starts")
    let originalReply = expectation(description: "Original reaches independent time budget")
    let previewReply = expectation(description: "Preview does not await the original stream")
    io.onRequest = { started.fulfill() }
    var originalResponse: [String: Any]?
    var originalCompleted = false
    let original = PhotoResourceInspection(assetId: identifier, includeHash: true,
      includeThumbnail: false, timeoutSeconds: 3, io: io) {
      originalResponse = $0; originalCompleted = true; originalReply.fulfill()
    }
    original.start()
    wait(for: [started], timeout: 3)
    let preview = PhotoPreviewBatch(assetIds: [identifier]) { result in
      let rows = result["assets"] as? [[String: Any]]
      XCTAssertEqual(rows?.first?["status"] as? String, "local")
      XCTAssertFalse(originalCompleted, "Cached preview must finish before the stalled original reader.")
      previewReply.fulfill()
    }
    preview.start()
    wait(for: [originalReply, previewReply], timeout: 5)
    XCTAssertEqual(originalResponse?["pendingReason"] as? String, "resource_time_budget")
    XCTAssertNil(originalResponse?["hash"])
    XCTAssertEqual(originalResponse?["sizeKnown"] as? Bool, false)
  }

  func testOriginalCancellationReturnsBeforeBlockedRequestAndLateID() throws {
    let identifier = try simulatorPhoto()
    let io = ControlledResourceIO()
    let started = expectation(description: "Native request call is blocked")
    let replied = expectation(description: "Cancel still returns a result")
    let cancelled = expectation(description: "Returned native request ID is cancelled")
    let barrier = DispatchSemaphore(value: 0)
    io.requestBarrier = barrier
    io.onRequest = { started.fulfill() }
    io.onCancel = { cancelled.fulfill() }
    var responses = 0
    let job = PhotoResourceInspection(assetId: identifier, includeHash: true,
      includeThumbnail: false, timeoutSeconds: 2, io: io) { result in
      responses += 1
      XCTAssertEqual(result["pendingReason"] as? String, "cancelled")
      XCTAssertNil(result["hash"]); replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2)
    job.cancel()
    wait(for: [replied], timeout: 1)
    barrier.signal()
    wait(for: [cancelled], timeout: 2)
    io.send(Data("late".utf8)); io.settle()
    XCTAssertEqual(responses, 1)
  }

  func testContinuousOriginalChunksStopAtByteBudgetWithoutHash() throws {
    let identifier = try simulatorPhoto()
    let io = ControlledResourceIO()
    let started = expectation(description: "Native streaming starts")
    let replied = expectation(description: "Byte budget stops a flowing resource")
    let cancelled = expectation(description: "Over-budget native request is cancelled")
    io.onRequest = { started.fulfill() }
    io.onCancel = { cancelled.fulfill() }
    var response: [String: Any]?
    let job = PhotoResourceInspection(assetId: identifier, includeHash: true,
      includeThumbnail: false, timeoutSeconds: 2, maximumBytes: 6, io: io) {
      response = $0; replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2)
    io.send(Data("abc".utf8)); io.send(Data("def".utf8)); io.send(Data("ghi".utf8))
    wait(for: [replied, cancelled], timeout: 2)
    XCTAssertEqual(response?["pendingReason"] as? String, "byte_budget_exceeded")
    XCTAssertEqual((response?["partialBytes"] as? NSNumber)?.int64Value, 6)
    XCTAssertEqual(response?["complete"] as? Bool, false)
    XCTAssertEqual(response?["sizeKnown"] as? Bool, false)
    XCTAssertEqual(response?["sizeComplete"] as? Bool, false)
    XCTAssertEqual(response?["hashComplete"] as? Bool, false)
    XCTAssertNil(response?["hash"])
    io.settle()
  }

  func testCancellationCanWaitForCallbackWithoutDeadlockingFlutterResult() throws {
    let identifier = try simulatorPhoto()
    let io = ControlledResourceIO()
    let started = expectation(description: "Native stream starts")
    let replied = expectation(description: "Flutter result is independent of native cancel wait")
    let cancelling = expectation(description: "Native cancel is waiting for callback")
    let barrier = DispatchSemaphore(value: 0)
    io.cancelBarrier = barrier
    io.onRequest = { started.fulfill() }
    io.onCancel = { io.send(Data("callback-during-cancel".utf8)); io.settle(); cancelling.fulfill() }
    let job = PhotoResourceInspection(assetId: identifier, includeHash: true,
      includeThumbnail: false, timeoutSeconds: 2, io: io) { result in
      XCTAssertEqual(result["pendingReason"] as? String, "cancelled"); replied.fulfill()
    }
    job.start(); wait(for: [started], timeout: 2)
    job.cancel()
    wait(for: [replied, cancelling], timeout: 2)
    barrier.signal()
  }
}
