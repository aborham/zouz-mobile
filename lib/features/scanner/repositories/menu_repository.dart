import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// Since the menu endpoint is public, we can use a standard Dio instance
// or reuse the ApiClient but it hits `/api/menu` instead of `/api/customer`.
final menuDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api', // Adjust in production
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  return dio;
});

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  Future<Map<String, dynamic>> fetchMenu(
    String tenantSlug,
    String? standId,
  ) async {
    try {
      final Map<String, dynamic> queryParams = standId != null
          ? {'standId': standId}
          : <String, dynamic>{};
      final response = await _dio.get(
        '/menu/$tenantSlug',
        queryParameters: queryParams,
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load menu');
    }
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(menuDioProvider));
});
