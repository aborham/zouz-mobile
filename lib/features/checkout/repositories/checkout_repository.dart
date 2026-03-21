import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  Future<Map<String, dynamic>> createOrder(
    String packageId,
    int quantity,
    String? standId,
  ) async {
    try {
      final response = await _dio.post(
        '/customer/orders/create',
        data: {
          'items': [
            {'packageId': packageId, 'quantity': quantity, 'standId': standId},
          ],
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create order');
    }
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider).dio);
});
