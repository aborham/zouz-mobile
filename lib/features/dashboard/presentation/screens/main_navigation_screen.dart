import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../providers/navigation_provider.dart';
import 'home_dashboard_screen.dart';
import '../../../scanner/presentation/screens/qr_scanner_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';

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
      extendBody: true,
      body: Stack(
        children: [
          _buildTab(0, const HomeDashboardScreen(), currentIndex),
          _buildTab(1, const QrScannerScreen(), currentIndex),
          _buildTab(2, const AccountScreen(), currentIndex),
        ],
      ),
      floatingActionButton: Container(
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => ref.read(navigationProvider.notifier).setIndex(1),
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: Colors.white,
          elevation: 0,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home,
                  'dashboard.home'.tr().toUpperCase(),
                ),
                const SizedBox(width: 50),
                _buildNavItem(
                  2,
                  Icons.person_outline,
                  Icons.person,
                  'profile.account'.tr().toUpperCase(),
                ),
              ],
            ),
          ),
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final currentIndex = ref.watch(navigationProvider);
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => ref.read(navigationProvider.notifier).setIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
