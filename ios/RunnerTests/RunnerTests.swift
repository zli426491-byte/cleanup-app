import Flutter
import Photos
import UIKit
import XCTest
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

final class RunnerTests: XCTestCase {
  private static var fixtureIdentifier: String?
  private static var authorizationRequested = false

  private func simulatorPhoto() throws -> String {
    #if targetEnvironment(simulator)
    var status: PHAuthorizationStatus
    if #available(iOS 14, *) { status = PHPhotoLibrary.authorizationStatus(for: .readWrite) }
    else { status = PHPhotoLibrary.authorizationStatus() }
    if status == .notDetermined && !Self.authorizationRequested {
      Self.authorizationRequested = true
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
    }
    // Deliberately fail, rather than silently skip CI's Photos integration.
    guard status == .authorized else {
      let host = Bundle.main.bundleIdentifier ?? "unknown"
      let testBundle = Bundle(for: RunnerTests.self).bundleIdentifier ?? "unknown"
      let addStatus: Int
      if #available(iOS 14, *) { addStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly).rawValue }
      else { addStatus = status.rawValue }
      XCTFail("Simulator Photos readWrite=\(status.rawValue), addOnly=\(addStatus), host=\(host), tests=\(testBundle). Grant access after installing the final test host.")
      throw NSError(domain: "CleanupNativeTests", code: 1)
    }
    if let existing = Self.fixtureIdentifier { return existing }
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
    return value
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
    XCTAssertGreaterThan((result["size"] as? NSNumber)?.int64Value ?? 0, 0)
    XCTAssertEqual((result["hash"] as? String)?.count, 64)
    XCTAssertNil(result["thumbnail"])
  }

  func testStalledOriginalDoesNotBlockRealPhotosPreview() throws {
    let identifier = try simulatorPhoto()
    // Warm metadata separately: this tests a stalled resource reader, not the
    // first Photos database fetch or simulator cold-start scheduling latency.
    let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject)
    XCTAssertFalse(PHAssetResource.assetResources(for: asset).isEmpty)
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
