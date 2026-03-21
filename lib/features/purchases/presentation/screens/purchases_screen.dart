import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../repositories/purchases_repository.dart';

final purchasesFutureProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repository = ref.watch(purchasesRepositoryProvider);
      return await repository.fetchPurchases();
    });

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard.purchases'.tr()),
        centerTitle: true,
      ),
      body: purchasesAsync.when(
        data: (purchases) {
          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'purchases.empty'.tr(),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(purchasesFutureProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: purchases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final package = purchases[index];
                return _buildPurchaseCard(context, package);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: ${err.toString()}'),
              TextButton(
                onPressed: () => ref.refresh(purchasesFutureProvider),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    Map<String, dynamic> package,
  ) {
    final status = package['status'] ?? 'UNKNOWN';
    final isDepleted = status == 'DEPLETED' || status == 'EXPIRED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Logo area
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              image: package['imageUrl'] != null
                  ? DecorationImage(
                      image: NetworkImage(
                        ImageUtils.getFullUrl(package['imageUrl'])!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getLocalStatus(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (package['businessLogo'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            ImageUtils.getFullUrl(package['businessLogo'])!,
                          ),
                          radius: 16,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package['packageName'] ?? 'Unknown Package',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package['businessName'] ?? 'Unknown Business',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'purchases.purchased'.tr(),
                      _formatDate(package['purchaseDate']),
                    ),
                    if (package['packageType'] == 'QUANTITY')
                      _buildInfoColumn(
                        'purchases.remaining'.tr(),
                        '${package['remainingQuantity'] ?? 0}',
                      ),
                    if (package['packageType'] == 'TIME_BASED')
                      _buildInfoColumn(
                        'purchases.expires'.tr(),
                        _formatDate(package['expiresAt']),
                      ),
                  ],
                ),
                if (!isDepleted && status == 'ACTIVE')
                  const SizedBox(height: 12),
                if (!isDepleted && status == 'ACTIVE')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showQRCodeDialog(context, package);
                      },
                      icon: const Icon(Icons.qr_code),
                      label: Text('purchases.redeem'.tr()),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.push('/purchase-details', extra: package);
                    },
                    child: Text('purchases.view_details'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'purchases.redeem_title'.tr(args: [package['packageName'] ?? '']),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'purchases.redeem_instruction'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: package['qrCode'] ?? package['id'] ?? '',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ID: ${package['qrCode'] ?? package['id']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'common.close'.tr(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  String _getLocalStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'purchases.status.active'.tr();
      case 'EXPIRED':
        return 'purchases.status.expired'.tr();
      case 'DEPLETED':
        return 'purchases.status.depleted'.tr();
      case 'PENDING_PAYMENT':
        return 'purchases.status.pending_payment'.tr();
      case 'PENDING_ACTIVATION':
        return 'purchases.status.pending_activation'.tr();
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'EXPIRED':
      case 'DEPLETED':
        return Colors.grey;
      case 'PENDING_PAYMENT':
      case 'PENDING_ACTIVATION':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
