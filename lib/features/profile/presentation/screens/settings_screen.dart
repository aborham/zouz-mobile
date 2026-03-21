import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B00)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'profile.settings'.tr(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // User Brief Card
            profileAsync.when(
              data: (profile) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFF3E0,
                  ), // Gentle beige/glass from design
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(
                              ImageUtils.getFullUrl(profile.avatarUrl)!,
                            )
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name ?? 'profile.customer_name'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          profile.email ?? profile.phoneNumber ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7D7D7D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Container(),
            ),
            const SizedBox(height: 32),
            // Preferences Section
            _buildSectionHeader('profile.preferences'.tr()),
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'profile.account_settings'.tr(),
              onTap: () => _showComingSoon(context),
              iconColor: const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.notifications_none_outlined,
              title: 'profile.notifications'.tr(),
              trailing: Switch(
                value: true,
                onChanged: (v) => _showComingSoon(context),
                activeColor: AppColors.primary,
              ),
              onTap: () {},
              iconColor: const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.language_outlined,
              title: 'profile.preferences'.tr(),
              onTap: () => _showComingSoon(context),
              iconColor: const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 32),
            // Legal & Support Section
            _buildSectionHeader('profile.legal_support'.tr()),
            _buildSettingsItem(
              icon: Icons.description_outlined,
              title: 'profile.terms'.tr(),
              onTap: () => _showContentDialog(
                context,
                'profile.terms'.tr(),
                'profile.terms_content'.tr(),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: 'profile.privacy'.tr(),
              onTap: () => _showContentDialog(
                context,
                'profile.privacy'.tr(),
                'profile.privacy_content'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'profile.help_center'.tr(),
              onTap: () => _showComingSoon(
                context,
              ), // Changed to coming soon as per general instruction
              iconColor: const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 48),
            // Logout Button
            ElevatedButton(
              onPressed: () => _showLogoutDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'profile.logout'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Zouz App Version 2.4.1 (Build 890)',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
          color: Color(0xFFFF6B00),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('common.coming_soon'.tr())));
  }

  void _showContentDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              )
            : null,
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
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
