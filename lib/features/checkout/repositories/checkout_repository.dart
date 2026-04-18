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

  Future<Map<String, dynamic>> processOrder(String orderId) async {
    try {
      final response = await _dio.post(
        '/payment/process-order',
        data: {
          'orderId': orderId,
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
