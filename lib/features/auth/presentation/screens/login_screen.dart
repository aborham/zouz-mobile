import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/widgets/glass_card.dart';
import '../../../../core/widgets/zouz_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (next.status == AuthStatus.otpSent) {
        context.push('/otp');
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Elements
          Container(
            color: AppColors.background,
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const Center(child: ZouzLogo(size: 100, color: AppColors.primary)),
                      const SizedBox(height: 40),
                      Text(
                        'auth.login_title'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),

                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'auth.login_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),

                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      GlassCard(
                        padding: const EdgeInsets.all(32),
                        opacity: 0.04,
                        color: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'auth.phone_number'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: ui.TextDirection.ltr,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'auth.phone_hint'.tr(),
                                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                                fillColor: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: authState.status == AuthStatus.loading
                                  ? null
                                  : () {
                                      if (_phoneController.text.isNotEmpty) {
                                        ref
                                            .read(authNotifierProvider.notifier)
                                            .requestOtp(_phoneController.text);
                                      }
                                    },
                              child: authState.status == AuthStatus.loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text('auth.send_otp'.tr()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
