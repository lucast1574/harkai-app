import Flutter
import UIKit
import AVFoundation
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HarkaiDevicePermissions")!
    let channel = FlutterMethodChannel(name: "harkai/device_permissions", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        result([
          "camera": AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
          "microphone": AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        ])
      case "requestCamera", "requestMicrophone":
        let media: AVMediaType = call.method == "requestCamera" ? .video : .audio
        switch AVCaptureDevice.authorizationStatus(for: media) {
        case .authorized: result(true)
        case .notDetermined:
          AVCaptureDevice.requestAccess(for: media) { allowed in
            DispatchQueue.main.async { result(allowed) }
          }
        default: result(false)
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
