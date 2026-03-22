import 'dart:io';
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

  Future<String> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _apiClient.dio.post(
        '/profile/avatar',
        data: formData,
      );

      return response.data['avatarUrl'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to upload avatar');
    }
  }

  Future<void> completeProfile({
    required String userId,
    required String name,
    required String email,
    String? dateOfBirth,
    String? avatarUrl,
  }) async {
    try {
      await _apiClient.dio.post(
        '/profile/complete',
        data: {
          'userId': userId,
          'name': name,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'avatarUrl': avatarUrl,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update profile');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
