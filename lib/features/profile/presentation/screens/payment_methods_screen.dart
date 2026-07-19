import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../providers/profile_provider.dart';


import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/config/app_config.dart';
import '../../providers/profile_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  String? _verificationUrl;
  bool _isProcessing = false;
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
          onPageFinished: (String url) {
            debugPrint('PaymentMethods WebView finished loading: $url');
            _handleRedirect(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              debugPrint('PaymentMethods WebView URL changed: ${change.url}');
              _handleRedirect(change.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('PaymentMethods WebView navigation request: ${request.url}');
            if (request.url.contains('payment-callback/success') || request.url.contains('payment-callback/error')) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _handleRedirect(String url) {
    debugPrint('PaymentMethods _handleRedirect called with URL: $url');
    if (url.contains('payment-callback/success')) {
      // Refresh saved cards
      ref.invalidate(paymentMethodsProvider);
      if (mounted) {
        setState(() {
          _verificationUrl = null;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.success'.tr()), backgroundColor: Colors.green),
        );
      }
    } else if (url.contains('payment-callback/error')) {
      final uri = Uri.parse(url);
      final reason = uri.queryParameters['reason'] ?? 'Failed to verify card';
      if (mounted) {
        setState(() {
          _verificationUrl = null;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _startCardSetup() async {
    setState(() => _isProcessing = true);
    try {
      // Tap provides a hosted checkout/token page for card verification where they enter card details securely.
      // Alternatively, we use Tap's Card input form. We can load Tap's standard tokenize page,
      // or verification URL by calling verifyAndSaveCard backend endpoint with tok_card.
      // For sandbox verification testing, we pass 'tok_card' directly to trigger Tap's Authorize flow.
      final result = await ref.read(profileRepositoryProvider).verifyAndSaveCard('src_card', false);
      final redirectUrl = result['redirectUrl'];

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        setState(() {
          _verificationUrl = redirectUrl;
        });
        _webViewController.loadRequest(Uri.parse(redirectUrl));
      } else {
        throw Exception('Failed to get verification link from Tap');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificationUrl != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('payment.add_card'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _verificationUrl = null;
              _isProcessing = false;
            }),
          ),
        ),
        body: WebViewWidget(controller: _webViewController),
      );
    }

    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'profile.title'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'payment.title'.tr(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'payment.subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Payment Methods List
                paymentMethodsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('payment.error'.tr(), style: const TextStyle(color: Colors.red)),
                  ),
                  data: (methods) {
                    if (methods.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'payment.empty_methods'.tr(),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: methods.map((method) {
                        if (method.type == 'WALLET') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildWalletCard(
                              icon: method.provider == 'APPLE_PAY' ? Icons.apple : Icons.account_balance_wallet,
                              title: method.provider == 'APPLE_PAY' ? "Apple Pay" : method.provider,
                              subtitle: 'payment.default_quick'.tr(),
                              isActive: method.isDefault,
                            ),
                          );
                        } else {
                          final title = "${method.brand ?? 'Card'} •••• ${method.last4 ?? '****'}";
                          final subtitle = 'payment.expires'.tr(namedArgs: {
                            "date": "${method.expiryMonth?.toString().padLeft(2, '0')}/${method.expiryYear?.toString().substring(2)}"
                          });
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCardItem(
                              id: method.id,
                              title: title,
                              subtitle: subtitle,
                              type: Icons.credit_card,
                            ),
                          );
                        }
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Add New Card Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _startCardSetup,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: Text(
                      'payment.add_card'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 5,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Grid items
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.trending_up,
                        title: 'payment.spending'.tr(),
                        subtitle: 'payment.spending_desc'.tr(),
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'payment.active'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData type,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.credit_card, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('common.confirm'.tr()),
                    content: Text('payment.delete_confirm'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('common.cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: Text('common.delete'.tr()),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await ref.read(profileRepositoryProvider).deletePaymentMethod(id);
                    ref.invalidate(paymentMethodsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('common.success'.tr()), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
