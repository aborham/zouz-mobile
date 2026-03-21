class ImageUtils {
  // Base URL for the backend server
  // In development, localhost might not work on devices, so we use the common IP for emulators/simulators
  // For production, this should come from a config or environment variable
  static const String _serverBaseUrl = 'http://localhost:3000';

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
