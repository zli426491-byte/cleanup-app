import XCTest

/// Bootstrap full Photos permission by making a real choice in the system UI
/// before RunnerTests exercises the simulator's actual PhotoKit resources.
final class PhotosFixtureAuthorizationTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor func testAuthorizePhotosByTappingFullAccess() {
    #if targetEnvironment(simulator)
    let app = XCUIApplication(bundleIdentifier: "com.cleanupapp.cleaner")
    app.launchArguments = ["--cleanup-native-photos-authorization-fixture"]
    app.launchEnvironment["CLEANUP_NATIVE_FIXTURE_ONLY"] = "1"
    app.launch()

    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let allowFullAccess = springboard.buttons["Allow Full Access"]
    XCTAssertTrue(allowFullAccess.waitForExistence(timeout: 45),
      "Reset simulator Photos permission before this test: the real full-access choice must appear.")
    let photoLibraryMessage = springboard.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] %@", "Photo Library")).firstMatch
    XCTAssertTrue(photoLibraryMessage.waitForExistence(timeout: 5),
      "Only a system prompt identifying the Photo Library may receive this full-access choice.")
    let hittable = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "hittable == true"), object: allowFullAccess)
    XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 5), .completed,
      "The full-access system button must be interactable.")
    allowFullAccess.tap()

    let dismissed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == false"), object: allowFullAccess)
    XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 15), .completed,
      "The full-access prompt must disappear after the actual UI choice.")
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15),
      "The app must return to the foreground after Photos authorization.")
    #else
    XCTFail("This authorization bootstrap must run on an isolated CI simulator.")
    #endif
  }
}
