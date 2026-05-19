import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/widgets/error_state_widget.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/purchases/presentation/widgets/purchase_summary_cards.dart';
import '../../providers/home_provider.dart';
import '../../models/home_data.dart';
import '../../../cart/providers/cart_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: homeState.when(
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(homeDataProvider.future),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context, ref, data.user),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: PurchaseSummaryCards(
                      totalSpent: 185,
                      totalSavings: 65,
                    ),
                  ),
                ),
                _buildActiveRoutine(context, data.activePackages),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ErrorStateWidget(
            onRetry: () => ref.refresh(homeDataProvider.future),
            subtitle: err.toString(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, HomeUser user) {
    final hour = DateTime.now().hour;
    final cartState = ref.watch(cartProvider);
    String greetingKey;
    if (hour < 12) {
      greetingKey = 'dashboard.good_morning';
    } else if (hour < 17) {
      greetingKey = 'dashboard.good_afternoon';
    } else {
      greetingKey = 'dashboard.good_evening';
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(ImageUtils.getFullUrl(user.avatarUrl!)!)
                        : const NetworkImage(
                            'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${greetingKey.tr()}, ${user.name?.split(' ').first ?? 'profile.customer_name'.tr()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                _buildHeaderIconButton(
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => context.push('/cart'),
                  badgeCount: cartState.totalItems,
                ),
                const SizedBox(width: 8),
                _buildHeaderIconButton(
                  icon: Icons.notifications_outlined,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    int badgeCount = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(icon, size: 20),
            onPressed: onPressed,
            color: AppColors.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          if (badgeCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildActiveRoutine(BuildContext context, List<ActivePackage> packages) {
    if (packages.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.only(top: 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dashboard.active_routine'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/purchases'),
                    child: Text(
                      'dashboard.see_all'.tr().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pkg = packages[index];
                final locale = context.locale.languageCode;
                final packageName = pkg.packageName[locale] ?? pkg.packageName['en'] ?? '';

                return GestureDetector(
                  onTap: () => context.push('/purchase-details', extra: pkg.toMap()),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.secondary, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(packageName),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: pkg.providerLogo != null && pkg.providerLogo!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        ImageUtils.getFullUrl(pkg.providerLogo!)!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                            _buildDefaultIcon(packageName),
                                      ),
                                    )
                                  : _buildDefaultIcon(packageName),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    packageName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildExpiryRow(pkg.expiresAt),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'dashboard.usage'.tr().toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            _buildUsageText(context, pkg),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: pkg.progress,
                            minHeight: 12,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(String name) {
    final lName = name.toLowerCase();
    IconData iconData = Icons.inventory_2_outlined;
    Color iconColor = AppColors.primary;

    if (lName.contains('gym') || lName.contains('fitness') || lName.contains('workout')) {
      iconData = Icons.fitness_center;
      iconColor = const Color(0xFF2E7D32);
    } else if (lName.contains('workspace') || lName.contains('office') || lName.contains('desk') || lName.contains('laptop')) {
      iconData = Icons.laptop_mac;
      iconColor = const Color(0xFF4527A0);
    } else if (lName.contains('coffee') || lName.contains('food') || lName.contains('cafe')) {
      iconData = Icons.coffee;
      iconColor = const Color(0xFFEF6C00);
    } else if (lName.contains('beauty') || lName.contains('spa') || lName.contains('salon')) {
      iconData = Icons.spa;
      iconColor = const Color(0xFFC2185B);
    }

    return Icon(iconData, color: iconColor, size: 28);
  }

  Color _getCategoryColor(String name) {
    final lName = name.toLowerCase();
    if (lName.contains('gym') || lName.contains('fitness') || lName.contains('workout')) {
      return const Color(0xFFE8F5E9);
    }
    if (lName.contains('workspace') || lName.contains('office') || lName.contains('desk') || lName.contains('laptop')) {
      return const Color(0xFFEDE7F6);
    }
    if (lName.contains('coffee') || lName.contains('food') || lName.contains('cafe')) {
      return const Color(0xFFFFF3E0);
    }
    if (lName.contains('beauty') || lName.contains('spa') || lName.contains('salon')) {
      return const Color(0xFFFCE4EC);
    }
    return const Color(0xFFF5F5F5);
  }

  Widget _buildExpiryRow(DateTime? expiresAt) {
    if (expiresAt == null) return const SizedBox.shrink();
    
    final days = expiresAt.difference(DateTime.now()).inDays;
    final isExpiresTomorrow = days == 1;
    final color = isExpiresTomorrow ? AppColors.error : AppColors.textSecondary;
    final text = isExpiresTomorrow 
        ? 'purchases.expires_tomorrow'.tr() 
        : 'purchases.expires_in_days'.tr(args: [days.toString()]);
    
    return Row(
      children: [
        Icon(
          isExpiresTomorrow ? Icons.calendar_today_outlined : Icons.access_time,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isExpiresTomorrow ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageText(BuildContext context, ActivePackage pkg) {
    final usedCount = pkg.initialQuantity! - pkg.remainingQuantity;
    final totalCount = pkg.initialQuantity;
    final unitKey = pkg.type.toLowerCase() == 'quantity' ? 'dashboard.visits' : 'dashboard.items';

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '$usedCount ',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          TextSpan(text: '/ $totalCount ${unitKey.tr()}'),
        ],
      ),
    );
  }
}

