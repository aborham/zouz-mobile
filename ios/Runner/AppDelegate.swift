import Flutter
import PassKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let applePayDiagnostics = FlutterMethodChannel(
      name: "zouz/apple_pay_diagnostics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    applePayDiagnostics.setMethodCallHandler { call, result in
      guard call.method == "check" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let merchantIdentifier = Bundle.main.object(
        forInfoDictionaryKey: "ApplePayMerchantIdentifier"
      ) as? String
      let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .mada]

      result([
        "canMakePayments": PKPaymentAuthorizationController.canMakePayments(),
        "canMakePaymentsWithNetworks": PKPaymentAuthorizationController.canMakePayments(
          usingNetworks: supportedNetworks
        ),
        "configuredMerchantIdentifier": merchantIdentifier ?? "",
      ])
    }
  }
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // If we receive a notification while in the foreground, show the banner natively.
    // This overrides CrispPlugin's default behavior of swallowing non-Crisp notifications.
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}
