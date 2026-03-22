import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/auth_repository.dart';
import '../../../core/api/api_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  otpSent,
  needsProfile,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? userId;
  final String? errorMessage;
  final bool onboardingCompleted;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.userId,
    this.errorMessage,
    this.onboardingCompleted = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? userId,
    String? errorMessage,
    bool? onboardingCompleted,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  late FlutterSecureStorage _storage;
  late ApiClient _apiClient;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);
    _apiClient = ref.watch(apiClientProvider);

    _checkInitialAuth();
    return AuthState();
  }

  Future<void> _checkInitialAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    final onboarding = await _storage.read(key: 'onboarding_completed');
    
    final isOnboardingDone = onboarding == 'true';
    
    if (token != null) {
      _apiClient.setAuthToken(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        onboardingCompleted: isOnboardingDone,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        onboardingCompleted: isOnboardingDone,
      );
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: 'onboarding_completed', value: 'true');
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> requestOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.requestOtp(phoneNumber);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    if (state.phoneNumber == null) return;

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.verifyOtp(state.phoneNumber!, code);
      final token = response['token'];

      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        _apiClient.setAuthToken(token);
        
        final needsProfile = response['needsProfile'] == true;
        final userId = response['customer']['id'];

        if (needsProfile) {
          state = state.copyWith(
            status: AuthStatus.needsProfile,
            userId: userId,
          );
        } else {
          state = state.copyWith(status: AuthStatus.authenticated);
        }
      } else {
        throw Exception('Token not found in response');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String?> uploadAvatar(File file) async {
    try {
      return await _repository.uploadAvatar(file);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> completeProfile({
    required String name,
    required String email,
    String? dateOfBirth,
    String? avatarUrl,
  }) async {
    if (state.userId == null) return;
    
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.completeProfile(
        userId: state.userId!,
        name: name,
        email: email,
        dateOfBirth: dateOfBirth,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _apiClient.clearAuthToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
