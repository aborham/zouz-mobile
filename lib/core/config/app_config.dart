import 'package:flutter/foundation.dart';
import 'secrets.dart';

class AppConfig {
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

  // Automatically switches based on whether the app is running in debug or release mode
  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _localBaseUrl;
  static String get websiteUrl => kReleaseMode ? _prodWebsiteUrl : _localWebsiteUrl;

  static String get apiBaseUrl => '$baseUrl/api';
  static String get customerApiBaseUrl => '$apiBaseUrl/customer';

  static const String crispWebsiteId = '1da3bb6b-9c97-4f51-8c65-41c4886a170b';

  // ── Apple Pay ──────────────────────────────────────────────────────────────
  // Apple Pay merchant identifiers (must match Xcode capability + Apple Developer portal)
  static const String _sandboxApplePayMerchantId    = 'merchant.zouz.tap.sandbox';
  static const String _productionApplePayMerchantId = 'merchant.zouz.tap.production';

  static String get applePayMerchantId =>
      kReleaseMode ? _productionApplePayMerchantId : _sandboxApplePayMerchantId;

  // Tap publishable keys (pk_test_ / pk_live_) — stored in git-ignored secrets.dart
  static String get tapPublishableSandboxKey    => AppSecrets.tapSandboxPublishableKey;
  static String get tapPublishableProductionKey => AppSecrets.tapProductionPublishableKey;

  // Active key based on build mode
  static String get tapPublishableKey =>
      kReleaseMode ? tapPublishableProductionKey : tapPublishableSandboxKey;

  static const String tapBundleIdIOS     = 'com.zouz.mobile';
  static const String tapBundleIdAndroid = 'com.zouz.mobile';
}
