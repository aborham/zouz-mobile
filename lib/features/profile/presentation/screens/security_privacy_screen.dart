import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  bool _biometricLogin = true;
  bool _twoFactor = false;

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
          'profile.security_privacy'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildMenuTile(
            icon: Icons.lock_outline,
            title: "profile.change_password".tr(),
            onTap: () {},
          ),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: "profile.biometric_login".tr(),
            subtitle: "profile.biometric_desc".tr(),
            value: _biometricLogin,
            onChanged: (val) => setState(() => _biometricLogin = val),
          ),
          _buildSwitchTile(
            icon: Icons.security,
            title: "profile.two_factor".tr(),
            subtitle: "profile.two_factor_desc".tr(),
            value: _twoFactor,
            onChanged: (val) => setState(() => _twoFactor = val),
          ),
          const SizedBox(height: 32),
          _buildMenuTile(
            icon: Icons.privacy_tip,
            title: "profile.privacy_policy".tr(),
            onTap: () {},
          ),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: "profile.terms_service".tr(),
            onTap: () {},
          ),
          const SizedBox(height: 48),
          
          // Delete Account
          ListTile(
            onTap: () => _showDeleteAccountDialog(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            tileColor: AppColors.error.withValues(alpha: 0.05),
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              "profile.delete_account".tr(),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "profile.delete_account_desc".tr(),
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
        secondary: Icon(icon, color: AppColors.textPrimary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("profile.delete_confirm".tr()),
        content: Text("profile.delete_confirm_desc".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete logic
            },
            child: Text(
              "profile.delete_btn".tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
