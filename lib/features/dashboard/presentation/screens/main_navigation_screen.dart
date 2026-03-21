import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../providers/navigation_provider.dart';
import 'home_dashboard_screen.dart';
import 'explore_screen.dart';
import '../../../purchases/presentation/screens/purchases_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          const HomeDashboardScreen(),
          const ExploreScreen(),
          PurchasesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_outlined,
                Icons.home,
                'dashboard.home'.tr(),
              ),
              _buildNavItem(
                1,
                Icons.explore_outlined,
                Icons.explore,
                'dashboard.explore'.tr(),
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(
                2,
                Icons.inventory_2_outlined,
                Icons.inventory_2,
                'dashboard.my_packages'.tr(),
              ),
              _buildNavItem(
                3,
                Icons.person_outline,
                Icons.person,
                'profile.title'.tr(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
