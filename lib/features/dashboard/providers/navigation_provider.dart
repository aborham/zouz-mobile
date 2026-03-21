import 'package:flutter_riverpod/legacy.dart';

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});
