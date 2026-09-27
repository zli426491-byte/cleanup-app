import Flutter
import Photos
import UIKit
import XCTest
import AVFoundation
import CoreVideo
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
