import 'package:dio/dio.dart';
import '../models/profile_model.dart';
import '../models/saved_payment_method.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _dio.get('profile');
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('profile', data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProfile() async {
    try {
      await _dio.delete('profile/delete');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestEmailVerification(String email) async {
    try {
      await _dio.post('profile/email/request-verification', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmEmailVerification(String email, String code) async {
    try {
      await _dio.post('profile/email/confirm-verification', data: {
        'email': email,
        'code': code,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SavedPaymentMethod>> fetchPaymentMethods() async {
    try {
      final response = await _dio.get('payment-methods');
      return (response.data as List)
          .map((json) => SavedPaymentMethod.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyAndSaveCard(String token, bool isDefault) async {
    try {
      final response = await _dio.post('payment-methods', data: {
        'token': token,
        'isDefault': isDefault,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _dio.delete('payment-methods', queryParameters: {'id': id});
    } catch (e) {
      rethrow;
    }
  }
}
