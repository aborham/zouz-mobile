import '../config/app_config.dart';

class ImageUtils {
  // Base URL for the backend server
  static const String _serverBaseUrl = AppConfig.baseUrl;

  /// Resolves a full URL for an image.
  /// If [path] is relative (starts with /), it prepends the server base URL.
  /// If [path] is already a full URL or null, it returns it as is.
  static String? getFullUrl(String? path) {
    if (path == null) return null;

    if (path.startsWith('http')) {
      return path;
    }

    if (path.startsWith('/')) {
      return '$_serverBaseUrl$path';
    }

    return path;
  }
}
