import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';

/// A failed checkout request. [code] is the API's stable error code (the
/// screen localizes it); the API's `error` text is never shown to users.
class CheckoutApiException implements Exception {
  final String? code;
  final int? status;
  final Map<String, dynamic>? body;

  CheckoutApiException(this.code, this.status, this.body);

  factory CheckoutApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final body = data is Map ? Map<String, dynamic>.from(data) : null;
    final code = body?['code'];
    return CheckoutApiException(
      code is String ? code : null,
      e.response?.statusCode,
      body,
    );
  }

  @override
  String toString() => 'CheckoutApiException($status, $code)';
}

/// The merchant's active terms (see MERCHANT_TERMS_API.md in the platform repo).
class MerchantTerms {
  final String id;
  final int version;
  final String contentAr;
  final String contentEn;

  const MerchantTerms({
    required this.id,
    required this.version,
    required this.contentAr,
    required this.contentEn,
  });

  String contentFor(String languageCode) =>
      languageCode == 'ar' ? contentAr : contentEn;
}

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  /// Active terms for [tenantId], or null when the merchant requires none.
  Future<MerchantTerms?> fetchMerchantTerms(String tenantId) async {
    try {
      // Public endpoint, outside the customer API prefix.
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/public/merchant-terms',
        queryParameters: {'tenantId': tenantId},
      );
      final data = Map<String, dynamic>.from(response.data);
      final terms = data['terms'];
      if (data['required'] != true || terms is! Map) return null;
      return MerchantTerms(
        id: terms['id'] as String,
        version: (terms['version'] as num).toInt(),
        contentAr: (terms['contentAr'] ?? '').toString(),
        contentEn: (terms['contentEn'] ?? '').toString(),
      );
    } on DioException catch (e) {
      throw CheckoutApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createOrder(
    List<Map<String, dynamic>> items, {
    String? acceptedTermsId,
    String? locale,
  }) async {
    try {
      final normalizedItems = items.map((item) {
        final normalized = Map<String, dynamic>.from(item);
        final standId = normalized['standId'];
        if (standId == null || (standId is String && standId.trim().isEmpty)) {
          normalized.remove('standId');
        }
        return normalized;
      }).toList();

      final response = await _dio.post(
        '/orders/create',
        data: {
          'items': normalizedItems,
          if (acceptedTermsId != null) 'acceptedTermsId': acceptedTermsId,
          if (locale != null) 'locale': locale,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw CheckoutApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> confirmOrder(
    String orderId,
    String tapChargeId,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/confirm',
        data: {'orderId': orderId, 'tapChargeId': tapChargeId},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw CheckoutApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> processOrder(
    String orderId, {
    String? token,
    Map<String, dynamic>? applePayToken,
    String? paymentMethod,
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
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw CheckoutApiException.fromDio(e);
    }
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider).dio);
});
