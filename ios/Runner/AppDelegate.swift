import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "mango_balance/notification_settings",
                           binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { call, result in
          guard call.method == "openNotificationSettings" else {
            result(FlutterMethodNotImplemented)
            return
          }
          let settingsURL: String
          if #available(iOS 15.4, *) {
            settingsURL = UIApplication.openNotificationSettingsURLString
          } else {
            settingsURL = UIApplication.openSettingsURLString
          }
          guard let url = URL(string: settingsURL) else {
            result(false)
            return
          }
          UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
