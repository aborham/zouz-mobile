import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/widgets/error_state_widget.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(child: _buildScanStandBanner(context, ref)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                const SliverToBoxAdapter(child: _PromoCarousel()),
                _buildActiveRoutine(context, ref, data.activePackages),
                _buildTrendingPackages(context, data.trendingPackages),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
          loading: () => _buildSkeleton(context),
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
                    radius: 18,
                    backgroundColor: AppColors.surface,
                    backgroundImage: user.avatarUrl != null && !user.avatarUrl!.contains('svg')
                        ? NetworkImage(ImageUtils.getFullUrl(user.avatarUrl!)!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.contains('svg')
                        ? const Icon(Icons.person, size: 20, color: AppColors.primary)
                        : null,
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

  Widget _buildScanStandBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            context.push('/scanner'); // Go to QR Scanner screen
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.scan_stand'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dashboard.quick_action_desc'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.87),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoutine(BuildContext context, WidgetRef ref, List<ActivePackage> packages) {
    if (packages.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.secondary, width: 1.0),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_activity_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'purchases.empty'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'scanner.premium_permission_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.push('/scanner');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'dashboard.scan_stand'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: pkg.progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/purchase-details', extra: pkg.toMap()),
                              icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                              label: Text(
                                'dashboard.redeem_now'.tr(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildTrendingPackages(BuildContext context, List<TrendingPackage> packages) {
    if (packages.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'dashboard.featured_packages'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: packages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final pkg = packages[index];
                  final locale = context.locale.languageCode;
                  final packageName = pkg.name[locale] ?? pkg.name['en'] ?? '';
                  final providerName = pkg.providerName[locale] ?? pkg.providerName['en'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      context.push('/package', extra: {
                        'id': pkg.id,
                        'name': packageName,
                        'price': pkg.price.toString(),
                        'imageUrl': pkg.imageUrl,
                        'businessName': providerName,
                        'rating': pkg.rating,
                      });
                    },
                    child: Container(
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.secondary, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                image: pkg.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(pkg.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: AppColors.surface,
                              ),
                              child: pkg.imageUrl == null
                                  ? const Center(
                                      child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
                                    )
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  packageName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  providerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${pkg.price} ${'dashboard.currency'.tr()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          (pkg.rating ?? 4.5).toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const _SkeletonPlaceholder(width: 36, height: 36, borderRadius: 18),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonPlaceholder(width: 80, height: 12),
                        SizedBox(height: 6),
                        _SkeletonPlaceholder(width: 140, height: 16),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: const [
                    _SkeletonPlaceholder(width: 40, height: 40, borderRadius: 12),
                    SizedBox(width: 8),
                    _SkeletonPlaceholder(width: 40, height: 40, borderRadius: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SkeletonPlaceholder(width: double.infinity, height: 120, borderRadius: 24),
            const SizedBox(height: 24),
            const _SkeletonPlaceholder(width: double.infinity, height: 150, borderRadius: 24),
            const SizedBox(height: 24),
            const _SkeletonPlaceholder(width: 140, height: 20),
            const SizedBox(height: 16),
            const _SkeletonPlaceholder(width: double.infinity, height: 160, borderRadius: 32),
            const SizedBox(height: 28),
            const _SkeletonPlaceholder(width: 160, height: 20),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _SkeletonPlaceholder(width: 150, height: 220, borderRadius: 24)),
                SizedBox(width: 16),
                Expanded(child: _SkeletonPlaceholder(width: 150, height: 220, borderRadius: 24)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonPlaceholder({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();
}

class _SkeletonPlaceholderState extends State<_SkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class _PromoBannerItem {
  final String title;
  final String subtitle;
  final String badgeText;
  final String imageUrl;
  final Color baseColor;

  _PromoBannerItem({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.imageUrl,
    required this.baseColor,
  });
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_PromoBannerItem> _banners = [
    _PromoBannerItem(
      title: "Half Million Special",
      subtitle: "Save up to 35% on your daily V60 and Flat White routines",
      badgeText: "HOT DEAL",
      imageUrl: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=800&auto=format&fit=crop",
      baseColor: const Color(0xFFEF6C00),
    ),
    _PromoBannerItem(
      title: "Key Cafe Signature",
      subtitle: "Get the premium Spanish Latte bundle at a special rate",
      badgeText: "POPULAR",
      imageUrl: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?q=80&w=800&auto=format&fit=crop",
      baseColor: const Color(0xFF4527A0),
    ),
    _PromoBannerItem(
      title: "Barns Premium Coffee",
      subtitle: "Unlock exclusive rewards when scanning table stand QR codes",
      badgeText: "EXCLUSIVE",
      imageUrl: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=800&auto=format&fit=crop",
      baseColor: const Color(0xFFC2185B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: NetworkImage(banner.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.55),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: banner.baseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          banner.badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
