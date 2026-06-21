class AppConfig {
  // Centralized base URL configuration
  // For production, these should be moved to --dart-define or a .env file
  // static const String host = '192.168.1.12';
  // static const String port = '3000';
  // static const String baseUrl = 'http://$host:$port';

  static const String baseUrl = 'https://dashboard.usezouz.com';
  static const String websiteUrl = 'https://usezouz.com';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String customerApiBaseUrl = '$apiBaseUrl/customer';
  static const String crispWebsiteId = '1da3bb6b-9c97-4f51-8c65-41c4886a170b';
}
