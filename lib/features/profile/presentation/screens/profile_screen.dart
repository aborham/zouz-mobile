import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import 'package:zouz_mobile/features/dashboard/providers/navigation_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'profile.title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.refresh(profileProvider.future),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 20),
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(
                                ImageUtils.getFullUrl(profile.avatarUrl)!,
                              )
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00), // Orange from design
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: () => _showComingSoon(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Name & Email
              Center(
                child: Column(
                  children: [
                    Text(
                      profile.name ?? 'profile.customer_name'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email ?? profile.phoneNumber ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Stats
              _buildStatCard(
                '${profile.activePackagesCount}',
                'profile.active_packages'.tr().toUpperCase(),
              ),
              const SizedBox(height: 32),
              // Account Activity
              _buildSectionHeader('profile.account_activity'.tr()),
              _buildMenuCard(
                icon: Icons.inventory_2_outlined,
                title: 'profile.my_packages'.tr(),
                subtitle: 'profile.manage_active_packages'.tr(),
                onTap: () => ref.read(navigationProvider.notifier).setIndex(2),
                iconColor: const Color(0xFF4FC3F7),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.receipt_long_outlined,
                title: 'profile.order_history'.tr(),
                subtitle: 'profile.view_past_purchases'.tr(),
                onTap: () => ref.read(navigationProvider.notifier).setIndex(2),
                iconColor: const Color(0xFF81D4FA),
              ),
              const SizedBox(height: 32),
              // Preferences
              _buildSectionHeader('profile.preferences'.tr()),
              _buildMenuCard(
                icon: Icons.settings_outlined,
                title: 'profile.settings'.tr(),
                subtitle: 'Privacy, notifications, theme',
                onTap: () => context.push('/settings'),
                iconColor: const Color(0xFF4DB6AC),
              ),
              const SizedBox(height: 40),
              // Logout
              OutlinedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: Color(0xFFFF6B00)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'profile.logout'.tr(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'profile.version'.tr(args: ['2.4.1']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label, {
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (color == Colors.white)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7D7D7D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9E9E9E),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D1D1)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('common.coming_soon'.tr())));
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('profile.share_app'.tr()),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text('profile.rate_app'.tr()),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.logout'.tr()),
        content: Text('profile.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: Text(
              'profile.logout'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
