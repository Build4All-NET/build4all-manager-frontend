import UIKit
import Flutter
import UserNotifications

// FirebaseApp.configure() is intentionally removed — Firebase is initialised from
// Dart via Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
// so that the correct project (build4all-manager) is always used regardless of
// whatever GoogleService-Info.plist is present in the bundle.

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    application.registerForRemoteNotifications()
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}