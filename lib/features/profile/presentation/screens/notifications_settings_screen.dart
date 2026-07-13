import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../providers/profile_provider.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _orderUpdates = true;
  bool _promotions = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile.notification_settings'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_initialized) {
            _pushNotifications = profile.settings.pushNotifications;
            _emailNotifications = profile.settings.emailNotifications;
            _smsNotifications = profile.settings.smsNotifications;
            _orderUpdates = profile.settings.orderUpdates;
            _promotions = profile.settings.promotionalNotifications;
            _initialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildSectionHeader("notifications.channels".tr()),
              _buildSwitchTile(
                "notifications.push".tr(),
                "notifications.push_desc".tr(),
                _pushNotifications,
                (val) => _updateSetting('pushNotifications', val, () => _pushNotifications = val),
              ),
              _buildSwitchTile(
                "notifications.email".tr(),
                "notifications.email_desc".tr(),
                _emailNotifications,
                (val) => _updateSetting('emailNotifications', val, () => _emailNotifications = val),
              ),
              _buildSwitchTile(
                "notifications.sms".tr(),
                "notifications.sms_desc".tr(),
                _smsNotifications,
                (val) => _updateSetting('smsNotifications', val, () => _smsNotifications = val),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader("notifications.preferences".tr()),
              _buildSwitchTile(
                "notifications.order_updates".tr(),
                "notifications.order_updates_desc".tr(),
                _orderUpdates,
                (val) => _updateSetting('orderUpdates', val, () => _orderUpdates = val),
              ),
              _buildSwitchTile(
                "notifications.promotions".tr(),
                "notifications.promotions_desc".tr(),
                _promotions,
                (val) => _updateSetting('promotionalNotifications', val, () => _promotions = val),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('common.error'.tr())),
      ),
    );
  }

  Future<void> _updateSetting(String key, bool value, VoidCallback updateLocalState) async {
    // Optimistic update
    setState(updateLocalState);

    try {
      final repository = ref.read(profileRepositoryProvider);
      
      final Map<String, dynamic> settingsData = {
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'smsNotifications': _smsNotifications,
        'orderUpdates': _orderUpdates,
        'promotionalNotifications': _promotions,
      };

      await repository.updateProfile({'settings': settingsData});
      
      // Background refresh
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        // Revert on failure
        setState(() {
          _initialized = false; // Force re-initialization from provider data
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
