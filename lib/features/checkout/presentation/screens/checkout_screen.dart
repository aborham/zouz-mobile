import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:go_sell_sdk_flutter/go_sell_sdk_flutter.dart';
import 'package:go_sell_sdk_flutter/model/models.dart';
import '../../repositories/checkout_repository.dart';
import '../../../cart/providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? package;
  final List<Map<String, dynamic>>? items;
  final bool fromCart;

  const CheckoutScreen({
    super.key,
    this.package,
    this.items,
    this.fromCart = false,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;

  String _getLocalizedValue(dynamic field, String locale) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map) {
      return field[locale] ?? field['en'] ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _configureTapSDK();
  }

  void _configureTapSDK() {
    GoSellSdkFlutter.configureApp(
      productionSecretKey: 'sk_test_PLACEHOLDER',
      sandBoxSecretKey: 'sk_test_PLACEHOLDER',
      bundleId: 'com.zouz.customer',
      lang: context.locale.languageCode,
    );
  }

  void _initializeTapSession(String amountStr) {
    GoSellSdkFlutter.sessionConfigurations(
      trxMode: TransactionMode.PURCHASE,
      paymentItems: [],
      paymentMetaData: const {},
      taxes: [],
      shippings: [],
      customer: Customer(
        customerId: "",
        email: "customer@example.com",
        isdNumber: "966",
        number: "500000000",
        firstName: "Test",
        middleName: "",
        lastName: "User",
        metaData: '{"test": "test"}',
      ),
      transactionCurrency: "SAR",
      amount: double.tryParse(amountStr) ?? 0.0,
      applePayMerchantID: "merchant.applePayMerchantID",
      allowsToSaveSameCardMoreThanOnce: false,
      isUserAllowedToSaveCard: true,
      isRequires3DSecure: true,
      receipt: Receipt(true, false),
      authorizeAction: AuthorizeAction(
        type: AuthorizeActionType.VOID,
        timeInHours: 168,
      ),
      destinations: null,
      merchantID: "",
      allowedCadTypes: CardType.ALL,
      postURL: "https://tap.company",
      paymentDescription: "Payment for Zouz",
      paymentStatementDescriptor: "Zouz package payment",
      paymentType: PaymentType.ALL,
      allowsToEditCardHolderName: false,
      cardHolderName: "Test User",
      paymentReference: Reference(
        acquirer: "acquirer",
        gateway: "gateway",
        payment: "payment",
        track: "track",
        transaction: "trans_910101",
        order: "order_262625",
      ),
      appearanceMode: SDKAppearanceMode.fullscreen,
      sdkMode: SDKMode.Sandbox,
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final repository = ref.read(checkoutRepositoryProvider);
      
      // 1. Prepare items for backend
      List<Map<String, dynamic>> orderItems = [];
      double subtotal = 0;

      if (widget.fromCart && widget.items != null) {
        orderItems = widget.items!;
        for (var item in orderItems) {
          subtotal += (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0) * (double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0);
        }
      } else if (widget.package != null) {
        orderItems = [
          {
            'packageId': widget.package!['id'],
            'quantity': 1,
            'standId': widget.package!['standId'],
          }
        ];
        subtotal = double.tryParse(widget.package!['price']?.toString() ?? '0') ?? 0.0;
      } else {
        throw Exception('No items to checkout');
      }

      final totalAmount = subtotal + (subtotal * 0.15);

      // 2. Create Order on Backend
      final response = await repository.createOrder(orderItems);
      final orderId = response['orderId'];

      if (!mounted) return;

      // 3. Initialize Session
      _initializeTapSession(totalAmount.toStringAsFixed(2));

      // 4. Start Payment SDK
      final result = await GoSellSdkFlutter.startPaymentSDK;

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (result != null && result is Map) {
        final sdkResult = result['sdk_result'];
        if (sdkResult == 'SUCCESS') {
          final tapChargeId = result['charge_id'] ?? 'MOCK_CHARGE_ID';
          await repository.confirmOrder(orderId, tapChargeId);
          
          if (widget.fromCart) {
            ref.read(cartProvider.notifier).clear();
          }

          if (!mounted) return;
          _showSuccess(orderId);
          return;
        } else if (sdkResult == 'SDK_ERROR' || sdkResult == 'FAILED') {
          _showError(result['sdk_error_message'] ?? 'checkout.failed'.tr());
          return;
        } else if (sdkResult == 'CANCELLED') {
          _showError('checkout.cancelled'.tr());
          return;
        }
      }
      _showError('Unknown Payment Status');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showError(e.toString());
    }
  }

  void _showSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('checkout.success_title'.tr()),
        content: Text('checkout.success_msg'.tr(args: [orderId])),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); 
              context.go('/dashboard');
            },
            child: Text('checkout.return_home'.tr()),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('checkout.error_prefix'.tr(args: [message])),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    
    double subtotal = 0;
    List<Widget> itemWidgets = [];

    if (widget.fromCart && widget.items != null) {
      for (var item in widget.items!) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        subtotal += price * qty;
        
        itemWidgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item['packageName']} (x$qty)', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(price * qty).toStringAsFixed(2)} ${'dashboard.currency'.tr()}'),
            ],
          ),
        ));
      }
    } else if (widget.package != null) {
      final name = _getLocalizedValue(widget.package!['name'], locale);
      final price = double.tryParse(widget.package!['price']?.toString() ?? '0') ?? 0.0;
      subtotal = price;
      
      itemWidgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${price.toStringAsFixed(2)} ${'dashboard.currency'.tr()}'),
        ],
      ));
    }

    final tax = subtotal * 0.15;
    final total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(title: Text('checkout.title'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'checkout.summary'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...itemWidgets,
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('checkout.vat'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                      Text('${tax.toStringAsFixed(2)} ${'dashboard.currency'.tr()}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('checkout.total'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('checkout.payment_method'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Text('checkout.card'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: _isProcessingPayment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('checkout.pay_button'.tr(args: ['${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}'])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
