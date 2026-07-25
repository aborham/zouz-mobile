import 'package:flutter/foundation.dart';
import 'secrets.dart';

class AppConfig {
  // Allows a debug/profile build on a physical device to exercise production:
  // flutter run --dart-define=USE_PRODUCTION=true
  static const bool _useProductionOverride =
      bool.fromEnvironment('USE_PRODUCTION', defaultValue: false);

  static bool get isProduction => kReleaseMode || _useProductionOverride;

  // Local Development Options:
  // - iOS Simulator: 'localhost'
  // - Android Emulator: '10.0.2.2'
  // - Physical Device: Your computer's local IP (e.g. '192.168.1.50')
  //static const String host = '127.0.0.1';
  static const String host = '10.0.0.178';
  static const String port = '3000';

  static const String _localBaseUrl = 'http://$host:$port';
  static const String _prodBaseUrl = 'https://dashboard.usezouz.com';

  static const String _localWebsiteUrl = 'http://$host:8080';
  static const String _prodWebsiteUrl = 'https://usezouz.com';

  // Release builds always use production. Debug/profile builds can opt in.
  static String get baseUrl => isProduction ? _prodBaseUrl : _localBaseUrl;
  static String get websiteUrl => isProduction ? _prodWebsiteUrl : _localWebsiteUrl;

  static String get apiBaseUrl => '$baseUrl/api';
  static String get customerApiBaseUrl => '$apiBaseUrl/customer';

  static const String crispWebsiteId = '1da3bb6b-9c97-4f51-8c65-41c4886a170b';

  // ── Apple Pay ──────────────────────────────────────────────────────────────
  // Apple Pay merchant identifiers (must match Xcode capability + Apple Developer portal)
  static const String _sandboxApplePayMerchantId    = 'merchant.zouz.tap.sandbox';
  static const String _productionApplePayMerchantId = 'merchant.zouz.tap.production';

  static String get applePayMerchantId =>
      isProduction ? _productionApplePayMerchantId : _sandboxApplePayMerchantId;

  // Tap publishable keys (pk_test_ / pk_live_) — stored in git-ignored secrets.dart
  static String get tapPublishableSandboxKey    => AppSecrets.tapSandboxPublishableKey;
  static String get tapPublishableProductionKey => AppSecrets.tapProductionPublishableKey;

  // Active key based on build mode
  static String get tapPublishableKey =>
      isProduction ? tapPublishableProductionKey : tapPublishableSandboxKey;

  static const String tapBundleIdIOS     = 'com.zouz.mobile';
  static const String tapBundleIdAndroid = 'com.zouz.mobile';
}
