import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../widgets/navigation_tile.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.homeBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'profile.help_center'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar (Premium Style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'support.search_hint'.tr(),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Support Channels Header
                  Text(
                    'support.how_can_we_help'.tr().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Support Channels Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSupportChannel(
                          icon: Icons.chat_bubble_rounded,
                          title: 'support.live_chat'.tr(),
                          subtitle: 'support.live_chat_wait'.tr(),
                          color: const Color(0xFF6CF8FC), // Cyan accent
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportChannel(
                          icon: Icons.alternate_email_rounded,
                          title: 'support.email_support'.tr(),
                          subtitle: 'support.email_response'.tr(),
                          color: const Color(0xFF244BF9), // Primary blue
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSupportChannel(
                    icon: Icons.phone_in_talk_rounded,
                    title: 'support.call_us'.tr(),
                    subtitle: 'support.direct_line'.tr(),
                    color: Colors.black,
                    isWide: true,
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),

                  // FAQ Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'support.faq'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'support.view_all'.tr(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ProfileNavigationTile(
                    icon: Icons.help_outline_rounded,
                    title: 'How to redeem a package?',
                    subtitle: 'Redemption guide for Zouz stands',
                    onTap: () {},
                  ),
                  ProfileNavigationTile(
                    icon: Icons.payment_rounded,
                    title: 'Payment and refunds',
                    subtitle: 'Billing cycles and package terms',
                    onTap: () {},
                  ),
                  ProfileNavigationTile(
                    icon: Icons.security_rounded,
                    title: 'Securing your account',
                    subtitle: 'Personal data and privacy',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChannel({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color == Colors.black ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color == Colors.black ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color == Colors.black ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color == Colors.black ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (color == Colors.black ? Colors.white : AppColors.textSecondary).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
