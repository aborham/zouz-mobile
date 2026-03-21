import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';

class PurchaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> package;

  const PurchaseDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final status = package['status'] ?? 'UNKNOWN';
    final isDepleted = status == 'DEPLETED' || status == 'EXPIRED';

    return Scaffold(
      appBar: AppBar(
        title: Text('purchases.details_title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Header Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (package['businessLogo'] != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            ImageUtils.getFullUrl(package['businessLogo'])!,
                          ),
                          radius: 24,
                        )
                      else
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 24,
                          child: Icon(Icons.business, color: Colors.white),
                        ),
                      const SizedBox(width: 12),
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
                            Text(
                              package['businessName'] ?? 'Unknown Business',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  if (package['description'] != null &&
                      package['description'].toString().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Text(
                      'packages.description'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(package['description']),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Info Section
            Text(
              'purchases.order_info'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              child: Column(
                children: [
                  _buildDetailRow(
                    'purchases.order_number'.tr(),
                    '#${package['orderNumber'] ?? 'N/A'}',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'purchases.purchased'.tr(),
                    _formatDate(package['purchaseDate']),
                  ),
                  if (package['packageType'] == 'QUANTITY') ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'purchases.remaining'.tr(),
                      '${package['remainingQuantity'] ?? 0} / ${package['initialQuantity'] ?? 0}',
                    ),
                  ],
                  if (package['expiresAt'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'purchases.expires'.tr(),
                      _formatDate(package['expiresAt']),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 16),

            // Order Summary Card (Premium)
            _buildSectionCard(
              child: InkWell(
                onTap: () => _showOrderSummaryBottomSheet(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'purchases.order_summary'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            if (!isDepleted && status == 'ACTIVE')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showQRCodeDialog(context),
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: Text(
                    'purchases.redeem'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showOrderSummaryBottomSheet(BuildContext context) {
    final invoice = package['invoice'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'purchases.order_summary'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Item detail
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1x ${package['packageName'] ?? 'Item'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (package['description'] != null)
                          Text(
                            package['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${package['orderTotal'] ?? '0'} ${'dashboard.currency'.tr()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              // Billing breakdown
              if (invoice != null) ...[
                _buildSummaryRow(
                  'purchases.subtotal'.tr(),
                  '${invoice['subtotal']} ${'dashboard.currency'.tr()}',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'purchases.vat'.tr(),
                  '${invoice['vatAmount']} ${'dashboard.currency'.tr()}',
                ),
                const SizedBox(height: 12),
              ],
              _buildSummaryRow(
                'purchases.total'.tr(),
                '${package['orderTotal'] ?? '0'} ${'dashboard.currency'.tr()}',
                isBold: true,
                fontSize: 18,
              ),
              Text(
                'purchases.vat_included'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Order metadata
              _buildMetadataRow(
                'purchases.order_number'.tr(),
                '${package['orderNumber'] ?? 'N/A'}',
                showCopy: true,
              ),
              const SizedBox(height: 12),
              _buildMetadataRow(
                'purchases.order_time'.tr(),
                _formatDateTime(package['purchaseDate']),
              ),
              const SizedBox(height: 12),
              _buildMetadataRow(
                'purchases.payment_method'.tr(),
                invoice?['paymentMethod'] ?? 'Apple Pay',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'purchases.got_it'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.black : AppColors.textSecondary,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value, {
    bool showCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (showCopy) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'purchases.copy'.tr(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy at HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }

  void _showQRCodeDialog(BuildContext context) {
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
                  child: Image.network(
                    'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${package['qrCode'] ?? package['id']}',
                    width: 200,
                    height: 200,
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getLocalStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
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
