import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      final name = widget.package!['name'] is Map 
        ? widget.package!['name'][locale] ?? widget.package!['name']['en'] ?? ''
        : widget.package!['name']?.toString() ?? '';
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

    final total = subtotal;
    final tax = total - (total / 1.15);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('checkout.title'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
                      Text('checkout.vat'.tr(), style: const TextStyle(color: Colors.grey)),
                      Text('${tax.toStringAsFixed(2)} ${'dashboard.currency'.tr()}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('checkout.total'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      Text(
                        '${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF224AFB)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('checkout.payment_method'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF224AFB), width: 1.5),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: Colors.black),
                  const SizedBox(width: 16),
                  Text('checkout.card'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: Color(0xFF224AFB)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF224AFB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isProcessingPayment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'checkout.pay_button'.tr(args: ['${total.toStringAsFixed(2)} ${'dashboard.currency'.tr()}']),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'checkout.security_hint'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
