import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saudi_riyal_symbol/saudi_riyal_symbol.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tap_apple_pay_flutter/tap_apple_pay_flutter.dart';
import 'package:tap_apple_pay_flutter/models/models.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../repositories/checkout_repository.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../profile/models/profile_model.dart';

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
  bool _isNavigatingToStatus = false;
  String? _checkoutUrl;
  String _selectedPaymentMethod = 'card';
  late final WebViewController _webViewController;
  bool _isShowingProfileDialog = false;
  // true once setupApplePay resolves successfully
  bool _applePayReady = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _initApplePay();
  }

  Future<void> _initApplePay() async {
    try {
      // NOTE: merchantId is required but nullable. We pass null here (SDK sends "")
      // because passing a non-Tap-registered merchant ID causes server error 1164.
      // The Apple Pay merchant ID used for the actual payment token is supplied
      // per-transaction in ApplePayConfig inside _processApplePayCheckout().
      TapApplePayFlutter.setupApplePayConfiguration(
        sandboxKey: AppConfig.tapPublishableSandboxKey,
        productionKey: AppConfig.tapPublishableProductionKey,
        sdkMode: kReleaseMode ? SdkMode.production : SdkMode.sandbox,
        merchantId: null,
        applePayButtonRadius: 28,
      );
      final result = await TapApplePayFlutter.setupApplePay;
      if (result["success"] == true) {
        debugPrint("Apple Pay SDK initialised successfully.");
        if (mounted) setState(() => _applePayReady = true);
      } else {
        debugPrint("Apple Pay SDK init failed: ${result["error"]}");
      }
    } catch (e) {
      debugPrint("Error initializing Apple Pay: $e");
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
    setState(() => _isProcessingPayment = true);

    try {
      final repository = ref.read(checkoutRepositoryProvider);

      // Enforce profile completion before checkout
      try {
        final profile = await ref.read(profileProvider.future);
        if ((profile.name?.isEmpty ?? true) || (profile.email?.isEmpty ?? true)) {
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

      // 2. Process Order (Initiate Tap Payment Hosted)
      final processResponse = await repository.processOrder(orderId);
      final redirectUrl = processResponse['redirectUrl'];

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        setState(() {
          _checkoutUrl = redirectUrl;
        });
        _webViewController.loadRequest(Uri.parse(redirectUrl));
      } else {
        throw Exception('checkout.no_redirect'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showError(e.toString());
    }
  }

  Future<void> _processApplePayCheckout(double total) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    try {
      final repository = ref.read(checkoutRepositoryProvider);

      // Enforce profile completion before checkout
      try {
        final profile = await ref.read(profileProvider.future);
        if ((profile.name?.isEmpty ?? true) || (profile.email?.isEmpty ?? true)) {
          setState(() => _isProcessingPayment = false);
          if (mounted) {
            _showProfileIncompleteDialog(context);
          }
          return;
        }
      } catch (e) {
        debugPrint('Failed to fetch profile before checkout: $e');
        setState(() => _isProcessingPayment = false);
        _showError('checkout.profile_error'.tr());
        return;
      }

      // 2. Request Tap Apple Pay Token
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

      // getTapToken returns the raw Tap API response — no {success/data} wrapper.
      // A successful response has result["id"] = "tok_..." and result["status"] = "ACTIVE".
      // An error response has result["errors"] = [...].
      debugPrint("getTapToken raw result: $result");

      final errors = result["errors"];
      if (errors != null && (errors as List).isNotEmpty) {
        final desc = errors.first["description"] ?? "Apple Pay token failed";
        throw Exception(desc);
      }

      final String? tapTokenId = result["id"] as String?;
      if (tapTokenId == null || tapTokenId.isEmpty) {
        throw Exception("Apple Pay token generation failed — no token ID returned");
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

      // 3. Create Order
      final createResponse = await repository.createOrder(orderItems);
      final orderId = createResponse['orderId'];

      if (!mounted) return;

      // 4. Process Order with Tap Token
      final processResponse = await repository.processOrder(
        orderId,
        token: tapTokenId,
      );

      if (!mounted) return;

      if (processResponse['success'] == true) {
        _isNavigatingToStatus = true;
        ref.read(cartProvider.notifier).clear();
        context.goNamed(
          'payment-success',
          queryParameters: {'orderId': orderId},
        );
      } else {
        _showError('Payment failed to process');
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                'checkout.profile_incomplete_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'checkout.profile_incomplete_desc'.tr(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                _isShowingProfileDialog = false;
                Navigator.pop(dialogContext); // close dialog
                context.pop(); // return to previous screen
              },
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        if ((profile.name?.isEmpty ?? true) || (profile.email?.isEmpty ?? true)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showProfileIncompleteDialog(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildCheckoutContent(context, profile);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, UserProfile profile) {

    final locale = context.locale.languageCode;
    double subtotal = 0;
    List<Widget> itemWidgets = [];

    String? tenantName;
    String? tenantLogoUrl;

    if (widget.fromCart && widget.items != null && widget.items!.isNotEmpty) {
      tenantName = widget.items!.first['tenantName'];
      tenantLogoUrl = widget.items!.first['tenantLogoUrl'];

      for (var item in widget.items!) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        subtotal += price * qty;

        itemWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$qty × ${item['packageName']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SaudiCurrencySymbol(
                      price: price * qty,
                      priceStyle: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      symbolFontColor: Colors.black87,
                      isOldPrice: false,
                    ),
                    if (item['originalPrice'] != null) ...[
                      const SizedBox(height: 2),
                      SaudiCurrencySymbol(
                        price:
                            (double.tryParse(
                                  item['originalPrice'].toString(),
                                ) ??
                                0.0) *
                            qty,
                        priceStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        symbolFontColor: Colors.grey.shade400,
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

      tenantName = widget.package!['tenantName'] is Map
          ? (widget.package!['tenantName'][locale] ??
                widget.package!['tenantName']['en'])
          : widget.package!['tenantName']?.toString();

      if (tenantName == null && widget.package!['providerName'] != null) {
        tenantName = widget.package!['providerName'];
      }

      tenantLogoUrl =
          widget.package!['tenantLogoUrl'] ?? widget.package!['imageUrl'];

      final price =
          double.tryParse(widget.package!['price']?.toString() ?? '0') ?? 0.0;
      subtotal = price;

      itemWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '1 × $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SaudiCurrencySymbol(
                    price: price,
                    priceStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    symbolFontColor: Colors.black87,
                    isOldPrice: false,
                  ),
                  if (widget.package!['originalPrice'] != null) ...[
                    const SizedBox(height: 2),
                    SaudiCurrencySymbol(
                      price:
                          double.tryParse(
                            widget.package!['originalPrice'].toString(),
                          ) ??
                          0.0,
                      priceStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      symbolFontColor: Colors.grey.shade400,
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

    return Scaffold(
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
        padding: const EdgeInsets.only(bottom: 120),
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
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
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
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
                          backgroundImage: tenantLogoUrl != null
                              ? NetworkImage(tenantLogoUrl)
                              : null,
                          child: tenantLogoUrl == null
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
                                '${widget.items?.length ?? 1} ${'packages.items'.tr()}',
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

            // Order Totals Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'checkout.total'.tr(),
                style: const TextStyle(
                  fontSize: 20,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'checkout.total'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      SaudiCurrencySymbol(
                        price: total,
                        priceStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        symbolFontColor: Colors.black,
                        isOldPrice: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'packages.vat_included'.tr(),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Payment Method Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'checkout.payment_method'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (Platform.isIOS) ...[
              GestureDetector(
                // Only allow selection after SDK is ready
                onTap: _applePayReady
                    ? () => setState(() => _selectedPaymentMethod = 'apple_pay')
                    : null,
                child: Opacity(
                  opacity: _applePayReady ? 1.0 : 0.55,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPaymentMethod == 'apple_pay'
                            ? Colors.black
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _selectedPaymentMethod == 'apple_pay'
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apple,
                          color: _selectedPaymentMethod == 'apple_pay'
                              ? Colors.black
                              : Colors.grey.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Apple Pay',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (!_applePayReady)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        else if (_selectedPaymentMethod == 'apple_pay')
                          const Icon(Icons.check_circle, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = 'card'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPaymentMethod == 'card'
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedPaymentMethod == 'card'
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: _selectedPaymentMethod == 'card'
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'checkout.card'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedPaymentMethod == 'card')
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'checkout.security_hint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'checkout.total'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  SaudiCurrencySymbol(
                    price: total,
                    priceStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF2C3E50),
                    ),
                    symbolFontColor: const Color(0xFF2C3E50),
                    isOldPrice: false,
                  ),
                ],
              ),
              _selectedPaymentMethod == 'apple_pay'
                  ? SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: _applePayReady
                          ? TapApplePayFlutter.buildApplePayButton(
                              applePayButtonType: ApplePayButtonType.appleLogoOnly,
                              applePayButtonStyle: ApplePayButtonStyle.black,
                              onPress: () => _processApplePayCheckout(total),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}
