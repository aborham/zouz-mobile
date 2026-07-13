import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../providers/navigation_provider.dart';
import 'home_dashboard_screen.dart';
import '../../../purchases/presentation/screens/purchases_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../common/presentation/widgets/app_update_dialog.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  /// Tracks which tabs have ever been visited.
  /// Only visited tabs get their widget tree built — this prevents ALL tabs
  /// from firing API calls simultaneously on startup (the IndexedStack bug).
  final Set<int> _visitedTabs = {0}; // Home is always built first

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOptionalUpdate();
    });
  }

  void _checkOptionalUpdate() {
    final pendingUpdate = AppUpdateService.pendingOptionalUpdate;
    if (pendingUpdate != null) {
      AppUpdateService.pendingOptionalUpdate = null; // Clear it so it doesn't show again unnecessarily
      AppUpdateDialog.show(context, pendingUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    // Mark current tab as visited — triggers its widget tree to be built
    if (!_visitedTabs.contains(currentIndex)) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visitedTabs.add(currentIndex));
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildTab(0, const HomeDashboardScreen(), currentIndex),
          _buildTab(1, const PurchasesScreen(), currentIndex),
          _buildTab(2, const AccountScreen(), currentIndex),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(navigationProvider.notifier).setIndex(index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: 'dashboard.home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: 'dashboard.purchases'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'profile.account'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  /// Lazily builds a tab:
  /// - Not yet visited → renders nothing (SizedBox.shrink)
  /// - Visited but not active → Offstage (hidden but alive in the tree)
  /// - Active → fully rendered and ticking
  Widget _buildTab(int index, Widget child, int currentIndex) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    final isActive = currentIndex == index;
    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: child,
      ),
    );
  }
}
