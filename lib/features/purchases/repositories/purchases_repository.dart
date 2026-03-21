import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PurchasesRepository {
  final Dio _dio;

  PurchasesRepository(this._dio);

  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    try {
      final response = await _dio.get('packages');
      if (response.data['packages'] != null) {
        return List<Map<String, dynamic>>.from(response.data['packages']);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load purchases');
    }
  }
}

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(ref.watch(apiClientProvider).dio);
});
