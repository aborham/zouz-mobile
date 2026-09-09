import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';

class LegalDocsScreen extends StatefulWidget {
  final String type; // 'terms' or 'privacy'

  const LegalDocsScreen({super.key, required this.type});

  @override
  State<LegalDocsScreen> createState() => _LegalDocsScreenState();
}

class _LegalDocsScreenState extends State<LegalDocsScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // Keep track of the last loaded URL to prevent duplicate loads on identical renders
  String? _lastLoadedUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.locale.languageCode;
    final url = AppConfig.legalDocumentUrl(
      type: widget.type,
      language: lang,
    ).toString();

    if (_lastLoadedUrl != url) {
      _lastLoadedUrl = url;
      debugPrint('LegalDocsScreen loading webview URL: $url');
      _isLoading = true;
      _hasError = false;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.homeBackground)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String finishedUrl) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == true && mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'terms'
        ? 'profile.terms'.tr()
        : 'profile.privacy'.tr();
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (controller != null && !_hasError)
            WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'profile.legal_load_error'.tr(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        controller?.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
