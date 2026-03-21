import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/menu_repository.dart';

class MenuState {
  final bool isLoading;
  final Map<String, dynamic>? tenant;
  final List<dynamic>? packages;
  final Map<String, dynamic>? stand;
  final String? errorMessage;

  MenuState({
    this.isLoading = false,
    this.tenant,
    this.packages,
    this.stand,
    this.errorMessage,
  });

  MenuState copyWith({
    bool? isLoading,
    Map<String, dynamic>? tenant,
    List<dynamic>? packages,
    Map<String, dynamic>? stand,
    String? errorMessage,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      tenant: tenant ?? this.tenant,
      packages: packages ?? this.packages,
      stand: stand ?? this.stand,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MenuNotifier extends Notifier<MenuState> {
  late MenuRepository _repository;

  @override
  MenuState build() {
    _repository = ref.watch(menuRepositoryProvider);
    return MenuState();
  }

  Future<void> fetchMenu(String tenantSlug, String? standId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchMenu(tenantSlug, standId);
      state = state.copyWith(
        isLoading: false,
        tenant: data['tenant'],
        packages: data['packages'],
        stand: data['stand'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final menuNotifierProvider = NotifierProvider<MenuNotifier, MenuState>(() {
  return MenuNotifier();
});
