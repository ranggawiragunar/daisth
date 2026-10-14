import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    excludeRoutineAttachmentsFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func excludeRoutineAttachmentsFromBackup() {
    do {
      let support = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      )[0]
      let attachments = support.appendingPathComponent(
        "routine_attachments",
        isDirectory: true
      )
      try FileManager.default.createDirectory(
        at: attachments,
        withIntermediateDirectories: true
      )
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      var mutableAttachments = attachments
      try mutableAttachments.setResourceValues(values)
    } catch {
      // This best-effort privacy setting must not block application startup.
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
