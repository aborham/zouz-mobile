import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  Future<Map<String, dynamic>> createOrder(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/create',
        data: {
          'items': items,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create order');
    }
  }

  Future<Map<String, dynamic>> confirmOrder(
    String orderId,
    String tapChargeId,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/confirm',
        data: {
          'orderId': orderId,
          'tapChargeId': tapChargeId,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to confirm order');
    }
  }

  Future<Map<String, dynamic>> processOrder(
    String orderId, {
    String? token,
    Map<String, dynamic>? applePayToken,
  }) async {
    try {
      // Payment processing can take 30-45 s when Tap's backend is charging
      // the token — use a longer receive timeout for this call only.
      final response = await _dio.post(
        '/payment/process-order',
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        data: {
          'orderId': orderId,
          if (token != null) 'token': token,
          if (applePayToken != null) 'applePayToken': applePayToken,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to process payment');
    }
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider).dio);
});
