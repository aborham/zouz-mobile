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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Assuming context.locale.languageCode is accessible here, but actually we can get it via context in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final lang = context.locale.languageCode;
      final url = widget.type == 'terms' 
          ? '${AppConfig.websiteUrl}/mobile-terms?lang=$lang' 
          : '${AppConfig.websiteUrl}/mobile-privacy?lang=$lang';
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.homeBackground)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
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
    final title = widget.type == 'terms' ? 'profile.terms'.tr() : 'profile.privacy'.tr();

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
