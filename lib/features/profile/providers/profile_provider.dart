import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import '../models/profile_model.dart';
import '../models/saved_payment_method.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient.dio);
});

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  // Guard: only fetch when initialized AND authenticated
  if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
    return Completer<UserProfile>().future; // Stay in loading until auth is ready
  }

  final repository = ref.watch(profileRepositoryProvider);
  
  try {
    return await repository.fetchProfile();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      // The user row doesn't exist (e.g. database reset, but valid JWT token)
      // Force logout to clear the stale session
      ref.read(authNotifierProvider.notifier).logout();
      throw Exception('Session expired or user not found. Please log in again.');
    }
    rethrow;
  }
});

final paymentMethodsProvider = FutureProvider<List<SavedPaymentMethod>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  // Guard: only fetch when initialized AND authenticated
  if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
    return Completer<List<SavedPaymentMethod>>().future;
  }

  final repository = ref.watch(profileRepositoryProvider);
  return await repository.fetchPaymentMethods();
});
