class AppConfig {
  // Centralized base URL configuration
  // For production, these should be moved to --dart-define or a .env file
  static const String host = '192.168.1.8';
  static const String port = '3000';
  static const String baseUrl = 'http://$host:$port';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String customerApiBaseUrl = '$apiBaseUrl/customer';
}
