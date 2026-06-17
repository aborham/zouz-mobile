import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
    return Future.any([]); // Stay in loading until auth is ready
  }

  final repository = ref.watch(profileRepositoryProvider);
  return await repository.fetchProfile();
});

final paymentMethodsProvider = FutureProvider<List<SavedPaymentMethod>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  // Guard: only fetch when initialized AND authenticated
  if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
    return Future.any([]);
  }

  final repository = ref.watch(profileRepositoryProvider);
  return await repository.fetchPaymentMethods();
});
