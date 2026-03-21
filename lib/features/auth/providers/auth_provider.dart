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
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage ?? this.errorMessage,
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
    if (token != null) {
      _apiClient.setAuthToken(token);
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
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
        state = state.copyWith(status: AuthStatus.authenticated);
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

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _apiClient.clearAuthToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
