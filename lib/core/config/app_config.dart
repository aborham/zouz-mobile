import 'package:flutter/foundation.dart';

class AppConfig {
  // Local Development Options:
  // - iOS Simulator: 'localhost'
  // - Android Emulator: '10.0.2.2'
  // - Physical Device: Your computer's local IP (e.g. '192.168.1.50')
  static const String host = '127.0.0.1';
  static const String port = '3000';
  
  static const String _localBaseUrl = 'http://$host:$port';
  static const String _prodBaseUrl = 'https://dashboard.usezouz.com';

  static const String _localWebsiteUrl = 'http://$host:$port';
  static const String _prodWebsiteUrl = 'https://usezouz.com';

  // Automatically switches based on whether the app is running in debug or release mode
  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _localBaseUrl;
  static String get websiteUrl => kReleaseMode ? _prodWebsiteUrl : _localWebsiteUrl;

  static String get apiBaseUrl => '$baseUrl/api';
  static String get customerApiBaseUrl => '$apiBaseUrl/customer';
  
  static const String crispWebsiteId = '1da3bb6b-9c97-4f51-8c65-41c4886a170b';
}
