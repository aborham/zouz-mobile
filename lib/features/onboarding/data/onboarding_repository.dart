import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/core/api/api_client.dart';

class OnboardingSlide {
  final String id;
  final Map<String, dynamic> title;
  final Map<String, dynamic> subtitle;
  final Map<String, dynamic> description;
  final String? lottieUrl;
  final String? imageUrl;
  final int sortOrder;

  OnboardingSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.lottieUrl,
    this.imageUrl,
    required this.sortOrder,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      description: json['description'],
      lottieUrl: json['lottieUrl'],
      imageUrl: json['imageUrl'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository(this._apiClient);

  Future<List<OnboardingSlide>> getSlides() async {
    try {
      // Relative to baseUrl: http://localhost:3000/api/customer/
      final response = await _apiClient.dio.get('onboarding');
      final List<dynamic> data = response.data;
      return data.map((json) => OnboardingSlide.fromJson(json)).toList();
    } catch (e) {

      // Return empty list or handle error appropriately
      rethrow;
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingRepository(apiClient);
});

final onboardingSlidesProvider = FutureProvider<List<OnboardingSlide>>((ref) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getSlides();
});
