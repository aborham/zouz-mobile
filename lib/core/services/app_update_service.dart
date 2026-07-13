import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final bool forceUpdate;
  final String updateUrl;

  AppUpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.updateUrl,
  });
}

class AppUpdateService {
  final Dio _dio;

  static AppUpdateInfo? pendingOptionalUpdate;

  AppUpdateService() : _dio = Dio();

  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final response = await _dio.get('${AppConfig.baseUrl}/api/public/app-version');
      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('AppUpdateService: Fetched data: $data');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        debugPrint('AppUpdateService: Current app version: $currentVersion');

        if (Platform.isIOS) {
          final latestVersion = data['iosLatestVersion'] as String?;
          final forceUpdate = data['iosForceUpdate'] as bool? ?? false;
          final updateUrl = data['iosUpdateUrl'] as String?;

          if (latestVersion != null && latestVersion.isNotEmpty && _isUpdateRequired(currentVersion, latestVersion)) {
            return AppUpdateInfo(
              updateAvailable: true,
              forceUpdate: forceUpdate,
              updateUrl: updateUrl ?? '',
            );
          }
        } else if (Platform.isAndroid) {
          final latestVersion = data['androidLatestVersion'] as String?;
          final forceUpdate = data['androidForceUpdate'] as bool? ?? false;
          final updateUrl = data['androidUpdateUrl'] as String?;

          if (latestVersion != null && latestVersion.isNotEmpty && _isUpdateRequired(currentVersion, latestVersion)) {
            return AppUpdateInfo(
              updateAvailable: true,
              forceUpdate: forceUpdate,
              updateUrl: updateUrl ?? '',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for app updates: $e');
    }
    return null;
  }

  bool _isUpdateRequired(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
      }
      return false;
    } catch (e) {
      debugPrint('AppUpdateService: _isUpdateRequired error: $e');
      return false;
    }
  }
}
