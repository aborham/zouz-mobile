import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../../../core/api/api_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
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
  final bool isInitialized;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.userId,
    this.errorMessage,
    this.onboardingCompleted = false,
    this.isInitialized = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? userId,
    String? errorMessage,
    bool? onboardingCompleted,
    bool? isInitialized,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  late FlutterSecureStorage _storage;
  late SharedPreferences _prefs;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);
    _prefs = ref.watch(sharedPreferencesProvider);

    // Trigger async initialization but return initial state
    Future.microtask(() => _checkInitialAuth());
    return AuthState();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final isOnboardingDone = _prefs.getBool('onboarding_completed') ?? false;
      
      if (token != null) {
        ref.read(authTokenProvider.notifier).updateToken(token);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          onboardingCompleted: isOnboardingDone,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          onboardingCompleted: isOnboardingDone,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isInitialized: true,
      );
    }
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboarding_completed', true);
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
        ref.read(authTokenProvider.notifier).updateToken(token);
        
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

  void skipProfile() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _storage.delete(key: 'jwt_token');
    ref.read(authTokenProvider.notifier).updateToken(null);
    state = AuthState(status: AuthStatus.unauthenticated, isInitialized: true, onboardingCompleted: true);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
