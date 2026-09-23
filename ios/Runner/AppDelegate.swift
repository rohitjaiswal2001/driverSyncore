import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Hands Dart the same key GMSServices reads from Info.plist, so it is
    // configured once, in Secrets.xcconfig.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GlobelinkConfig") {
      FlutterMethodChannel(name: "globelink/config", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          switch call.method {
          case "getMapsApiKey":
            result(Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)
          default:
            result(FlutterMethodNotImplemented)
          }
        }
    }
  }
}
