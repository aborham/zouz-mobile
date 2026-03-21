import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:go_sell_sdk_flutter/go_sell_sdk_flutter.dart';
import 'package:go_sell_sdk_flutter/model/models.dart';
import '../../repositories/checkout_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> package;

  const CheckoutScreen({super.key, required this.package});

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

  late Map<dynamic, dynamic> defaultColors;
  late Map<dynamic, dynamic> defaultLightColors;
  late Map<dynamic, dynamic> defaultDarkColors;

  @override
  void initState() {
    super.initState();
    _configureTapSDK();
  }

  void _configureTapSDK() {
    // Start Tap Payments SDK
    GoSellSdkFlutter.configureApp(
      productionSecretKey:
          'sk_test_PLACEHOLDER', // Use environment variables for keys
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
      // 1. Create Order on Backend
      final repository = ref.read(checkoutRepositoryProvider);
      final response = await repository.createOrder(
        widget.package['id'],
        1,
        widget.package['standId'],
      );

      final orderId = response['orderId'];
      final price = widget.package['price'] ?? 0;
      final totalAmount = price + (price * 0.15); // Add 15% VAT

      if (!mounted) return;

      // 2. Initialize Session
      _initializeTapSession(totalAmount.toStringAsFixed(2));

      // 3. Start Payment SDK and handle response map
      final result = await GoSellSdkFlutter.startPaymentSDK;

      if (!mounted) return;

      setState(() => _isProcessingPayment = false);

      if (result != null && result is Map) {
        final sdkResult = result['sdk_result'];
        if (sdkResult == 'SUCCESS') {
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
              context.pop(); // dismiss dialog
              context.go('/home'); // go to home or purchases
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
    final name = _getLocalizedValue(widget.package['name'], locale);
    final price = widget.package['price'] ?? 0;
    final tax = price * 0.15; // Assuming 15% tax
    final total = price + tax;

    return Scaffold(
      appBar: AppBar(title: Text('checkout.title'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'checkout.summary'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('$price ${'dashboard.currency'.tr()}'),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'checkout.vat'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${tax.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'checkout.total'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods Placeholder
            Text(
              'checkout.payment_method'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'checkout.card'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),

            const SizedBox(height: 48),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                child: _isProcessingPayment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'checkout.pay_button'.tr(
                          args: [
                            '${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
