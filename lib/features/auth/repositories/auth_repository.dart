import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _apiClient.dio.post(
        '/auth/request-otp',
        data: {'phoneNumber': phoneNumber},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String code, {
    String? deviceToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
          'deviceInfo': {
            'token': deviceToken ?? 'dummy_dev_token',
            'type': 'IOS', // or 'ANDROID' based on platform
          },
        },
      );

      return response.data; // Should contain success, token, customer
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Invalid OTP code');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
