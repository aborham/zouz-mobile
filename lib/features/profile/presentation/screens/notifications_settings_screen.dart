import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _orderUpdates = true;
  bool _promotions = false;

    @override
  Widget build(BuildContext context) {
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
          'profile.notifications'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionHeader("Channels"),
          _buildSwitchTile(
            "Push Notifications",
            "Get instant updates on your phone",
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchTile(
            "Email Notifications",
            "Receive updates and receipts via email",
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val),
          ),
          _buildSwitchTile(
            "SMS Notifications",
            "Critical alerts via text message",
            _smsNotifications,
            (val) => setState(() => _smsNotifications = val),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("Preferences"),
          _buildSwitchTile(
            "Order Updates",
            "Notifications about your active orders",
            _orderUpdates,
            (val) => setState(() => _orderUpdates = val),
          ),
          _buildSwitchTile(
            "Promotions & Offers",
            "News about discounts and new features",
            _promotions,
            (val) => setState(() => _promotions = val),
          ),
        ],
      ),
    );
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
