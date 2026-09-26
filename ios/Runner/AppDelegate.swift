import Flutter
import UIKit
#if DEBUG && targetEnvironment(simulator)
import Photos
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  #if DEBUG && targetEnvironment(simulator)
  private var nativePhotosFixtureObserver: NSObjectProtocol?
  private var nativePhotosFixtureRequestStarted = false
  #endif

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let resourceRegistrar = registrar(forPlugin: "PhotoResourceInspector") {
      PhotoResourceInspector.register(with: resourceRegistrar)
    }
    #if DEBUG && targetEnvironment(simulator)
    if ProcessInfo.processInfo.arguments.contains("--cleanup-native-photos-authorization-fixture") {
      // The UI test must tap the real system prompt. Wait for foreground so
      // PhotoKit can present it; normal launches and physical/release builds
      // never enter this simulator-only authorization bootstrap.
      nativePhotosFixtureObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
      ) { [weak self] _ in self?.requestNativePhotosFixtureAuthorization() }
      DispatchQueue.main.async { [weak self] in self?.requestNativePhotosFixtureAuthorization() }
    }
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  #if DEBUG && targetEnvironment(simulator)
  private func requestNativePhotosFixtureAuthorization() {
    guard UIApplication.shared.applicationState == .active,
      !nativePhotosFixtureRequestStarted else { return }
    nativePhotosFixtureRequestStarted = true
    if let observer = nativePhotosFixtureObserver {
      NotificationCenter.default.removeObserver(observer)
      nativePhotosFixtureObserver = nil
    }
    guard #available(iOS 14, *) else {
      print("Native Photos authorization UI fixture requires iOS 14 or newer.")
      return
    }
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      print("Native Photos authorization UI fixture resolved readWrite=\(status.rawValue)")
    }
  }
  #endif
}
