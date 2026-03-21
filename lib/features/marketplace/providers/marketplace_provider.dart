import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/core/api/api_client.dart';
import '../models/marketplace_data.dart';

final marketplaceProvider = FutureProvider<MarketplaceData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('marketplace');
  return MarketplaceData.fromJson(response.data);
});

class SelectedCategory extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String value) => state = value;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategory, String>(
  SelectedCategory.new,
);
