import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/widgets/glass_card.dart';
import '../../../../core/widgets/zouz_logo.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
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
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Center(child: ZouzLogo(size: 80, color: AppColors.primary)),
                    const SizedBox(height: 32),
                    Text(
                      'auth.otp_title'.tr(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),

                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'auth.otp_subtitle'.tr(),
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
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 24,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "******",
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.3),
                                letterSpacing: 24,
                              ),
                              fillColor: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: authState.status == AuthStatus.loading
                                ? null
                                : () {
                                    if (_otpController.text.length == 6) {
                                      ref
                                          .read(authNotifierProvider.notifier)
                                          .verifyOtp(_otpController.text);
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
                                : Text('auth.verify_otp'.tr()),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              if (authState.phoneNumber != null) {
                                ref
                                    .read(authNotifierProvider.notifier)
                                    .requestOtp(authState.phoneNumber!);
                              }
                            },
                            child: Text(
                              'auth.resend_code'.tr(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}
