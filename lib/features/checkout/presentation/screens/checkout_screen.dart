import 'package:flutter/material.dart';
import '../../../../core/services/analytics_service.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tap_apple_pay_flutter/tap_apple_pay_flutter.dart';
import 'package:tap_apple_pay_flutter/models/models.dart';
import 'dart:io' show Platform;
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/image_utils.dart';
import '../../repositories/checkout_repository.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../profile/models/profile_model.dart';
import 'package:zouz_mobile/features/dashboard/providers/home_provider.dart';
import 'package:zouz_mobile/features/purchases/presentation/screens/purchases_screen.dart';
import 'dart:async';

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
  static const _applePayDiagnosticsChannel = MethodChannel(
    'zouz/apple_pay_diagnostics',
  );
  bool _isProcessingPayment = false;
  // Silent guard while Apple Pay sheet is open — no overlay shown.
  // Overlay only shows after sheet dismisses via _isProcessingPayment.
  bool _isApplePaySheetOpen = false;
  bool _isNavigatingToStatus = false;
  String? _checkoutUrl;
  String _selectedPaymentMethod = Platform.isIOS ? 'apple_pay' : 'card';
  String? _selectedSavedCardToken;
  late final WebViewController _webViewController;
  bool _isShowingProfileDialog = false;
  // Render Apple's native control immediately on iOS. Capability checks run
  // silently and remove it only when Wallet cannot make a supported payment.
  bool _applePayReady = Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _initApplePay();
  }

  void _markApplePayUnavailable() {
    if (!mounted) return;
    setState(() {
      _applePayReady = false;
      if (_selectedPaymentMethod == 'apple_pay') {
        _selectedPaymentMethod = 'card';
      }
    });
  }

  Future<void> _initApplePay() async {
    try {
      // Tap's checkout-profile endpoint rejects the Apple Developer merchant
      // identifier with error 1164. This setup field is optional; the actual
      // Apple Pay request still uses AppConfig.applePayMerchantId below.
      TapApplePayFlutter.setupApplePayConfiguration(
        sandboxKey: AppConfig.tapPublishableSandboxKey,
        productionKey: AppConfig.tapPublishableProductionKey,
        sdkMode: AppConfig.isProduction ? SdkMode.production : SdkMode.sandbox,
        merchantId: null,
        applePayButtonRadius: 8,
      );
      final result = await TapApplePayFlutter.setupApplePay.timeout(
        const Duration(seconds: 12),
      );
      if (result["success"] == true) {
        debugPrint("Apple Pay SDK initialised successfully.");
        var deviceCanUseApplePay = true;
        if (Platform.isIOS) {
          final diagnostics = await _applePayDiagnosticsChannel
              .invokeMapMethod<String, dynamic>('check');
          final configuredMerchantId =
              diagnostics?['configuredMerchantIdentifier'] as String? ?? '';
          final hasExpectedMerchantId =
              configuredMerchantId == AppConfig.applePayMerchantId;
          final canMakePayments = diagnostics?['canMakePayments'] == true;
          final canUseSupportedCard =
              diagnostics?['canMakePaymentsWithNetworks'] == true;
          deviceCanUseApplePay =
              hasExpectedMerchantId && canMakePayments && canUseSupportedCard;

          debugPrint(
            'Apple Pay diagnostics: '
            'mode=${AppConfig.isProduction ? 'production' : 'sandbox'}, '
            'requestedMerchantId=${AppConfig.applePayMerchantId}, '
            'configuredMerchantId=$configuredMerchantId, '
            'canMakePayments=$canMakePayments, '
            'canUseVisaMastercardMada=$canUseSupportedCard',
          );

          if (!hasExpectedMerchantId) {
            debugPrint(
              'Apple Pay unavailable: the iOS build is not configured with '
              '${AppConfig.applePayMerchantId}.',
            );
          } else if (!canMakePayments) {
            debugPrint(
              'Apple Pay unavailable: Wallet/Apple Pay is not enabled on this device.',
            );
          } else if (!canUseSupportedCard) {
            debugPrint(
              'Apple Pay unavailable: Wallet has no supported Visa, Mastercard, or Mada card.',
            );
          }
        }
        if (mounted) {
          setState(() {
            _applePayReady = deviceCanUseApplePay;
            if (Platform.isIOS && deviceCanUseApplePay) {
              _selectedPaymentMethod = 'apple_pay';
            }
          });
        }
      } else {
        debugPrint("Apple Pay SDK init failed: ${result["error"]}");
        _markApplePayUnavailable();
      }
    } on TimeoutException {
      debugPrint('Apple Pay SDK initialisation timed out.');
      _markApplePayUnavailable();
    } catch (e) {
      debugPrint("Error initializing Apple Pay: $e");
      _markApplePayUnavailable();
    }
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            _handleRedirect(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _handleRedirect(change.url!);
            }
          },
        ),
      );
  }

  void _handleRedirect(String url) {
    if (_isNavigatingToStatus) return;

    if (url.contains('/checkout/success')) {
      _isNavigatingToStatus = true;
      ref.read(cartProvider.notifier).clear();
      // Invalidate home data and purchases cache so fresh data is loaded
      ref.invalidate(homeDataProvider);
      ref.invalidate(purchasesFutureProvider);
      final uri = Uri.parse(url);
      final orderId = uri.queryParameters['orderId'];
      context.goNamed(
        'payment-success',
        queryParameters: {'orderId': orderId ?? ''},
      );
    } else if (url.contains('/checkout/failed')) {
      _isNavigatingToStatus = true;
      final uri = Uri.parse(url);
      final reason = uri.queryParameters['reason'];

      // Reset state
      setState(() {
        _isProcessingPayment = false;
        _checkoutUrl = null;
      });

      context.goNamed(
        'payment-failure',
        queryParameters: {'reason': reason ?? ''},
        extra: {'package': widget.package, 'items': widget.items},
      );
    }
  }

  Future<void> _processCheckout(double totalAmount) async {
    final analyticsPaymentMethod = _selectedPaymentMethod == 'saved_card'
        ? 'saved_card'
        : 'card';
    AnalyticsService.instance.checkoutStarted(
      paymentMethod: analyticsPaymentMethod,
      value: totalAmount,
    );
    setState(() => _isProcessingPayment = true);

    try {
      final repository = ref.read(checkoutRepositoryProvider);

      // Enforce profile completion before checkout
      try {
        final profile = await ref.read(profileProvider.future);
        if ((profile.name?.isEmpty ?? true) ||
            (profile.email?.isEmpty ?? true)) {
          setState(() => _isProcessingPayment = false);
          if (mounted) {
            context.push('/complete-profile');
          }
          return;
        }
      } catch (e) {
        debugPrint('Failed to fetch profile before checkout: $e');
        setState(() => _isProcessingPayment = false);
        _showError('checkout.profile_error'.tr());
        return;
      }

      List<Map<String, dynamic>> orderItems = [];

      if (widget.fromCart && widget.items != null) {
        orderItems = widget.items!;
      } else if (widget.package != null) {
        orderItems = [
          {
            'packageId': widget.package!['id'],
            'quantity': 1,
            'standId': widget.package!['standId'],
          },
        ];
      } else {
        throw Exception('checkout.no_items'.tr());
      }

      // 1. Create Order
      final createResponse = await repository.createOrder(orderItems);
      final orderId = createResponse['orderId'];

      if (!mounted) return;

      // 2. Process Order (Initiate Tap Payment Hosted or Token Charge)
      final processResponse = await repository.processOrder(
        orderId,
        token: _selectedPaymentMethod == 'saved_card'
            ? _selectedSavedCardToken
            : null,
      );
      final redirectUrl = processResponse['redirectUrl'];

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        setState(() {
          _checkoutUrl = redirectUrl;
        });
        _webViewController.loadRequest(Uri.parse(redirectUrl));
      } else if (processResponse['success'] == true) {
        AnalyticsService.instance.paymentFinished(
          paymentMethod: analyticsPaymentMethod,
          success: true,
          value: totalAmount,
        );
        // Successful dynamic token charge without redirect (immediate CAPTURED)
        _isNavigatingToStatus = true;
        ref.read(cartProvider.notifier).clear();
        ref.invalidate(homeDataProvider);
        ref.invalidate(purchasesFutureProvider);
        if (mounted) {
          context.goNamed(
            'payment-success',
            queryParameters: {'orderId': orderId},
          );
        }
      } else {
        throw Exception('checkout.no_redirect'.tr());
      }
    } catch (e) {
      AnalyticsService.instance.paymentFinished(
        paymentMethod: analyticsPaymentMethod,
        success: false,
        value: totalAmount,
      );
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showError(e.toString());
    }
  }

  Future<void> _processApplePayCheckout(double total) async {
    // Guard: prevent double-tap while sheet is open or payment is processing
    if (!_applePayReady || _isApplePaySheetOpen || _isProcessingPayment) {
      return;
    }
    setState(() => _isApplePaySheetOpen = true);
    AnalyticsService.instance.checkoutStarted(
      paymentMethod: 'apple_pay',
      value: total,
    );

    try {
      final repository = ref.read(checkoutRepositoryProvider);

      // Enforce profile completion before checkout
      try {
        final profile = await ref.read(profileProvider.future);
        if ((profile.name?.isEmpty ?? true) ||
            (profile.email?.isEmpty ?? true)) {
          setState(() => _isApplePaySheetOpen = false);
          if (mounted) {
            _showProfileIncompleteDialog(context);
          }
          return;
        }
      } catch (e) {
        debugPrint('Failed to fetch profile before checkout: $e');
        setState(() => _isApplePaySheetOpen = false);
        _showError('checkout.profile_error'.tr());
        return;
      }

      // Phase 1: Show Apple Pay sheet — no overlay yet.
      final result = await TapApplePayFlutter.getTapToken(
        config: ApplePayConfig(
          transactionCurrency: TapCurrencyCode.SAR,
          allowedCardNetworks: [
            AllowedCardNetworks.VISA,
            AllowedCardNetworks.MASTERCARD,
            AllowedCardNetworks.MADA,
          ],
          applePayMerchantId: AppConfig.applePayMerchantId,
          amount: total,
          merchantCapabilities: [
            MerchantCapabilities.ThreeDS,
            MerchantCapabilities.Debit,
            MerchantCapabilities.Credit,
          ],
        ),
      );

      // Sheet dismissed — switch to processing overlay now.
      if (!mounted) return;
      setState(() {
        _isApplePaySheetOpen = false;
        _isProcessingPayment = true;
      });

      // SDK response shape: {success: true, data: {token: "tok_...", ...}}
      debugPrint("getTapToken raw result: $result");

      if (result["cancelled"] == true) {
        setState(() => _isProcessingPayment = false);
        return;
      }

      if (result["success"] != true) {
        final data = result["data"];
        final errMsg =
            (data != null ? data["sdk_result"] : null) ??
            "Apple Pay token generation failed";
        throw Exception(errMsg);
      }

      final data = result["data"] as Map?;
      final String? tapTokenId = data?["token"] as String?;
      if (tapTokenId == null || tapTokenId.isEmpty) {
        throw Exception(
          "Apple Pay token generation failed — no token returned",
        );
      }

      List<Map<String, dynamic>> orderItems = [];

      if (widget.fromCart && widget.items != null) {
        orderItems = widget.items!;
      } else if (widget.package != null) {
        orderItems = [
          {
            'packageId': widget.package!['id'],
            'quantity': 1,
            'standId': widget.package!['standId'],
          },
        ];
      } else {
        throw Exception('checkout.no_items'.tr());
      }

      // Phase 2 (overlay visible): Create Order → Process with token
      final createResponse = await repository.createOrder(orderItems);
      final orderId = createResponse['orderId'];

      if (!mounted) return;

      final processResponse = await repository.processOrder(
        orderId,
        token: tapTokenId,
        paymentMethod: 'APPLE_PAY',
      );

      if (!mounted) return;

      if (processResponse['success'] == true) {
        AnalyticsService.instance.paymentFinished(
          paymentMethod: 'apple_pay',
          success: true,
          value: total,
        );
        _isNavigatingToStatus = true;
        ref.read(cartProvider.notifier).clear();
        // Invalidate home data and purchases cache so fresh data is loaded
        ref.invalidate(homeDataProvider);
        ref.invalidate(purchasesFutureProvider);
        context.goNamed(
          'payment-success',
          queryParameters: {'orderId': orderId},
        );
      } else {
        _showError('Payment failed to process');
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      AnalyticsService.instance.paymentFinished(
        paymentMethod: 'apple_pay',
        success: false,
        value: total,
      );
      if (!mounted) return;
      setState(() {
        _isApplePaySheetOpen = false;
        _isProcessingPayment = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('checkout.error_prefix'.tr(args: [message])),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showProfileIncompleteDialog(BuildContext context) {
    if (_isShowingProfileDialog) return;
    _isShowingProfileDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'checkout.profile_incomplete_title'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'checkout.profile_incomplete_desc'.tr(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isShowingProfileDialog = false;
                Navigator.pop(dialogContext); // close dialog
                context.pop(); // return to previous screen
              },
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _isShowingProfileDialog = false;
                Navigator.pop(dialogContext); // close dialog
                context.push('/complete-profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'checkout.complete_profile_btn'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('checkout.payment_title'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _checkoutUrl = null;
              _isProcessingPayment = false;
            }),
          ),
        ),
        body: WebViewWidget(controller: _webViewController),
      );
    }

    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if ((profile.name?.isEmpty ?? true) ||
            (profile.email?.isEmpty ?? true)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showProfileIncompleteDialog(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildCheckoutContent(context, profile);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _paymentSelectionIndicator(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 17, color: Colors.white)
          : null,
    );
  }

  Widget _paymentOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
        child: Row(
          children: [
            _paymentSelectionIndicator(selected),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ],
        ),
      ),
    );
  }

  Widget _paymentDivider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade200);

  Widget _checkoutImage(String? path, {double size = 58}) {
    final imageUrl = ImageUtils.getFullUrl(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.shade100,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.inventory_2_outlined, color: Colors.grey.shade500)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade500,
                ),
              ),
      ),
    );
  }

  Widget _priceDetailRow(String label, double amount, {bool total = false}) {
    final weight = total ? FontWeight.w800 : FontWeight.w500;
    final color = total ? Colors.black : Colors.grey.shade700;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: total ? 16 : 14,
              fontWeight: weight,
              color: color,
            ),
          ),
        ),
        _sarAmount(
          amount,
          style: TextStyle(
            fontSize: total ? 17 : 14,
            fontWeight: total ? FontWeight.w800 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _sarAmount(
    double amount, {
    required TextStyle style,
    bool isOldPrice = false,
  }) {
    final decoration = isOldPrice
        ? TextDecoration.lineThrough
        : TextDecoration.none;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${amount.toStringAsFixed(2)} ',
            style: style.copyWith(decoration: decoration),
          ),
          TextSpan(
            text: '',
            style: style.copyWith(fontFamily: 'SAR', decoration: decoration),
          ),
        ],
      ),
      maxLines: 1,
    );
  }

  String? _localizedValue(dynamic value, String locale) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map) {
      final localized = value[locale] ?? value['en'] ?? value['ar'];
      if (localized is String && localized.trim().isNotEmpty) return localized;
    }
    return null;
  }

  Widget _buildCheckoutContent(BuildContext context, UserProfile profile) {
    final locale = context.locale.languageCode;
    double subtotal = 0;
    List<Widget> itemWidgets = [];

    String? tenantName;
    String? tenantLogoUrl;

    if (widget.fromCart && widget.items != null && widget.items!.isNotEmpty) {
      final firstItem = widget.items!.first;
      tenantName = _localizedValue(
        firstItem['tenantName'] ??
            firstItem['businessName'] ??
            firstItem['providerName'],
        locale,
      );
      tenantLogoUrl =
          firstItem['tenantLogoUrl']?.toString() ??
          firstItem['businessLogo']?.toString() ??
          firstItem['providerLogo']?.toString();

      for (var item in widget.items!) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        subtotal += price * qty;

        itemWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkoutImage(item['imageUrl']?.toString()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['packageName']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'checkout.item_quantity'.tr(args: [qty.toString()]),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _sarAmount(
                      price * qty,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (item['originalPrice'] != null) ...[
                      const SizedBox(height: 2),
                      _sarAmount(
                        (double.tryParse(item['originalPrice'].toString()) ??
                                0.0) *
                            qty,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        isOldPrice: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } else if (widget.package != null) {
      final name = widget.package!['name'] is Map
          ? widget.package!['name'][locale] ??
                widget.package!['name']['en'] ??
                ''
          : widget.package!['name']?.toString() ?? '';

      tenantName = _localizedValue(
        widget.package!['tenantName'] ??
            widget.package!['businessName'] ??
            widget.package!['providerName'],
        locale,
      );

      tenantLogoUrl =
          widget.package!['tenantLogoUrl']?.toString() ??
          widget.package!['businessLogo']?.toString() ??
          widget.package!['providerLogo']?.toString();

      final price =
          double.tryParse(widget.package!['price']?.toString() ?? '0') ?? 0.0;
      subtotal = price;

      itemWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkoutImage(widget.package!['imageUrl']?.toString()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'checkout.item_quantity'.tr(args: const ['1']),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sarAmount(
                    price,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (widget.package!['originalPrice'] != null) ...[
                    const SizedBox(height: 2),
                    _sarAmount(
                      double.tryParse(
                            widget.package!['originalPrice'].toString(),
                          ) ??
                          0.0,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      isOldPrice: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    final total = subtotal;
    final amountBeforeVat = total / 1.15;
    final vatAmount = total - amountBeforeVat;
    final itemCount = widget.fromCart && widget.items != null
        ? widget.items!.fold<int>(
            0,
            (count, item) =>
                count +
                (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1),
          )
        : 1;
    final resolvedTenantLogoUrl = ImageUtils.getFullUrl(tenantLogoUrl);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7F7F9),
          appBar: AppBar(
            title: Text(
              'checkout.title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card (User Information)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage:
                            profile.avatarUrl != null &&
                                profile.avatarUrl!.isNotEmpty
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child:
                            profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? Text(
                                (profile.name?.isNotEmpty ?? false)
                                    ? profile.name![0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name?.isNotEmpty ?? false
                                  ? profile.name!
                                  : 'checkout.anonymous_user'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            if (profile.phoneNumber != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                profile.phoneNumber!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/complete-profile'),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Order Summary Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'checkout.summary'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Items Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              radius: 20,
                              backgroundImage: resolvedTenantLogoUrl != null
                                  ? NetworkImage(resolvedTenantLogoUrl)
                                  : null,
                              child: resolvedTenantLogoUrl == null
                                  ? const Icon(
                                      Icons.store_rounded,
                                      color: Colors.black54,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tenantName ?? 'checkout.store_label'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'checkout.items_count'.tr(
                                      args: [itemCount.toString()],
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),

                      // Items List
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: itemWidgets),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Price details
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'checkout.price_details'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Totals Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _priceDetailRow(
                        'checkout.amount_before_vat'.tr(),
                        amountBeforeVat,
                      ),
                      const SizedBox(height: 14),
                      _priceDetailRow('checkout.vat_amount'.tr(), vatAmount),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      _priceDetailRow(
                        'checkout.total'.tr(),
                        total,
                        total: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'checkout.payment_details'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'checkout.pay_now_full'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _sarAmount(
                            total,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _paymentDivider(),
                    ],
                  ),
                ),

                if (Platform.isIOS && _applePayReady) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _paymentOption(
                          title: 'Apple Pay',
                          subtitle: 'checkout.apple_pay_available'.tr(),
                          selected: _selectedPaymentMethod == 'apple_pay',
                          onTap: () => setState(
                            () => _selectedPaymentMethod = 'apple_pay',
                          ),
                          trailing: SizedBox(
                            width: 96,
                            height: 44,
                            child: Image.asset(
                              'assets/images/apple_pay_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        _paymentDivider(),
                      ],
                    ),
                  ),
                ] else if (Platform.isIOS) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      'checkout.apple_pay_unavailable'.tr(),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ref
                    .watch(paymentMethodsProvider)
                    .when(
                      data: (methods) {
                        final cardMethods = methods
                            .where((m) => m.type == 'CARD')
                            .toList();
                        if (cardMethods.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: cardMethods.map((method) {
                              final tapCardId = method.cardId;
                              final isSelected =
                                  _selectedPaymentMethod == 'saved_card' &&
                                  _selectedSavedCardToken == tapCardId;
                              final title =
                                  "${method.brand ?? 'Card'} •••• ${method.last4 ?? '****'}";

                              return Column(
                                children: [
                                  _paymentOption(
                                    title: title,
                                    selected: isSelected,
                                    onTap: () => setState(() {
                                      _selectedPaymentMethod = 'saved_card';
                                      _selectedSavedCardToken = tapCardId;
                                    }),
                                    trailing: Icon(
                                      Icons.credit_card,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  _paymentDivider(),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _paymentOption(
                    title: 'checkout.bank_card'.tr(),
                    selected: _selectedPaymentMethod == 'card',
                    onTap: () => setState(() {
                      _selectedPaymentMethod = 'card';
                      _selectedSavedCardToken = null;
                    }),
                    trailing: SizedBox(
                      width: 138,
                      height: 38,
                      child: Image.asset(
                        'assets/images/payment_methods.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'checkout.security_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _selectedPaymentMethod == 'apple_pay'
                      ? SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: _applePayReady
                              ? TapApplePayFlutter.buildApplePayButton(
                                  applePayButtonType:
                                      ApplePayButtonType.payWithApplePay,
                                  applePayButtonStyle:
                                      ApplePayButtonStyle.black,
                                  onPress: () =>
                                      _processApplePayCheckout(total),
                                )
                              : const SizedBox.shrink(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isProcessingPayment
                                ? null
                                : () => _processCheckout(total),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessingPayment
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'checkout.pay_button'.tr(args: ['']).trim(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // ── Processing overlay ──────────────────────────────────────────────
        // Blocks all interaction and shows a spinner while the payment is
        // being processed (Apple Pay token → create order → charge).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isProcessingPayment
              ? Container(
                  key: const ValueKey('processing'),
                  color: const Color(0xFF101828).withValues(alpha: 0.62),
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0F4FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 4,
                                    strokeCap: StrokeCap.round,
                                    color: AppColors.primary,
                                    backgroundColor: Color(0xFFDCE5FF),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'checkout.processing_title'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF101828),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'checkout.processing_desc'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF667085),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 16,
                                        color: Color(0xFF667085),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'checkout.security_hint'.tr(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.3,
                                            color: Color(0xFF667085),
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('idle')),
        ),
      ],
    );
  }
}
