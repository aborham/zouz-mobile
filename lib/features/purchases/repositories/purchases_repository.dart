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

  Future<Map<String, dynamic>> fetchPurchaseDetails(String orderItemId) async {
    try {
      final response = await _dio.get('packages/$orderItemId');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to load package details'));
    }
  }

  Future<Map<String, dynamic>> createRedemptionIntent({
    required String orderItemId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post(
        'redemption-intents',
        data: {
          'orderItemId': orderItemId,
          if (items.isNotEmpty) 'items': items,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to create redemption QR'));
    }
  }

  Future<void> cancelRedemptionIntent(String intentId) async {
    try {
      await _dio.post('redemption-intents/$intentId/cancel');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to cancel redemption QR'));
    }
  }

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final apiError = data['error'];
      if (apiError is Map && apiError['message'] != null) {
        return apiError['message'].toString();
      }
      if (apiError != null) return apiError.toString();
      if (data['message'] != null) return data['message'].toString();
    }
    return fallback;
  }
}

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(ref.watch(apiClientProvider).dio);
});
