import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../models/home_data.dart';

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  
  // Wait until initialized AND authenticated
  if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
    // Return a never-completing future or similar to keep it in loading if we just go to dashboard?
    // Actually, if we are on dashboard, we SHOULD be authenticated.
    // If we reach here and aren't, stay in loading or throw.
    return Future.any([]); // Stay in loading
  }

  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.dio.get('home');
    if (response.statusCode == 200) {
      return HomeData.fromJson(response.data);
    } else {
      throw Exception('Failed to load home data: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
});

// Selector for user info
final homeUserProvider = Provider<HomeUser?>((ref) {
  return ref.watch(homeDataProvider).maybeWhen(
    data: (data) => data.user,
    orElse: () => null,
  );
});
