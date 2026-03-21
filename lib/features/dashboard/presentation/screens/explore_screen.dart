import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard.explore'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'dashboard.explore_coming_soon'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
