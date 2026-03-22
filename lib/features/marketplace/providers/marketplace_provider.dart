import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/core/api/api_client.dart';
import '../models/marketplace_data.dart';

final marketplaceProvider = FutureProvider<MarketplaceData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('marketplace');
  return MarketplaceData.fromJson(response.data);
});

// Using Notifiers for v3 compatibility and best practices
class MarketplaceSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final marketplaceSearchProvider = NotifierProvider<MarketplaceSearchNotifier, String>(
  MarketplaceSearchNotifier.new,
);

class MarketplaceCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setCategory(String? category) => state = category;
}

final marketplaceCategoryProvider = NotifierProvider<MarketplaceCategoryNotifier, String?>(
  MarketplaceCategoryNotifier.new,
);

final exploreDataProvider = FutureProvider<MarketplaceExploreData>((ref) async {
  final apiClient = ref.watch(apiClientProvider).dio;
  final query = ref.watch(marketplaceSearchProvider);
  final category = ref.watch(marketplaceCategoryProvider);

  final Map<String, dynamic> queryParams = {};
  if (query.isNotEmpty) queryParams['q'] = query;
  if (category != null && category != 'All') queryParams['category'] = category;

  final response = await apiClient.get(
    'explore',
    queryParameters: queryParams,
  );
  
  return MarketplaceExploreData.fromJson(response.data);
});
