import 'package:dio/dio.dart';
import '../models/profile_model.dart';

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
}
