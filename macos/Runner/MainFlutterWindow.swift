import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMethodChannel(name: "mango_balance/notification_settings",
                         binaryMessenger: flutterViewController.engine.binaryMessenger)
      .setMethodCallHandler { call, result in
        guard call.method == "openNotificationSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else {
          result(false)
          return
        }
        result(NSWorkspace.shared.open(url))
      }

    super.awakeFromNib()
  }
}
