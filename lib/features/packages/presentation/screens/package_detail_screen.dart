import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';

class PackageDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final name = _getLocalizedValue(package['name'], locale);
    final description = _getLocalizedValue(package['description'], locale);
    final price = package['price']?.toString() ?? 'N/A';
    final type = package['type'] ?? 'QUANTITY'; // QUANTITY or DURATION
    final validityDays = package['validityDays']?.toString() ?? 'N/A';
    final initialQuantity =
        package['initialQuantity']?.toString() ?? 'Unlimited';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: package['imageUrl'] != null
                  ? Image.network(
                      ImageUtils.getFullUrl(package['imageUrl'])!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.primary),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$price ${'dashboard.currency'.tr()}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (description.isNotEmpty) ...[
                    Text(
                      'package.description'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: type == 'QUANTITY'
                            ? '$initialQuantity ${'packages.items'.tr()}'
                            : 'packages.unlimited'.tr(),
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        icon: Icons.timer_outlined,
                        label: '$validityDays ${'packages.days_validity'.tr()}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // TODO: Proceed to Checkout / Tap Payments
              context.push('/checkout', extra: package);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('package.purchase_now'.tr()),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
