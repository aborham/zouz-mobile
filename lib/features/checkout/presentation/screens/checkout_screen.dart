import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saudi_riyal_symbol/saudi_riyal_symbol.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../repositories/checkout_repository.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../profile/providers/profile_provider.dart';

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
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
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
      context.goNamed('payment-success', queryParameters: {'orderId': orderId ?? ''});
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
        extra: {
          'package': widget.package,
          'items': widget.items,
        },
      );
    }
  }

  Future<void> _processCheckout() async {
    setState(() => _isProcessingPayment = true);

    try {
      final repository = ref.read(checkoutRepositoryProvider);
      
      // Enforce profile completion before checkout
      try {
        final profile = await ref.read(profileProvider.future);
        if (profile.name?.isEmpty ?? true) {
          setState(() => _isProcessingPayment = false);
          if (mounted) {
            context.push('/complete-profile');
          }
          return;
        }
      } catch (e) {
        debugPrint('Failed to fetch profile before checkout: $e');
        // If it fails, we can proceed, but ideally we show error. We'll proceed or redirect.
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
          }
        ];
      } else {
        throw Exception('checkout.no_items'.tr());
      }

      // 1. Create Order
      final createResponse = await repository.createOrder(orderItems);
      final orderId = createResponse['orderId'];

      if (!mounted) return;

      // 2. Process Order (Initiate Tap Payment)
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
        
        itemWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$qty × ${item['packageName']}', 
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
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
                      price: (double.tryParse(item['originalPrice'].toString()) ?? 0.0) * qty,
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
        ));
      }
    } else if (widget.package != null) {
      final name = widget.package!['name'] is Map 
        ? widget.package!['name'][locale] ?? widget.package!['name']['en'] ?? ''
        : widget.package!['name']?.toString() ?? '';
        
      tenantName = widget.package!['tenantName'] is Map 
        ? (widget.package!['tenantName'][locale] ?? widget.package!['tenantName']['en'])
        : widget.package!['tenantName']?.toString();
      
      if (tenantName == null && widget.package!['providerName'] != null) {
        tenantName = widget.package!['providerName'];
      }
      
      tenantLogoUrl = widget.package!['tenantLogoUrl'] ?? widget.package!['imageUrl'];
      
      final price = double.tryParse(widget.package!['price']?.toString() ?? '0') ?? 0.0;
      subtotal = price;
      
      itemWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '1 × $name', 
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
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
                    price: double.tryParse(widget.package!['originalPrice'].toString()) ?? 0.0,
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
      ));
    }

    final total = subtotal;
    final tax = total - (total / 1.15);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('checkout.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
            // Order Summary Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'checkout.summary'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                          backgroundImage: tenantLogoUrl != null ? NetworkImage(tenantLogoUrl) : null,
                          child: tenantLogoUrl == null 
                            ? const Icon(Icons.store_rounded, color: Colors.black54, size: 20)
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenantName ?? 'checkout.store_label'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.items?.length ?? 1} ${'packages.items'.tr()}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
                    child: Column(
                      children: itemWidgets,
                    ),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                      Text('checkout.total'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                  Text('packages.vat_included'.tr(), style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment Method Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('checkout.payment_method'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('checkout.card'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: AppColors.primary),
                ],
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'checkout.total'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    SaudiCurrencySymbol(
                      price: total,
                      priceStyle: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 20, 
                        color: Colors.black,
                      ),
                      symbolFontColor: Colors.black,
                      isOldPrice: false,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _processCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      elevation: 0,
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Text(
                            'checkout.pay_button'.tr(args: ['']).trim(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
