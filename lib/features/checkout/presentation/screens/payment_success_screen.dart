import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  ConsumerState<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await ref.read(apiClientProvider).dio.get('orders/${widget.orderId}');
      if (mounted) {
        setState(() {
          _orderData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedString(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map) {
      final locale = context.locale.languageCode;
      return data[locale]?.toString() ?? data['en']?.toString() ?? data.values.firstOrNull?.toString() ?? '';
    }
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'checkout.status_page_title'.tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildSuccessContent(),
    );
  }

  Widget _buildSuccessContent() {
    final dateStr = _orderData?['createdAt'] != null 
        ? DateFormat('yyyy/MM/dd hh:mm a').format(DateTime.parse(_orderData!['createdAt']))
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Success Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 8),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 60),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'checkout.success_title'.tr(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'checkout.success_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 40),
          // Order Receipt Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('checkout.store_label'.tr(), _getLocalizedString(_orderData?['tenantName']), isMerchant: true),
                const Divider(height: 32),
                _buildInfoRow('checkout.package_label'.tr(), _getLocalizedString(_orderData?['items']?[0]?['packageName'])),
                _buildInfoRow('checkout.payment_method_label'.tr(), _orderData?['paymentType'] ?? 'Tap Payments'),
                _buildInfoRow('checkout.date_label'.tr(), dateStr),
                _buildInfoRow('checkout.transaction_id_label'.tr(), '#${_orderData?['gatewayId'] ?? _orderData?['orderNumber'] ?? ''}'),
                const Divider(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'checkout.total_label'.tr(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    Text(
                      '${_orderData?['totalAmount']} ${'SAR'.tr()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF224AFB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              context.go('/purchases');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF224AFB),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Text('checkout.view_packages'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/dashboard'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text('checkout.return_home'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share, size: 20),
            label: Text('checkout.share'.tr()),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF224AFB)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMerchant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMerchant) ...[
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFDE9D9),
                    ),
                    child: const Center(child: Icon(Icons.store, size: 14, color: Color(0xFFD4813E))),
                  ),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
