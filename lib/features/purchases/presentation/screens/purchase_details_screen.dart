import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';

class PurchaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> package;

  const PurchaseDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isRtl = locale == 'ar';
    
    final packageName = isRtl ? (package['packageNameAr'] ?? package['packageName']) : package['packageName'];
    final businessName = isRtl ? (package['businessNameAr'] ?? package['businessName']) : package['businessName'];

    final remainingUsages = package['remainingQuantity'] ?? 0;
    final initialUsages = package['initialQuantity'] ?? 0;
    final usagePercent = initialUsages > 0 ? (initialUsages - remainingUsages) / initialUsages : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'purchases.details_title'.tr(),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: package['businessLogo'] != null && package['businessLogo'] != ""
                        ? Image.network(
                            ImageUtils.getFullUrl(package['businessLogo'])!,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.business, color: AppColors.primary),
                          )
                        : const Icon(Icons.business, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
                        ),
                        Text(
                          businessName ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'purchases.qr_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'purchases.qr_instruction'.tr(),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: QrImageView(
                      data: package['id'] ?? 'N/A',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '# ${package['id']?.toString().substring(0, 8).toUpperCase() ?? "N/A"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Package Info & History Grid
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'purchases.package_details'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                   // Grid
                  Row(
                    children: [
                      _buildInfoItem('purchases.order_number'.tr(), '#${package['orderNumber'] ?? "N/A"}'),
                      _buildInfoItem('purchases.type'.tr(), package['packageType'] ?? 'ITEM'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildInfoItem('purchases.purchase_date'.tr(), _formatDate(package['purchaseDate'])),
                      _buildInfoItem('dashboard.valid_until'.tr(), _formatDate(package['expiresAt'])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 24),
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        'dashboard.usage'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$remainingUsages ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            ),
                            TextSpan(
                              text: '${'purchases.from'.tr()} $initialUsages ',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textSecondary),
                            ),
                             TextSpan(
                              text: 'purchases.usages_remaining'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ]
                        )
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: usagePercent,
                      minHeight: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Empty History Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Column(
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: const Icon(Icons.history, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'purchases.no_redemptions'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'purchases.history_instruction'.tr(),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }
}
