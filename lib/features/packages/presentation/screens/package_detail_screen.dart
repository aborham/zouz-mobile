import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saudi_riyal_symbol/saudi_riyal_symbol.dart';
import 'package:zouz_mobile/features/cart/providers/cart_provider.dart';
import 'package:zouz_mobile/features/cart/providers/cart_provider.dart' as cart_models;

class PackageDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> package;

  const PackageDetailScreen({super.key, required this.package});

  String _getLocalizedValue(dynamic field, String locale) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map) {
      return field[locale] ?? field['en'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final name = _getLocalizedValue(package['name'], locale);
    final description = _getLocalizedValue(package['description'], locale);
    final price = package['price']?.toString() ?? 'N/A';
    final type = package['type'] ?? 'QUANTITY'; // QUANTITY or DURATION
    final validityDays = package['validityDays']?.toString() ?? 'N/A';
    final initialQuantity = package['initialQuantity']?.toString() ?? 'Unlimited';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  package['imageUrl'] != null
                      ? Image.network(
                          ImageUtils.getFullUrl(package['imageUrl'])!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primary),
                  // Gradient for better back button visibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              transform: Matrix4.translationValues(0, -30, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (package['isTrending'] == true)
                          _buildBadge(
                            icon: Icons.local_fire_department_rounded,
                            label: 'packages.trending'.tr(),
                            color: Colors.orange.shade600,
                            bgColor: Colors.orange.shade50,
                          ),
                        if (package['rating'] != null)
                          _buildBadge(
                            icon: Icons.star_rounded,
                            label: package['rating'].toString(),
                            color: Colors.amber.shade600,
                            bgColor: Colors.amber.shade50,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (description.isNotEmpty) ...[
                      Text(
                        'packages.description'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.inventory_2_rounded,
                            title: 'packages.items'.tr(),
                            value: type == 'QUANTITY' ? initialQuantity : 'packages.unlimited'.tr(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.timer_rounded,
                            title: 'packages.days_validity'.tr().replaceAll('{}', '').trim(),
                            value: '$validityDays ${'packages.days'.tr()}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'packages.total_price'.tr(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SaudiCurrencySymbol(
                            price: double.tryParse(package['price']?.toString() ?? '0') ?? 0,
                            priceStyle: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                            symbolFontColor: AppColors.primary,
                            isOldPrice: false,
                          ),
                          if (package['originalPrice'] != null) ...[
                            const SizedBox(width: 8),
                            SaudiCurrencySymbol(
                              price: double.tryParse(package['originalPrice'].toString()) ?? 0,
                              priceStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              symbolFontColor: Colors.grey.shade400,
                              isOldPrice: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final cartItem = cart_models.CartItem(
                        packageId: package['id'],
                        packageName: name,
                        price: double.tryParse(package['price'].toString()) ?? 0.0,
                        imageUrl: package['imageUrl'],
                        quantity: 1,
                        tenantId: package['tenantId'],
                        type: package['type'] ?? 'QUANTITY',
                        tenantName: package['tenantName'] is Map 
                          ? (package['tenantName'][locale] ?? package['tenantName']['en'] ?? '')
                          : package['tenantName']?.toString(),
                        tenantLogoUrl: package['tenantLogoUrl'],
                      );
                      
                      ref.read(cartProvider.notifier).addItem(cartItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to cart'), // Fallback text, ideally localized
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.push('/checkout', extra: {'package': package});
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'packages.purchase_now'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Very light slate
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
